#!/usr/bin/env bash
# Take a project shift lock. After successful run, the caller is the active
# project lead (Holder) until either release-shift or the expiry window passes.
#
# Atomic from caller's perspective: refuses on precondition failure before
# any mutation. If push to backup fails (someone got there first), the user
# is told to reset and re-evaluate.
#
# Usage:
#   bash scripts/take-shift.sh SLUG SCOPE [HOURS]
# or via make:
#   make take-shift SLUG=sitka-office SCOPE="разбор передачи"
#   make take-shift SLUG=sitka-office SCOPE="..." HOURS=4
#
# Default HOURS=8 (typical shift length).
# Email is taken from `git config user.email`.
#
# Pulls the latest TL_SHIFT.md from backup before reading, so the decision
# (free / occupied) is made on the freshest state. Pushes the new state on
# success — if push is rejected (non-fast-forward), someone else took the
# shift in parallel; user resets to backup/<branch> and retries if needed.
#
# Refuses on:
#   - missing SLUG / SCOPE / non-integer or zero HOURS
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TL_SHIFT.md missing inside overlay
#   - git config user.email empty
#   - rebase on backup/<branch> conflicts (manual resolution required)
#   - shift held by another user with non-expired Expires
#   - push to backup rejected (race lost)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG SCOPE [HOURS]
  SLUG   — overlay slug (e.g. sitka-office, astro)
  SCOPE  — короткое описание зоны работы на смену, на простом русском
  HOURS  — длина смены в часах (по умолчанию: 8)

Examples:
  $0 sitka-office "разбор передачи от dm-7-c"
  $0 astro "первая задача Phase 0.1" 4
EOF
}

if [[ $# -lt 2 ]] || [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
  echo "ERROR: нужно указать SLUG и SCOPE" >&2
  usage
  exit 64  # EX_USAGE
fi

SLUG="$1"
SCOPE="$2"
HOURS="${3:-8}"

if ! [[ "${HOURS}" =~ ^[0-9]+$ ]] || (( HOURS < 1 )); then
  echo "ERROR: HOURS должно быть целым положительным числом (получено: '${HOURS}')" >&2
  exit 65  # EX_DATAERR
fi

OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: папка проекта не найдена: ${OVERLAY}" >&2
  exit 65
fi

LOCK_FILE="${OVERLAY}/TL_SHIFT.md"
if [[ ! -f "${LOCK_FILE}" ]]; then
  echo "ERROR: файл смены не найден: ${LOCK_FILE}" >&2
  echo "       Создай его руками по стандартному шаблону перед первым использованием." >&2
  exit 65
fi

EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
if [[ -z "${EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой — установи email перед взятием смены" >&2
  exit 65
fi

BRANCH="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"

# Подтянуть последние изменения с резервной копии (если ветка там есть).
# Пропускается при AIDS_SKIP_PUSH=1 — тестовый режим без сетевой работы.
if [[ "${AIDS_SKIP_PUSH:-0}" == "1" ]]; then
  echo "  (rebase на backup пропущен — AIDS_SKIP_PUSH=1, режим тестирования)"
elif git -C "${ROOT_DIR}" fetch backup "${BRANCH}" 2>/dev/null; then
  echo "Подтягиваю последние изменения из резервной копии (ветка ${BRANCH})..."
  if ! git -C "${ROOT_DIR}" rebase "backup/${BRANCH}"; then
    echo "ERROR: rebase на backup/${BRANCH} не прошёл — разреши конфликты руками и попробуй снова" >&2
    git -C "${ROOT_DIR}" rebase --abort 2>/dev/null || true
    exit 75
  fi
else
  echo "  ветка ${BRANCH} ещё не на резервной копии — пропускаю rebase"
fi

# Прочитать текущее состояние смены ПОСЛЕ rebase.
RELEASED="$(grep -m1 -E '^- Released:' "${LOCK_FILE}" | sed -E 's/^- Released:[[:space:]]*//' | awk '{print $1}')"
HOLDER_LINE="$(grep -m1 -E '^- Holder:' "${LOCK_FILE}" | sed -E 's/^- Holder:[[:space:]]*//')"
EXPIRES_LINE="$(grep -m1 -E '^- Expires:' "${LOCK_FILE}" | sed -E 's/^- Expires:[[:space:]]*//')"

# Текущее время и время истечения новой смены.
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
NOW_EPOCH="$(date '+%s')"
EXPIRES_NEW_EPOCH=$(( NOW_EPOCH + HOURS * 3600 ))
# macOS BSD date: -r epoch; GNU date: -d @epoch.
EXPIRES_NEW="$(date -r "${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
              || date -d "@${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S')"

# Свободна или истекла?
SHIFT_FREE="no"
EXPIRY_REASON=""
if [[ "${RELEASED}" == "yes" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="смена была свободна"
elif [[ -z "${HOLDER_LINE}" ]] || [[ "${HOLDER_LINE}" == "(нет)" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="поле Holder было пустым"
elif [[ -n "${EXPIRES_LINE}" ]] && [[ "${EXPIRES_LINE}" != "(нет)" ]]; then
  EXPIRES_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || date -d "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || echo "0")"
  if (( EXPIRES_EPOCH > 0 )) && (( EXPIRES_EPOCH < NOW_EPOCH )); then
    SHIFT_FREE="yes"
    EXPIRY_REASON="срок предыдущей смены истёк (был до ${EXPIRES_LINE})"
  fi
fi

if [[ "${SHIFT_FREE}" != "yes" ]]; then
  echo "ERROR: смена занята" >&2
  echo "  главный: ${HOLDER_LINE}" >&2
  echo "  до:      ${EXPIRES_LINE}" >&2
  echo "  сейчас:  ${NOW}" >&2
  echo "" >&2
  echo "       Если нужно перехватить — потребуется экстренное прерывание" >&2
  echo "       (добавляется в коммите 2 плана; пока недоступно). Иначе" >&2
  echo "       договорись с текущим главным или дождись истечения срока." >&2
  exit 75
fi

# Записать новое состояние смены.
cat > "${LOCK_FILE}" <<EOF
# Смена главного по проекту — ${SLUG}

- Released: no
- Holder: ${EMAIL}
- Started: ${NOW}
- Expires: ${EXPIRES_NEW}
- Scope: ${SCOPE}
- Active TASK: (нет)

## Notes

_(заметки появляются при освобождении смены через \`make release-shift\`)_
EOF

# Сохранить в журнал репозитория и отправить в резервную копию.
RELATIVE_LOCK="${LOCK_FILE#"${ROOT_DIR}/"}"
(
  cd "${ROOT_DIR}"
  git add "${RELATIVE_LOCK}"
  git commit -m "shift(${SLUG}): take by ${EMAIL} for ${HOURS}h — ${SCOPE}" >/dev/null

  if [[ "${AIDS_SKIP_PUSH:-0}" == "1" ]]; then
    echo "  (push в backup пропущен — AIDS_SKIP_PUSH=1, режим тестирования)"
  elif PUSH_OUT="$(git push backup "${BRANCH}" 2>&1)"; then
    echo "${PUSH_OUT}" | tail -2
  else
    echo "${PUSH_OUT}" >&2
    if echo "${PUSH_OUT}" | grep -qE 'rejected|non-fast-forward'; then
      echo "" >&2
      echo "ERROR: кто-то опередил тебя — резервная копия отказалась принимать запись" >&2
      echo "  Чтобы откатить локальное состояние и увидеть кто записался первым:" >&2
      echo "    git -C ${ROOT_DIR} reset --hard backup/${BRANCH}" >&2
      echo "  После отката посмотри новый TL_SHIFT.md и реши, нужна ли смена сейчас." >&2
      exit 75
    else
      echo "ERROR: push backup ${BRANCH} не удался — посмотри ошибку выше" >&2
      exit 75
    fi
  fi
) || exit $?

echo ""
echo "OK: смена взята (${EXPIRY_REASON})"
echo "  проект:  ${SLUG}"
echo "  главный: ${EMAIL}"
echo "  до:      ${EXPIRES_NEW}"
echo "  зона:    ${SCOPE}"
echo ""
echo "Освободить смену: make release-shift SLUG=${SLUG} NOTES=\"...\""
