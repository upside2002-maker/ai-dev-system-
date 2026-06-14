# shellcheck shell=bash
# shellcheck disable=SC2034  # C_* цвета используются в run.sh, который source-ит файл
# Общие функции лаборатории проверок ворот.
#
# source-ится из run.sh (для счётчиков/цвета) и из каждого файла-теста
# (для assert-хелперов и make_tmp_repo). Сам по себе не исполняется —
# никакого `set -e` тут нет: режим раннера задаёт run.sh.
#
# Контракт с тестом:
#   - тест печатает первую строку `TEST <id> <COLOR> <короткое-имя>`;
#   - возвращает 0 если ожидание выполнено, 1 если нарушено;
#   - любую мутацию делает в WORK="$(mktemp -d)" под trap rm -rf.
#
# Лаборатория НИКОГДА не пишет в живой репозиторий: все мутирующие тесты
# работают на временных копиях, контракт-тесты — только test -e.

# Корень живого репо ai-dev-system (lib/ → evals/lab/ → evals/ → repo).
# Вычисляем от расположения этого файла, не от cwd.
LAB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${LAB_LIB_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${LAB_DIR}/../.." && pwd)"
export REPO_ROOT

# --- цвет --------------------------------------------------------------------
# ANSI только при TTY; текстовые маркеры [PASS]/[FAIL] дублируют цвет для логов.
if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
  C_DIM=$'\033[2m'
  C_RST=$'\033[0m'
else
  C_GREEN=""
  C_RED=""
  C_DIM=""
  C_RST=""
fi

# --- наличие инструментов ----------------------------------------------------
has_python3() { command -v python3 >/dev/null 2>&1; }
has_git()     { command -v git >/dev/null 2>&1; }

# --- assert-хелперы ----------------------------------------------------------
# Все печатают понятную диагностику в stdout при провале и возвращают 1.

# assert_exit <expected> <actual>
assert_exit() {
  local expected="$1" actual="$2"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "    assert_exit: ожидался код ${expected}, получен ${actual}"
    return 1
  fi
  return 0
}

# assert_exit_nonzero <actual> — для ворот-замка (точный код не фиксируем).
assert_exit_nonzero() {
  local actual="$1"
  if [[ "${actual}" == "0" ]]; then
    echo "    assert_exit_nonzero: ожидался ненулевой код, получен 0"
    return 1
  fi
  return 0
}

# assert_out_has <substr> <captured> — подстрока в захваченном stderr+stdout.
assert_out_has() {
  local substr="$1" captured="$2"
  if [[ "${captured}" != *"${substr}"* ]]; then
    echo "    assert_out_has: не найдена подстрока: ${substr}"
    echo "    --- захваченный вывод (первые 20 строк) ---"
    printf '%s\n' "${captured}" | head -20 | sed 's/^/      | /'
    echo "    --- конец вывода ---"
    return 1
  fi
  return 0
}

# assert_out_lacks <substr> <captured> — подстроки НЕ должно быть (анти-WARN).
assert_out_lacks() {
  local substr="$1" captured="$2"
  if [[ "${captured}" == *"${substr}"* ]]; then
    echo "    assert_out_lacks: подстрока присутствует, а не должна: ${substr}"
    echo "    --- захваченный вывод (первые 20 строк) ---"
    printf '%s\n' "${captured}" | head -20 | sed 's/^/      | /'
    echo "    --- конец вывода ---"
    return 1
  fi
  return 0
}

# assert_file_exists <path> — побочный эффект «файл на месте» (не перемещён).
assert_file_exists() {
  local path="$1"
  if [[ ! -e "${path}" ]]; then
    echo "    assert_file_exists: файл отсутствует (перемещён?): ${path}"
    return 1
  fi
  return 0
}

# assert_file_absent <path> — файл НЕ должен существовать.
assert_file_absent() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    echo "    assert_file_absent: файл существует, а не должен: ${path}"
    return 1
  fi
  return 0
}

# assert_unchanged <path> <sha-before> — содержимое файла не менялось.
# Доказывает отсутствие мутации (Status не тронут).
assert_unchanged() {
  local path="$1" sha_before="$2" sha_after
  if [[ ! -e "${path}" ]]; then
    echo "    assert_unchanged: файл исчез: ${path}"
    return 1
  fi
  sha_after="$(file_sha "${path}")"
  if [[ "${sha_after}" != "${sha_before}" ]]; then
    echo "    assert_unchanged: содержимое изменилось: ${path}"
    return 1
  fi
  return 0
}

# file_sha <path> — переносимый хэш содержимого (shasum / sha256sum / cksum).
file_sha() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${path}" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  else
    cksum "${path}" | awk '{print $1"-"$2}'
  fi
}

# --- временный репозиторий для мутирующих тестов -----------------------------
# make_tmp_repo — создаёт mktemp -d с минимальной раскладкой ai-dev-system:
#   копия указанного скрипта ворот + зависимые policies/*.md.
# Возвращает путь по stdout. Вызывающий обязан поставить trap на удаление.
#
# Аргументы: список относительных путей внутри репо, которые скопировать.
# Каталоги создаются автоматически.
make_tmp_repo() {
  local work
  work="$(mktemp -d)"
  local rel
  for rel in "$@"; do
    local src="${REPO_ROOT}/${rel}"
    local dst="${work}/${rel}"
    mkdir -p "$(dirname "${dst}")"
    cp "${src}" "${dst}"
  done
  printf '%s' "${work}"
}

# tmp_overlay_task <work> <slug> <header-block> <files-block>
# Пишет project-overlays/<slug>/TASKS/t.md в temp-репо с заданной шапкой и
# секцией Files. Возвращает абсолютный путь к файлу задачи по stdout.
tmp_overlay_task() {
  local work="$1" slug="$2" header="$3" files="$4"
  local dir="${work}/project-overlays/${slug}/TASKS"
  mkdir -p "${dir}"
  local f="${dir}/t.md"
  {
    printf '# TASK: lab-fixture\n\n'
    printf '%s\n' "${header}"
    printf '\n## Problem\n\nFixture task for lab.\n'
    printf '\n## Files\n\n%s\n' "${files}"
  } > "${f}"
  printf '%s' "${f}"
}

# make_git_repo_with_hook — создаёт temp git-репо с установленным commit-msg
# замком и baseline-коммитом (policies/USERS.md из живого репо). Возвращает путь.
# Baseline-коммит подписан Approved-by: upside2002@gmail.com (USERS.md в зоне
# policies/ — критпуть, иначе baseline сам бы упёрся в замок). git init с тихими
# настройками идентичности, чтобы не зависеть от глобального git config.
make_git_repo_with_hook() {
  local work
  work="$(mktemp -d)"
  git -C "${work}" init -q
  git -C "${work}" config user.email "upside2002@gmail.com"
  git -C "${work}" config user.name "Lab Owner"
  git -C "${work}" config commit.gpgsign false
  # Замок ожидает себя в .githooks/commit-msg относительно корня репо.
  mkdir -p "${work}/.githooks" "${work}/policies"
  cp "${REPO_ROOT}/.githooks/commit-msg" "${work}/.githooks/commit-msg"
  chmod +x "${work}/.githooks/commit-msg"
  cp "${REPO_ROOT}/policies/USERS.md" "${work}/policies/USERS.md"
  git -C "${work}" config core.hooksPath .githooks
  # Baseline: USERS.md — критпуть, поэтому подписываем владельцем.
  # Вывод замка на baseline-коммите глушим (>/dev/null 2>&1): он легитимен
  # (критпуть подписан), но его строка не должна попасть ни в один захват теста.
  git -C "${work}" add policies/USERS.md .githooks/commit-msg
  git -C "${work}" commit -q -m $'baseline: USERS.md + hook\n\nApproved-by: upside2002@gmail.com' >/dev/null 2>&1
  printf '%s' "${work}"
}

# make_selfcheck_repo — temp-репо для self-check-handoff.sh: копия скрипта +
# policies/OPERATOR_LANGUAGE.md. Возвращает путь.
make_selfcheck_repo() {
  make_tmp_repo scripts/self-check-handoff.sh policies/OPERATOR_LANGUAGE.md
}

# write_handoff_fixture <work> <extra-body-lines...>
# Кладёт project-overlays/demo/HANDOFFS/h.md из шаблона шапки (>15 строк) +
# дополнительные строки тела (под правило evidence/user-facing). Возвращает путь.
write_handoff_fixture() {
  local work="$1"; shift
  local dir="${work}/project-overlays/demo/HANDOFFS"
  mkdir -p "${dir}"
  local f="${dir}/h.md"
  cp "${LAB_DIR}/fixtures/handoff_header.txt" "${f}"
  local line
  for line in "$@"; do
    printf '%s\n' "${line}" >> "${f}"
  done
  printf '%s' "${f}"
}

# git_head_count <repo> — число коммитов в HEAD (для доказательства «коммит не создан»).
git_head_count() {
  git -C "$1" rev-list --count HEAD 2>/dev/null || echo 0
}

# tmp_handoff <work> <slug> <name> <body> — кладёт HANDOFF в overlay.
tmp_handoff() {
  local work="$1" slug="$2" name="$3" body="$4"
  local dir="${work}/project-overlays/${slug}/HANDOFFS"
  mkdir -p "${dir}"
  printf '%s\n' "${body}" > "${dir}/${name}"
  printf '%s' "${dir}/${name}"
}

# --- временный реестр для тестов валидатора aida check -----------------------
# Валидатор (scripts/aida check) читает каталог реестра из переменной окружения
# AIDA_LEDGER_DIR (по умолчанию — живой ledger/). Тесты подставляют СВОЙ
# временный каталог: живой ledger/ так не трогается ни на чтение-как-цель, ни на
# запись. Сам валидатор — pure-python (enum'ы/обязательные поля проверяет кодом,
# schema-файлы во время check не читает), поэтому temp-каталога с *.jsonl хватает.

# make_tmp_ledger — пустой mktemp -d под реестр. Вызывающий ставит trap на rm.
make_tmp_ledger() {
  mktemp -d
}

# ledger_write <dir> <file-basename> <line...> — дописать строки в файл реестра.
# file-basename: facts.jsonl | decisions.jsonl | inbox.jsonl | contradictions.jsonl.
ledger_write() {
  local dir="$1" base="$2"; shift 2
  local line
  for line in "$@"; do
    printf '%s\n' "${line}" >> "${dir}/${base}"
  done
}

# run_aida_check <ledger-dir> — прогнать ЖИВОЙ scripts/aida check против
# указанного каталога реестра. Печатает stdout+stderr; код выхода — у caller'а
# через $?. Живой ledger/ не задействован (AIDA_LEDGER_DIR перекрывает путь).
run_aida_check() {
  local dir="$1"
  AIDA_LEDGER_DIR="${dir}" bash "${REPO_ROOT}/scripts/aida" check 2>&1
}

# run_aida_action <ledger-dir> [args...] — прогнать ЖИВОЙ защищённый адаптер
# записи (scripts/aida action) против временного каталога реестра. args — флаги
# --kind/--target/--change (и при нужде глобальный --by ПЕРЕД 'action'). Печатает
# stdout+stderr; код выхода у caller'а через $?. Живой ledger/ не задействован.
# Так тест доказывает: ядро исполняет РОВНО заявку и пишет requested+executed во
# ВРЕМЕННЫЙ журнал/наблюдаемую зону, а не в живой репозиторий.
run_aida_action() {
  local dir="$1"; shift
  AIDA_LEDGER_DIR="${dir}" bash "${REPO_ROOT}/scripts/aida" "$@" 2>&1
}

# observed_marker <ledger-dir> <target> — путь к маркеру наблюдаемой зоны (мир),
# куда адаптер marker.write кладёт содержимое. Тесты сверки-с-миром правят этот
# файл напрямую, имитируя обход ядра («сказал А — сделал Б» / прямая запись).
observed_marker() {
  printf '%s' "$1/observed/$2"
}

# run_aida_brief <ledger-dir> [args...] — прогнать ЖИВОЙ scripts/aida-brief в
# ОФЛАЙН-режиме (AIDA_BRIEF_NO_PROJECTS=1): реестр-ядро читается из переданного
# каталога (AIDA_LEDGER_DIR на фикстуру), а живой обход проектов (git-снимки
# sitka/astro/crypto) и почта ПРОПУСКАЮТСЯ. Так тест детерминирован и быстр (без
# хождения по живым репозиториям и ящику — раньше отсюда зависание на 180с), но
# логика честной деградации И-3 (пусто-vs-недоступно реестра) проверяется в
# точности как раньше. Живой ledger/ не тронут. Печатает stdout+stderr; код
# выхода — у caller'а через $?.
run_aida_brief() {
  local dir="$1"; shift
  AIDA_LEDGER_DIR="${dir}" AIDA_BRIEF_NO_PROJECTS=1 \
    bash "${REPO_ROOT}/scripts/aida-brief" "$@" 2>&1
}

# seed_fixture_ledger <dir> — заполнить каталог реестра минимальной ВАЛИДНОЙ
# фикстурой: одно активное решение (D-…), один не-stale факт с источником,
# пустые contradictions/inbox. Достаточно, чтобы `aida show` отдал непустой
# экран с записью решения (PASS-тесты про непустоту и операторскую подачу). Все
# поля синтетические, привязок к живым проектам нет. Живой ledger/ не задействован.
seed_fixture_ledger() {
  local dir="$1"
  ledger_write "${dir}" decisions.jsonl \
    '{"basis":["фикстура лаборатории"],"decided_at":"2026-06-13","decided_by":"owner","decision":"Фикстурное активное решение для теста слоя регидратации.","id":"D-20260613-001","recorded_at":"2026-06-13T10:00:00-05:00","recorded_by":"owner","review_when":"никогда (фикстура)","scope":"crypto","status":"active","supersedes":null}'
  ledger_write "${dir}" facts.jsonl \
    '{"checked_at":"2026-06-13","confidence":"high","expires":null,"id":"F-20260613-001","origin":null,"recorded_at":"2026-06-13T10:00:00-05:00","recorded_by":"owner","scope":"crypto","source":{"kind":"command","quote":"фикстурный источник факта","ref":"lab fixture"},"statement":"Фикстурный не-stale факт с источником.","status":"verified","supersedes":null}'
  : > "${dir}/contradictions.jsonl"
  : > "${dir}/inbox.jsonl"
}

# --- стоп-хук русского языка ru_guard.py -------------------------------------
# ru_guard читает на stdin JSON {"transcript_path": "<файл.jsonl>"} и при
# нарушении печатает на stdout {"decision": "block", "reason": "..."} (exit 0
# ВСЕГДА — хук не должен заклинить сессию). Признак блока — подстрока
# '"decision": "block"' в stdout; её ОТСУТСТВИЕ = пропуск. Код выхода не
# различает блок/пропуск, поэтому тесты смотрят именно stdout.

# ru_transcript <work> <assistant-text> — собрать минимальный транскрипт-файл
# (один настоящий ход пользователя + один ход ассистента с переданным текстом)
# и вернуть его путь по stdout. ВАЖНО: assistant-text подаётся как СЫРОЙ текст,
# в JSON его кладёт python json.dumps — без проблем с кавычками/экранированием.
ru_transcript() {
  local work="$1" text="$2"
  local f="${work}/transcript.jsonl"
  TR_TEXT="${text}" python3 - "${f}" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
text = os.environ["TR_TEXT"]
with open(path, "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"type": "user",
                         "message": {"role": "user", "content": "Тестовый вопрос."}},
                        ensure_ascii=False) + "\n")
    fh.write(json.dumps({"type": "assistant",
                         "message": {"role": "assistant", "content": text}},
                        ensure_ascii=False) + "\n")
PYEOF
  printf '%s' "${f}"
}

# run_ru_guard <transcript-path> — скормить хуку путь к транскрипту, вернуть его
# stdout (где блок/пусто). Код выхода у caller'а через $? (всегда 0 у хука).
run_ru_guard() {
  local tr="$1"
  printf '{"transcript_path": "%s"}' "${tr}" \
    | python3 "${REPO_ROOT}/.claude/hooks/ru_guard.py" 2>&1
}

# --- ядро правды aida_kernel.py ---------------------------------------------
# Ядро выносит ВЕРДИКТ по claim (JSON) детерминированным кодом против доверенного
# источника (анти-ведро: модель выбирает адаптер из белого списка, не подаёт
# команду). Тесты гоняют ЖИВОЙ scripts/aida-kernel, но источники подменяют на
# ВРЕМЕННЫЕ через переменные окружения — живой ledger/, реестр возможностей и
# журнал ошибок не трогаются:
#   AIDA_LEDGER_DIR        — временный каталог реестра (структурная память);
#   AIDA_CAPABILITIES_FILE — файл реестра возможностей (берём ЖИВОЙ из репо —
#                            это часть поставки ядра, не мутируется чтением);
#   AIDA_MODEL_ERRORS_FILE — временный журнал пойманной лжи (gate дозаписывает).
# Код выхода ядра кодирует вердикт машинно: 0 passed, 3 unverified, 4 stop.

# kernel_caps_file — путь к ЖИВОМУ реестру возможностей репо (источник для
# адаптера capability.exists и capability-ворот). Только чтение.
kernel_caps_file() {
  printf '%s' "${REPO_ROOT}/PROJECTS/capabilities.json"
}

# run_aida_kernel <subcmd> <ledger-dir> <errors-file> [args...] — прогнать ЖИВОЙ
# scripts/aida-kernel с временными источниками. claim подаётся caller'ом на stdin.
# Печатает stdout+stderr; код выхода (вердикт) у caller'а через $?.
run_aida_kernel() {
  local subcmd="$1" led="$2" errf="$3"; shift 3
  AIDA_LEDGER_DIR="${led}" \
  AIDA_CAPABILITIES_FILE="$(kernel_caps_file)" \
  AIDA_MODEL_ERRORS_FILE="${errf}" \
    bash "${REPO_ROOT}/scripts/aida-kernel" "${subcmd}" --json "$@" 2>&1
}

# seed_memory_fact <ledger-dir> <key> <value> [valid_until] — дозаписать факт
# структурной памяти (через ЖИВОЙ aida_ledger) во временный реестр. valid_until
# опционально (временная опора). Используется тестами контекст/память/источник.
seed_memory_fact() {
  local led="$1" key="$2" value="$3" valid_until="${4:-}"
  # valid_until опционально. Под `set -u` пустой массив "${arr[@]}" в старом bash
  # (macOS bash 3.2) роняет «unbound variable», поэтому ветвим вызов, а не
  # раскрываем потенциально пустой массив.
  if [[ -n "${valid_until}" ]]; then
    AIDA_LEDGER_DIR="${led}" python3 "${REPO_ROOT}/scripts/aida_ledger.py" \
      fact "память: ${key}=${value}" \
      --scope system --source-kind human --source-ref owner \
      --key "${key}" --value "${value}" --valid-until "${valid_until}" >/dev/null 2>&1
  else
    AIDA_LEDGER_DIR="${led}" python3 "${REPO_ROOT}/scripts/aida_ledger.py" \
      fact "память: ${key}=${value}" \
      --scope system --source-kind human --source-ref owner \
      --key "${key}" --value "${value}" >/dev/null 2>&1
  fi
}

# Захват вывода и кода выхода в тестах делается inline, без хелпера:
#   OUT="$(bash some.sh arg 2>&1)"; RC=$?
# (через $() протащить и stdout, и rc одним хелпером нельзя — subshell.)
