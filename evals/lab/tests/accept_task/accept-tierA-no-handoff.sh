#!/usr/bin/env bash
# RED (И-12): Tier A strict, поле Reviewer заполнено независимым именем, но
# HANDOFFS/ пуст → приёмка отказывает (артефакт проверки не найден, инцидент X-1).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-tierA-no-handoff RED TierA без Reviewer-HANDOFF отказ"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: A\n- Mode: strict\n- Reviewer: Дядя Вася (отдельная сессия)\n- Created by: bondvit@gmail.com'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"
# HANDOFFS/ намеренно не создаём — артефакта нет.
SHA="$(file_sha "$TASK")"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
assert_exit 65 "$RC"                                       || rc=1
assert_out_has "не имеет независимого Reviewer-HANDOFF" "$OUT" || rc=1
assert_out_has "И-12" "$OUT"                               || rc=1
assert_unchanged "$TASK" "$SHA"                            || rc=1
exit "$rc"
