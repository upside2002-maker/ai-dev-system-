#!/usr/bin/env bash
# RED (ворота дел): защищённый адаптер записи ОТКАЗЫВАЕТ на цель в критпути
# (scripts/**) без заявки/права. Отказ (exit≠0) наступает ДО открытия заявки —
# журнал действий остаётся пуст (нечего журналировать на запрещённую цель).
# v0.1 в критпуть не пишет (денежный/системный контур — поздний слой). Временный
# реестр; живой репозиторий не задет.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST action-critpath-refused RED запись в критпуть без заявки -> отказ"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

OUT="$(run_aida_action "$LED" --by worker action \
        --kind marker.write --target "scripts/evil.sh" --change "rm -rf")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                     || rc=1
assert_out_has "критпути" "$OUT"              || rc=1
# Побочного эффекта нет: ни журнала действий, ни маркера не создано.
assert_file_absent "$LED/actions.jsonl"       || rc=1
assert_file_absent "$LED/observed"            || rc=1
exit "$rc"
