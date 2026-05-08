# Migration Plan: mini-MVP → Target Architecture

**Дата:** 2026-04-24.
**Предпосылки:** см. `current-mvp-review.md` (что есть) и `target-architecture.md` (куда идём).
**Цель:** перейти к рабочему инструменту соляра Марины с минимальным выбрасыванием годного кода и без полного rewrite.

> **Update 2026-05-06:** Phase 0 эволюционировал за рамки оригинального плана 0.1/0.2 в продуктовой работе 2026-04-24 → 2026-05-06 (внутренние «фазы 0.5–0.10b»). См. `architecture-drift-recon.md` § 3 (PHASE_0_TASKS status walk) и § 5.1 (conscious deviations) + `target-architecture.md` § 6 «Эволюция scope». Этот migration-plan остаётся валидным для **порядка** и **зависимостей** блоков; конкретный scope каждого блока — обновлён в `target-architecture.md` § 6 и в status-аннотациях `PHASE_0_TASKS.md`.

---

## 1. Стратегия миграции

**Selective rewrite с сохранением каркасов.** Не greenfield, но и не «доработка существующего» — это частичный rewrite под изменившийся scope после research.

**Сохраняем (~30% переиспользования):**
- Cabal-проект `core/astrology-hs` со структурой src/test/app.
- Algorithmic-модули core: `Domain.Zodiac`, `Domain.Aspects` (после параметризации), `Domain.Dignities`, `Domain.StrengthAnalysis`, `Domain.WeaknessAnalysis`, `Domain.Houses.Placidus`.
- Vite + React Router каркас фронтенда.
- WeasyPrint + Jinja2 PDF pipeline.
- Subprocess-граница Python↔Haskell.
- Принцип JSON-Schema контрактов в `packages/contracts/`.

**Переписываем (~70% нового кода):**
- Domain scope (Person/Consultation/Solar workflow вместо анонимного транзит-запроса).
- Все output-DTO (текущие схемы заменяются новыми).
- API endpoints (с CRUD-моделью вместо single-shot).
- Frontend pages (новый UI flow вокруг клиента и соляра).
- Ruleset (v2 с расширенным доменом + Дараган-orbs контракт).
- Storage (новая SQLite-схема с persons/consultations/charts_cache).
- Расширения core: HouseSystem(Equal), OrbProfile, FixedStars, SolarReturn, TransitTable, расширенный Planet ADT.

Ключевой принцип последовательности: **сначала зелёный extended core, потом bridge с Phase 0 scope, потом Services, потом Frontend, потом integration**. Причина: core — источник истины вычислений; если он зелёный, всё остальное строится на твёрдом фундаменте.

**Реалистичное ожидание темпа:** Phase 0 — это масштаб ближе к full rewrite, чем к доработке. Worker-агенты не должны ожидать что «допишут пару модулей и запустят». См. § 8 «Что считается успехом» и оценки в `PHASE_0_TASKS.md`.

---

## 2. Последовательность миграции Phase 0

Phase 0 = минимальный vertical slice «создали Person → посчитали Solar → получили PDF». Точные задачи — в `PHASE_0_TASKS.md`. Здесь — только **порядок и параллелизация**.

```
         Блок A            Блок B              Блок C           Блок D         Блок E
    ┌────────────┐      ┌──────────┐       ┌────────────┐   ┌──────────┐   ┌──────────┐
    │  Cleanup   │  →   │  Core    │   →   │  Contracts │ → │ Services │ → │ Frontend │
    │            │      │  extended│       │   v2       │   │          │   │          │
    │  + Ruleset │      │          │       │            │   │          │   │          │
    │  v2 базово │      │          │       │            │   │          │   │          │
    └────────────┘      └──────────┘       └────────────┘   └──────────┘   └──────────┘
                                                                  ↓
                                                          ┌──────────────┐
                                                          │ Integration  │
                                                          │ + PDF шаблон │
                                                          │ + Golden     │
                                                          │   tests      │
                                                          └──────────────┘
```

### Блок A — Cleanup и подготовка (1-2 дня)

Убрать явный мусор перед тем как расширять:

- Удалить `core/astrology-hs/dist-newstyle/` из git + добавить в `.gitignore`.
- Удалить `services/orchestrator-python/` (мёртвый код).
- Удалить `core/astrology-hs/src/Adapters/Ephemeris/Swiss.hs` (отменён ADR-0001).
- Удалить `core/astrology-hs/src/Domain/Report.hs` (не используется).
- Удалить `packages/contracts/core-input.schema.json` (deprecated).
- Пометить `docs/architecture/adr-0001-python-ephemeris-bridge.md` как `Superseded by target-architecture.md`.
- Пометить `docs/agents/current-state-handoff.md` как `Archived 2026-04-24`.
- Создать базовые `.claude/architecture-invariants.md` + `.claude/corrections.md` в `astro/` с 7 bright lines из target-architecture.md.
- Схлопнуть `services/ephemeris-python/` и `services/pdf-python/` в `services/api-python/app/ephemeris/` и `services/api-python/app/pdf/`.
- Создать `ruleset-v2.0.0.json` с расширенным доменом + placeholder orbs + `daragan-orbs-v1.json` с TODO-заглушками.

Параллелизация: всё блока A делается одним агентом последовательно, это мелкие правки. Не стоит дёргать параллельно.

### Блок B — Core: расширение Haskell ядра (5-8 дней)

Параллельно, но с зависимостями:

**B.1** (основа, всё следующее зависит):
- Переписать `Domain.Types` с новыми newtypes (Longitude360 как newtype, JulianDay как newtype, OrbDegrees, SpeedDegPerDay), расширить ADT `Planet`, добавить `HouseSystem(EqualFromAsc)`, `OrbProfile`, `FixedStar FixedStarId`.

**B.2** (параллелится после B.1):
- `Domain.Aspects` — параметризовать через `OrbProfile`, брать orbs из передаваемого config (из snapshot'а).
- `Domain.Houses.Equal` — новый модуль с формулой equal-from-asc.
- `Domain.FixedStars` — новый модуль с `applyPrecession`.
- `Domain.SolarReturn` — новый модуль с bisection'ом по Sun-longitude.
- `Domain.TransitTable` — новый модуль для годовой таблицы транзитов по домам.

**B.3** (после B.1, B.2):
- `app/Main.hs` переписать как диспетчер workflow (сейчас только Solar): парсит `workflow` поле из input, вызывает соответствующий pipeline, сериализует output.
- Убрать дубликаты output-типов между `Domain.Types.AnalysisResult` и `Main.hs`. Оставить **один** источник — в dedicated модуле `Bridge.Solar` (или `app/Main.hs`, но тогда без параллельного `AnalysisResult` в Domain).

**B.4** (параллелится):
- Property tests в `test/` на инварианты (`desc = (asc+180) mod 360`, aspect orb ≤ max, sum house spans = 360).
- Переименовать `Test.Golden` в `Test.GoldenSolar` и заложить файл `test/golden/` для эталонов.

**Acceptance блока B:** `cabal build` + `cabal test` зелёные. Core ничего не знает про Phase 0 specifics (Person, Consultation, PDF).

### Блок C — Contracts v2 (1-2 дня)

Параллельно с блоком B (после B.1 достаточно для проектирования contracts).

- Переписать `packages/contracts/solar-resolved-input.schema.json` (бывший `core-resolved-input.schema.json`).
- Переписать `packages/contracts/solar-computed-facts.schema.json` (бывший `analysis-result.schema.json`).
- Переписать `packages/contracts/person.schema.json` (новый) и `packages/contracts/consultation.schema.json` (новый) — для API-DTO.
- Переписать `packages/test-fixtures/` — минимум 2 fixture-набора (средний случай + Заполярье).

**Acceptance блока C:** Schema валидна, fixture'ы проходят jsonschema-валидацию.

### Блок D — Services: API + DB + bridge + PDF (5-8 дней)

Порядок внутри:

**D.1** (основа):
- Storage: SQLite схема + миграции + CRUD persons/consultations.

**D.2** (параллелится):
- `ephemeris/bridge.py` — расширить на Nodes/Lilith/Chiron/Equal houses, добавить precession-эфемериды для фикс.звёзд.
- `ephemeris/fixed_stars.py` — hard-coded каталог топ-30 звёзд.
- `ephemeris/cache.py` — интеграция бывшего `ephemeris-python` loader'а.
- `core_client.py` — незначительные правки (добавить timeout, улучшить error channel).

**D.3** (после D.1, D.2):
- `main.py` — переписать endpoints: persons CRUD, consultations CRUD, compute, download PDF.
- `models.py` — pydantic под новые DTO, contract-test против JSON-Schema.
- `persons.py`, `consultations.py` — бизнес-логика endpoint'ов (orchestrate bridge → core → pdf).

**D.4** (параллелится):
- `pdf/templates/solar.html.j2` — новый шаблон под Phase 0 layout (натал, соляр, годовая таблица).
- `pdf/builder.py` — тот же WeasyPrint, возможно небольшая доработка CSS для печати.

**Acceptance блока D:** `uvicorn app.main:app` запускается; через `curl`/`httpie` можно создать Person, запустить compute (пусть с ожидающим фиксированным bridge-output), получить PDF.

### Блок E — Frontend (3-5 дней)

Порядок внутри:

**E.1**:
- Переписать `src/types.ts` под новые DTO.
- Переписать `src/api.ts` под новые endpoints.

**E.2** (параллелится):
- `src/pages/PersonList.tsx` — список клиентов с поиском.
- `src/pages/PersonForm.tsx` — форма создания/редактирования.
- `src/pages/PersonDetails.tsx` — карточка клиента.

**E.3**:
- `src/pages/ConsultationForm.tsx` — создание соляра (year picker + request_note).
- `src/pages/ConsultationView.tsx` — просмотр фактов.

**E.4**:
- Компоненты `NatalChartFacts`, `SolarChartFacts`, `AnnualTransitTable`.

**Acceptance блока E:** Весь UI-flow работает на mock-данных (frontend может независимо тестироваться через fixtures).

### Блок F — Integration + Golden tests (3-5 дней)

После блоков B, C, D, E:

**F.1**:
- End-to-end проверка: `run-local.sh` → открыть UI → создать Person → запустить расчёт → получить PDF.
- Пофиксить баги интеграции (почти гарантированно будут на первом проходе из-за ручных DTO).

**F.2**:
- Golden tests в Haskell-core: 3-5 реальных клиентов Марины — запросить у неё выгрузку из Zet9 (ФИО анонимизировать, данные рождения + натальные позиции/cusps из Zet9), зафиксировать как golden fixtures, cross-check с pyswisseph + core.

**F.3**:
- Property tests: `cabal test` включает инварианты.

**F.4**:
- `run-local.sh` — финальная полировка (cleanup старых артефактов, вывод user-friendly).

**Acceptance блока F (и Phase 0):** см. `PHASE_0_TASKS.md § Acceptance`.

---

## 3. Что параллелится

| Параллельно | Последовательно (зависимость) |
|---|---|
| B.2 ↔ B.4 (algo и tests) | B.1 → B.2, B.3 |
| B ↔ C | C зависит от B.1 (знание типов) |
| D.2 ↔ D.4 (bridge и PDF) | D.3 зависит от D.1, D.2 |
| E.2 ↔ E.3 ↔ E.4 (страницы и компоненты) | E.1 должен быть первым |
| F.1 ↔ F.2 ↔ F.3 | После всех B-E |

Расчёт: один агент последовательно — 17-30 дней работы. 2 агента параллельно (где допускается) — 12-20 дней. Это приблизительные ориентиры, не обязательство.

---

## 4. Early Evaluation Gate (критическая точка)

**Когда:** через ~3 месяца после старта Phase 0 (примерно 2026-07-24 при старте 2026-04-24).

**Что оцениваем:**

1. **Время compute** одного solar workflow — замер. Если > 10 сек регулярно — это триггер перехода на long-lived Haskell process (см. target-architecture.md § 8.1).
2. **Число разъездов типов** между слоями за 3 мес. Если ≥ 3 — триггер внедрения codegen pipeline.
3. **Число изменений core-домена** за 3 мес. Если > 10 — проверить что дисциплина bright lines держится (частые изменения Core — это либо расширение (ок), либо operational-данные просочились (плохо)).
4. **Использование Мариной.** Сколько реальных соляров она сделала через инструмент. Если 0 — проблема в удобстве, не в архитектуре, нужен UX-ревью.
5. **Золотые тесты против Zet9** — сколько клиентов покрыто. Если < 5 — добавить приоритет.

**Gate решения:**
- ✅ Архитектура работает → продолжаем к Phase 1 (дирекции, касания высших, книга).
- ⚠️ Частичные проблемы → внести corrections в `.claude/corrections.md`, затянуть bright lines, но не переписывать.
- ❌ Существенные проблемы (темп < ожидаемого, качество < Zet9, Марина не использует) → ревизия архитектуры. В крайнем случае — reverse migration Haskell → Python-only, если source of problems — обвязка.

### Escape hatch: reverse migration Haskell→Python

Если на evaluation gate окажется, что:
- Обвязка съедает > 40% времени разработки,
- Агенты регулярно делают типовые ошибки разъезда между слоями,
- Марина жалуется что каждая её новая идея («добавь X») идёт > недели,

— тогда документируем это в `.claude/corrections.md` и делаем сознательный выбор: портировать Haskell-core в Python за 2-3 недели, убрать subprocess-границу. Это **не провал**, это честное признание что инвестиция не окупилась.

Документируем этот escape hatch **заранее**, чтобы через 3 мес не было давления «мы уже столько вложили, нельзя откатывать».

---

## 5. Риски миграции и mitigation

| Риск | Вероятность | Impact | Mitigation |
|---|---|---|---|
| Агенты ломают Haskell-core правками | средняя | высокий | Property + golden tests как DoD; `-Werror -Wincomplete-patterns`; запрет catch-all patterns в corrections.md |
| Разъезд типов между слоями накапливается | высокая | средний | Contract-тесты (pydantic validate против JSON-Schema на каждый request); ручной ревью при изменении Schema |
| Дрейф границы «Python тоже считает» | высокая | высокий | Bright line #7 в architecture-invariants; ревью на вопрос «где это считается»; corrections.md с конкретными примерами |
| Ошибка в формуле Placidus / Equal / precession | средняя | критичный | Golden tests против Zet9 (минимум 3-5 клиентов); cross-check с astro.com для реперных значений |
| Марина просит фичу не из Phase 0 scope | высокая | средний | Фиксируем scope в PHASE_0_TASKS.md; новые фичи → Phase 1+ backlog |
| Оператор выгорает от двойного языка | низкая-средняя | высокий | Early evaluation gate; escape hatch на Python-only описан заранее |
| Swiss Ephemeris AGPL риск при расширении доступа | низкая в Phase 0 (solo-use) | средний | Изолированный `EphemerisEngine` интерфейс готов к Skyfield replacement |
| Заполярье / edge-cases широт не покрыты | средняя | высокий | Invariant fallback Placidus→Equal при `|lat| > 66.5°`; тест-кейс для реальной клиентки Марины (её данные из интервью) |
| Orbs Дарагана не заведены вовремя (оператор занят) | средняя | низкий | Phase 0 работает с placeholder orbs 6/8; правильные значения — апдейт после Phase 0, инфраструктура готова |

---

## 6. Что **не** в Phase 0 миграции (но резервируется)

Структуры, которые создаются в Phase 0 «пустыми», чтобы Phase 1+ не требовал реструктуризации:

- `core/astrology-hs/src/Domain/Directions.hs` — скелет модуля для Phase 1 дирекций.
- `services/api-python/app/interpretation/` — пустая директория для Phase 1+ rules engine.
- `services/api-python/app/book/` — пустая директория для Phase 1+ book-table workflow.
- `consultations.type` в SQLite уже поддерживает `'elective'` + Phase 1+ типы без миграции.
- `core_client.run_workflow(type, input)` поддерживает диспетчинг на несколько workflow, в Phase 0 только `solar` реализован.

Эти пустые каркасы — не «на вырост», а **дорога для следующего Phase** с минимальным структурным изменением.

---

## 7. Deploy-стратегия миграции

### Phase 0 deploy: dev на маке оператора

- `git clone` → `run-local.sh` → работает.
- SQLite в `./data/`.
- `.se1` файлы в `./data/ephemeris/` (одноразовый download).
- Оператор запускает, делает расчёты, пересылает PDF Марине.

### Phase 1 deploy: VPS

**Триггер:** Марина готова сама пользоваться → VPS + домен + auth.

**Что нужно:**
- VPS в РФ (Selectel/Timeweb/Croc).
- Domain + HTTPS (Let's Encrypt).
- Dockerfile'ы → docker-compose уже в репозитории (оставили из MVP).
- Single-user auth (cookie session с одним паролем из `.env`).
- Backup SQLite → ежедневный s3/b2-compatible storage.
- 152-ФЗ уведомление Роскомнадзора (оператор делает вне ПО).

Это **отдельный блок Phase 1**, не входит в Phase 0.

---

## 8. Что считается «успехом миграции»

- Worker-агент по `PHASE_0_TASKS.md` делает задачи последовательно/параллельно без уточняющих вопросов по архитектуре (только по локальным техническим деталям).
- Через N дней/недель запускается `run-local.sh`, открывается `localhost:3000`, оператор создаёт Person (клиент Марины), запускает Solar за 2026 год, получает PDF с 4 блоками (натал, соляр, аспекты, годовая таблица).
- Мрина/оператор смотрят PDF, сравнивают с Zet9-выводом на той же клиентке, расхождения в пределах допуска (или документированы как known issue).
- Марина делает первую live-консультацию с использованием PDF (открывает свою PDF-шпаргалку с правилами, смотрит факты из инструмента, пишет интерпретацию).
- Через 3 мес evaluation gate — зелёный или с corrections, без ревизии архитектуры.

Если все пять — Phase 0 успешен, переходим в Phase 1 (дирекции + касания высших + улучшения UX + возможно VPS).

---

## 9. Что **не** считается успехом

- PDF сгенерировался, но Марина не использует (UX-проблема — ревью).
- PDF не совпадает с Zet9 систематически — ошибка в core, не миграция.
- Половина кода — вспомогательные утилиты — over-engineering, пересмотреть scope.
- Каждое расширение домена идёт 2+ недели — обвязка не оптимальна, включать codegen досрочно.

---

## 10. Подпись

Этот план — **живой документ**. При отклонениях добавлять entries в `.claude/corrections.md` astro-проекта с пометкой `MIGRATION-N`. Major-отклонения → архитектурная сессия с оператором.
