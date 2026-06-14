#!/usr/bin/env bash
# RED #3 (ПРАВДА): claim type=fact без адаптера-из-белого-списка. Ядро НЕ
# выпускает это как факт — вердикт «не проверено» (exit 3), наружу плашка
# [не проверено], в журнал corrections/model_errors.jsonl дописана строка, в
# facts.jsonl ничего не пишется. Асимметрия: нет источника → не проверено.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-fact-no-source-unverified RED факт без источника -> не проверено"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"   # gate создаст файл сам — проверим, что он появился с записью

CLAIM='{"type":"fact","text":"Курс BTC сейчас 100к"}'
# gate (а не eval) — он же дозаписывает журнал ошибок и собирает наружный текст.
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel gate "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 3 "$RC"                          || rc=1
assert_out_has "UNVERIFIED_NO_SOURCE" "$OUT" || rc=1
assert_out_has "не проверено" "$OUT"         || rc=1
# В память (facts.jsonl) НЕ записано.
assert_file_absent "${LED}/facts.jsonl"      || rc=1
# В журнал ошибок дописана строка.
assert_file_exists "$ERRF"                   || rc=1
if [[ -f "$ERRF" ]]; then
  ERRTXT="$(cat "$ERRF")"
  assert_out_has "UNVERIFIED_NO_SOURCE" "$ERRTXT" || rc=1
fi
exit "$rc"
