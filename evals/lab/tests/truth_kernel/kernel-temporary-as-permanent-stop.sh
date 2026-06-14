#!/usr/bin/env bash
# RED #1 (КОНТЕКСТ, случай «200 временные»): память несёт api_credit со СРОКОМ
# годности (valid_until), а совет хочет строить ПОСТОЯННЫЙ мост на этой опоре
# (horizon=permanent). Ядро ДЕТЕРМИНИРОВАННО останавливает: «опора временная —
# нельзя как постоянная основа». Вердикт выносит КОД (exit 4 = stop), не модель.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-temporary-as-permanent-stop RED 200 временные -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT

# Опора временная: кредит апи 200, окно до 2026-06-22; автопродление выключено.
seed_memory_fact "$LED" api_credit 200 2026-06-22
seed_memory_fact "$LED" subscription.autorenew off

CLAIM='{"type":"recommendation","text":"Строить постоянный мост через апи/Телеграм","supports":["api_credit"],"horizon":"permanent"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                              || rc=1
assert_out_has "STOP_TEMPORARY_AS_PERMANENT" "$OUT" || rc=1
assert_out_has "опора временная" "$OUT"          || rc=1
exit "$rc"
