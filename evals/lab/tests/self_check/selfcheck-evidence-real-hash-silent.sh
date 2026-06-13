#!/usr/bin/env bash
# PASS (анти-ложный-срабат к фиксу десятичного хеша): НАСТОЯЩИЙ git short hash
# (есть hex-буква a-f) обязан гасить WARN. Доказывает, что ужесточение под
# десятичное число не сломало легитимный случай: дата+git-слово+реальный хеш.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-real-hash-silent PASS реальный хеш гасит WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'Выкат на прод 2026-06-10 a1b2c3d — настоящий short hash.')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                  || rc=1
assert_out_lacks "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
exit "$rc"
