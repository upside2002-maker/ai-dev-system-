#!/usr/bin/env bash
# Accept a HANDOFF: bump `- Status:` to `closed` and move file to archive/.
# Atomic from caller's perspective: either both happen, or neither (refuses on
# any precondition failure before mutating).
#
# Usage:
#   bash scripts/accept-handoff.sh project-overlays/sitka-office/HANDOFFS/<file>.md
# or via make:
#   make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/<file>.md
#
# Refuses on:
#   - missing FILE arg
#   - file not found
#   - path not project-overlays/<slug>/HANDOFFS/<file>.md (no nested dirs, not archive/)
#   - basename == README.md (folder docs, not a HANDOFF)
#   - target in archive/ already exists (no clobber)
#   - no `- Status:` line in file (malformed handoff)
#
# Does NOT touch OPERATING.md — TL removes the line manually if present.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE — path to HANDOFF .md inside project-overlays/<slug>/HANDOFFS/
         (relative to repo root or absolute; NOT inside archive/)

Example:
  $0 project-overlays/sitka-office/HANDOFFS/2026-05-04-claude-worker-to-claude-tl-foo.md
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

# Path must match: .../project-overlays/<slug>/HANDOFFS/<single-file>.md
# Excludes: nested paths, archive/, anything outside HANDOFFS/.
if [[ ! "${FILE}" =~ /project-overlays/[^/]+/HANDOFFS/[^/]+\.md$ ]]; then
  echo "ERROR: path must be project-overlays/<slug>/HANDOFFS/<file>.md" >&2
  echo "       (not inside archive/, no nested dirs, .md extension required)" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

# Compute archive target.
DIRNAME="$(dirname "${FILE}")"
BASENAME="$(basename "${FILE}")"

# Explicit README.md block — folder docs, not a HANDOFF.
# (Path regex above implicitly allows README.md; this is defense-in-depth
# symmetric with accept-task / reject-task / new-task / new-handoff.)
if [[ "${BASENAME}" == "README.md" ]]; then
  echo "ERROR: README.md is folder documentation, not a HANDOFF" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

ARCHIVE_DIR="${DIRNAME}/archive"
TARGET="${ARCHIVE_DIR}/${BASENAME}"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: target already exists, refusing to clobber: ${TARGET}" >&2
  exit 73  # EX_CANTCREAT
fi

if ! grep -qE '^- Status:' "${FILE}"; then
  echo "ERROR: no '- Status:' line found in ${FILE} (malformed handoff?)" >&2
  exit 65
fi

# Mutate: bump Status to closed (perl for portability between macOS/Linux sed).
perl -i -pe 's/^- Status:.*$/- Status: closed/' "${FILE}"

# Move into archive/.
mkdir -p "${ARCHIVE_DIR}"
mv "${FILE}" "${TARGET}"

# Report.
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: handoff accepted"
echo "  Status:  closed"
echo "  moved:   ${RELATIVE_TARGET}"
echo
echo "Если HANDOFF был перечислен в OPERATING.md — убери строку вручную (helper не трогает OPERATING)."
