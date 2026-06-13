#!/usr/bin/env bash
# RED: файл без строки `- Status:` → приёмка отказывает (malformed task).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-missing-status-line RED нет Status-строки отказ"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

# Шапка без строки '- Status:'.
HEADER=$'- Ready: yes\n- Risk tier: C\n- Created by: bondvit@gmail.com'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"
SHA="$(file_sha "$TASK")"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
assert_exit 65 "$RC"                         || rc=1
assert_out_has "no '- Status:' line found" "$OUT" || rc=1
assert_unchanged "$TASK" "$SHA"              || rc=1
exit "$rc"
