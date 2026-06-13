#!/usr/bin/env bash
# RED* (И-5): чисто-десятичное 7+-значное число НЕ должно маскироваться под
# git short hash. До фикса '\b[a-f0-9]{7,}\b' ловил и десятичное — заявка
# 'Выкат на прод 2026-06-10 1234567' гасила WARN фальшивым «хешем». Теперь
# настоящий хеш обязан содержать hex-букву (a-f); десятичное число — нет.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-decimal-not-hash-warns RED* десятичное не хеш -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'Выкат на прод 2026-06-10 1234567 без настоящего хеша.')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                || rc=1
assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
exit "$rc"
