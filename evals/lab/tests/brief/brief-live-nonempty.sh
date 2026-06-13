#!/usr/bin/env bash
# PASS (ТЗ §2.2): aida-brief на ЖИВОМ реестре отрабатывает и выдаёт непустой
# экран состояния — все четыре блока источников присутствуют (реестр-ядро,
# live-снимки, задачи/передачи, почта). Это база: если слой молчит на здоровом
# хозяйстве, все лица секретаря останутся без регидратации.
#
# Реестр берём ЖИВОЙ (без подмены AIDA_LEDGER_DIR — здесь нам нужен реальный),
# но запуск read-only: aida-brief только читает (снимки git, status, mailbox),
# ничего не пишет. Живой ledger/ не мутируется.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST brief-live-nonempty PASS живой реестр -> непустой экран со всеми блоками"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

# Запуск против живого реестра (AIDA_LEDGER_DIR пуст → дефолт ledger/).
OUT="$(bash "${REPO_ROOT}/scripts/aida-brief" --for-agent 2>&1)"; RC=$?

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
# раз реестр живой и непустой — должна быть хотя бы одна запись решения (D-…)
assert_out_has "D-" "$OUT"                            || rc=1
exit "$rc"
