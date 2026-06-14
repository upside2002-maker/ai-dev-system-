#!/usr/bin/env bash
# RED (ворота дел, форма журнала): строка действия с фазой failed БЕЗ непустого
# reason — рассогласование формы. Валидатор журнала действий в aida check обязан
# упасть (exit≠0). Доказывает, что схема action.schema.json принуждена кодом, а
# не на честном слове. Временный реестр; маркера мира тут нет (executed нет) —
# проверяем именно ветку формы журнала, не сверку-с-миром.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST action-journal-shape-bad RED failed без reason -> ошибка формы"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

# requested + failed, но failed без reason — невалидная форма.
ledger_write "$LED" actions.jsonl \
  '{"id":"A-20260614-001","phase":"requested","kind":"marker.write","target":"x","change":"y","recorded_by":"lab","recorded_at":"2026-06-14T10:00:00+03:00"}' \
  '{"id":"A-20260614-001","phase":"failed","kind":"marker.write","target":"x","change":"y","recorded_by":"lab","recorded_at":"2026-06-14T10:00:01+03:00"}'

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                       || rc=1
assert_out_has "phase=failed без непустого reason" "$OUT" || rc=1
exit "$rc"
