#!/usr/bin/env bash
# RED: Tier A, Mode=normal → приёмка отказывает (policies/MODES.md).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-tierA-no-strict RED TierA без strict отказ"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: A\n- Mode: normal\n- Created by: bondvit@gmail.com'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"
SHA="$(file_sha "$TASK")"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
assert_exit 65 "$RC"                                            || rc=1
assert_out_has "Tier A TASK must have 'Mode: strict' to accept" "$OUT" || rc=1
assert_unchanged "$TASK" "$SHA"                                 || rc=1
exit "$rc"
