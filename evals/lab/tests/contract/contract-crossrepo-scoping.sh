#!/usr/bin/env bash
# CONTRACT: cross-repo пути .claude/risk-tiers.md и .claude/agents/sitka-reviewer.md
# (упомянуты с контекстом «в sitka-office») резолвятся против
# $HOME/Projects/sitka-office, НЕ против ai-dev-system. Эти пути НЕ должны
# попадать в список фантомов (они есть в продуктовом репо). Регрессия наивного
# резолва (ложный phantom против ai-dev-system) краснит тест.
#
# Честность: если ~/Projects/sitka-office отсутствует — тест печатает SKIP
# (а не FAIL и не ложный PASS).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST contract-crossrepo-scoping CONTRACT cross-repo пути резолвятся в продуктовый репо"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

PRODUCT_REPO="${HOME}/Projects/sitka-office"
if [[ ! -d "$PRODUCT_REPO" ]]; then
  echo "продуктовый репо ~/Projects/sitka-office отсутствует — cross-repo проверку не выполнить"
  exit 77
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CHECKER="${LAB_DIR}/tests/contract/check_paths.py"

# Изолированный TSV только с cross-repo путями — проверяем именно scoping.
TSV="$WORK/crossrepo.tsv"
{
  printf 'crossrepo:sitka-office\t.claude/risk-tiers.md\tpolicies/MODES.md\n'
  printf 'crossrepo:sitka-office\t.claude/agents/sitka-reviewer.md\tROLE_MODEL.md\n'
} > "$TSV"

OUT="$(CONTRACT_TSV="$TSV" REPO_ROOT="$REPO_ROOT" python3 "$CHECKER" 2>&1)"; RC=$?

rc=0
# Должно быть OK: пути найдены в продуктовом репо, фантомов нет.
assert_exit 0 "$RC"                        || rc=1
assert_out_lacks "PHANTOM:" "$OUT"         || rc=1
assert_out_has "OK:" "$OUT"                || rc=1

# Регрессионный детектор: если эти же пути резолвить как intra (наивно против
# ai-dev-system) — они ОБЯЗАНЫ стать фантомами. Иначе тест ничего не доказывает.
NAIVE="$WORK/naive.tsv"
{
  printf 'intra\tproject-overlays/sitka-office/.claude/risk-tiers.md\tnaive\n'
} > "$NAIVE"
NAIVE_OUT="$(CONTRACT_TSV="$NAIVE" REPO_ROOT="$REPO_ROOT" python3 "$CHECKER" 2>&1)"; NRC=$?
assert_exit_nonzero "$NRC"                 || rc=1
assert_out_has "PHANTOM:" "$NAIVE_OUT"     || rc=1

if [[ "$rc" != 0 ]]; then
  echo "    --- cross-repo вывод ---"; printf '%s\n' "$OUT" | sed 's/^/    /'
fi
exit "$rc"
