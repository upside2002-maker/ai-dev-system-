#!/usr/bin/env bash
# RED (#8 Owner): заявка с неподдержанным типом → отклонена. Конверт с kind вне
# пяти известных (диспетчер маршрутизирует только fact_claim/advice_basis/
# capability_check/action_request/done_report) → unverified
# (UNVERIFIED_UNSUPPORTED_KIND), наружу не как опора. Анти-ведро на уровне типа:
# нет маршрута — нет вердикта «проверено».
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-08-unsupported-kind-rejected RED неизвестный kind -> отклонён"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

CLAIM='{"kind":"prophecy","text":"я предсказываю будущее"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 3 "$RC"                                  || rc=1
assert_out_has "UNVERIFIED_UNSUPPORTED_KIND" "$OUT"  || rc=1
exit "$rc"
