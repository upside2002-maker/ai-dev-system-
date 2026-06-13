#!/usr/bin/env bash
# Accept a TASK: bump `- Status:` to `done` and move file to archive/.
# Atomic from caller's perspective: refuses on any precondition failure
# before mutating.
#
# Usage:
#   bash scripts/accept-task.sh project-overlays/sitka-office/TASKS/<file>.md
# or via make:
#   make accept-task FILE=project-overlays/sitka-office/TASKS/<file>.md
#
# Refuses on:
#   - missing FILE arg
#   - file not found
#   - path not project-overlays/<slug>/TASKS/<file>.md (no nested dirs, not archive/)
#   - basename == README.md (folder docs, not a TASK)
#   - target in archive/ already exists (no clobber)
#   - no `- Status:` line in file (malformed task)
#   - Status != review (lifecycle: only review-stage TASK can transition to done)
#   - Ready != yes (DRAFT/blocked TASK cannot be accepted; raise Ready: yes first)
#   - Risk tier: A without Mode: strict (see policies/MODES.md — Tier A
#     requires strict mode; missing Mode field on a Tier A task also refused)
#   - Risk tier: A without an independent `- Reviewer:` (inline/self/TL rejected —
#     Correction 011; returns-core incident hardened this from advice to a gate)
#   - Risk tier: A without a material Reviewer-HANDOFF in the overlay's HANDOFFS/
#     (or archive/) — From/Role mode: Reviewer, TASK: this task's basename,
#     Status != open. Поле Reviewer можно вписать без проверки; артефакт — нельзя
#     (И-12, инцидент X-1: денежная математика принята без независимого ревью)
#
# Does NOT touch OPERATING.md — TL removes the line manually if present.
# Does NOT support reject-task (rejected status) — separate helper if needed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 FILE
  FILE — path to TASK .md inside project-overlays/<slug>/TASKS/
         (relative to repo root or absolute; NOT inside archive/, NOT README.md)

Example:
  $0 project-overlays/sitka-office/TASKS/2026-05-04-dm7-c-foo.md
EOF
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "ERROR: FILE argument required" >&2
  usage
  exit 64  # EX_USAGE
fi

FILE="$1"

# Resolve to absolute path against repo root if not already absolute.
if [[ "${FILE}" != /* ]]; then
  FILE="${ROOT_DIR}/${FILE}"
fi

if [[ ! -f "${FILE}" ]]; then
  echo "ERROR: file not found: ${FILE}" >&2
  exit 66  # EX_NOINPUT
fi

# Path must match: .../project-overlays/<slug>/TASKS/<single-file>.md
# Excludes: nested paths, archive/, anything outside TASKS/.
if [[ ! "${FILE}" =~ /project-overlays/[^/]+/TASKS/[^/]+\.md$ ]]; then
  echo "ERROR: path must be project-overlays/<slug>/TASKS/<file>.md" >&2
  echo "       (not inside archive/, no nested dirs, .md extension required)" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

# Explicit README.md block — folder docs, not a TASK.
BASENAME="$(basename "${FILE}")"
if [[ "${BASENAME}" == "README.md" ]]; then
  echo "ERROR: README.md is folder documentation, not a TASK" >&2
  echo "  got: ${FILE}" >&2
  exit 65  # EX_DATAERR
fi

# Compute archive target.
DIRNAME="$(dirname "${FILE}")"
ARCHIVE_DIR="${DIRNAME}/archive"
TARGET="${ARCHIVE_DIR}/${BASENAME}"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: target already exists, refusing to clobber: ${TARGET}" >&2
  exit 73  # EX_CANTCREAT
fi

if ! grep -qE '^- Status:' "${FILE}"; then
  echo "ERROR: no '- Status:' line found in ${FILE} (malformed task?)" >&2
  exit 65
fi

# Lifecycle gate: only Status=review + Ready=yes TASK can transition to done.
# Both checks happen BEFORE any mutation — refuse cleanly if pre-conditions not met.
CURRENT_STATUS="$(grep -m1 -E '^- Status:' "${FILE}" | sed -E 's/^- Status:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_STATUS}" != "review" ]]; then
  echo "ERROR: TASK Status must be 'review' to accept (got: '${CURRENT_STATUS:-empty}')" >&2
  echo "       Lifecycle: open → in-progress → review → done." >&2
  echo "       accept-task is the review→done step. Cannot skip stages." >&2
  echo "       If Worker submitted HANDOFF — bump Status to 'review' first, then re-run." >&2
  exit 65
fi

CURRENT_READY="$(grep -m1 -E '^- Ready:' "${FILE}" | sed -E 's/^- Ready:[[:space:]]*//' | awk '{print $1}')"
if [[ "${CURRENT_READY}" != "yes" ]]; then
  echo "ERROR: TASK Ready must be 'yes' to accept (got: '${CURRENT_READY:-empty}')" >&2
  echo "       If TASK was DRAFT/blocked, raise Ready: yes first, then re-run." >&2
  echo "       (Ready=no с Status=review — странная комбинация; gate refuses to be safe.)" >&2
  exit 65
fi

# Risk-tier × Mode gate: Tier A requires Mode=strict.
# Tier B/C — Mode optional (missing field tolerated; legacy tasks pre-2026-05-08
# do not have Mode at all). Tier A without Mode=strict — refusal regardless of
# whether Mode is missing or set to a non-strict value. See policies/MODES.md.
#
# Регистр tier нормализуем к ВЕРХНЕМУ перед сравнением (инцидент X-1, регистр):
# new-task.sh пишет поле как есть, без линта регистра. Без нормализации строчная
# '- Risk tier: a' считалась бы НЕ-Tier-A и разом пропускала все три ворота Tier A
# (Mode strict + независимый Reviewer + Reviewer-HANDOFF). Денежная Tier A с
# 'a'+normal+self прошла бы приёмку. tr приводит 'a'/'A'/'A (high)' → 'A …'.
CURRENT_TIER="$(grep -m1 -E '^- Risk tier:' "${FILE}" | sed -E 's/^- Risk tier:[[:space:]]*//' | awk '{print toupper($1)}')"
if [[ "${CURRENT_TIER}" == "A" ]]; then
  CURRENT_MODE="$(grep -m1 -E '^- Mode:' "${FILE}" | sed -E 's/^- Mode:[[:space:]]*//' | awk '{print $1}')"
  if [[ "${CURRENT_MODE}" != "strict" ]]; then
    echo "ERROR: Tier A TASK must have 'Mode: strict' to accept (got: '${CURRENT_MODE:-missing}')" >&2
    echo "       Risk tier A = migrations / money-flow / security boundaries / schema / ledger /" >&2
    echo "       auth / payment / any code with explicit invariant in architecture-invariants.md." >&2
    echo "       Such TASKs require strict mode — separate Worker subagent + separate Reviewer +" >&2
    echo "       full ceremony. Понизить tier ради удобства запрещено (см. Correction 012)." >&2
    echo "       См. policies/MODES.md для таблицы соответствия risk tier → mode." >&2
    exit 65
  fi

  # Tier A also requires an INDEPENDENT Reviewer (Correction 011 / ROLE_MODEL).
  # Инцидент returns-core (2026-06): TL закрыл Tier A inline self-review, когда
  # Reviewer-субагент упёрся в лимит сессии. Этот гейт делает такое невозможным:
  # Tier A не доходит до `done` без зафиксированного независимого ревьюера. Поле
  # `- Reviewer:` должно называть ОТДЕЛЬНОГО ревьюера (отдельная сессия / ссылка
  # на HANDOFF) — не TL, не inline, не self.
  # `|| true`: поля `- Reviewer:` может вовсе не быть (старые Tier A задачи) —
  # пустой grep под `set -o pipefail` не должен ронять скрипт, пусть дойдёт до
  # понятной ошибки ниже (а не молчаливый exit 1).
  CURRENT_REVIEWER="$(grep -m1 -E '^- Reviewer:' "${FILE}" 2>/dev/null | sed -E 's/^- Reviewer:[[:space:]]*//' | sed -E 's/[[:space:]]+$//' || true)"
  REVIEWER_TOKEN="$(printf '%s' "${CURRENT_REVIEWER}" | tr '[:upper:]' '[:lower:]' | awk '{print $1}')"
  case "${REVIEWER_TOKEN}" in
    ""|"(нет)"|"(none)"|"none"|"-"|"—"|"todo"|"tbd"|"n/a"|"na"|"self"|"self-review"|"inline"|"tl"|"tl-inline"|"tech-lead"|"techlead")
      echo "ERROR: Tier A TASK must record an INDEPENDENT Reviewer to accept." >&2
      echo "       Поле '- Reviewer:' пустое или указывает на self / inline / TL (got: '${CURRENT_REVIEWER:-missing}')." >&2
      echo "       Tier A (деньги / математика / схема / безопасность) требует ОТДЕЛЬНОГО ревьюера" >&2
      echo "       в отдельной сессии (Correction 011, policies/ROLE_MODEL.md). Inline self-review запрещён." >&2
      echo "       После независимого ревью заполни: '- Reviewer: <кто, отдельная сессия / ссылка на HANDOFF>'." >&2
      exit 65
      ;;
  esac

  # Tier A also requires a MATERIAL Reviewer-HANDOFF — не просто заполненное поле
  # `- Reviewer:`, а реально существующий файл передачи от ревьюера (И-12, X-1).
  # Инцидент X-1: денежная математика принята с заполненным полем Reviewer, но
  # без проведённой независимой проверки — поле можно вписать, проверку не делая.
  # Этот гейт требует артефакт: Reviewer-HANDOFF по этой же задаче, дошедший до
  # адресата (Status не open).
  #
  # Где ищем: project-overlays/<slug>/HANDOFFS/ и его archive/.
  # Что должно совпасть в шапке HANDOFF:
  #   - From: содержит роль Reviewer ИЛИ Role mode: Reviewer
  #     (форматы From в репо разные: 'Reviewer (...)', 'reviewer', 'Codex Reviewer',
  #      'Worker, branch …' — ловим слово reviewer без привязки к регистру/позиции;
  #      'Claude Worker' слова reviewer не содержит → корректно не матчится);
  #   - TASK: ссылается на принимаемый TASK по ИМЕНИ ФАЙЛА (basename), а не пути —
  #     ссылки в репо встречаются голым slug'ом без .md, полным путём в backticks,
  #     путём через archive/, markdown-ссылкой и с хвостом '(Status: …)';
  #   - Status: не open (acknowledged / closed — проверка дошла до адресата).
  SLUG="$(printf '%s' "${FILE}" | sed -E 's#.*/project-overlays/([^/]+)/TASKS/.*#\1#')"
  HANDOFFS_DIR="${ROOT_DIR}/project-overlays/${SLUG}/HANDOFFS"
  TASK_BASE="${BASENAME%.md}"  # имя файла TASK без расширения — ключ сличения

  # Экранируем TASK_BASE для использования в grep -E: точки (а равно любая
  # ERE-метасимволика) должны стать литералами, иначе '.' матчит любой символ.
  # Дефисы внутри имён безопасны (мы не кладём TASK_BASE в класс символов).
  TASK_BASE_ESC="$(printf '%s' "${TASK_BASE}" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g')"

  REVIEWER_HANDOFF=""
  if [[ -d "${HANDOFFS_DIR}" ]]; then
    # Кандидаты: *.md в HANDOFFS/ и HANDOFFS/archive/ (maxdepth 2 ловит оба).
    while IFS= read -r hf; do
      [[ -z "${hf}" ]] && continue
      # Шапку читаем из первых 25 строк — поля шапки живут там, тело не трогаем.
      header="$(head -25 "${hf}")"

      # TASK: должна упоминать basename принимаемой задачи (с .md или без),
      # сверяем ИМЯ ЦЕЛИКОМ по границам — иначе короткое имя матчит длинное как
      # подстрока: приёмка 'money' ловила бы Reviewer-HANDOFF чужой 'money-3'.
      # Граница — отсутствие [[:alnum:]_-] вплотную к имени (с любой стороны),
      # допускаем необязательный суффикс '.md' и конец строки/markdown-хвост.
      task_line="$(printf '%s\n' "${header}" | grep -m1 -E '^- TASK:' || true)"
      printf '%s' "${task_line}" \
        | grep -qE "(^|[^[:alnum:]_-])${TASK_BASE_ESC}(\.md)?([^[:alnum:]_-]|$)" \
        || continue

      # Роль Reviewer: в From: или в Role mode: (слово reviewer, без регистра).
      from_line="$(printf '%s\n' "${header}" | grep -m1 -E '^- From:' || true)"
      rolemode_line="$(printf '%s\n' "${header}" | grep -m1 -E '^- Role mode:' || true)"
      if ! printf '%s\n%s\n' "${from_line}" "${rolemode_line}" \
           | grep -qiwE 'reviewer'; then
        continue
      fi

      # Status: не open — проверка дошла до адресата (acknowledged / closed).
      # '|| true': если у кандидата-HANDOFF нет строки '- Status:', grep -m1 даёт
      # ненулевой код; под `set -e` + pipefail это аварийно роняло весь скрипт с
      # пустым RC=1 вместо документированного RC=65 с объяснением. Кандидат без
      # Status просто пропускаем (hf_status пустой → continue ниже). Соседние
      # *_line уже имеют '|| true' — приводим эту строку к тому же контракту.
      hf_status="$(printf '%s\n' "${header}" | grep -m1 -E '^- Status:' \
                     | sed -E 's/^- Status:[[:space:]]*//' | awk '{print tolower($1)}' || true)"
      [[ "${hf_status}" == "open" ]] && continue
      [[ -z "${hf_status}" ]] && continue

      REVIEWER_HANDOFF="${hf}"
      break
    done < <(find "${HANDOFFS_DIR}" -maxdepth 2 -name '*.md' -type f 2>/dev/null | sort)
  fi

  if [[ -z "${REVIEWER_HANDOFF}" ]]; then
    echo "ERROR: Tier A TASK не имеет независимого Reviewer-HANDOFF — приёмка отклонена (И-12, инцидент X-1)." >&2
    echo "       Поле '- Reviewer:' заполнено, но это лишь обещание: нужен сам артефакт проверки." >&2
    echo "       Не найден файл передачи в project-overlays/${SLUG}/HANDOFFS/ (или archive/), у которого:" >&2
    echo "         • From: или Role mode: = Reviewer;" >&2
    echo "         • TASK: ссылается на '${TASK_BASE}';" >&2
    echo "         • Status: не open (acknowledged или closed)." >&2
    echo "       Как исправить: провести независимую проверку отдельной сессией и оформить" >&2
    echo "       Reviewer-HANDOFF (make new-handoff SLUG=${SLUG} TASK=${FILE#"${ROOT_DIR}/"} FROM=reviewer TO=tl)," >&2
    echo "       довести его Status до acknowledged/closed, затем повторить приёмку." >&2
    exit 65
  fi
  echo "Info: независимый Reviewer-HANDOFF найден: ${REVIEWER_HANDOFF#"${ROOT_DIR}/"}"
fi

# Critical-paths gate: если задача затрагивает путь из policies/CRITICAL_PATHS.md
# — нужна подпись владельца (поле `- Critical approved by:` от email с
# can_approve_critical: yes в policies/USERS.md). Если Created by уже имеет
# это право — отдельная подпись не нужна (creator == approver).
#
# Парсинг паттернов: блок между ``` маркерами в policies/CRITICAL_PATHS.md.
# Поддерживаемые форматы: точный путь, `prefix/**`, `*suffix`.
CRITICAL_PATHS_FILE="${ROOT_DIR}/policies/CRITICAL_PATHS.md"
if [[ -f "${CRITICAL_PATHS_FILE}" ]]; then
  # Извлечь Files-секцию задачи (после ## Files до следующего ## ...).
  # Backticks убираются — markdown-convention в шаблонах обёртывает пути в
  # `path/...`, и без нормализации gate не ловит критичные пути в backticks.
  FILES_BLOCK="$(awk '/^## Files/{flag=1; next} flag && /^## /{flag=0} flag' "${FILE}" | tr -d '`')"

  # Извлечь критичные паттерны.
  CRITICAL_PATTERNS="$(awk '
    /^```/ { in_block = !in_block; next }
    in_block && !/^[[:space:]]*#/ && NF { print }
  ' "${CRITICAL_PATHS_FILE}")"

  TOUCHES_CRITICAL="no"
  WHICH_PATTERN=""
  while IFS= read -r pattern; do
    [[ -z "${pattern}" ]] && continue
    case "${pattern}" in
      *"/**")
        prefix="${pattern%/**}"
        if echo "${FILES_BLOCK}" | grep -qE "(^|[[:space:]/,])${prefix}/"; then
          TOUCHES_CRITICAL="yes"; WHICH_PATTERN="${pattern}"; break
        fi
        ;;
      "*"*)
        suffix="${pattern#\*}"
        if echo "${FILES_BLOCK}" | grep -qF "${suffix}"; then
          TOUCHES_CRITICAL="yes"; WHICH_PATTERN="${pattern}"; break
        fi
        ;;
      *)
        if echo "${FILES_BLOCK}" | grep -qE "(^|[[:space:]/,])${pattern}([[:space:],]|$)"; then
          TOUCHES_CRITICAL="yes"; WHICH_PATTERN="${pattern}"; break
        fi
        ;;
    esac
  done <<< "${CRITICAL_PATTERNS}"

  if [[ "${TOUCHES_CRITICAL}" == "yes" ]]; then
    POLICIES_USERS="${ROOT_DIR}/policies/USERS.md"
    if [[ ! -f "${POLICIES_USERS}" ]]; then
      echo "ERROR: ${POLICIES_USERS} не найден — без него нельзя проверить право подписи" >&2
      exit 65
    fi

    # Helper: get a can_* field for email from USERS.md.
    get_user_perm() {
      local _email="$1" _field="$2"
      awk -v want_email="${_email}" -v want_field="${_field}" '
        /^- email:[[:space:]]*/ {
          sub(/^- email:[[:space:]]*/, "");
          cur_email = $0;
          next;
        }
        cur_email == want_email && $0 ~ ("^- " want_field ":[[:space:]]*") {
          line = $0;
          sub("^- " want_field ":[[:space:]]*", "", line);
          print line;
          exit;
        }
      ' "${POLICIES_USERS}"
    }

    CREATED_BY="$(grep -m1 -E '^- Created by:' "${FILE}" | sed -E 's/^- Created by:[[:space:]]*//' | awk '{print $1}')"
    APPROVED_BY="$(grep -m1 -E '^- Critical approved by:' "${FILE}" | sed -E 's/^- Critical approved by:[[:space:]]*//' | awk '{print $1}')"

    CREATOR_CAN_APPROVE=""
    if [[ -n "${CREATED_BY}" ]]; then
      CREATOR_CAN_APPROVE="$(get_user_perm "${CREATED_BY}" "can_approve_critical")"
    fi

    if [[ "${CREATOR_CAN_APPROVE}" == "yes" ]]; then
      echo "Info: TASK затрагивает критичный путь '${WHICH_PATTERN}', но Created by '${CREATED_BY}' имеет право подписи — пропускаю отдельную проверку Critical approved by."
    else
      if [[ -z "${APPROVED_BY}" ]] || [[ "${APPROVED_BY}" == "(нет)" ]]; then
        echo "ERROR: TASK затрагивает критичный путь '${WHICH_PATTERN}' (из policies/CRITICAL_PATHS.md)" >&2
        echo "       а Created by '${CREATED_BY:-(не указано)}' не имеет права can_approve_critical." >&2
        echo "       Нужна подпись владельца. Сделай:" >&2
        echo "         make approve-critical FILE=${FILE#"${ROOT_DIR}/"}" >&2
        exit 65
      fi
      APPROVER_CAN_APPROVE="$(get_user_perm "${APPROVED_BY}" "can_approve_critical")"
      if [[ "${APPROVER_CAN_APPROVE}" != "yes" ]]; then
        echo "ERROR: TASK подписан '${APPROVED_BY}', но у него нет права can_approve_critical" >&2
        echo "       (поле в policies/USERS.md = '${APPROVER_CAN_APPROVE:-(не найдено)}')." >&2
        echo "       Подпись должна быть от владельца. Сделай:" >&2
        echo "         make approve-critical FILE=${FILE#"${ROOT_DIR}/"}" >&2
        exit 65
      fi
      # Защита от подмены: проверить что последний коммит, изменивший
      # `Critical approved by:` в этом файле, был сделан approver-email'ом.
      # Если файл новый (не закоммичен) — git log вернёт пусто, пропускаем.
      LAST_AUTHOR="$(git -C "${ROOT_DIR}" log -1 --format='%ae' \
                       --pickaxe-regex -S '^- Critical approved by:' \
                       -- "${FILE}" 2>/dev/null || true)"
      if [[ -n "${LAST_AUTHOR}" ]] && [[ "${LAST_AUTHOR}" != "${APPROVED_BY}" ]]; then
        echo "ERROR: поле Critical approved by указывает на '${APPROVED_BY}'," >&2
        echo "       но последний commit, который ввёл/изменил эту строку, был от '${LAST_AUTHOR}'." >&2
        echo "       Это похоже на подделку подписи. Пусть владелец подпишет своим email'ом:" >&2
        echo "         make approve-critical FILE=${FILE#"${ROOT_DIR}/"}" >&2
        exit 65
      fi
    fi
  fi
fi

# Mutate: bump Status to done (perl for portability between macOS/Linux sed).
perl -i -pe 's/^- Status:.*$/- Status: done/' "${FILE}"

# Move into archive/.
mkdir -p "${ARCHIVE_DIR}"
mv "${FILE}" "${TARGET}"

# Report.
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: task accepted"
echo "  Status:  done"
echo "  moved:   ${RELATIVE_TARGET}"
echo
echo "Если TASK был перечислен в OPERATING.md — убери строку вручную (helper не трогает OPERATING)."
echo "Если задача была отклонена (rejected, не done) — accept-task сюда не подходит; используй ручной mv после bump'а Status: rejected."
