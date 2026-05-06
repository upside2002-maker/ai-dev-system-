# Current MVP Review

**Дата:** 2026-04-24.
**Автор:** Architect-агент.
**Объект ревью:** `/Users/ilya/Projects/astro/` (состояние на 2026-04-14, последний touch).
**Цель:** сопоставить mini-MVP каркас с validated requirements из `RESEARCH/findings/CORRECTIONS_AFTER_INTERVIEW.md` и `MARINA_INTERVIEW_RESPONSES.md`, дать покомпонентный приговор.

---

## 1. Что физически в репозитории

### 1.1 Структура на верхнем уровне

```
astro/
├── core/astrology-hs/              Haskell-ядро (cabal 3.0, GHC 9.6.6)
│   ├── src/Domain/                 Types, Zodiac, Planets, Aspects, Dignities,
│   │                               Houses/Placidus, Ascendant, Transits,
│   │                               StrengthAnalysis, WeaknessAnalysis, Report
│   ├── src/Adapters/               Ephemeris/Swiss, Ephemeris/Types, TimeZone
│   ├── app/Main.hs                 CLI: stdin JSON → stdout JSON
│   ├── test/                       hspec + QuickCheck + Test.Golden
│   └── dist-newstyle/              build artefacts (закоммичены в репозиторий)
│
├── services/
│   ├── api-python/                 FastAPI: main, models, core_client,
│   │                               ephemeris_bridge, pdf, geocoder
│   ├── ephemeris-python/           downloader .se1 файлов с astro.com
│   ├── orchestrator-python/        InMemoryJobStore (не интегрирован)
│   └── pdf-python/                 WeasyPrint + Jinja2 шаблон
│
├── apps/web-react/                 Vite + React Router SPA
│   └── src/pages/                  NewAnalysisPage, AnalysisResultPage, HistoryPage
│
├── packages/
│   ├── contracts/                  4 JSON Schema: core-input, core-resolved-input,
│   │                               analysis-request, analysis-result
│   ├── rulesets/ruleset-v1.0.0.json
│   └── test-fixtures/              sample JSONs
│
├── infra/docker/                   api.Dockerfile, web.Dockerfile, nginx.conf
├── docker-compose.yml              api + web
├── run-local.sh                    stack: cabal build + uvicorn + vite dev
└── docs/
    ├── architecture/adr-0001-python-ephemeris-bridge.md
    └── agents/current-state-handoff.md
```

### 1.2 Что реально работает (заявлено в handoff)

- Haskell CLI собирается (GHC 9.6.6, aarch64-osx build artefacts присутствуют).
- Python API компилируется (`python3 -m compileall app` проходит).
- React frontend существует с роутингом + 3 страницы.
- PDF-builder рендерит HTML через WeasyPrint в PDF.

### 1.3 Что явно не работает или рассогласовано (из handoff + Read)

- API ожидает output поля `ascendant/strong_planets/weak_planets/transit_hits/meta`; Haskell `Main.hs` возвращает их же (это ОК), но `Domain.Types.AnalysisResult` (внутренний тип) описывает совсем другую структуру с полями `arChart/arClassifications/arTransitHits/arRulesetVersion/...`. **Два параллельных набора output-типов в одном репозитории.**
- Frontend `src/api.ts` обращается к `/api/v1/...`, формы используют `birth_data`; backend model — `birth`. Разъезд типов подтверждён.
- `orchestrator-python` не интегрирован с API (мёртвый код).
- `dist-newstyle/` закоммичен — build-артефакты в git, ~MB мусора.

---

## 2. Сверка с validated requirements

Требования из `CORRECTIONS_AFTER_INTERVIEW.md` и `MARINA_INTERVIEW_RESPONSES.md`, колонка `Phase 0 scope` отражает зафиксированный с оператором scope этой архитектурной сессии.

| Требование | В текущем MVP | Phase 0 scope | Статус |
|---|---|---|---|
| Письменный формат, PDF — центральный артефакт | PDF-builder есть, короткий шаблон | ✅ центр | частично готово |
| Соляр 90% как услуга | Нет концепции соляра | ✅ центр | **отсутствует** |
| Электив 10% как услуга | Нет концепции электива | Phase 1+ | — |
| Натал как промежуточный расчёт | Есть (натальные позиции, Placidus cusps) | ✅ | готово |
| Годовая таблица транзитов по домам натала | Нет | ✅ центр | **отсутствует** |
| Дирекции от даты рождения до окончания | Нет | Phase 1+ | — |
| Касания высших планет + аспекты Сатурна/Юпитера | Нет | Phase 1+ | — |
| Выход транзитной планеты на Асц | Есть (единственная фича MVP) | Phase 0 (как часть транзитов) | пересекается |
| Плацидус + Равнодомная от Асц | Только Placidus | ✅ обе | **отсутствует Equal** |
| Орбисы по Дарагану, натал vs прогностика | Зашиты 6/8, один профиль | ✅ Дараган, 2 профиля | **не совпадает** |
| Лунные узлы | `excluded_in_v1` явно | ✅ | **отсутствует** |
| Лилит | `excluded_in_v1` явно | ✅ | **отсутствует** |
| Хирон | `excluded_in_v1` явно | ✅ | **отсутствует** |
| Неподвижные звёзды | Нет | ✅ топ-30 | **отсутствует** |
| Заполярье (полярные рождения) | Placidus не обрабатывает edge-case | ✅ fallback на Equal | **отсутствует** |
| Offline-режим | Docker-стек, требует сети | снято (online-only) | нерелевантно |
| Один пользователь | Multi-user схема (in-memory _analyses dict) | ✅ single-user | избыточно |
| Person как сущность (повторные клиенты) | Нет, каждый `AnalysisRequest` анонимен | ✅ first-class | **отсутствует** |
| Правила интерпретации | Нет | Phase 1+ (в Phase 0 инструмент даёт только факты) | — |
| Deploy target — локально на маке оператора | Docker-compose + nginx | dev-setup, run-local.sh | избыточно |

**Пересечение «что построено» и «что нужно для Phase 0»:** узкое. Реально переиспользуется только:
- Python ephemeris bridge (pyswisseph + geocoder + tz) — но требует расширения на Nodes/Lilith/Chiron.
- Haskell Domain.Zodiac / Domain.Aspects / Domain.Dignities / Domain.StrengthAnalysis / Domain.WeaknessAnalysis — алгоритмические модули, остаются в ядре.
- PDF-builder каркас — расширяемый.
- JSON-schema подход — принцип сохраняется, сами схемы переписываются.

**Всё остальное** либо выбрасывается, либо переписывается под новый scope.

---

## 3. Оценка через 4 tech-lead фильтра

### Фильтр 1 — Goal vs letter

**Goal (из интервью):** сократить подготовку соляра с 8 ч до 1-2 ч, для потока 60+ консультаций/мес, формат письменный, output — PDF-отчёт клиенту.

**Letter текущего MVP:** «API для расчёта транзитов к натальному Асценденту на произвольный период». Узкая численная фича без доменного workflow соляра.

**Разрыв:**
- MVP решает одну из 4 болей Марины (транзиты на Асц), не касается остальных трёх.
- MVP не знает про соляр (возврат Солнца), годовую таблицу по домам, повторных клиентов.
- MVP строит UI вокруг «технической операции» (NewAnalysis / AnalysisResult / History), не вокруг workflow соляра.

**Вердикт:** mini-MVP — технический прототип одной фичи, не prototype рабочего инструмента. Это не критика реализации, это факт смещения цели после research.

### Фильтр 2 — Архитектурная цена

**Многосервисный монорепо (api + ephemeris + orchestrator + pdf + web) + Docker + nginx** — это шаблон SaaS с горизонтальным масштабированием. Для одного пользователя на dev-машине оператора это избыточно:
- `ephemeris-python` — downloader `.se1` файлов. Это **утилита**, не сервис. Не имеет API, не запускается отдельным процессом. Выделение в `services/` cargo-cult от SaaS-паттерна.
- `orchestrator-python` — InMemoryJobStore не интегрирован с API. Дублирует `_analyses: dict[str, AnalysisRecord]` в `api-python/app/main.py`. Мёртвый код.
- `docker-compose.yml` + два Dockerfile + nginx — для Phase 0 deploy «локально на маке» не используется, но занимают место в репозитории и требуют поддержки.

**Два параллельных набора типов** (`Domain.Types.AnalysisResult` vs `Main.hs CoreOutput`) — в Haskell-репозитории без явной причины. Ломает источник истины внутри core.

**JSON-схемы как контракты** идея правильная, но их 4 штуки (`core-input`, `core-resolved-input`, `analysis-request`, `analysis-result`) — `core-input` кажется deprecated остатком до ADR-0001 (`core-input` ≠ `core-resolved-input`). Нужен аудит.

### Фильтр 3 — Scale vs complexity

Текущая архитектура калибрована под **horizontally scalable multi-service SaaS**:
- Job orchestrator (async jobs).
- Dockerised services (independent deploys).
- Nginx reverse proxy.
- In-memory store как «placeholder for PostgreSQL» (из комментария в `main.py:32`).

Реальный масштаб: **один оператор, один пользователь (Марина), 60-100 консультаций/мес, dev-машина оператора**. Разрыв 100×.

### Фильтр 4 — Red-flag vocabulary

Фразы в документации текущего MVP:
- ADR-0001: «preserves Haskell as the domain kernel», «better kept in a strongly typed functional kernel» — **без бизнес-обоснования**. Это классический «for purity».
- `main.py:32`: «placeholder for PostgreSQL» — «на будущее», BД не нужна в текущем масштабе.
- `services/orchestrator-python/jobs.py:32`: «Queue-agnostic store used until Redis/PostgreSQL-backed orchestration is wired» — «future-proof», не решает текущей задачи.
- `models.py:45`: `language: str = Field(default="en", description="Language code for the analysis output")` — поле для мультиязычности, которая не нужна (99% РФ).

Каждая из этих фраз — маркер «строим на вырост», не «строим под задачу».

---

## 4. Покомпонентный приговор

Легенда: 🟢 оставить — 🟡 упростить — 🔵 переписать — 🔴 выбросить.

### Core (Haskell)

| Компонент | Приговор | Обоснование |
|---|---|---|
| `Domain.Types` | 🔵 переписать | Дублирует типы с `Main.hs`, не содержит Nodes/Lilith/Chiron/FixedStar, нет `HouseSystem(Equal)`, `OrbProfile`, нет newtypes для единиц |
| `Domain.Zodiac` | 🟢 оставить | Чистая арифметика, работает |
| `Domain.Planets` | 🟡 упростить + расширить | Enum `Planet` расширить до 14+ значений + `FixedStar Text` |
| `Domain.Aspects` | 🔵 переписать | Захардкодено 5 аспектов с фиксированными orb'ами; параметризовать `OrbProfile` |
| `Domain.Dignities` | 🟢 оставить | Classical dignities стабильны |
| `Domain.Houses.Placidus` | 🟢 оставить | Формула корректная, golden-tests можно написать |
| `Domain.Houses.Equal` | 🔴 отсутствует, создать | Критично для Заполярья |
| `Domain.Ascendant` | 🟢 оставить | — |
| `Domain.Transits` | 🔵 переписать | Сейчас — «transit to natal Asc», нужно «annual table by houses» + обобщение |
| `Domain.StrengthAnalysis` / `WeaknessAnalysis` | 🟢 оставить | Логика классификации применима |
| `Domain.Report` | 🔴 выбросить | Дублирует логику `Main.hs runAnalysis`, не используется в runtime |
| `Adapters.Ephemeris.Swiss` | 🔴 выбросить | ADR-0001 отменил прямой FFI, модуль мёртв |
| `Adapters.Ephemeris.Types` | 🟡 упростить | Только те типы что реально на границе |
| `Adapters.TimeZone` | 🟢 оставить | `julianDayToUTC` нужна в CLI |
| `app/Main.hs` | 🔵 переписать | Дублирует типы, захардкожена логика одной фичи (транзиты на Асц); заменить на диспетчер workflow |
| `test/` golden + spec | 🟢 оставить + расширить | Добавить golden против Zet9 на реальных клиентах Марины |
| `dist-newstyle/` в git | 🔴 удалить | Build-артефакты не коммитятся |

### Services (Python)

| Компонент | Приговор | Обоснование |
|---|---|---|
| `services/api-python/app/main.py` | 🔵 переписать | Endpoints заточены под `AnalysisRequest` (анонимный), нужны Person + Consultation CRUD + workflow-endpoints |
| `services/api-python/app/models.py` | 🔵 переписать | Модели под старый scope; переписать под новый домен |
| `services/api-python/app/ephemeris_bridge.py` | 🟡 упростить + расширить | База работает; добавить Nodes/Lilith/Chiron/FixedStars + Equal houses; убрать захардкоженный `house_system=b"P"` |
| `services/api-python/app/core_client.py` | 🟢 оставить | Subprocess-обёртка работает |
| `services/api-python/app/pdf.py` | 🟡 упростить | Оставить как адаптер; перенести логику PDF в `services/pdf-python/` |
| `services/api-python/app/geocoder.py` | 🟢 оставить (проверить наличие) | Read показал файл пустой — уточнить |
| `services/ephemeris-python/` | 🟡 упростить | Оставить как библиотечный пакет `ephemeris_loader`, убрать `pyproject.toml` и статус «service». Либо слить в `services/api-python/app/ephemeris/` |
| `services/orchestrator-python/` | 🔴 выбросить | Мёртвый код, функциональность не нужна в Phase 0 (синхронная обработка достаточна) |
| `services/pdf-python/` | 🟡 упростить + переписать шаблон | Каркас оставляем; шаблон переписываем под соляр-отчёт (натал, соляр, годовая таблица, аспекты) |

### Frontend (React)

| Компонент | Приговор | Обоснование |
|---|---|---|
| `apps/web-react/` общий каркас (Vite, React Router) | 🟢 оставить | Правильный выбор для UI |
| `src/App.tsx` — заголовок «Транзиты к Асценденту» | 🔵 переписать | UI-структура заточена под старый scope |
| `src/pages/NewAnalysisPage.tsx` | 🔵 переписать | Форма анонимного запроса; нужен flow Person → Consultation |
| `src/pages/AnalysisResultPage.tsx` | 🔵 переписать | Отображает транзиты к Асц; нужно отображение соляр-фактов |
| `src/pages/HistoryPage.tsx` | 🔵 переписать | История анонимных запросов; нужна история по клиентам |
| `src/api.ts` | 🔵 переписать | Переделать под новые endpoints |
| `src/types.ts` | 🔵 переписать | Под новые DTO |

### Contracts

| Компонент | Приговор | Обоснование |
|---|---|---|
| `packages/contracts/core-input.schema.json` | 🔴 выбросить | Deprecated остаток до ADR-0001 |
| `packages/contracts/core-resolved-input.schema.json` | 🔵 переписать | Переименовать в `solar-resolved-input.schema.json`, расширить на Nodes/Lilith/Chiron/FixedStars, добавить `house_systems: [Placidus, Equal]`, `orb_profile` |
| `packages/contracts/analysis-request.schema.json` | 🔵 переписать | Под новый domain (Person + Consultation + workflow type) |
| `packages/contracts/analysis-result.schema.json` | 🔵 переписать | Под ComputedFacts для соляра (натал, соляр-карта, годовая таблица транзитов) |
| `packages/rulesets/ruleset-v1.0.0.json` | 🔵 переписать v2 | Добавить Nodes/Lilith/Chiron; orbs Дарагана (placeholder с TODO, полные значения — из книги Дарагана оператором); два orb-профиля |
| `packages/test-fixtures/` | 🔵 обновить | Фикстуры под новые контракты + golden Zet9 output |

### Infra

| Компонент | Приговор | Обоснование |
|---|---|---|
| `docker-compose.yml` | 🟡 оставить, но не использовать в Phase 0 | Пригодится при переезде на VPS в Phase 1+ |
| `infra/docker/api.Dockerfile` | 🟡 оставить | Phase 1+ |
| `infra/docker/web.Dockerfile` | 🟡 оставить | Phase 1+ |
| `infra/docker/nginx.conf` | 🟡 оставить | Phase 1+ |
| `run-local.sh` | 🔵 переписать | Основной способ запуска в Phase 0; адаптировать под новую структуру |

### Docs

| Компонент | Приговор | Обоснование |
|---|---|---|
| `docs/architecture/adr-0001-python-ephemeris-bridge.md` | 🟡 пометить `Superseded by target-architecture.md` | Ценное историческое решение, но теперь полная архитектура в overlay |
| `docs/agents/current-state-handoff.md` | 🟡 пометить `Archived` | Зафиксирован state на апрель 2026, больше не актуален |

---

## 5. Состояние контрактов — уже есть разъезд

Handoff явно фиксирует **три разъезда** на момент апреля 2026:

1. **API ↔ Core DTO.** `main.py` ждёт `ascendant/strong_planets/weak_planets/transit_hits/meta`. `Domain.Types.AnalysisResult` описывает `arChart/arAscendant/arAscZodiac/arClassifications/arTransitHits/arRulesetVersion/arCoreVersion/arEphemerisSource`. `Main.hs CoreOutput` параллельно описывает **третий** набор полей, совместимый с API.

2. **Frontend ↔ API.** `src/api.ts` вызывает `/api/v1/...`, модели используют `birth_data`; backend — `/api/v1/analysis`, модель — `birth`.

3. **Contracts ↔ реализации.** `packages/contracts/core-input.schema.json` — deprecated (до ADR-0001), но лежит рядом с `core-resolved-input.schema.json` без пометки.

**Значение для target-architecture:** проблема «разъезд типов» уже материализовалась на объёме 10 планет + 1 фичи. При расширении до 14+ планет + 24+ фикс.звёзд + 4 workflow'ов (натал/соляр/электив/разбор известной личности) без **явного источника истины и дисциплины bright lines** разъезд станет системным. Это обосновывает строгую формулировку `packages/contracts/` как источник межсервисных типов.

---

## 6. Состояние ruleset-v1.0.0.json — что не совпадает с Дараган-методикой

| Элемент | В текущем ruleset | Требование Марины |
|---|---|---|
| Планеты | 10 (Sun-Pluto) | +Узлы, Лилит, Хирон, фикс.звёзды |
| Exclusion | `excluded_in_v1: Chiron, Lilith, NorthNode, SouthNode` + note «NorthNode/SouthNode may be added in v2» | Эти точки — **часть методики Марины**, а не опция v2 |
| Orbs | `harmonious: trine 8, sextile 6; tense: opposition 8, square 8; neutral: conjunction 8` | Дараган-орбисы (конкретные значения — из его книги о транзитах), **разные для натала и прогностики** |
| Orb profile | Один набор | Два профиля: `Natal` / `Prognostic` |
| Системы домов | Placidus только | Placidus + Equal from Asc |
| Fixed stars | нет | топ-30 мажорных (Phase 0 гипотеза) |
| Combust | есть, 8.5° | применимо |
| Cazimi | есть, <17′ | применимо |
| T-square | есть | применимо |
| Elevation modes | `above_horizon / angular_priority / custom_rule_set` | избыточно на Phase 0, достаточно `above_horizon` (MC-проверка + дом 10) |

**Вывод:** `ruleset-v1.0.0.json` фиксирует неверную методологию для Марины и помечает её методику как `v2 maybe`. Нужен `ruleset-v2.0.0.json` с правильной базой.

---

## 7. Summary-таблица: что идёт в target, что выбрасывается

### Из MVP переиспользуется (доработкой)

- `core/astrology-hs/` как проект — cabal + test harness + принцип pure core.
- `Domain.Zodiac`, `Domain.Dignities`, `Domain.StrengthAnalysis`, `Domain.WeaknessAnalysis`, `Domain.Ascendant` — как алгоритмические модули.
- `Domain.Houses.Placidus` — формула.
- `Domain.Aspects` — после параметризации через `OrbProfile`.
- `services/api-python/app/ephemeris_bridge.py` — pyswisseph + geocoder + tz caller.
- `services/api-python/app/core_client.py` — subprocess-обёртка.
- `services/pdf-python/pdf_builder/builder.py` — WeasyPrint + Jinja каркас.
- `apps/web-react/` — Vite + React Router каркас.
- `run-local.sh` — базовая идея.
- `packages/contracts/` как директория — принцип «JSON Schema как межслойный контракт».

### Из MVP выбрасывается

- `core/astrology-hs/dist-newstyle/` (build artefacts в git).
- `core/astrology-hs/src/Adapters/Ephemeris/Swiss.hs` — отменено ADR-0001.
- `core/astrology-hs/src/Domain/Report.hs` — не используется.
- `core/astrology-hs/src/Domain/Types.hs` в текущем виде — заменяется новой модульной структурой; output-типы соляра (то что core возвращает наружу) живут в **одном** bridge-модуле (`src/Bridge/Solar.hs`), без параллельных дублей в Domain.* (см. `target-architecture.md § 8.3` про двухуровневую модель источников истины).
- `services/orchestrator-python/` — мёртвый код.
- `packages/contracts/core-input.schema.json` — deprecated.
- `packages/rulesets/ruleset-v1.0.0.json` — заменяется на v2.
- `src/pages/*` в текущем виде — UI под старый scope.

### Добавляется (новое в target)

- `Domain.Planets.FixedStars` (precession применяется к каталогу).
- `Domain.Houses.Equal`.
- `Domain.OrbProfile` (Natal / Prognostic).
- `Domain.SolarReturn` (поиск возврата Солнца bisection'ом).
- `Domain.TransitTable` (годовая таблица по домам натала).
- `Services` слой с Person / Consultation / storage (SQLite).
- Рабочий контракт `solar-resolved-input.schema.json` + `solar-computed-facts.schema.json` (формат один крупный snapshot).
- PDF-шаблон для соляра (натал, соляр-карта, годовая таблица, аспекты, классификации).
- Frontend flow Person → Consultation → Facts → PDF.
- Golden tests против Zet9-output на 3-5 реальных клиентов Марины.
- `.claude/architecture-invariants.md` + `.claude/corrections.md` для astro-проекта.

---

## 8. Главный вывод ревью

Mini-MVP — технический прототип одной численной фичи (транзиты на Асц), построенный до закрытия research. После pivot'а в `CORRECTIONS_AFTER_INTERVIEW.md` стало понятно что нужен не SaaS-скелет с orchestrator/docker/nginx, а **рабочий инструмент соляра** с Person как first-class, годовой таблицей транзитов как центром PDF-отчёта и расширенным доменом (Узлы/Лилит/Хирон/фикс.звёзды/Equal houses/Дараган-орбисы).

**Цена миграции:** выше чем «doработать текущий каркас», ниже чем «переписать с нуля». Переиспользуется ~30% кода (numeric algorithms + bridge skeleton + PDF builder + React shell). Остальное переписывается под новый domain и scope.

**Цена обоснована:** mini-MVP не был ошибкой — был корректным прототипом до research. Research задал другой scope, под него делается target-architecture.
