#!/usr/bin/env bash
# RED* (ворота-WARNING): текст на ОДНОЙ строке с маркерами user-facing не должен
# протекать. До фикса awk делал next на строке-маркере и весь текст
# '<!-- user-facing --> accept this commit now <!-- /user-facing -->' выпадал
# из зоны → запрещённые слова молчали. Тест требует WARN на inline-варианте.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-operator-word-inline-marker-warns RED* inline-маркер -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

# Оба маркера и текст между ними на одной строке.
F="$(write_handoff_fixture "$WORK" \
  '<!-- user-facing --> accept this commit now <!-- /user-facing -->')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                  || rc=1
assert_out_has "в user-facing зоне найдены запрещённые слова" "$OUT" || rc=1
assert_out_has "accept" "$OUT"                                       || rc=1
assert_out_has "commit" "$OUT"                                       || rc=1
exit "$rc"
