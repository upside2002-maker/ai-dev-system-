#!/usr/bin/env bash
# Submit a TASK for review: bump `- Status:` from open|in-progress → review.
# Worker (or any role finishing TASK execution) calls this as the formal
# self-submit step instead of asking TL to manually edit Status.
#
# Pairs with accept-task.sh: submit-task does open|in-progress → review,
# accept-task does review → done. Together they close the loop without
# requiring TL to ever touch Status by hand.
#
# Usage:
#   bash scripts/submit-task.sh project-overlays/sitka-office/TASKS/<file>.md
# or via make:
#   make submit-task FILE=project-overlays/sitka-office/TASKS/<file>.md
#
# Refuses on:
#   - missing FILE arg
#   - file not found
#   - path not project-overlays/<slug>/TASKS/<file>.md (no nested dirs, not archive/)
#   - basename == README.md (folder docs, not a TASK)
#   - no `- Status:` line in file (malformed task)
#   - Status not in {open, in-progress} (already review/done/rejected — submit is no-op or wrong stage)
#   - Ready != yes (DRAFT/blocked TASK cannot be submitted; raise Ready: yes first)
#
# Does NOT move file (file stays in TASKS/, only archive on accept-task).
# Does NOT touch OPERATING.md.
# Does NOT validate that HANDOFF exists — that's Worker's responsibility per
# .claude/agents/sitka-worker.md (HANDOFF must be written before submit-task).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE — path to TASK .md inside project-overlays/<slug>/TASKS/
         (relative to repo root or absolute; NOT inside archive/, NOT README.md)

Example:
  $0 project-overlays/sitka-office/TASKS/2026-05-06-foo.md
EOF
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "ERROR: FILE argument required" >&2
  usage
  exit 64  # EX_USAGE
fi

FILE="$1"

# Resolve to absolute path against repo root if not already absolute.
if [[ "${FILE}" != /* ]]; then
  FILE="${ROOT_DIR}/${FILE}"
fi

if [[ ! -f "${FILE}" ]]; then
  echo "ERROR: file not found: ${FILE}" >&2
  exit 66  # EX_NOINPUT
fi

# Path must match: .../project-overlays/<slug>/TASKS/<single-file>.md
# Excludes: nested paths, archive/, anything outside TASKS/.
if [[ ! "${FILE}" =~ /project-overlays/[^/]+/TASKS/[^/]+\.md$ ]]; then
  echo "ERROR: path must be project-overlays/<slug>/TASKS/<file>.md" >&2
  echo "       (not inside archive/, no nested dirs, .md extension required)" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

# Explicit README.md block — folder docs, not a TASK.
BASENAME="$(basename "${FILE}")"
if [[ "${BASENAME}" == "README.md" ]]; then
  echo "ERROR: README.md is folder documentation, not a TASK" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

if ! grep -qE '^- Status:' "${FILE}"; then
  echo "ERROR: no '- Status:' line found in ${FILE} (malformed task?)" >&2
  exit 65
fi

# Lifecycle gate: only Status=open or Status=in-progress + Ready=yes can submit.
CURRENT_STATUS="$(grep -m1 -E '^- Status:' "${FILE}" | sed -E 's/^- Status:[[:space:]]*//' | awk '{print $1}')"
case "${CURRENT_STATUS}" in
  open|in-progress)
    : # OK, can submit
    ;;
  review)
    echo "ERROR: TASK already at Status: review (got: '${CURRENT_STATUS}')" >&2
    echo "       submit-task is a no-op here. If TL hasn't accepted yet — wait or run 'make accept-task'." >&2
    echo "       If you want to revert review→in-progress for more work, edit Status manually." >&2
    exit 65
    ;;
  done|rejected)
    echo "ERROR: TASK already terminal (got: '${CURRENT_STATUS}')" >&2
    echo "       submit-task is a no-op here. Submit applies only to active TASK (open|in-progress)." >&2
    exit 65
    ;;
  *)
    echo "ERROR: TASK Status must be 'open' or 'in-progress' to submit (got: '${CURRENT_STATUS:-empty}')" >&2
    echo "       Lifecycle: open → in-progress → review → done." >&2
    echo "       submit-task is the (open|in-progress)→review step." >&2
    exit 65
    ;;
esac

CURRENT_READY="$(grep -m1 -E '^- Ready:' "${FILE}" | sed -E 's/^- Ready:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_READY}" != "yes" ]]; then
  echo "ERROR: TASK Ready must be 'yes' to submit (got: '${CURRENT_READY:-empty}')" >&2
  echo "       If TASK was DRAFT/blocked — raise Ready: yes first, then re-run." >&2
  echo "       Submitting a Ready: no TASK to review is a lifecycle bug (TL never gave go)." >&2
  exit 65
fi

# Self-check handoff gate (if linked HANDOFF exists).
# Поиск связанного HANDOFF: в TASK overlay'е директория HANDOFFS/, ищем
# файл который ссылается на текущий TASK по relative path. Если HANDOFF не
# найден — пропускаем самопроверку (Worker мог ещё не написать или это
# мелкая задача без HANDOFF). Если найден — запускаем self-check; при errors
# отказ submit'а до bump'а Status.
OVERLAY_DIR="$(dirname "$(dirname "${FILE}")")"
TASK_REL="${FILE#"${ROOT_DIR}/"}"
HANDOFF_FILE=""
if [[ -d "${OVERLAY_DIR}/HANDOFFS" ]]; then
  for h in "${OVERLAY_DIR}/HANDOFFS/"*.md; do
    [[ -f "${h}" ]] || continue
    [[ "$(basename "${h}")" == "README.md" ]] && continue
    if grep -qF "${TASK_REL}" "${h}" 2>/dev/null \
       || grep -qF "$(basename "${TASK_REL}")" "${h}" 2>/dev/null; then
      HANDOFF_FILE="${h}"
      break
    fi
  done
fi

if [[ -n "${HANDOFF_FILE}" ]]; then
  echo "Связанная передача найдена: ${HANDOFF_FILE#"${ROOT_DIR}/"}"
  if ! bash "${ROOT_DIR}/scripts/self-check-handoff.sh" "${HANDOFF_FILE}"; then
    echo "" >&2
    echo "ERROR: самопроверка передачи нашла ошибки. Поправь HANDOFF и повтори submit-task." >&2
    echo "       Запустить вручную: make self-check-handoff FILE=${HANDOFF_FILE#"${ROOT_DIR}/"}" >&2
    exit 65
  fi
else
  echo "Info: связанной передачи не найдено в ${OVERLAY_DIR#"${ROOT_DIR}/"}/HANDOFFS/ — пропускаю самопроверку."
fi

# Mutate: bump Status to review (perl for portability between macOS/Linux sed).
perl -i -pe 's/^- Status:.*$/- Status: review/' "${FILE}"

# Report.
RELATIVE_FILE="${FILE#"${ROOT_DIR}"/}"
echo "OK: task submitted for review"
echo "  Status:  ${CURRENT_STATUS} → review"
echo "  file:    ${RELATIVE_FILE}"
echo
echo "Дальше: TL читает HANDOFF (если Worker уже записал), при необходимости запускает Reviewer."
echo "Принятие — 'make accept-task FILE=${RELATIVE_FILE}' после того как HANDOFF закрыт через 'make accept-handoff'."
echo "Если HANDOFF ещё не написан — Worker должен сделать 'make new-handoff' и заполнить body ДО submit-task."
