#!/usr/bin/env bash
# CONTRACT (П2 аудита, D-20260613-008): ЕДИНЫЙ реестр проектов
# (PROJECTS/projects.json) — ЕДИНСТВЕННЫЙ источник правды о списке проектов и их
# путях. Доказываем ДВА свойства, оба детерминированно и без хождения по живым
# репозиториям:
#
#   1. В scripts/aida-brief НЕ осталось захардкоженного списка слагов/путей:
#      нет литералов путей продуктовых репозиториев (Projects/…, crypto-platform)
#      и нет перечисления проектных слагов в КОДЕ (не в комментариях). Регрессия
#      (кто-то вернул хардкод) — краснит тест.
#
#   2. Список известных проектов aida-brief реально ЧИТАЕТ из реестра, а не из
#      своей копии. Проверяем через РАННЮЮ проверку --scope (до любых снимков git,
#      поэтому быстро и детерминированно): на временном реестре (AIDA_PROJECTS_FILE)
#      только с проектом lab-extra:
#        • aida-brief --scope lab-extra  — slug ИЗВЕСТЕН (нет ошибки 64);
#        • aida-brief --scope crypto     — slug НЕИЗВЕСТЕН (ошибка 64), а в строке
#          «Известны: …» перечислен ИМЕННО lab-extra из реестра, не зашитый
#          штатный список. На штатном (живом) реестре crypto, наоборот, известен.
#      Живой PROJECTS/projects.json не мутируется — подмена через временный файл.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST brief-registry-single-source CONTRACT реестр проектов — единый источник, aida-brief без хардкода"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

BRIEF="${REPO_ROOT}/scripts/aida-brief"
REGISTRY="${REPO_ROOT}/PROJECTS/projects.json"
READER="${REPO_ROOT}/scripts/aida_registry.py"

rc=0

# --- (0) реестр и читатель на месте и валидны --------------------------------
assert_file_exists "${REGISTRY}"  || rc=1
assert_file_exists "${READER}"    || rc=1
SLUGS_OUT="$(python3 "${READER}" slugs 2>&1)"; RS=$?
assert_exit 0 "${RS}"             || rc=1
if [[ -z "${SLUGS_OUT//[[:space:]]/}" ]]; then
  echo "    реестр отдал пустой список слагов — реестр не источник"
  rc=1
fi

# --- (1) в КОДЕ aida-brief нет захардкоженного списка слагов/путей ------------
# Берём только КОД (без строк-комментариев и usage-примеров): slug'и в шапке —
# человеческие пояснения, это не источник данных. Комментарии начинаются с #.
CODE="$(grep -vE '^[[:space:]]*#' "${BRIEF}")"

# Пути продуктовых репозиториев в коде — запрещены (идут из реестра).
if printf '%s\n' "${CODE}" | grep -qE 'Projects/|crypto-platform'; then
  echo "    в коде aida-brief найден захардкоженный путь репозитория (Projects/ или crypto-platform)"
  printf '%s\n' "${CODE}" | grep -nE 'Projects/|crypto-platform' | sed 's/^/      | /'
  rc=1
fi

# Перечисление проектных слагов в коде — запрещено. Берём слаги из реестра и
# проверяем, что КОНКРЕТНЫЙ продуктовый slug не встречается в КОДЕ отдельным
# словом. Роли вида tl-<slug> не совпадут (дефис слева), не-проектные scope
# (system/global) сюда не попадают (их нет в реестре).
while IFS= read -r s; do
  [[ -n "${s}" ]] || continue
  if printf '%s\n' "${CODE}" | grep -qE "(^|[^-a-zA-Z])${s}([^-a-zA-Z]|$)"; then
    echo "    в коде aida-brief найден захардкоженный slug проекта: '${s}'"
    printf '%s\n' "${CODE}" | grep -nE "(^|[^-a-zA-Z])${s}([^-a-zA-Z]|$)" | sed 's/^/      | /'
    rc=1
  fi
done <<< "${SLUGS_OUT}"

# --- (2) известный список проектов aida-brief берёт ИЗ реестра ----------------
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
TMP_REG="${WORK}/projects.json"
cat > "${TMP_REG}" <<'JSON'
{ "projects": [
    {"slug": "lab-extra", "name_ru": "Лаб-проект", "repo": "", "tl_role": "", "overlay": "project-overlays/lab-extra", "mailbox": "", "snapshot": false}
] }
JSON

# Неизвестный для ВРЕМЕННОГО реестра slug 'crypto' → ошибка usage (64), а строка
# «Известны: …» обязана перечислить lab-extra из реестра (а НЕ зашитый список).
OUT_UNK="$(AIDA_PROJECTS_FILE="${TMP_REG}" bash "${BRIEF}" --scope crypto 2>&1)"; RU=$?
assert_exit 64 "${RU}"                       || rc=1
assert_out_has "lab-extra" "${OUT_UNK}"      || rc=1
# Зашитых штатных слагов в строке «Известны» при таком реестре быть НЕ должно.
assert_out_lacks "sitka-office" "${OUT_UNK}" || rc=1
assert_out_lacks "aida-voice" "${OUT_UNK}"   || rc=1

# Контраст на ЖИВОМ реестре: 'crypto' — известный scope, проверка слага его
# пропускает. Гоняем в офлайн-режиме (без живого обхода/снимков — быстро и
# детерминированно): ошибки про неизвестный slug 'crypto' быть НЕ должно.
LEDX="$(make_tmp_ledger)"
trap 'rm -rf "$WORK" "$LEDX"' EXIT
for base in facts decisions contradictions inbox; do : > "${LEDX}/${base}.jsonl"; done
# crypto принят как известный scope (раздел реестра собрался без ошибки usage),
# значит штатный реестр содержит crypto — список идёт из файла.
OUT_LIVE="$(run_aida_brief "${LEDX}" --scope crypto 2>&1)"; RL=$?
assert_exit 0 "${RL}"                                      || rc=1
assert_out_lacks "неизвестный slug 'crypto'" "${OUT_LIVE}" || rc=1

exit "$rc"
