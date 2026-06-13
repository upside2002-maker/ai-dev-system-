#!/usr/bin/env bash
# RED-семантика (И-14): запись в реестр — ТОЛЬКО дозапись. Берём валидный
# реестр из одной строки, снимаем md5 КАЖДОЙ строки, прогоняем `aida fact`
# (создаёт новый факт) и доказываем: ни одна старая строка не изменилась (md5
# совпали), добавилась ровно одна строка. Операция идёт против ВРЕМЕННОГО
# каталога (AIDA_LEDGER_DIR) — живой ledger/ не задет.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-append-only RED-семантика запись = только дозапись (И-14)"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

ledger_write "$LED" facts.jsonl \
  '{"id":"F-20260612-001","statement":"Старый факт, трогать нельзя.","scope":"system","status":"verified","confidence":"high","source":{"kind":"file","ref":"x"},"checked_at":"2026-06-12","expires":null,"supersedes":null,"origin":null,"recorded_by":"lab","recorded_at":"2026-06-12T10:00:00+03:00"}'

FACTS="$LED/facts.jsonl"
LINES_BEFORE="$(wc -l < "$FACTS" | tr -d ' ')"
# md5 каждой строки ДО операции.
MD5_BEFORE="$(while IFS= read -r ln; do printf '%s' "$ln" | (md5 2>/dev/null || md5sum 2>/dev/null | awk '{print $1}'); echo; done < "$FACTS")"

# Операция записи через ЖИВОЙ aida против временного каталога.
OP="$(AIDA_LEDGER_DIR="$LED" bash "$REPO_ROOT/scripts/aida" fact \
  "Новый факт лаборатории." --scope system \
  --source-kind file --source-ref "evals/lab" 2>&1)"; OPRC=$?

LINES_AFTER="$(wc -l < "$FACTS" | tr -d ' ')"
# md5 первых LINES_BEFORE строк ПОСЛЕ операции (старая часть файла).
MD5_AFTER_OLD="$(head -n "$LINES_BEFORE" "$FACTS" | while IFS= read -r ln; do printf '%s' "$ln" | (md5 2>/dev/null || md5sum 2>/dev/null | awk '{print $1}'); echo; done)"

rc=0
if ! assert_exit 0 "$OPRC"; then
  echo "    вывод операции aida fact: ${OP}"
  rc=1
fi
# Добавилась ровно одна строка.
if [[ "$LINES_AFTER" != "$((LINES_BEFORE + 1))" ]]; then
  echo "    ожидалось +1 строка: было ${LINES_BEFORE}, стало ${LINES_AFTER}"
  rc=1
fi
# Старые строки байт-в-байт не тронуты.
if [[ "$MD5_BEFORE" != "$MD5_AFTER_OLD" ]]; then
  echo "    старые строки реестра изменились — нарушена дозаписываемость (И-14)"
  rc=1
fi
exit "$rc"
