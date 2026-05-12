#!/usr/bin/env bash
# Take a project shift lock. After successful run, the caller is the active
# project lead (Holder) until either release-shift or the expiry window passes.
#
# Atomic from caller's perspective: refuses on precondition failure before
# any mutation. If push to backup fails (someone got there first), the user
# is told to reset and re-evaluate.
#
# Usage:
#   bash scripts/take-shift.sh SLUG SCOPE [HOURS]
# or via make:
#   make take-shift SLUG=sitka-office SCOPE="разбор передачи"
#   make take-shift SLUG=sitka-office SCOPE="..." HOURS=4
#
# Default HOURS=8 (typical shift length).
# Email is taken from `git config user.email`.
#
# Pulls the latest TL_SHIFT.md from backup before reading, so the decision
# (free / occupied) is made on the freshest state. Pushes the new state on
# success — if push is rejected (non-fast-forward), someone else took the
# shift in parallel; user resets to backup/<branch> and retries if needed.
#
# Override flow (экстренное прерывание):
#   OVERRIDE=yes REASON="..." make take-shift SLUG=... SCOPE=...
# When OVERRIDE=yes:
#   - caller's email must have `can_override: yes` in policies/USERS.md
#   - REASON must be non-empty
#   - if shift is held by another user (not expired), caller becomes new
#     Holder and prior Holder block is preserved in `## Override history`
#   - if shift was already free / expired, OVERRIDE flag is a no-op (no
#     override entry written, caller just takes the free slot normally)
#
# Test hook: env var OVERRIDE_EMAIL=<email> substitutes the caller's email
# for can_override / Holder checks WITHOUT touching git config. For tests
# only — real-life override always reads from `git config user.email`.
#
# Refuses on:
#   - missing SLUG / SCOPE / non-integer or zero HOURS
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TL_SHIFT.md missing inside overlay
#   - git config user.email empty
#   - rebase on backup/<branch> conflicts (manual resolution required)
#   - shift held by another user with non-expired Expires (without OVERRIDE)
#   - OVERRIDE=yes from email without can_override permission
#   - OVERRIDE=yes without non-empty REASON
#   - push to backup rejected (race lost)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG SCOPE [HOURS]
  SLUG   — overlay slug (e.g. sitka-office, astro)
  SCOPE  — короткое описание зоны работы на смену, на простом русском
  HOURS  — длина смены в часах (по умолчанию: 8)

Environment (для экстренного прерывания):
  OVERRIDE=yes        — попытаться перехватить занятую смену
  REASON="..."        — обязательно непустое при OVERRIDE=yes
  OVERRIDE_EMAIL=...  — подменить email инициатора (только для тестов)

Examples:
  $0 sitka-office "разбор передачи от dm-7-c"
  $0 astro "первая задача Phase 0.1" 4
  OVERRIDE=yes REASON="срочный фикс продакшена" $0 sitka-office "hot fix"
EOF
}

if [[ $# -lt 2 ]] || [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
  echo "ERROR: нужно указать SLUG и SCOPE" >&2
  usage
  exit 64  # EX_USAGE
fi

SLUG="$1"
SCOPE="$2"
HOURS="${3:-8}"

if ! [[ "${HOURS}" =~ ^[0-9]+$ ]] || (( HOURS < 1 )); then
  echo "ERROR: HOURS должно быть целым положительным числом (получено: '${HOURS}')" >&2
  exit 65  # EX_DATAERR
fi

OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: папка проекта не найдена: ${OVERLAY}" >&2
  exit 65
fi

LOCK_FILE="${OVERLAY}/TL_SHIFT.md"
if [[ ! -f "${LOCK_FILE}" ]]; then
  echo "ERROR: файл смены не найден: ${LOCK_FILE}" >&2
  echo "       Создай его руками по стандартному шаблону перед первым использованием." >&2
  exit 65
fi

EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
if [[ -z "${EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой — установи email перед взятием смены" >&2
  exit 65
fi

# Effective email — кого скрипт считает инициатором действия. По умолчанию
# совпадает с git config user.email; OVERRIDE_EMAIL — тестовый бэкдор для
# подмены email без правки git config (для acceptance-проверок).
EFFECTIVE_EMAIL="${OVERRIDE_EMAIL:-${EMAIL}}"

# Override-режим (экстренное прерывание).
OVERRIDE="${OVERRIDE:-no}"
REASON="${REASON:-}"

case "${OVERRIDE}" in
  yes|no) ;;
  *)
    echo "ERROR: OVERRIDE должно быть 'yes' или 'no' (получено: '${OVERRIDE}')" >&2
    exit 65
    ;;
esac

if [[ "${OVERRIDE}" == "yes" ]] && [[ -z "${REASON}" ]]; then
  echo "ERROR: при OVERRIDE=yes нужно указать непустое REASON=\"...\"" >&2
  echo "       Это короткое объяснение зачем перехватываешь смену — попадёт" >&2
  echo "       в TL_SHIFT.md в раздел ## Override history как аудит-след." >&2
  exit 65
fi

# При OVERRIDE=yes — сразу проверить право, до сетевой работы. Это позволяет
# отказать неавторизованному вызову не тратя fetch.
if [[ "${OVERRIDE}" == "yes" ]]; then
  POLICIES_USERS="${ROOT_DIR}/policies/USERS.md"
  if [[ ! -f "${POLICIES_USERS}" ]]; then
    echo "ERROR: ${POLICIES_USERS} не найден — без него нельзя проверить право на прерывание" >&2
    exit 65
  fi
  CAN_OVERRIDE="$(awk -v want_email="${EFFECTIVE_EMAIL}" '
    /^- email:[[:space:]]*/ {
      sub(/^- email:[[:space:]]*/, "");
      cur_email = $0;
      next;
    }
    cur_email == want_email && /^- can_override:[[:space:]]*/ {
      line = $0;
      sub(/^- can_override:[[:space:]]*/, "", line);
      print line;
      exit;
    }
  ' "${POLICIES_USERS}")"
  if [[ "${CAN_OVERRIDE}" != "yes" ]]; then
    echo "ERROR: у ${EFFECTIVE_EMAIL} нет права на экстренное прерывание смены" >&2
    echo "       поле can_override в policies/USERS.md = '${CAN_OVERRIDE:-(не найдено)}'" >&2
    echo "       Это право есть только у владельца. Договорись с текущим главным" >&2
    echo "       или попроси владельца сделать перехват от своего имени." >&2
    exit 65
  fi
fi

BRANCH="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"

# Подтянуть последние изменения из origin (источник правды для совместной
# работы). Пропускается при AIDS_SKIP_PUSH=1 — тестовый режим без сетевой
# работы. Если ветки на origin нет (новая локальная ветка) — пропускаю rebase.
if [[ "${AIDS_SKIP_PUSH:-0}" == "1" ]]; then
  echo "  (rebase на origin пропущен — AIDS_SKIP_PUSH=1, режим тестирования)"
elif git -C "${ROOT_DIR}" fetch origin "${BRANCH}" 2>/dev/null; then
  echo "Подтягиваю последние изменения из origin (ветка ${BRANCH})..."
  if ! git -C "${ROOT_DIR}" rebase "origin/${BRANCH}"; then
    echo "ERROR: rebase на origin/${BRANCH} не прошёл — разреши конфликты руками и попробуй снова" >&2
    git -C "${ROOT_DIR}" rebase --abort 2>/dev/null || true
    exit 75
  fi
else
  echo "  ветка ${BRANCH} ещё не на origin или сеть недоступна — пропускаю rebase"
fi

# Прочитать текущее состояние смены ПОСЛЕ rebase.
RELEASED="$(grep -m1 -E '^- Released:' "${LOCK_FILE}" | sed -E 's/^- Released:[[:space:]]*//' | awk '{print $1}')"
HOLDER_LINE="$(grep -m1 -E '^- Holder:' "${LOCK_FILE}" | sed -E 's/^- Holder:[[:space:]]*//')"
EXPIRES_LINE="$(grep -m1 -E '^- Expires:' "${LOCK_FILE}" | sed -E 's/^- Expires:[[:space:]]*//')"

# Текущее время и время истечения новой смены.
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
NOW_EPOCH="$(date '+%s')"
EXPIRES_NEW_EPOCH=$(( NOW_EPOCH + HOURS * 3600 ))
# macOS BSD date: -r epoch; GNU date: -d @epoch.
EXPIRES_NEW="$(date -r "${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
              || date -d "@${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S')"

# Свободна или истекла?
SHIFT_FREE="no"
EXPIRY_REASON=""
if [[ "${RELEASED}" == "yes" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="смена была свободна"
elif [[ -z "${HOLDER_LINE}" ]] || [[ "${HOLDER_LINE}" == "(нет)" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="поле Holder было пустым"
elif [[ -n "${EXPIRES_LINE}" ]] && [[ "${EXPIRES_LINE}" != "(нет)" ]]; then
  EXPIRES_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || date -d "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || echo "0")"
  if (( EXPIRES_EPOCH > 0 )) && (( EXPIRES_EPOCH < NOW_EPOCH )); then
    SHIFT_FREE="yes"
    EXPIRY_REASON="срок предыдущей смены истёк (был до ${EXPIRES_LINE})"
  fi
fi

DO_OVERRIDE="no"
if [[ "${SHIFT_FREE}" != "yes" ]]; then
  if [[ "${OVERRIDE}" == "yes" ]]; then
    DO_OVERRIDE="yes"
    PRIOR_HOLDER="${HOLDER_LINE}"
    PRIOR_STARTED="$(grep -m1 -E '^- Started:' "${LOCK_FILE}" | sed -E 's/^- Started:[[:space:]]*//')"
    PRIOR_EXPIRES="${EXPIRES_LINE}"
    PRIOR_SCOPE="$(grep -m1 -E '^- Scope:' "${LOCK_FILE}" | sed -E 's/^- Scope:[[:space:]]*//')"
    EXPIRY_REASON="экстренное прерывание (прежний главный: ${PRIOR_HOLDER}, до ${PRIOR_EXPIRES})"
  else
    echo "ERROR: смена занята" >&2
    echo "  главный: ${HOLDER_LINE}" >&2
    echo "  до:      ${EXPIRES_LINE}" >&2
    echo "  сейчас:  ${NOW}" >&2
    echo "" >&2
    echo "       Если нужно перехватить — экстренное прерывание:" >&2
    echo "         OVERRIDE=yes REASON=\"причина\" make take-shift SLUG=${SLUG} SCOPE=\"...\"" >&2
    echo "       Право на прерывание есть только у владельца (см. policies/USERS.md)." >&2
    echo "       Иначе — договорись с текущим главным или дождись истечения срока." >&2
    exit 75
  fi
fi

# Извлечь существующие секции из файла ДО перезаписи. Override history и
# Notes — накопительные, не должны теряться ни при обычном take, ни при
# overriding take. Плейсхолдер из ## Notes отфильтровывается чтобы он не
# дублировался при пустых заметках. Leading blank lines режутся awk-фильтром
# `NF || p; NF{p=1}` (печатать строку если она непустая, или если уже была
# непустая раньше) — иначе двойные пустые строки нарастают на каждый цикл.
EXISTING_OVERRIDE_HISTORY="$(awk '/^## Override history/{flag=1; next} flag && /^## /{flag=0} flag' "${LOCK_FILE}" \
                              | awk 'NF || p; NF{p=1}')"
EXISTING_NOTES="$(awk '/^## Notes/{flag=1; next} flag' "${LOCK_FILE}" \
                  | sed -E '/^_\(заметки появляются.*\)_$/d' \
                  | awk 'NF || p; NF{p=1}')"

# Новая override entry — если перехват. Заголовок секции выводит инициатор и
# время; тело — карточка прежней смены и причина перехвата.
NEW_OVERRIDE_ENTRY=""
if [[ "${DO_OVERRIDE}" == "yes" ]]; then
  NEW_OVERRIDE_ENTRY="### ${NOW} — перехват инициировал ${EFFECTIVE_EMAIL}

- Прежний главный:   ${PRIOR_HOLDER}
- Прежнее начало:    ${PRIOR_STARTED}
- Прежний предел:    ${PRIOR_EXPIRES}
- Прежняя зона:      ${PRIOR_SCOPE}
- Причина перехвата: ${REASON}"
fi

# Сформировать новое содержимое файла: шапка + (опц. override history) + notes.
{
  cat <<EOF
# Смена главного по проекту — ${SLUG}

- Released: no
- Holder: ${EFFECTIVE_EMAIL}
- Started: ${NOW}
- Expires: ${EXPIRES_NEW}
- Scope: ${SCOPE}
- Active TASK: (нет)
EOF

  has_new_override="no"
  [[ -n "${NEW_OVERRIDE_ENTRY}" ]] && has_new_override="yes"
  has_existing_override="no"
  [[ -n "$(echo "${EXISTING_OVERRIDE_HISTORY}" | tr -d '[:space:]')" ]] && has_existing_override="yes"

  if [[ "${has_new_override}" == "yes" ]] || [[ "${has_existing_override}" == "yes" ]]; then
    echo ""
    echo "## Override history"
    echo ""
    if [[ "${has_new_override}" == "yes" ]]; then
      echo "${NEW_OVERRIDE_ENTRY}"
    fi
    if [[ "${has_existing_override}" == "yes" ]]; then
      [[ "${has_new_override}" == "yes" ]] && echo ""
      echo "${EXISTING_OVERRIDE_HISTORY}"
    fi
  fi

  echo ""
  echo "## Notes"
  echo ""
  if [[ -n "$(echo "${EXISTING_NOTES}" | tr -d '[:space:]')" ]]; then
    echo "${EXISTING_NOTES}"
  else
    echo "_(заметки появляются при освобождении смены через \`make release-shift\`)_"
  fi
} > "${LOCK_FILE}"

# Сохранить в журнал репозитория и отправить в резервную копию.
COMMIT_MSG="shift(${SLUG}): take by ${EFFECTIVE_EMAIL} for ${HOURS}h — ${SCOPE}"
if [[ "${DO_OVERRIDE}" == "yes" ]]; then
  COMMIT_MSG="shift(${SLUG}): OVERRIDE by ${EFFECTIVE_EMAIL} from ${PRIOR_HOLDER} — ${REASON}"
fi
RELATIVE_LOCK="${LOCK_FILE#"${ROOT_DIR}/"}"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/_push_helper.sh"
(
  cd "${ROOT_DIR}"
  git add "${RELATIVE_LOCK}"
  git commit -m "${COMMIT_MSG}" >/dev/null

  if ! push_both "${BRANCH}"; then
    echo "" >&2
    echo "ERROR: отправка изменений не прошла — операция остановлена." >&2
    echo "  Если origin отверг (кто-то опередил) — подтяни свежее:" >&2
    echo "    git -C ${ROOT_DIR} pull --rebase origin ${BRANCH}" >&2
    echo "  Затем повтори make take-shift." >&2
    exit 75
  fi
) || exit $?

echo ""
if [[ "${DO_OVERRIDE}" == "yes" ]]; then
  echo "OK: смена перехвачена (экстренное прерывание)"
  echo "  проект:        ${SLUG}"
  echo "  новый главный: ${EFFECTIVE_EMAIL}"
  echo "  прежний:       ${PRIOR_HOLDER}"
  echo "  до:            ${EXPIRES_NEW}"
  echo "  зона:          ${SCOPE}"
  echo "  причина:       ${REASON}"
  echo ""
  echo "В TL_SHIFT.md записана аудит-карточка в раздел ## Override history."
else
  echo "OK: смена взята (${EXPIRY_REASON})"
  echo "  проект:  ${SLUG}"
  echo "  главный: ${EFFECTIVE_EMAIL}"
  echo "  до:      ${EXPIRES_NEW}"
  echo "  зона:    ${SCOPE}"
fi
echo ""
echo "Освободить смену: make release-shift SLUG=${SLUG} NOTES=\"...\""
