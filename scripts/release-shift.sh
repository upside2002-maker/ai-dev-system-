#!/usr/bin/env bash
# Сдать ведение проекта. Caller must be the current Holder (or ведение
# already free — no-op error). Appends NOTES entry into `## Notes` and
# resets Holder/Started/Expires/Scope.
#
# Usage:
#   bash scripts/release-shift.sh SLUG NOTES
# or via make:
#   make release-shift SLUG=sitka-office NOTES="что сделано за период ведения"
#
# NOTES is mandatory and non-empty: короткое описание того, что сделано
# за период ведения — для второго разработчика, когда он подхватит проект.
# Ленивые сдачи теряют ценность; gate требует хотя бы одну фразу.
#
# Refuses on:
#   - missing SLUG / empty NOTES
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TL_SHIFT.md missing
#   - git config user.email empty
#   - ведение уже свободно (Released: yes — нечего сдавать)
#   - caller email != Holder email (cannot release someone else's ведение)
#
# Push в обе копии (origin + backup) через scripts/_push_helper.sh.
# Если origin отверг — fatal (расхождение с источником правды).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG NOTES
  SLUG   — overlay slug (e.g. sitka-office, astro)
  NOTES  — короткое описание что сделано за период ведения, непустое

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
  echo "ERROR: файл ведения не найден: ${LOCK_FILE}" >&2
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
  echo "ERROR: ведение уже свободно — нечего сдавать" >&2
  echo "  файл: ${LOCK_FILE#"${ROOT_DIR}/"}" >&2
  exit 65
fi

if [[ "${HOLDER}" != "${EMAIL}" ]]; then
  echo "ERROR: ведение не твоё — сдавать чужое нельзя" >&2
  echo "  текущий держатель: ${HOLDER}" >&2
  echo "  ты:                ${EMAIL}" >&2
  echo "  Если нужно забрать его ведение — потребуется экстренное прерывание:" >&2
  echo "    OVERRIDE=yes REASON=\"причина\" make take-shift SLUG=${SLUG} SCOPE=\"...\"" >&2
  echo "  Право на прерывание есть только у владельца (см. policies/USERS.md)." >&2
  exit 65
fi

NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# Извлечь существующие секции из файла ДО перезаписи. Override history и
# существующие заметки — накопительные, должны сохраняться. Leading blank
# lines режутся awk-фильтром `NF || p; NF{p=1}` (печатать строку если она
# непустая, или если уже была непустая раньше) — иначе двойные пустые
# строки нарастают на каждый цикл release.
EXISTING_OVERRIDE_HISTORY="$(awk '/^## Override history/{flag=1; next} flag && /^## /{flag=0} flag' "${LOCK_FILE}" \
                              | awk 'NF || p; NF{p=1}')"
EXISTING_NOTES="$(awk '/^## Notes/{flag=1; next} flag' "${LOCK_FILE}" \
                  | sed -E '/^_\(заметки появляются.*\)_$/d' \
                  | awk 'NF || p; NF{p=1}')"

# Записать новое состояние: шапка с Released=yes, опц. override history,
# новая запись в Notes наверху + старые заметки под ней.
{
  cat <<EOF
# Ведение проекта — ${SLUG}

- Released: yes
- Holder: (нет)
- Started: (нет)
- Expires: (нет)
- Scope: (нет)
- Active TASK: (нет)
EOF

  if [[ -n "$(echo "${EXISTING_OVERRIDE_HISTORY}" | tr -d '[:space:]')" ]]; then
    echo ""
    echo "## Override history"
    echo ""
    echo "${EXISTING_OVERRIDE_HISTORY}"
  fi

  cat <<EOF

## Notes

### ${NOW} — ${EMAIL}

- Зона ведения: ${PREV_SCOPE}
- Начало:       ${PREV_STARTED}
- Заметки:      ${NOTES}
EOF

  if [[ -n "$(echo "${EXISTING_NOTES}" | tr -d '[:space:]')" ]]; then
    echo ""
    echo "${EXISTING_NOTES}"
  fi
} > "${LOCK_FILE}"

# Commit + двойная отправка (origin + backup) через scripts/_push_helper.sh.
BRANCH="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"
RELATIVE_LOCK="${LOCK_FILE#"${ROOT_DIR}/"}"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/_push_helper.sh"
(
  cd "${ROOT_DIR}"
  git add "${RELATIVE_LOCK}"
  git commit -m "shift(${SLUG}): release by ${EMAIL} — ${NOTES}" >/dev/null

  if ! push_both "${BRANCH}"; then
    echo "" >&2
    echo "ERROR: отправка не прошла — сдача ведения сохранена локально, но не синхронизирована." >&2
    echo "  Если origin отверг — подтяни свежее:" >&2
    echo "    git -C ${ROOT_DIR} pull --rebase origin ${BRANCH}" >&2
    echo "  Затем 'git push origin ${BRANCH} && git push backup ${BRANCH}' вручную." >&2
    exit 75
  fi
) || exit $?

echo ""
echo "OK: ведение сдано"
echo "  проект:    ${SLUG}"
echo "  держатель: ${EMAIL}"
echo "  заметки:   ${NOTES}"
