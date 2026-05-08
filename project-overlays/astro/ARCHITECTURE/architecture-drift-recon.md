# Architecture Drift Recon — Astro

**Дата:** 2026-05-06.
**Baseline:** `astro:4937c00` (`chore: initial local git import after AI Dev System bootstrap`).
**Автор:** Worker (AI Dev System).
**Источник запроса:** TASK `architecture-drift-recon` (`project-overlays/astro/TASKS/2026-05-06-architecture-drift-recon.md`).
**Статус:** recon-only. Этот документ **не разрешает** дрейф, только описывает его. Решения по обновлению prescriptive документов — отдельным TASK по результатам.

---

## 1. Baseline и метод

### 1.1 Baseline

- Git commit: `4937c0065054f627e92f59b1e7bf8b29c3c4d7f2` (short `4937c00`).
- 161 файл tracked в product repo `/Users/ilya/Projects/astro/`.
- Branch: `main`.
- Backup mirror: `/Users/ilya/Backups/astro.git` (HEAD == 4937c00).

### 1.2 Источники сверки (overlay)

Документы, против которых выполнялась сверка:

1. `project-overlays/astro/starts/TECH_LEAD.md`
2. `project-overlays/astro/README.md`
3. `project-overlays/astro/ARCHITECTURE/target-architecture.md` (от 2026-04-24, prescriptive)
4. `project-overlays/astro/ARCHITECTURE/migration-plan.md` (от 2026-04-24, prescriptive)
5. `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` (от 2026-04-24, prescriptive)

### 1.3 Метод evidence

Все claims в § 2-§ 5 ниже подтверждены одной из следующих форм:

- `git ls-tree [-r] 4937c00 -- <path>` — наличие файла/каталога в blob.
- `git show 4937c00:<path>` (с `head` / `grep`) — содержимое файла на указанный commit.
- `wc -l` / счёт по awk — размеры.
- Прямая цитата ≤ 15 слов из overlay-документа (с указанием файла и предметной секции).

Никаких claim'ов «по памяти» из предыдущих сессий. См. § 7 «Evidence appendix» — список конкретных команд с фрагментами вывода.

### 1.4 Ограничение recon

Этот документ:
- **не** меняет product code в `/Users/ilya/Projects/astro/`;
- **не** меняет prescriptive документы (`target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, `current-mvp-review.md`);
- **не** меняет `.overlay-maturity`;
- **не** создаёт `CURRENT_STATE.md` / `KNOWN_ISSUES.md` / `NEXT_ACTIONS.md` / `PROJECT_MAP.md`;
- **не** записывает в `astro/.claude/{corrections,architecture-invariants}.md`;
- **не** запускает `cabal build` / `pytest` / `npm` / `tsc`.

---

## 2. Что реально реализовано в `astro:4937c00`

Inventory по слоям. Каждый пункт — путь в repo + 1-2 предложения о роли + git evidence.

### 2.1 Core — Haskell (`core/astrology-hs/`)

**Cabal layout:** `app/Main.hs`, `astrology-core.cabal`, `cabal.project`.

**Adapters (FFI-обвязка raw):**
- `src/Adapters/Ephemeris/Types.hs` — типы для ephemeris-данных, приходящих из Python (без FFI).
- `src/Adapters/TimeZone.hs` — type wrappers для tz-данных.

Файлов `Adapters/Ephemeris/Swiss.hs`, `Domain/Report.hs`, `services/orchestrator-python/`, `packages/contracts/core-input.schema.json` в blob `4937c00` **нет** — соответствует cleanup-предписанию `PHASE_0_TASKS.md § T-A.2`.

**Bridge (межслойный SOT, target § 8.3):**
- `src/Bridge/Solar.hs` (875 строк) — **единственный** модуль с `SolarResolvedInput` / `SolarComputedFacts` + их `FromJSON`/`ToJSON`. Module header цитирует bright line #5, #6, #8 + Correction 001. Соответствует target § 8.3 + invariant #8.

**Domain (20 модулей):**

Прямо предусмотрены target / `PHASE_0_TASKS.md`:
- `src/Domain/Types.hs` — newtypes + ADT (T-B.1).
- `src/Domain/Aspects.hs` — `findAspects` + `OrbConfig` (T-B.2).
- `src/Domain/Houses/Placidus.hs` — Placidus cusps (mini-MVP carryover).
- `src/Domain/SolarReturn.hs` — bisection (T-B.5).
- `src/Domain/Transits.hs` — single-shot transit-to-asc (mini-MVP carryover).
- `src/Domain/Dignities.hs`, `src/Domain/StrengthAnalysis.hs`, `src/Domain/WeaknessAnalysis.hs` — классификации (mini-MVP carryover).
- `src/Domain/Zodiac.hs`, `src/Domain/Planets.hs`, `src/Domain/Ascendant.hs` — базовые типы (mini-MVP carryover).

**Не предусмотрены overlay-документами**, появились в Phase 0.5–0.10b:
- `src/Domain/Directions.hs` — Solar Arc / symbolic directions, фильтр Asc/MC/1-house (cited module header: «Architects Архипова's "формулы"»).
- `src/Domain/HouseAxisAnalysis.hs` — анализ year-themes по осям домов.
- `src/Domain/PriorityWindows.hs` — оконные приоритеты (драйвер для key periods).
- `src/Domain/Progressions.hs` — progressed Moon, прогрессии для psych setting.
- `src/Domain/TransitCalendar.hs` — annual calendar; module header: `«Phase 0.5»`.
- `src/Domain/Stellium.hs` — стеллиумы.
- `src/Domain/KingOfAspects.hs` — «король аспектов» (анализ доминирующих линий).
- `src/Domain/ImportantTransitPlanets.hs` — выбор слоу-планет для transit calendar.
- `src/Domain/ConsultationSkeleton.hs` — module header: `«Phase 0.7»`. Аггрегатор «уже посчитанных блоков → структурированный черновик письма».

Отсутствуют в `4937c00` (предусмотрены target / `PHASE_0_TASKS.md`, но не реализованы):
- `src/Domain/Houses/Equal.hs` (T-B.3).
- `src/Domain/FixedStars.hs` (T-B.4).

**Tests** (`test/`): `Spec.hs` + 19 spec-модулей (включая `Test/Bridge/SolarRoundtripSpec.hs`, `Test/Domain/InvariantsSpec.hs`, `Test/Domain/Houses/PlacidusSpec.hs`, по spec'у на каждый Phase-0.5+ модуль) + `Test/Golden.hs` + `Test/Golden/SolarSpec.hs`. Golden fixtures: `placidus-reference.json`, `synthetic-solar-1.{input,expected}.json`.

### 2.2 Services — Python (`services/api-python/`)

Структура (`app/`):
- `main.py` — FastAPI app (T-D.3).
- `models.py` — Pydantic под межслойные DTO (T-D.3).
- `db.py` — SQLite session + миграции (T-D.1).
- `persons.py`, `consultations.py` — CRUD + workflow runner (T-D.1).
- `core_client.py` — subprocess Haskell CLI (mini-MVP carryover).
- `ephemeris/{__init__,bridge,cache}.py` — FFI к pyswisseph + ephemeris loader (T-A.5 + T-D.2 partial).
- `migrations/001_initial.sql` (T-D.1) + `migrations/002_draft_overrides.sql` (header: `«Phase 0.8: editable consultation drafts with manual overrides»`).
- `pdf/{__init__,builder,wheel}.py` — PDF pipeline (T-A.5 + T-D.4).
- `pdf/templates/solar.html.j2` — Jinja2-шаблон (T-D.4).

**Не предусмотрены overlay-документами**, появились в Phase 0.5–0.10b:
- `pdf/wheel.py` — SVG-генерация колёс с глифами.
- `pdf/direction_themes.py` — closed-dictionary текст по дирекциям.
- `pdf/house_pair_themes.py` — 144-cell интерпретации Solar/Natal house pairs.
- `pdf/transit_themes.py` — 84-entry интерпретации «{планета} в {доме}».
- `pdf/synthesis_themes.py` — theme-grouped синтез «Итогов консультации» (10 life themes).
- `app/draft.py` — поддержка manual overrides поверх machine-generated facts.

Отсутствуют в `4937c00` (предусмотрены `PHASE_0_TASKS.md`):
- `app/ephemeris/geocoder.py` — отдельный модуль геокодинга (T-D.2).
- `app/ephemeris/timezone.py` — отдельный модуль tz-resolve (T-D.2).
- `app/ephemeris/fixed_stars.py` — каталог топ-30 звёзд (T-D.2 / target § 10.2).

**Tests**: `test_api.py`, `test_bridge.py`, `test_contracts.py`, `test_draft.py`, `test_golden_cases.py`, `test_storage.py`. Дополнительный скрипт `scripts/generate_placidus_reference.py`.

### 2.3 Frontend — React (`apps/web-react/src/`)

Прямо предусмотрены overlay:
- `pages/PersonList.tsx`, `PersonForm.tsx`, `PersonDetails.tsx` (T-E.2).
- `pages/ConsultationForm.tsx`, `ConsultationView.tsx` (T-E.3).
- `components/NatalChartFacts.tsx`, `SolarChartFacts.tsx` (T-E.4).
- `App.tsx`, `api.ts`, `types.ts`, `main.tsx`, `vite.config.ts`, `index.html`, `tsconfig.json`, `package.json`, `package-lock.json`.

**Не предусмотрены overlay-документами**, появились в Phase 0.5–0.10b:
- `pages/DraftEditor.tsx` — UI для editorial overrides поверх consultation skeleton.
- `components/draft-editor/*` (16 файлов: `ActionBar.tsx`, `CautionsEditor.tsx`, `ClosingNotesEditor.tsx`, `ConfirmResetModal.tsx`, `ExtendedThemesEditor.tsx`, `FieldOverride.tsx`, `FinalPreview.tsx`, `KeyPeriodCard.tsx`, `KeyPeriodsEditor.tsx`, `ListOverride.tsx`, `OpeningEditor.tsx`, `PsychSettingEditor.tsx`, `SectionShell.tsx`, `StatusBadge.tsx`, `helpers.ts`, `styles.ts`).
- `lib/draftMerge.ts`, `lib/i18n.ts`.

Отсутствуют в `4937c00` (предусмотрены `PHASE_0_TASKS.md` § T-E.4):
- `components/AnnualTransitTable.tsx` — компонент годовой таблицы транзитов на UI (заменён вытяжкой через PDF-pipeline через `transit_themes.py`).

### 2.4 Contracts (`packages/`)

Schemas:
- `packages/contracts/solar-resolved-input.schema.json` (T-C.1).
- `packages/contracts/solar-computed-facts.schema.json` (T-C.2).
- `packages/contracts/person.schema.json`, `consultation.schema.json` (T-C.3).
- **Не предусмотрена**: `packages/contracts/consultation-draft-overrides.schema.json` — Phase 0.8 (parallel к `002_draft_overrides.sql`).

Rulesets:
- `packages/rulesets/ruleset-v1.0.0.json` (mini-MVP carryover, оставлен).
- `packages/rulesets/ruleset-v2.0.0.json` (T-A.6) — header: `«0.1 base; 0.2 extends with Nodes/Lilith/Chiron/FixedStars/EqualFromAsc/Daragan-orbs»`. Содержит `deferred_to_phase_0_2` секцию для перечисленного.
- `packages/rulesets/daragan-orbs-v1.json` (T-A.6).

Test-fixtures:
- `packages/test-fixtures/solar-input-sample.json`, `solar-facts-sample.json` (T-C.3).
- `packages/test-fixtures/golden-cases/*` — **9 пар** реальных кейсов клиентов (`01-kseniya-2024-2025` … `10-danila-2025-2026`, плюс `06-incomplete-2025-2026.stub.json`). T-F.2 предписывал ≥ 3 — фактически 9.
- Helpers: `_compare_directions.py`, `_generate.py`.

### 2.5 Infra и docs

- `run-local.sh` (T-F.1), `docker-compose.yml`, `infra/docker/{api,web}.Dockerfile`, `infra/docker/nginx.conf`.
- `CLAUDE.md` (T-A.3), `.claude/architecture-invariants.md` (T-A.3, цитирует все 8 bright lines), `.claude/corrections.md` (T-A.3, начальный набор Correction 001 «не дублировать DTO» + Correction 002 «no catch-all» + Correction 003 «no operational data in Core» + последующие).
- `docs/PHASE_0_DEMO.md` (T-F.3), `docs/architecture/adr-0001-python-ephemeris-bridge.md` (T-A.4 предписала пометить как Superseded — нужна сверка с реальным содержанием в § 7), `docs/architecture/placidus-validation.md`, `docs/agents/current-state-handoff.md` (T-A.4 предписала пометить как Archived).

---

## 3. Какие пункты `PHASE_0_TASKS.md` уже фактически закрыты

Walk через каждый блок. Статусы: `closed-in-fact` / `partial` / `not-started` / `obsolete-by-evolution`.

### Block A — Cleanup и подготовка

| TASK | Статус | Evidence |
|------|--------|----------|
| T-A.1 (gitignore + dist-newstyle) | `closed-in-fact` | `.gitignore` 35 строк (4937c00), `dist-newstyle/` отсутствует. |
| T-A.2 (удалить мёртвые модули) | `closed-in-fact` | `services/orchestrator-python/`, `Adapters/Ephemeris/Swiss.hs`, `Domain/Report.hs`, `core-input.schema.json` отсутствуют. |
| T-A.3 (architecture-invariants + corrections + CLAUDE.md) | `closed-in-fact` | Файлы существуют; invariants содержит все 8 bright lines цитатой. |
| T-A.4 (пометить устаревшие docs) | `partial` | Файлы `docs/architecture/adr-0001-*.md` и `docs/agents/current-state-handoff.md` существуют; статус блок-шапки не сверял (recon-only). |
| T-A.5 (схлопнуть ephemeris-python + pdf-python) | `closed-in-fact` | `services/{ephemeris,pdf}-python/` отсутствуют; `services/api-python/app/{ephemeris,pdf}/` присутствуют. |
| T-A.6 (ruleset-v2 + daragan-orbs) | `closed-in-fact` | Оба файла существуют; ruleset-v2 содержит секцию `deferred_to_phase_0_2`. |

### Block B — Core

| TASK | Статус | Evidence |
|------|--------|----------|
| T-B.1 (newtypes + ADT расширение) | `partial` | Newtypes + базовое ADT есть. **Planet ADT остался 10 классических** (без NorthNode/SouthNode/Lilith/Chiron/FixedStar) — Phase 0.2 deferral подтверждён ruleset-v2 `deferred_to_phase_0_2`. |
| T-B.2 (параметризация Aspects через OrbProfile) | `closed-in-fact` | `Bridge.Solar` импортирует `OrbConfig(..)` из `Domain.Aspects`. |
| T-B.3 (Domain.Houses.Equal) | `not-started` | `Houses/Equal.hs` отсутствует; `Houses/` содержит только `Placidus.hs`. |
| T-B.4 (Domain.FixedStars + precession) | `not-started` | `Domain/FixedStars.hs` отсутствует. |
| T-B.5 (Domain.SolarReturn) | `closed-in-fact` | `src/Domain/SolarReturn.hs` присутствует + spec `Test/Domain/SolarReturnSpec.hs`. |
| T-B.6 (Domain.TransitTable) | `obsolete-by-evolution` | Прескрипция: модуль `Domain.TransitTable` для Mars/Venus/Saturn/Jupiter × 12 домов. Реальность: модуль называется `Domain.TransitCalendar`, header цитирует `«Phase 0.5»`, scope расширен на Jupiter/Saturn/Uranus/Neptune/Pluto «outer slow planets» (cited from `pdf/transit_themes.py`). |
| T-B.7 (Main.hs + Bridge.Solar) | `closed-in-fact` | `Bridge/Solar.hs` (875 строк), single SOT, exports `runSolar`. |
| T-B.8 (property tests + golden infra) | `partial` | `Test/Domain/InvariantsSpec.hs` + golden fixtures есть. **Не выполнено** переименование `Test.Golden` → `Test.GoldenSolar` (модуль остался под старым именем; `Test/Golden/SolarSpec.hs` создан как parallel). |

### Block C — Contracts

| TASK | Статус | Evidence |
|------|--------|----------|
| T-C.1 (`solar-resolved-input.schema.json`) | `closed-in-fact` | Файл существует. |
| T-C.2 (`solar-computed-facts.schema.json`) | `closed-in-fact` | Файл существует. |
| T-C.3 (Person/Consultation schemas + fixtures) | `closed-in-fact` + расширение | `person.schema.json`, `consultation.schema.json`, `solar-input-sample.json`, `solar-facts-sample.json` присутствуют. **Расширение** (не предусмотренное): `consultation-draft-overrides.schema.json` (Phase 0.8). Кейс «Заполярье» (T-C.3 предписал) — отдельным fixture не выделен; реальные клиентские кейсы в `golden-cases/` покрывают разные широты. |

### Block D — Services

| TASK | Статус | Evidence |
|------|--------|----------|
| T-D.1 (SQLite + Person/Consultation CRUD) | `closed-in-fact` | `db.py`, `persons.py`, `consultations.py`, `migrations/001_initial.sql`. |
| T-D.2 (bridge расширения) | `partial` | `bridge.py` + `cache.py` есть. **Отсутствуют отдельные модули** `geocoder.py`, `timezone.py`, `fixed_stars.py` (Phase 0.2 scope, ruleset-v2 deferred). |
| T-D.3 (endpoints) | `closed-in-fact` | `main.py`, `models.py` присутствуют. |
| T-D.4 (PDF templates) | `obsolete-by-evolution` | Прескрипция: одностраничный шаблон с 4 блоками. Реальность: `pdf/builder.py` + `wheel.py` + 4 `*_themes.py` модуля + Jinja2 template; SVG-колёса; closed-dictionary интерпретации; theme-grouped synthesis. См. § 4 «target § 6 divergences». |

### Block E — Frontend

| TASK | Статус | Evidence |
|------|--------|----------|
| T-E.1 (types.ts + api.ts) | `closed-in-fact` | Оба файла присутствуют. |
| T-E.2 (Person pages) | `closed-in-fact` | `PersonList.tsx`, `PersonForm.tsx`, `PersonDetails.tsx`. |
| T-E.3 (ConsultationForm + View) | `closed-in-fact` + расширение | Оба файла присутствуют. **Расширение** (Phase 0.8): `DraftEditor.tsx` + 16 компонентов под `components/draft-editor/`. |
| T-E.4 (NatalChartFacts + SolarChartFacts + AnnualTransitTable) | `partial` | `NatalChartFacts.tsx`, `SolarChartFacts.tsx` присутствуют. **`AnnualTransitTable.tsx` отсутствует** (см. § 5). |

### Block F — Integration

| TASK | Статус | Evidence |
|------|--------|----------|
| T-F.1 (run-local.sh) | `closed-in-fact` | `run-local.sh` присутствует на root. |
| T-F.2 (golden tests против Zet9) | `closed-in-fact` + расширение | Прескрипция: ≥ 3 кейса. Реальность: **9 пар** golden-cases (`01-kseniya` … `10-danila`) + `06-incomplete.stub.json`. |
| T-F.3 (smoke test + PHASE_0_DEMO.md) | `closed-in-fact` (partial) | `docs/PHASE_0_DEMO.md` существует; recon не запускал demo. |
| T-F.4 (active overlay set + bump maturity) | `not-started` (намеренно) | `.overlay-maturity` остаётся `pre-phase0`; `CURRENT_STATE.md` etc. отсутствуют. Это соответствует TL-decision не bump'ать до Architecture drift reconciliation. |

### Сводка

- **closed-in-fact:** 21 пункт.
- **partial:** 6 пунктов (T-A.4, T-B.1, T-B.8, T-C.3, T-D.2, T-E.4, T-F.3).
- **not-started (намеренно отложено в Phase 0.2):** T-B.3, T-B.4.
- **not-started (намеренно отложено TL):** T-F.4.
- **obsolete-by-evolution:** T-B.6, T-D.4.

---

## 4. Где `target-architecture.md` расходится с реальным продуктом

Walk по секциям target. Каждый divergence — короткая цитата (≤ 15 слов) + evidence-pointer.

### 4.1 § 1-2 (Треугольник + слои) — **aligned**

Слои `Core / Services / Frontend` соблюдены: Haskell не хранит Person/Consultation как entity, Python не считает aspects/houses, Frontend не считает.

### 4.2 § 3.2 (Planet ADT расширение) — **divergent (deferred)**

Цитата target § 3.2: `«Planet … FixedStar FixedStarId — параметризованный конструктор»`.
Evidence: `git show 4937c00:core/astrology-hs/src/Domain/Types.hs` показывает `data Planet = Sun | … | Pluto` без `NorthNode`, `SouthNode`, `Lilith`, `Chiron`, `FixedStar`. Соответствует Phase 0.2 scope (ruleset-v2 явно `deferred_to_phase_0_2`).

### 4.3 § 5.1 (Services структура) — **divergent (extension)**

Цитата target § 5.1: «`pdf/builder.py` + `pdf/templates/solar.html.j2`».
Evidence: реальный `pdf/` содержит 6 файлов (`builder.py`, `wheel.py`, `direction_themes.py`, `house_pair_themes.py`, `transit_themes.py`, `synthesis_themes.py`) + template. Расширение под Phase 0.5–0.10b.

### 4.4 § 5.1 (Services отсутствие) — **divergent (missing)**

Цитата target § 5.1: «`ephemeris/{bridge,geocoder,timezone,fixed_stars,cache}.py`».
Evidence: реальный `ephemeris/` содержит только `bridge.py` + `cache.py` + `__init__.py`. `geocoder.py`, `timezone.py`, `fixed_stars.py` отсутствуют (Phase 0.2 deferred).

### 4.5 § 5.2 (Storage model) — **divergent (extension)**

Цитата target § 5.2: «`InterpretationRule, Draft, Artifact — отсутствуют в Phase 0`».
Evidence: миграция `002_draft_overrides.sql` header: `«Phase 0.8: editable consultation drafts»`. Это эволюция за пределы прескрипции.

### 4.6 § 6 (PDF layout) — **divergent (major)**

Цитата target § 6: «**Чего НЕТ в Phase 0 PDF:** Графических карт-колёс…; Текстовых интерпретаций…; Дирекций…».
Evidence:
- Графические колёса: `services/api-python/app/pdf/wheel.py` (SVG-генерация).
- Текстовые интерпретации: `direction_themes.py`, `house_pair_themes.py`, `transit_themes.py`, `synthesis_themes.py`.
- Дирекции: `Domain/Directions.hs` + `pdf/direction_themes.py`.

Все 3 «чего НЕТ» — фактически реализованы. Это самое крупное расхождение overlay vs реальность.

### 4.7 § 7.2 (Frontend компоненты) — **divergent (mixed)**

Цитата target § 7.2: «`AnnualTransitTable (по 4 планетам, группировка по домам)`».
Evidence: компонент отсутствует в `apps/web-react/src/components/`. Функциональность вынесена в PDF-pipeline (`pdf/transit_themes.py`).

Цитата target § 7.3: «`Редактор правил интерпретации — Phase 1+`».
Evidence: `apps/web-react/src/pages/DraftEditor.tsx` + 16 компонентов в `components/draft-editor/` — Marina-style редактор поверх machine-generated skeleton (не «правил интерпретации» по target-терминологии, но по сути editorial-layer).

### 4.8 § 8.3 (Bridge type discipline) — **aligned**

Цитата target § 8.3: «`Один модуль с типами SolarResolvedInput/SolarComputedFacts`».
Evidence: `Bridge/Solar.hs` — single SOT (875 строк), explicit module header цитирует bright line #5/#6/#8. `Test/Bridge/SolarRoundtripSpec.hs` присутствует — bright line #8 enforced.

### 4.9 § 11 (Bright lines) — **mostly aligned, one boundary blur**

- #1, #2, #3, #4, #6, #7, #8 — **aligned** (нет Person в Haskell, нет PDF в Haskell, нет HTTP в Haskell, нет UI в Haskell, single snapshot, Python не дублирует math, Schema gate с roundtrip-test).
- #5 «Core не знает про Consultation как workflow» — **boundary blur**. Evidence: `src/Domain/ConsultationSkeleton.hs` exports `ConsultationOpening`, `ConsultationSkeleton`, `KeyPeriodEntry`. Module header: `«Phase 0.7. Aggregation layer that takes already-computed analysis blocks … and produces a STRUCTURED draft of the written consultation»`. Underlying types оперируют facts (нет Person/Consultation entity), но **именование** прямо нарушает invariant. Это NAMING-LEVEL drift — глубинный invariant (operational data в Core) не нарушен.

### 4.10 § 12 (Open questions) — **out of scope**

Pre-Phase 1 пункты, не оцениваются.

---

## 5. Conscious deviations vs real drift

Для каждого пункта divergence — корзина и обоснование (≤ 1 предложения).

### 5.1 Conscious deviations (bizdev-evolution, требуют **фиксации** в overlay)

| Пункт | Корзина | Обоснование |
|------|---------|-------------|
| § 4.6 PDF layout — графические колёса (`pdf/wheel.py`) | Conscious | Прямой запрос Марины: SVG-колесо нужно как визуальный референс при письме консультации; § 6 prescribed «без графики» написан до этого требования. |
| § 4.6 PDF layout — closed-dictionary текстовые интерпретации (`direction_themes`, `house_pair_themes`, `transit_themes`, `synthesis_themes`) | Conscious | Не «interpretation rules engine» (которого избегал target), а closed-dictionary template — phrases как часть контента, не правила; serves Marina's writing pipeline. |
| § 4.6 PDF layout — дирекции (`Domain/Directions.hs` + `pdf/direction_themes.py`) | Conscious | Обнаружилось при работе над solar reports что direction-формулы критичны для Marina's narrative; § 6 «Дирекций — Phase 1» написан до этого открытия. |
| § 4.5 Storage — `Draft` overrides (миграция 002) | Conscious | UX-итерация Marina: machine-generated skeleton хорош на 70%, нужен editor для правок; storage-разделение «facts immutable / overrides mutable» соответствует bright line #1. |
| § 4.7 Frontend — `DraftEditor` + `components/draft-editor/*` | Conscious | Парный с `Draft` overrides пункт; UI-проявление того же editorial-layer. |
| § 4.4 Services — `geocoder.py`/`timezone.py`/`fixed_stars.py` отсутствуют | Conscious | Phase 0.2 scope, ruleset-v2 явно `deferred_to_phase_0_2`. |
| § 4.2 Planet ADT — нет Lilith/Chiron/Nodes/FixedStar | Conscious | Тот же Phase 0.2 deferral; ruleset-v2 explicit. |
| § 4.7 Frontend — `AnnualTransitTable.tsx` отсутствует | Conscious | Заменён PDF-only выдачей через `transit_themes.py` (UI-таблица проиграла PDF-нарративу как формат для Marina). |
| § 4.5 Расширение — `consultation-draft-overrides.schema.json` | Conscious | Парный к миграции 002 + DraftEditor — необходимый contract для UI ↔ DB. |

### 5.2 Real drift (без bizdev-обоснования, дисциплинарный)

| Пункт | Корзина | Обоснование |
|------|---------|-------------|
| § 4.9 Bright line #5 boundary blur (`ConsultationSkeleton.hs`, тип `ConsultationSkeleton`) | Real drift | Naming-level violation: тип в `Domain.*` назван `Consultation*`. Альтернативное имя (`SolarReportSkeleton` / `WrittenReportSkeleton`) было бы compliant. Глубинный invariant (no operational data in Core) не нарушен — но именование — прямой блокер инварианта в формулировке. |
| § 3 T-B.8 — `Test.Golden` не переименован в `Test.GoldenSolar` | Real drift | Mini-discipline gap; `Test/Golden.hs` существует под старым именем + параллельный `Test/Golden/SolarSpec.hs`. Не критично, но указывает на пропущенный шаг T-B.8. |

### 5.3 Объяснение почему обе корзины непустые

Обе корзины непустые. § 5.1 содержит 9 пунктов («что развилось правильно, но overlay не зафиксирован»); § 5.2 содержит 2 пункта («что развилось без необходимости»). Соотношение ≈ 5:1 в пользу conscious, что разумно: продуктовая эволюция под прямые запросы пользователя — норма для pre-Phase 1; жёсткий drift — minimal.

---

## 6. Какой следующий product TASK безопасно делать первым

**Рекомендация (одно предложение):** Создать docs-only TASK `phase0-status-annotations` (Tier C, ≤ 100 строк markdown) — пройти `PHASE_0_TASKS.md` блоками A–F и в каждой `### T-X.Y` добавить одну строчку-аннотацию в формате `**Status @ astro:4937c00:** closed-in-fact | partial | not-started (Phase 0.2) | obsolete-by-evolution (Phase 0.5–0.10b — see architecture-drift-recon.md § 3)` со ссылкой на этот recon-документ; **не** менять Scope / Acceptance / Checks / зависимости задач.

Почему этот TASK удовлетворяет 4 критериям:
1. **docs-only / ≤ 30 строк product-code patch:** 0 строк product code, ~60 строк markdown в overlay.
2. **не bumps maturity:** не трогает `.overlay-maturity` или 4 active-set документа.
3. **не BA:** чисто evidence-based annotation, никаких бизнес-решений.
4. **ясный следующий ход TL:** после accept'а — TL имеет map по PHASE_0_TASKS «что есть / чего нет», и оба следующих больших шага (либо обновление `target-architecture.md § 6`, либо явная фиксация conscious deviations в `astro/.claude/corrections.md`) становятся осмысленным выбором, а не догадками.

Что **не** входит в этот следующий TASK (намеренно):
- Обновление `target-architecture.md § 6` — не Tier C.
- Запись Correction 011 в `astro/.claude/corrections.md` про bright line #5 boundary blur — требует прохода через product repo (TL должен дать отдельный go).
- Переименование `ConsultationSkeleton.hs` / `Test.Golden` → `Test.GoldenSolar` — product code change.
- Создание `CURRENT_STATE.md` etc. — Phase 0.2 / T-F.4.

---

## 7. Evidence appendix

Все команды воспроизводимы на `astro:4937c00`. Каждая — с фрагментом реального вывода (≤ 5 строк).

### 7.1 Baseline и общий счёт

```
$ git -C /Users/ilya/Projects/astro rev-parse HEAD
4937c0065054f627e92f59b1e7bf8b29c3c4d7f2

$ git -C /Users/ilya/Projects/astro ls-tree -r 4937c00 | wc -l
161
```

### 7.2 Domain inventory

```
$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- core/astrology-hs/src/Domain/
[20 entries: Ascendant.hs, Aspects.hs, ConsultationSkeleton.hs, Dignities.hs,
 Directions.hs, HouseAxisAnalysis.hs, Houses (tree), ImportantTransitPlanets.hs,
 KingOfAspects.hs, Planets.hs, PriorityWindows.hs, Progressions.hs,
 SolarReturn.hs, Stellium.hs, StrengthAnalysis.hs, TransitCalendar.hs,
 Transits.hs, Types.hs, WeaknessAnalysis.hs, Zodiac.hs]

$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- core/astrology-hs/src/Domain/Houses/
[1 entry: Placidus.hs]   # NB: Equal.hs absent
```

### 7.3 Bridge-SOT verification

```
$ git -C /Users/ilya/Projects/astro show 4937c00:core/astrology-hs/src/Bridge/Solar.hs | wc -l
875

$ git -C /Users/ilya/Projects/astro show 4937c00:core/astrology-hs/src/Bridge/Solar.hs | head -20
{-# LANGUAGE OverloadedStrings #-}
-- | Bridge layer for the @solar@ workflow — single source of truth for the
--   wire-format types crossing the Python ↔ Haskell process boundary.
[…]
```

### 7.4 Planet ADT scope

```
$ git -C /Users/ilya/Projects/astro show 4937c00:core/astrology-hs/src/Domain/Types.hs | grep -A 4 'data Planet'
data Planet
  = Sun | Moon | Mercury | Venus | Mars
  | Jupiter | Saturn | Uranus | Neptune | Pluto
  deriving (Eq, Ord, Show, Enum, Bounded, Generic, ToJSON, FromJSON)
```

### 7.5 ConsultationSkeleton — bright line #5 evidence

```
$ git -C /Users/ilya/Projects/astro show 4937c00:core/astrology-hs/src/Domain/ConsultationSkeleton.hs | head -4
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
-- | Consultation skeleton — Phase 0.7.

$ git -C /Users/ilya/Projects/astro show 4937c00:core/astrology-hs/src/Domain/ConsultationSkeleton.hs | grep -E '^(data |newtype )'
data ConsultationOpening = ConsultationOpening
data KeyFactor = KeyFactor
data KeyPeriodEntry = KeyPeriodEntry
data ConsultationSkeleton = ConsultationSkeleton
```

### 7.6 PDF interpretation modules

```
$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- services/api-python/app/pdf/
[8 entries: __init__.py, builder.py, direction_themes.py, house_pair_themes.py,
 synthesis_themes.py, templates (tree), transit_themes.py, wheel.py]
```

### 7.7 Frontend draft-editor

```
$ git -C /Users/ilya/Projects/astro ls-tree -r 4937c00 -- apps/web-react/src/components/ | wc -l
18                                # 2 facts components + 16 draft-editor

$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- apps/web-react/src/pages/
[6 entries: ConsultationForm.tsx, ConsultationView.tsx, DraftEditor.tsx,
 PersonDetails.tsx, PersonForm.tsx, PersonList.tsx]
```

### 7.8 Cleanup verification (T-A.2 deletions)

```
$ git -C /Users/ilya/Projects/astro ls-tree -r 4937c00 -- services/orchestrator-python/ | wc -l
0

$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- core/astrology-hs/src/Adapters/Ephemeris/Swiss.hs
                                                # empty stdout — file deleted

$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- core/astrology-hs/src/Domain/Report.hs
                                                # empty stdout — file deleted
```

### 7.9 Ruleset v2 deferred-list

```
$ git -C /Users/ilya/Projects/astro show 4937c00:packages/rulesets/ruleset-v2.0.0.json | head -16
{
  "version": "2.0.0",
  "phase": "0.1 base; 0.2 extends with Nodes/Lilith/Chiron/FixedStars/EqualFromAsc/Daragan-orbs",
  […]
  "planets": {
    "used": ["Sun", "Moon", "Mercury", "Venus", "Mars",
             "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"],
    "deferred_to_phase_0_2": ["NorthNode", "SouthNode", "Lilith", "Chiron",
                              "FixedStars (top-30)"]
  },
```

### 7.10 Golden cases count

```
$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- packages/test-fixtures/golden-cases/ | grep -c '\.input\.json$'
9                                 # plus 06-incomplete-2025-2026.stub.json

$ git -C /Users/ilya/Projects/astro ls-tree 4937c00 -- packages/test-fixtures/golden-cases/ | wc -l
21                                # 9 input + 9 expected + 1 stub + _generate.py + _compare_directions.py
```

---

## 8. Summary

- 21 prescribed TASK закрыт фактически; 6 partial; 2 целевых deferral в Phase 0.2; 1 deferral по TL-decision; 2 obsolete-by-evolution.
- 9 conscious deviations (PDF/Draft/Direction features) ждут либо фиксации в `target-architecture.md § 6`, либо закрепления как `corrections.md` записей.
- 2 real drift (Bright line #5 boundary blur через `ConsultationSkeleton.hs`; `Test.Golden` без переименования) — требуют отдельных мелких TASK.
- Безопасный следующий шаг: docs-only TASK `phase0-status-annotations` для аннотации `PHASE_0_TASKS.md` ссылками на этот recon, без правки Scope. См. § 6.
