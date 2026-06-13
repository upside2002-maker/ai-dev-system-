#!/usr/bin/env bash
# PASS (И-4/5/6): корректный минимальный реестр (один факт с источником) →
# aida check exit 0 и «реестр валиден». Доказывает, что валидатор не краснеет
# на здоровом реестре (база для остальных red-кейсов). Живой ledger/ не задет —
# проверка идёт против временного каталога через AIDA_LEDGER_DIR.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-valid-passes PASS корректный реестр -> валиден"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Тестовый факт лаборатории.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"evals/lab/tests/ledger"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit 0 "$RC"                 || rc=1
assert_out_has "реестр валиден" "$OUT" || rc=1
exit "$rc"
