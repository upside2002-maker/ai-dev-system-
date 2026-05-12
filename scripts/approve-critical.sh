#!/usr/bin/env bash
# Sign a TASK as critical-approved by the owner. Required when the task
# touches paths from policies/CRITICAL_PATHS.md and the creator does not
# have can_approve_critical permission on their own.
#
# Updates the `- Critical approved by: <email>` line in the TASK header to
# the caller's email, commits the change, pushes to backup.
#
# Usage:
#   bash scripts/approve-critical.sh project-overlays/<slug>/TASKS/<file>.md
# or via make:
#   make approve-critical FILE=project-overlays/sitka-office/TASKS/<file>.md
#
# Refuses on:
#   - missing FILE arg / file not found / not a TASK path
#   - git config user.email empty
#   - caller email does not have can_approve_critical: yes in policies/USERS.md
#   - TASK file lacks `- Critical approved by:` line (malformed — should be
#     scaffolded via make new-task which puts the placeholder there)
#
# Test hook: env var OVERRIDE_EMAIL substitutes caller's email without
# touching git config — same convention as scripts/take-shift.sh.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE  — путь к задаче (project-overlays/<slug>/TASKS/<file>.md)

Example:
  $0 project-overlays/sitka-office/TASKS/2026-05-12-some-task.md
EOF
}

if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
  echo "ERROR: нужно указать FILE" >&2
  usage
  exit 64
fi

FILE="$1"
if [[ "${FILE}" != /* ]]; then
  FILE="${ROOT_DIR}/${FILE}"
fi

if [[ ! -f "${FILE}" ]]; then
  echo "ERROR: файл не найден: ${FILE}" >&2
  exit 66
fi

if [[ ! "${FILE}" =~ /project-overlays/[^/]+/TASKS/[^/]+\.md$ ]]; then
  echo "ERROR: путь должен быть project-overlays/<slug>/TASKS/<file>.md (без вложенных папок, не archive)" >&2
  echo "  получено: ${FILE}" >&2
  exit 65
fi

BASENAME="$(basename "${FILE}")"
if [[ "${BASENAME}" == "README.md" ]]; then
  echo "ERROR: README.md — документация папки, не задача" >&2
  exit 65
fi

GIT_EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
EFFECTIVE_EMAIL="${OVERRIDE_EMAIL:-${GIT_EMAIL}}"
if [[ -z "${EFFECTIVE_EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой — установи email или передай OVERRIDE_EMAIL для теста" >&2
  exit 65
fi

# Проверить право подписи.
POLICIES_USERS="${ROOT_DIR}/policies/USERS.md"
if [[ ! -f "${POLICIES_USERS}" ]]; then
  echo "ERROR: ${POLICIES_USERS} не найден" >&2
  exit 65
fi
CAN_APPROVE="$(awk -v want_email="${EFFECTIVE_EMAIL}" '
  /^- email:[[:space:]]*/ {
    sub(/^- email:[[:space:]]*/, "");
    cur_email = $0;
    next;
  }
  cur_email == want_email && /^- can_approve_critical:[[:space:]]*/ {
    line = $0;
    sub(/^- can_approve_critical:[[:space:]]*/, "", line);
    print line;
    exit;
  }
' "${POLICIES_USERS}")"
if [[ "${CAN_APPROVE}" != "yes" ]]; then
  echo "ERROR: у ${EFFECTIVE_EMAIL} нет права на подпись критичных задач" >&2
  echo "       поле can_approve_critical в policies/USERS.md = '${CAN_APPROVE:-(не найдено)}'" >&2
  echo "       Это право есть только у владельца." >&2
  exit 65
fi

# Проверить что строка Critical approved by: в файле есть (новые задачи через
# new-task.sh всегда её содержат; на старых TASK без поля — отказ с просьбой
# добавить руками).
if ! grep -qE '^- Critical approved by:' "${FILE}"; then
  echo "ERROR: в задаче нет строки '- Critical approved by:' — добавь её в шапку перед подписью" >&2
  echo "       (новые задачи через make new-task создаются с этой строкой автоматически)" >&2
  exit 65
fi

CURRENT_APPROVED="$(grep -m1 -E '^- Critical approved by:' "${FILE}" | sed -E 's/^- Critical approved by:[[:space:]]*//')"
if [[ "${CURRENT_APPROVED}" == "${EFFECTIVE_EMAIL}" ]]; then
  echo "OK: задача уже подписана ${EFFECTIVE_EMAIL} — нечего менять"
  exit 0
fi

# Заменить значение строки. Email пробрасывается через ENV — иначе bash
# раскрывает ${EFFECTIVE_EMAIL} в double-quoted perl-команде, и perl видит
# `@gmail` как свой массив-переменную (пустой), что отъедает кусок email'а.
APPROVER_EMAIL="${EFFECTIVE_EMAIL}" perl -i -pe \
  's|^- Critical approved by:.*$|- Critical approved by: $ENV{APPROVER_EMAIL}|' \
  "${FILE}"

# Commit + двойная отправка (origin + backup) через scripts/_push_helper.sh.
BRANCH="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"
RELATIVE="${FILE#"${ROOT_DIR}/"}"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/_push_helper.sh"
(
  cd "${ROOT_DIR}"
  git add "${RELATIVE}"
  git commit -m "approve-critical(${RELATIVE}): signed by ${EFFECTIVE_EMAIL}" >/dev/null

  if ! push_both "${BRANCH}"; then
    echo "" >&2
    echo "ERROR: отправка не прошла — подпись сохранена локально, но не синхронизирована." >&2
    echo "  Если origin отверг — подтяни свежее:" >&2
    echo "    git -C ${ROOT_DIR} pull --rebase origin ${BRANCH}" >&2
    echo "  Затем 'git push origin ${BRANCH} && git push backup ${BRANCH}' вручную." >&2
    exit 75
  fi
) || exit $?

echo ""
echo "OK: задача подписана"
echo "  файл:     ${RELATIVE}"
echo "  подпись:  ${EFFECTIVE_EMAIL}"
echo "  прежний:  ${CURRENT_APPROVED:-(пусто)}"
echo ""
echo "Теперь \`make accept-task FILE=${RELATIVE}\` пропустит критичный gate."
