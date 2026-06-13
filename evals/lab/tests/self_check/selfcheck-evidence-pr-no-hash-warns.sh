#!/usr/bin/env bash
# RED* (И-5): строка ниже 15-й с PR #74 без хеша → фильтр обязан предупредить.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-pr-no-hash-warns RED* PR без хеша -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'Закрыто PR #74')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                              || rc=1
assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
exit "$rc"
