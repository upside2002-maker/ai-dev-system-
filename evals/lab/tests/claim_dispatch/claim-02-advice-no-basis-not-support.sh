#!/usr/bin/env bash
# RED (#2 Owner): совет без advice_basis НЕ принимается как архитектурная опора.
# Конверт advice_basis ОБЯЗАН нести supports (список ключей-опор). Без поля
# supports конверт неполон → диспетчер отклоняет (unverified, асимметрия):
# совет, не объявивший на чём держится, не становится опорой по желанию модели.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-02-advice-no-basis-not-support RED совет без опор -> не опора"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

# advice_basis без поля supports — неполный конверт.
CLAIM='{"kind":"advice_basis","text":"делай всегда так","horizon":"permanent"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 3 "$RC"                                 || rc=1
assert_out_has "UNVERIFIED_INVALID_ENVELOPE" "$OUT" || rc=1
assert_out_has "supports" "$OUT"                    || rc=1
exit "$rc"
