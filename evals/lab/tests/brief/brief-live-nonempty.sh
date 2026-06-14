#!/usr/bin/env bash
# PASS (ТЗ §2.2): aida-brief на ЗДОРОВОМ реестре отрабатывает и выдаёт непустой
# экран состояния — все четыре блока источников присутствуют (реестр-ядро,
# live-снимки, задачи/передачи, почта). Это база: если слой молчит на здоровом
# хозяйстве, все лица секретаря останутся без регидратации.
#
# Реестр берём ФИКСТУРНЫЙ (AIDA_LEDGER_DIR → seed_fixture_ledger): одно активное
# решение + не-stale факт. Обход живых проектов и почты ОТКЛЮЧЁН (офлайн-режим
# run_aida_brief, AIDA_BRIEF_NO_PROJECTS=1) — заголовки секций при этом остаются
# на месте, поэтому структура экрана проверяется в точности, но за секунды и без
# хождения по живым репозиториям/ящику. Живой ledger/ не мутируется.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST brief-live-nonempty PASS здоровый реестр -> непустой экран со всеми блоками"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
trap 'rm -rf "$LED"' EXIT
seed_fixture_ledger "$LED"

# Запуск против фикстурного реестра в офлайн-режиме (без живых проектов/почты).
OUT="$(run_aida_brief "$LED" --for-agent)"; RC=$?

rc=0
assert_exit 0 "$RC"                                   || rc=1
# вывод не пустой
if [[ -z "${OUT//[[:space:]]/}" ]]; then
  echo "    aida-brief выдал пустой экран — это запрещено (И-3)"
  rc=1
fi
# все четыре блока источников на месте
assert_out_has "РЕЕСТР-ЯДРО" "$OUT"                   || rc=1
assert_out_has "LIVE-СНИМКИ ПРОЕКТОВ" "$OUT"          || rc=1
assert_out_has "АКТИВНЫЕ ЗАДАЧИ / ПЕРЕДАЧИ" "$OUT"    || rc=1
assert_out_has "ПОЧТА (непрочитанное)" "$OUT"         || rc=1
# раз реестр здоров и непустой — должна быть хотя бы одна запись решения (D-…)
assert_out_has "D-" "$OUT"                            || rc=1
exit "$rc"
