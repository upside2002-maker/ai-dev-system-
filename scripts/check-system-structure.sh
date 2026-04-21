#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_root_files=(
  "README.md"
  "CLAUDE_GLOBAL.md"
  "AGENT_OPERATING_MODEL.md"
  "AGENT_ONBOARDING.md"
  "corrections/global-corrections.md"
  ".claude/README.md"
)

required_sitka_overlay_files=(
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

for file in "${required_root_files[@]}"; do
  [[ -f "${ROOT_DIR}/${file}" ]] || fail "missing required root file: ${file}"
done

SITKA_OVERLAY="${ROOT_DIR}/project-overlays/sitka-office"
[[ -d "${SITKA_OVERLAY}" ]] || fail "missing sitka-office overlay directory"

for file in "${required_sitka_overlay_files[@]}"; do
  [[ -f "${SITKA_OVERLAY}/${file}" ]] || fail "missing sitka overlay file: ${file}"
done

grep -q 'project-overlays/\[slug\]/README.md' "${ROOT_DIR}/AGENT_ONBOARDING.md" \
  || fail "AGENT_ONBOARDING.md no longer points to overlay README"

grep -q 'project-overlays/<slug>/README.md' "${ROOT_DIR}/README.md" \
  || fail "README.md no longer documents overlay README entrypoint"

echo "OK: ai-dev-system root structure and sitka overlay entrypoints are consistent."
