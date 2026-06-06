# TASK: planet-returns-schema-gate

- Status: done
- Ready: yes
- Date: 2026-05-24
- Project: astro
- Layer: mixed (contracts + Haskell Bridge + Haskell golden + Python contract-test + TS-типы — атомарный schema-change-gate)
- Risk tier: A (bright line #8 schema-change-gate; 5 артефактов в одном коммите; новый `returns` workflow)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: upside2002@gmail.com («го» 2026-05-24)

## Problem

Phase C эпика «возвраты планет» (мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` § 6). Phase B (`Domain.Returns.findNearestReturns`, product `a1e0c75`, CLOSED) дал чистый Core-движок. Теперь нужно **провести его через границу процесса**: новый **standalone `returns` workflow** (свой контракт + Bridge DTO + dispatch) так, чтобы Python мог вызвать движок и получить JSON.

**Это schema-change-gate (bright line #8): ВСЕ 5 артефактов — в ОДНОМ атомарном коммите.** Контракт — **greenfield** (новые `returns-*.schema.json`), большую `solar-computed-facts.schema.json` НЕ трогаем → blast-radius минимальный.

## Decisions (locked, мемо + TL)

- **Standalone `returns` workflow** (не секция solar-фактов). `app/Main.hs` диспетчеризует по полю `workflow`: `"solar"` → `runSolar` (существующее, не ломать), `"returns"` → `runReturns` (новое).
- **JD-конвенция в контракте** (НЕ ISO). Как `annual_transit_table` (`enter_jd`/`exit_jd` — JD doubles). Конвертация JD→ISO — презентация (Phase E Python/PDF), не контракт. Это сохраняет единый формат дат в контрактах (Correction 001 — без дивергентного datetime-формата).
- **Reuse существующих Bridge sub-типов** (Correction 001 — не дублировать DTO): `natal_positions` использует `BridgePlanetPosition`; `samples` использует `BridgeTransitSample`; meta — существующий тип. НЕ объявлять параллельные record'ы того же смысла.
- **returns[] — плоский список**: медленные планеты дают НЕСКОЛЬКО записей (pass_number 1/2/3), быстрые — одну. Прямой маппинг `ReturnsResult.rrReturns`.

## Scope (5 артефактов, ОДИН коммит)

### C.1 — Контракты (greenfield, новые файлы)

`packages/contracts/returns-input.schema.json`:
```jsonc
{
  "workflow": "returns",
  "natal_positions": [ /* BridgePlanetPosition shape: planet, longitude, ... */ ],
  "reference_jd": 2461000.5,
  "samples": { "Saturn": [ {"jd":..,"longitude":..,"speed":..} ], ... },
  "meta": { ... }
}
```

`packages/contracts/returns-output.schema.json`:
```jsonc
{
  "workflow": "returns",
  "reference_jd": 2461000.5,
  "returns": [
    {
      "planet": "Saturn",
      "natal_longitude": 210.12,
      "exact_jd": 2469129.5,
      "orb_enter_jd": 2469120.0,
      "orb_exit_jd": 2469139.0,
      "motion": "direct",          // direct | retrograde | direct_return
      "pass_number": 1,
      "period_years": 29.46,
      "beyond_lifespan": false
    }
    // slow planets → multiple entries (pass 1/2/3); fast → one
  ],
  "meta": { ... }
}
```
`returns` НЕ в `required` если пусто допустимо — но обычно непустой; согласовать с golden. Draft-2020-12, `additionalProperties:false` по образцу solar-схемы.

### C.2 — Bridge `core/astrology-hs/src/Bridge/Returns.hs` (new) + Main dispatch

- `ReturnsResolvedInput` (FromJSON): `rriNatalPositions :: [BridgePlanetPosition]`, `rriReferenceJd :: Double`, `rriSamples :: Map Text [BridgeTransitSample]`, `rriMeta`. **Импортировать `BridgePlanetPosition` / `BridgeTransitSample` из `Bridge.Solar`** (или вынести в общий `Bridge.Common` если так чище — но не дублировать).
- `ReturnsComputedFacts` (ToJSON): `reference_jd`, `returns` (из `ReturnsResult`), `meta`. Сериализация `MotionPhase` → `"direct"|"retrograde"|"direct_return"` (сверить с тем, как `tcPhase` сериализуется в solar — единый маппинг).
- `runReturns :: ReturnsResolvedInput -> ReturnsComputedFacts` — собрать `samplesMap :: Map Planet [...]` (через `planetFromText`), вызвать `Domain.Returns.findNearestReturns`, обернуть.
- `app/Main.hs`: читать `workflow` из входного JSON; `"solar"` → существующий путь (НЕ ломать), `"returns"` → `runReturns`. Неизвестный workflow → внятная ошибка.
- Добавить `Bridge.Returns` в `.cabal`.

### C.3 — Haskell golden roundtrip

- `core/astrology-hs/test/golden/returns-sample.input.json` + `returns-sample.expected.json` (малый фикстур: 2-3 планеты, включая одну медленную с ретро-серией из ≥2 проходов).
- Тест (по образцу `Test/GoldenSolar.hs`): parse input → `runReturns` → сравнить JSON с expected.
- Input roundtrip: parse → encode → parse стабилен (Eq).

### C.4 — Python contract-test

- `packages/test-fixtures/returns-sample.json` (зеркало expected-output).
- `services/api-python/tests/test_contracts.py`: расширить — `jsonschema.Draft202012Validator.check_schema(returns-output.schema)` + `jsonschema.validate(returns-sample.json, returns-output.schema)`. (И input-schema check-schema.)

### C.5 — TS-типы

- `apps/web-react/src/types.ts`: `PlanetReturn` (поля = returns-output items, snake_case → camelCase по существующей конвенции файла), `ReturnsComputedFacts`. Зеркалят схему.
- `tsc --noEmit` чисто.

## Files

- new:
  - `packages/contracts/returns-input.schema.json`, `packages/contracts/returns-output.schema.json`.
  - `core/astrology-hs/src/Bridge/Returns.hs`.
  - `core/astrology-hs/test/golden/returns-sample.input.json`, `returns-sample.expected.json`.
  - `packages/test-fixtures/returns-sample.json`.
- modify:
  - `core/astrology-hs/app/Main.hs` (workflow dispatch — additive).
  - `core/astrology-hs/*.cabal` (Bridge.Returns + golden fixture data-files если нужно).
  - `core/astrology-hs/test/Spec.hs` (или golden runner) — подключить returns-golden.
  - `services/api-python/tests/test_contracts.py`.
  - `apps/web-react/src/types.ts`.
  - `project-overlays/astro/STATUS_RU.md`.
- delete: —

## Do not touch

- `packages/contracts/solar-*.schema.json` — НЕ трогать (greenfield returns-only).
- `core/astrology-hs/test/golden/synthetic-solar-1.*` + calibrated golden — БЕЗ изменений.
- `Domain.Returns` / `Domain.TransitMath` / `Domain.TransitCalendar` — Phase B closed, НЕ менять логику (только импортировать `findNearestReturns`).
- `Bridge.Solar` `runSolar` / `SolarComputedFacts` / `SolarResolvedInput` — НЕ менять (только реэкспорт sub-типов если нужно).
- Python sampler / endpoint (`app/api/`, `app/ephemeris/`) — Phase D, НЕ трогать (кроме test_contracts.py).
- UI компоненты / PDF templates — Phase E (только types.ts здесь).
- DB, synthesis, outer_cards.
- **NO дублирование DTO-типов** (Correction 001) — reuse BridgePlanetPosition/BridgeTransitSample.
- **NO ISO datetime в контракте** — JD (Correction-consistency).
- **NO split schema-change** по нескольким коммитам (bright line #8 — атомарно).
- **NO LLM.**

## Acceptance

### Primary
- [ ] `returns-input.schema.json` + `returns-output.schema.json` валидны (Draft-2020-12 check-schema).
- [ ] `Bridge.Returns` (`ReturnsResolvedInput`/`ReturnsComputedFacts`/`runReturns`) реализован; reuse BridgePlanetPosition/BridgeTransitSample (без дублирования).
- [ ] `app/Main.hs` диспетчеризует solar/returns; solar путь НЕ сломан.
- [ ] JD-конвенция в контракте (exact_jd/orb_enter_jd/orb_exit_jd — числа), НЕ ISO.
- [ ] returns[] плоский; медленные → серия pass_number, быстрые → одна запись.
- [ ] Haskell golden returns-sample roundtrip проходит; input parse→encode→parse стабилен.
- [ ] Python `test_contracts` валидирует returns-sample против схемы.
- [ ] TS-типы зеркалят схему; `tsc --noEmit` чисто.

### Common
- [ ] `cabal build` clean; `cabal test` — returns-golden + ВСЕ существующие solar/golden зелёные (0 правок solar expected).
- [ ] `pytest` — test_contracts проходит (existing + новый returns).
- [ ] `tsc --noEmit` (frontend) чисто.
- [ ] `git status --short` чисто для intended changes.
- [ ] **ОДИН product commit** со ВСЕМИ 5 артефактами (bright line #8 — атомарно).
- [ ] Один overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity.
- [ ] **Reviewer REQUIRED** (Tier A schema-gate).

### Discipline
- [ ] NO solar-схема/golden/fixture правок.
- [ ] NO Domain.* логики изменений (Phase B closed).
- [ ] NO Python sampler/endpoint (Phase D).
- [ ] NO UI/PDF (Phase E).
- [ ] NO дублирование DTO (Correction 001).
- [ ] NO ISO в контракте.
- [ ] NO split-commit.
- [ ] NO LLM.

## STOP triggers

- Solar-схема / solar-golden / solar-fixture тронуты → STOP.
- Schema-change разбит на >1 коммит → STOP (bright line #8).
- ISO datetime в контракте вместо JD → STOP.
- `runSolar` / solar dispatch сломан → STOP.
- Дублирование BridgePlanetPosition/BridgeTransitSample (параллельный record) → STOP.
- Worker лезет в Python sampler/endpoint или UI/PDF (за пределами test_contracts.py + types.ts) → STOP.
- Worker меняет логику Domain.Returns/TransitMath → STOP (Phase B closed).

## Reviewer subagent — REQUIRED

Tier A schema-gate. После self-submit TL спускает Reviewer (или ревью инлайн, если субагент недоступен — прецедент). Критерии:
- Атомарность: все 5 артефактов в одном коммите (`git show`).
- Roundtrip: Haskell golden returns + Python contract + tsc — независимо зелёные.
- Solar untouched: solar-схема/golden бит-в-бит; runSolar работает.
- JD-конвенция (не ISO); reuse DTO (не дублирование).
- Схема ↔ Bridge DTO ↔ TS взаимно согласованы (поля/типы).
- 0 STOP triggers.

## Context

**Mode strict + Tier A.** Critical approved: upside2002@gmail.com «го» 2026-05-24.

**Baseline:**
- Product main @ `a1e0c75` (Phase B Core CLOSED).
- Overlay master @ `7f94239` (Phase B closure).
- `cabal test` 275/0; `pytest` зелёный; `tsc` чисто — все baseline зелёные.

**Cross-references:**
- Мемо § 5 (JSON-схема), § 6 (schema-gate 5 артефактов).
- `Domain.Returns.findNearestReturns` (Phase B, product `a1e0c75`) — вызывать как есть.
- `core/astrology-hs/src/Bridge/Solar.hs` — `BridgePlanetPosition` (~270), `BridgeTransitSample` (~280), `SolarComputedFacts` ToJSON pattern, `planetFromText` (~618), `MotionPhase` сериализация (сверить с `tcPhase`).
- `core/astrology-hs/app/Main.hs` — текущий solar entry (расширить dispatch).
- `core/astrology-hs/test/Test/GoldenSolar.hs` — образец golden roundtrip.
- `services/api-python/tests/test_contracts.py` — образец contract-test.
- `apps/web-react/src/types.ts` — образец зеркальных типов.

**Не в scope:** Python sampler/endpoint (Phase D), UI-панель/PDF-секция (Phase E), самоаспекты/куспиды/Lilith (волны 2-5).

**Ready: yes** — дизайн в мемо § 5/6, Phase B движок готов, все решения locked. Доп. уточнений не требуется.
