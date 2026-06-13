#!/usr/bin/env bash
# PASS (анти-ложный-срабат для §A): ЗАГЛАВНАЯ кириллица БЕЗ git-слова рядом с
# датой молчит. 'ПРОГНОЗ ТРАНЗИТА НА 2048-03-01' — заглавными, но это не выкат:
# фикс §A складывает регистр только чтобы СРАВНИТЬ с ключами git-работы, а не
# чтобы ловить любую заглавную строку. Голая дата прогноза остаётся без WARN.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-uppercase-nongit-silent PASS ЗАГЛАВНАЯ дата-прогноз молчит"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'ПРОГНОЗ ТРАНЗИТА НА 2048-03-01 — САТУРН')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                  || rc=1
assert_out_lacks "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
assert_out_has "самопроверка прошла чисто" "$OUT"                    || rc=1
exit "$rc"
