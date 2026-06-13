#!/usr/bin/env bash
# RED (И-5): факт с ПРОБЕЛЬНЫМИ source.kind/source.ref — не источник. Валидатор
# обязан упасть (exit≠0) с подстрокой про «источник (И-5)». Доказывает, что
# обход через "  " вместо отсутствия поля не проходит. Временный реестр.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-fact-no-source RED факт без источника -> ошибка И-5"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Факт без источника.","scope":"system","status":"verified","confidence":"high","source":{"kind":"  ","ref":""},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                || rc=1
assert_out_has "источника (И-5)" "$OUT"  || rc=1
exit "$rc"
