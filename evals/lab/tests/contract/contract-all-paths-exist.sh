#!/usr/bin/env bash
# CONTRACT: каждый intra-путь из дедуплицированного contract_paths существует
# в ai-dev-system. Любой отсутствующий → exit 1 + PHANTOM + источник.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST contract-all-paths-exist CONTRACT все пути методологии на месте"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

TSV="${LAB_DIR}/fixtures/contract_paths.tsv"
CHECKER="${LAB_DIR}/tests/contract/check_paths.py"

OUT="$(CONTRACT_TSV="$TSV" REPO_ROOT="$REPO_ROOT" python3 "$CHECKER" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"          || rc=1
assert_out_has "OK:" "$OUT"  || rc=1
assert_out_has "путей на месте" "$OUT" || rc=1
# Если был хоть один PHANTOM — это провал контракта.
assert_out_lacks "PHANTOM:" "$OUT" || rc=1
if [[ "$rc" != 0 ]]; then
  echo "    --- вывод проверки ---"
  printf '%s\n' "$OUT" | sed 's/^/    /'
fi
exit "$rc"
