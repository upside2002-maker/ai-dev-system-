#!/usr/bin/env bash
# RED: две строки фактов с одним id → ошибка про дубль. id обязан быть уникален
# в файле (история состояния идёт через supersedes/новый id, а не повтор того же).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-dup-id RED дубль id факта -> ошибка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Первый.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}' \
  '{"id":"F-20260612-001","statement":"Второй с тем же id.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"y"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:01:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"              || rc=1
assert_out_has "дубл" "$OUT"          || rc=1
exit "$rc"
