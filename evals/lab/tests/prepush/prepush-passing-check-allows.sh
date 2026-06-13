#!/usr/bin/env bash
# PASS (анти-ложный-срабат к §D): когда `make check` зелёный — pre-push
# ПРОПУСКАЕТ push (exit 0). Симметрично red-кейсу: тот же настоящий хук, но
# временный Makefile с check, который проходит. Доказывает, что замок не глухой
# (не всегда отклоняет), а реагирует именно на код make check.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST prepush-passing-check-allows PASS make check зелёный -> push разрешён"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.githooks"
cp "$REPO_ROOT/.githooks/pre-push" "$WORK/.githooks/pre-push"
chmod +x "$WORK/.githooks/pre-push"

printf 'check:\n\t@echo "[lab] состояние согласовано — make check зелёный"\n' > "$WORK/Makefile"

OUT="$(printf '' | bash "$WORK/.githooks/pre-push" origin "git@example:repo" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                       || rc=1
assert_out_has "отправляю" "$OUT"         || rc=1
exit "$rc"
