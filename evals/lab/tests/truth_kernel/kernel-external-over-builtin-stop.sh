#!/usr/bin/env bash
# RED #2 (ВОЗМОЖНОСТИ, случай «Телеграм»): реестр возможностей несёт встроенное
# claude.remote_control под потребность remote_control. Совет предлагает ВНЕШНИЙ
# telegram_bridge первым под ту же потребность. Ядро ДЕТЕРМИНИРОВАННО
# останавливает: «сначала встроенное». Вердикт выносит КОД (exit 4 = stop).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-external-over-builtin-stop RED Телеграм при встроенном -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT

CLAIM='{"type":"recommendation","text":"Поставь Телеграм-бота первым для управления","tool":"telegram_bridge","need":"remote_control"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                              || rc=1
assert_out_has "STOP_EXTERNAL_OVER_BUILTIN" "$OUT" || rc=1
assert_out_has "сначала встроенное" "$OUT"       || rc=1
exit "$rc"
