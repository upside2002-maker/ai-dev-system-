#!/usr/bin/env bash
# Scaffold a new TASK file from skeleton, with validated header fields.
# Symmetric helper to accept-task / reject-task — covers creation side of
# the lifecycle, removing manual template copy-paste.
#
# Usage:
#   bash scripts/new-task.sh SLUG TASK_SLUG LAYER TIER MODE
# or via make:
#   make new-task SLUG=sitka-office TASK_SLUG=dm7-d-widget-copy LAYER=web TIER=C MODE=normal
#
# Refuses on:
#   - any of the 5 args missing or empty
#   - TASK_SLUG not matching ^[a-z0-9]+(-[a-z0-9]+)*$
#     (lowercase + digits + single hyphens, no leading/trailing/double hyphens)
#   - LAYER not in {docs, core, services, web, infra, mixed}
#   - TIER not in {A, B, C}
#   - MODE not in {light, normal, strict, preview}
#   - overlay directory project-overlays/<SLUG>/ does not exist
#   - target file already exists (no clobber)
#
# Note: MODE is selected explicitly by TL — no default. See policies/MODES.md
# for the risk-tier→mode default table. Tier A without Mode=strict will be
# refused by accept-task at acceptance time (lifecycle gate).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG TASK_SLUG LAYER TIER MODE
  SLUG       — project overlay slug, must exist as project-overlays/<SLUG>/
  TASK_SLUG  — lowercase letters/digits/hyphens (e.g. dm7-d-widget-copy)
  LAYER      — one of: docs, core, services, web, infra, mixed
  TIER       — one of: A, B, C
  MODE       — one of: light, normal, strict, preview
               (see policies/MODES.md for the risk-tier→mode default table)

Example:
  $0 sitka-office dm7-d-widget-copy web C light
EOF
}

# --- arg validation ----------------------------------------------------------
if [[ $# -lt 5 ]]; then
  echo "ERROR: need 5 args (got $#): SLUG TASK_SLUG LAYER TIER MODE" >&2
  usage
  exit 64  # EX_USAGE
fi

SLUG="${1:-}"
TASK_SLUG="${2:-}"
LAYER="${3:-}"
TIER="${4:-}"
MODE="${5:-}"

for var_name in SLUG TASK_SLUG LAYER TIER MODE; do
  if [[ -z "${!var_name}" ]]; then
    echo "ERROR: ${var_name} is empty" >&2
    usage
    exit 64
  fi
done

# TASK_SLUG: lowercase + digits + single internal hyphens.
if [[ ! "${TASK_SLUG}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "ERROR: TASK_SLUG must match ^[a-z0-9]+(-[a-z0-9]+)*$" >&2
  echo "       (lowercase, digits, single hyphens; no leading/trailing/double hyphen, no other chars)" >&2
  echo "  got: ${TASK_SLUG}" >&2
  exit 65  # EX_DATAERR
fi

# LAYER whitelist.
case "${LAYER}" in
  docs|core|services|web|infra|mixed) ;;
  *)
    echo "ERROR: LAYER must be one of: docs, core, services, web, infra, mixed" >&2
    echo "  got: ${LAYER}" >&2
    exit 65
    ;;
esac

# TIER whitelist.
case "${TIER}" in
  A|B|C) ;;
  *)
    echo "ERROR: TIER must be one of: A, B, C" >&2
    echo "  got: ${TIER}" >&2
    exit 65
    ;;
esac

# MODE whitelist.
case "${MODE}" in
  light|normal|strict|preview) ;;
  *)
    echo "ERROR: MODE must be one of: light, normal, strict, preview" >&2
    echo "       (see policies/MODES.md for risk-tier→mode default table)" >&2
    echo "  got: ${MODE}" >&2
    exit 65
    ;;
esac

# --- overlay & target path ---------------------------------------------------
OVERLAY="${ROOT_DIR}/project-overlays/${SLUG}"
if [[ ! -d "${OVERLAY}" ]]; then
  echo "ERROR: overlay not found: ${OVERLAY}" >&2
  echo "       create overlay manually before scaffolding TASKs" >&2
  exit 65
fi

TASKS_DIR="${OVERLAY}/TASKS"
TODAY="$(date '+%Y-%m-%d')"
TARGET="${TASKS_DIR}/${TODAY}-${TASK_SLUG}.md"

if [[ -e "${TARGET}" ]]; then
  echo "ERROR: target already exists, refusing to clobber: ${TARGET}" >&2
  exit 73  # EX_CANTCREAT
fi

# --- write skeleton ----------------------------------------------------------
# Auto-fill Created by from git config user.email (tests may override via env
# OVERRIDE_EMAIL — same convention as scripts/take-shift.sh).
GIT_EMAIL="$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)"
CREATED_BY="${OVERRIDE_EMAIL:-${GIT_EMAIL}}"
if [[ -z "${CREATED_BY}" ]]; then
  echo "ERROR: не удалось определить email создателя — установи git config user.email" >&2
  exit 65
fi

mkdir -p "${TASKS_DIR}"

cat > "${TARGET}" <<EOF
# TASK: ${TASK_SLUG}

- Status: open
- Ready: yes
- Date: ${TODAY}
- Project: ${SLUG}
- Layer: ${LAYER}
- Risk tier: ${TIER}
- Owner: Project Tech Lead
- Created by: ${CREATED_BY}
- Worker model: TBD
- Mode: ${MODE}
- Critical approved by: (нет)

## Problem

<!-- Что делаем и почему. 2–5 предложений, технически. Без bizdev — это уже в TL decision / product brief. -->

## Files

- new:    <!-- пути новых файлов -->
- modify: <!-- пути изменяемых -->
- delete: <!-- редко -->

## Do not touch

<!-- TASK-specific исключения. Wider-scope policy — в starts/WORKER.md, не дублируем. -->

## Acceptance

- [ ] <!-- конкретная проверка #1 (команда / числовая метрика / файловый инвариант) -->
- [ ] <!-- конкретная проверка #2 -->

## Context

<!-- Ссылки на CURRENT_STATE / архитектурный документ / предшествующий HANDOFF / связанный TASK. -->
<!-- Если выбран не-default Mode для tier — здесь обоснование одной строкой (см. policies/MODES.md). -->
EOF

# --- report ------------------------------------------------------------------
RELATIVE_TARGET="${TARGET#"${ROOT_DIR}"/}"
echo "OK: TASK scaffolded"
echo "  path:  ${RELATIVE_TARGET}"
echo "  status: open"
echo "  layer: ${LAYER}  tier: ${TIER}  mode: ${MODE}"
echo
echo "Дальше: TL заполняет Problem / Files / Do not touch / Acceptance / Context,"
echo "потом передаёт TASK Worker'у. Не забудь добавить ссылку в OPERATING.md → 'Активные TASKS'."
