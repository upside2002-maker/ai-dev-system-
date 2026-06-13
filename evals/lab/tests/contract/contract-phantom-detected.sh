#!/usr/bin/env bash
# CONTRACT (негативный самотест): во ВРЕМЕННОЙ копии добавить ссылку на
# policies/PHANTOM_DOES_NOT_EXIST.md, прогнать проверку → exit≠0 + имя фантома.
# Доказывает, что детектор реально краснеет (а не всегда зелёный).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST contract-phantom-detected CONTRACT детектор краснеет на фантоме"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TSV="${LAB_DIR}/fixtures/contract_paths.tsv"
CHECKER="${LAB_DIR}/tests/contract/check_paths.py"

# Дополнительный TSV только с фантомом — основной список не трогаем.
EXTRA="$WORK/extra.tsv"
printf 'intra\tpolicies/PHANTOM_DOES_NOT_EXIST.md\tlab-negative-selftest\n' > "$EXTRA"

OUT="$(CONTRACT_TSV="$TSV" EXTRA_TSV="$EXTRA" REPO_ROOT="$REPO_ROOT" python3 "$CHECKER" 2>&1)"; RC=$?

rc=0
assert_exit_nonzero "$RC"                                || rc=1
assert_out_has "PHANTOM_DOES_NOT_EXIST.md" "$OUT"        || rc=1
assert_out_has "PHANTOM:" "$OUT"                         || rc=1
exit "$rc"
