#!/usr/bin/env bash
# RED (источник-врёт): claim заявляет факт api_credit=500 и честно выбирает
# адаптер ledger.fact (из белого списка), но доверенный источник (память) даёт
# 200. Ядро сверяет КОДОМ и останавливает: «противоречит источнику» (exit 4).
# Это показывает: проверяемый claim не штампуется «проверено» по желанию модели —
# код сверяет ожидаемое с реальным источником.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-source-lies-stop RED источник-врёт -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT

seed_memory_fact "$LED" api_credit 200 2026-06-22

CLAIM='{"type":"fact","text":"Кредит апи равен 500","adapter":"ledger.fact","arg":"api_credit","expected":"500"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                            || rc=1
assert_out_has "STOP_CONTRADICTS_SOURCE" "$OUT" || rc=1
assert_out_has "противоречит источнику" "$OUT"  || rc=1
exit "$rc"
