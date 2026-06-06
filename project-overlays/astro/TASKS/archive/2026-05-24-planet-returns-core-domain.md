# TASK: planet-returns-core-domain

- Status: done
- Ready: yes
- Date: 2026-05-24
- Project: astro
- Layer: core (Haskell: новый `Domain.Returns` + вынос `Domain.TransitMath` из `Domain.TransitCalendar`; pure, без I/O)
- Risk tier: A (Core engine refactor — вынос общего ядра из TransitCalendar; bit-identical инвариант на golden cases; первый Core-код эпика «возвраты»)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: upside2002@gmail.com («го» 2026-05-24)

## Problem

Phase B эпика «возвраты планет» (мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md`). Реализовать **pure Core-движок** ближайших возвратов 10 классических планет. Stage 0 (Phase A, overlay `3471e64`) эмпирически доказал подход и выявил: возвраты медленных планет — 3-проходные ретро-петли; `SolarReturn.findSolarReturnJd` непригоден (forward-only `crossesArc` промахивается мимо ретро-пересечения).

**Два шага:**
1. **Вынести** retro-aware ядро детекции из `Domain.TransitCalendar` в новый `Domain.TransitMath` (общее для `analyzeAnnualCalendar` и нового `Domain.Returns`) — БЕЗ дублирования math (bright line #7 / Correction 004).
2. **Новый `Domain.Returns`** — для каждой натальной планеты найти ближайший возврат (быстрые) / серию точных проходов (медленные) после reference_jd, орб 1°.

**Schema/Bridge/Python/frontend в этой фазе НЕ трогаем** — это Phase C+. Phase B = pure Domain + unit-тесты (in-memory, HUnit).

## Параметры (locked, мемо § 0.1 / 0.2 — Дараган источник)

- **Орб = 1°** (контрольные времена Дарагана = 1° во времени per planet).
- **Только сходящийся + точный** (applying→exact); расходящийся не считаем.
- **Геоцентрика** (все позиции из существующего движка; Меркурий/Венера возвращаются ~раз в год — подтверждено).
- **Быстрые (Sun/Moon/Mercury/Venus/Mars):** один ближайший точный контакт + окно орб-вход→exact.
- **Медленные (Jupiter/Saturn/Uranus/Neptune/Pluto):** возврат = СЕРИЯ точных проходов в ретро-петле (1-3 прохода), headline = первый после reference_jd; pass_number по образцу TransitCalendar.
- **Внешние (Uranus/Neptune/Pluto):** флаг `beyond_lifespan` (Нептун/Плутон true; Уран = once-in-life, не beyond — отдельная пометка по возрасту).
- **10 классических** (Lilith/Nodes — НЕ в этой фазе).

## Scope

### Stage B.1 — Вынос `Domain.TransitMath`

Из `core/astrology-hs/src/Domain/TransitCalendar.hs` вынести в новый `core/astrology-hs/src/Domain/TransitMath.hs` retro-aware helpers (Phase A назвал 6): `signedArc`, `findCrossings`/bracket-detection, `interpolateOrbBoundary`, `findOrbWindows`, `numberContactsFor`, `phaseFromSpeedAndPass` (+ типы `CalSample`, `TransitPhase` если они там же — вынести/реэкспортировать).

`TransitCalendar` импортирует их из `TransitMath`. **Инвариант (КРИТИЧНО):** вывод `analyzeAnnualCalendar` остаётся **бит-в-бит** — все golden cases (`synthetic-solar-1`, calibrated cases) проходят без изменений expected-файлов. Если хоть один golden диффится — STOP, вынос неконсервативен.

Добавить в `.cabal` (`other-modules`/`exposed-modules`) новый `Domain.TransitMath`.

### Stage B.2 — Новый `Domain.Returns`

`core/astrology-hs/src/Domain/Returns.hs`:

```haskell
data PlanetReturn = PlanetReturn
  { prPlanet         :: !Planet
  , prNatalLong      :: !Longitude360
  , prExactJd        :: !Double          -- ближайший точный проход после reference_jd
  , prOrbEnterJd     :: !(Maybe Double)  -- окно 1° (applying→exact)
  , prOrbExitJd      :: !(Maybe Double)
  , prMotion         :: !TransitPhase    -- Direct | Retrograde | DirectReturn
  , prPassNumber     :: !Int             -- проход в ретро-петле (1..3)
  , prPeriodYears    :: !Double          -- средний период обращения (справочно)
  , prBeyondLifespan :: !Bool            -- True: Нептун/Плутон
  } deriving (Eq, Show)

data ReturnsResult = ReturnsResult { rrReturns :: [PlanetReturn] }
  deriving (Eq, Show)

findNearestReturns
  :: [PlanetPosition]                    -- натальные позиции (цели)
  -> Double                              -- reference_jd
  -> Map Planet [(Double,Double,Double)] -- per-planet sample'ы (jd,lon,speed), отсортированы по jd
  -> ReturnsResult                       -- по одной/серии записей на планету, порядок Sun..Pluto
```

Логика: для каждой натальной планеты взять её sample-стрим, через `TransitMath` найти пересечения натальной долготы строго после reference_jd, орб 1°, retro-aware (медленные → серия проходов с pass_number). Быстрые → ближайший единственный. `beyond_lifespan` для Нептун/Плутон. **НЕ использовать** `findSolarReturnJd` (доказано непригоден на ретро).

Modern/classical convention не применимо (возврат = соединение планеты с собой). Никаких rulership/house вычислений (это волны 2-3).

### Stage B.3 — Unit-тесты

`core/astrology-hs/test/` (по образцу существующих spec-ов). Покрыть:
- **Синтетика прямого движения:** планета линейно проходит натальную долготу → assert точный JD (бисекция).
- **Синтетика ретро-петли:** speed меняет знак → 3 пересечения → assert серия из 3 проходов с pass_number 1/2/3 и фазами Direct/Retrograde/DirectReturn.
- **Орб 1°:** окно вход→exact корректно.
- **Reference_jd boundary:** возврат строго ПОСЛЕ reference (не раньше/не на).
- **beyond_lifespan:** Нептун/Плутон флаг.
- **Детерминизм/порядок:** результат стабилен, порядок Sun..Pluto.
- (Опц. realistic cross-check) встроить малый sample-фикстур из Phase A (напр. Сатурн Марины) → assert возврат ≈ дата Phase A HANDOFF `3471e64`.

## Files

- new:
  - `core/astrology-hs/src/Domain/TransitMath.hs` (вынос).
  - `core/astrology-hs/src/Domain/Returns.hs`.
  - `core/astrology-hs/test/Test/ReturnsSpec.hs` (или по существующей конвенции тестов).
- modify:
  - `core/astrology-hs/src/Domain/TransitCalendar.hs` (импорт из TransitMath; поведение бит-в-бит).
  - `core/astrology-hs/*.cabal` (новые модули + test).
  - `project-overlays/astro/STATUS_RU.md`.
- delete: —

## Do not touch

- **Schema** (`packages/contracts/*`), Bridge DTO (`Bridge/Solar.hs`), `app/Main.hs` — это Phase C.
- Python services, frontend — Phase D/E.
- Любые golden expected-файлы (`test/golden/*.expected.json`, calibrated) — должны пройти БЕЗ изменений (инвариант B.1).
- `findSolarReturnJd` / `SolarReturn.hs` — не править, не использовать в Returns.
- `data Planet` — НЕ расширять (Lilith/Nodes — будущие волны; Correction 002).
- DB, PDF, synthesis, outer_cards и пр.
- **NO wildcard** в match по Planet (Correction 002).
- **NO дублирование math** (копипаст вместо выноса) — Correction 004.
- **NO LLM.**

## Acceptance

### Primary
- [ ] `Domain.TransitMath` вынесен; `TransitCalendar` импортирует из него.
- [ ] `analyzeAnnualCalendar` вывод **бит-в-бит** — все golden cases проходят без изменения expected-файлов.
- [ ] `Domain.Returns.findNearestReturns` реализован per § B.2.
- [ ] Быстрые → один ближайший возврат; медленные → серия проходов с pass_number.
- [ ] Орб 1°, applying→exact; reference_jd boundary (строго после).
- [ ] `beyond_lifespan` для Нептун/Плутон.
- [ ] Unit-тесты B.3 проходят (синтетика прямая/ретро, орб, boundary, детерминизм).

### Common
- [ ] `cabal --project-dir core/astrology-hs build` clean (0 warnings-as-errors если включены).
- [ ] `cabal --project-dir core/astrology-hs test` — все тесты зелёные, включая существующие golden (0 изменений expected).
- [ ] `git status --short` чисто для intended changes.
- [ ] Один product commit (Core: TransitMath + Returns + tests + cabal).
- [ ] Один overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity.
- [ ] **Reviewer REQUIRED** (Tier A Core math).

### Discipline
- [ ] NO schema/Bridge/Main изменений (Phase C).
- [ ] NO Python/frontend.
- [ ] NO golden expected правок.
- [ ] NO wildcard Planet match.
- [ ] NO math-дублирование (вынос, не копипаст).
- [ ] NO findSolarReturnJd reuse для ретро.
- [ ] NO Planet sum-type расширение.
- [ ] NO LLM.

## STOP triggers

- Хоть один golden case диффится после выноса (analyzeAnnualCalendar не бит-в-бит) → STOP.
- Worker копипастит детекцию вместо выноса → STOP.
- Worker использует `findSolarReturnJd` для ретро-планет → STOP.
- Worker трогает schema/Bridge/Main/Python/frontend → STOP (не та фаза).
- Worker расширяет `data Planet` → STOP.
- Worker вводит wildcard в Planet match → STOP.
- Worker правит golden expected-файлы, чтобы «прошло» → STOP (это маскировка регрессии).

## Reviewer subagent — REQUIRED

Tier A Core math. После self-submit TL спускает внешнего Reviewer. Критерии:
- Вынос консервативен: golden бит-в-бит (Reviewer независимо прогоняет `cabal test`).
- `findNearestReturns` корректен: синтетика прямая/ретро, орб 1°, boundary, beyond_lifespan.
- Ретро-серия: pass_number/фазы соответствуют TransitCalendar-семантике.
- Нет math-дублирования (вынос, не копипаст); нет wildcard; нет findSolarReturnJd на ретро.
- 0 STOP triggers.

## Context

**Mode strict + Tier A.** Critical approved: upside2002@gmail.com «го» 2026-05-24.

**Baseline:**
- Product main @ `ba806d5` (Useful People Polish landed).
- Overlay master @ `14264f1` (memo locked params).
- Phase A proof: overlay `3471e64` (HANDOFF с reference-числами Марины — для realistic cross-check).
- `cabal test` baseline зелёный.

**Cross-references:**
- Мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` (§ 0.1 / 0.2 параметры, § 3.1 дизайн, § 7 фазы).
- Phase A HANDOFF `HANDOFFS/archive/2026-05-24-worker-to-tl-planet-returns-stage0-empirical-proof.md` (reference дат, retro Сатурн 3-pass, вывод по выносу 6 helpers).
- `core/astrology-hs/src/Domain/TransitCalendar.hs:330-606` (источник выноса).
- `core/astrology-hs/src/Domain/SolarReturn.hs:48` (НЕ использовать — forward-only).
- `core/astrology-hs/src/Domain/Types.hs:83` (`data Planet` — не трогать).

**Не в scope:** schema-gate (Phase C), Python sampler/endpoint (Phase D), UI+PDF (Phase E), самоаспекты/куспиды/Lilith (волны 2-5).

**Ready: yes** — параметры locked первоисточником (Дараган), math де-рискована Phase A, дизайн в мемо. Доп. уточнений не требуется.
