#!/usr/bin/env bash
# RED-семантика (И-3, ТЗ §5 — деградация): если реестр-ядро недоступно (битый
# ledger), aida-brief обязан сказать ЧЕСТНО «состояние не прочитал: <что>» —
# НИКОГДА не пустой экран и НИКОГДА не выдумка из памяти модели. На этом слое
# стоят все лица секретаря: лучше честное «не прочитал», чем тихий ноль или ложь.
#
# Подменяем реестр временным каталогом с БИТЫМИ jsonl (AIDA_LEDGER_DIR). Живой
# ledger/ не тронут. Снимки git / задачи / почта читаются read-only — они должны
# остаться доступными (доказываем, что падает ИМЕННО реестр, а не весь слой).
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST brief-degradation-broken-ledger RED битый реестр -> честное «не прочитал», не пустота"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT

# Все четыре файла реестра — невалидный JSON.
for base in facts decisions contradictions inbox; do
  ledger_write "$LED" "${base}.jsonl" '{битый json,,,'
done

# --- формат агента ----------------------------------------------------------
OUT="$(run_aida_brief "$LED" --for-agent)"; RC=$?

rc=0
assert_exit 0 "$RC"                                              || rc=1
# экран НЕ пустой
if [[ -z "${OUT//[[:space:]]/}" ]]; then
  echo "    aida-brief выдал пустой экран при битом реестре — нарушение И-3"
  rc=1
fi
# честная строка деградации присутствует для реестровых источников
assert_out_has "состояние не прочитал" "$OUT"                   || rc=1
assert_out_has "активные решения" "$OUT"                        || rc=1
assert_out_has "факты" "$OUT"                                   || rc=1
# слой не свалился целиком: остальные источники (снимки git) остались доступны
assert_out_has "LIVE-СНИМКИ ПРОЕКТОВ" "$OUT"                    || rc=1
# выдумки нет: при битом реестре не должно «появиться» решение с реальным id
assert_out_lacks "D-2026" "$OUT"                               || rc=1

# --- формат оператора (голос/телефон): та же честность -----------------------
OUT_OWNER="$(run_aida_brief "$LED" --for-owner)"; RC2=$?
assert_exit 0 "$RC2"                                            || rc=1
if [[ -z "${OUT_OWNER//[[:space:]]/}" ]]; then
  echo "    --for-owner выдал пустой экран при битом реестре — нарушение И-3"
  rc=1
fi
assert_out_has "Состояние не прочитал" "$OUT_OWNER"             || rc=1

# =============================================================================
#  F1 (CRITICAL, И-3): реестр НЕДОСТУПЕН (каталог/файлы отсутствуют) ≠ «пусто».
#  Корень: aida_ledger.read_records трактует ОТСУТСТВУЮЩИЙ файл как пустой
#  список → `aida show` выходит с кодом 0 и печатает бодрый ноль. Без проверки
#  доступности слой сказал бы владельцу «решений нет», когда память ПРОПАЛА.
#  Здесь доказываем: и пропавший каталог, и пустой каталог (без *.jsonl) дают
#  ЧЕСТНОЕ «состояние не прочитал» в ОБОИХ форматах, а НЕ нулевой экран.
# =============================================================================

# --- (а) AIDA_LEDGER_DIR указывает на НЕсуществующий каталог ------------------
GONE="$(make_tmp_ledger)"   # mktemp -d
rmdir "$GONE"               # теперь каталога нет вовсе
# trap не ставим: каталог уже удалён; временный LED чистится своим trap'ом.

OUT_GONE_A="$(run_aida_brief "$GONE" --for-agent)"; RC_GA=$?
assert_exit 0 "$RC_GA"                                          || rc=1
assert_out_has "состояние не прочитал" "$OUT_GONE_A"            || rc=1
assert_out_has "реестр недоступен" "$OUT_GONE_A"               || rc=1
# НЕ бодрый ноль: счётчиков «решений: 0»/«фактов нет» при пропаже быть не должно.
assert_out_lacks "сырых записок в карантине: 0" "$OUT_GONE_A"   || rc=1
assert_out_lacks "D-2026" "$OUT_GONE_A"                        || rc=1

OUT_GONE_O="$(run_aida_brief "$GONE" --for-owner)"; RC_GO=$?
assert_exit 0 "$RC_GO"                                          || rc=1
assert_out_has "Состояние не прочитал" "$OUT_GONE_O"            || rc=1
assert_out_has "реестр недоступен" "$OUT_GONE_O"              || rc=1
# Бодрого нуля владельцу быть не должно (память пропала, не «пусто»).
assert_out_lacks "Действующих решений: 0" "$OUT_GONE_O"         || rc=1
assert_out_lacks "Расхождений в знаниях нет" "$OUT_GONE_O"      || rc=1
assert_out_lacks "Заметок ждёт разбора: 0" "$OUT_GONE_O"        || rc=1

# --- (б) AIDA_LEDGER_DIR на ПУСТОЙ каталог (есть, но без *.jsonl) -------------
EMPTYD="$(make_tmp_ledger)"   # каталог есть, файлов реестра в нём нет
trap 'rm -rf "$LED" "$EMPTYD"' EXIT

OUT_EMPTY_A="$(run_aida_brief "$EMPTYD" --for-agent)"; RC_EA=$?
assert_exit 0 "$RC_EA"                                          || rc=1
assert_out_has "состояние не прочитал" "$OUT_EMPTY_A"           || rc=1
assert_out_has "реестр недоступен" "$OUT_EMPTY_A"             || rc=1
assert_out_lacks "сырых записок в карантине: 0" "$OUT_EMPTY_A"  || rc=1

OUT_EMPTY_O="$(run_aida_brief "$EMPTYD" --for-owner)"; RC_EO=$?
assert_exit 0 "$RC_EO"                                          || rc=1
assert_out_has "Состояние не прочитал" "$OUT_EMPTY_O"           || rc=1
assert_out_has "реестр недоступен" "$OUT_EMPTY_O"            || rc=1
assert_out_lacks "Действующих решений: 0" "$OUT_EMPTY_O"        || rc=1

# --- (в) КОНТРАСТ: реально ПУСТОЙ реестр (файлы есть, пустые) = ЛЕГИТИМНО ------
#  Здесь деградации быть НЕ должно: каталог есть, все ожидаемые *.jsonl на месте
#  (пустые) → честный «решений нет / Действующих решений: 0», а НЕ «не прочитал».
#  Это и отделяет «реально пусто» от «недоступно».
REALEMPTY="$(make_tmp_ledger)"
for base in facts decisions contradictions inbox; do
  : > "${REALEMPTY}/${base}.jsonl"   # файл существует, но пуст
done
trap 'rm -rf "$LED" "$EMPTYD" "$REALEMPTY"' EXIT

OUT_RE_A="$(run_aida_brief "$REALEMPTY" --for-agent)"; RC_REA=$?
assert_exit 0 "$RC_REA"                                         || rc=1
# легитимный ноль присутствует
assert_out_has "сырых записок в карантине: 0" "$OUT_RE_A"       || rc=1
# и это НЕ деградация реестра-ядра
assert_out_lacks "состояние не прочитал: реестр недоступен" "$OUT_RE_A" || rc=1

OUT_RE_O="$(run_aida_brief "$REALEMPTY" --for-owner)"; RC_REO=$?
assert_exit 0 "$RC_REO"                                         || rc=1
assert_out_has "Действующих решений: 0" "$OUT_RE_O"             || rc=1
assert_out_lacks "Состояние не прочитал: реестр недоступен" "$OUT_RE_O" || rc=1

exit "$rc"
