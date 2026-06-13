#!/usr/bin/env bash
# PASS: чистый русский без латиницы и хешей → хук молчит (нет блока). Базовый
# анти-ложный-срабат: нормальный операторский ответ проходит свободно.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ruguard-clean-russian-pass PASS чистый русский -> не блокирует"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TR="$(ru_transcript "$WORK" \
  "Я всё сделал по-русски, лишнего не написал, правки на месте и проверены.")"
OUT="$(run_ru_guard "$TR")"

rc=0
assert_out_lacks '"decision": "block"' "$OUT"  || rc=1
exit "$rc"
