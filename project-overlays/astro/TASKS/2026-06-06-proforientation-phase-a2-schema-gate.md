# TASK: proforientation-phase-a2-schema-gate

- Status: open
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: mixed (contracts + Haskell Bridge + Haskell golden + Python contract-test + TS — атомарный schema-gate)
- Risk tier: A (bright line #8 schema-change-gate; новый `vocation` workflow; money/career-класс)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: upside2002@gmail.com («го» 2026-06-06)
- Reviewer: (независимый, после self-submit — Correction 021; заполнить при приёмке)

## Problem

Phase A2 эпика профориентации. Phase A1 (закрыт, `7dc313e`, независимый ревью APPROVE) дал чистый Core-движок `Domain.Vocation` (стадии 1–4, выход = топ-2–3 «планета+дом» + таблица факторов). A2 проводит его **через границу процесса**: новый standalone `vocation` workflow (контракт + Bridge DTO + dispatch + golden + TS), по образцу возвратов Phase C (`37db1c2`).

**Schema-change-gate (bright line #8): ВСЕ 5 артефактов — в ОДНОМ атомарном коммите.** Контракт greenfield (`vocation-*`), solar/returns-схемы НЕ трогаем.

## Decisions (locked)

- **Standalone `vocation` workflow.** `app/Main.hs` диспетчеризует по `workflow`: `"solar"`/`"returns"` (существующие, не ломать) + `"vocation"` (новое) → `runVocation`.
- **Вход = статичный натал** (профориентация — натальный анализ, без time-series): `vocation-input` = `natal_positions` + `house_cusps` (Placidus, с Asc/MC) + `meta`. НЕ нужны transit_samples.
- **Выход** = `VocationResult`: ранжированные топ-сочетания (планета + связанные дома + ключи факторов + score/ранг) + таблица факторов (стадии 1–2). **Без текста толкования** (стадия 5 = Phase B). Машинные ключи факторов — чтобы Phase B подставлял правила.
- **Reuse Bridge sub-типов** (Correction 001): `BridgePlanetPosition`, house-cusps representation, meta — импортировать из `Bridge.Solar`, не дублировать.
- **F1 cleanup (из ревью A1):** удалить мёртвую `planetsInHouse` (`Domain/Vocation.hs:586-588`) — в этом же коммите (dead-code, golden остаётся бит-в-бит).

## Scope (5 артефактов, ОДИН коммит)

### A2.1 — Контракты (greenfield)
`packages/contracts/vocation-input.schema.json`: `{ workflow:"vocation", natal_positions:[BridgePlanetPosition-shape], house_cusps:{...Placidus, Asc, MC...}, meta }`.
`packages/contracts/vocation-output.schema.json`: `{ workflow:"vocation", top_combinations:[{planet, connected_houses:[int], factor_keys:[str], rank, score}], factor_table:{...стадии 1-2 по планетам...}, meta }`. Draft-2020-12, `additionalProperties:false`, по стилю solar/returns. Поля = то, что реально эмитит Bridge ToJSON.

### A2.2 — `Bridge.Vocation` (new) + Main dispatch
- `VocationResolvedInput` (FromJSON): natal_positions, house_cusps, meta (reuse sub-типов из Bridge.Solar).
- `VocationComputedFacts` (ToJSON): top_combinations + factor_table + meta (из `Domain.Vocation` результата).
- `runVocation :: VocationResolvedInput -> VocationComputedFacts` — собрать вход, вызвать `Domain.Vocation` анализатор, обернуть.
- `app/Main.hs`: ветка `"vocation"` (solar/returns не ломать; неизвестный workflow → внятная ошибка).
- `.cabal`: `Bridge.Vocation`.

### A2.3 — Haskell golden roundtrip
`test/golden/vocation-sample.{input,expected}.json` — фикстура (Банкир ИЛИ Marina; та, что в A1 golden). Тест (по образцу `GoldenReturns`): parse→runVocation→expected; input roundtrip parse→encode→parse.

### A2.4 — Python contract-test
`packages/test-fixtures/vocation-sample.json` (зеркало expected). `services/api-python/tests/test_contracts.py`: check_schema ×2 + validate.

### A2.5 — TS-типы
`apps/web-react/src/types.ts`: `VocationResult`/`VocationComputedFacts` + sub-типы, зеркалят схему. `tsc --noEmit` чисто.

## Files
- new: `packages/contracts/vocation-input.schema.json`, `vocation-output.schema.json`; `core/astrology-hs/src/Bridge/Vocation.hs`; `core/astrology-hs/test/golden/vocation-sample.{input,expected}.json`; `packages/test-fixtures/vocation-sample.json`.
- modify: `core/astrology-hs/app/Main.hs`; `core/astrology-hs/*.cabal`; `core/astrology-hs/test/Spec.hs` (golden runner); `services/api-python/tests/test_contracts.py`; `apps/web-react/src/types.ts`; `core/astrology-hs/src/Domain/Vocation.hs` (F1 dead-code удаление); возможно `Bridge.Solar` (аддитивный реэкспорт sub-типов).
- delete: —

## Do not touch
- `solar-*` / `returns-*` схемы + их golden/fixtures — БЕЗ изменений.
- `Domain.Vocation` логика стадий 1–4 — НЕ менять (только удалить dead `planetsInHouse`); A1 closed.
- `Domain.Returns`/`TransitMath`/`TransitCalendar`, `runSolar`/`runReturns` — не трогать (только реэкспорт sub-типов если нужно).
- Python sampler/endpoint, UI компоненты, PDF — это Phase B (кроме test_contracts.py + types.ts здесь).
- **NO дублирование DTO** (Correction 001). **NO split schema-change** по коммитам (bright line #8). **NO стадия 5 / толкование.** **NO LLM.**

## Acceptance
### Primary
- [ ] `vocation-input/output.schema.json` валидны (Draft-2020-12 check-schema).
- [ ] `Bridge.Vocation` (`runVocation`) + Main dispatch; solar/returns не сломаны.
- [ ] Вход = натал+куспиды (без samples); выход = top_combinations + factor_table, без текста толкования.
- [ ] Haskell golden vocation roundtrip проходит; input parse→encode→parse стабилен.
- [ ] Python `test_contracts` валидирует vocation-sample.
- [ ] TS-типы зеркалят схему; `tsc --noEmit` чисто.
- [ ] F1 dead-code удалён; golden (solar/returns/vocation-A1) бит-в-бит.

### Common
- [ ] `cabal build` clean; `cabal test` — vocation golden + ВСЕ существующие зелёные (0 правок solar/returns expected).
- [ ] `pytest test_contracts` зелёный; `tsc --noEmit` чисто.
- [ ] `git status --short` чисто для intended.
- [ ] **ОДИН product commit** со ВСЕМИ 5 артефактами + F1 (bright line #8 атомарно).
- [ ] Один overlay commit (HANDOFF + journal).
- [ ] Push backup, parity.
- [ ] **Reviewer REQUIRED (Tier A, независимый — Correction 021).**

### Discipline
- [ ] NO solar/returns схема/golden правок. NO Domain.Vocation логики (кроме F1). NO Python sampler/endpoint/UI/PDF (Phase B). NO дублирование DTO. NO split-commit. NO стадия 5. NO LLM.

## STOP triggers
- solar/returns схема/golden тронуты → STOP.
- Schema-change разбит на >1 коммит → STOP.
- `runSolar`/`runReturns`/solar dispatch сломан → STOP.
- Дублирование Bridge sub-типов → STOP.
- Worker лезет в Python sampler/endpoint/UI/PDF (за пределами test_contracts.py + types.ts) → STOP.
- Worker меняет логику стадий 1–4 / добавляет толкование → STOP.

## Reviewer subagent — REQUIRED (Tier A, независимый)
После self-submit TL спускает независимого Reviewer (Correction 021). Критерии: атомарность (5 артефактов один коммит, `git show`); roundtrip (Haskell golden + Python contract + tsc) независимо зелёные; solar/returns untouched; схема↔Bridge↔TS согласованы; reuse DTO не дубль; F1 удалён, golden бит-в-бит; 0 STOP.

## Context
**Mode strict + Tier A.** Critical approved: «го» 2026-06-06.
**Baseline:** product `7dc313e` (A1 ядро); overlay свежий; `cabal test` 334/0.
**Cross-references:**
- `Domain.Vocation` (A1) — анализатор для `runVocation`.
- `Bridge.Returns` + `returns-*.schema.json` (Phase C, `37db1c2`) — образец schema-gate.
- `Bridge.Solar` — `BridgePlanetPosition`, house-cusps DTO, meta, `planetFromText`.
- `app/Main.hs` — dispatch (расширить).
- `test/Test/GoldenReturns.hs` — образец golden.
- A1 HANDOFF + reviewer HANDOFF (archive) — формат VocationResult, F1.
**Не в scope:** Phase B (толкование-правила + раздел консультации PDF+UI).
**Ready: yes** — A1 ядро закрыто+проверено, образец (возвраты Phase C) есть, решения locked.
