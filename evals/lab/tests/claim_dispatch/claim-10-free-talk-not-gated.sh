#!/usr/bin/env bash
# PASS (#10 Owner): свободный разговор НЕ блокируется. Диспетчер срабатывает
# ТОЛЬКО на поданный конверт; свободная речь конверт не выставляет — значит
# мимо ворот ПО КОНСТРУКЦИИ. Доказываем двояко (анти-тормоз):
#  (а) валидный ПРОВЕРЕННЫЙ конверт (fact_claim, источник подтверждает) проходит
#      чисто — passed, наружу [проверено], в журнал ошибок НЕ пишется: ворота не
#      краснеют на честном;
#  (б) структурно: диспетчер не читает свободный текст как сырьё классификации —
#      поле text переносится как есть, авто-классификации речи нет (см. также
#      contract-no-freetext-parser). Здесь проверяем (а) поведенчески.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-10-free-talk-not-gated PASS свободная речь -> не гейтится"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

# Память подтверждает заявленное значение — честный проверенный факт.
seed_memory_fact "$LED" build_status green

CLAIM='{"kind":"fact_claim","text":"сборка зелёная — рассуждаю вслух, опираюсь на проверенное","adapter":"ledger.fact","arg":"build_status","expected":"green"}'
OUT="$(printf '%s' "$CLAIM" | run_aida_claim gate "$LED" "$ERRF")"; RC=$?

rc=0
assert_exit 0 "$RC"                       || rc=1
assert_out_has "OK_SOURCE_MATCH" "$OUT"   || rc=1
assert_out_has "проверено" "$OUT"         || rc=1
# Честный путь НЕ пишет в журнал ошибок (нет ложного срабатывания на речи).
assert_file_absent "$ERRF"                || rc=1
exit "$rc"
