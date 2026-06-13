#!/usr/bin/env bash
# PASS (анти-ложный-срабат, И-5): голая дата-прогноз без git-слова →
# WARN про PR/дату НЕТ (у прогноза транзита хеша быть не может).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-bare-forecast-date-silent PASS голая дата-прогноз молчит"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'Прогноз транзита на 2048-03-01 — Сатурн')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                            || rc=1
assert_out_lacks "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
assert_out_has "самопроверка прошла чисто" "$OUT"              || rc=1
exit "$rc"
