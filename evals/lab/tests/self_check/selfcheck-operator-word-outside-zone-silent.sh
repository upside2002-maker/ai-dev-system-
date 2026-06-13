#!/usr/bin/env bash
# PASS: те же слова ВНЕ user-facing зоны → WARN про запрещённые слова НЕТ.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-operator-word-outside-zone-silent PASS слова вне зоны молчат"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

# Маркеров user-facing вовсе нет — проверка слов пропускается.
F="$(write_handoff_fixture "$WORK" \
  'Внутренний агентный текст: нужно accept задачу и сделать commit.')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                   || rc=1
assert_out_lacks "найдены запрещённые слова" "$OUT"                   || rc=1
assert_out_has "самопроверка прошла чисто" "$OUT"                     || rc=1
exit "$rc"
