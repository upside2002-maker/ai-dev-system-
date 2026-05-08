# Sitka Office Overlay

> **Если хочешь видеть статус без чтения технических артефактов — [`STATUS_RU.md`](STATUS_RU.md).** Простой русский, 5 разделов, читается за 30 секунд.

Overlay для проекта `sitka-office`.

Репозиторий проекта:
`/Users/ilya/Projects/sitka-office`

Текущая стадия:

- active development
- post-Phase-DM
- lead-first flow уже включён
- message inbox / Avito messaging уже в активной разработке

## Точки входа в сессии (новая ROLE_MODEL)

- [`starts/TECH_LEAD.md`](starts/TECH_LEAD.md) — главный вход для технической работы
- [`starts/BUSINESS_ANALYST.md`](starts/BUSINESS_ANALYST.md) — продуктовая / маркетинговая / юр.-фин. аналитика
- [`starts/REVIEWER.md`](starts/REVIEWER.md) — независимая проверка (Claude или Codex)
- [`starts/WORKER.md`](starts/WORKER.md) — реализация по TASK от TL
- Legacy entrypoints — в [`starts/archive/`](starts/archive/)

## Что читать первым

1. [`OPERATING.md`](OPERATING.md) — живой dashboard (активные TASKS / HANDOFFS / findings)
2. `CURRENT_STATE.md` — что реально есть сейчас
3. `KNOWN_ISSUES.md` — какие ограничения и долги ещё живы
4. `NEXT_ACTIONS.md` — куда логично двигаться дальше
5. `PROJECT_MAP.md` — где в коде лежат основные зоны

## Что читать глубже

- `DOMAIN_V3.md` — финальная доменная модель DM-перехода
- `ARCHITECTURE_V2.md` — ранний архитектурный дизайн
- `MARKET_RESEARCH.md`, `MY_AVITO_AUDIT.md`, `MARKETING_STRATEGY.md` —
  исследовательский слой

## Архив (закрытые фазы)

- `archive/PHASE_0_TASKS.md` — Phase 0 (marketing foundation), закрыта
- `archive/PHASE_1_TASKS.md` — Phase 1 (Marketing Analytics MVP), закрыта
- `archive/PHASE_DM_TASKS.md` — Phase DM (lead-first refactor), закрыта
- `archive/TECHNICAL_ARCHITECTURE_2026-04-15.md` — frozen snapshot
  технической архитектуры (legacy flow на дату 2026-04-15), перенесён
  из корня `ai-dev-system` 2026-04-26

## Важная оговорка

Этот overlay — не источник правды сам по себе. Источник правды:

1. сам repo `sitka-office`
2. его `CLAUDE.md`
3. его `.claude/architecture-invariants.md`

Задача overlay — дать агенту быстрый и актуальный вход в проект, а не
заменить кодовую базу.
