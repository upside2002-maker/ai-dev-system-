#!/usr/bin/env bash
# Scaffold a periodic-audit TASK from templates/AUDIT_TASK_TEMPLATE.md.
# Owner-only: caller email must have can_approve_critical: yes in
# policies/USERS.md. Same right as signing critical tasks — audit is the
# symmetric oversight operation.
#
# Usage:
#   bash scripts/new-audit-task.sh SLUG
# or via make:
#   make new-audit-task SLUG=sitka-office
#
# Test hook: env var OVERRIDE_EMAIL substitutes caller's email without
# touching git config — same convention as scripts/take-shift.sh and
# scripts/approve-critical.sh.
#
# Refuses on:
#   - missing SLUG
#   - overlay project-overlays/<SLUG>/ does not exist
#   - templates/AUDIT_TASK_TEMPLATE.md missing
#   - git config user.email empty (without OVERRIDE_EMAIL)
#   - caller email lacks can_approve_critical: yes in policies/USERS.md
#   - target file <today>-audit.md already exists in TASKS/

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG
  SLUG — overlay slug (e.g. sitka-office, astro)

Example:
  $0 sitka-office
EOF
}

if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
  echo "ERROR: нужно указать SLUG" >&2
  usage
  exit 64
fi

SLUG="$1"

OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: папка проекта не найдена: ${OVERLAY}" >&2
  exit 65
fi

TEMPLATE="${ROOT_DIR}/templates/AUDIT_TASK_TEMPLATE.md"
if [[ ! -f "${TEMPLATE}" ]]; then
  echo "ERROR: шаблон не найден: ${TEMPLATE}" >&2
  exit 65
fi

GIT_EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
EFFECTIVE_EMAIL="${OVERRIDE_EMAIL:-${GIT_EMAIL}}"
if [[ -z "${EFFECTIVE_EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой — установи email или передай OVERRIDE_EMAIL" >&2
  exit 65
fi

# Проверка can_approve_critical — то же право что для override смены и для
# подписи серьёзных задач. Единообразие: один флаг для трёх операций контроля.
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
  echo "ERROR: у ${EFFECTIVE_EMAIL} нет права запускать периодическую сверку" >&2
  echo "       поле can_approve_critical в policies/USERS.md = '${CAN_APPROVE:-(не найдено)}'" >&2
  echo "       Это право есть только у владельца — сверка симметрична подписи" >&2
  echo "       серьёзных задач, см. policies/AUDIT.md." >&2
  exit 65
fi

TASKS_DIR="${OVERLAY}/TASKS"
TODAY="$(date '+%Y-%m-%d')"
TARGET="${TASKS_DIR}/${TODAY}-audit.md"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: задача на сегодняшнюю дату уже существует: ${TARGET}" >&2
  echo "       Если предыдущая ещё не закрыта — заверши её или удали и создай заново." >&2
  exit 73
fi

# Период сверки — последние 3 недели (по умолчанию).
PERIOD_START_EPOCH=$(( $(date '+%s') - 21 * 86400 ))
PERIOD_START="$(date -r "${PERIOD_START_EPOCH}" '+%Y-%m-%d' 2>/dev/null \
                || date -d "@${PERIOD_START_EPOCH}" '+%Y-%m-%d')"

mkdir -p "${TASKS_DIR}"

# Подстановка переменных шаблона. perl -pe чтобы не зависеть от различий
# BSD/GNU sed; ENV-проброс чтобы не словить bash-интерполяцию в команде
# (как баг с @gmail в commit 9ea2627).
TPL_SLUG="${SLUG}" \
TPL_TODAY="${TODAY}" \
TPL_PERIOD_START="${PERIOD_START}" \
TPL_OWNER_EMAIL="${EFFECTIVE_EMAIL}" \
perl -pe '
  s|\{\{SLUG\}\}|$ENV{TPL_SLUG}|g;
  s|\{\{TODAY\}\}|$ENV{TPL_TODAY}|g;
  s|\{\{PERIOD_START\}\}|$ENV{TPL_PERIOD_START}|g;
  s|\{\{OWNER_EMAIL\}\}|$ENV{TPL_OWNER_EMAIL}|g;
' "${TEMPLATE}" > "${TARGET}"

RELATIVE_TARGET="${TARGET#"${ROOT_DIR}/"}"
echo "OK: задача на сверку создана"
echo "  путь:    ${RELATIVE_TARGET}"
echo "  период:  с ${PERIOD_START} по ${TODAY}"
echo "  главный: ${EFFECTIVE_EMAIL}"
echo
echo "Дальше: пройди чек-лист (a)-(e) из policies/AUDIT.md, запиши находки в Acceptance."
echo "Принять: make accept-task FILE=${RELATIVE_TARGET}"
