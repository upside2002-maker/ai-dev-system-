#!/usr/bin/env bash
# RED (замок рассинхрона): pre-push гоняет `make check` и при его падении
# ОТКЛОНЯЕТ push (exit≠0). Полный make check живого репо тянет реальные
# проверки продукта — изолируем точечно (как разрешает ТЗ §D): берём НАСТОЯЩИЙ
# .githooks/pre-push, кладём рядом временный Makefile, чей `check` краснеет
# (exit 1), и доказываем контракт «make check упал → push отклонён». Хук берём
# дословно из живого репо — проверяем именно его логику проброса кода.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST prepush-failed-check-rejects RED make check упал -> push отклонён"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.githooks"
cp "$REPO_ROOT/.githooks/pre-push" "$WORK/.githooks/pre-push"
chmod +x "$WORK/.githooks/pre-push"

# Временный Makefile: check НАМЕРЕННО падает (имитация рассинхрона состояния).
printf 'check:\n\t@echo "[lab] имитация рассинхрона — make check краснеет"; exit 1\n' > "$WORK/Makefile"

# pre-push читает refs со stdin; контракт замка — упасть ДО анализа refs, на
# самом make check. Подаём пустой stdin (push без ветки не важен — замок раньше).
OUT="$(printf '' | bash "$WORK/.githooks/pre-push" origin "git@example:repo" 2>&1)"; RC=$?

rc=0
assert_exit_nonzero "$RC"                 || rc=1
assert_out_has "ОТКАЗ" "$OUT"             || rc=1
exit "$rc"
