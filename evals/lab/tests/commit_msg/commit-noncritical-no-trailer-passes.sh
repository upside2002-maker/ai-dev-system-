#!/usr/bin/env bash
# PASS: правка некритичного README_local.txt (вне зон), без Approved-by →
# замок не вмешивается, коммит создаётся. Анти-ложный-срабат для И-11.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST commit-noncritical-no-trailer-passes PASS некритичный коммит без трейлера проходит"

if ! has_git; then echo "git недоступен"; exit 77; fi

WORK="$(make_git_repo_with_hook)"
trap 'rm -rf "$WORK"' EXIT

BEFORE="$(git_head_count "$WORK")"
printf 'локальная заметка\n' > "$WORK/README_local.txt"
git -C "$WORK" add README_local.txt

OUT="$(git -C "$WORK" commit -m "правка некритичного файла без подписи" 2>&1)"; RC=$?
AFTER="$(git_head_count "$WORK")"

rc=0
assert_exit 0 "$RC" || rc=1
if [[ "$AFTER" != "$((BEFORE + 1))" ]]; then
  echo "    коммит НЕ создан ($BEFORE -> $AFTER), а замок не должен был вмешаться"
  echo "    вывод: $OUT"
  rc=1
fi
# Подстраховка: новая запись в git log --oneline.
# Лог захватываем в переменную и грепаем её, а НЕ `git log | grep -q`:
# под `set -o pipefail` ранний выход `grep -q` шлёт SIGPIPE в `git log`,
# и статус пайплайна становится 141 (смерть git), а не 0 (греп нашёл) —
# ложный FAIL при реально созданном коммите.
LOG="$(git -C "$WORK" log --oneline)"
if [[ "$LOG" != *"правка некритичного файла"* ]]; then
  echo "    нет записи о коммите в git log --oneline"
  echo "    log: $LOG"
  rc=1
fi
exit "$rc"
