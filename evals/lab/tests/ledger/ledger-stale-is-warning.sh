#!/usr/bin/env bash
# PASS-семантика (И-13): факт с expires в прошлом, статус не stale — это
# ПРЕДУПРЕЖДЕНИЕ, а не ошибка. Доказываем: реестр остаётся валидным (exit 0),
# но протухшее помечено в блоке предупреждений. Срок годности не роняет ворота.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-stale-is-warning PASS протухший факт -> предупреждение, не ошибка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

# expires в далёком прошлом, статус verified (не stale/superseded).
ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Протухший факт.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2020-01-01","expires":"2020-06-01","supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2020-01-01T10:00:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit 0 "$RC"                    || rc=1
assert_out_has "реестр валиден" "$OUT" || rc=1
assert_out_has "протух" "$OUT"         || rc=1
exit "$rc"
