# Архитектурный мемо: модуль «Планетные циклы» (planet cycles)

- Дата: 2026-05-24
- Автор: Project Tech Lead (через tech-lead-architect)
- Статус: DRAFT — ждёт подтверждения владельца по 1 флагу (см. § 9)
- Tier: A (Core-first + schema-change-gate bright line #8 + методология)
- Источник истины при расхождении: `target-architecture.md` + `architecture-invariants.md`

---

## 1. Резюме

Новый прогностический модуль `Domain.PlanetCycles` (Haskell core) считает три семейства событий: **возвраты планет** (транзитная планета = своё натальное положение), **самоаспекты** (транзитная планета под углом 0/60/90/120/150/180° к своему натальному положению) и **прохождение транзитных планет по куспидам натальных домов** (геометрия пересечения градуса, не управитель). Хорошая новость: ~70% машинерии уже есть в `Domain.TransitCalendar` (retro-aware детекция контактов, орб-окна, нумерация проходов, интерполяция точного JD куспида). Главная работа — не математика, а: (1) вынести общий contact-finder в шаренный хелпер, (2) запустить его на широком окне только для нужной подвыборки планет/целей, (3) добавить cusp-crossing как first-class события, (4) пройти schema-change-gate (5 артефактов атомарно), (5) PDF-секции.

**Это эпик из 6 фаз-TASK'ов, не один TASK.** Stage 0 эмпирический proof — обязателен (наш трижды-подтверждённый meta-урок).

---

## 2. Что уже есть (переиспользуем, не пишем заново)

Проверено чтением файлов 2026-05-24:

| Возможность | Где | Переиспользование |
|---|---|---|
| Аспект к **сдвинутой** цели (target + угол) | `TransitCalendar.hs` `shiftedTargets` (~580) | Самоаспект = аспект транзитной P к цели = натальной P + угол. **Та же функция.** |
| Retro-aware детекция + орб-окна (enter/exact/exit) | `TransitCalendar.hs` `findOrbWindows`, `interpolateOrbBoundary` (~330-404) | Точные даты + окна действия для возвратов/самоаспектов. |
| Нумерация проходов + фаза (Direct/Retro/DirectReturn) | `TransitCalendar.hs` `numberContactsFor`, `phaseFromSpeedAndPass` (586-606) | `pass_number` + `loop_id` для ретро-петель «как есть». |
| Точный JD пересечения куспида | `TransitCalendar.hs` `houseIntervals` + `interpolateZero` (413-453) | cusp_transits — реификация переходов из `houseIntervals` в события. |
| Эфемериды Python→Haskell | `Bridge/Solar.hs` `sriTransitSamples :: Map Text [BridgeTransitSample]` (102), `.!= Map.empty` | Новые `cycles_samples` крепятся тем же паттерном, optional, backward-compatible. |
| Бисекция до 1 минуты | `SolarReturn.hs` `findSolarReturnJd` (48) | ⚠️ техника — да; **прямой reuse — нет** (его `crossesArc` предполагает только прямое движение Солнца; ретро-планеты он сломает). |
| House cusps тип | `Domain/Types.hs` `HouseCusps {hcCusps, hcAscendant, hcMc, ...}` | Вход для cusp-crossing. |
| Planet sum-type | `Domain/Types.hs:83` — 10 классических, без wildcard | Phase 1 без расширения; Lilith/Nodes — Phase 2 (Correction 002 дисциплина). |

**Вывод:** новый математический код минимален. Опасность — соблазн скопировать contact-finder в `PlanetCycles` (нарушит дух bright line #7 / Correction 004 — дублирование math). Поэтому Phase B начинается с **рефакторинга-выноса** общего ядра.

---

## 3. Целевая архитектура (слоевая раскладка)

### 3.1 Core (Haskell) — вся математика

**Рефакторинг (Phase B, шаг 1):** вынести из `TransitCalendar.hs` общий contact-finder в шаренный модуль (рабочее имя `Domain.TransitMath`) или экспортировать internals:
- `findContacts :: Double -> [CalSample] -> [AspectType] -> [Contact]` (orb-window + pass-numbering ядро),
- `findCuspCrossings :: HouseCusps -> [CalSample] -> [CuspCrossing]` (из `houseIntervals`).

`analyzeAnnualCalendar` после рефакторинга **вызывает** этот же хелпер (поведение бит-в-бит сохранено — golden cases не меняются; это инвариант Phase B).

**Новый модуль `Domain.PlanetCycles`:**

```haskell
module Domain.PlanetCycles
  ( PlanetReturn(..)
  , SelfAspect(..)
  , CuspCrossing(..)
  , PlanetCyclesResult(..)
  , analyzePlanetCycles
  ) where

-- Возврат: транзитная P к натальной P (соединение).
data PlanetReturn = PlanetReturn
  { prPlanet     :: !Planet
  , prNatalLong  :: !Longitude360
  , prExactJd    :: !Double
  , prOrbEnterJd :: !(Maybe Double)
  , prOrbExitJd  :: !(Maybe Double)
  , prMotion     :: !TransitPhase     -- Direct | Retrograde | DirectReturn
  , prPassNumber :: !Int
  , prLoopId     :: !Text
  } deriving (Eq, Show)

-- Самоаспект: транзитная P под углом к натальной P.
data SelfAspect = SelfAspect
  { saPlanet     :: !Planet
  , saAspect     :: !AspectType       -- Sextile|Square|Trine|Quincunx|Opposition (Conj = это PlanetReturn)
  , saAspectAngle:: !Int
  , saNatalLong  :: !Longitude360
  , saExactJd    :: !Double
  , saOrbEnterJd :: !(Maybe Double)
  , saOrbExitJd  :: !(Maybe Double)
  , saMotion     :: !TransitPhase
  , saPassNumber :: !Int
  , saLoopId     :: !Text
  } deriving (Eq, Show)

-- Пересечение куспида: транзитная P проходит градус куспида дома (ГЕОМЕТРИЯ, не управитель).
data CuspCrossing = CuspCrossing
  { ccPlanet      :: !Planet
  , ccCuspHouse   :: !Int             -- 1..12
  , ccCuspLong    :: !Longitude360
  , ccExactJd     :: !Double
  , ccOrbEnterJd  :: !(Maybe Double)
  , ccOrbExitJd   :: !(Maybe Double)
  , ccMotion      :: !TransitPhase
  , ccPassNumber  :: !Int
  , ccLoopId      :: !Text
  } deriving (Eq, Show)

data PlanetCyclesResult = PlanetCyclesResult
  { pcrReturns      :: ![PlanetReturn]
  , pcrSelfAspects  :: ![SelfAspect]
  , pcrCuspCrossings:: ![CuspCrossing]
  } deriving (Eq, Show)

analyzePlanetCycles
  :: [PlanetPosition]                  -- натальные позиции (цели)
  -> HouseCusps                        -- натальные куспиды
  -> Map Planet [(Double,Double,Double)] -- cycles-sample'ы (jd, lon, speed) по планетам
  -> PlanetCyclesResult
```

Логика: для каждой планеты, для которой есть cycles-sample'ы — прогнать `findContacts` против цели = собственное натальное положение (возврат = Conjunction, самоаспекты = прочие углы) и `findCuspCrossings` против всех 12 куспидов. Три логики **раздельны по конструкции** (три разных списка, три разных типа). Куспид ≠ управитель (тут нет обращения к rulership вообще). Возврат ≠ самоаспект (Conjunction уходит в `pcrReturns`, не в `pcrSelfAspects`).

### 3.2 Services (Python) — только сырые эфемериды + оркестрация + PDF

- **Sampling** (`services/api-python/app/ephemeris/`): новый сэмплер cycles-окна. Считает per-planet sample'ы по правилу каденции (§ 5), собирает в **тот же** единый Bridge-вход. **Никакой математики аспектов** (bright line #7).
- **Orchestration**: один `runSolar`-вызов получает и solar-year transit_samples, и cycles_samples. Один snapshot (bright line #6).
- **PDF** (`app/pdf/transit_themes.py` + `templates/solar.html.j2`): две новые секции (§ 6). Человеческие трактовки, без Daragan verbatim.

### 3.3 Frontend (React) — типы + (опц.) конфиг окна

- `apps/web-react/src/types.ts`: зеркальные интерфейсы `PlanetReturn`/`SelfAspect`/`CuspCrossing`/`PlanetCycles`.
- (Опц., может уехать в Phase 2) UI для конфигурирования cycles-окна на форме консультации. В Phase 1 окно берётся из дефолтов сервера (§ 5).

---

## 4. Точка крепления в контракте (решено)

**`planet_cycles` — top-level sibling рядом с `annual_transit_table`**, не вложение в `analysis`.

| Вариант | Вердикт |
|---|---|
| Вложить в `analysis.planet_cycles` | **Отклонено.** `BridgeAnalysis` — все поля required по схеме → новое поле раздувает blast-radius на все fixtures + golden + ломает «empty chart» backward-compat. |
| **Top-level `planet_cycles`, default-empty** | **Принято.** Зеркалит прецедент `annual_transit_table` (top-level, default `{returns:[],self_aspects:[],cusp_transits:[]}` когда нет cycles_samples). Backward-compatible: существующие fixtures получают пустую секцию. Не трогает all-required analysis-блок. |

DTO: новый `data BridgePlanetCycles` + поле `scfPlanetCycles :: BridgePlanetCycles` в `SolarComputedFacts` (после `scfAnnualTransitTable`). Вход: `sriCyclesSamples :: Map Text [BridgeTransitSample]` + `sriCyclesWindow :: Maybe BridgeCyclesWindow` — оба optional `.:?` (backward-compatible).

---

## 5. Стратегия sampling / snapshot (решение Q1 + Q2)

**Принцип:** один Bridge-вход содержит ВСЕ sample'ы (solar-year transit + cycles), Python считает их в один проход до единственного `runSolar`. Без серии subprocess-вызовов (bright line #6). Размер payload — главный риск; разводим каденцию и окно **per-planet класс**.

| Класс планет | Окно (default) | Каденция | Обоснование |
|---|---|---|---|
| **Медленные** Jupiter, Saturn, Uranus, Neptune, Pluto | широкое (default `[birth_jd, birth_jd + 90 лет]`, конфигурируемо) | адаптивная, шаг ≤ 0.5° (Pluto ~10 дн, Jupiter ~2 дн) | milestone-циклы жизни: Saturn return ~29/58, Uranus opp ~42, Neptune square ~42, Pluto square ~40. Payload bounded (полный угловой путь / шаг). |
| **Внутренние** Sun, Mercury, Venus, Mars | узкое (default `[solar_year_start − 3y, solar_year_start + 5y]`, конфигурируемо) | daily | возвраты ~ежегодно/2-летне; на широком окне дают много, но в узком — управляемо. |
| **Луна** | **по умолчанию ВЫКЛ**; opt-in только на bounded под-окне ≤ 1–2 года, каденция ~6 ч | месячный возврат × multi-year × мелкая каденция = взрыв payload → физически несовместимо с одним snapshot | см. § 9 флаг. |

**Q2 (Moon explosion):** Луна исключена из широкого окна. Возврат Луны осмыслен только в узком окне; делаем его **opt-in** на ограниченном под-окне, иначе не эмитим. По умолчанию Луны в циклах нет.

**Q3 (Sun return):** в широком окне Sun-return = годовой соляр (раз в год). Эмитим, но помечаем `event_subtype: "solar_return"`; PDF дедупит против основной соляр-секции (не дублируем там, где соляр уже описан). В списке циклов остаётся как годовой якорь.

**Самоаспекты — default только медленные** (Jupiter..Pluto): Saturn square Saturn (~7/21/36/51), Uranus opp Uranus (~42), Neptune square Neptune (~42), Pluto square Pluto (~40) — это высокосигнальные возрастные фазы. Самоаспекты внутренних планет (Sun/Mercury/Venus квадрат к себе) — высокочастотный низкосигнальный шум → по умолчанию **не эмитим** (opt-in). **Возвраты** считаем для всех Sun..Pluto (Луна по флагу).

---

## 6. JSON-схема секций (решение Q4)

```jsonc
"planet_cycles": {
  "returns": [
    {
      "planet": "Jupiter",
      "event_type": "return",
      "event_subtype": null,            // "solar_return" для Sun
      "aspect_angle": 0,
      "aspect_name": "conjunction",
      "natal_longitude": 123.45,
      "exact_datetime": "2031-05-14T08:22:00Z",
      "start_datetime": "2031-04-20T...",
      "end_datetime":   "2031-06-09T...",
      "orb": 1.0,
      "motion": "direct",               // direct | retrograde | direct_return
      "pass_number": 1,
      "loop_id": "jupiter-return-2031"
    }
  ],
  "self_aspects": [
    {
      "planet": "Saturn",
      "event_type": "self_aspect",
      "aspect_angle": 90,
      "aspect_name": "square",          // sextile|square|trine|quincunx|opposition
      "natal_longitude": 210.12,
      "exact_datetime": "...", "start_datetime": "...", "end_datetime": "...",
      "orb": 1.0, "motion": "retrograde", "pass_number": 2, "loop_id": "saturn-square-2026"
    }
  ],
  "cusp_transits": [
    {
      "planet": "Jupiter",
      "event_type": "cusp_crossing",
      "cusp_house": 10,
      "cusp_longitude": 250.12,
      "exact_datetime": "...", "start_datetime": "...", "end_datetime": "...",
      "orb": 1.0, "motion": "direct", "pass_number": 1, "loop_id": "jupiter-cusp-10-2026"
    }
  ]
}
```

`returns`/`self_aspects` делят форму (различие — `event_type` + наличие `aspect_angle≠0`). `cusp_transits` использует `cusp_house`/`cusp_longitude` вместо `natal_longitude`/`aspect_*`. Все три — массивы, default `[]`.

---

## 7. Schema-change-gate — план (5 артефактов, ОДИН коммит, Phase C)

Bright line #8. Атомарно:

1. **`packages/contracts/solar-computed-facts.schema.json`** — `$defs/PlanetReturn`, `$defs/SelfAspect`, `$defs/CuspCrossing`, `$defs/PlanetCycles`; добавить `planet_cycles` в properties (НЕ в `required` → default-empty backward-compat).
2. **`core/astrology-hs/src/Bridge/Solar.hs`** — `BridgePlanetCycles` + sub-records (ToJSON/FromJSON); `scfPlanetCycles` в `SolarComputedFacts` ToJSON; `sriCyclesSamples`/`sriCyclesWindow` в input FromJSON (optional); `runSolar` вызывает `analyzePlanetCycles`.
3. **`core/astrology-hs/test/golden/synthetic-solar-1.expected.json`** (+ `Test/GoldenSolar.hs` если нужно) — расширить ожидаемый вывод секцией `planet_cycles` (несколько примеров событий). Roundtrip: parse→encode→DeepEq.
4. **`packages/test-fixtures/solar-facts-sample.json`** (+ `services/api-python/tests/test_contracts.py`) — зеркало golden; `jsonschema.validate` проходит.
5. **`apps/web-react/src/types.ts`** (+ `tsc --noEmit`) — интерфейсы зеркалят DTO.

**Плюс Correction 010** (решение Q5): scope квинконса расширяется до `{Directions, TransitCalendar, PlanetCycles}`. Записать как amendment к Correction 009 + обновить устаревший комментарий `AspectType` в `Domain/Types.hs:97` («emitted ONLY by Domain.Directions» — уже неверно после 009). Это часть Phase C коммита (методологический инвариант рядом со схемой).

**Q6 (Lilith mode):** convention фиксируем в этом мемо (`lilith_mode: "mean"|"true"`, без тихого смешивания), но **поле в схему НЕ добавляем до Phase 2** (YAGNI — мёртвое поле не нужно; добавление в Phase 2 — свой gate). Phase 1 = 10 классических, Луна по флагу.

---

## 8. Фазовая декомпозиция (6 TASK'ов, последовательно)

Каждая фаза = слой = конкретные файлы, со STOP-триггерами и acceptance. Зависимости: A гейтит всё; C зависит от B; D от C; E от D; F финал.

### Phase A — Stage 0 эмпирический proof (НЕ продуктовый код)
- **Слой:** аналитика (scratch).
- **Что:** на реальной карте (Марина, person 4) вычислить вручную/через pyswisseph известные циклы — Jupiter return, Saturn return даты, Uranus opp (если по возрасту попадает), один ретро-петлевой возврат с 3 проходами. Сверить с эфемеридами; если есть — с Zet 9 Марины (по парам/датам, не подгонять exact — Correction 006-pre).
- **STOP:** если планируемый подход не воспроизводит известную дату возврата в пределах толеранса (напр. ±1 день) → STOP, пересмотр до кода.
- **Acceptance:** HANDOFF с таблицей «событие → наша дата → эталон → Δ»; подтверждение, что retro-петля даёт 3 прохода.

### Phase B — Core `Domain.PlanetCycles` + вынос contact-finder + unit-тесты
- **Слой:** Core (Haskell). Файлы: новый `Domain/PlanetCycles.hs`; рефактор `Domain/TransitCalendar.hs` (экспорт/вынос `findContacts`/`findCuspCrossings` в `Domain/TransitMath.hs`); тесты `test/`.
- **Без schema-изменений** — считаем in-memory, тестируем HUnit/golden-unit.
- **STOP:** дублирование math (копипаст детекции вместо выноса); wildcard в Planet match; **изменение вывода `analyzeAnnualCalendar`** (golden cases обязаны остаться бит-в-бит).
- **Acceptance:** `cabal build` clean; unit-тесты на Jupiter return / Saturn square / Uranus opp / ретро-петля 3 прохода / cusp-crossing; существующие golden cases без изменений.

### Phase C — Schema-gate атомарно (тяжёлая)
- **Слой:** контракт (cross-layer). 5 артефактов § 7 + Correction 010 — ОДИН коммит.
- **STOP:** любой из 5 артефактов отсутствует в коммите; golden roundtrip падает; `tsc` падает; `planet_cycles` попал в `required`.
- **Acceptance:** Haskell roundtrip + Python contract-test + `tsc --noEmit` зелёные; `git show` коммита содержит все 5.

### Phase D — Python sampling + orchestration
- **Слой:** Services. Файлы: `app/ephemeris/` (cycles-сэмплер per-planet каденция § 5); compute-путь собирает единый Bridge-вход; дефолты окна.
- **STOP:** математика аспектов в Python; >1 subprocess-вызов на расчёт; payload Луны взрывается (нарушение § 5).
- **Acceptance:** один `runSolar` отдаёт `planet_cycles` для реальной карты; payload в разумных границах (залогировать размер); pytest зелёный.

### Phase E — PDF секции
- **Слой:** Services (presentation). Файлы: `app/pdf/transit_themes.py` (хелперы `planet_returns_block`, `self_aspects_block`, `cusp_crossings_block`); `templates/solar.html.j2` (две секции: «Планетные циклы и возвраты», «Включение домов через куспиды»).
- **STOP:** Daragan verbatim; смешение возвратов с домами; смешение куспида с управителем; generic-вода без указания качества планеты; LLM.
- **Acceptance:** свежий render Марины: обе секции присутствуют, даты + смысловые трактовки; Sun-return дедуплицирован против соляр-секции; брейвити-гайд.

### Phase F — Калибровочная регрессия
- **Слой:** тесты. Все 6 калиброванных кейсов + Марина + Ольга.
- **STOP:** регрессия существующих golden/калиброванных секций.
- **Acceptance:** pytest + cabal зелёные; spot-check дат циклов на 2-3 кейсах; HANDOFF с диффами.

**Reviewer:** REQUIRED на Phase B (Core math), Phase C (schema-gate), Phase E (методология/клиентский текст). Phase A/D/F — self-review достаточно.

---

## 9. Главные риски + флаг владельцу

| Риск | Стратегия снижения |
|---|---|
| **R1: payload Луны/внутренних × широкое окно** | § 5 разводка каденции/окна; Луна opt-in bounded; внутренние — узкое окно. **← флаг § 9.1** |
| R2: schema-gate — самый опасный шов | атомарный коммит, Phase C изолирована, все 5 артефактов + roundtrip |
| R3: корректность ретро-многопроходности | переиспользуем проверенный `numberContactsFor`, не новый код; Phase A верифицирует на реальной петле |
| R4: scope-creep квинконса | явная Correction 010, scoped только к PlanetCycles; транзит-календарь не трогаем |
| R5: методологический дрейф (Daragan verbatim / смешение логик) | те же гарды что в прошлых TASK'ах; Reviewer на Phase E; три раздельных типа по конструкции |
| R6: дублирование math (копипаст из TransitCalendar) | Phase B начинается с выноса общего ядра; bright line #7 / Correction 004 |

### 9.1 ФЛАГ владельцу (один блокирующий вопрос)

Твоё решение «все 10 классических» физически конфликтует с «широкое multi-year окно + один snapshot» для **Луны** (месячный возврат × десятилетия × мелкая каденция = взрыв payload). Рабочее предположение мемо (по которому действую, если не поправишь):

> **Возвраты:** Sun..Pluto на своих окнах (§ 5). **Луна — по умолчанию ВЫКЛ**, opt-in только на bounded под-окне ≤ 1–2 года.
> **Самоаспекты:** по умолчанию только медленные Jupiter..Pluto (возрастные фазы); внутренние — opt-in.
> **Cusp-crossings:** все запрошенные планеты на своих окнах.

Если хочешь Луну/внутренние самоаспекты в полном объёме — это либо отдельный «лунный» узкооконный отчёт (Phase 2), либо принять тяжёлый payload. Подтверди предположение или скорректируй.

---

## 10. Оценка scope

- **Core (Phase B):** средне — большая часть машинерии есть; работа = вынос + новый тонкий модуль + тесты.
- **Schema-gate (Phase C):** тяжело — 5 артефактов, самый рискованный шаг.
- **Python sampling (Phase D):** средне — новый сэмплер с per-planet каденцией.
- **PDF (Phase E):** средне — две секции + словари трактовок (без verbatim).
- **Итого:** Tier A эпик, 6 фаз, каждая — отдельный TASK с Reviewer на B/C/E.

Не выходить за фазу: один TASK = один слой = конкретные файлы. STOP-триггеры — выше.
