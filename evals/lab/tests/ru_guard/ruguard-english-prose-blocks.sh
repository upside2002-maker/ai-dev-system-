#!/usr/bin/env bash
# RED: ответ с длинной английской прозой (6+ латинских слов подряд вне ALLOW) →
# хук печатает {"decision": "block", ...}. Признак блока — подстрока
# '"decision": "block"' в stdout (код выхода у хука всегда 0).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ruguard-english-prose-blocks RED английская проза -> block"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TR="$(ru_transcript "$WORK" \
  "This is a long sentence of plain english prose without any russian words at all.")"
OUT="$(run_ru_guard "$TR")"

rc=0
assert_out_has '"decision": "block"' "$OUT"  || rc=1
exit "$rc"
