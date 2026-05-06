# AI Dev System

Системный репозиторий для агентной разработки: правила, corrections,
playbooks, overlay-документация по проектам и лёгкие проверки
консистентности.

Важно: это пока docs-first control center, а не полностью
автоматизированная self-improving platform. Источник правды по каждому
проекту остаётся в самом проекте; overlay здесь должен отражать его
текущее состояние.

## Структура

```
START_HERE.md                     ← главная навигация по entrypoints
README.md                         ← этот файл (карта)
CLAUDE_GLOBAL.md                  ← глобальные правила для всех агентов
ROLE_MODEL.md                     ← канонический источник правды по ролям

starts/
  AI_DEV_ADMIN.md                 ← системная сессия (обслуживание самой ai-dev-system)

guides/
  LAYER_RESPONSIBILITIES.md       ← слои Worker-задачи (Core/Services/Frontend)
  archive/                        ← legacy онтология (AGENT_ONBOARDING, AGENT_PLAYBOOK)
                                    + SYSTEM_REFRESH_2026-04-21.md (исторический журнал)

learning/
  START.md                        ← учебная сессия (tech-lead для пользователя)
  TECH_LEAD_PLAN.md               ← 12-недельный план обучения
  progress.md                     ← журнал прогресса

corrections/
  global-corrections.md           ← кросс-проектные anti-patterns

templates/
  TASKS_TEMPLATE.md               ← формат TASK от TL → Worker
  HANDOFFS_TEMPLATE.md            ← формат передачи между ролями/моделями
  reference-snippets/             ← эталонные code samples

playbooks/                        ← layer-specific guidance (haskell / python / frontend)
prompts/task-splitting.md         ← шаблоны задач по слоям
evals/review-checklist.md         ← чеклист ревью

project-overlays/
  sitka-office/                   ← overlay активного CRM-проекта
    README.md                     ← точка входа в overlay
    OPERATING.md                  ← живой dashboard
    CURRENT_STATE.md              ← актуальный snapshot
    KNOWN_ISSUES.md               ← текущие ограничения / долги
    NEXT_ACTIONS.md               ← ближайшие практические шаги
    PROJECT_MAP.md                ← карта кода и модулей
    starts/                       ← entrypoints по новой модели
      TECH_LEAD.md
      BUSINESS_ANALYST.md
      REVIEWER.md
      WORKER.md
      archive/                    ← legacy START-файлы
    TASKS/                        ← активные TASK-документы
    HANDOFFS/                     ← handoff-документы
    archive/                      ← закрытые phase docs / frozen snapshots
  astro/                          ← overlay astro-проекта
    starts/archive/               ← legacy START_ASTRO_RESEARCH

scripts/
  check-system-structure.sh       ← проверка root docs + entrypoints
  check-overlay-consistency.sh    ← проверка, что overlay не отстал от repo

Makefile
  check                           ← запустить минимальные self-checks
```

## Как использовать

Перед задачей:

1. [`START_HERE.md`](START_HERE.md) — выбрать нужный entrypoint
2. [`ROLE_MODEL.md`](ROLE_MODEL.md) — определить свою роль
3. [`CLAUDE_GLOBAL.md`](CLAUDE_GLOBAL.md)
4. [`corrections/global-corrections.md`](corrections/global-corrections.md)
5. `project-overlays/<slug>/README.md` — контекст проекта
6. Уже потом углубляться в `CURRENT_STATE`, `KNOWN_ISSUES`, `OPERATING`, код

После задачи:

1. Обновить corrections, если встретился новый повторяемый анти-паттерн
2. Обновить overlay, если проект реально сменил фазу или архитектурную форму
3. Прогнать `scripts/check-overlay-consistency.sh <slug>`, если менялся overlay
4. Или просто `make check` для минимальной системной проверки

## Текущие проекты

- `sitka-office` — CRM для байерского бизнеса; DM-7 cashbox refactor, Phase B закрыта (см. `project-overlays/sitka-office/CURRENT_STATE.md`).
- `astro` — внутренний инструмент астролога Марины Архиповой; Architecture закрыта 2026-04-24, переход к Development (см. `project-overlays/astro/README.md`).
