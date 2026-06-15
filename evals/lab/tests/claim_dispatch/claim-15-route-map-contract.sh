#!/usr/bin/env bash
# CONTRACT: таблица маршрутов — РОВНО пять строк kind, и каждая ведёт в УЖЕ
# ВЛИТОЙ верификатор (диспетчер сам не проверяет, проверка переиспользована
# import'ом). Печать типов берём у живого диспетчера (aida-claim kinds), маршруты
# — структурно по исходнику: fact/advice/capability → aida_kernel.gate;
# action → aida_ledger.cmd_action; done → run_check / gate(fact).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-15-route-map-contract CONTRACT 5 типов -> влитые верификаторы"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

OUT="$(bash "${REPO_ROOT}/scripts/aida-claim" kinds 2>&1)"; RC=$?
SRC="${REPO_ROOT}/scripts/aida_claim.py"

rc=0
assert_exit 0 "$RC" || rc=1
# Ровно пять типов.
for k in fact_claim advice_basis capability_check action_request done_report; do
  assert_out_has "$k" "$OUT" || rc=1
done
N="$(printf '%s\n' "$OUT" | grep -c '.')"
if [[ "$N" != "5" ]]; then echo "    типов не 5, а ${N}: $OUT"; rc=1; fi

# Диспетчер переиспользует ВЛИТЫЕ ядра import'ом (не дублирует проверку).
assert_file_exists "$SRC" || rc=1
grep -q "import aida_kernel as K" "$SRC" || { echo "    нет import aida_kernel"; rc=1; }
grep -q "import aida_ledger as L"  "$SRC" || { echo "    нет import aida_ledger"; rc=1; }
# Маршруты ведут в влитые верификаторы.
grep -q "K.gate"        "$SRC" || { echo "    fact/advice/capability не идут в K.gate"; rc=1; }
grep -q "L.cmd_action"  "$SRC" || { echo "    action не идёт в L.cmd_action"; rc=1; }
grep -q "L.run_check"   "$SRC" || { echo "    done(world) не идёт в L.run_check"; rc=1; }

# Диспетчер НЕ держит своей логики сверки источников: нет своих адаптеров/
# резолверов (они только в ядре). Грубо: нет определения ADAPTERS/резолверов тут.
if grep -qE "^ADAPTERS\s*=|def _adapter_" "$SRC"; then
  echo "    диспетчер дублирует адаптеры ядра — должен переиспользовать"; rc=1
fi
exit "$rc"
