#!/usr/bin/env bash
# RED* (ворота-WARNING): слова accept/commit внутри <!-- user-facing --> вне
# backticks → фильтр обязан предупредить (exit 0, но [WARN] в выводе).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-operator-word-in-zone-warns RED* запрещённые слова в зоне -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  '<!-- user-facing -->' \
  'Нужно accept эту задачу и сделать commit изменений.' \
  '<!-- /user-facing -->')"

# env -i LC_ALL=C LANG=C — как в карте: иначе кириллица в evidence ловится непредсказуемо.
OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                  || rc=1
assert_out_has "в user-facing зоне найдены запрещённые слова" "$OUT" || rc=1
assert_out_has "accept" "$OUT"                                       || rc=1
assert_out_has "commit" "$OUT"                                       || rc=1
exit "$rc"
