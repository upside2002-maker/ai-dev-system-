# Start Here

Главная навигация `ai-dev-system`. Открой нужный entrypoint по контексту.

## Я только начинаю / хочу понять систему

- [`ROLE_MODEL.md`](ROLE_MODEL.md) — канонический источник правды по ролям (Project Tech Lead / Business Analyst / Reviewer / Worker / AI Dev System Admin), иерархия, координация, multi-model protocol.
- [`CLAUDE_GLOBAL.md`](CLAUDE_GLOBAL.md) — глобальные правила для всех агентов: anti-confabulation, tech-lead posture, проверки для юр/фин/мед.
- [`README.md`](README.md) — карта репо.
- [`guides/LAYER_RESPONSIBILITIES.md`](guides/LAYER_RESPONSIBILITIES.md) — слои Worker-задачи (Core / Services / Frontend), не роли.
- [`corrections/global-corrections.md`](corrections/global-corrections.md) — кросс-проектные anti-patterns.

## Я хочу запустить агентскую сессию

### По проекту sitka-office

- [`project-overlays/sitka-office/starts/TECH_LEAD.md`](project-overlays/sitka-office/starts/TECH_LEAD.md) — главный вход для технической работы.
- [`project-overlays/sitka-office/starts/BUSINESS_ANALYST.md`](project-overlays/sitka-office/starts/BUSINESS_ANALYST.md) — продуктовая / маркетинговая / юр.-фин. аналитика.
- [`project-overlays/sitka-office/starts/REVIEWER.md`](project-overlays/sitka-office/starts/REVIEWER.md) — независимая проверка (Claude или Codex).
- [`project-overlays/sitka-office/starts/WORKER.md`](project-overlays/sitka-office/starts/WORKER.md) — реализация по TASK от TL.
- Текущее операционное состояние — [`project-overlays/sitka-office/OPERATING.md`](project-overlays/sitka-office/OPERATING.md).

### По проекту astro

- Точки входа по новой модели ещё не созданы (запланированы в Фазе 4 миграции).
- Legacy `START_ASTRO_RESEARCH.md` — в [`project-overlays/astro/starts/archive/`](project-overlays/astro/starts/archive/).
- Контекст проекта — [`project-overlays/astro/README.md`](project-overlays/astro/README.md).

### Системные сессии (не привязаны к проекту)

- [`starts/AI_DEV_ADMIN.md`](starts/AI_DEV_ADMIN.md) — обслуживание самой `ai-dev-system` (overlay-гигиена, эволюция методологии).
- [`learning/START.md`](learning/START.md) — обучение тех-лиду (учебная сессия пользователя). План — [`learning/TECH_LEAD_PLAN.md`](learning/TECH_LEAD_PLAN.md), журнал — [`learning/progress.md`](learning/progress.md).

## Шаблоны и справочники

- [`templates/TASKS_TEMPLATE.md`](templates/TASKS_TEMPLATE.md) — формат TASK от TL → Worker.
- [`templates/HANDOFFS_TEMPLATE.md`](templates/HANDOFFS_TEMPLATE.md) — формат передачи между ролями / моделями.
- [`templates/reference-snippets/`](templates/reference-snippets/) — эталонные code samples (Haskell handlers, pricing, state machine).

## Архив

- [`guides/archive/`](guides/archive/) — `AGENT_ONBOARDING.md`, `AGENT_PLAYBOOK.md` (legacy, старая 5-ролевая онтология) + `SYSTEM_REFRESH_2026-04-21.md` (исторический журнал refresh).
- `project-overlays/<slug>/starts/archive/` — legacy START-файлы по каждому проекту.
- `project-overlays/sitka-office/archive/` — закрытые phase docs и frozen технические снимки.

## Если непонятно с чего начать

1. Прочитай `ROLE_MODEL.md` — определи свою роль.
2. Открой соответствующий `START_*.md` из списка выше.
3. Если ни одна роль не подходит — скажи пользователю, не выдумывай.
