#!/usr/bin/env bash
# Лаборатория проверок ворот: единый раннер.
#
# Гоняет все тесты из tests/**, печатает сводку, возвращает exit≠0 при любом
# FAIL. НЕ `set -e` — раннер собирает ВСЕ результаты, а не падает на первом.
#
# Что лаборатория доказывает на каждом прогоне:
#   1. red   — программные ворота РЕАЛЬНО блокируют нарушение инварианта
#              (ненулевой код + ожидаемая подстрока + побочный эффект не наступил);
#   2. pass  — легитимное действие проходит (анти-ложный-срабат, И-15);
#   3. contract — каждый путь из методологии существует на диске (нет фантомов).
#
# Все мутирующие тесты работают на временных копиях (mktemp -d) и убирают за
# собой. Живой репозиторий, ledger/, project-overlays/, .git — не трогаются.
#
# Зависимости: только bash + python3 stdlib + git. Если python3/git нет —
# зависящие тесты печатают SKIP, раннер не падает молча.
#
# Usage:
#   bash evals/lab/run.sh
# or:
#   make lab

set -uo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=evals/lab/lib/harness.sh
source "${LAB_DIR}/lib/harness.sh"

# Счётчики по категориям: индекс 0 = pass, 1 = fail.
declare -a RED_N=(0 0)
declare -a PASS_N=(0 0)
declare -a CONTRACT_N=(0 0)
SKIP_N=0
declare -a FAILED_TESTS=()
declare -a SKIPPED_TESTS=()
declare -a TIMEOUT_TESTS=()

# Бюджет на ОДИН тест. Зависший тест должен ПАДАТЬ с явным [TIMEOUT], а не
# вешать весь прогон. Переопределяется через LAB_TEST_TIMEOUT (секунды).
TEST_TIMEOUT="${LAB_TEST_TIMEOUT:-30}"
# Особый код выхода, которым помечаем именно превышение бюджета (отличаем от
# обычного FAIL=1). 124 — тот же код, что отдаёт coreutils `timeout`.
TIMEOUT_RC=124

# kill_tree <signal> <pid> — послать сигнал процессу И ВСЕМ его потомкам
# (рекурсивно, вглубь). Зависший тест — это bash-субшелл, под ним python/git;
# kill по одному pid оставил бы детей-сирот (на macOS нет process-group-kill без
# setsid). Дерево обходим через `ps -o pid=,ppid=` — только bash + ps.
kill_tree() {
  local sig="$1" pid="$2" child
  # сначала дети (чтобы не потерять связь после смерти родителя), потом сам pid
  for child in $(ps -o pid=,ppid= 2>/dev/null | awk -v p="${pid}" '$2==p{print $1}'); do
    kill_tree "${sig}" "${child}"
  done
  kill "-${sig}" "${pid}" 2>/dev/null || true
}

# run_with_timeout <secs> <out-file> <cmd...>
# Запускает команду с жёстким бюджетом времени, перенаправляя stdout+stderr в
# <out-file>. Возвращает код выхода команды; при превышении бюджета убивает её
# вместе с детьми (TERM, затем KILL) и возвращает TIMEOUT_RC (124). Переносимо:
# не зависит от coreutils `timeout`/`gtimeout` (на macOS их обычно нет) — чистый
# bash-сторож на фоновых процессах. Только bash + ps, без сторонних утилит.
run_with_timeout() {
  local secs="$1" outf="$2"; shift 2

  # Команда — в фоне; её stdout+stderr в файл. Детей при убийстве добиваем
  # рекурсивно (kill_tree), т.к. отдельного process group у фонового job нет.
  "$@" >"${outf}" 2>&1 &
  local cmd_pid=$!

  # Сторож: спит бюджет, затем валит дерево команды. Сторож тих — его вывод
  # не используется. Свой stderr глушим, чтобы job-control-уведомления о смерти
  # дочернего sleep не попали в лог прогона.
  (
    exec 2>/dev/null
    sleep "${secs}"
    if kill -0 "${cmd_pid}" 2>/dev/null; then
      kill_tree TERM "${cmd_pid}"   # мягко всему дереву
      sleep 2
      kill_tree KILL "${cmd_pid}"   # добить выжившее
    fi
  ) &
  local guard_pid=$!

  # Ждём команду. Если сторож её убил — wait вернёт код >128 (сигнал).
  local rc=0
  wait "${cmd_pid}" 2>/dev/null || rc=$?

  if (( rc > 128 )); then
    # Превышение бюджета: команду прибил сторож. НЕ гасим сторож сразу — даём ему
    # доиграть эскалацию TERM→KILL по всему дереву (иначе осиротевший внук, напр.
    # `sleep`, мог бы пережить только TERM). wait — со стёртым stderr (без шума
    # job-control про прибитый фоновый процесс).
    wait "${guard_pid}" 2>/dev/null || true
    return "${TIMEOUT_RC}"
  fi

  # Команда завершилась сама в срок — гасим сторож (и его sleep) вместе с детьми,
  # чтобы не ждать впустую. Гашение и wait — со стёртым stderr: иначе bash
  # печатает «Terminated: 15» про прибитый фоновый job в лог.
  { kill_tree TERM "${guard_pid}"; wait "${guard_pid}"; } 2>/dev/null || true
  return "${rc}"
}

# run_one_test <test-file>
# Исполняет тест в субшелле под per-test бюджетом времени, разбирает первую
# строку `TEST <id> <COLOR> <name>`, код выхода (0 ok / 1 fail / 77 skip / 124
# timeout), печатает строку результата, обновляет счётчики выбранной категории.
run_one_test() {
  local tf="$1"
  local raw rc header id color name body
  local outf
  outf="$(mktemp)"

  # Анонс ДО запуска: видно, на каком тесте прогон стоит, если он зависнет.
  echo "${C_DIM}[RUN]${C_RST} ${tf##*/}"

  run_with_timeout "${TEST_TIMEOUT}" "${outf}" bash "${tf}"; rc=$?
  raw="$(cat "${outf}")"
  rm -f "${outf}"

  # Превышение бюджета: тест зависший — явный [TIMEOUT], НЕ виснем дальше.
  if [[ "${rc}" == "${TIMEOUT_RC}" ]]; then
    echo "${C_RED}[TIMEOUT]${C_RST} ${tf##*/} — тест не уложился в ${TEST_TIMEOUT}с, прибит"
    TIMEOUT_TESTS+=("${tf##*/}")
    FAILED_TESTS+=("${tf##*/} (TIMEOUT ${TEST_TIMEOUT}с)")
    # частичный вывод теста печатаем для диагностики
    [[ -n "${raw}" ]] && printf '%s\n' "${raw}" | head -20 | sed 's/^/       /'
    return
  fi

  header="$(printf '%s\n' "${raw}" | head -1)"
  body="$(printf '%s\n' "${raw}" | tail -n +2)"

  if [[ "${header}" != TEST\ * ]]; then
    # Тест не следует контракту — считаем это FAIL харнесса.
    echo "${C_RED}[FAIL]${C_RST} ${tf##*/} — нет строки 'TEST <id> <COLOR> <name>'"
    FAILED_TESTS+=("${tf##*/} (нарушен контракт заголовка)")
    return
  fi

  # shellcheck disable=SC2086
  set -- ${header}
  id="${2:-?}"
  color="${3:-?}"
  shift 3 2>/dev/null || true
  name="$*"

  local cat_label
  case "${color}" in
    RED)      cat_label="red" ;;
    PASS)     cat_label="pass" ;;
    CONTRACT) cat_label="contract" ;;
    *)        cat_label="red" ;;  # неизвестный цвет — считаем строгим
  esac

  if [[ "${rc}" == "77" ]]; then
    SKIP_N=$((SKIP_N + 1))
    SKIPPED_TESTS+=("${id}")
    echo "${C_DIM}[SKIP]${C_RST} ${id} (${cat_label}) — ${name}"
    # тело SKIP-теста печатаем для прозрачности
    [[ -n "${body}" ]] && printf '%s\n' "${body}" | sed 's/^/       /'
    return
  fi

  if [[ "${rc}" == "0" ]]; then
    case "${cat_label}" in
      red)      RED_N[0]=$((RED_N[0] + 1)) ;;
      pass)     PASS_N[0]=$((PASS_N[0] + 1)) ;;
      contract) CONTRACT_N[0]=$((CONTRACT_N[0] + 1)) ;;
    esac
    echo "${C_GREEN}[PASS]${C_RST} ${id} (${cat_label}) — ${name}"
  else
    case "${cat_label}" in
      red)      RED_N[1]=$((RED_N[1] + 1)) ;;
      pass)     PASS_N[1]=$((PASS_N[1] + 1)) ;;
      contract) CONTRACT_N[1]=$((CONTRACT_N[1] + 1)) ;;
    esac
    FAILED_TESTS+=("${id} (${cat_label})")
    echo "${C_RED}[FAIL]${C_RST} ${id} (${cat_label}) — ${name}"
    [[ -n "${body}" ]] && printf '%s\n' "${body}" | sed 's/^/       /'
  fi
}

echo "=== Лаборатория проверок ворот: прогон ==="
echo "Корень репо: ${REPO_ROOT}"
if ! has_python3; then echo "${C_DIM}заметка: python3 не найден — зависящие тесты будут SKIP${C_RST}"; fi
if ! has_git;     then echo "${C_DIM}заметка: git не найден — зависящие тесты будут SKIP${C_RST}"; fi
echo ""

# Порядок групп — фиксированный для читаемой сводки.
for group in accept_task commit_msg self_check ledger truth_kernel action_core brief ru_guard prepush contract; do
  group_dir="${LAB_DIR}/tests/${group}"
  [[ -d "${group_dir}" ]] || continue
  # сортируем по имени для детерминированного порядка
  while IFS= read -r tf; do
    [[ -z "${tf}" ]] && continue
    run_one_test "${tf}"
  done < <(find "${group_dir}" -maxdepth 1 -name '*.sh' -type f | sort)
done

# --- сводка ------------------------------------------------------------------
red_pass="${RED_N[0]}";      red_fail="${RED_N[1]}"
pass_pass="${PASS_N[0]}";    pass_fail="${PASS_N[1]}"
con_pass="${CONTRACT_N[0]}"; con_fail="${CONTRACT_N[1]}"
timeout_n="${#TIMEOUT_TESTS[@]}"
total_pass=$((red_pass + pass_pass + con_pass))
# Тесты-таймауты не попадают в счётчики категорий (падают до разбора цвета),
# поэтому добавляем их в общий fail явно — иначе зависший тест выглядел бы
# «потерянным» из итога.
total_fail=$((red_fail + pass_fail + con_fail + timeout_n))

echo ""
echo "=== Лаборатория проверок: сводка ==="
printf '  red (блокировка):     %d pass / %d fail\n' "${red_pass}" "${red_fail}"
printf '  pass (легитимное):    %d pass / %d fail\n' "${pass_pass}" "${pass_fail}"
printf '  contract (пути):      %d pass / %d fail\n' "${con_pass}" "${con_fail}"
printf '  ИТОГО: %d pass / %d fail' "${total_pass}" "${total_fail}"
if (( SKIP_N > 0 )); then
  printf ' / %d skip' "${SKIP_N}"
fi
if (( timeout_n > 0 )); then
  printf ' (из них %d по таймауту)' "${timeout_n}"
fi
printf '\n'

if (( SKIP_N > 0 )); then
  echo "  пропущено (SKIP): ${SKIPPED_TESTS[*]}"
fi
if (( timeout_n > 0 )); then
  echo "  таймаут (>${TEST_TIMEOUT}с): ${TIMEOUT_TESTS[*]}"
fi

# --- honor_system: что лаборатория ЧЕСТНО НЕ покрывает -----------------------
# Печатаем на каждом прогоне, чтобы охват не выглядел шире, чем он есть.
# Покрыто сейчас: ворота приёмки (accept-task), подпись критпути (commit-msg),
# фильтр evidence + операторский язык (self-check, вкл. лазейку регистра §A),
# валидатор реестра aida check (И-4/5/6/13/14), стоп-хук русского (ru_guard),
# замок рассинхрона (pre-push), контракт путей.
echo ""
echo "=== honor_system: вне покрытия лаборатории (честно) ==="
echo "  • Поведенческие И-1/И-3/И-7/И-9 — нет исполняемого контура под них,"
echo "    проверять их статически нечем (нужен живой запуск, не файлы)."
echo "  • И-2/И-10 (всё через ядро + в журнал) покрыты ЧАСТИЧНО воротами дел"
echo "    v0.1 (tests/action_core): защищённый путь journals requested+executed,"
echo "    а сверка-с-миром ловит обход ПОСТ-ФАКТУМ (инцидент). НЕ покрыто:"
echo "    физическая блокировка прямой записи мимо ядра — это поздний слой"
echo "    (урезанная учётка, модель физически не пишет мимо), не v0.1."
echo "  • И-8 (денежный контур) — отдельный проект, в эту методологию не входит."
echo "  • И-15 (процессный: ритм смен/аудита) — проверяется людьми, не воротами."
echo "  • Смешанные ру-en конструкции — ru_guard ловит прозу/кашу/хеши, но фразовый"
echo "    контекст («полу-русское» предложение) остаётся на усмотрение автора."
echo "  • commit-msg покрыт по prefix-зонам критпутей, не по каждому точечному пути."
echo "  • Авто-скан путей в доках (грубый поиск *.md/*.sh/*.py по тексту) —"
echo "    следующая итерация; пока contract ведётся явной фикстурой"
echo "    contract_paths.tsv (синхронизирована вручную)."
echo "  Снято: «И-5 непокрыт» — источник факта проверяет валидатор реестра (см."
echo "  tests/ledger/ledger-fact-no-source); §A закрыл лазейку заглавной кириллицы."
echo "  Добавлено: ядро правды v0.1 (tests/truth_kernel) — вердикт выносит КОД"
echo "  против доверенного источника, адаптеры из белого списка (анти-ведро),"
echo "  3 красных теста + источник-врёт/невалидный/счастливый путь."
echo "  Честный предел ядра v0.1 (по ТЗ): НЕ ловит правдоподобную ложь там, где"
echo "  сам доверенный источник неполон/неверен (напр. Owner ошибся в ручной"
echo "  записи) — это не вина ядра, но названо явно."

if (( total_fail > 0 )); then
  echo ""
  echo "${C_RED}Провалившиеся тесты:${C_RST}"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  • ${t}"
  done
  exit 1
fi

echo ""
echo "${C_GREEN}Все тесты зелёные.${C_RST}"
exit 0
