#!/usr/bin/env bash
# Mechanical view of project operational state.
# Scans TASKS/ and HANDOFFS/, prints summary + drift check.
# Always exits 0 — informational, not a check (use `make check` for invariants).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${1:-sitka-office}"
OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
REPO_PATH="${REPO_PATH:-/Users/ilya/Projects/${SLUG}}"

if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: overlay not found: ${OVERLAY}" >&2
  exit 1
fi

# Extract `- Field: value` from markdown header.
extract_field() {
  local file="$1" field="$2"
  grep -m1 -E "^- ${field}:" "$file" 2>/dev/null \
    | sed -E "s/^- ${field}:[[:space:]]*//" \
    | sed -E 's/[[:space:]]+$//'
}

# First word of a string (for trimming "closed (TL accepted...)" → "closed").
first_word() { echo "$1" | awk '{print $1}'; }

# Truncate string to N chars with "…" suffix if needed.
trunc() {
  local s="$1" n="${2:-60}"
  if [[ ${#s} -gt ${n} ]]; then
    echo "${s:0:$((n-1))}…"
  else
    echo "$s"
  fi
}

print_task() {
  local file="$1" id status layer tier ready display_status ready_suffix
  id=$(head -1 "$file" | sed -E 's/^# *//')
  status=$(first_word "$(extract_field "$file" "Status")")
  layer=$(extract_field "$file" "Layer")
  tier=$(extract_field "$file" "Risk tier")
  tier="${tier:0:1}"
  ready=$(first_word "$(extract_field "$file" "Ready")")
  # Display: open + Ready=no → BLOCKED bracket. Other statuses unchanged.
  # Legacy TASKs without Ready field — treat as ready (yes).
  display_status="${status:-?}"
  if [[ "${status}" == "open" && "${ready}" == "no" ]]; then
    display_status="BLOCKED"
  fi
  # Ready suffix: show only when field is present (skip for legacy archived).
  ready_suffix=""
  if [[ -n "${ready}" ]]; then
    ready_suffix="  ready=${ready}"
  fi
  printf "  [%-8s] %s\n" "${display_status}" "$(trunc "$id" 70)"
  printf "             layer=%s  tier=%s%s\n" "${layer:-?}" "${tier:-?}" "${ready_suffix}"
}

print_handoff() {
  local file="$1" title status from date
  title=$(head -1 "$file" | sed -E 's/^# *//')
  status=$(first_word "$(extract_field "$file" "Status")")
  from=$(extract_field "$file" "From")
  date=$(extract_field "$file" "Date")
  printf "  [%-8s] %s\n" "${status:-?}" "$(trunc "$title" 70)"
  printf "             %s  from: %s\n" "${date:-?}" "$(trunc "${from:-?}" 50)"
}

list_active_md() {
  # Files matching YYYY-... pattern at given dir; null-safe.
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -name '[0-9]*.md' -type f 2>/dev/null | sort
}

list_recent_md() {
  # Last N files by mtime in given dir.
  local dir="$1" n="${2:-3}"
  [[ -d "$dir" ]] || return 0
  # Use ls -t for portability (macOS bash 3.2).
  # shellcheck disable=SC2012
  ls -t "$dir"/[0-9]*.md 2>/dev/null | head -"$n"
}

NOW=$(date -u '+%Y-%m-%d %H:%M UTC')
echo "=== ${SLUG} operating status (generated ${NOW}) ==="
echo

# --- Active TASKS ------------------------------------------------------------
echo "ACTIVE TASKS:"
ACTIVE_TASKS=$(list_active_md "${OVERLAY}/TASKS")
if [[ -z "${ACTIVE_TASKS}" ]]; then
  echo "  (none)"
  ACTIVE_TASK_COUNT=0
else
  ACTIVE_TASK_COUNT=$(echo "${ACTIVE_TASKS}" | wc -l | tr -d ' ')
  while IFS= read -r f; do
    print_task "$f"
  done <<< "${ACTIVE_TASKS}"
fi
echo

# --- Open HANDOFFS -----------------------------------------------------------
echo "OPEN HANDOFFS:"
OPEN_HANDOFFS=$(list_active_md "${OVERLAY}/HANDOFFS")
if [[ -z "${OPEN_HANDOFFS}" ]]; then
  echo "  (none)"
  OPEN_HANDOFF_COUNT=0
else
  OPEN_HANDOFF_COUNT=$(echo "${OPEN_HANDOFFS}" | wc -l | tr -d ' ')
  while IFS= read -r f; do
    print_handoff "$f"
  done <<< "${OPEN_HANDOFFS}"
fi
echo

# --- Recently archived TASKS -------------------------------------------------
echo "RECENTLY ARCHIVED TASKS (last 3 by mtime):"
RECENT_TASKS=$(list_recent_md "${OVERLAY}/TASKS/archive" 3)
if [[ -z "${RECENT_TASKS}" ]]; then
  echo "  (none)"
else
  while IFS= read -r f; do
    print_task "$f"
  done <<< "${RECENT_TASKS}"
fi
echo

# --- Recently archived HANDOFFS ----------------------------------------------
echo "RECENTLY ARCHIVED HANDOFFS (last 3 by mtime):"
RECENT_HANDOFFS=$(list_recent_md "${OVERLAY}/HANDOFFS/archive" 3)
if [[ -z "${RECENT_HANDOFFS}" ]]; then
  echo "  (none)"
else
  while IFS= read -r f; do
    print_handoff "$f"
  done <<< "${RECENT_HANDOFFS}"
fi
echo

# --- Lifecycle warning: archived HANDOFFS without Status: closed -------------
# Per templates/HANDOFFS_TEMPLATE.md, archived handoffs must have Status: closed.
# `open` / `acknowledged` / empty in archive/ = lifecycle drift (Worker/TL
# discipline gap). Warning is informational; exit code stays 0.
WARN_LINES=""
if [[ -d "${OVERLAY}/HANDOFFS/archive" ]]; then
  for f in "${OVERLAY}/HANDOFFS/archive"/[0-9]*.md; do
    [[ -e "$f" ]] || continue
    s=$(first_word "$(extract_field "$f" "Status")")
    if [[ "${s}" != "closed" ]]; then
      WARN_LINES+="${s:-EMPTY}|${f}"$'\n'
    fi
  done
fi

if [[ -n "${WARN_LINES}" ]]; then
  echo "WARN: archived handoffs with non-closed status:"
  while IFS='|' read -r s f; do
    [[ -z "$f" ]] && continue
    rel="${f#${OVERLAY}/}"
    printf "  [%-12s] %s\n" "$s" "$rel"
  done <<< "${WARN_LINES}"
  echo "  → expected: Status: closed before \`mv → archive/\` (see templates/HANDOFFS_TEMPLATE.md)"
  echo
fi

# --- Drift check -------------------------------------------------------------
echo "DRIFT CHECK:"
OPERATING_FILE="${OVERLAY}/OPERATING.md"
if [[ -f "${OPERATING_FILE}" ]]; then
  # Count `^- [`TASKS/...` bullets in OPERATING (TL's claim of active TASKs).
  OPERATING_ACTIVE=$(grep -cE '^- \[`TASKS/' "${OPERATING_FILE}" 2>/dev/null || true)
  OPERATING_OPEN=$(grep -cE '^- \[`HANDOFFS/' "${OPERATING_FILE}" 2>/dev/null || true)
  printf "  TASKS active     fs=%-3s  OPERATING.md=%-3s  " "${ACTIVE_TASK_COUNT}" "${OPERATING_ACTIVE}"
  if [[ "${ACTIVE_TASK_COUNT}" == "${OPERATING_ACTIVE}" ]]; then echo "match"; else echo "DRIFT"; fi
  printf "  HANDOFFS open    fs=%-3s  OPERATING.md=%-3s  " "${OPEN_HANDOFF_COUNT}" "${OPERATING_OPEN}"
  if [[ "${OPEN_HANDOFF_COUNT}" == "${OPERATING_OPEN}" ]]; then echo "match"; else echo "DRIFT"; fi
else
  echo "  (no OPERATING.md — skipping fs vs OPERATING comparison)"
fi

CURRENT_STATE_FILE="${OVERLAY}/CURRENT_STATE.md"
if [[ -d "${REPO_PATH}/.git" && -f "${CURRENT_STATE_FILE}" ]]; then
  HEAD_SHA=$(git -C "${REPO_PATH}" rev-parse --short HEAD)
  SNAPSHOT=$(grep -m1 -E '^Snapshot commit:' "${CURRENT_STATE_FILE}" 2>/dev/null \
    | sed -E 's/.*`([^`]+)`.*/\1/')
  printf "  %s HEAD  =%-12s  CURRENT_STATE=%-12s  " "${SLUG}" "${HEAD_SHA}" "${SNAPSHOT:-?}"
  if [[ "${HEAD_SHA}" == "${SNAPSHOT}" ]]; then echo "match"; else echo "DRIFT"; fi
fi

echo
echo "(informational — for invariants run \`make check\`)"
