#!/usr/bin/env bash
# RED (И-11): правка policies/CRITICAL_PATHS.md, сообщение без Approved-by →
# замок отказывает, коммит не создан.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST commit-critpath-no-trailer RED критпуть без трейлера отказ"

if ! has_git; then echo "git недоступен"; exit 77; fi

WORK="$(make_git_repo_with_hook)"
trap 'rm -rf "$WORK"' EXIT

BEFORE="$(git_head_count "$WORK")"
# Правка критпути policies/CRITICAL_PATHS.md.
mkdir -p "$WORK/policies"
printf 'lab edit\n' >> "$WORK/policies/CRITICAL_PATHS.md"
git -C "$WORK" add policies/CRITICAL_PATHS.md

# Коммит без Approved-by — замок должен отклонить.
OUT="$(git -C "$WORK" commit -m "правка критпути без подписи" 2>&1)"; RC=$?
AFTER="$(git_head_count "$WORK")"

rc=0
assert_exit_nonzero "$RC"                                  || rc=1
assert_out_has "ОТКАЗ: коммит трогает критичные файлы" "$OUT" || rc=1
assert_out_has "нет трейлера Approved-by" "$OUT"           || rc=1
if [[ "$BEFORE" != "$AFTER" ]]; then
  echo "    коммит создан ($BEFORE -> $AFTER), а замок должен был отклонить"
  rc=1
fi
exit "$rc"
