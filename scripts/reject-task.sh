#!/usr/bin/env bash
# Reject a TASK: bump `- Status:` to `rejected`, insert `- Rejected reason: …`
# after Status line, and move file to archive/. Symmetric to accept-task.
#
# Usage:
#   bash scripts/reject-task.sh FILE REASON
# or via make:
#   make reject-task FILE=project-overlays/sitka-office/TASKS/<file>.md REASON="…"
#
# Refuses on:
#   - missing FILE arg
#   - missing or empty REASON arg
#   - file not found
#   - path not project-overlays/<slug>/TASKS/<file>.md (no nested dirs, not archive/)
#   - basename == README.md (folder docs, not a TASK)
#   - target in archive/ already exists (no clobber)
#   - no `- Status:` line in file (malformed task)
#   - file already has `- Rejected reason:` line (already rejected, don't double-stamp)
#
# REASON is passed to perl via env var ($ENV{REASON}) — no shell-escaping
# needed inside the substitution. REASON should be single-line; multi-line
# reasons keep first line and append rest as comment.
#
# Does NOT touch OPERATING.md.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE REASON
  FILE   — path to TASK .md inside project-overlays/<slug>/TASKS/
           (relative to repo root or absolute; NOT inside archive/, NOT README.md)
  REASON — non-empty single-line reason (will be inserted as
           '- Rejected reason: <REASON>' after Status line)

Example:
  $0 project-overlays/sitka-office/TASKS/2026-05-04-foo.md "scope changed, superseded by TASK bar"
EOF
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "ERROR: FILE argument required" >&2
  usage
  exit 64  # EX_USAGE
fi

if [[ $# -lt 2 || -z "${2:-}" ]]; then
  echo "ERROR: REASON argument required (non-empty)" >&2
  usage
  exit 64  # EX_USAGE
fi

FILE="$1"
REASON="$2"

# Resolve to absolute path against repo root if not already absolute.
if [[ "${FILE}" != /* ]]; then
  FILE="${ROOT_DIR}/${FILE}"
fi

if [[ ! -f "${FILE}" ]]; then
  echo "ERROR: file not found: ${FILE}" >&2
  exit 66  # EX_NOINPUT
fi

# Path validation (same as accept-task).
if [[ ! "${FILE}" =~ /project-overlays/[^/]+/TASKS/[^/]+\.md$ ]]; then
  echo "ERROR: path must be project-overlays/<slug>/TASKS/<file>.md" >&2
  echo "       (not inside archive/, no nested dirs, .md extension required)" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

BASENAME="$(basename "${FILE}")"
if [[ "${BASENAME}" == "README.md" ]]; then
  echo "ERROR: README.md is folder documentation, not a TASK" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

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

# Guard against double-stamping: file already has Rejected reason → не повторяем.
if grep -qE '^- Rejected reason:' "${FILE}"; then
  echo "ERROR: ${FILE} already has '- Rejected reason:' line — refusing to double-stamp" >&2
  echo "       (если нужно изменить причину, правь руками + ручной mv в archive/)" >&2
  exit 65
fi

# Mutate: bump Status line + insert Rejected reason line right after.
# REASON passed via env to avoid shell-escaping inside perl pattern.
export REASON
perl -i -pe '
  if (/^- Status:/) {
    $_ = "- Status: rejected\n- Rejected reason: $ENV{REASON}\n";
  }
' "${FILE}"

# Move into archive/.
mkdir -p "${ARCHIVE_DIR}"
mv "${FILE}" "${TARGET}"

# Report.
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: task rejected"
echo "  Status:  rejected"
echo "  reason:  ${REASON}"
echo "  moved:   ${RELATIVE_TARGET}"
echo
echo "Если TASK был перечислен в OPERATING.md — убери строку вручную (helper не трогает OPERATING)."
