#!/usr/bin/env bash
# RED (И-11): в рабочей копии bondvit no->yes (и в индексе) + Approved-by:
# bondvit@gmail.com. Право читается из HEAD (где no), не из индекса → замок
# отказывает. Доказывает защиту от самоодобрения одним коммитом.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST commit-critpath-self-approve RED самоодобрение в одном коммите отказ"

if ! has_git; then echo "git недоступен"; exit 77; fi

WORK="$(make_git_repo_with_hook)"
trap 'rm -rf "$WORK"' EXIT

BEFORE="$(git_head_count "$WORK")"

# Поднять bondvit can_approve_critical no->yes в рабочей копии и застейджить.
# (USERS.md сам критпуть — но проверка читает право из HEAD, где ещё no.)
perl -0pi -e 's/(bondvit\@gmail\.com.*?can_approve_critical:\s*)no/${1}yes/s' \
  "$WORK/policies/USERS.md"
# Доказываем, что подмена в рабочей копии реально произошла.
# Блок захватываем в переменную и проверяем через [[ ]], а не `grep | grep -q`:
# под pipefail ранний выход grep -q даёт SIGPIPE первому grep → ложный сбой.
BONDVIT_BLOCK="$(grep -A6 'bondvit@gmail.com' "$WORK/policies/USERS.md")"
if [[ "$BONDVIT_BLOCK" != *"can_approve_critical: yes"* ]]; then
  echo "    fixture: не удалось подменить право bondvit в рабочей копии"
  exit 1
fi
git -C "$WORK" add policies/USERS.md

OUT="$(git -C "$WORK" commit -m $'самоодобрение\n\nApproved-by: bondvit@gmail.com' 2>&1)"; RC=$?
AFTER="$(git_head_count "$WORK")"

rc=0
assert_exit_nonzero "$RC"                                      || rc=1
assert_out_has "ни у кого из них нет права подписи" "$OUT"     || rc=1
assert_out_has "bondvit@gmail.com (can_approve_critical ≠ yes" "$OUT" || rc=1
if [[ "$BEFORE" != "$AFTER" ]]; then
  echo "    коммит создан ($BEFORE -> $AFTER) — самоодобрение прошло, это дыра"
  rc=1
fi
exit "$rc"
