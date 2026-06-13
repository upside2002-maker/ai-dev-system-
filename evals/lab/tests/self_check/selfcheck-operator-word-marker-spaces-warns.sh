#!/usr/bin/env bash
# RED* (ворота-WARNING): маркер user-facing с ВНУТРЕННИМИ пробелами
# '<!--   user-facing   -->' не должен прятать запрещённые слова. До фикса
# awk-экстрактор требовал литеральное совпадение '<!-- user-facing -->' и
# не распознавал зону с лишними пробелами → accept/commit утекали молча.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-operator-word-marker-spaces-warns RED* маркер с пробелами -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  '<!--   user-facing   -->' \
  'Нужно accept эту задачу и сделать commit изменений.' \
  '<!--   /user-facing   -->')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                  || rc=1
assert_out_has "в user-facing зоне найдены запрещённые слова" "$OUT" || rc=1
assert_out_has "accept" "$OUT"                                       || rc=1
assert_out_has "commit" "$OUT"                                       || rc=1
exit "$rc"
