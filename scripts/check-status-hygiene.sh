#!/usr/bin/env bash
# check-status-hygiene.sh <slug>
# ЗАМОК на раздувание и жаргон в пользовательском статус-файле STATUS_RU.md.
# Он должен читаться «за 30 секунд» (живой статус ≤ ~1 экран) и на человеческом
# языке; история событий — отдельно в OPERATING/journal/. Раздутый/жаргонный
# STATUS_RU = «зелёный фасад» + нарушение policies/OPERATOR_LANGUAGE.md.
#
# Размер: active overlay сверх лимита — ERROR (блокирует push через pre-push).
#         pre-phase0 — WARN (станет блокирующим при переводе в 'active').
# Жаргон: всегда advisory WARN (порог щадящий, чтобы не ловить редкие термины).
#
# Лимит настраивается: STATUS_RU_MAX_LINES (по умолчанию 150).
set -euo pipefail

SLUG="${1:?usage: check-status-hygiene.sh <slug>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="${ROOT}/project-overlays/${SLUG}"
STATUS="${OVERLAY}/STATUS_RU.md"
LIMIT="${STATUS_RU_MAX_LINES:-150}"

if [[ ! -f "${STATUS}" ]]; then
  echo "OK: ${SLUG} — STATUS_RU.md нет (нечего проверять)."
  exit 0
fi

MATURITY="$(tr -d '[:space:]' < "${OVERLAY}/.overlay-maturity" 2>/dev/null || true)"
[[ -n "${MATURITY}" ]] || MATURITY="active"
LINES="$(wc -l < "${STATUS}" | tr -d ' ')"

# Жаргон (advisory): строки с англо-терминами в пользовательском статусе.
JARGON="$(grep -icE '\b(handoff|worker|reviewer|verdict|blocker|fixture|pytest|subprocess|schema-gate|roundtrip)\b' "${STATUS}" || true)"
if [[ "${JARGON}" -gt 15 ]]; then
  echo "WARN: ${SLUG} STATUS_RU.md — ${JARGON} строк с англо-жаргоном (policies/OPERATOR_LANGUAGE.md). Пользовательский статус должен быть на человеческом языке."
fi

if [[ "${LINES}" -le "${LIMIT}" ]]; then
  echo "OK: ${SLUG} STATUS_RU.md = ${LINES} строк (лимит ${LIMIT}) — читаемо."
  exit 0
fi

MSG="${SLUG} STATUS_RU.md раздут: ${LINES} строк при лимите ${LIMIT}. Статус должен читаться за 30 секунд — вынеси историю в OPERATING/journal/, оставь живой статус ≤ ${LIMIT} строк."
if [[ "${MATURITY}" == "active" ]]; then
  echo "ERROR: ${MSG}" >&2
  exit 1
fi
echo "WARN: ${MSG} (overlay=${MATURITY} → пока предупреждение; на 'active' станет блокирующим)."
exit 0
