# Target Architecture

**Дата:** 2026-04-24.
**Автор:** Architect-агент.
**Цель:** целевая архитектура внутреннего инструмента Марины Архиповой для ускорения соляр-консультаций, с заделом на электив/дирекции/книгу/курсы (Phase 1+).
**Вход:** validated requirements из `RESEARCH/findings/CORRECTIONS_AFTER_INTERVIEW.md`, `MARINA_INTERVIEW_RESPONSES.md`, `SUMMARY.md`, `PIVOT_INTERNAL_TOOL.md`; обсуждение архитектурных решений с оператором (апрель 2026).

---

## 1. Треугольник источников истины

Система построена на трёх независимых источниках истины, каждый в своём слое. Нарушение границ — главный архитектурный риск.

| Уровень | Источник истины | Что в нём живёт | Чем **не** является |
|---|---|---|---|
| Вычислительный домен | **Haskell `core/astrology-hs`** | Доменные типы (Planet, Sign, HouseSystem, OrbProfile, TransitHit, SolarReturn, DirectionEvent); pure algorithms; инварианты расчётов | Не источник истины для API и Frontend; не хранит operational data |
| Межслойный контракт | **JSON-Schema в `packages/contracts/`** | DTO передаваемые по линии Python↔Haskell и Python↔Frontend; формат входного snapshot'а и выходных facts | Не источник истины для вычислительного домена; не хранит данные |
| Operational data + workflow | **Python services + SQLite** | Person, Consultation, Artifact, history; workflow «заявка→расчёт→черновик→PDF»; UI-state | Не считает астрологической математики; не владеет домен-типами |

**Следствие.** Расширение домена (например +Chiron): (1) в Haskell расширяется `Planet` ADT, (2) обновляется JSON-Schema snapshot'а, (3) Python-bridge начинает передавать Chiron в snapshot, (4) Frontend получает Chiron в facts и отображает. Последовательность независимая, но все три слоя обязаны согласоваться по JSON-Schema.

---

## 2. Слои ответственности

### Core — Haskell (`core/astrology-hs`)

**Владеет:**
- Astrological domain types (Planet, Sign, HouseSystem, AspectType, OrbProfile, MotionPhase, DirectionType, FixedStar).
- Numeric newtypes (Longitude360, Latitude, JulianDay, ArcSec, OrbDegrees, SpeedDegPerDay).
- Алгоритмы: аспекты с orb-профилем, дома (Placidus, Equal from Asc), соляр-возврат (bisection), классификация (strength/weakness), применение прецессии к фикс.звёздам, транзит hits + refinement, house assignment, годовая таблица транзитов по домам натала.
- Инварианты (проверяются property-tests).
- Pure functions only; IO только в `app/Main.hs` (чтение stdin + запись stdout).

**Не владеет:** FFI к pyswisseph, геокодингом, timezone-resolving (получает как данные в snapshot), storage, PDF, HTTP, UI, правилами интерпретации как текстом, Person/Consultation entities.

### Services — Python (`services/`)

**Владеет:**
- FFI: pyswisseph через `ephemeris_bridge` (натальные позиции, Nodes, Lilith, Chiron, Equal cusps).
- Геокодинг (Nominatim), timezone-resolving (zoneinfo + timezonefinder).
- Загрузка каталога фикс.звёзд (топ-30 мажорных в Phase 0) из текстового файла, передача в snapshot как сырые данные (name, RA, Dec, epoch, magnitude).
- Storage: SQLite-БД с Person, Consultation, Artifact, charts_cache.
- PDF generation: WeasyPrint + Jinja2 шаблоны (натал-карта, соляр-карта, годовая таблица транзитов, аспекты, классификации).
- HTTP API: FastAPI endpoints (CRUD Person, CRUD Consultation, Run workflow, Download PDF).
- Orchestration вызовов Haskell CLI (один крупный snapshot per workflow).
- На Phase 1+: применение `InterpretationRule` к фактам для автоматического черновика.

**Не владеет:** астрологическими расчётами (делегирует в Haskell); domain-типами (использует JSON-DTO, генерит Python-модели из Schema или пишет руками); бизнес-решениями про классификацию (это core).

### Frontend — React (`apps/web-react`)

**Владеет:**
- UI-структура вокруг workflow Марины: список клиентов → карточка клиента → создать соляр/электив → просмотр фактов → скачать PDF.
- Валидация форм ввода (дата рождения, время, место).
- Отображение фактов и аспектов в табличном/визуальном формате.
- В Phase 1+: редактор правил интерпретации (когда они станут first-class).

**Не владеет:** truth о состоянии сущностей (source — API + БД); расчётами.

---

## 3. Доменная модель Core (Haskell)

### 3.1 Numeric newtypes

```haskell
newtype Longitude360 = Longitude360 Double   -- [0, 360)
newtype Latitude     = Latitude Double       -- [-90, 90]
newtype JulianDay    = JulianDay Double
newtype ArcSec       = ArcSec Double
newtype OrbDegrees   = OrbDegrees Double     -- ≥ 0
newtype SpeedDegPerDay = SpeedDegPerDay Double
```

Защищает от смешения единиц компилятором.

### 3.2 Enum-ы (sum types)

```haskell
data Planet
  = Sun | Moon | Mercury | Venus | Mars
  | Jupiter | Saturn | Uranus | Neptune | Pluto
  | NorthNode | SouthNode
  | Lilith | Chiron
  | FixedStar FixedStarId              -- параметризованный конструктор

data ZodiacSign = Aries | Taurus | ... | Pisces

data HouseSystem = Placidus | EqualFromAsc

data AspectType = Conjunction | Sextile | Square | Trine | Opposition
                | (Phase 1+) SemiSextile | Quincunx | Sesquiquadrate | SemiSquare

data OrbProfile = Natal | Prognostic

data MotionPhase = Direct | Retrograde | DirectReturn

data ClassificationReason
  = Strong StrengthReason
  | Weak WeaknessReason
```

`Planet` — открыт для расширения через `FixedStar FixedStarId`, не требует перечислять каждую звезду в ADT. `FixedStarId` — `Text` (имя из каталога, передаваемого Python'ом в snapshot).

### 3.3 Composite types

```haskell
data PlanetPosition = PlanetPosition
  { ppPlanet       :: Planet
  , ppLongitude    :: Longitude360
  , ppLatitude     :: Latitude
  , ppSpeed        :: SpeedDegPerDay
  , ppIsRetrograde :: Bool
  }

data HouseCusps = HouseCusps
  { hcSystem    :: HouseSystem
  , hcCusps     :: [Longitude360]     -- 12 cusps
  , hcAscendant :: Longitude360
  , hcMc        :: Longitude360
  }

data NatalChart = NatalChart
  { ncBirth       :: BirthData
  , ncJulianDay   :: JulianDay
  , ncPositions   :: [PlanetPosition]
  , ncCuspsMap    :: Map HouseSystem HouseCusps    -- обе системы сразу
  , ncFixedStars  :: [FixedStarPosition]           -- уже после прецессии
  }

data Aspect = Aspect
  { aspPlanet1 :: Planet
  , aspPlanet2 :: Planet
  , aspType    :: AspectType
  , aspOrb     :: OrbDegrees
  , aspProfile :: OrbProfile     -- какой профиль орбисов применён
  }

data TransitHit = TransitHit
  { thTransitingPlanet :: Planet
  , thTargetBody       :: Planet         -- к чему аспектирует (или к asc/mc/house cusp)
  , thAspect           :: AspectType
  , thExactJd          :: JulianDay
  , thPhase            :: MotionPhase
  , thHouseOfTarget    :: Maybe Int      -- в каком доме натала объект
  }

data AnnualTransitEntry = AnnualTransitEntry
  { ateTransitingPlanet :: Planet           -- Mars/Venus/Saturn/Jupiter
  , ateNatalHouse       :: Int              -- 1..12
  , ateEnterJd          :: JulianDay
  , ateExitJd           :: JulianDay
  , ateHits             :: [TransitHit]     -- аспекты к натальным объектам за период
  }
```

### 3.4 Solar return

```haskell
data SolarReturn = SolarReturn
  { srYear            :: Int
  , srReturnJd        :: JulianDay            -- точный момент возврата Sun к natal
  , srLocation        :: GeoPoint             -- где построена карта (обычно — место на момент)
  , srPositions       :: [PlanetPosition]     -- планеты на момент возврата
  , srCusps           :: Map HouseSystem HouseCusps
  }
```

### 3.5 Classifications

Уже в коде MVP: `StrengthReason` (InDomicile, InExaltation, HasHarmoniousAspects, InElevation), `WeaknessReason` (InDetriment, InFall, AtTSquareApex, NoHarmoniousAspects, OnlyTenseAspects, IsRetrograde, IsCombust). **Оставляем как есть**, расширяем в Phase 1+ если появятся требования Марины.

### 3.6 Pure algorithms (экспортируемые функции)

```
computeAspects      :: OrbProfile → [PlanetPosition] → [Aspect]
computeHouses       :: HouseSystem → GeoPoint → JulianDay → HouseCusps
assignHouse         :: HouseCusps → Longitude360 → Int
findSolarReturn     :: BirthData → Int → EphemerisFn → SolarReturn
computeAnnualTable  :: NatalChart → DateRange → [PositionSample] → [AnnualTransitEntry]
classify            :: NatalChart → PlanetPosition → ([StrengthReason], [WeaknessReason])
applyPrecession     :: FixedStarCatalogEntry → JulianDay → FixedStarPosition
```

`EphemerisFn` — функция, которую передаёт bridge (на самом деле — pre-computed samples, Haskell итерирует по ним). В Phase 0 — просто список `PositionSample { jd, longitude, speed }` для каждой планеты.

---

## 4. Workflow snapshots — главный контракт

Это **центральный архитектурный принцип**: один workflow = один крупный snapshot in + один крупный snapshot out. Не много мелких вызовов.

### 4.1 Workflows в Phase 0

Только один: **Solar**.

### 4.2 Workflows в Phase 1+ (указаны для задела, не реализуются)

- Elective (выбор благоприятного времени для события).
- KnownPersonStudy (разбор известной личности для курса — Person без Consultation).
- BookTable (таблица/график для издательства).

### 4.3 Solar workflow contract

**Schema файлы:**
- `packages/contracts/solar-resolved-input.schema.json` — вход в core.
- `packages/contracts/solar-computed-facts.schema.json` — выход core.

**Input (упрощённо):**

```jsonc
{
  "workflow": "solar",
  "birth": {
    "birth_utc": "1990-06-15T11:30:00Z",
    "place": "Moscow, Russia",
    "latitude": 55.7558,
    "longitude": 37.6173,
    "timezone_id": "Europe/Moscow"
  },
  "solar_year": 2026,
  "natal_positions": [ /* pre-computed Python */ ],
  "solar_positions": [ /* pre-computed Python, на момент возврата Sun */ ],
  "transit_samples": {
    /* daily samples Mars/Venus/Saturn/Jupiter за период солнечного года */
    "Mars":    [{ "jd": ..., "longitude": ..., "speed": ... }, ...],
    "Venus":   [...],
    "Saturn":  [...],
    "Jupiter": [...]
  },
  "fixed_stars_catalog": [
    { "name": "Regulus",  "epoch_jd": ..., "ra": ..., "dec": ..., "magnitude": ... },
    /* ~30 мажорных */
  ],
  "options": {
    "house_systems": ["Placidus", "EqualFromAsc"],   /* обе рассчитываются */
    "orb_profile": {
      "natal":      { /* Дараган orbs из книги; placeholder в Phase 0 */ },
      "prognostic": { /* Дараган orbs для прогностики */ }
    },
    "polar_fallback": "EqualFromAsc"   /* если |lat| > 66.5°, Placidus → Equal */
  },
  "meta": {
    "ephemeris_source": "Swiss Ephemeris",
    "ruleset_version": "2.0.0"
  }
}
```

**Output (упрощённо):**

```jsonc
{
  "workflow": "solar",
  "natal_chart": {
    "positions": [...],
    "house_systems": {
      "Placidus": { "cusps": [...], "ascendant": ..., "mc": ... },
      "EqualFromAsc": { "cusps": [...], "ascendant": ..., "mc": ... }
    },
    "aspects": [...],
    "classifications": { "strong": [...], "weak": [...] },
    "fixed_star_conjunctions": [...]
  },
  "solar_chart": {
    "return_jd": ...,
    "positions": [...],
    "house_systems": { /* как выше */ },
    "aspects": [...],
    "classifications": { /* как выше */ }
  },
  "annual_transit_table": [
    {
      "transiting_planet": "Mars",
      "natal_house": 1,
      "enter_jd": ...,
      "exit_jd": ...,
      "hits": [
        {
          "target_planet": "Sun",
          "aspect": "Conjunction",
          "exact_jd": ...,
          "phase": "Direct"
        }
      ]
    },
    /* по всем 4 планетам × 12 домов */
  ],
  "meta": {
    "core_version": "2.0.0",
    "computed_at_utc": "..."
  }
}
```

**Принцип.** Один вызов `core_client.run_solar(input)` → весь пакет данных для PDF. Python не запрашивает «а теперь посчитай ещё аспекты», «а теперь дома в другой системе» — всё в одном snapshot.

---

## 5. Services layer (Python)

### 5.1 Структура

```
services/api-python/
├── app/
│   ├── main.py              FastAPI, endpoints
│   ├── models.py            Pydantic для DTO (source — packages/contracts/)
│   ├── db.py                SQLite session + миграции
│   ├── persons.py           Person CRUD
│   ├── consultations.py     Consultation CRUD + workflow runner
│   ├── ephemeris/           
│   │   ├── bridge.py        pyswisseph caller (расширен: Nodes, Lilith, Chiron)
│   │   ├── geocoder.py      Nominatim
│   │   ├── timezone.py      zoneinfo + timezonefinder
│   │   ├── fixed_stars.py   загрузка каталога топ-30 звёзд
│   │   └── cache.py         каталог .se1 (объединение с бывшим ephemeris-python)
│   ├── core_client.py       subprocess Haskell CLI
│   └── pdf/
│       ├── builder.py       WeasyPrint обвязка (перенесено из pdf-python)
│       └── templates/
│           └── solar.html.j2
└── pyproject.toml
```

`services/ephemeris-python/`, `services/orchestrator-python/`, `services/pdf-python/` **схлопываются** в `services/api-python/app/`. Одно рабочее приложение, не псевдо-микросервисы.

### 5.2 Storage model (SQLite)

```sql
CREATE TABLE persons (
  id              INTEGER PRIMARY KEY,
  full_name       TEXT NOT NULL,
  birth_date      TEXT NOT NULL,       -- ISO-8601
  birth_time      TEXT NOT NULL,       -- HH:MM[:SS]
  birth_place     TEXT NOT NULL,
  birth_latitude  REAL,                -- кэш геокодера, может быть NULL пока не геокодировано
  birth_longitude REAL,
  birth_timezone  TEXT,                -- IANA tz id
  notes           TEXT,                -- заметки Марины, not для клиента
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

CREATE TABLE consultations (
  id              INTEGER PRIMARY KEY,
  person_id       INTEGER NOT NULL REFERENCES persons(id),
  type            TEXT NOT NULL,       -- 'solar' | 'elective' (Phase 1+)
  solar_year      INTEGER,             -- для type='solar'
  status          TEXT NOT NULL,       -- 'draft' | 'computed' | 'sent'
  request_note    TEXT,                -- запрос клиента / фокус-тема
  facts_json      TEXT,                -- закэшированный ComputedFacts (JSON)
  pdf_path        TEXT,                -- путь к сгенерированному PDF
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

CREATE TABLE charts_cache (
  -- опционально в Phase 0, простой инвалидирует по birth_* hash
  person_id       INTEGER NOT NULL REFERENCES persons(id),
  chart_type      TEXT NOT NULL,       -- 'natal' | 'solar_2026' | ...
  facts_json      TEXT NOT NULL,
  computed_at     TEXT NOT NULL,
  PRIMARY KEY (person_id, chart_type)
);
```

`InterpretationRule`, `Draft`, `Artifact` — **отсутствуют в Phase 0**. Правила живут у Марины в PDF на её стороне; draft и artifact — это просто `consultations.facts_json` + `consultations.pdf_path` в одной таблице.

### 5.3 Endpoints (API)

```
GET    /api/v1/persons                    список клиентов
POST   /api/v1/persons                    создать (авто-геокодинг)
GET    /api/v1/persons/{id}               получить
PATCH  /api/v1/persons/{id}               обновить
DELETE /api/v1/persons/{id}               удалить

GET    /api/v1/persons/{id}/consultations список консультаций клиента
POST   /api/v1/persons/{id}/consultations создать (type + year)
GET    /api/v1/consultations/{id}         получить с facts_json
POST   /api/v1/consultations/{id}/compute запустить расчёт (sync, Haskell CLI)
GET    /api/v1/consultations/{id}/pdf     скачать PDF (генерит если нет)
DELETE /api/v1/consultations/{id}         удалить
```

Синхронный вызов в Phase 0 (без background jobs). Расчёт ~2-5 сек.

---

## 6. PDF layout — Phase 0

Цель: PDF-отчёт, в который Марина смотрит как на **структурированные факты** и сверяет со своим PDF-справочником правил Дарагана/Седашева, на основе чего пишет интерпретацию для клиента.

**Блоки отчёта:**

1. **Заголовок:** ФИО клиента, дата/время/место рождения, год соляра.
2. **Натальная карта:**
   - Таблица позиций планет (Planet, Sign, Degree°Minute, House Placidus, House Equal, Retrograde?).
   - Таблица аспектов (с указанием orb-профиля Natal).
   - Соединения с фикс.звёздами (планета / звезда / orb).
   - Классификации (strong-planets с причинами, weak-planets с причинами).
3. **Соляр-карта:**
   - Точный момент возврата (UTC + локальное время места рождения).
   - Таблица позиций планет.
   - Аспекты (в профиле Natal, т.к. это натал-типа карта).
   - Классификации.
4. **Годовая таблица транзитов по домам натала:**
   - Разбиение на 4 раздела: Марс / Венера / Сатурн / Юпитер.
   - В каждом — список «период X в доме натала Y» с датами вход/выход + хиты аспектов к натальным объектам (с orb-профилем Prognostic).
5. **Footer:** версия ruleset, версия core, ephemeris source, дата генерации.

**Чего НЕТ в Phase 0 PDF:**
- Графических карт-колёс (SVG натальная карта) — Phase 1 (нужна для книги).
- Текстовых интерпретаций — Phase 1+ (когда правила станут first-class).
- Дирекций — Phase 1.
- Касаний высших планет — Phase 1.

---

## 7. Frontend structure (React)

### 7.1 Роуты

```
/                            → список клиентов (с поиском)
/persons/new                 → создать клиента
/persons/:id                 → карточка клиента: натальные данные, список консультаций
/persons/:id/consultations/new  → создать консультацию (type + year + request_note)
/consultations/:id           → просмотр фактов + кнопка «Скачать PDF»
```

### 7.2 Компоненты

- `PersonList`, `PersonForm`, `PersonDetails`
- `ConsultationList`, `ConsultationForm`, `ConsultationView`
- `NatalChartFacts` (таблица позиций, аспектов, классификаций)
- `SolarChartFacts` (та же структура)
- `AnnualTransitTable` (по 4 планетам, группировка по домам)

### 7.3 Что **не** во Frontend

- Редактор правил интерпретации — Phase 1+.
- Графическая карта-колесо (SVG wheel) — Phase 1 (для книги).
- Share-link для Марины — Phase 1+ (сейчас оператор пересылает PDF по почте/Telegram).

---

## 8. Bridge protocol (Python ↔ Haskell)

### 8.1 Транспорт

**Phase 0:** subprocess с stdin/stdout JSON. Один крупный snapshot in → один крупный snapshot out.

**Phase 1+ триггеры миграции:**
- Если время одного `compute` > 10 сек регулярно → long-lived Haskell-process с построчным протоколом.
- Если число вызовов на консультацию > 5 → long-lived или HTTP (Servant).
- Если замеры Phase 0 показывают что Phase 0 subprocess ок — **не мигрируем**.

### 8.2 Принципы

- **Один workflow = один snapshot in + один snapshot out.** Не запрашиваем аспекты отдельно от домов.
- **Python не дублирует math.** Geocoder, timezone, ephemeris raw positions — Python; всё остальное считает Haskell.
- **Errors через exit code + stderr.** Haskell:
  - Exit 0 + stdout JSON — success.
  - Exit 1 + stderr `"parse error: ..."` — bad input.
  - Exit 2 + stderr `"computation error: ..."` — internal failure.

### 8.3 Source of types — двухуровневая модель

Тип-дрейф в текущем mini-MVP уже материализовался (см. `current-mvp-review.md § 5`). Чтобы не повторить ту же проблему в новой архитектуре, владение типами разделено на **два уровня** с явными правилами синхронизации.

**Уровень 1 — Межслойный SOT (между процессами/языками):**

```
packages/contracts/*.schema.json
```

Это **единственный** источник истины для DTO которые пересекают границу процессов (Python ↔ Haskell через subprocess/HTTP) или границу языков (Python ↔ Frontend через HTTP). Изменение Schema = архитектурное изменение, требует синхронной правки во всех слоях.

**Уровень 2 — Внутренний SOT каждого слоя (как тип живёт в этом языке):**

| Слой | Внутренний SOT | Правило |
|---|---|---|
| Haskell | `core/astrology-hs/src/Bridge/Solar.hs` | **Один** модуль с типами `SolarResolvedInput`/`SolarComputedFacts` + их `FromJSON`/`ToJSON`. Никаких параллельных типов в `Domain.Types` или `app/Main.hs`. |
| Python  | `services/api-python/app/models.py` | Pydantic-модели вручную; contract-test валидирует каждый request/response через `jsonschema` против Schema. |
| TS      | `apps/web-react/src/types.ts` | Ручные типы; обновляются в том же PR что и Schema, проверяется code review. |

**Правила синхронизации:**

1. Уровень 2 в каждом слое **сверяется** с Уровнем 1 автоматическим тестом (Python — jsonschema-валидация; Haskell — roundtrip property test против fixture; TS — ручной ревью).
2. Уровень 1 (Schema) меняется **только** через явный коммит в `packages/contracts/` + соответствующие правки во всех трёх Уровнях 2 + обновление fixtures в `packages/test-fixtures/`. См. **bright line #8** в § 11.
3. Запрещено создавать параллельные DTO-типы внутри слоя (например два разных `AnalysisResult` в `Domain.Types` и `Main.hs`). Один слой = один внутренний SOT.

**Codegen откладывается** до момента, когда боль расхождения типов станет измеримой (≥ 3 инцидентов расхождения за квартал). Пока — ручная дисциплина + contract-тесты + bright line #8.

---

## 9. Online-стратегия и deploy

### 9.1 Phase 0: dev на маке оператора

- `run-local.sh` — единственный способ запуска.
- SQLite в `./data/astro.db`.
- pyswisseph `.se1` файлы в `./data/ephemeris/` (одноразовый download через `ephemeris_loader`).
- Frontend на `localhost:3000`, API на `localhost:8000`.
- Марина **не** получает прямой доступ — оператор генерит PDF и пересылает.

### 9.2 Phase 1+: VPS

- Docker-compose + nginx + Let's Encrypt.
- VPS в РФ (152-ФЗ: ПДн её клиентов хранятся в РФ).
- Домен + HTTPS.
- Марина заходит через браузер по домену.
- Опция auth: single-password в `.env` (один пользователь), или OAuth через Яндекс-ID.

### 9.3 Offline-режим снят

Требование из интервью «иногда нет интернета» снято оператором на этапе обсуждения архитектуры. Делаем online-only. Если через 6 мес Марина столкнётся с реальной проблемой — пересматриваем (PWA / native / SSH-tunnel на ноутбук оператора).

---

## 10. Extension points

### 10.1 Swiss Ephemeris ↔ Skyfield изоляция

Один интерфейс в Python-слое:

```python
class EphemerisEngine(Protocol):
    def natal_positions(self, jd: JulianDay, bodies: list[Body]) -> list[RawPosition]: ...
    def transit_samples(self, jd_range: tuple[JulianDay, JulianDay],
                         bodies: list[Body], step_days: float) -> dict[Body, list[Sample]]: ...
    def houses(self, jd: JulianDay, geo: GeoPoint, system: HouseSystem) -> list[float]: ...
    def fixed_star_position(self, name: str, jd: JulianDay) -> RawPosition: ...
```

Реализации:
- `PyswissephEngine` — default в Phase 0.
- `SkyfieldEngine` — лицензионный путь отхода, Phase 1+ если AGPL становится проблемой.

Замена — замена зависимости + тест что обе реализации дают одинаковые результаты в пределах допуска.

### 10.2 Фикс.звёзды — каталог как данные

В Phase 0: hard-coded список ~30 мажорных звёзд в `services/api-python/app/ephemeris/fixed_stars.py` как `list[FixedStarCatalogEntry]`. При переходе на Robson 110 — подставить более полный каталог, код не меняется.

Precession считается в Haskell: `applyPrecession :: FixedStarCatalogEntry -> JulianDay -> FixedStarPosition`. Это **не данные**, это вычисление, оно в core.

### 10.3 Орбисы Дарагана — параметризуемый конфиг

`packages/rulesets/daragan-orbs-v1.json`:

```json
{
  "version": "1.0.0",
  "source": "Дараган К., книга о транзитах (год, страница — заполнит оператор)",
  "natal": {
    "Sun":     { "Conjunction": 8.0, "Sextile": 4.0, ... },
    "Moon":    { ... },
    ...
  },
  "prognostic": {
    "Sun":     { "Conjunction": 1.0, ... },
    ...
  }
}
```

В Phase 0 — placeholder с TODO-комментарием в файле. Значения вносит оператор после Phase 0 из книги.

### 10.4 InterpretationRule — Phase 1+

Когда Марина захочет автоматизировать применение правил:
- В `persons.db` добавится таблица `interpretation_rules`.
- UI редактор правил в Frontend.
- Engine применения правил **в Python** (берёт `facts_json` от core + правила из БД + шаблоны, генерит текст).
- Haskell-core **не меняется** — он продолжает возвращать факты.

Это сразу проектируем как «факты + правила применяются в Python над фактами», не «правила применяются в Haskell».

### 10.5 Книга / курсы — Phase 1+

- **BookTable workflow:** `KnownPersonStudy` + генерация SVG-фрагментов → вставка в книжный layout.
- **KnownPersonStudy:** Person без Consultation. Расчёт натала, переиспользует тот же core-slice как soлар (без soлар-части).

---

## 11. Bright lines (Architecture Invariants)

Зафиксированы как `astro/.claude/architecture-invariants.md` + в `.claude/corrections.md` astro-проекта.

1. **Core не хранит клиентов.** Person/Consultation — только в Python+SQLite.
2. **Core не рендерит PDF.** Вся типография — в Python+WeasyPrint.
3. **Core не управляет HTTP.** HTTP-роуты только в FastAPI.
4. **Core не знает про UI.** Никаких полей типа `display_label`, `ui_colour`, `tooltip_text` в domain-типах.
5. **Core не знает про Consultation как workflow.** Знает только про «snapshot → facts». Если завтра переименуют Consultation в Session — core не затронут.
6. **Один workflow = один крупный snapshot.** Запрещено делать несколько последовательных subprocess-вызовов за один расчёт.
7. **Python не дублирует math из core.** Geocoder/timezone/ephemeris raw — Python. Aspects/houses/classifications/orb-application — только Haskell.
8. **Schema change gate.** Любое изменение `packages/contracts/*.schema.json` обязательно сопровождается **одним коммитом**, в котором есть всё перечисленное:
   - обновлённый `.schema.json`;
   - обновлённые fixtures в `packages/test-fixtures/`, валидируемые против новой Schema;
   - обновлённый roundtrip-тест в Haskell core (`Test.GoldenSolar` или аналог): parse fixture → encode → DeepEq fixture;
   - обновлённый contract-тест в Python (`pytest`: `jsonschema.validate(fixture, schema)` + `pydantic.model_validate(fixture, strict=True)`);
   - обновлённые TS-типы в `apps/web-react/src/types.ts` + smoke-сборка `tsc --noEmit`.

   Schema-only коммит, не сопровождаемый этими шагами — ревью блокирует. Это правило защищает самый опасный шов системы (межслойный SOT — см. § 8.3).

Нарушение любого правила — код-ревью его блокирует. Это не гайдлайн, это инвариант.

---

## 12. Open questions (для Phase 1+ или после early evaluation)

1. **Codegen pipeline.** Внедрить когда накопится ≥ 3 инцидента расхождения типов между слоями.
2. **Long-lived Haskell process / Servant HTTP.** Внедрить когда замеры показывают subprocess overhead > 20% общего compute time.
3. **Postgres миграция.** Когда Марина начнёт работать с live-клиентами на VPS и потребуется concurrent access + backups.
4. **Full Robson 110 fixed stars catalog.** Когда Марина запросит конкретные нестандартные звёзды.
5. **Ректификация (уточнение времени рождения).** Если окажется критичной — отдельный workflow Rectify.
6. **Синастрия.** Отдельный workflow, требует типа `PairChart`.
7. **Автоматизация применения правил.** Phase 1+ when Марина accumulates structured rule-base.

---

## 13. Как этот документ используется

- **Worker-агент** читает target-architecture + PHASE_0_TASKS.md, выполняет задачи.
- **Architect-агент** при расширении домена в Phase 1+ обновляет этот документ и `architecture-invariants.md`.
- **Early evaluation gate** (через ~3 мес после старта Phase 0) — сверка реального кода с этим документом. Если дрейф — фиксируем либо как отложенный рефакторинг, либо как осознанное отклонение (с обоснованием в `.claude/corrections.md`).

Документ — **прескрипция**, а не описание текущего состояния. Описание текущего — `current-mvp-review.md` + код.
