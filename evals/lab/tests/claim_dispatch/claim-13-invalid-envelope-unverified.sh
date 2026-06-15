#!/usr/bin/env bash
# RED (приёмка ТЗ): невалидный конверт → unverified. Битый JSON на входе — это
# тоже невалидный конверт (асимметрия): ничто не штампуется «проверено». Плюс
# конверт-не-объект (массив) ловится тем же путём. Диспетчер не падает и не
# пропускает мусор как опору.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-13-invalid-envelope-unverified RED невалидный конверт -> не проверено"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

rc=0
# (а) битый JSON.
OUT="$(printf 'не json{' | run_aida_claim eval "$LED" "$ERRF")"; RC=$?
assert_exit 3 "$RC"                                 || rc=1
assert_out_has "UNVERIFIED_INVALID_ENVELOPE" "$OUT" || rc=1

# (б) валидный JSON, но не объект-конверт (массив).
OUT2="$(printf '[1,2,3]' | run_aida_claim eval "$LED" "$ERRF")"; RC2=$?
assert_exit 3 "$RC2"                                 || rc=1
assert_out_has "UNVERIFIED_UNSUPPORTED_KIND" "$OUT2" || rc=1
exit "$rc"
