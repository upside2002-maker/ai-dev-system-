#!/usr/bin/env bash
# PASS: русский текст + латиница ВНУТРИ inline-кода (backticks) НЕ блокируется.
# Хук вырезает код/инлайн-код перед проверкой прозы — латиница в `командах` и
# именах файлов законна. Снаружи backticks — только русский, блока быть не должно.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ruguard-code-fence-pass PASS латиница в backticks -> не блокирует"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Латиница (в т.ч. то, что иначе сошло бы за английскую прозу) — внутри `…`.
TR="$(ru_transcript "$WORK" \
  "Запусти команду \`make check and run all the lab tests now\` и посмотри вывод.")"
OUT="$(run_ru_guard "$TR")"

rc=0
assert_out_lacks '"decision": "block"' "$OUT"  || rc=1
exit "$rc"
