#!/usr/bin/env bash
# RED (#7 Owner): «сказал А — записал Б» ловится. fact_claim несёт собственное
# утверждение key=value (api_credit=500), а структурная память по тому же key
# говорит 200. Диспетчер переименовывает key→claim_key, value→claim_value и
# зовёт влитой gate; ядро механически сверяет с памятью и даёт stop «противоречит
# памяти» — расхождение заявленного и записанного ловится КОДОМ, не моделью.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-07-say-a-record-b-caught RED сказал А записал Б -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

# Память: api_credit=200 (бессрочно, чтобы сработал именно ловец памяти).
seed_memory_fact "$LED" api_credit 200

# Заявка говорит другое значение по тому же key.
CLAIM='{"kind":"fact_claim","text":"кредит апи равен 500","key":"api_credit","value":"500"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                               || rc=1
assert_out_has "STOP_CONTRADICTS_MEMORY" "$OUT"   || rc=1
assert_out_has "противоречит" "$OUT"              || rc=1
exit "$rc"
