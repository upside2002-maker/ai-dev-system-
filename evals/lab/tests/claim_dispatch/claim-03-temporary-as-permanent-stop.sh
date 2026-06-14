#!/usr/bin/env bash
# RED (#3 Owner): временный ресурс НЕ может быть основанием постоянного совета.
# Память хранит временную опору (api_credit=200 с valid_until). advice_basis
# опирается на неё с horizon=permanent → влитой контекст-ворота ядра дают stop
# «временное как постоянная основа без пометки» (случай «200 временные»).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-03-temporary-as-permanent-stop RED 200-временные -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

# Временная опора: кредит 200, годен до даты (valid_until).
seed_memory_fact "$LED" api_credit 200 2026-06-22

CLAIM='{"kind":"advice_basis","text":"строим архитектуру на кредите 200","supports":["api_credit"],"horizon":"permanent"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                                   || rc=1
assert_out_has "STOP_TEMPORARY_AS_PERMANENT" "$OUT"   || rc=1
assert_out_has "временная" "$OUT"                     || rc=1
exit "$rc"
