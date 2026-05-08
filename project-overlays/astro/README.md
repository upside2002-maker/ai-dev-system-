# Astro — project overlay

> **Если хочешь видеть статус без чтения технических артефактов — [`STATUS_RU.md`](STATUS_RU.md).** Простой русский, 5 разделов, читается за 30 секунд.

Точка входа для любого агента работающего с проектом Astro.

## Project info

- **Slug:** astro
- **Repo path:** `/Users/ilya/Projects/astro/` (mini-MVP, перестраивается под target architecture)
- **Status:** **Architecture закрыта 2026-04-24, переход к Development.** Worker-агенты выполняют задачи из `ARCHITECTURE/PHASE_0_TASKS.md`.

## Context

- **Ниша:** астрология. Внутренний инструмент эксперта-астролога Марины Архиповой для ускорения подготовки соляр-консультаций.
- **Бизнес-модель (валидирована research + интервью):** письменные консультации (Соляр 90% + Электив 10%) + курсы. SaaS-направление снято.
- **Целевая аудитория клиентов Марины:** 99% РФ, 1% Беларусь.
- **Стек после Architecture:** Haskell core (вычисления + domain types) + Python services (IO, storage, PDF, API) + React frontend. Полное обоснование — в `ARCHITECTURE/target-architecture.md`.
- **Pivot истории:** проект стартовал как «B2C сайт + B2B SaaS на стеке sitka», после research и интервью с Мариной зафиксирован как **внутренний инструмент Марины с технологичным бэком** (см. `RESEARCH/findings/PIVOT_INTERNAL_TOOL.md` и `RESEARCH/findings/CORRECTIONS_AFTER_INTERVIEW.md`).

## Текущая фаза — Development

Architecture-документы созданы и являются действующим источником истины:

- `ARCHITECTURE/current-mvp-review.md` — что физически в `/Users/ilya/Projects/astro/`, покомпонентный приговор.
- `ARCHITECTURE/target-architecture.md` — целевая архитектура, треугольник источников истины, доменная модель, 8 bright lines.
- `ARCHITECTURE/migration-plan.md` — порядок переделки, early evaluation gate через 3 мес.
- `ARCHITECTURE/PHASE_0_TASKS.md` — атомарные задачи для worker-агента (разбито на Phase 0.1 walking skeleton + Phase 0.2 полный Phase 0).

**Артефакты-итоги (`CURRENT_STATE.md`, `KNOWN_ISSUES.md`, `NEXT_ACTIONS.md`, `PROJECT_MAP.md`) + bump `.overlay-maturity` в `active`** создаются только при завершении **полного Phase 0** (т.е. после Phase 0.2, задача T-F.4). На gate между 0.1 и 0.2 worker даёт устный отчёт оператору, отдельный markdown-файл не пишется — это внутренняя точка синхронизации, не публичный артефакт.

Research-блок завершён, его выводы зафиксированы в `RESEARCH/findings/` (см. `SUMMARY.md` + `CORRECTIONS_AFTER_INTERVIEW.md`).

## Что НЕ копировать из sitka-overlay

Соседний `project-overlays/sitka-office/` — пример применения принципов к другой нише (байер Sitka-снаряжения). Из него переносится только методология, никакой предметной специфики:

| Не переносить | Причина |
|---------------|---------|
| Доменные типы (DealStatus, SourceTouch) | Специфика байерской модели |
| Юр.выводы (комиссионный договор, СБП+ИП+УСН) | Под другую нишу |
| Каналы (Telegram → VK → ОК приоритет) | Специфика sitka |
| Стек (Haskell core / Python services / React) | Был принят для sitka; для astro обоснован отдельно в target-architecture.md, не скопирован по умолчанию |
| UI-структура (step-based workspace) | Под deal lifecycle байера |

Переносимо: методология, anti-confabulation правила, подход к agent-driven разработке, tech-lead posture, принцип research → architecture → development.

## Reading order

Канонический источник правды по ролям — [`ai-dev-system/ROLE_MODEL.md`](../../ROLE_MODEL.md) (5 ролей: Project Tech Lead / Business Analyst / Reviewer / Worker / AI Dev System Admin); навигация по системным entrypoints — [`ai-dev-system/START_HERE.md`](../../START_HERE.md). Для astro проектные START-файлы по новой модели ещё не созданы (запланированы в Фазе 4 миграции `ROLE_MODEL`); сейчас reading order ниже подходит для роли **Worker** на astro.

**Для Worker (текущая фаза astro — Development Phase 0):**
1. [`ai-dev-system/ROLE_MODEL.md`](../../ROLE_MODEL.md) — роль и координация
2. [`ai-dev-system/CLAUDE_GLOBAL.md`](../../CLAUDE_GLOBAL.md)
3. [`ai-dev-system/corrections/global-corrections.md`](../../corrections/global-corrections.md)
4. [`ai-dev-system/guides/LAYER_RESPONSIBILITIES.md`](../../guides/LAYER_RESPONSIBILITIES.md) — слои Worker-задачи (Core / Services / Frontend)
5. `project-overlays/astro/README.md` (этот файл)
6. `project-overlays/astro/ARCHITECTURE/target-architecture.md` — § 1-2 (треугольник + слои) и § 11 (bright lines).
7. `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` — конкретный таск.
8. После создания в T-A.3: `astro/.claude/architecture-invariants.md` + `astro/.claude/corrections.md`.

## Structure

```
astro/
├── README.md                  ← этот файл (контекст + статус)
├── RESEARCH/                  ← Phase 0 Research (закрыт)
│   ├── questions.md
│   └── findings/              ← markdown с разделением ФАКТ/ГИПОТЕЗА/ВЫВОД
│       ├── SUMMARY.md
│       ├── PIVOT_INTERNAL_TOOL.md
│       ├── CORRECTIONS_AFTER_INTERVIEW.md
│       ├── MARINA_INTERVIEW_RESPONSES.md
│       └── A-G блоки + STRATEGY_REVISED.md, OPEN_QUESTIONS.md
├── ARCHITECTURE/              ← Architecture (закрыта 2026-04-24, действующая)
│   ├── current-mvp-review.md
│   ├── target-architecture.md
│   ├── migration-plan.md
│   └── PHASE_0_TASKS.md
├── .overlay-maturity          ← `pre-phase0` сейчас; T-F.4 bumpает в `active`
├── CURRENT_STATE.md           ← создаётся в T-F.4 (после Phase 0.2)
├── KNOWN_ISSUES.md            ← создаётся в T-F.4
├── NEXT_ACTIONS.md            ← Phase 1 backlog, создаётся в T-F.4
└── PROJECT_MAP.md             ← карта кода по слоям, создаётся в T-F.4 (по образцу sitka)
```

После bump'а `.overlay-maturity` в `active` (T-F.4) — `make check-astro-overlay` начнёт требовать все 4 markdown-файла выше + snapshot match `CURRENT_STATE.md` с HEAD astro repo. Это та же дисциплина что у sitka-office.
