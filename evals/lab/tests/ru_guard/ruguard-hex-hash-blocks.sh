#!/usr/bin/env bash
# RED: прозаический русский текст с git-хешем (b1c9107 — 7 hex, есть буква) →
# block. Хеши коммитов в тексте для пользователя запрещены (операторский язык).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ruguard-hex-hash-blocks RED git-хеш в прозе -> block"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TR="$(ru_transcript "$WORK" \
  "Я внёс правку, она теперь лежит в b1c9107 и всё на месте.")"
OUT="$(run_ru_guard "$TR")"

rc=0
assert_out_has '"decision": "block"' "$OUT"  || rc=1
assert_out_has 'хеш' "$OUT"                  || rc=1
exit "$rc"
