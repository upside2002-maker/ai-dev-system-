#!/usr/bin/env bash
# Accept a TASK: bump `- Status:` to `done` and move file to archive/.
# Atomic from caller's perspective: refuses on any precondition failure
# before mutating.
#
# Usage:
#   bash scripts/accept-task.sh project-overlays/sitka-office/TASKS/<file>.md
# or via make:
#   make accept-task FILE=project-overlays/sitka-office/TASKS/<file>.md
#
# Refuses on:
#   - missing FILE arg
#   - file not found
#   - path not project-overlays/<slug>/TASKS/<file>.md (no nested dirs, not archive/)
#   - basename == README.md (folder docs, not a TASK)
#   - target in archive/ already exists (no clobber)
#   - no `- Status:` line in file (malformed task)
#   - Status != review (lifecycle: only review-stage TASK can transition to done)
#   - Ready != yes (DRAFT/blocked TASK cannot be accepted; raise Ready: yes first)
#   - Risk tier: A without Mode: strict (see policies/MODES.md — Tier A
#     requires strict mode; missing Mode field on a Tier A task also refused)
#
# Does NOT touch OPERATING.md — TL removes the line manually if present.
# Does NOT support reject-task (rejected status) — separate helper if needed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE — path to TASK .md inside project-overlays/<slug>/TASKS/
         (relative to repo root or absolute; NOT inside archive/, NOT README.md)

Example:
  $0 project-overlays/sitka-office/TASKS/2026-05-04-dm7-c-foo.md
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

# Compute archive target.
DIRNAME="$(dirname "${FILE}")"
ARCHIVE_DIR="${DIRNAME}/archive"
TARGET="${ARCHIVE_DIR}/${BASENAME}"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: target already exists, refusing to clobber: ${TARGET}" >&2
  exit 73  # EX_CANTCREAT
fi

if ! grep -qE '^- Status:' "${FILE}"; then
  echo "ERROR: no '- Status:' line found in ${FILE} (malformed task?)" >&2
  exit 65
fi

# Lifecycle gate: only Status=review + Ready=yes TASK can transition to done.
# Both checks happen BEFORE any mutation — refuse cleanly if pre-conditions not met.
CURRENT_STATUS="$(grep -m1 -E '^- Status:' "${FILE}" | sed -E 's/^- Status:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_STATUS}" != "review" ]]; then
  echo "ERROR: TASK Status must be 'review' to accept (got: '${CURRENT_STATUS:-empty}')" >&2
  echo "       Lifecycle: open → in-progress → review → done." >&2
  echo "       accept-task is the review→done step. Cannot skip stages." >&2
  echo "       If Worker submitted HANDOFF — bump Status to 'review' first, then re-run." >&2
  exit 65
fi

CURRENT_READY="$(grep -m1 -E '^- Ready:' "${FILE}" | sed -E 's/^- Ready:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_READY}" != "yes" ]]; then
  echo "ERROR: TASK Ready must be 'yes' to accept (got: '${CURRENT_READY:-empty}')" >&2
  echo "       If TASK was DRAFT/blocked, raise Ready: yes first, then re-run." >&2
  echo "       (Ready=no с Status=review — странная комбинация; gate refuses to be safe.)" >&2
  exit 65
fi

# Risk-tier × Mode gate: Tier A requires Mode=strict.
# Tier B/C — Mode optional (missing field tolerated; legacy tasks pre-2026-05-08
# do not have Mode at all). Tier A without Mode=strict — refusal regardless of
# whether Mode is missing or set to a non-strict value. See policies/MODES.md.
CURRENT_TIER="$(grep -m1 -E '^- Risk tier:' "${FILE}" | sed -E 's/^- Risk tier:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_TIER}" == "A" ]]; then
  CURRENT_MODE="$(grep -m1 -E '^- Mode:' "${FILE}" | sed -E 's/^- Mode:[[:space:]]*//' | awk '{print $1}')"
  if [[ "${CURRENT_MODE}" != "strict" ]]; then
    echo "ERROR: Tier A TASK must have 'Mode: strict' to accept (got: '${CURRENT_MODE:-missing}')" >&2
    echo "       Risk tier A = migrations / money-flow / security boundaries / schema / ledger /" >&2
    echo "       auth / payment / any code with explicit invariant in architecture-invariants.md." >&2
    echo "       Such TASKs require strict mode — separate Worker subagent + separate Reviewer +" >&2
    echo "       full ceremony. Понизить tier ради удобства запрещено (см. Correction 012)." >&2
    echo "       См. policies/MODES.md для таблицы соответствия risk tier → mode." >&2
    exit 65
  fi
fi

# Mutate: bump Status to done (perl for portability between macOS/Linux sed).
perl -i -pe 's/^- Status:.*$/- Status: done/' "${FILE}"

# Move into archive/.
mkdir -p "${ARCHIVE_DIR}"
mv "${FILE}" "${TARGET}"

# Report.
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: task accepted"
echo "  Status:  done"
echo "  moved:   ${RELATIVE_TARGET}"
echo
echo "Если TASK был перечислен в OPERATING.md — убери строку вручную (helper не трогает OPERATING)."
echo "Если задача была отклонена (rejected, не done) — accept-task сюда не подходит; используй ручной mv после bump'а Status: rejected."
