#!/usr/bin/env bash
# RED (§8.4): битая строка JSON в реестре → ошибка с номером строки. Валидатор
# не падает трейсбэком, а указывает место. Вторая строка намеренно не-JSON.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-broken-json RED битый JSON -> ошибка с номером строки"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Целая строка.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}' \
  '{это не валидный JSON,,,'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                       || rc=1
assert_out_has "facts.jsonl:2" "$OUT"           || rc=1
assert_out_has "не является валидным JSON" "$OUT" || rc=1
exit "$rc"
