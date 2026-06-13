#!/usr/bin/env bash
# RED* (И-5): строка ниже 15-й с датой РЯДОМ с git-словом (Выкат) без хеша →
# фильтр обязан предупредить (exit 0, [WARN] про PR/дату без git short hash).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-date-git-no-hash-warns RED* дата+git без хеша -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

# Заглавная кириллица 'Выкат' — карта требует env -i LC_ALL=C, чтобы ловилось.
F="$(write_handoff_fixture "$WORK" \
  'Выкат на прод 2026-06-10 без хеша.')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                              || rc=1
assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
assert_out_has "Выкат на прод 2026-06-10 без хеша." "$OUT"       || rc=1
exit "$rc"
