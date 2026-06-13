#!/usr/bin/env bash
# RED (И-14): supersedes факта на несуществующий id → ссылка в никуда, ошибка.
# История замены должна указывать на реально существующий прежний факт.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-supersedes-nowhere RED supersedes в никуда -> ошибка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-002","statement":"Факт ссылается на несуществующий.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":"F-20990101-999","origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                  || rc=1
assert_out_has "supersedes" "$OUT"         || rc=1
assert_out_has "в никуда" "$OUT"           || rc=1
exit "$rc"
