#!/usr/bin/env bash
# Print a canonical one-block snapshot of a project's PRODUCT repository, read
# live from git — never typed by hand (И-13, обзор ADS-DRIFT-1).
#
# Снимки состояния («сервер на …», «HEAD …») в CURRENT_STATE.md / DISPATCHER
# раньше писались по памяти — класс ошибок «рассинхрон 0 при реальном дрейфе».
# Этот скрипт выдаёт строку-снимок из источника: короткий HEAD, ветка,
# дата-время, чистота дерева, последний коммит. Только печать — файлы не правит.
#
# Путь к продукт-репо определяется тем же способом, что в
# scripts/check-overlay-consistency.sh: $HOME/Projects/<slug>, с возможностью
# переопределить вторым аргументом. Работает и для overlay в maturity=pre-phase0
# (репозиторий уже известен, снимок берётся напрямую из git).
#
# Exit codes:
#   0  — снимок напечатан
#   1  — overlay/репозиторий не найден или это не git-репо
#   64 — usage error
#
# Usage:
#   bash scripts/snapshot.sh <slug> [<repo-path>]
# or via make:
#   make snapshot SLUG=sitka-office

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<EOF
Usage: $0 SLUG [REPO_PATH]
  SLUG      — слаг проекта (имя каталога в project-overlays/ и в \$HOME/Projects/)
  REPO_PATH — путь к продуктовому репо (по умолчанию \$HOME/Projects/<slug>)

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
REPO_PATH="${2:-${HOME}/Projects/${SLUG}}"
OVERLAY_DIR="${ROOT_DIR}/project-overlays/${SLUG}"

# Overlay должен существовать — иначе slug, скорее всего, опечатка.
if [[ ! -d "${OVERLAY_DIR}" ]]; then
  echo "ERROR: overlay не найден: project-overlays/${SLUG}" >&2
  echo "       Проверь слаг. Доступные проекты:" >&2
  if [[ -d "${ROOT_DIR}/project-overlays" ]]; then
    find "${ROOT_DIR}/project-overlays" -maxdepth 1 -mindepth 1 -type d \
      -exec basename {} \; 2>/dev/null | sort | sed 's/^/         • /' >&2
  fi
  exit 1
fi

# Продуктовый репозиторий должен быть git-репо — снимок берём только из git.
if [[ ! -d "${REPO_PATH}/.git" ]]; then
  echo "ERROR: продуктовый репозиторий не найден или это не git-репо: ${REPO_PATH}" >&2
  if [[ -n "${2:-}" ]]; then
    # Путь задан явно вторым аргументом — не врём про $HOME/Projects.
    echo "       Этот путь передан вторым аргументом (REPO_PATH); .git внутри не найден." >&2
    echo "       Проверь, что путь верный и в нём действительно git-репо." >&2
  else
    echo "       Ожидался каталог \$HOME/Projects/${SLUG} с .git внутри." >&2
    echo "       Если репо лежит в другом месте — укажи путь вторым аргументом:" >&2
    echo "         make snapshot SLUG=${SLUG} REPO_PATH=/путь/к/репо" >&2
  fi
  exit 1
fi

# --- собрать поля снимка из git -------------------------------------------
HEAD_SHORT="$(git -C "${REPO_PATH}" rev-parse --short HEAD)"
BRANCH="$(git -C "${REPO_PATH}" rev-parse --abbrev-ref HEAD)"
NOW="$(date '+%Y-%m-%d %H:%M %Z')"

# Чистота дерева: посчитать неучтённые (untracked) и изменённые/staged отдельно.
# git status --porcelain: '??' = untracked; всё остальное непустое = изменения.
STATUS_PORCELAIN="$(git -C "${REPO_PATH}" status --porcelain)"
if [[ -z "${STATUS_PORCELAIN}" ]]; then
  CLEANLINESS="чисто"
else
  UNTRACKED_N="$(printf '%s\n' "${STATUS_PORCELAIN}" | grep -c '^??' || true)"
  CHANGED_N="$(printf '%s\n' "${STATUS_PORCELAIN}" | grep -cv '^??' || true)"
  CLEANLINESS="${UNTRACKED_N} неучтённых / ${CHANGED_N} изменённых"
fi

LAST_COMMIT="$(git -C "${REPO_PATH}" log -1 --pretty=format:'%h %s')"

# --- каноническая строка снимка -------------------------------------------
echo "${SLUG}: HEAD ${HEAD_SHORT} (${BRANCH}), ${NOW}, дерево: ${CLEANLINESS}"
echo "  последний коммит: ${LAST_COMMIT}"
