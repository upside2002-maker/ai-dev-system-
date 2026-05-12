#!/usr/bin/env bash
# Pack a project overlay's context into a single markdown stream on stdout.
# Polymorphic by `.overlay-maturity`:
#   - active     → STATUS_RU + OPERATING dashboard + CURRENT_STATE summary
#                  + active TASKS/HANDOFFS counts/links + last 5 commits
#                  overlay + last 5 commits product repo + corrections
#                  headings + first 15 lines of NEXT_ACTIONS.
#   - pre-phase0 → STATUS_RU + README head + last 5 commits overlay
#                  + last 5 commits product repo + corrections headings.
#   - archived   → short note, see overlay README.
#
# Length capped at ~300 lines; if the natural output exceeds the cap, the
# tail is truncated and replaced with a pointer to the overlay/product
# repo paths so the reader knows where the full files live.
#
# Usage:
#   bash scripts/context-pack.sh SLUG
# or via make:
#   make context SLUG=sitka-office
#
# Refuses on:
#   - missing SLUG arg
#   - overlay project-overlays/<SLUG>/ does not exist
#   - missing or unknown .overlay-maturity
#
# Notes:
#   - Default product repo path is /Users/ilya/Projects/<SLUG>. Overridable
#     by exporting PRODUCT_REPO=<path> before invocation. If the directory
#     does not exist, product-repo sections degrade to a "(not found)"
#     placeholder rather than failing.
#   - All file reads are best-effort: missing optional files become
#     "(no <name>)" placeholders, not errors.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_LINES=300

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG
  SLUG — project overlay slug, must exist as project-overlays/<SLUG>/
         (e.g. sitka-office, astro).

Output: markdown context pack to stdout, length capped at ${MAX_LINES} lines.

Environment:
  PRODUCT_REPO — override product repo path (default: /Users/ilya/Projects/<SLUG>)
EOF
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "ERROR: SLUG argument required" >&2
  usage
  exit 64  # EX_USAGE
fi

SLUG="$1"
OVERLAY_DIR="${ROOT_DIR}/project-overlays/${SLUG}"

if [[ ! -d "${OVERLAY_DIR}" ]]; then
  echo "ERROR: overlay not found: ${OVERLAY_DIR}" >&2
  exit 65  # EX_DATAERR
fi

MATURITY_FILE="${OVERLAY_DIR}/.overlay-maturity"
if [[ ! -f "${MATURITY_FILE}" ]]; then
  echo "ERROR: missing .overlay-maturity in ${OVERLAY_DIR}" >&2
  echo "       expected one line: active | pre-phase0 | archived" >&2
  exit 65
fi
MATURITY="$(head -1 "${MATURITY_FILE}" | tr -d '[:space:]')"

case "${MATURITY}" in
  active|pre-phase0|archived) ;;
  *)
    echo "ERROR: unknown maturity '${MATURITY}' in ${MATURITY_FILE}" >&2
    echo "       expected: active | pre-phase0 | archived" >&2
    exit 65
    ;;
esac

PRODUCT_REPO="${PRODUCT_REPO:-/Users/ilya/Projects/${SLUG}}"
PRODUCT_REPO_NOTE=""
if [[ ! -d "${PRODUCT_REPO}" ]]; then
  PRODUCT_REPO_NOTE=" — (not found)"
fi

TODAY="$(date '+%Y-%m-%d')"

# Collect entire pack in a temp file so we can apply the line-cap once at
# the end, instead of trying to budget per-section in advance.
TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

section() {
  printf '\n---\n\n## %s\n\n' "$1"
}

read_or_skip() {
  local path="$1"
  local label="$2"
  if [[ -f "${path}" ]]; then
    cat "${path}"
  else
    printf '_(no %s)_\n' "${label}"
  fi
}

head_or_skip() {
  local path="$1"
  local n="$2"
  local label="$3"
  if [[ -f "${path}" ]]; then
    head -n "${n}" "${path}"
    printf '\n_… (полный файл — %s)_\n' "${path#${ROOT_DIR}/}"
  else
    printf '_(no %s)_\n' "${label}"
  fi
}

{
  cat <<EOF
# Context Pack — ${SLUG}

- Generated: ${TODAY}
- Maturity: ${MATURITY}
- Overlay: project-overlays/${SLUG}/
- Product repo: ${PRODUCT_REPO}${PRODUCT_REPO_NOTE}
EOF

  # Блок «Кто на смене» — короткая сводка из TL_SHIFT.md. Появляется и для
  # active, и для pre-phase0 overlay'ев (для archived блок не рисуется, так
  # как смены там не имеют смысла). Полное описание — policies/SHIFTS.md.
  section "Кто на смене"
  if [[ "${MATURITY}" == "archived" ]]; then
    echo "_(overlay архивирован — смены не отслеживаются)_"
  elif [[ -f "${OVERLAY_DIR}/TL_SHIFT.md" ]]; then
    SHIFT_RELEASED="$(grep -m1 -E '^- Released:' "${OVERLAY_DIR}/TL_SHIFT.md" | sed -E 's/^- Released:[[:space:]]*//' | awk '{print $1}')"
    SHIFT_HOLDER="$(grep -m1 -E '^- Holder:' "${OVERLAY_DIR}/TL_SHIFT.md" | sed -E 's/^- Holder:[[:space:]]*//')"
    SHIFT_EXPIRES="$(grep -m1 -E '^- Expires:' "${OVERLAY_DIR}/TL_SHIFT.md" | sed -E 's/^- Expires:[[:space:]]*//')"
    SHIFT_SCOPE="$(grep -m1 -E '^- Scope:' "${OVERLAY_DIR}/TL_SHIFT.md" | sed -E 's/^- Scope:[[:space:]]*//')"
    SHIFT_ACTIVE_TASK="$(grep -m1 -E '^- Active TASK:' "${OVERLAY_DIR}/TL_SHIFT.md" | sed -E 's/^- Active TASK:[[:space:]]*//')"
    if [[ "${SHIFT_RELEASED}" == "yes" ]]; then
      echo "- смена свободна (активного главного нет)"
      echo "- взять смену: \`make take-shift SLUG=${SLUG} SCOPE=\"...\"\`"
    else
      echo "- главный:         ${SHIFT_HOLDER}"
      echo "- до:              ${SHIFT_EXPIRES}"
      echo "- зона:            ${SHIFT_SCOPE}"
      echo "- активная задача: ${SHIFT_ACTIVE_TASK}"
    fi
  else
    echo "_(TL_SHIFT.md ещё не создан — см. policies/SHIFTS.md)_"
  fi

  section "STATUS_RU.md"
  read_or_skip "${OVERLAY_DIR}/STATUS_RU.md" "STATUS_RU.md"

  case "${MATURITY}" in
    active)
      section "OPERATING.md (dashboard)"
      read_or_skip "${OVERLAY_DIR}/OPERATING.md" "OPERATING.md"

      section "CURRENT_STATE.md (summary, head -25)"
      head_or_skip "${OVERLAY_DIR}/CURRENT_STATE.md" 25 "CURRENT_STATE.md"

      section "Active TASKS / HANDOFFS"
      if [[ -d "${OVERLAY_DIR}/TASKS" ]]; then
        ACTIVE_TASKS_COUNT="$(find "${OVERLAY_DIR}/TASKS" -maxdepth 1 -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
        printf -- '- Active TASKS: %s\n' "${ACTIVE_TASKS_COUNT}"
        find "${OVERLAY_DIR}/TASKS" -maxdepth 1 -name '*.md' -not -name 'README.md' 2>/dev/null \
          | sort | sed "s|^${ROOT_DIR}/||" | head -10 | sed 's|^|  - |'
      else
        echo "- Active TASKS: (no TASKS/ dir)"
      fi
      if [[ -d "${OVERLAY_DIR}/HANDOFFS" ]]; then
        OPEN_HANDOFFS_COUNT="$(find "${OVERLAY_DIR}/HANDOFFS" -maxdepth 1 -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
        printf -- '- Open HANDOFFS: %s\n' "${OPEN_HANDOFFS_COUNT}"
        find "${OVERLAY_DIR}/HANDOFFS" -maxdepth 1 -name '*.md' -not -name 'README.md' 2>/dev/null \
          | sort | sed "s|^${ROOT_DIR}/||" | head -10 | sed 's|^|  - |'
      else
        echo "- Open HANDOFFS: (no HANDOFFS/ dir)"
      fi

      section "Last 5 commits — overlay (paths under project-overlays/${SLUG}/)"
      git -C "${ROOT_DIR}" log -5 --pretty=format:'- `%h` %ad %s' --date=short -- "project-overlays/${SLUG}/" 2>/dev/null || echo "_(no overlay git log available)_"
      echo

      section "Last 5 commits — product repo (${PRODUCT_REPO})"
      if [[ -d "${PRODUCT_REPO}/.git" || -f "${PRODUCT_REPO}/.git" ]]; then
        git -C "${PRODUCT_REPO}" log -5 --pretty=format:'- `%h` %ad %s' --date=short 2>/dev/null || echo "_(git log failed)_"
        echo
      else
        printf '_(product repo not a git repo or not found at %s)_\n' "${PRODUCT_REPO}"
      fi

      section "Corrections (headings only — full text in corrections/global-corrections.md)"
      if [[ -f "${ROOT_DIR}/corrections/global-corrections.md" ]]; then
        grep -E '^## Correction [0-9]' "${ROOT_DIR}/corrections/global-corrections.md" | sed 's|^## |- |'
      else
        echo "_(no corrections/global-corrections.md)_"
      fi

      section "NEXT_ACTIONS.md (top 15 lines)"
      head_or_skip "${OVERLAY_DIR}/NEXT_ACTIONS.md" 15 "NEXT_ACTIONS.md"
      ;;

    pre-phase0)
      section "README.md (head -40)"
      head_or_skip "${OVERLAY_DIR}/README.md" 40 "README.md"

      section "Last 5 commits — overlay (paths under project-overlays/${SLUG}/)"
      git -C "${ROOT_DIR}" log -5 --pretty=format:'- `%h` %ad %s' --date=short -- "project-overlays/${SLUG}/" 2>/dev/null || echo "_(no overlay git log available)_"
      echo

      section "Last 5 commits — product repo (${PRODUCT_REPO})"
      if [[ -d "${PRODUCT_REPO}/.git" || -f "${PRODUCT_REPO}/.git" ]]; then
        git -C "${PRODUCT_REPO}" log -5 --pretty=format:'- `%h` %ad %s' --date=short 2>/dev/null || echo "_(git log failed)_"
        echo
      else
        printf '_(product repo not a git repo or not found at %s)_\n' "${PRODUCT_REPO}"
      fi

      section "Corrections (headings only — full text in corrections/global-corrections.md)"
      if [[ -f "${ROOT_DIR}/corrections/global-corrections.md" ]]; then
        grep -E '^## Correction [0-9]' "${ROOT_DIR}/corrections/global-corrections.md" | sed 's|^## |- |'
      else
        echo "_(no corrections/global-corrections.md)_"
      fi
      ;;

    archived)
      section "Archived overlay"
      printf '_(overlay archived — see %s/README.md for context)_\n' "${OVERLAY_DIR}"
      ;;
  esac
} > "${TMP}"

# Apply length cap.
LINES="$(wc -l < "${TMP}" | tr -d ' ')"
if (( LINES > MAX_LINES )); then
  HEAD_LINES=$((MAX_LINES - 4))
  head -n "${HEAD_LINES}" "${TMP}"
  cat <<EOF

---

_[truncated: original was ${LINES} lines, capped at ${MAX_LINES}. Full files: overlay = ${OVERLAY_DIR}/, product repo = ${PRODUCT_REPO}.]_
EOF
else
  cat "${TMP}"
fi
