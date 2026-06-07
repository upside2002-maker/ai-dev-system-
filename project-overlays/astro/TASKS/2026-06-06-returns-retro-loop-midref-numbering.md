# TASK: returns-retro-loop-midref-numbering

- Status: open
- Ready: no
- Date: 2026-06-06
- Project: astro
- Layer: core (Haskell: `Domain.Returns` / `Domain.TransitMath` — нумерация/группировка проходов ретро-петли)
- Risk tier: A (Core money/math-класс — правка движка возвратов; Correction 021: независимый Reviewer обязателен)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: (нет — queued, ждёт приоритизации Owner'а)

## Problem

Находка **RET-1 (low)** из независимого ревью возвратов (HANDOFF `2026-06-06-reviewer-to-tl-returns-belated-independent-review.md`).

Когда `reference_jd` попадает **строго внутрь незавершённой ретро-петли** медленной планеты, `findNearestReturns` нумерует только пережившие reference пересечения. Из-за этого `phaseFromSpeedAndPass` (требует pass≥3 для `DirectReturn`):
1. метит settling-проход текущей петли как `Direct` вместо `DirectReturn`;
2. поглощает первый проход **следующего** цикла (≈29 лет спустя для Сатурна) как «pass 3 / DirectReturn» — **сливая два разных возврата в одну плоскую серию**.

**Репро** (live, Марина person 4): `as_of=2048-04-01` → Saturn `[Retrograde 2048-06-28, Direct 2048-11-21, DirectReturn 2077-12-30]` (последний — уже следующий цикл).

**Severity low, НО:** триггерится ровно для людей, кто **прямо сейчас в своём возврате** (Сатурн ~29/58, Юпитер кратно 12) — т.е. для самой релевантной аудитории. Direction движения и **даты всегда верны**; деградирует только метка `DirectReturn` + группировка проходов. Shipped live/PDF путь с reference=сегодня для большинства чист (петля целиком в будущем).

## Scope (Core fix)

`core/astrology-hs/src/Domain/Returns.hs:211-223` + `Domain/TransitMath.hs:239-243`.

Варианты (Worker выбирает + обосновывает):
- **(a)** Группировать пересечения в петли (по близости долготы/смене знака скорости) **до** отбрасывания pre-reference и до нумерации; нумеровать внутри полной петли; затем фильтровать петли, чья последняя точка > reference. Headline = ближайшая будущая точка, но pass_number/phase отражают позицию в ПОЛНОЙ петле.
- **(b)** Определять полное число проходов петли из sample'ов **до** reference (заглянуть назад), чтобы `phaseFromSpeedAndPass` получил верный pass-index.

Инвариант: НЕ ломать основной случай (reference до начала петли → чистая 1/2/3); НЕ сливать соседние циклы; быстрые планеты без изменений; даты/орб-окна/`beyond_lifespan` без изменений.

## Files
- modify: `core/astrology-hs/src/Domain/Returns.hs`, возможно `Domain/TransitMath.hs`.
- modify/new: тест в `test/Test/Domain/ReturnsSpec.hs` — кейс «reference внутри петли» (синтетика + Марина `as_of=2048-04-01`): ожидаем `[..., DirectReturn 2048-11-21]` без слияния с 2077.
- delete: —

## Do not touch
- Контракт/Bridge/Python/UI (это чисто Core-нумерация; формат не меняется).
- Solar golden (бит-в-бит).
- `data Planet`; без wildcard; без `findSolarReturnJd`.
- **NO LLM.**

## Acceptance
- [ ] reference внутри петли → корректные pass_number/phase, без слияния с соседним циклом (тест).
- [ ] Основной случай (reference до петли) без регрессии.
- [ ] Быстрые планеты, даты, орб-окна, `beyond_lifespan` без изменений.
- [ ] `cabal test` зелёный, golden solar + returns бит-в-бит (кроме нового/правленого returns-теста).
- [ ] **Reviewer REQUIRED (Tier A, независимый — Correction 021).**

## Context
- Источник: HANDOFF `2026-06-06-reviewer-to-tl-returns-belated-independent-review.md` (RET-1).
- Мемо locked-параметры: `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md`.
- Baseline: product `51f1e57`.

**Ready: no** — low severity, не горит. Ждёт приоритизации Owner'а (после №2 STATUS_RU и/или эпика профориентации). Поднять Ready: yes + critical-approval перед запуском.
