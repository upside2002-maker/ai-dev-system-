#!/usr/bin/env bash
# RED (КОНТЕКСТ, противоречие памяти по key): память говорит
# subscription.autorenew=off. claim несёт собственное утверждение
# claim_key=subscription.autorenew, claim_value=on. Ядро МЕХАНИЧЕСКИ по key
# ловит расхождение и останавливает: «противоречит памяти» (exit 4). Без модели.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-contradicts-memory-stop RED противоречит памяти -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT

seed_memory_fact "$LED" subscription.autorenew off

CLAIM='{"type":"fact","text":"автопродление включено","claim_key":"subscription.autorenew","claim_value":"on"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                             || rc=1
assert_out_has "STOP_CONTRADICTS_MEMORY" "$OUT" || rc=1
assert_out_has "противоречит памяти" "$OUT"     || rc=1
exit "$rc"
