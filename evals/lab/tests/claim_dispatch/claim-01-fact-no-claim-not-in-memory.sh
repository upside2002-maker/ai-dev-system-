#!/usr/bin/env bash
# RED (#1 Owner): факт БЕЗ опоры-источника не попадает в память. fact_claim без
# adapter → влитой gate(fact) даёт unverified «нет источника», memory_eligible=
# false. Наружу как «не проверено», НЕ как факт. Доказывает: заявка-конверт без
# проверяемой опоры не штампуется и в структурную память не идёт (асимметрия).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-01-fact-no-claim-not-in-memory RED факт без опоры -> не в память"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

CLAIM='{"kind":"fact_claim","text":"кредит апи равен 200"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim gate "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 3 "$RC"                              || rc=1
assert_out_has "UNVERIFIED_NO_SOURCE" "$OUT"     || rc=1
assert_out_has '"memory_eligible": false' "$OUT" || rc=1
assert_out_has "не проверено" "$OUT"             || rc=1
# В память факт не дописан: реестр фактов пуст/без записи кредита.
if [[ -f "$LED/facts.jsonl" ]] && grep -q "api_credit" "$LED/facts.jsonl" 2>/dev/null; then
  echo "    факт без опоры попал в память — нарушение #1"; rc=1
fi
exit "$rc"
