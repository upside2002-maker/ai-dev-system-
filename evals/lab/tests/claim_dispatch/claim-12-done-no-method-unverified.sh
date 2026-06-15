#!/usr/bin/env bash
# RED (приёмка ТЗ): done без способа сверки → unverified. Чисто словесное
# «готово» без mode (нет ни ветки world=run_check, ни source=gate) — диспетчер
# отклоняет конверт как неполный (асимметрия): «сделано» без объявленного способа
# сверки с миром не штампуется «проверено». Это честный предел по конструкции:
# необъявленная словесная опора вне охвата (цена отказа от парсера речи).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-12-done-no-method-unverified RED done без способа сверки -> не проверено"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

CLAIM='{"kind":"done_report","text":"всё готово, поверьте на слово"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 3 "$RC"                                 || rc=1
assert_out_has "UNVERIFIED_INVALID_ENVELOPE" "$OUT" || rc=1
assert_out_has "способ сверки" "$OUT"               || rc=1
exit "$rc"
