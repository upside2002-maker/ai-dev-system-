#!/usr/bin/env bash
# PASS (ворота дел, честный путь): модель ЗАЯВИЛА действие (цель+изменение),
# ядро исполнило РОВНО заявку, записало requested+executed, маркер мира совпал
# с journal-полем change → сверка-с-миром в aida check ПРОХОДИТ (exit 0). Это
# анти-ложный-срабат: на честном «заявил=исполнил=записал» инцидента нет.
# Временный реестр — живой ledger/ не задет (AIDA_LEDGER_DIR).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST action-honest-path-passes PASS заявил=исполнил=записал -> проходит"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

# Заявка+исполнение одним проходом: ядро пишет requested и executed.
ACT="$(run_aida_action "$LED" --by worker action \
        --kind marker.write --target deploy_state --change "v42 deployed")"
ARC=$?

# Сверка-с-миром: маркер совпал с заявкой → check зелёный.
OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit 0 "$ARC"                              || rc=1
assert_out_has "исполнено РОВНО заявкой" "$ACT"   || rc=1
assert_exit 0 "$RC"                               || rc=1
assert_out_has "реестр валиден" "$OUT"            || rc=1
assert_out_lacks "ИНЦИДЕНТ" "$OUT"                || rc=1
# Побочный эффект на месте: маркер мира создан с заявленным содержимым.
assert_file_exists "$(observed_marker "$LED" deploy_state)" || rc=1
exit "$rc"
