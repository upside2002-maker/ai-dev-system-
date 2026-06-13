#!/usr/bin/env bash
# PASS (ТЗ §2.2, операторский язык): aida-brief --for-owner идёт в голос/телефон,
# значит НЕ должен нести англо-технический жаргон. Грубая проверка: в выводе
# отсутствуют слова из стоп-списка policies/OPERATOR_LANGUAGE.md (выборка самых
# вредных — commit/branch/push/HEAD/container/healthcheck/bcrypt/curl/tier/…).
#
# Тонкость: реестр живой, но тексты решений (на рабочем языке) в операторский
# канал НЕ зачитываются — слой даёт счётчики и простые ориентиры. Эта проверка
# и стережёт то, что подача осталась операторской, даже если в ledger налили
# техжаргона. Запуск read-only; ничего не мутируется.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST brief-owner-no-jargon PASS --for-owner -> без техжаргона из стоп-списка"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

OUT="$(bash "${REPO_ROOT}/scripts/aida-brief" --for-owner 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC" || rc=1
if [[ -z "${OUT//[[:space:]]/}" ]]; then
  echo "    --for-owner выдал пустой экран"
  rc=1
fi

# Грубый стоп-список (подвыборка из policies/OPERATOR_LANGUAGE.md): целое слово,
# без учёта регистра (grep -i). Стоп-слова — ASCII, кириллицу вывода не трогаем.
STOP=(commit branch push pull makefile healthcheck bcrypt curl container \
      htpasswd compose pytest dashboard template handoff worker reviewer \
      tier strict normal preview head override fixture)
for w in "${STOP[@]}"; do
  if printf '%s' "$OUT" | grep -qiwF "$w"; then
    echo "    найден техжаргон в операторском выводе: '${w}'"
    rc=1
  fi
done

exit "$rc"
