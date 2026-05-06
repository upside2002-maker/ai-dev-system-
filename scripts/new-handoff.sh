#!/usr/bin/env bash
# Scaffold a new HANDOFF file from skeleton, with link to a TASK.
# Symmetric to new-task: covers creation side of the lifecycle.
#
# Usage:
#   bash scripts/new-handoff.sh SLUG TASK [FROM] [TO]
# or via make:
#   make new-handoff SLUG=sitka-office TASK=project-overlays/sitka-office/TASKS/<file>.md FROM=worker TO=tl
#
# Defaults:
#   FROM=worker
#   TO=tl
#   Agent runtime in skeleton: "Claude Code" (edit if Codex/ChatGPT)
#   Model in skeleton: "TBD"
#
# Refuses on:
#   - SLUG or TASK missing/empty
#   - overlay project-overlays/<SLUG>/ does not exist
#   - TASK file does not exist
#   - TASK not inside project-overlays/<SLUG>/TASKS/ or TASKS/archive/
#   - TASK basename does not match YYYY-MM-DD-<slug>.md (e.g. README.md rejected)
#   - FROM or TO not in {tl, worker, reviewer, ba, admin}
#   - target HANDOFF file already exists (no clobber)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG TASK [FROM] [TO]
  SLUG  — project overlay slug (e.g. sitka-office)
  TASK  — path to TASK file inside project-overlays/<SLUG>/TASKS/[archive/]<file>.md
          (relative to repo root or absolute)
  FROM  — one of: tl, worker, reviewer, ba, admin    (default: worker)
  TO    — one of: tl, worker, reviewer, ba, admin    (default: tl)

Example:
  $0 sitka-office project-overlays/sitka-office/TASKS/2026-05-03-foo.md worker tl
EOF
}

# --- arg validation ----------------------------------------------------------
if [[ $# -lt 2 ]]; then
  echo "ERROR: need at least 2 args (got $#): SLUG TASK [FROM] [TO]" >&2
  usage
  exit 64  # EX_USAGE
fi

SLUG="${1:-}"
TASK="${2:-}"
FROM="${3:-}"
TO="${4:-}"

# Defaults for FROM / TO when caller passes empty strings.
[[ -z "${FROM}" ]] && FROM="worker"
[[ -z "${TO}" ]]   && TO="tl"

if [[ -z "${SLUG}" ]]; then
  echo "ERROR: SLUG is empty" >&2
  usage
  exit 64
fi

if [[ -z "${TASK}" ]]; then
  echo "ERROR: TASK is empty" >&2
  usage
  exit 64
fi

# FROM / TO whitelist.
validate_role() {
  local var_name="$1" val="$2"
  case "${val}" in
    tl|worker|reviewer|ba|admin) return 0 ;;
    *)
      echo "ERROR: ${var_name} must be one of: tl, worker, reviewer, ba, admin" >&2
      echo "  got: ${val}" >&2
      return 1
      ;;
  esac
}
validate_role FROM "${FROM}" || exit 65
validate_role TO   "${TO}"   || exit 65

# --- overlay & task path -----------------------------------------------------
OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: overlay not found: ${OVERLAY}" >&2
  exit 65
fi

# Resolve TASK to absolute against repo root if not already absolute.
if [[ "${TASK}" != /* ]]; then
  TASK="${ROOT_DIR}/${TASK}"
fi

if [[ ! -f "${TASK}" ]]; then
  echo "ERROR: TASK file not found: ${TASK}" >&2
  exit 66  # EX_NOINPUT
fi

# TASK must live under project-overlays/<SLUG>/TASKS/[archive/]<single-file>.md.
# Excludes: different SLUG, HANDOFFS, nested deeper than archive/.
EXPECTED_RE="^${ROOT_DIR}/project-overlays/${SLUG}/TASKS/(archive/)?[^/]+\.md$"
if [[ ! "${TASK}" =~ ${EXPECTED_RE} ]]; then
  echo "ERROR: TASK must be inside project-overlays/${SLUG}/TASKS/ or TASKS/archive/" >&2
  echo "       (no nested dirs, no other slug, .md required)" >&2
  echo "  got: ${TASK}" >&2
  exit 65
fi

# Extract task slug from basename: YYYY-MM-DD-<slug>.md → <slug>.
TASK_BASE="$(basename "${TASK}")"
if [[ "${TASK_BASE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.+)\.md$ ]]; then
  TASK_SLUG="${BASH_REMATCH[1]}"
else
  echo "ERROR: TASK basename must match YYYY-MM-DD-<slug>.md (got: ${TASK_BASE})" >&2
  echo "       (README.md and other non-dated files cannot be referenced as TASK)" >&2
  exit 65
fi

# --- compute target ----------------------------------------------------------
HANDOFFS_DIR="${OVERLAY}/HANDOFFS"
TODAY="$(date '+%Y-%m-%d')"
NOW="$(date '+%Y-%m-%d %H:%M')"
TARGET="${HANDOFFS_DIR}/${TODAY}-${FROM}-to-${TO}-${TASK_SLUG}.md"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: target already exists, refusing to clobber: ${TARGET}" >&2
  exit 73  # EX_CANTCREAT
fi

# Map FROM short-form to canonical Role mode label (per ROLE_MODEL.md).
case "${FROM}" in
  tl)       ROLE_MODE="Tech Lead" ;;
  worker)   ROLE_MODE="Worker" ;;
  reviewer) ROLE_MODE="Reviewer / Red Team" ;;
  ba)       ROLE_MODE="Business Analyst" ;;
  admin)    ROLE_MODE="AI Dev System Admin" ;;
  *)        ROLE_MODE="${FROM}" ;;
esac

# Compute relative TASK path for storing in handoff (portable form).
TASK_REL="${TASK#"${ROOT_DIR}"/}"

# --- write skeleton ----------------------------------------------------------
mkdir -p "${HANDOFFS_DIR}"

cat > "${TARGET}" <<EOF
# HANDOFF: ${FROM} → ${TO} — ${TASK_SLUG}

- Status: open
- Date: ${NOW}
- Project: ${SLUG}
- From: ${FROM}
- To: ${TO}
- Agent runtime: Claude Code
- Model: TBD
- Role mode: ${ROLE_MODE}
- TASK: ${TASK_REL}

## Summary

<!-- 1–3 предложения: что произошло, статус задачи, главный risk/блокер если есть. -->

## Done

<!-- Конкретный список: коммиты, файлы, тесты, PR. Не процесс — артефакты. -->

## Remaining

<!-- Что не сделано (если применимо): открытые пункты для следующего шага. -->

## Artifacts

- branch:               <!-- git branch / worktree -->
- commit(s):            <!-- SHA(s) -->
- PR:                   <!-- ссылка если есть; формат: PR #NN (YYYY-MM-DD, <short-hash>) -->
- tests:                <!-- counts: 539/539 green; что было red; что новое -->
- Product repo status:  <!-- ОБЯЗАТЕЛЬНО, выбрать ОДНО:
                             committed                              — закоммичено, branch указан выше
                             intentionally uncommitted (Tier C docs) — Tier C, working tree edit достаточен
                             not applicable                         — TASK ничего не трогал в product repo
                             dirty (см. Conflicts/risks)            — что-то висит, объяснить ниже -->

<!-- Evidence rule: любая ссылка на PR # / merge-дату — с git short hash
     из `git log --grep` или `gh pr view`. Никогда "из памяти".
     Формат: `PR #74 (2026-05-01, b58e5fb)`. См. Correction 010. -->

## Conflicts / risks

<!-- Найденные противоречия, scope creep, нарушения инвариантов, что требует решения TL/пользователя. -->

## Next step

<!-- Кто делает следующий ход и что именно. Если ожидание ревью — кто Reviewer. -->
EOF

# --- report ------------------------------------------------------------------
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: HANDOFF scaffolded"
echo "  path:  ${RELATIVE_TARGET}"
echo "  from:  ${FROM}  →  to: ${TO}"
echo "  TASK:  ${TASK_REL}"
echo
echo "Дальше: получатель (${TO}) заполнит/уточнит Summary / Done / Remaining / Artifacts / Conflicts / Next step,"
echo "потом 'make accept-handoff FILE=${RELATIVE_TARGET}' когда работа закрыта."
echo "Если runtime ≠ Claude Code или модель отличается — поправь поля 'Agent runtime' / 'Model' вручную."
