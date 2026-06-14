#!/usr/bin/env bash
# RED (ворота дел): прямая запись в наблюдаемую зону МИМО ядра, без заявки.
# Маркер появился в мире, а в журнале действий НЕТ соответствующего executed.
# Сверка-с-миром обязана пометить это ИНЦИДЕНТОМ (exit≠0) — обход журнала.
# Это покрывает обязательную правку критика «сверка-с-МИРОМ, а не журнала с
# собой»: артефакт без записи ядра ловится постфактум. Временный реестр.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST action-direct-write-incident RED маркер без заявки -> инцидент"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

# Пустой журнал действий + прямая запись маркера в мир (обход ядра).
: > "$LED/actions.jsonl"
mkdir -p "$LED/observed"
printf 'snuck in mimo yadra' > "$LED/observed/rogue_marker"

OUT="$(run_aida_check "$LED")"; RC=$?

rc=0
assert_exit_nonzero "$RC"                          || rc=1
assert_out_has "ИНЦИДЕНТ (ворота дел)" "$OUT"      || rc=1
assert_out_has "изменён БЕЗ заявки" "$OUT"         || rc=1
exit "$rc"
