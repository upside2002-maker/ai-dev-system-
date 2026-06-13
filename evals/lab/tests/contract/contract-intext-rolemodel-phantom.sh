#!/usr/bin/env bash
# CONTRACT: известная висячая ссылка policies/ROLE_MODEL.md живёт только в
# тексте сообщения об ошибке accept-task.sh (строка ~149) — файл существует
# как КОРНЕВОЙ ROLE_MODEL.md, не как policies/ROLE_MODEL.md. Тест фиксирует
# статус-кво: ссылка только в тексте, исполнение не ломает; помечаем её как
# known-phantom, чтобы не потерять при будущей чистке.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST contract-intext-rolemodel-phantom CONTRACT известный phantom policies/ROLE_MODEL.md зафиксирован"

ACCEPT="${REPO_ROOT}/scripts/accept-task.sh"

rc=0
# 1. Корневой ROLE_MODEL.md обязан существовать (он настоящий).
assert_file_exists "${REPO_ROOT}/ROLE_MODEL.md" || rc=1

# 2. policies/ROLE_MODEL.md обязан ОТСУТСТВОВАТЬ (это и есть known-phantom).
#    Если он вдруг появится — статус-кво изменился, надо пересмотреть тест.
assert_file_absent "${REPO_ROOT}/policies/ROLE_MODEL.md" || rc=1

# 3. Ссылка на policies/ROLE_MODEL.md живёт только в ТЕКСТЕ сообщения (echo),
#    не в исполняемой логике (не в условии/пути файла). Проверяем, что
#    единственное упоминание — внутри echo-строки.
if grep -nq 'policies/ROLE_MODEL.md' "$ACCEPT"; then
  # Все упоминания должны быть в echo-строках (текст для человека).
  NONECHO="$(grep -n 'policies/ROLE_MODEL.md' "$ACCEPT" | grep -vE '^\s*[0-9]+:\s*echo ' || true)"
  if [[ -n "$NONECHO" ]]; then
    echo "    policies/ROLE_MODEL.md упомянут вне echo-строки (может ломать исполнение):"
    printf '%s\n' "$NONECHO" | sed 's/^/    /'
    rc=1
  fi
else
  echo "    заметка: ссылка policies/ROLE_MODEL.md исчезла из accept-task.sh — known-phantom устранён (можно убрать этот тест)"
fi

exit "$rc"
