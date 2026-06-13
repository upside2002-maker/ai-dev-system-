#!/usr/bin/env bash
# Self-check a HANDOFF file before submitting the task it belongs to.
#
# Checks:
#   1. Required header fields present and non-empty:
#      Date, From, To, Agent runtime, Model, Role mode, TASK, Status
#      → ERROR if any missing.
#   2. `Product repo status:` present with non-empty value.
#      → ERROR if missing.
#   3. Evidence rule (WARNING): any `PR #NN` or `YYYY-MM-DD` date in body
#      should have a git short hash ([a-f0-9]{7,}) on the same line.
#      Shown as warning, not blocker — some references are legit (future
#      dates, general epoch mentions). Author judges.
#   4. User-facing forbidden words (WARNING): inside <!-- user-facing -->
#      / <!-- /user-facing --> markers, no word from
#      policies/OPERATOR_LANGUAGE.md should appear outside backticks.
#      → WARNING. If markers absent — check skipped entirely.
#   5. Length (WARNING): if HANDOFF > 400 lines, suggest the author check
#      whether the file is retelling a journal.
#
# Exit codes:
#   0  — checks passed, possibly with warnings
#   1  — errors detected (caller's submit should refuse)
#   64 — usage error
#   66 — file not found
#
# Usage:
#   bash scripts/self-check-handoff.sh <handoff_file>
# or via make:
#   make self-check-handoff FILE=project-overlays/sitka-office/HANDOFFS/<f>.md

set -uo pipefail
# Note: 'set -e' is intentionally NOT enabled — we want to collect ALL
# violations before returning, not stop at the first one.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE — путь к HANDOFF .md (relative to repo root или absolute)

Example:
  $0 project-overlays/sitka-office/HANDOFFS/2026-05-12-worker-to-tl-some-task.md
EOF
}

if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
  echo "ERROR: нужно указать FILE" >&2
  usage
  exit 64
fi

FILE="$1"
if [[ "${FILE}" != /* ]]; then
  FILE="${ROOT_DIR}/${FILE}"
fi

if [[ ! -f "${FILE}" ]]; then
  echo "ERROR: файл не найден: ${FILE}" >&2
  exit 66
fi

ERRORS=0
WARNINGS=0

# --- helper: строки с датой рядом со словом о git-работе ---------------------
# Печатает строки вида `lineno:content` (формат grep -n) для тех строк файла,
# где есть YYYY-MM-DD И рядом слово о git-работе (commit/merge/выкат/задеплоен/…).
#
# Регистр складываем НЕ через `grep -i`: в пустой локали (скрипт зовут под
# `env -i LC_ALL=C`) grep -i НЕ сворачивает регистр кириллицы — «ВЫКАТ»
# заглавными проскальзывал мимо ключа «выкат» (это была лазейка). python3
# `.lower()` складывает кириллицу независимо от локали. Решение о совпадении
# принимаем по lower(строки), а печатаем ВСЕГДА исходную строку — регистр в
# отчёте не теряется. Латинские ключи покрывает тот же .lower().
#
# Без python3 — запасной grep с классами на первую букву (полностью-заглавную
# кириллицу так не закрыть, но без python3 лаборатория и так SKIP-ает зависимые
# тесты, а критпуть на машинах разработки python3 имеет всегда).
_git_word_date_lines() {
  local file="$1"
  if command -v python3 >/dev/null 2>&1; then
    grep -nE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "${file}" | python3 "${PY_GITWORD}"
  else
    grep -nE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "${file}" \
      | grep -iE 'commit|merg|deploy|push|master|landed|ship|releas|[Дд]еплой|[Зз]акоммич|[Сс]мерж|[Зз]адеплоен|[Вв]ыкат|[Вв]лит|[Зз]апушен|[Рр]елиз|[Оо]публик|[Оо]тгру|[Сс]лил|[Вв]ыло[жг]|[Вв]недр|[Ии]нтегрир'
  fi
}

# python3-фильтр пишем во временный файл (heredoc): держать многострочный
# `python3 -c` с круглыми скобками внутри process-substitution `<( … )` нельзя —
# скобки python-литерала ломают парность скобок подстановки в bash.
PY_GITWORD="$(mktemp)"
trap 'rm -f "${PY_GITWORD}"' EXIT
cat > "${PY_GITWORD}" <<'PYEOF'
import sys
# Ключи git-работы строчными. lower() кириллицы локале-независим (в т.ч. под C).
KEYS = ("commit", "merg", "deploy", "push", "master", "landed", "ship",
        "releas", "деплой", "закоммич", "смерж", "задеплоен", "выкат",
        "влит", "запушен", "релиз", "опублик", "отгру", "слил",
        "вылож", "вылог", "внедр", "интегрир")
for line in sys.stdin:
    low = line.lower()
    if any(k in low for k in KEYS):
        sys.stdout.write(line)
PYEOF

# Section header for output readability.
echo "Самопроверка передачи: ${FILE#"${ROOT_DIR}/"}"

# --- Check 1: required header fields ----------------------------------------
# Поля шапки HANDOFF — формат `- Field: value`. Пустое value = поле есть, но
# значения нет, что считаем ошибкой.
REQUIRED_FIELDS=("Date" "From" "To" "Agent runtime" "Model" "Role mode" "TASK" "Status")
for field in "${REQUIRED_FIELDS[@]}"; do
  # grep escape: поля типа 'Agent runtime' содержат пробел, regex такой как есть.
  if ! grep -qE "^- ${field}:[[:space:]]*[^[:space:]]" "${FILE}"; then
    echo "  [ERROR] поле '${field}:' отсутствует или пустое в шапке"
    ERRORS=$((ERRORS + 1))
  fi
done

# --- Check 2: Product repo status -------------------------------------------
# Поле живёт в секции Артефакты, может быть как обычной строкой, так и в bold:
#   - Product repo status: committed
#   **Product repo status (обязательно):** committed
# Считаем за «есть и не пусто», если в строке после `:` есть alphanumeric.
if ! grep -qE 'Product repo status[^:]*:.*[a-zA-Zа-яА-Я0-9]' "${FILE}"; then
  echo "  [ERROR] поле 'Product repo status:' отсутствует или без значения (см. templates/HANDOFFS_TEMPLATE.md)"
  ERRORS=$((ERRORS + 1))
fi

# --- Check 3: evidence rule (warning) ---------------------------------------
# Заявка о git-работе должна ссылаться на git short hash. Строку триггерим, если:
#   - на ней PR #NN (всегда), либо
#   - дата YYYY-MM-DD РЯДОМ со словом о git-работе (commit/merge/deploy/push/…).
# Голую дату (например, прогноз 2048-… в астрологическом HANDOFF) НЕ трогаем —
# у неё hash'а быть не может. Раньше ловили любую дату → 24 ложных WARN на
# returns-HANDOFF и привыкание не смотреть на предупреждения (alarm fatigue).
# Шапку файла (первые 15 строк) пропускаем.
EVIDENCE_VIOLATIONS=0
SHOWN=0
while IFS=: read -r line_num line_content; do
  # Skip header (first 15 lines) and metadata-only lines.
  (( line_num <= 15 )) && continue
  # Skip lines that contain a real git short hash already.
  # ВАЖНО: настоящий short hash должен содержать хотя бы одну hex-БУКВУ (a-f).
  # Прежний '\b[a-f0-9]{7,}\b' матчил и ЧИСТО ДЕСЯТИЧНОЕ 7+-значное число
  # ('Выкат 2026-06-10 1234567' гасило WARN фальшивым «хешем»). Требуем 7..40
  # hex-символов, среди которых есть хотя бы один a-f — десятичная дата/счётчик
  # больше не маскируется под хеш. (Полностью-цифровой git-хеш теоретически
  # возможен, но как доказательство git-работы он неотличим от любого числа —
  # ради этого правила-предупреждения требуем явный hex.)
  if echo "${line_content}" | grep -oiE '\b[0-9a-f]{7,40}\b' \
       | grep -qiE '[a-f]'; then
    continue
  fi
  EVIDENCE_VIOLATIONS=$((EVIDENCE_VIOLATIONS + 1))
  if (( SHOWN < 3 )); then
    echo "  [WARN] line ${line_num}: упоминание PR/даты без git short hash рядом"
    echo "         ${line_content}"
    SHOWN=$((SHOWN + 1))
  fi
done < <( {
  grep -nE 'PR #[0-9]+' "${FILE}"
  # Строки с датой, рядом с которыми есть git-слово (см. _git_word_date_lines).
  _git_word_date_lines "${FILE}"
} 2>/dev/null | sort -t: -k1,1n -u || true )

if (( EVIDENCE_VIOLATIONS > 0 )); then
  if (( EVIDENCE_VIOLATIONS > 3 )); then
    echo "  [WARN] всего ${EVIDENCE_VIOLATIONS} упоминаний без hash (показаны первые 3)"
  fi
  WARNINGS=$((WARNINGS + 1))
fi

# --- Check 4: user-facing forbidden words (warning) -------------------------
# Экстрактор зоны устойчив к двум обходам форматирования маркера:
#   (1) внутренние пробелы в маркере: '<!--   user-facing   -->' — регэксп
#       допускает [[:space:]]* вокруг ключевого слова, литеральное совпадение
#       больше не требуется;
#   (2) текст на одной строке с маркером: '<!-- user-facing --> accept … '
#       и '… commit <!-- /user-facing -->' — не делаем next, а вырезаем сам
#       маркер из строки и печатаем остаток, чтобы запрещённые слова, прижатые
#       к маркеру, попадали в зону, а не утекали молча.
# Открывающий и закрывающий маркеры различаем по наличию слэша перед 'user-facing'.
USER_FACING_BLOCK="$(awk '
  {
    line = $0
    is_open  = (line ~ /<!--[[:space:]]*user-facing[[:space:]]*-->/)
    is_close = (line ~ /<!--[[:space:]]*\/user-facing[[:space:]]*-->/)

    # Оба маркера на одной строке: текст МЕЖДУ ними — это зона целиком.
    # Пример: открытие-маркер, текст, закрытие-маркер в одной строке.
    if (is_open && is_close) {
      mid = line
      sub(/.*<!--[[:space:]]*user-facing[[:space:]]*-->/, "", mid)
      sub(/<!--[[:space:]]*\/user-facing[[:space:]]*-->.*/, "", mid)
      if (mid ~ /[^[:space:]]/) print mid
      flag = 0
      next
    }

    if (is_close) {
      # текст ДО закрывающего маркера ещё в зоне, если зона открыта
      if (flag) {
        pre = line
        sub(/<!--[[:space:]]*\/user-facing[[:space:]]*-->.*/, "", pre)
        if (pre ~ /[^[:space:]]/) print pre
      }
      flag = 0
      next
    }

    if (is_open) {
      # текст ПОСЛЕ открывающего маркера на той же строке — уже в зоне
      post = line
      sub(/.*<!--[[:space:]]*user-facing[[:space:]]*-->/, "", post)
      if (post ~ /[^[:space:]]/) print post
      flag = 1
      next
    }

    if (flag) print line
  }
' "${FILE}")"

if [[ -n "${USER_FACING_BLOCK}" ]]; then
  WORDS_FILE="${ROOT_DIR}/policies/OPERATOR_LANGUAGE.md"
  if [[ ! -f "${WORDS_FILE}" ]]; then
    echo "  [WARN] policies/OPERATOR_LANGUAGE.md не найден — пропускаю проверку запрещённых слов"
    WARNINGS=$((WARNINGS + 1))
  else
    # Извлечь плоский список запрещённых слов из ``` блока.
    WORDS="$(awk '
      /^```/ { in_block = !in_block; next }
      in_block && !/^[[:space:]]*#/ && NF { print }
    ' "${WORDS_FILE}")"

    # Убрать из user-facing блока всё в backticks (имена технических объектов — ок).
    # shellcheck disable=SC2016  # одинарные кавычки намеренно: sed-выражение литеральное
    STRIPPED="$(echo "${USER_FACING_BLOCK}" | sed -E 's/`[^`]*`//g')"

    FORBIDDEN_HITS=()
    while IFS= read -r word; do
      [[ -z "${word}" ]] && continue
      # Case-insensitive word-boundary search.
      if echo "${STRIPPED}" | grep -qiwF -- "${word}" 2>/dev/null; then
        FORBIDDEN_HITS+=("${word}")
      fi
    done <<< "${WORDS}"

    if (( ${#FORBIDDEN_HITS[@]} > 0 )); then
      WARNINGS=$((WARNINGS + 1))
      echo "  [WARN] в user-facing зоне найдены запрещённые слова (${#FORBIDDEN_HITS[@]}):"
      # Показываем до 10 первых, без дубликатов.
      printf '         %s\n' "${FORBIDDEN_HITS[@]}" | sort -u | head -10
      echo "         Полный список — policies/OPERATOR_LANGUAGE.md."
    fi
  fi
fi

# --- Check 5: length (warning) ----------------------------------------------
LINE_COUNT="$(wc -l < "${FILE}" | tr -d ' ')"
if (( LINE_COUNT > 400 )); then
  echo "  [WARN] HANDOFF длиной ${LINE_COUNT} строк (> 400) — подумай не пересказываешь ли журнал"
  WARNINGS=$((WARNINGS + 1))
fi

# --- Summary ----------------------------------------------------------------
echo ""
if (( ERRORS > 0 )); then
  echo "ERROR: ${ERRORS} ошибок, ${WARNINGS} предупреждений — самопроверка не прошла" >&2
  exit 1
fi

if (( WARNINGS > 0 )); then
  echo "OK: самопроверка прошла с ${WARNINGS} предупреждениями (не блокеры)"
else
  echo "OK: самопроверка прошла чисто"
fi
exit 0
