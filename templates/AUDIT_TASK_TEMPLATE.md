# TASK: audit-{{TODAY}}

- Status: open
- Ready: yes
- Date: {{TODAY}}
- Project: {{SLUG}}
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Created by: {{OWNER_EMAIL}}
- Worker model: Claude Code
- Mode: light
- Critical approved by: (нет)

## Problem

Периодическая сверка системы разработки за период с {{PERIOD_START}} по {{TODAY}}. Цель — пройти чек-лист (a)-(e) из `policies/AUDIT.md` и зафиксировать находки.

## Files

- read-only: `policies/AUDIT.md`, `project-overlays/**`, `git log`

Сверка ничего не пишет в эти файлы. Находки записываются в раздел Acceptance ниже. Если нужно что-то починить — отдельная задача после закрытия сверки.

## Do not touch

Всё. Сверка — только-чтение.

## Acceptance

- [ ] (a) Подписи на серьёзных задачах за период — проверены. Находки:
- [ ] (b) Авторство прямых правок критичных путей — проверено. Находки:
- [ ] (c) Соответствие CURRENT_STATE.md фактическому HEAD — проверено. Находки:
- [ ] (d) Запрещённые слова в OPERATING.md и STATUS_RU.md — проверено. Находки:
- [ ] (e) Здравомыслие — посмотрел глазами. Находки:

## Context

См. `policies/AUDIT.md` для процедуры. Если нашёл находки уровня «системная» или «архитектурная» — заведи отдельную задачу после закрытия этой сверки.

Предыдущая сверка — посмотреть в `project-overlays/{{SLUG}}/TASKS/archive/` файлы вида `*-audit.md` (свежайший по дате).
