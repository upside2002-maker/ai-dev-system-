#!/usr/bin/env bash
# PASS (АНТИ-ТОРМОЗ): свободное рассуждение (type=reasoning) проходит мимо гейта
# — ядро проверяет НЕ мысль, а переход к опоре. Обычный разговор не гейтится:
# вердикт passed (exit 0) по коду OK_REASONING, в журнал ошибок ничего не пишется.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-reasoning-passes-fast PASS свободное рассуждение -> мимо гейта"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

CLAIM='{"type":"reasoning","text":"Давай прикинем варианты, ничего не утверждаю как факт."}'
OUT="$(printf '%s' "$CLAIM" | run_aida_kernel gate "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 0 "$RC"                    || rc=1
assert_out_has "OK_REASONING" "$OUT"   || rc=1
assert_file_absent "$ERRF"             || rc=1
exit "$rc"
