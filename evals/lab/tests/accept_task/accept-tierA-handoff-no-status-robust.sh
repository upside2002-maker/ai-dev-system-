#!/usr/bin/env bash
# RED (И-12, устойчивость): кандидат-HANDOFF без строки '- Status:' не должен
# ронять скрипт под set -e/pipefail. До фикса grep -m1 '^- Status:' без '|| true'
# давал ненулевой код → аварийный выход RC=1 с пустым выводом вместо
# документированного RC=65 с объяснением. Приёмка всё равно отказывала
# (инвариант держался), но причина была непонятной. Тест требует чистого
# отказа: RC=65 + внятное сообщение про Reviewer-HANDOFF, задача не тронута.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-tierA-handoff-no-status-robust RED HANDOFF без Status -> чистый отказ"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: A\n- Mode: strict\n- Reviewer: Дядя Вася\n- Created by: bondvit@gmail.com'
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"
SHA="$(file_sha "$TASK")"

# Кандидат-HANDOFF, совпадающий по TASK и роли Reviewer, но БЕЗ строки Status.
HF_BODY=$'- From: Reviewer (отдельная сессия)\n- Role mode: Reviewer\n- TASK: t'
tmp_handoff "$WORK" demo "hf.md" "$HF_BODY" >/dev/null

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

rc=0
# Документированный код отказа, а не аварийный RC=1 от set -e.
assert_exit 65 "$RC"                                          || rc=1
assert_out_has "не имеет независимого Reviewer-HANDOFF" "$OUT" || rc=1
assert_out_has "И-12" "$OUT"                                  || rc=1
assert_unchanged "$TASK" "$SHA"                              || rc=1
exit "$rc"
