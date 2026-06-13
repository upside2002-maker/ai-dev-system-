#!/usr/bin/env bash
# PASS: те же слова в backticks внутри зоны → WARN про запрещённые слова НЕТ
# (backtick-блоки — технические имена, скрипт их игнорирует).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-operator-word-in-backticks-silent PASS слова в backticks молчат"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

# shellcheck disable=SC2016  # backticks — литеральные данные теста, не подстановка
F="$(write_handoff_fixture "$WORK" \
  '<!-- user-facing -->' \
  'Технические имена в backticks допустимы: `accept` и `commit` — это не для пользователя.' \
  '<!-- /user-facing -->')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                  || rc=1
assert_out_lacks "найдены запрещённые слова" "$OUT"  || rc=1
exit "$rc"
