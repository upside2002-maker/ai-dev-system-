#!/usr/bin/env bash
# RED (И-6): факт со scope вне словаря допустимых → ошибка с номером строки.
# Доказывает, что ось области (scope) не принимает произвольное значение.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-bad-enum RED scope вне словаря -> ошибка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Факт с битой областью.","scope":"marsianskaya","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                 || rc=1
assert_out_has "facts.jsonl:1" "$OUT"     || rc=1
assert_out_has "scope" "$OUT"             || rc=1
exit "$rc"
