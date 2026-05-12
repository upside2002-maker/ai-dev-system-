#!/usr/bin/env bash
# Take ведение проекта. After successful run, the caller is the active project
# lead (Holder) until either release-shift, the expiry window passes (if set),
# or someone overrides (owner only).
#
# Atomic from caller's perspective: refuses on precondition failure before
# any mutation. If push fails (someone got there first), caller is told to
# pull and re-evaluate.
#
# Usage:
#   bash scripts/take-shift.sh SLUG SCOPE [HOURS]
# or via make:
#   make take-shift SLUG=sitka-office SCOPE="разбор передачи"
#   make take-shift SLUG=sitka-office SCOPE="..." HOURS=4
#
# HOURS — опциональный срок ведения в часах. Если не указан — ведение
# берётся бессрочно (Expires: бессрочно). Срок имеет смысл только для
# коротких сессий по выбору ("на 4 часа доделать UI", "на 12 часов
# уехать с проектом"). По умолчанию ведение бессрочное.
#
# Email is taken from `git config user.email`.
#
# Pulls latest TL_SHIFT.md from origin before reading, so the decision
# (free / occupied / extend) is made on the freshest state. Pushes the new
# state on success via scripts/_push_helper.sh (origin + backup).
#
# Поведение по случаям:
#  - Ведение свободно → берём бессрочно (или на HOURS, если задано).
#  - Срок предыдущего ведения истёк → берём как свободное.
#  - Тот же держатель повторно вызывает take-shift (без OVERRIDE) →
#    продление ведения: обновляются Scope и опционально Expires, Started
#    сохраняется как история начала ведения.
#  - Ведение занято другим, без OVERRIDE → отказ.
#  - OVERRIDE=yes REASON="..." от email с can_override: yes — перехват
#    (экстренное прерывание, для пожаров). Прежний Holder сохраняется в
#    `## Override history`.
#
# Test hook: env var OVERRIDE_EMAIL=<email> substitutes the caller's email
# for can_override / Holder checks WITHOUT touching git config. For tests
# only — real-life ведение always reads from `git config user.email`.
#
# Refuses on:
#   - missing SLUG / SCOPE
#   - HOURS задан, но не целое положительное число
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TL_SHIFT.md missing inside overlay
#   - git config user.email empty
#   - rebase on origin/<branch> conflicts (manual resolution required)
#   - ведение занято другим Holder'ом без OVERRIDE и срок не истёк
#   - OVERRIDE=yes from email without can_override permission
#   - OVERRIDE=yes without non-empty REASON
#   - push rejected (race lost)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG SCOPE [HOURS]
  SLUG   — overlay slug (e.g. sitka-office, astro)
  SCOPE  — короткое описание зоны работы, на простом русском
  HOURS  — опциональный срок ведения в часах. Без него — бессрочно.

Environment (для экстренного прерывания):
  OVERRIDE=yes        — попытаться перехватить занятое ведение
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
HOURS="${3:-}"

# Если HOURS задан — должно быть целым положительным числом.
# Если не задан — ведение берётся бессрочно (Expires: бессрочно).
if [[ -n "${HOURS}" ]]; then
  if ! [[ "${HOURS}" =~ ^[0-9]+$ ]] || (( HOURS < 1 )); then
    echo "ERROR: HOURS должно быть целым положительным числом (получено: '${HOURS}')" >&2
    exit 65  # EX_DATAERR
  fi
fi

OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: папка проекта не найдена: ${OVERLAY}" >&2
  exit 65
fi

LOCK_FILE="${OVERLAY}/TL_SHIFT.md"
if [[ ! -f "${LOCK_FILE}" ]]; then
  echo "ERROR: файл ведения не найден: ${LOCK_FILE}" >&2
  echo "       Создай его руками по стандартному шаблону перед первым использованием." >&2
  exit 65
fi

EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
if [[ -z "${EMAIL}" ]]; then
  echo "ERROR: git config user.email пустой — установи email перед взятием ведения" >&2
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
  echo "       Это короткое объяснение зачем забираешь ведение — попадёт" >&2
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
    echo "ERROR: у ${EFFECTIVE_EMAIL} нет права на экстренное прерывание ведения" >&2
    echo "       поле can_override в policies/USERS.md = '${CAN_OVERRIDE:-(не найдено)}'" >&2
    echo "       Это право есть только у владельца. Договорись с текущим держателем" >&2
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

# Текущее время и время истечения нового ведения.
# Если HOURS не задан — ведение бессрочное (маркер "бессрочно" вместо даты).
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
NOW_EPOCH="$(date '+%s')"
if [[ -z "${HOURS}" ]]; then
  EXPIRES_NEW="бессрочно"
else
  EXPIRES_NEW_EPOCH=$(( NOW_EPOCH + HOURS * 3600 ))
  # macOS BSD date: -r epoch; GNU date: -d @epoch.
  EXPIRES_NEW="$(date -r "${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                || date -d "@${EXPIRES_NEW_EPOCH}" '+%Y-%m-%d %H:%M:%S')"
fi

# Свободно ли ведение? Маркеры "бессрочно" / "none" / "(нет)" проверяются
# явно ДО попытки парсить Expires как дату — иначе date -j -f выдаёт
# непредсказуемый exit code на не-дате.
SHIFT_FREE="no"
EXPIRY_REASON=""
if [[ "${RELEASED}" == "yes" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="ведение было свободно"
elif [[ -z "${HOLDER_LINE}" ]] || [[ "${HOLDER_LINE}" == "(нет)" ]]; then
  SHIFT_FREE="yes"
  EXPIRY_REASON="поле Holder было пустым"
elif [[ "${EXPIRES_LINE}" == "бессрочно" ]] || [[ "${EXPIRES_LINE}" == "none" ]] || [[ "${EXPIRES_LINE}" == "(нет)" ]] || [[ -z "${EXPIRES_LINE}" ]]; then
  # Бессрочное ведение — не истекает само по себе.
  : # SHIFT_FREE остаётся "no"
else
  EXPIRES_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || date -d "${EXPIRES_LINE}" '+%s' 2>/dev/null \
                  || echo "0")"
  if (( EXPIRES_EPOCH > 0 )) && (( EXPIRES_EPOCH < NOW_EPOCH )); then
    SHIFT_FREE="yes"
    EXPIRY_REASON="срок предыдущего ведения истёк (был до ${EXPIRES_LINE})"
  fi
fi

# Продление ведения тем же держателем: если SCOPE'у обновить хотят, и
# вызывающий — тот же email, что и текущий Holder, и OVERRIDE не запрошен —
# это продление, не отказ. Started сохраняется (история начала ведения).
DO_EXTEND="no"
DO_OVERRIDE="no"
if [[ "${SHIFT_FREE}" != "yes" ]]; then
  if [[ "${OVERRIDE}" != "yes" ]] && [[ "${HOLDER_LINE}" == "${EFFECTIVE_EMAIL}" ]]; then
    DO_EXTEND="yes"
    PRIOR_STARTED_KEEP="$(grep -m1 -E '^- Started:' "${LOCK_FILE}" | sed -E 's/^- Started:[[:space:]]*//')"
    EXPIRY_REASON="продление ведения тем же держателем"
  elif [[ "${OVERRIDE}" == "yes" ]]; then
    DO_OVERRIDE="yes"
    PRIOR_HOLDER="${HOLDER_LINE}"
    PRIOR_STARTED="$(grep -m1 -E '^- Started:' "${LOCK_FILE}" | sed -E 's/^- Started:[[:space:]]*//')"
    PRIOR_EXPIRES="${EXPIRES_LINE}"
    PRIOR_SCOPE="$(grep -m1 -E '^- Scope:' "${LOCK_FILE}" | sed -E 's/^- Scope:[[:space:]]*//')"
    EXPIRY_REASON="экстренное прерывание (прежний держатель: ${PRIOR_HOLDER}, до ${PRIOR_EXPIRES})"
  else
    echo "ERROR: ведение занято" >&2
    echo "  держатель: ${HOLDER_LINE}" >&2
    echo "  до:        ${EXPIRES_LINE}" >&2
    echo "  сейчас:    ${NOW}" >&2
    echo "" >&2
    echo "       Если нужно забрать ведение — экстренное прерывание (для пожаров):" >&2
    echo "         OVERRIDE=yes REASON=\"причина\" make take-shift SLUG=${SLUG} SCOPE=\"...\"" >&2
    echo "       Право на прерывание есть только у владельца (см. policies/USERS.md)." >&2
    echo "       Иначе — договорись с текущим держателем или дождись истечения срока (если задан)." >&2
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
# время; тело — карточка прежнего ведения и причина перехвата.
NEW_OVERRIDE_ENTRY=""
if [[ "${DO_OVERRIDE}" == "yes" ]]; then
  NEW_OVERRIDE_ENTRY="### ${NOW} — перехват инициировал ${EFFECTIVE_EMAIL}

- Прежний держатель: ${PRIOR_HOLDER}
- Прежнее начало:    ${PRIOR_STARTED}
- Прежний предел:    ${PRIOR_EXPIRES}
- Прежняя зона:      ${PRIOR_SCOPE}
- Причина перехвата: ${REASON}"
fi

# Started: при продлении сохраняется как история начала ведения.
# В остальных случаях (свободно/истёкло/override) — текущий момент.
if [[ "${DO_EXTEND}" == "yes" ]]; then
  STARTED_OUT="${PRIOR_STARTED_KEEP}"
else
  STARTED_OUT="${NOW}"
fi

# Active TASK: при продлении сохраняем существующее значение, иначе пусто.
if [[ "${DO_EXTEND}" == "yes" ]]; then
  PRIOR_ACTIVE_TASK="$(grep -m1 -E '^- Active TASK:' "${LOCK_FILE}" | sed -E 's/^- Active TASK:[[:space:]]*//')"
  ACTIVE_TASK_OUT="${PRIOR_ACTIVE_TASK:-(нет)}"
else
  ACTIVE_TASK_OUT="(нет)"
fi

# Сформировать новое содержимое файла: шапка + (опц. override history) + notes.
{
  cat <<EOF
# Ведение проекта — ${SLUG}

- Released: no
- Holder: ${EFFECTIVE_EMAIL}
- Started: ${STARTED_OUT}
- Expires: ${EXPIRES_NEW}
- Scope: ${SCOPE}
- Active TASK: ${ACTIVE_TASK_OUT}
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
    echo "_(заметки появляются при сдаче ведения через \`make release-shift\`)_"
  fi
} > "${LOCK_FILE}"

# Сохранить в журнал репозитория и отправить в резервную копию.
if [[ "${DO_OVERRIDE}" == "yes" ]]; then
  COMMIT_MSG="shift(${SLUG}): OVERRIDE by ${EFFECTIVE_EMAIL} from ${PRIOR_HOLDER} — ${REASON}"
elif [[ "${DO_EXTEND}" == "yes" ]]; then
  COMMIT_MSG="shift(${SLUG}): extend by ${EFFECTIVE_EMAIL} — ${SCOPE}"
elif [[ -z "${HOURS}" ]]; then
  COMMIT_MSG="shift(${SLUG}): take by ${EFFECTIVE_EMAIL} (бессрочно) — ${SCOPE}"
else
  COMMIT_MSG="shift(${SLUG}): take by ${EFFECTIVE_EMAIL} for ${HOURS}h — ${SCOPE}"
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
  echo "OK: ведение перехвачено (экстренное прерывание)"
  echo "  проект:          ${SLUG}"
  echo "  новый держатель: ${EFFECTIVE_EMAIL}"
  echo "  прежний:         ${PRIOR_HOLDER}"
  echo "  до:              ${EXPIRES_NEW}"
  echo "  зона:            ${SCOPE}"
  echo "  причина:         ${REASON}"
  echo ""
  echo "В TL_SHIFT.md записана аудит-карточка в раздел ## Override history."
elif [[ "${DO_EXTEND}" == "yes" ]]; then
  echo "OK: ведение продлено (тот же держатель)"
  echo "  проект:    ${SLUG}"
  echo "  держатель: ${EFFECTIVE_EMAIL}"
  echo "  с:         ${STARTED_OUT} (история начала сохранена)"
  echo "  до:        ${EXPIRES_NEW}"
  echo "  зона:      ${SCOPE}"
else
  echo "OK: ведение взято (${EXPIRY_REASON})"
  echo "  проект:    ${SLUG}"
  echo "  держатель: ${EFFECTIVE_EMAIL}"
  echo "  до:        ${EXPIRES_NEW}"
  echo "  зона:      ${SCOPE}"
fi
echo ""
echo "Сдать ведение: make release-shift SLUG=${SLUG} NOTES=\"...\""
