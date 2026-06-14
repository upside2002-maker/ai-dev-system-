#!/usr/bin/env bash
# CONTRACT (АНТИ-ВЕДРО): белый список адаптеров ядра — РОВНО семь имён из ТЗ, и
# среди них НЕТ адаптера произвольной команды (shell/exec/run/eval/system/cmd).
# Доказывает структурно: нет пути «модель подаёт команду-проверку». Печать
# списка берём у живого ядра (aida-kernel adapters), не из памяти теста.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST kernel-whitelist-contract CONTRACT белый список = 7 адаптеров, нет команды"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

OUT="$(bash "${REPO_ROOT}/scripts/aida-kernel" adapters 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC" || rc=1
# Все семь имён из ТЗ присутствуют.
for name in ledger.fact project.status git.snapshot capability.exists \
            billing.manual_record file.exists test.result; do
  assert_out_has "$name" "$OUT" || rc=1
done
# Ровно семь строк (никаких лишних адаптеров).
N="$(printf '%s\n' "$OUT" | grep -c '.')"
if [[ "$N" != "7" ]]; then
  echo "    адаптеров не 7, а ${N}: $OUT"; rc=1
fi
# Нет адаптера произвольной команды.
for bad in shell exec "run " eval system "cmd" subprocess; do
  assert_out_lacks "$bad" "$OUT" || rc=1
done
exit "$rc"
