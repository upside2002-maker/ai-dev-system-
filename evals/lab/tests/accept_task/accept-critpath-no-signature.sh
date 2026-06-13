#!/usr/bin/env bash
# RED (И-11): Files трогает критпуть policies/MODES.md, Created by=bondvit
# (can_approve_critical: no), подписи нет → приёмка отказывает.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-critpath-no-signature RED критпуть без подписи отказ"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

# Tier C — чтобы Tier A гейты не перехватили; критпуть-гейт работает на любом tier.
HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: C\n- Created by: bondvit@gmail.com\n- Critical approved by: (нет)'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: policies/MODES.md')"
SHA="$(file_sha "$TASK")"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
assert_exit 65 "$RC"                                || rc=1
assert_out_has "затрагивает критичный путь" "$OUT"  || rc=1
assert_out_has "не имеет права can_approve_critical" "$OUT" || rc=1
assert_unchanged "$TASK" "$SHA"                     || rc=1
exit "$rc"
