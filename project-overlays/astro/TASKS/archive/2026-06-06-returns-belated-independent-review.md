# TASK: returns-belated-independent-review

- Status: done
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: docs (READ-ONLY независимый ревью diff'а; продуктового кода не пишем — находки оформляются отдельными fix-TASK'ами)
- Risk tier: A (subject = money/math-класс Core-движок возвратов; закрывает процессный долг X-1)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Reviewer-роль, ОТДЕЛЬНАЯ сессия)
- Mode: strict
- Critical approved by: upside2002@gmail.com («го» 2026-06-06)
- Reviewer: независимый Reviewer-агент (отдельная сессия 2026-06-06) — APPROVE-WITH-FINDINGS; verdict в `HANDOFFS/archive/2026-06-06-reviewer-to-tl-returns-belated-independent-review.md`

## Problem

Самопроверка (`policies/AUDIT.md`, 2026-06-06) + архитектурный аудит (`docs/ARCHITECT_REVIEW_2026-06-05.md`, находка **X-1 critical**) вскрыли: Core-движок «возвраты планет» (money/math-класс) закрыт **inline-самопроверкой TL** вместо обязательного **независимого** ревьюера. Фаза C — Tier A, где независимый ревью обязателен. Непроверенный (в смысле изоляции) код уже в `main`.

**Задача:** провести **запоздалый независимый ревью** всего diff'а возвратов (фазы B–E) свежим ревьюером, который НЕ участвовал в реализации и НЕ опирается на прежние inline-вердикты TL. Подтвердить корректность money/math либо завести находки.

На будущее долг закрыт замком (Correction 021: `accept-task` требует независимого `Reviewer:` на Tier A) — этот TASK гасит уже-в-main хвост.

## Scope (READ-ONLY независимая проверка)

**Diff под ревью (product):** `ba806d5..51f1e57` — 4 коммита, 30 файлов, +10076:
- `a1e0c75` (B) — `Domain.Returns` + вынос `Domain.TransitMath` из `TransitCalendar`.
- `37db1c2` (C) — schema-gate: `returns-*` контракт + `Bridge.Returns` + Main dispatch + golden + TS.
- `4bdf1b1` (D) — Python sampler + `GET /persons/{id}/returns`.
- `51f1e57` (E) — PDF-секция + UI-панель + JD→дата.

**Что проверить (приоритет — B и C, money/math и контракт):**

1. **Корректность ядра (B):** бисекция/детекция пересечений (`findCrossings`), орб-окна (`findOrbWindows`), нумерация проходов (`numberPasses`), фазы Direct/Retrograde/DirectReturn, `beyond_lifespan` (только Нептун/Плутон), порядок Sun..Pluto, граница «строго после reference_jd». Скептически: есть ли off-by-one, потеря прохода в ретро-петле, неверный орб, неверная классификация.
2. **Вынос без регрессии (B):** `analyzeAnnualCalendar` бит-в-бит (golden solar без изменений expected); нет дублирования math (хелперы только в `TransitMath`).
3. **Контракт (C):** schema ↔ Bridge DTO ↔ TS согласованы; JD-конвенция (не ISO); reuse `BridgePlanetPosition`/`BridgeTransitSample` (не дубль); solar-схема не тронута; атомарность коммита.
4. **Оркестрация (D):** один subprocess-вызов (bright line #6); нет math в Python (bright line #7); не кэшируется в БД.
5. **Выдача (E):** факт-таблица без Дараган-verbatim; существующие секции целы; AST-WIRE-1 СНЯТ — подтвердить, что `Domain.Returns` реально доходит до PDF/UI (на момент аудита 2026-06-05 был помечен not-wired; фазы C-E подключили).
6. **Эфемериды:** геоцентрика/тропик `FLG_SWIEPH|FLG_SPEED`; sanity на Марине (person 4): Sun ≈ ДР, Saturn серия, внешние beyond-life.

**Независимая проверка обязательна:** ревьюер сам прогоняет `cabal test`, `pytest`, читает код — НЕ верит числам из прежних HANDOFF/STATUS_RU.

## Files

- new: HANDOFF/review `project-overlays/astro/HANDOFFS/2026-06-06-reviewer-to-tl-returns-belated-independent-review.md` (вердикт + находки).
- modify: `project-overlays/astro/STATUS_RU.md` (запись о закрытии X-1).
- delete: —

Находки, требующие правок кода → **отдельные fix-TASK'и**, не в этом ревью (read-only).

## Do not touch

- Любой продуктовый код (ревью read-only).
- Существующие тесты/фикстуры (только прогон).
- **NO правок кода** — находки оформляются TASK'ами.
- **NO опоры на прежние inline-вердикты TL** — независимая проверка с нуля.
- **NO LLM.**

## Acceptance

- [ ] Diff `ba806d5..51f1e57` прочитан независимо (B/C приоритет).
- [ ] `cabal test` + `pytest` прогнаны самим ревьюером; числа подтверждены/опровергнуты.
- [ ] Money/math ядра проверены скептически (бисекция/орб/проходы/beyond_lifespan/граница).
- [ ] Вынос `TransitMath` без регрессии solar (golden бит-в-бит) — подтверждено.
- [ ] Контракт↔Bridge↔TS согласованность + JD + solar-untouched + атомарность.
- [ ] AST-WIRE-1 снят: `Domain.Returns` доходит до PDF/UI — подтверждено (или находка).
- [ ] Вердикт: APPROVE (X-1 долг погашен) ЛИБО список находок с severity.
- [ ] Находки code-fix → отдельные TASK'и заведены.
- [ ] HANDOFF написан; STATUS_RU отметка о закрытии X-1.

## Context

**Mode strict + Tier A.** Critical approved: upside2002@gmail.com «го» 2026-06-06.

**Baseline:** product `51f1e57`; overlay свежий. `cabal test` ожид. 279/0; `pytest` ожид. 728/3/0 — ревьюер проверяет сам.

**Cross-references:**
- `docs/ARCHITECT_REVIEW_2026-06-05.md` — X-1 (critical), AST-WIRE-1 (medium, проверить снятие), AST-OPS-1 (PII в фикстурах — отдельно), low-находки (бисекция лишний `signed_diff(lo)`, прогрессии 365.25 vs тропик).
- `MAILBOX/to-tl-astro.md` 2026-06-06 — задача №1.
- Мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` (locked-параметры: орб 1°, fast/slow, геоцентрика).
- Архивные HANDOFF фаз A-E (`HANDOFFS/archive/2026-05-24-worker-to-tl-planet-returns-*`) — для контекста, НЕ как источник истины.

**Ready: yes** — diff заморожен в `main`, параметры в мемо, аудит-находки даны. Независимый ревьюер стартует.
