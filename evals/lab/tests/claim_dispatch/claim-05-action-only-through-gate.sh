#!/usr/bin/env bash
# PASS+RED (#5 Owner): action_request исполняется ТОЛЬКО через ворота дел.
# (а) честная заявка marker.write → влитой cmd_action открывает requested,
#     исполняет РОВНО заявку, пишет executed, кладёт маркер в наблюдаемую зону —
#     вердикт passed (OK_ACTION_EXECUTED), журнал и маркер на месте;
# (б) заявка с целью в КРИТПУТИ (scripts/**) → ворота дел отказывают (stop),
#     маркера нет, в критпуть этим путём не пишут. Доказывает: мир меняется
#     только через защищённый адаптер, не «как попало».
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-05-action-only-through-gate RED действие только через ворота дел"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"
trap 'rm -rf "$LED" "$ERRF"' EXIT
rm -f "$ERRF"

rc=0
# (а) честный путь: заявка → executed → маркер в мире.
OK_CLAIM='{"kind":"action_request","text":"задеплоил v42","act_kind":"marker.write","target":"deploy_state","change":"v42"}'
OUT="$(printf '%s' "$OK_CLAIM" | run_aida_claim gate "$LED" "$ERRF")"; ARC=$?
assert_exit 0 "$ARC"                                 || rc=1
assert_out_has "OK_ACTION_EXECUTED" "$OUT"           || rc=1
assert_file_exists "$(observed_marker "$LED" deploy_state)" || rc=1
# В журнале действий есть executed-строка (исполнено РОВНО заявкой).
if ! grep -q '"phase": "executed"' "$LED/actions.jsonl" 2>/dev/null; then
  echo "    нет executed-строки в журнале действий"; rc=1
fi

# (б) критпуть: ворота дел отказывают, маркера нет.
BAD_CLAIM='{"kind":"action_request","text":"трону scripts","act_kind":"marker.write","target":"scripts/evil","change":"x"}'
OUT2="$(printf '%s' "$BAD_CLAIM" | run_aida_claim gate "$LED" "$ERRF")"; BRC=$?
assert_exit 4 "$BRC"                                 || rc=1
assert_out_has "STOP_ACTION_REFUSED" "$OUT2"         || rc=1
assert_out_has "критпут" "$OUT2"                     || rc=1
exit "$rc"
