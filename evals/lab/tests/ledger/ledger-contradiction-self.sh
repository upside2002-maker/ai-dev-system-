#!/usr/bin/env bash
# RED: противоречие с a == b — факт не спорит сам с собой. Валидатор обязан
# отвергнуть самопротиворечие. Факт существует (чтобы ошибка была именно про
# a==b, а не про несуществующую сторону).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-contradiction-self RED противоречие a==b -> ошибка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Единственный факт.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'
ledger_write "$LED" contradictions.jsonl \
  '{"id":"C-20260612-001","a":"F-20260612-001","b":"F-20260612-001","working":"F-20260612-001","resolves_when":"никогда","status":"open","resolved_by":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:01:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                          || rc=1
assert_out_has "a и b совпадают" "$OUT"            || rc=1
exit "$rc"
