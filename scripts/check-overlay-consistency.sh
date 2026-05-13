#!/usr/bin/env bash
# Check that an overlay is structurally consistent with its declared maturity.
#
# Maturity is read from `<overlay>/.overlay-maturity` (one line). Defaults to
# `active` for backward-compat when the file is absent.
#
# Maturity values:
#   active      — full operational overlay. Requires README + CURRENT_STATE +
#                 KNOWN_ISSUES + NEXT_ACTIONS + PROJECT_MAP, plus Snapshot
#                 commit in CURRENT_STATE.md must match the project repo HEAD.
#   pre-phase0  — overlay exists but project hasn't completed Phase 0 yet.
#                 Requires only README. CURRENT_STATE/etc. expected later
#                 (per project roadmap, e.g. astro T-F.4). No snapshot check.
#   archived    — project decommissioned. Only README required as marker.
#
# Usage:
#   bash scripts/check-overlay-consistency.sh <slug> [<repo-path>]
#
# Defaults: slug=sitka-office, repo-path=$HOME/Projects/<slug>.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${1:-sitka-office}"
REPO_PATH="${2:-${HOME}/Projects/${SLUG}}"
OVERLAY_DIR="${ROOT_DIR}/project-overlays/${SLUG}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d "${OVERLAY_DIR}" ]] || fail "overlay not found: ${OVERLAY_DIR}"

# --- read maturity ---
MATURITY_FILE="${OVERLAY_DIR}/.overlay-maturity"
if [[ -f "${MATURITY_FILE}" ]]; then
  MATURITY="$(head -1 "${MATURITY_FILE}" | tr -d '[:space:]')"
else
  MATURITY="active"
fi

case "${MATURITY}" in
  active|pre-phase0|archived) ;;
  *)
    fail "invalid overlay maturity for '${SLUG}': '${MATURITY}' (must be: active | pre-phase0 | archived)"
    ;;
esac

# --- README always required, regardless of maturity ---
[[ -f "${OVERLAY_DIR}/README.md" ]] || fail "missing required overlay file: README.md (slug=${SLUG})"

# --- maturity-specific checks ---
case "${MATURITY}" in
  active)
    # Full operational overlay.
    required_files=(
      "CURRENT_STATE.md"
      "KNOWN_ISSUES.md"
      "NEXT_ACTIONS.md"
      "PROJECT_MAP.md"
    )
    for file in "${required_files[@]}"; do
      [[ -f "${OVERLAY_DIR}/${file}" ]] || fail "missing required overlay file: ${file} (slug=${SLUG}, maturity=active)"
    done

    CURRENT_STATE_FILE="${OVERLAY_DIR}/CURRENT_STATE.md"
    grep -q '^Snapshot commit: `' "${CURRENT_STATE_FILE}" \
      || fail "CURRENT_STATE.md must contain a 'Snapshot commit:' line (slug=${SLUG})"

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

    echo "OK: overlay '${SLUG}' is structurally complete and snapshot-aligned (maturity=active)."
    ;;

  pre-phase0)
    # CURRENT_STATE / KNOWN_ISSUES / NEXT_ACTIONS / PROJECT_MAP intentionally
    # absent at this maturity — they appear when project finishes Phase 0.
    # No snapshot check (there is no committed snapshot yet).
    echo "OK: overlay '${SLUG}' is at maturity=pre-phase0 (README only; CURRENT_STATE/etc. expected after Phase 0 — bump to 'active' then)."
    ;;

  archived)
    # Project decommissioned; overlay kept as marker.
    echo "OK: overlay '${SLUG}' is archived (no further checks)."
    ;;
esac
