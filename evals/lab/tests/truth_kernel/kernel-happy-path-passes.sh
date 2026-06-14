#!/usr/bin/env bash
# PASS (счастливый путь): валидный claim type=fact выбирает адаптер ledger.fact
# из белого списка, ожидаемое значение СОВПАДАЕТ с доверенным источником
# (память). Ядро выносит «проверено» (exit 0), наружу плашка [проверено]. Это
# анти-ложный-срабат: ядро НЕ краснеет на честном проверенном факте.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-happy-path-passes PASS валидный+проверенный -> проходит"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

seed_memory_fact "$LED" api_credit 200 2026-06-22

CLAIM='{"type":"fact","text":"Кредит апи равен 200","adapter":"ledger.fact","arg":"api_credit","expected":"200"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel gate "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 0 "$RC"                       || rc=1
assert_out_has "OK_SOURCE_MATCH" "$OUT"   || rc=1
assert_out_has "проверено" "$OUT"         || rc=1
# Счастливый путь НЕ пишет в журнал ошибок.
assert_file_absent "$ERRF"                || rc=1
exit "$rc"
