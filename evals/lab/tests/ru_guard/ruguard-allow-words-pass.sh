#!/usr/bin/env bash
# PASS: русский текст с латинскими словами из ALLOW-списка (Claude, git, Sitka,
# Aida — имена продуктов/команд) НЕ блокируется: это не «английская проза» и не
# «каша», а законные имена. Хук должен молчать (нет '"decision": "block"').
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ruguard-allow-words-pass PASS слова из ALLOW -> не блокирует"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TR="$(ru_transcript "$WORK" \
  "Я открыл Claude и через git собрал сборку для Sitka, ядро Aida на месте.")"
OUT="$(run_ru_guard "$TR")"

rc=0
assert_out_lacks '"decision": "block"' "$OUT"  || rc=1
exit "$rc"
