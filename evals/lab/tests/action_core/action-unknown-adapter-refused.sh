#!/usr/bin/env bash
# RED (ворота дел, анти-ведро): адаптер записи не из БЕЛОГО СПИСКА → отказ
# (exit≠0). Модель выбирает адаптер из набора, произвольную команду-исполнитель
# подать не может (иначе ведро: «исполни что хочу»). Журнал и маркер не созданы.
# Временный реестр.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST action-unknown-adapter-refused RED адаптер вне белого списка -> отказ"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

OUT="$(run_aida_action "$LED" --by worker action \
        --kind "shell.exec" --target "x" --change "y")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                            || rc=1
assert_out_has "Белый список" "$OUT"                 || rc=1
assert_file_absent "$LED/actions.jsonl"              || rc=1
exit "$rc"
