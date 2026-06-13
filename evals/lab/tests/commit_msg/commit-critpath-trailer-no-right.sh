#!/usr/bin/env bash
# RED (И-11): правка критпути, Approved-by: bondvit@gmail.com
# (can_approve_critical: no в HEAD-версии USERS.md) → замок отказывает.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST commit-critpath-trailer-no-right RED трейлер без права отказ"

if ! has_git; then echo "git недоступен"; exit 77; fi

WORK="$(make_git_repo_with_hook)"
trap 'rm -rf "$WORK"' EXIT

BEFORE="$(git_head_count "$WORK")"
mkdir -p "$WORK/scripts"
printf '# lab edit\n' >> "$WORK/scripts/dummy.sh"
git -C "$WORK" add scripts/dummy.sh

OUT="$(git -C "$WORK" commit -m $'правка критпути\n\nApproved-by: bondvit@gmail.com' 2>&1)"; RC=$?
AFTER="$(git_head_count "$WORK")"

rc=0
assert_exit_nonzero "$RC"                                      || rc=1
assert_out_has "ни у кого из них нет права подписи" "$OUT"     || rc=1
assert_out_has "bondvit@gmail.com (can_approve_critical ≠ yes" "$OUT" || rc=1
if [[ "$BEFORE" != "$AFTER" ]]; then
  echo "    коммит создан ($BEFORE -> $AFTER), а замок должен был отклонить"
  rc=1
fi
exit "$rc"
