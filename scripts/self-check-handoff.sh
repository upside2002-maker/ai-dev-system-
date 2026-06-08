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
  # Skip lines that contain a short hash already.
  if echo "${line_content}" | grep -qE '\b[a-f0-9]{7,}\b'; then
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
  grep -nE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "${FILE}" \
    | grep -iE 'commit|merg|deploy|push|master|landed|ship|закоммич|смерж|задеплоен|влит|выкат|запушен'
} 2>/dev/null | sort -t: -k1,1n -u || true )

if (( EVIDENCE_VIOLATIONS > 0 )); then
  if (( EVIDENCE_VIOLATIONS > 3 )); then
    echo "  [WARN] всего ${EVIDENCE_VIOLATIONS} упоминаний без hash (показаны первые 3)"
  fi
  WARNINGS=$((WARNINGS + 1))
fi

# --- Check 4: user-facing forbidden words (warning) -------------------------
USER_FACING_BLOCK="$(awk '
  /<!-- user-facing -->/ { flag=1; next }
  /<!-- \/user-facing -->/ { flag=0; next }
  flag { print }
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
