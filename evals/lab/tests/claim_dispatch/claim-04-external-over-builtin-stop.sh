#!/usr/bin/env bash
# RED (#4 Owner): внешний инструмент НЕ предлагается первым, если реестр знает
# встроенный. capability_check предлагает telegram_bridge (внешнее) под need
# remote_control, а в реестре возможностей есть встроенное claude.remote_control
# под тот же need → влитой capability-ворота ядра дают stop «сначала встроенное»
# (случай «Телеграм»). Реестр возможностей — ЖИВОЙ из репо (источник правды).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-04-external-over-builtin-stop RED Телеграм при встроенном -> стоп"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

CLAIM='{"kind":"capability_check","text":"предлагаю телеграм-бота для управления","tool":"telegram_bridge","need":"remote_control"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim eval "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 4 "$RC"                                || rc=1
assert_out_has "STOP_EXTERNAL_OVER_BUILTIN" "$OUT" || rc=1
assert_out_has "сначала встроенное" "$OUT"         || rc=1
exit "$rc"
