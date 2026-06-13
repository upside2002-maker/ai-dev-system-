#!/usr/bin/env bash
# RED (И-12, инцидент X-1, регистр): строчный '- Risk tier: a' НЕ должен
# пропускать ворота Tier A. До фикса регистрозависимое сравнение == "A"
# считало 'a' НЕ-Tier-A и разом пропускало Mode strict + независимый Reviewer
# + Reviewer-HANDOFF — денежная задача с a+normal+self+без HANDOFF принималась.
# Этот тест краснеет на лазейке: tier нормализуется к верхнему регистру.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-tierA-lowercase-tier RED строчный tier a не обходит TierA"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

# Худший сценарий X-1: строчный tier + normal + self + нет HANDOFF.
HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: a\n- Mode: normal\n- Reviewer: self\n- Created by: bondvit@gmail.com'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"
SHA="$(file_sha "$TASK")"

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
# Должно блокироваться на первом же воротах Tier A (Mode strict).
assert_exit 65 "$RC"                                                   || rc=1
assert_out_has "Tier A TASK must have 'Mode: strict' to accept"        "$OUT" || rc=1
# Побочный эффект не наступил: файл не перемещён, Status не тронут.
assert_unchanged "$TASK" "$SHA"                                        || rc=1
assert_file_absent "$WORK/project-overlays/demo/TASKS/archive/t.md"    || rc=1
exit "$rc"
