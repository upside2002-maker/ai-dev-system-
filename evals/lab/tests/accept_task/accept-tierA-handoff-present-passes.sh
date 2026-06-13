#!/usr/bin/env bash
# PASS: Tier A strict + независимый Reviewer-HANDOFF (Status: closed,
# Role mode: Reviewer, TASK: <base>) → приёмка ПРОХОДИТ, задача в archive/, done.
# Анти-ложный-срабат для гейта И-12: легитимная Tier A проходит.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST accept-tierA-handoff-present-passes PASS TierA с Reviewer-HANDOFF проходит"

WORK="$(make_tmp_repo scripts/accept-task.sh policies/CRITICAL_PATHS.md policies/USERS.md)"
trap 'rm -rf "$WORK"' EXIT

HEADER=$'- Status: review\n- Ready: yes\n- Risk tier: A\n- Mode: strict\n- Reviewer: Независимый ревьюер (отдельная сессия)\n- Created by: bondvit@gmail.com'
# Files без критпути — чтобы не упереться в подпись (это тест гейта И-12).
TASK="$(tmp_overlay_task "$WORK" demo "$HEADER" '- modify: README_local.txt')"

# Базовое имя задачи — 't' (файл t.md). HANDOFF должен ссылаться на него.
HANDOFF_BODY=$'# HANDOFF: reviewer -> tl\n\n- Date: 2026-06-12\n- From: Reviewer (независимая сессия)\n- To: Tech Lead\n- Role mode: Reviewer\n- TASK: t\n- Status: closed\n\n## Вердикт\n\nAPPROVE.'
tmp_handoff "$WORK" demo "2026-06-12-reviewer-to-tl-t.md" "$HANDOFF_BODY" >/dev/null

OUT="$(bash "$WORK/scripts/accept-task.sh" "$TASK" 2>&1)"; RC=$?

ARCHIVED="$WORK/project-overlays/demo/TASKS/archive/t.md"
rc=0
assert_exit 0 "$RC"                                     || rc=1
assert_out_has "независимый Reviewer-HANDOFF найден" "$OUT" || rc=1
assert_file_absent "$TASK"                              || rc=1  # перемещён
assert_file_exists "$ARCHIVED"                          || rc=1
if [[ -e "$ARCHIVED" ]] && ! grep -qE '^- Status: done' "$ARCHIVED"; then
  echo "    Status в архивной задаче не 'done'"
  rc=1
fi
exit "$rc"
