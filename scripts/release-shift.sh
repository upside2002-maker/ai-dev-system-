#!/usr/bin/env bash
# Release a project shift lock. Caller must be the current Holder (or shift
# must be already free — in which case it's a no-op error). Appends NOTES
# entry into `## Notes` section and resets Holder/Started/Expires/Scope.
#
# Usage:
#   bash scripts/release-shift.sh SLUG NOTES
# or via make:
#   make release-shift SLUG=sitka-office NOTES="что сделано за смену"
#
# NOTES is mandatory and non-empty: it's the short message to the other dev
# about what got done during this shift. Lazy releases lose value; the gate
# forces at least one sentence.
#
# Refuses on:
#   - missing SLUG / empty NOTES
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TL_SHIFT.md missing
#   - git config user.email empty
#   - shift already free (Released: yes — nothing to release)
#   - caller email != Holder email (cannot release someone else's shift)
#
# Push failure on backup is soft: the release is saved locally; the user is
# told how to push manually. Rationale: release is less time-critical than
# take, and never racing for ownership.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG NOTES
  SLUG   — overlay slug (e.g. sitka-office, astro)
  NOTES  — короткое описание что сделано за смену, непустое

Example:
  $0 sitka-office "разобрал передачу, поставил TASK dm-7-c-foo"
EOF
}

if [[ $# -lt 2 ]] || [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
  echo "ERROR: нужно указать SLUG и непустое NOTES" >&2
  usage
  exit 64
fi

SLUG="$1"
NOTES="$2"

OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: папка проекта не найдена: ${OVERLAY}" >&2
  exit 65
fi

LOCK_FILE="${OVERLAY}/TL_SHIFT.md"
if [[ ! -f "${LOCK_FILE}" ]]; then
  echo "ERROR: файл смены не найден: ${LOCK_FILE}" >&2
  exit 65
fi

EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
if [[ -z "${EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой" >&2
  exit 65
fi

# Прочитать текущее состояние.
RELEASED="$(grep -m1 -E '^- Released:' "${LOCK_FILE}" | sed -E 's/^- Released:[[:space:]]*//' | awk '{print $1}')"
HOLDER="$(grep -m1 -E '^- Holder:' "${LOCK_FILE}" | sed -E 's/^- Holder:[[:space:]]*//')"
PREV_SCOPE="$(grep -m1 -E '^- Scope:' "${LOCK_FILE}" | sed -E 's/^- Scope:[[:space:]]*//')"
PREV_STARTED="$(grep -m1 -E '^- Started:' "${LOCK_FILE}" | sed -E 's/^- Started:[[:space:]]*//')"

if [[ "${RELEASED}" == "yes" ]]; then
  echo "ERROR: смена уже свободна — нечего освобождать" >&2
  echo "  файл: ${LOCK_FILE#"${ROOT_DIR}/"}" >&2
  exit 65
fi

if [[ "${HOLDER}" != "${EMAIL}" ]]; then
  echo "ERROR: смена не твоя — освобождать чужую нельзя" >&2
  echo "  текущий главный: ${HOLDER}" >&2
  echo "  ты:              ${EMAIL}" >&2
  echo "  Если нужно прервать его смену — потребуется экстренное прерывание" >&2
  echo "  (добавляется в коммите 2 плана; пока недоступно)." >&2
  exit 65
fi

NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# Достать существующие notes (всё после строки "## Notes").
# Уберём leading плейсхолдер если он есть.
EXISTING_NOTES="$(awk '/^## Notes/{flag=1;next} flag' "${LOCK_FILE}" \
                  | sed -E '/^_\(заметки появляются.*\)_$/d' \
                  | awk 'NF || p; NF{p=1}')"

# Записать новое состояние.
{
  cat <<EOF
# Смена главного по проекту — ${SLUG}

- Released: yes
- Holder: (нет)
- Started: (нет)
- Expires: (нет)
- Scope: (нет)
- Active TASK: (нет)

## Notes

### ${NOW} — ${EMAIL}

- Зона смены: ${PREV_SCOPE}
- Начало:     ${PREV_STARTED}
- Заметки:    ${NOTES}
EOF

  if [[ -n "$(echo "${EXISTING_NOTES}" | tr -d '[:space:]')" ]]; then
    echo ""
    echo "${EXISTING_NOTES}"
  fi
} > "${LOCK_FILE}"

# Commit + push.
BRANCH="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"
RELATIVE_LOCK="${LOCK_FILE#"${ROOT_DIR}/"}"
(
  cd "${ROOT_DIR}"
  git add "${RELATIVE_LOCK}"
  git commit -m "shift(${SLUG}): release by ${EMAIL} — ${NOTES}" >/dev/null

  if [[ "${AIDS_SKIP_PUSH:-0}" == "1" ]]; then
    echo "  (push в backup пропущен — AIDS_SKIP_PUSH=1, режим тестирования)"
  elif PUSH_OUT="$(git push backup "${BRANCH}" 2>&1)"; then
    echo "${PUSH_OUT}" | tail -2
  else
    echo "${PUSH_OUT}" >&2
    echo "" >&2
    echo "WARN: push backup ${BRANCH} не удался — освобождение сохранено локально" >&2
    echo "      попробуй push вручную:" >&2
    echo "        git -C ${ROOT_DIR} push backup ${BRANCH}" >&2
  fi
)

echo ""
echo "OK: смена освобождена"
echo "  проект:  ${SLUG}"
echo "  главный: ${EMAIL}"
echo "  заметки: ${NOTES}"
