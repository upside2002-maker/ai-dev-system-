# TASK: important-transit-planets-rule-fix

- Status: done
- Ready: yes
- Date: 2026-05-08
- Project: astro
- Layer: core
- Risk tier: A
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: strict

## Problem

Текущая логика `important_transit_planets` в Haskell core (`Domain.ImportantTransitPlanets.hs`) учитывает только 3 reason types: `RulerOfAsc`, `RulerOfMc`, `KingOfAspects`. Этого недостаточно: продуктовая методика Марины опирается на **5 правил**, и текущий engine для Натальи (case 8) выдаёт `[Mercury, Venus]`, тогда как Marina reference (Соляр 2025-2026_5.pdf, p. 7) для той же натальной карты указывает `[Mercury, Sun, Jupiter]` как обязательные. Дополнительные planets допустимы, если каждая объясняется одним из 5 правил.

Цель — привести selection logic к продуктовой методике через bright-line #8 schema-gate cascade, одним atomic коммитом.

### Product rules (5 источников)

`important_transit_planets` = объединение планет из:

1. **Управитель Asc** — по знаку куспида 1 дома. Для `Aquarius` → `Uranus + Saturn`; `Pisces` → `Neptune + Jupiter`; `Scorpio` → `Pluto + Mars`. Остальные знаки — один обычный управитель.
2. **Управитель MC** — по знаку куспида 10 дома. Та же логика двойных управителей для `Aquarius / Pisces / Scorpio`.
3. **Король аспектов** — планета с максимальным числом мажорных аспектов (текущая `KingOfAspects` logic, не меняется).
4. **Управитель знака стеллиума** — если в одном знаке стоит стеллиум, важной считается планета-управитель этого знака. Для `Aquarius / Pisces / Scorpio` берутся оба управителя.
5. **Управитель солнечного знака** — по знаку натального Солнца. Для `Aquarius / Pisces / Scorpio` берутся оба управителя.

### ADT changes (Haskell)

`ImportantTransitReason` расширяется до **ровно 5** значений:
- `RulerOfAsc` (existing)
- `RulerOfMc` (existing)
- `KingOfAspects` (existing)
- `RulerOfSunSign` (NEW)
- `RulerOfStelliumSign` (NEW)

**Новых reason types для "second ruler" не вводить.** Двойные управители для `Aqu/Pis/Sco` выражаются тем, что один и тот же reason type порождает **две планеты** в финальном списке (e.g., `RulerOfAsc` для Asc=Aquarius → emits `Uranus` AND `Saturn`, оба с reason=`RulerOfAsc`).

### Representation rule (dedup + accumulate)

Если одна и та же планета попадает из нескольких источников:
- в финальном `important_transit_planets[]` она присутствует **один раз**;
- её `reasons[]` содержит **полный список** правил, по которым она попала (объединение reason types по всем источникам).

## Files

- modify (core logic):
  - `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs` — extend ADT, rewrite `identifyImportantTransitPlanets` под 5 правил, dedup + accumulate.
  - `core/astrology-hs/src/Domain/Dignities.hs` (если необходимо для shared ruler-table helpers; иначе не трогать).

- modify (schema cascade — bright-line #8):
  - `packages/contracts/solar-computed-facts.schema.json` — расширить enum `important_transit_planets[].reasons[]` до 5 values.
  - `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs` — обновить fixture или roundtrip expectation если нужно.
  - `services/api-python/tests/test_contracts.py` — обновить contract test если зависит от старого enum.
  - `apps/web-react/src/types.ts` — обновить TS reason enum до 5 values.

- modify (regenerate fixtures):
  - `packages/test-fixtures/golden-cases/01-kseniya-2024-2025.expected.json`
  - `packages/test-fixtures/golden-cases/02-maksim-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/03-artem-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/04-valeriya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/05-ekaterina-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/07-mariya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/09-anastasiya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`
  - `packages/test-fixtures/solar-facts-sample.json` (если затронут)

Worker регенерирует через **rebuilt CLI** (`cabal build` ОБЯЗАТЕЛЬНО для этого TASK потому что core changes), затем feed input → CLI → save expected.json.

- new: —
- delete: —

**1 atomic commit**: всё перечисленное одним коммитом, иначе bright-line #8 violation.

## Do not touch

- Haskell core: `Domain.{Directions, PriorityWindows, SolarReportSkeleton, Stellium, KingOfAspects, HouseAxisAnalysis, Progressions, TransitCalendar, SolarReturn, Houses, Aspects, Types, Zodiac, Planets, Ascendant, StrengthAnalysis, WeaknessAnalysis, Transits}` — за исключением `Dignities.hs` (если требуется shared ruler-helpers; иначе тоже не трогать).
- `Bridge.Solar` — не менять (только schema/JSON shape consumed; Bridge остаётся single SOT).
- PDF presentation: `services/api-python/app/pdf/{wheel,builder,direction_themes,house_pair_themes,synthesis_themes,transit_themes}.py`, `templates/solar.html.j2` — НЕ трогать. Presentation update — отдельный Tier C TASK после accept.
- Python services: `services/api-python/app/{main,db,persons,consultations,draft,core_client,models,ephemeris/**,migrations/**}` — НЕ трогать.
- Frontend: `apps/web-react/**` кроме `src/types.ts` (только enum extension в types.ts).
- Lilith / NorthNode / SouthNode / FixedStars — НЕ добавлять. Это отдельный Tier A TASK (`solar-nodes-lilith-retro-display`).
- `LIFE_THEMES` в `synthesis_themes.py` — не трогать (presentation layer).
- `data/`, `infra/`, `astro/.claude/`, `CLAUDE.md`, `docs/`, overlay (`project-overlays/astro/**`) — out of scope.

## Acceptance

### Behavioural invariants (objective, automated)

- [ ] `cabal build` зелёный после ADT extension + rewrite. **`cabal build` РАЗРЕШЁН в этом TASK** (core changes требуют rebuild — это Tier A, не Tier C light).
- [ ] `cabal test` зелёный (все Haskell tests passing, включая Test.Bridge.SolarRoundtripSpec с обновлённым fixture).
- [ ] `pytest 70/70` после regen всех 9 fixtures (case 1-5, 7-10; case 6 — stub, не regen).
- [ ] **Schema cascade complete in 1 commit:** `git show --stat HEAD` показывает изменения во ВСЕХ из:
  - `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs`
  - `packages/contracts/solar-computed-facts.schema.json`
  - `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs` (если нужно)
  - `services/api-python/tests/test_contracts.py` (если затронут)
  - `apps/web-react/src/types.ts`
  - 9 golden case `expected.json` файлов
- [ ] `git log --oneline 7edbedb..HEAD` = ровно 1 commit (atomic cascade).
- [ ] Backup parity: `git ls-remote backup main` == local HEAD.

### ADT correctness

- [ ] `ImportantTransitReason` enum в Haskell ADT содержит ровно 5 values: `RulerOfAsc | RulerOfMc | KingOfAspects | RulerOfSunSign | RulerOfStelliumSign`.
- [ ] `solar-computed-facts.schema.json` enum `important_transit_planets[].reasons[]` содержит ровно те же 5 strings.
- [ ] `apps/web-react/src/types.ts` reason enum содержит ровно те же 5.
- [ ] Никаких "second ruler" reason types типа `SecondRulerOfAsc` (по spec'у — двойные управители выражаются множественностью planets на один reason).

### Logic correctness

- [ ] **Existing 3 reasons работают как раньше:** для cases где `RulerOfAsc` / `RulerOfMc` / `KingOfAspects` были в pre-fix output — те же planets должны быть в post-fix output (либо с extended reasons если добавились по новым правилам).
- [ ] **2 new reasons** (`RulerOfSunSign` / `RulerOfStelliumSign`) появляются только там где правила реально применяются.
- [ ] **Dual-ruler для Aqu/Pis/Sco** — на cases где Asc / MC / Sun-знак ∈ `{Aqu, Pis, Sco}` выдаются ОБА ruler'а (modern + traditional) с тем же reason type.
- [ ] **Dedup**: одна и та же planet встречается в финальном `important_transit_planets[]` ровно один раз.
- [ ] **Accumulate reasons**: если planet попадает по нескольким правилам — её `reasons[]` содержит полный объединённый набор, не только один.

### Oracle (Наталья case 8)

- [ ] После регена `golden-cases/08-natalya-2025-2026.expected.json` для **case 8 (Наталья)** содержит `important_transit_planets` с **обязательным минимумом 3 planets**: `Mercury` + `Sun` + `Jupiter`. Дополнительные planets допустимы, если каждая объяснима одним из 5 правил.
- [ ] Worker в HANDOFF явно объясняет по каким правилам каждая попала (per Marina reference p. 7 + натальная карта Натальи: Asc=Дева → Mercury (RulerOfAsc), MC=Близнецы → Mercury (RulerOfMc — accumulate с RulerOfAsc), Sun=Лев → Sun (RulerOfSunSign), стеллиум в Стрельце → Jupiter (RulerOfStelliumSign)).
- [ ] Mercury, Sun, Jupiter объяснимы правилами, не попали случайно.
- [ ] Любая extra planet (например, Venus через KingOfAspects rule 3) должна быть rule-justifiable; engine не имеет conditional clause для подавления rule 3 если KoA даёт новую planet — это by-design per Marina's 5-rule spec.

### Other 9 cases sanity

- [ ] Для каждого из 8 valid cases (1, 2, 3, 4, 5, 7, 8, 10): после regen каждая planet в `important_transit_planets` объяснима хотя бы одним из 5 правил по натальной карте этого case. Reviewer пробегает phycially.
- [ ] Если planet не объяснима ни одним правилом — automatic REJECT.

### Process invariants

- [ ] Worker применил Correction 008 — `git status --short` checked перед commit.
- [ ] **Mode strict**: отдельный Worker subagent + отдельный Reviewer subagent (две разные сессии, не одна).
- [ ] Worker subagent сам создаёт + заполняет HANDOFF + вызывает `make submit-task`.
- [ ] Reviewer subagent сам создаёт + заполняет Reviewer HANDOFF + verdict.
- [ ] TL accepts ТОЛЬКО при Reviewer verdict = ACCEPT.

### Reviewer checklist (operational, embedded для cold-start subagent)

```
## Independent re-verification
- [ ] Cabal build + cabal test green
- [ ] pytest 70/70 (после regen)
- [ ] git diff на schema: enum `ImportantTransitReason` содержит ровно 5 values, ничего лишнего
- [ ] git diff: соответствие schema ↔ Haskell ADT ↔ TS types
- [ ] Roundtrip test (`Test.Bridge.SolarRoundtripSpec`) обновлён и зелёный

## Logic correctness
- [ ] Existing 3 reasons (`RulerOfAsc` / `RulerOfMc` / `KingOfAspects`) работают как раньше — для cases где они были до фикса, planets всё ещё в списке
- [ ] 2 new reasons (`RulerOfSunSign` / `RulerOfStelliumSign`) появляются там где должны
- [ ] Dual-ruler для `Aqu/Pis/Sco`: на cases где `Asc` / `MC` / Sun-sign ∈ `{Aqu, Pis, Sco}` выдаются оба ruler'а с тем же reason type
- [ ] Dedup работает: одна и та же planet в финальном `important_transit_planets` встречается только один раз
- [ ] Accumulate reasons работает: если planet попадает по нескольким правилам, у неё сохраняется полный список `reasons`

## Oracle (Наталья case 8)
- [ ] `important_transit_planets` для Натальи (case 8) после регена содержит **обязательно**: `Mercury`, `Sun`, `Jupiter`
- [ ] `Mercury`, `Sun`, `Jupiter` объяснимы правилами Марины, а не попали случайно
- [ ] Любая extra planet (e.g., `Venus` через `KingOfAspects`) допустима, если объяснима одним из 5 правил
- [ ] Reviewer явно указывает, по каким rules попали:
  - `Mercury`
  - `Sun`
  - `Jupiter`
  - + любые extras (с указанием reason)

## Other 9 cases sanity
- [ ] Для каждого из case 1-5, 7-10: после регена не появилось random planets без объяснимого reason
- [ ] Reviewer пробегает по списку каждого case и для каждой planet находит applicable rule из 5
- [ ] Если planet в `important_transit_planets` не объяснима ни одним из 5 правил — REJECT

## Scope discipline
- [ ] `git show --stat`: затронуты только expected files (`ImportantTransitPlanets.hs`, при необходимости `Dignities.hs`, schema, fixtures, roundtrip test, Python contract test, TS types)
- [ ] PDF presentation files (`solar.html.j2`, `synthesis_themes.py`, etc.) НЕ затронуты
- [ ] `PriorityWindows` / `SolarReportSkeleton` / `Directions` НЕ затронуты
- [ ] `Lilith` / `Nodes` / `SouthNode` НЕ добавлены

## Process
- [ ] 1 atomic commit (весь cascade одним коммитом)
- [ ] Backup parity verified
- [ ] Worker применил Correction 008 (`git status` check)
```

## Context

**Mode strict + Tier A** (User decision 2026-05-08): первый Tier A в продукте. `policies/MODES.md` § strict требует отдельный Worker subagent + отдельный Reviewer subagent (cold-start, разные сессии). Same-session inline ЗАПРЕЩЁН для этого Tier'а; gate в `accept-task` откажет на A без strict mode.

**Worker subagent** = separate Agent tool call, fresh memory, owns full lifecycle (read TASK → execute через `cabal build` (разрешён для core changes) → fixture regen × 9 → schema cascade → 1 atomic commit → push backup → make new-handoff → fill body sam → make submit-task → return brief summary).

**Reviewer subagent** = separate Agent tool call after Worker submit, fresh memory, given Worker HANDOFF path + Reviewer checklist (см. embedded выше). Owns own HANDOFF + verdict. **Mandatory.**

**Oracle truth scope:** только case 8 (Наталья) имеет product oracle от Marina reference (Соляр 2025-2026_5.pdf p. 7: Mercury + Sun + Jupiter — **обязательный минимум**, не exhaustive). Остальные 8 valid cases (1, 2, 3, 4, 5, 7, 9, 10) — regenerate тавтологически (actual = expected после CLI rerun, pytest зелёный). Это нормально для schema-gate cascade'ов: oracle на одном case'е достаточно для функционального acceptance, schema cascade — для формального. **Reviewer должен дополнительно verify** каждый case'овский post-regen список через сверку с натальной картой того case'а — каждая planet должна быть объяснима хотя бы одним из 5 правил (в т.ч. extras от KingOfAspects rule 3 — допустимы).

**Oracle attribution для Натальи** (case 8): Asc = Дева → Mercury (RulerOfAsc); MC = Близнецы → Mercury (accumulate RulerOfMc); Sun = Лев → Sun (RulerOfSunSign); стеллиум в Стрельце → Jupiter (RulerOfStelliumSign). Финальный список с reasons (минимум):
- `Mercury`: `[RulerOfAsc, RulerOfMc]`
- `Sun`: `[RulerOfSunSign]`
- `Jupiter`: `[RulerOfStelliumSign]`

Engine также применяет rule 3 (KingOfAspects) — без conditional clause. Если KoA-planet — одна из этих 3, она accumulate'ится в reasons. Если KoA — новая planet (например, Venus для case 8), она добавляется как 4-я entry с `[KingOfAspects]`. Это **корректный engine output** per Marina's 5-rule spec — Marina reference перечисляет 3 как обязательный минимум, не exhaustive list.

**TL spec correction (2026-05-08, post-Worker-submit):** TASK изначально ссылался на «case 9 (Наташа)» как oracle subject — это TL-level numbering error. Marina reference chart (1984-08-07 8:40 Москва, Asc=Дева, MC=Близнецы, Sun=Лев, стеллиум в Стрельце) фактически matches **`08-natalya-2025-2026.input.json`**, не case 9 (Анастасия). Worker корректно идентифицировал и proceed'нул against case 8. TL принимает Worker'овскую интерпретацию (а), TASK ссылки исправлены (case 9 → case 8, p. 8 → p. 7). Engine output случилось verify'нут против правильного chart'а. Worker'овский commit `7b86cf9` НЕ требует rework. Также: «ровно 3 planets» переформулировано в «3 обязательных + extras allowed if rule-justified» (per User decision (A) engine-spec strict).

**Bright-line #8 cascade obligatory.** TASK затрагивает `solar-computed-facts.schema.json` enum, поэтому one atomic commit включает: schema + Haskell ADT + Haskell roundtrip test + Python contract test + TS types + 9 fixture regen. Schema-only commit без cascade — auto-REJECT.

**Spec-length note**: TASK body превышает рекомендованные ≤60 строк для нового short template. **Deliberate** для Tier A: 5 product rules + ADT spec + dedup/accumulate semantics + 9-fixture cascade list + Reviewer checklist (mandatory operational form) — не сжимаемы без потери смысла. Mode strict + Tier A оправдывает плотность спеки.

**Baseline**: `astro:7edbedb` (после `synthesis-themes-rewrite-toward-reference`, 7 commits с baseline `4937c00`), pytest 70/70, branch `main`, clean. Backup parity ✓.

**References**:
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` p. 7 — oracle для case 8 (Наталья). См. также TL spec correction note выше — оригинальная отсылка на «case 9» была numbering error.
- Текущая `Domain.ImportantTransitPlanets.hs` — старая 3-reason logic, базовый template для расширения.
- Previous Tier A precedent: НЕТ. Это первый Tier A в Astro. Подсмотреть стиль Tier B atomic commits можно в `astro-core-naming-drift-cleanup` (renames + cabal/imports/Spec.hs одним коммитом).
- Schema cascade pattern: см. `target-architecture.md § 8.3` (двухуровневая модель SOT) + `architecture-invariants.md` § bright line #8.

**Ready: no** — Worker НЕ стартует без явного TL go (после User approval). После TL go: TL flips `Ready: yes` (single-field mechanical edit), spawns Worker subagent через Agent tool с self-contained prompt включая 5 product rules + oracle Натальи (case 8) + Reviewer checklist (для context'а Worker, чтобы он знал что Reviewer проверит — это улучшает его self-verification).
