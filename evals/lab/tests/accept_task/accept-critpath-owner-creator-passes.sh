#!/usr/bin/env bash
# PASS: тот же критпуть policies/MODES.md, но Created by=upside2002
# (can_approve_critical: yes) → short-circuit, приёмка ПРОХОДИТ без отдельной
# подписи. Анти-ложный-срабат для гейта И-11: владелец-создатель принимается.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-critpath-owner-creator-passes PASS критпуть владелец-создатель проходит"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

# Tier C — критпуть-гейт срабатывает, но Tier A гейты не вмешиваются.
HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: C\n- Created by: upside2002@gmail.com\n- Critical approved by: (нет)'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: policies/MODES.md')"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

ARCHIVED="$WORK/project-overlays/demo/TASKS/archive/t.md"
rc=0
assert_exit 0 "$RC"                          || rc=1
assert_out_has "имеет право подписи" "$OUT"   || rc=1
assert_file_absent "$TASK"                   || rc=1
assert_file_exists "$ARCHIVED"               || rc=1
exit "$rc"
