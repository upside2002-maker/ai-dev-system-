# Phase 0 Tasks — Vertical Slice «Person → Solar → PDF»

**Дата:** 2026-04-24.
**Предпосылки:** см. `target-architecture.md`, `migration-plan.md`.
**Цель Phase 0:** рабочий локальный (dev-only на маке оператора) инструмент: создать клиента → посчитать соляр → скачать PDF.
**Для кого:** worker-агент, выполняет задачи последовательно по блокам с допустимой параллелизацией внутри блока.

---

## Phase 0 разбит на две стадии

Чтобы не задерживать первое реальное использование инструмента «правильной полнотой», Phase 0 разбит на **0.1 (Walking Skeleton)** и **0.2 (Full Phase 0)**. Worker сначала проходит все задачи `[0.1]`, останавливается, демонстрирует результат оператору; затем `[0.2]` расширяет до полной целевой картины.

| Стадия | Срок | Что делает | Чего НЕТ |
|---|---|---|---|
| **0.1 Walking Skeleton** | ~1-1.5 нед | End-to-end pipeline: Person → Solar → JSON facts → simple PDF. 10 классических планет, Placidus only. Ручной ввод lat/lon/tz без auto-geocoder. Один синтетический golden test. | Auto-geocoder, Equal houses, Nodes/Lilith/Chiron/FixedStars, годовая таблица транзитов, polar fallback, cache, Zet9 golden tests, расширенный PDF |
| **0.2 Full Phase 0** | ~2-3 нед после 0.1 | Расширение до полного DoD: Equal-from-Asc, расширенные точки, годовая таблица, фикс.звёзды, polar fallback, cache, auto-geocoder, golden tests против Zet9, полный PDF с 4 блоками | — |

### Phase 0.1 — Definition of Done

1. `./run-local.sh` поднимает full stack (Haskell CLI + Python API + React dev) одной командой.
2. На `localhost:3000` отображается список клиентов.
3. Можно создать Person с **ручным** вводом ФИО / даты / времени / координат (lat/lon) / timezone-id (без auto-geocoder).
4. На карточке клиента можно создать Solar-консультацию (выбор года).
5. Compute синхронно возвращает facts (Placidus only, 10 классических планет, без фикс.звёзд, без Equal-cusps): натальные позиции + натальные аспекты + классификации + соляр-позиции + соляр-аспекты + соляр-классификации.
6. На странице консультации видны facts в табличном виде.
7. Кнопка «Скачать PDF» — простой PDF (натал-таблица + соляр-таблица + список аспектов в одной странице, без CSS-полировки).
8. `cabal test` зелёный с **базовыми** property-тестами (`asc+180=desc`, sum house spans = 360°) + 1 синтетический golden fixture (без Zet9).

### Phase 0.2 — Definition of Done (расширяет 0.1)

Всё из 0.1 + дополнительно:

1. Auto-geocoder через Nominatim + auto-resolve timezone через timezonefinder.
2. На странице фактов **два** набора домов (Placidus + Equal-from-Asc).
3. Расширенный domain в core: NorthNode/SouthNode/Lilith/Chiron + топ-30 фикс.звёзд (precession в core).
4. Годовая таблица транзитов Mars/Venus/Saturn/Jupiter по домам натала с hits (4-й блок PDF).
5. Polar fallback: при `|latitude| > 66.5°` Placidus → Equal без ошибки, с явной пометкой в facts.
6. Cache `charts_cache`: повторный расчёт того же Person+year < 0.5 сек.
7. Расширенный PDF: 4 блока согласно `target-architecture.md § 6` (натал, соляр, годовая таблица, footer), CSS под печать A4, русские шрифты.
8. Golden tests против Zet9: ≥ 3 реальных клиента Марины, расхождения в пределах допуска (longitude ≤ 0.01°, JD ≤ 0.001).
9. Дараган-orbs контракт (`packages/rulesets/daragan-orbs-v1.json`): инфраструктура готова к замене значений; в файле — placeholder + TODO для оператора.

---

## Демо-сценарии

### Phase 0.1 demo (минимум)

```
$ cd /Users/ilya/Projects/astro
$ ./run-local.sh
# Browser → http://localhost:3000

# В UI:
# 1. [+ Новый клиент] — заполнить вручную: ФИО, дата, время, координаты, tz-id
# 2. [+ Соляр] → 2026
# 3. Ждём 3-5 сек → видим facts (Placidus, 10 планет, аспекты, классификации)
# 4. [Скачать PDF] → файл с базовой версткой
```

Цель 0.1 demo: убедиться что pipeline сшит end-to-end. Качество вёрстки и полнота домена — задача 0.2.

### Phase 0.2 demo (полный)

```
$ ./run-local.sh

# В UI:
# 1. [+ Новый клиент] → заполнить: «Тестовая Клиентка, 1985-06-15, 14:30, Москва»
# 2. Геокодинг автоматически показывает lat/lon/tz
# 3. [+ Соляр] → год 2026 → тема «карьера»
# 4. Ждём 3-5 сек → открывается страница фактов
# 5. Видим: натал (2 системы домов, Nodes/Lilith/Chiron, фикс.звёзды), соляр, годовая таблица
# 6. [Скачать PDF] → 4-блочный отчёт, аккуратная вёрстка
# 7. Повтор того же расчёта — < 0.5 сек (cache hit)
# 8. Создать клиента «Заполярье, lat=68» — Placidus auto-fallback на Equal, без ошибки
```

---

## Инварианты задач

- Каждая задача указывает **Phase** (0.1 / 0.2 / 0.1+0.2), **Слой**, **Файлы**, **Задача**, **Не трогать**, **Проверка**, **Зависит от**.
- «Не трогать» обычно = файлы других слоёв + bright lines из `architecture-invariants.md`.
- «Проверка» — конкретная команда (cabal build, pytest, tsc, jsonschema validate, curl).
- Перед выполнением worker читает `architecture-invariants.md` + `.claude/corrections.md`.

---

## Phase Distribution — список задач по фазам

Каждая задача в блоках A-F ниже выполняется в указанной фазе. Worker сначала проходит **все** `[0.1]` задачи, демонстрирует Phase 0.1 demo, потом приступает к `[0.2]`.

### Phase 0.1 — Walking Skeleton (минимальный путь)

**Block A (cleanup) — все в 0.1:**
- T-A.1 [0.1] — убрать build-артефакты.
- T-A.2 [0.1] — удалить мёртвые модули.
- T-A.3 [0.1] — architecture-invariants + corrections в `.claude/`.
- T-A.4 [0.1] — пометить устаревшие docs.
- T-A.5 [0.1] — схлопнуть ephemeris-python + pdf-python.
- T-A.6 [0.1+0.2] — ruleset-v2 базовый в 0.1 (10 классических планет, Placidus, классические orbs); Daragan-orbs config + расширенный планет в 0.2.

**Block B (core):**
- T-B.1 [0.1+0.2] — newtypes + HouseSystem ADT + OrbProfile + рефакторинг Domain.Types в 0.1; расширение `Planet` до Nodes/Lilith/Chiron/FixedStar в 0.2.
- T-B.2 [0.1] — параметризация `Domain.Aspects` через `OrbProfile`.
- T-B.3 [0.2] — `Domain.Houses.Equal`.
- T-B.4 [0.2] — `Domain.FixedStars` + precession.
- T-B.5 [0.1] — `Domain.SolarReturn`.
- T-B.6 [0.2] — `Domain.TransitTable` (годовая).
- T-B.7 [0.1+0.2] — `Bridge.Solar` диспетчер: в 0.1 minimal scope (Placidus, 10 планет, без таблицы транзитов); в 0.2 — полный.
- T-B.8 [0.1+0.2] — property tests + golden infrastructure в 0.1 (1 синтетический fixture, базовые инварианты); расширенный набор + Zet9 в 0.2 (см. T-F.2).

**Block C (contracts):**
- T-C.1 [0.1+0.2] — `solar-resolved-input.schema.json`: minimal в 0.1 (Placidus, 10 планет); расширение в 0.2.
- T-C.2 [0.1+0.2] — `solar-computed-facts.schema.json`: minimal в 0.1; расширение в 0.2.
- T-C.3 [0.1+0.2] — Person/Consultation схемы + fixtures в 0.1 (средний кейс); кейс Заполярья — в 0.2.

**Block D (services):**
- T-D.1 [0.1] — SQLite + Person/Consultation CRUD.
- T-D.2 [0.1+0.2] — bridge: 0.1 minimal (10 планет, Placidus, без auto-geocoder, без fixed_stars, без cache); 0.2 — расширения (Nodes/Lilith/Chiron, Equal, fixed_stars, auto-geocoder, polar fallback, cache).
- T-D.3 [0.1+0.2] — endpoints: minimal CRUD + compute в 0.1; cache logic + расширенные facts в 0.2.
- T-D.4 [0.1+0.2] — PDF: simple в 0.1 (одностраничный, base64 шрифты, минимум вёрстки); полный 4-блочный с CSS A4 в 0.2.

**Block E (frontend):**
- T-E.1 [0.1+0.2] — types.ts + api.ts: minimal в 0.1; расширение в 0.2.
- T-E.2 [0.1] — Person pages.
- T-E.3 [0.1] — Consultation form + view.
- T-E.4 [0.1+0.2] — `NatalChartFacts` + `SolarChartFacts` в 0.1 (без Equal-колонки, без fixed_stars-секции); расширение + `AnnualTransitTable` в 0.2.

**Block F (integration):**
- T-F.1 [0.1+0.2] — run-local.sh: базовый в 0.1, полировка в 0.2.
- T-F.2 [0.2] — golden tests против Zet9 (требует выгрузку у Марины).
- T-F.3 [0.1+0.2] — smoke test: Phase 0.1 demo в 0.1; Phase 0.2 demo в 0.2.
- T-F.4 [0.2] — CURRENT_STATE / KNOWN_ISSUES / NEXT_ACTIONS / PROJECT_MAP в overlay + bump `.overlay-maturity` в `active`.

### Gate между 0.1 и 0.2

После завершения всех `[0.1]` задач — **остановка**. Worker рапортует оператору:
- Phase 0.1 demo проходит.
- `cabal test` зелёный (базовые property + 1 synthetic golden).
- Список того, что заведомо отсутствует в 0.1 (см. таблицу выше).
- Замеры: время compute, размер facts JSON, время первого PDF.

Оператор + Марина смотрят результат, решают: продолжать на 0.2 или сначала корректировать что-то в 0.1. **Это синхронизация перед инвестицией следующих 2-3 недель.**

---

## Замечание по задачам с пометкой [0.1+0.2]

Некоторые задачи делаются в две итерации: в 0.1 — minimal scope, в 0.2 — расширение. Это сознательный компромисс между «не переписывать одно и то же дважды» (за: одна задача = один файл) и «не блокировать 0.1 на полном scope» (против: расширение в одной задаче размывает инкремент).

Правило: в 0.1 пишем код **с учётом будущего расширения** (типы и сигнатуры функций уже под полный scope, но реализация заглушена / упрощена). Например:
- `Bridge.Solar.SolarResolvedInput` сразу содержит поле `fixed_stars_catalog: [FixedStarCatalogEntry]`, но в 0.1 Python шлёт пустой список и Haskell его игнорирует.
- `Domain.Aspects` сразу принимает `OrbConfig`, но в 0.1 OrbConfig инициализируется классическими 6/8 а не Дараган.
- `HouseCusps` сразу содержит поле `hcSystem :: HouseSystem`, но в 0.1 всегда `Placidus`.

Это **минимизирует rework** в 0.2: добавление функциональности, не правка контрактов.

---

## Блок A — Cleanup и подготовка

### T-A.1 — Убрать build-артефакты из git

**Слой:** infra
**Файлы:** `/Users/ilya/Projects/astro/core/astrology-hs/dist-newstyle/`, `/Users/ilya/Projects/astro/.gitignore`
**Задача:**
- Удалить `dist-newstyle/` из репозитория (файлы + директории).
- Добавить в `.gitignore`: `dist-newstyle/`, `**/__pycache__/`, `*.pyc`, `node_modules/`, `/data/`, `*.se1`.
- `git status` после должен быть чистым, затронуты только `.gitignore`.

**Не трогать:** любой source code.
**Проверка:** `ls core/astrology-hs/dist-newstyle/` → не существует; `git status -s` → `M .gitignore` (если был) или `A .gitignore`.

### T-A.2 — Удалить мёртвые модули и сервисы

**Слой:** cleanup
**Файлы:**
- `/Users/ilya/Projects/astro/services/orchestrator-python/` (удалить целиком)
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Adapters/Ephemeris/Swiss.hs`
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/Report.hs`
- `/Users/ilya/Projects/astro/packages/contracts/core-input.schema.json`
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal` (убрать строки `Adapters.Ephemeris.Swiss`, `Domain.Report` из `exposed-modules`)

**Задача:** удалить указанные файлы/директории, обновить cabal-файл.
**Не трогать:** всё что не перечислено.
**Проверка:** `cabal build` в `core/astrology-hs/` компилируется без этих модулей.

### T-A.3 — Создать architecture-invariants + corrections в astro-репозитории

**Слой:** docs
**Файлы:**
- `/Users/ilya/Projects/astro/.claude/architecture-invariants.md` (новый)
- `/Users/ilya/Projects/astro/.claude/corrections.md` (новый)
- `/Users/ilya/Projects/astro/CLAUDE.md` (новый, краткие правила слоя)

**Задача:**
- `architecture-invariants.md` — скопировать **все 8 bright lines** из `target-architecture.md § 11` (включая #8 «Schema change gate» — это ключевое правило против type drift) с пометкой «источник истины — `ai-dev-system/project-overlays/astro/ARCHITECTURE/target-architecture.md`». Если в target позже появятся #9, #10 — переносить тоже.
- `corrections.md` — шапка + 4 начальных записи:
  - «Не дублировать типы между `Domain.Types` и `app/Main.hs` (прецедент в mini-MVP, handoff)».
  - «Не catch-all patterns в sum-type match кроме явного invalid-transition».
  - «Не impl'ить operational data в Core (Person, Consultation, Draft, Artifact)».
  - «Не дублировать math в Python: aspects, houses, classifications, orb-application — только Haskell».
- `CLAUDE.md` — выжимка для worker-агента: «читай `.claude/architecture-invariants.md` и `.claude/corrections.md` до правки любого слоя; tech-lead posture + границы слоёв; ссылки на target-architecture.md и PHASE_0_TASKS.md в overlay».

**Не трогать:** остальные файлы.
**Проверка:** файлы существуют, markdown валиден.

### T-A.4 — Пометить устаревшие docs

**Слой:** docs
**Файлы:**
- `/Users/ilya/Projects/astro/docs/architecture/adr-0001-python-ephemeris-bridge.md`
- `/Users/ilya/Projects/astro/docs/agents/current-state-handoff.md`

**Задача:** добавить в начало каждого файла блок:
```
---
status: Superseded | Archived
superseded_by: /Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/target-architecture.md
archived_at: 2026-04-24
note: содержимое сохранено для контекста; действующая архитектура — в overlay.
---
```

**Не трогать:** содержимое оригинальных документов.
**Проверка:** markdown-шапка присутствует.

### T-A.5 — Схлопнуть services/ephemeris-python + pdf-python

**Слой:** services
**Файлы:**
- `/Users/ilya/Projects/astro/services/ephemeris-python/` → перенести `ephemeris_loader/loader.py` в `/Users/ilya/Projects/astro/services/api-python/app/ephemeris/cache.py`, удалить директорию.
- `/Users/ilya/Projects/astro/services/pdf-python/` → перенести `pdf_builder/builder.py` в `/Users/ilya/Projects/astro/services/api-python/app/pdf/builder.py` + шаблон в `/Users/ilya/Projects/astro/services/api-python/app/pdf/templates/`, удалить директорию.
- Обновить `services/api-python/pyproject.toml`: добавить зависимости (`httpx`, `pyswisseph`, `timezonefinder`, `jinja2`, `weasyprint`), убрать sys.path-хак из `app/pdf.py`.

**Не трогать:** сам код builder'а/loader'а при переносе; FastAPI endpoints (пока).
**Проверка:** `pip install -e services/api-python && python -c "from app.pdf.builder import write_pdf_report; from app.ephemeris.cache import ensure_ephemeris_files"` без ошибок.

### T-A.6 — Создать ruleset-v2.0.0.json + daragan-orbs-v1.json

**Слой:** contracts/rulesets
**Файлы:**
- `/Users/ilya/Projects/astro/packages/rulesets/ruleset-v2.0.0.json` (новый)
- `/Users/ilya/Projects/astro/packages/rulesets/daragan-orbs-v1.json` (новый)

**Задача:**
- `ruleset-v2.0.0.json` — как `ruleset-v1.0.0.json`, но:
  - `planets.used_in_v2` включает `NorthNode`, `SouthNode`, `Lilith`, `Chiron`.
  - `planets.fixed_stars` — список топ-30 мажорных (см. target-architecture.md § 10.2; при неясности — использовать Regulus, Aldebaran, Antares, Spica, Sirius, Vega, Capella, Arcturus, Rigel, Betelgeuse, Procyon, Altair, Deneb, Fomalhaut, Achernar, Pollux, Castor, Algol, Mirach, Alphecca, Bellatrix, Alcyone, Menkar, Zosma, Zuben Elgenubi, Zuben Eschamali, Hamal, Nashira, Canopus, Ras Alhague).
  - `house_systems`: `["Placidus", "EqualFromAsc"]`, default `Placidus` с fallback `EqualFromAsc` при `|latitude| > 66.5°`.
  - `orb_profiles`: `["Natal", "Prognostic"]` + ссылка на `daragan-orbs-v1.json` как источник значений.
  - Остальное (domicile, detriment, exaltation, fall, t_square, combustion, cazimi, elevation) — скопировать из v1.
- `daragan-orbs-v1.json` — placeholder:
  ```json
  {
    "version": "1.0.0",
    "source": "TODO: заполнить оператором из книги К.Дарагана о транзитах",
    "natal": {
      "__placeholder__": "пока используются классические 6/8°; оператор заменит на значения Дарагана",
      "Conjunction": 8.0, "Sextile": 6.0, "Square": 8.0, "Trine": 8.0, "Opposition": 8.0
    },
    "prognostic": {
      "__placeholder__": "TODO: Дараган prognostic orbs",
      "Conjunction": 1.0, "Sextile": 1.0, "Square": 1.0, "Trine": 1.0, "Opposition": 1.0
    }
  }
  ```

**Не трогать:** `ruleset-v1.0.0.json` (оставить, не удалять).
**Проверка:** `python -c "import json; json.load(open('packages/rulesets/ruleset-v2.0.0.json')); json.load(open('packages/rulesets/daragan-orbs-v1.json'))"` без ошибок.

---

## Блок B — Haskell Core: extension и рефакторинг

### T-B.1 — Перенести numeric-типы в newtypes, расширить Planet ADT

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/Types.hs`

**Задача:**
- Конвертировать `Longitude`, `Latitude`, `Degrees`, `JulianDay` из type-alias в newtypes с deriving (`Eq`, `Ord`, `Show`, `Num` где оправдано, `ToJSON`, `FromJSON`). Конкретно:
  - `newtype Longitude360 = Longitude360 Double` (вместо type alias `Longitude`).
  - `newtype Latitude = Latitude Double`.
  - `newtype JulianDay = JulianDay Double`.
  - `newtype ArcSec = ArcSec Double`.
  - `newtype OrbDegrees = OrbDegrees Double`.
  - `newtype SpeedDegPerDay = SpeedDegPerDay Double`.
- Расширить `Planet`:
  ```haskell
  data Planet
    = Sun | Moon | Mercury | Venus | Mars
    | Jupiter | Saturn | Uranus | Neptune | Pluto
    | NorthNode | SouthNode
    | Lilith | Chiron
    | FixedStar Text
    deriving (Eq, Ord, Show, Generic, ToJSON, FromJSON)
  ```
  (для `FixedStar Text` — JSON как объект `{"kind": "FixedStar", "name": "Regulus"}` либо строка `"FixedStar:Regulus"`; выбрать один вариант и документировать).
- Расширить `HouseSystem`:
  ```haskell
  data HouseSystem = Placidus | EqualFromAsc
    deriving (Eq, Ord, Show, Generic, ToJSON, FromJSON)
  ```
- Добавить `OrbProfile`:
  ```haskell
  data OrbProfile = Natal | Prognostic
    deriving (Eq, Ord, Show, Generic, ToJSON, FromJSON)
  ```
- Обновить `HouseCusps` чтобы содержал `hcSystem :: HouseSystem`.
- Удалить `Domain.Types.AnalysisResult` (дублирует типы `Main.hs CoreOutput`). Bridge-типы (`SolarResolvedInput`, `SolarComputedFacts` + их `FromJSON`/`ToJSON` инстансы) живут **только** в `core/astrology-hs/src/Bridge/Solar.hs` — один модуль, без параллельных дублей в `app/Main.hs` или `Domain.*`. См. `target-architecture.md § 8.3` (двухуровневая модель SOT).

**Не трогать:** `Domain.Zodiac`, `Domain.Dignities`, `Domain.Aspects` (последующие задачи).
**Проверка:** `cabal build` зелёный с warnings on unused imports (ожидаемо — позже их исправят).

### T-B.2 — Параметризовать Domain.Aspects через OrbProfile

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/Aspects.hs`

**Задача:**
- Убрать захардкоженные orbs. Функция `findAspects` должна принимать `OrbConfig`:
  ```haskell
  data OrbConfig = OrbConfig
    { ocConjunction :: OrbDegrees
    , ocSextile     :: OrbDegrees
    , ocSquare      :: OrbDegrees
    , ocTrine       :: OrbDegrees
    , ocOpposition  :: OrbDegrees
    }
  findAspects :: OrbProfile -> OrbConfig -> [PlanetPosition] -> [Aspect]
  ```
- `Aspect` расширить полем `aspProfile :: OrbProfile`.

**Не трогать:** Domain.Dignities, Domain.StrengthAnalysis, Domain.WeaknessAnalysis (корректируются отдельно).
**Проверка:** `cabal build`; существующие тесты могут сломаться — починить минимально (поставить `OrbConfig` из классических 6/8 в тесте).
**Зависит от:** T-B.1.

### T-B.3 — Добавить Domain.Houses.Equal

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/Houses/Equal.hs` (новый)
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal` (добавить в exposed-modules)

**Задача:**
- Реализовать `computeEqualCuspsFromAsc :: Longitude360 -> HouseCusps`:
  - 12 cusps, каждый шагом 30° от Asc.
  - `mc` = 10-й cusp (упрощённо; для равнодомной формально MC не совпадает, но в практике берётся этот вариант). Уточнение у оператора/Марины, в комментарии модуля.
  - `hcSystem = EqualFromAsc`.
- Property: `sum (differences between consecutive cusps) == 360°`.

**Не трогать:** Domain.Houses.Placidus.
**Проверка:** `cabal build`; QuickCheck property проходит.
**Зависит от:** T-B.1.

### T-B.4 — Добавить Domain.FixedStars с precession

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/FixedStars.hs` (новый)
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal`

**Задача:**
- Типы:
  ```haskell
  data FixedStarCatalogEntry = FixedStarCatalogEntry
    { fsName      :: Text
    , fsEpochJd   :: JulianDay       -- каталог привязан к эпохе (обычно J2000 = 2451545.0)
    , fsRa        :: Double          -- RA на эпоху, градусы
    , fsDec       :: Double          -- Dec на эпоху, градусы
    , fsMagnitude :: Double
    }
  data FixedStarPosition = FixedStarPosition
    { fspName      :: Text
    , fspLongitude :: Longitude360   -- ecliptic longitude на запрошенную JD
    , fspLatitude  :: Latitude
    , fspMagnitude :: Double
    }
  ```
- Функция `applyPrecession :: FixedStarCatalogEntry -> JulianDay -> FixedStarPosition` — прецессия от эпохи каталога к заданному JD по стандартной модели (IAU 1976 или равностепенная упрощённая; агент выбирает, документирует допуск).
- Функция `fixedStarConjunctions :: [FixedStarPosition] -> [PlanetPosition] -> OrbDegrees -> [(Planet, Text, OrbDegrees)]` — поиск соединений.

**Не трогать:** FFI-эфемериды (этого нет в core).
**Проверка:** `cabal build`; smoke-test: Regulus на J2000 → Leo ~29°50′ ≈ 149.83°.
**Зависит от:** T-B.1.

### T-B.5 — Добавить Domain.SolarReturn (bisection по Sun-longitude)

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/SolarReturn.hs` (новый)
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal`

**Задача:**
- Функция:
  ```haskell
  findSolarReturnJd
    :: Longitude360                  -- natal Sun longitude
    -> JulianDay                     -- approximate year start JD
    -> JulianDay                     -- approximate year end JD
    -> [(JulianDay, Longitude360)]   -- daily samples of Sun longitude in range
    -> Maybe JulianDay
  ```
  - Находит пару последовательных samples, между которыми Sun пересекает natal value.
  - Bisection между ними до точности ≤ 1 минута времени (1/(24·60) JD).
  - Возвращает `Nothing` если не нашёл (input некорректный).
- Handle wrap-around через 360→0.

**Не трогать:** direct FFI к ephemeris — Haskell получает samples от Python.
**Проверка:** `cabal test`; unit-тест на моковых samples: дать sinusoidal-подобный Sun в течение 400 дней, проверить что bisection сходится в известную точку.
**Зависит от:** T-B.1.

### T-B.6 — Добавить Domain.TransitTable

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/TransitTable.hs` (новый)
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal`

**Задача:**
- Типы:
  ```haskell
  data AnnualTransitEntry = AnnualTransitEntry
    { ateTransitingPlanet :: Planet
    , ateNatalHouse       :: Int                  -- 1..12
    , ateEnterJd          :: JulianDay
    , ateExitJd           :: JulianDay
    , ateHits             :: [TransitHit]         -- аспекты к натальным объектам
    }
  ```
- Функция:
  ```haskell
  computeAnnualTable
    :: NatalChart
    -> HouseSystem                               -- используем Placidus (для Заполярья — Equal)
    -> (JulianDay, JulianDay)                    -- period
    -> [(Planet, [(JulianDay, Longitude360, SpeedDegPerDay)])]  -- daily samples по Mars/Venus/Saturn/Jupiter
    -> OrbConfig                                  -- Prognostic профиль
    -> [AnnualTransitEntry]
  ```
- Логика: по каждой транзит.планете — идти по samples, определять вход/выход из дома натала (через `assignHouse`), на каждом domainInterval искать hits к натальным позициям.

**Не трогать:** Domain.Transits (старый transit-to-asc — оставить на Phase 0 как альтернативный путь; удалить в Phase 1 если не используется).
**Проверка:** `cabal build`; unit-тест на минимальных samples.
**Зависит от:** T-B.1, T-B.2.

### T-B.7 — Переписать Main.hs как диспетчер workflow

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/app/Main.hs`
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Bridge/Solar.hs` (**новый, обязательный** — единственный источник bridge-типов; см. target § 8.3)
- `/Users/ilya/Projects/astro/core/astrology-hs/astrology-core.cabal` (добавить `Bridge.Solar` в `exposed-modules`)

**Задача:**
- Убрать весь захардкоженный транзит-to-asc pipeline.
- Парсер `workflow` поля из input.
- Dispatch:
  - `"solar"` → `Bridge.Solar.runSolar :: SolarResolvedInput -> SolarComputedFacts`.
  - Всё остальное → error «unknown workflow».
- `Bridge.Solar` содержит только FromJSON/ToJSON для input/output + вызов core-функций.
- Output ОДИН — `SolarComputedFacts` (никаких параллельных `AnalysisResult`).

**Не трогать:** все Domain модули.
**Проверка:** `cabal build`; smoke-test — запустить бинарник с sample input из `packages/test-fixtures/` (должен быть подготовлен в блоке C).
**Зависит от:** T-B.1..T-B.6.

### T-B.8 — Property tests + golden test infrastructure

**Слой:** core
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/test/Test/Domain/InvariantsSpec.hs` (новый)
- `/Users/ilya/Projects/astro/core/astrology-hs/test/Test/GoldenSolar.hs` (переименовать `Test.Golden`)
- `/Users/ilya/Projects/astro/core/astrology-hs/test/golden/` (директория для fixtures)

**Задача:**
- Property tests:
  - `∀ asc. desc(asc) == (asc + 180) mod 360`.
  - `∀ orb ≥ 0, aspectType. Orb <= maxOrbFor aspectType → aspect detected`.
  - `∀ HouseCusps. length cusps == 12`.
  - `∀ birth. assignHouse cusps lon ∈ [1..12]`.
- Golden test framework:
  - Читает `.json` input + expected `.json` output из `test/golden/`.
  - Запускает `runSolar`, сравнивает с tolerance (для JD — ≤ 0.001 = ~1.5 мин, для longitude — ≤ 0.01°).
  - В Phase 0 — 1 fixture (синтетический средний кейс). Реальные клиенты Марины добавляются в T-F.2.
- `Spec.hs` обновить.

**Не трогать:** существующие unit-тесты (пусть пока сломаны, исправляются в рамках B.1-B.6).
**Проверка:** `cabal test`.
**Зависит от:** T-B.7.

---

## Блок C — Contracts v2

### T-C.1 — Написать solar-resolved-input.schema.json

**Слой:** contracts
**Файлы:**
- `/Users/ilya/Projects/astro/packages/contracts/solar-resolved-input.schema.json` (новый)

**Задача:**
- JSON-Schema (draft 2020-12) для snapshot-input соляра. Структура — см. `target-architecture.md § 4.3`.
- Required полей: `workflow`, `birth`, `solar_year`, `natal_positions`, `solar_positions`, `transit_samples`, `fixed_stars_catalog`, `options`, `meta`.
- Валидация enum-значений (`house_systems`, `planet` в позициях, `orb_profile`).

**Не трогать:** старый `core-resolved-input.schema.json` (удалить только после T-C.3).
**Проверка:** `python -c "import json, jsonschema; s = json.load(open(...)); jsonschema.Draft202012Validator.check_schema(s)"`.

### T-C.2 — Написать solar-computed-facts.schema.json

**Слой:** contracts
**Файлы:**
- `/Users/ilya/Projects/astro/packages/contracts/solar-computed-facts.schema.json` (новый)

**Задача:** JSON-Schema для output соляра. Структура — см. `target-architecture.md § 4.3`.
**Проверка:** как в T-C.1.

### T-C.3 — Написать person/consultation schemas + обновить test-fixtures

**Слой:** contracts
**Файлы:**
- `/Users/ilya/Projects/astro/packages/contracts/person.schema.json` (новый)
- `/Users/ilya/Projects/astro/packages/contracts/consultation.schema.json` (новый)
- `/Users/ilya/Projects/astro/packages/test-fixtures/solar-input-sample.json` (новый — средний кейс)
- `/Users/ilya/Projects/astro/packages/test-fixtures/solar-input-polar.json` (новый — кейс Заполярья)
- `/Users/ilya/Projects/astro/packages/test-fixtures/solar-facts-sample.json` (expected output для sample)
- Удалить `packages/contracts/analysis-request.schema.json`, `packages/contracts/analysis-result.schema.json`, `packages/test-fixtures/analysis-result.sample.json`, `packages/test-fixtures/create-analysis-request.sample.json`, `packages/test-fixtures/core-input.sample.json`, `packages/test-fixtures/core-resolved-input.sample.json`.

**Задача:**
- Person schema: `id, full_name, birth_date, birth_time, birth_place, birth_latitude, birth_longitude, birth_timezone, notes, created_at, updated_at`.
- Consultation schema: `id, person_id, type, solar_year, status, request_note, facts (оптионально), pdf_url (опционально), created_at, updated_at`.
- Fixtures под schemas — минимум валидные sample'ы.

**Проверка:** все fixtures валидируются против соответствующих schemas.
**Зависит от:** T-C.1, T-C.2.

---

## Блок D — Services (Python)

### T-D.1 — Storage: SQLite + миграции + Person/Consultation CRUD

**Слой:** services
**Файлы:**
- `/Users/ilya/Projects/astro/services/api-python/app/db.py` (новый)
- `/Users/ilya/Projects/astro/services/api-python/app/persons.py` (новый)
- `/Users/ilya/Projects/astro/services/api-python/app/consultations.py` (новый)
- `/Users/ilya/Projects/astro/services/api-python/app/migrations/001_initial.sql` (новый)

**Задача:**
- SQLite connection через `sqlite3` (стандартная библиотека; можно SQLAlchemy но это overkill для Phase 0).
- Миграции — простой runner, который применяет `*.sql` файлы в порядке.
- Таблицы `persons`, `consultations`, `charts_cache` — см. `target-architecture.md § 5.2`.
- Модули `persons.py`, `consultations.py` — чистые функции CRUD (`create_person`, `get_person`, `list_persons`, `update_person`, `delete_person`; аналогично consultations).

**Не трогать:** endpoints (T-D.3).
**Проверка:** `python -c "from app.db import init_db; init_db('./data/test.db'); ..."` создаёт файл с схемой.

### T-D.2 — Ephemeris bridge: расширение на Nodes/Lilith/Chiron + Equal houses + fixed stars

**Слой:** services
**Файлы:**
- `/Users/ilya/Projects/astro/services/api-python/app/ephemeris/bridge.py` (адаптация из `ephemeris_bridge.py`)
- `/Users/ilya/Projects/astro/services/api-python/app/ephemeris/geocoder.py` (из `geocoder.py` если есть, или новый)
- `/Users/ilya/Projects/astro/services/api-python/app/ephemeris/timezone.py` (новый)
- `/Users/ilya/Projects/astro/services/api-python/app/ephemeris/fixed_stars.py` (новый)

**Задача:**
- `bridge.py`:
  - Добавить в `_PLANET_IDS` pyswisseph ID-ы для `Lilith` (MEAN_APOG или TRUE_APOG), `Chiron` (CHIRON), `NorthNode` (MEAN_NODE или TRUE_NODE), `SouthNode` (derived: NorthNode + 180°).
  - `compute_natal_chart` возвращает **обе** системы домов — Placidus и Equal-from-Asc.
  - Edge-case `|lat| > 66.5°`: для Placidus все cusps = NaN/неопределены → fallback просто на Equal (считаем только Equal cusps, в natal_chart.house_systems.Placidus = null или отсутствует).
  - Сырые данные фикс.звёзд загружаются из `fixed_stars.py`, прецессию не применяем в Python — это делает Haskell.
- `fixed_stars.py`: hard-coded `list[FixedStarCatalogEntry]` с ~30 мажорными звёздами (J2000 RA/Dec из открытых источников, например Robson Fixed Stars or IAU catalogues; одноразово).
- `timezone.py`: вынести `resolve_birth_utc` и `utc_offset_str` из bridge.

**Не трогать:** core_client.py (меняется мало, в T-D.3).
**Проверка:** `python -c "from app.ephemeris.bridge import compute_natal_chart; ..."` — натал для Москвы 1985-06-15 14:30 возвращает валидные Nodes/Lilith/Chiron + обе системы домов.

### T-D.3 — Переписать main.py: новые endpoints

**Слой:** services
**Файлы:**
- `/Users/ilya/Projects/astro/services/api-python/app/main.py`
- `/Users/ilya/Projects/astro/services/api-python/app/models.py`

**Задача:**
- `models.py`: pydantic под новые DTO из `packages/contracts/person.schema.json`, `consultation.schema.json`, `solar-computed-facts.schema.json`.
- `main.py`: endpoints согласно `target-architecture.md § 5.3`.
- `POST /api/v1/consultations/{id}/compute`:
  1. Загрузить Consultation + Person из DB.
  2. Через `ephemeris.bridge.build_resolved_input()` построить solar-resolved-input snapshot.
  3. Вызов `core_client.run_solar(input)` → `SolarComputedFacts`.
  4. Сохранить `facts_json` в `consultations` таблицу, `charts_cache`.
  5. Вернуть facts клиенту.
- `GET /api/v1/consultations/{id}/pdf`: если `pdf_path` нет — сгенерировать через `pdf.builder.write_pdf_report`, сохранить путь, вернуть FileResponse.
- Contract-тесты: на каждый endpoint — проверка что response валидируется JSON-Schema.

**Не трогать:** ephemeris/, pdf/, core_client.py (напрямую, кроме минимальных правок).
**Проверка:** `uvicorn app.main:app`; `curl http://localhost:8000/api/v1/health` → 200; `curl` Person CRUD работает; `compute` возвращает facts.
**Зависит от:** T-D.1, T-D.2, T-B.7, T-C.*.

### T-D.4 — PDF template для соляра

**Слой:** services
**Файлы:**
- `/Users/ilya/Projects/astro/services/api-python/app/pdf/templates/solar.html.j2` (заменяет старый шаблон)
- `/Users/ilya/Projects/astro/services/api-python/app/pdf/builder.py` (обновление `write_pdf_report` чтобы принимал `SolarComputedFacts`)

**Задача:**
- Шаблон рендерит 4 блока из `target-architecture.md § 6`:
  1. Заголовок (ФИО, дата/время/место, год соляра).
  2. Натальная карта (таблица позиций, аспекты, фикс.звёзды, классификации).
  3. Соляр-карта (позиции, аспекты, классификации).
  4. Годовая таблица транзитов (4 подраздела Mars/Venus/Saturn/Jupiter × 12 домов).
- CSS для печати A4: margins, page-break, font, tables.
- Русские шрифты корректно рендерятся (в WeasyPrint дефолт — часто fallback; можно явно указать DejaVu Sans).

**Не трогать:** API.
**Проверка:** `python -c "from app.pdf.builder import write_pdf_report; write_pdf_report(test_facts, 'test.pdf')"` создаёт PDF, открываемый без ошибок.
**Зависит от:** T-D.3 (нужен SolarComputedFacts тип).

---

## Блок E — Frontend (React)

### T-E.1 — Переписать types.ts + api.ts под новые DTO

**Слой:** web
**Файлы:**
- `/Users/ilya/Projects/astro/apps/web-react/src/types.ts`
- `/Users/ilya/Projects/astro/apps/web-react/src/api.ts`

**Задача:**
- `types.ts`: TypeScript-типы для Person, Consultation, SolarComputedFacts (из JSON-Schema).
- `api.ts`: functions `listPersons`, `getPerson`, `createPerson`, `updatePerson`, `deletePerson`, `listConsultations`, `getConsultation`, `createConsultation`, `computeConsultation`, `downloadPdf`.

**Не трогать:** App.tsx, pages/ (другие задачи).
**Проверка:** `tsc --noEmit` чисто.

### T-E.2 — Страницы PersonList, PersonForm, PersonDetails

**Слой:** web
**Файлы:**
- `/Users/ilya/Projects/astro/apps/web-react/src/pages/PersonList.tsx` (новый, заменяет HistoryPage)
- `/Users/ilya/Projects/astro/apps/web-react/src/pages/PersonForm.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/pages/PersonDetails.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/App.tsx` (обновить routing)

**Задача:**
- `/` → `PersonList` (список клиентов, кнопка «+ Новый», поиск).
- `/persons/new` → `PersonForm` (создание, auto-geocode на сабмит).
- `/persons/:id` → `PersonDetails` (данные клиента + список его консультаций + кнопка «+ Соляр»).
- Navigation: ссылки между страницами.
- Удалить старые pages (NewAnalysisPage, AnalysisResultPage, HistoryPage).

**Не трогать:** api.ts, types.ts.
**Проверка:** `npm run build` чисто; ручной smoke test в браузере.
**Зависит от:** T-E.1.

### T-E.3 — Страницы ConsultationForm + ConsultationView

**Слой:** web
**Файлы:**
- `/Users/ilya/Projects/astro/apps/web-react/src/pages/ConsultationForm.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/pages/ConsultationView.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/App.tsx`

**Задача:**
- `/persons/:id/consultations/new` → ConsultationForm (type=solar, year picker 2020-2030, request_note textarea).
- `/consultations/:id` → ConsultationView:
  - Если `status == 'draft'` — показать кнопку «Запустить расчёт» (calls compute endpoint).
  - Если `status == 'computed'` — показать facts через компоненты NatalChartFacts, SolarChartFacts, AnnualTransitTable + кнопка «Скачать PDF».

**Не трогать:** Person pages.
**Проверка:** `npm run build`; ручной smoke test.
**Зависит от:** T-E.1, T-E.2.

### T-E.4 — Компоненты фактов: NatalChartFacts, SolarChartFacts, AnnualTransitTable

**Слой:** web
**Файлы:**
- `/Users/ilya/Projects/astro/apps/web-react/src/components/NatalChartFacts.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/components/SolarChartFacts.tsx` (новый)
- `/Users/ilya/Projects/astro/apps/web-react/src/components/AnnualTransitTable.tsx` (новый)

**Задача:**
- `NatalChartFacts`: таблица планет (Planet, Sign, Degree°Minute, House Placidus, House Equal, Retrograde); таблица аспектов; секция фикс.звёзд (планета → звезда + orb); классификации (strong/weak with reasons).
- `SolarChartFacts`: структура та же, плюс точный момент возврата.
- `AnnualTransitTable`: 4 секции (Mars, Venus, Saturn, Jupiter). В каждой — таблица: Дом натала | Вход | Выход | Аспекты (натальная планета + тип + точный момент + phase).

**Не трогать:** pages (они используют эти компоненты).
**Проверка:** `npm run build`; показать в `ConsultationView` с моковыми данными.
**Зависит от:** T-E.3.

---

## Блок F — Integration + Golden tests + полировка

### T-F.1 — Обновить run-local.sh

**Слой:** infra
**Файлы:**
- `/Users/ilya/Projects/astro/run-local.sh`

**Задача:**
- Чек наличия `./data/ephemeris/*.se1` — если нет, скачать (через `app.ephemeris.cache.ensure_ephemeris_files`).
- Чек наличия `./data/astro.db` — если нет, init (через `app.db.init_db`).
- Cabal build + uvicorn + vite — как сейчас, но с явным output «что включилось».
- Handler Ctrl+C — чистый shutdown.
- Вывести URL-ы в конце: `UI: http://localhost:3000`, `API docs: http://localhost:8000/docs`.

**Не трогать:** docker-compose.yml (остаётся для Phase 1+).
**Проверка:** `./run-local.sh` с чистой директории → поднимается full stack за ≤ 60 сек; `curl localhost:8000/api/v1/health` → 200.
**Зависит от:** все предыдущие блоки.

### T-F.2 — Golden tests против Zet9

**Слой:** core/tests
**Файлы:**
- `/Users/ilya/Projects/astro/core/astrology-hs/test/golden/` (добавить `.json` fixtures)

**Задача:**
- Оператор запрашивает у Марины Zet9-output для 3-5 реальных клиентов (в анонимизированном виде: дата рождения → позиции планет + cusps Placidus + cusps Equal + аспекты Natal-профиля).
- Для каждого — создать `.input.json` (solar-resolved-input со снимком) и `.expected.json` (solar-computed-facts как ожидаемый output).
- Golden-тест в `Test.GoldenSolar` сравнивает наш compute с expected с допуском:
  - Longitude: ≤ 0.01° (36″).
  - JD: ≤ 0.001 (~1.5 мин).
  - Aspect orb: ≤ 0.01°.
- Включать **кейс Заполярья** (её клиентка — Марина упомянула в интервью).
- Если расхождения — разбираемся: либо наш core не прав (исправляем), либо Zet9 использует другую методологию (фиксируем).

**Не трогать:** core source, только test-данные.
**Проверка:** `cabal test` зелёный; документировать известные расхождения в `test/GOLDEN_NOTES.md`.
**Зависит от:** T-F.1 (run stack должен работать).

### T-F.3 — End-to-end smoke test по демо-сценарию

**Слой:** integration
**Файлы:**
- `/Users/ilya/Projects/astro/docs/PHASE_0_DEMO.md` (новый, для оператора)

**Задача:**
- Пройти руками весь демо-сценарий из начала документа.
- Записать в `PHASE_0_DEMO.md` что получилось, что нет, сколько секунд занимает compute.
- Список bugs & regressions (если есть) — в issue tracker или в `.claude/corrections.md`.

**Не трогать:** ничего (только тестирование).
**Проверка:** PDF открывается в просмотрщике, 4 блока присутствуют, данные кажутся осмысленными (compare-sanity с Zet9 для Марининого тестового клиента).
**Зависит от:** все T-*.

### T-F.4 — Создать active-overlay набор + bump maturity

**Слой:** docs (overlay)
**Файлы:**
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/CURRENT_STATE.md` (новый)
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/KNOWN_ISSUES.md` (новый)
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/NEXT_ACTIONS.md` (новый)
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/PROJECT_MAP.md` (новый)
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/.overlay-maturity` (modify: `pre-phase0` → `active`)

**Задача:**
- `CURRENT_STATE.md`: «Phase 0 завершён 2026-MM-DD; работает demo-сценарий; SQLite on-disk; subprocess-based core». **Должен содержать строку ровно в формате** `` Snapshot commit: `abc1234` `` (короткий SHA в backticks, на отдельной строке, начинается со столбца 1 — `^Snapshot commit: \``). SHA берётся из `git -C /Users/ilya/Projects/astro rev-parse --short HEAD` на момент закрытия Phase 0. Этот формат жёстко требует `scripts/check-overlay-consistency.sh` для `maturity=active`; placeholder без backticks приведёт к падению `make check-astro-overlay` после bump'а.
- `KNOWN_ISSUES.md`: известные расхождения с Zet9, open TODO (Daragan orbs placeholder, fixed stars топ-30, etc.).
- `NEXT_ACTIONS.md`: Phase 1 backlog (дирекции, касания высших, VPS deploy, rules engine, книга).
- `PROJECT_MAP.md`: карта кода astro по слоям (core / services / web / data / apps), какие модули где живут, reading shortcuts для типовых задач (по образцу `project-overlays/sitka-office/PROJECT_MAP.md`). Это требование симметрии для всех `active`-overlays — `make check-astro-overlay` будет требовать его наличия после bump'а maturity.
- `.overlay-maturity`: заменить содержимое `pre-phase0` на `active`. После этого `make check` начнёт enforce'ить snapshot match astro CURRENT_STATE с HEAD astro repo + наличие всех 4 файлов выше.

**Не трогать:** ARCHITECTURE/ (эти файлы live-documents, не переписываются каждый phase).

**Проверка:**
- 4 markdown-файла созданы, консистентны.
- `.overlay-maturity` = `active`.
- `make -C /Users/ilya/Projects/ai-dev-system check-astro-overlay` проходит зелёным (включая snapshot match).
- `make -C /Users/ilya/Projects/ai-dev-system check` (full) проходит зелёным.

**Зависит от:** T-F.3.

---

## Оценка объёма Phase 0

- Блок A: 1-2 дня.
- Блок B: 5-8 дней.
- Блок C: 1-2 дня.
- Блок D: 5-8 дней.
- Блок E: 3-5 дней.
- Блок F: 3-5 дней.

**Итого:** 18-30 дней одним агентом последовательно. 12-20 дней с параллелизацией где возможно (B/C/D могут частично параллелиться, E и F — последовательно).

Цифры приблизительные. Фактический темп — дело первого замера через 3-4 недели (см. `migration-plan.md § 4`).

---

## Правила работы worker-агента

1. Перед каждой задачей — прочитать `astro/.claude/architecture-invariants.md` и `astro/.claude/corrections.md`.
2. Перед правкой Haskell-модуля — запустить `cabal build`, зафиксировать текущее состояние.
3. Перед правкой Python-модуля — `pip install -e .` + smoke run.
4. Перед правкой frontend — `npm install` + `npm run dev` (хоть один раз поднять).
5. После завершения задачи — «Проверка» из задачи выполнена и зелёная.
6. Если обнаружен повторяемый anti-pattern (не первый раз) — добавить запись в `astro/.claude/corrections.md`.
7. Если обнаружено что target-architecture.md нужно скорректировать — остановиться, эскалировать к architect-агенту (не менять самостоятельно).
8. Не выходить за scope Phase 0. Если хочется добавить фичу — в `NEXT_ACTIONS.md` в Phase 1 backlog.
