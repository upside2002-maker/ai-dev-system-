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

## Bootstrap risks

Перед стартом любого Astro TASK нужно учесть состояние двух базовых рисков. Tech Lead сверяется с ними перед выдачей задач Worker'у. Risk #1 (git) закрыт 2026-05-06; risk #2 (architecture drift) остаётся открытым.

### 1. ~~Продуктовый repo не под git~~ — resolved 2026-05-06

`/Users/ilya/Projects/astro/` инициализирован как git repo 2026-05-06 в рамках TASK `git-bootstrap-execution` (overlay) после варианта решения local-only + local bare backup. Текущее состояние:

- **Baseline commit:** `astro:4937c00` (`chore: initial local git import after AI Dev System bootstrap`), 161 файл, branch `main`.
- **Remote topology:** только локальный bare backup `/Users/ilya/Backups/astro.git` (remote name `backup`). Публичного хостинга (GitHub/GitLab/Gitea) нет и не предполагается без отдельного go пользователя.
- **PII / реальные БД исключены:** `data/`, `*.db`, `*.sqlite*`, `*.se1`, `.env*` зафиксированы в `.gitignore`. Pre-init backup БД сохранён вне репо: `/Users/ilya/Backups/astro-pre-git-2026-05-06-183746.db`.
- **Evidence rule** из `templates/HANDOFFS_TEMPLATE.md` для Astro **применим начиная с `4937c00`**. Все новые HANDOFF используют git short hash; filesystem evidence (`ls`, `find`, mtime) для дат продукта больше не нужен.
- **Поле `Product repo status:`** в HANDOFF заполняется обычным образом (`clean / dirty / commit:<short>`).
- **Cross-repo state machine** (Correction 4 в `BASELINE.md`) для Astro действует полностью.
- **Что всё ещё требует go пользователя:** добавление публичных remote (GitHub/GitLab/Gitea), force-push, history rewrite, любая операция кроме `git push backup`.

### 2. Architecture drift между прескрипцией и реальностью

`ARCHITECTURE/target-architecture.md` зафиксирована 2026-04-24 и описывает Phase 0 как минимальный vertical slice с базовым PDF-выводом без графики и интерпретации (§ 6). В период между этой датой и моментом написания этого файла продуктовый код в `/Users/ilya/Projects/astro/services/api-python/app/pdf/` прошёл серию фаз с нумерацией 0.5–0.10b (введена в продуктовых сессиях, в overlay не зафиксирована), включая SVG-колёса, расшифровки таблиц, theme-grouped synthesis и миграцию направлений на Solar Arc.

Это **candidate drift**, не баг. TL не разрешает дрейф в одну сторону без отдельного шага: либо обновить overlay-документы (Architecture / migration-plan / PHASE_0_TASKS) под фактическое состояние, либо зафиксировать осознанное отклонение в `astro/.claude/corrections.md` с обоснованием. Кандидат на следующий TL TASK — «Architecture drift reconciliation», но не до явного go.

## Reading order

Канонический источник правды по ролям — [`ai-dev-system/ROLE_MODEL.md`](../../ROLE_MODEL.md) (5 ролей: Project Tech Lead / Business Analyst / Reviewer / Worker / AI Dev System Admin); навигация по системным entrypoints — [`ai-dev-system/START_HERE.md`](../../START_HERE.md). Для astro проектные START-файлы по новой модели создаются по мере необходимости — `TECH_LEAD.md` уже есть (см. ниже), `BUSINESS_ANALYST.md` / `REVIEWER.md` / `WORKER.md` создадутся в Фазе 4 миграции `ROLE_MODEL` или ad-hoc по требованию TL.

### Для Project Tech Lead

См. [`starts/TECH_LEAD.md`](starts/TECH_LEAD.md) — главный entry-point, включает promпт, reading order, operational discipline, явный учёт обоих bootstrap risks выше и cписок 8 bright lines из `target-architecture.md § 11`. Для Astro этот START-файл — **обязательный** перед любой TL-сессией: без него TL пропустит факт отсутствия git и сделает невалидное HANDOFF-поле `Product repo status:`.

### Для Worker (текущая фаза astro — Development Phase 0)

1. [`ai-dev-system/ROLE_MODEL.md`](../../ROLE_MODEL.md) — роль и координация
2. [`ai-dev-system/CLAUDE_GLOBAL.md`](../../CLAUDE_GLOBAL.md)
3. [`ai-dev-system/corrections/global-corrections.md`](../../corrections/global-corrections.md)
4. [`ai-dev-system/guides/LAYER_RESPONSIBILITIES.md`](../../guides/LAYER_RESPONSIBILITIES.md) — слои Worker-задачи (Core / Services / Frontend)
5. `project-overlays/astro/README.md` (этот файл) — особое внимание секции «Bootstrap risks» выше
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
