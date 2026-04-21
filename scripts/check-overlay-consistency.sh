#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${1:-sitka-office}"
REPO_PATH="${2:-/Users/ilya/Projects/${SLUG}}"
OVERLAY_DIR="${ROOT_DIR}/project-overlays/${SLUG}"
CURRENT_STATE_FILE="${OVERLAY_DIR}/CURRENT_STATE.md"

required_files=(
  "README.md"
  "CURRENT_STATE.md"
  "KNOWN_ISSUES.md"
  "NEXT_ACTIONS.md"
  "PROJECT_MAP.md"
)

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d "${OVERLAY_DIR}" ]] || fail "overlay not found: ${OVERLAY_DIR}"

for file in "${required_files[@]}"; do
  [[ -f "${OVERLAY_DIR}/${file}" ]] || fail "missing required overlay file: ${file}"
done

grep -q '^Snapshot commit: `' "${CURRENT_STATE_FILE}" \
  || fail "CURRENT_STATE.md must contain a 'Snapshot commit:' line"

if [[ -d "${REPO_PATH}/.git" ]]; then
  repo_head="$(git -C "${REPO_PATH}" rev-parse --short HEAD)"
  if ! grep -q "Snapshot commit: \`${repo_head}\`" "${CURRENT_STATE_FILE}"; then
    fail "overlay snapshot does not match ${SLUG} HEAD (${repo_head})"
  fi

  dirty_output="$(git -C "${REPO_PATH}" status --short)"
  if [[ -n "${dirty_output}" ]]; then
    echo "WARN: ${SLUG} working tree is not clean:"
    echo "${dirty_output}"
  fi
fi

echo "OK: overlay '${SLUG}' is structurally complete and snapshot-aligned."
