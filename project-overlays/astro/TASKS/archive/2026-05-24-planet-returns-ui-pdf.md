# TASK: planet-returns-ui-pdf

- Status: done
- Ready: yes
- Date: 2026-05-24
- Project: astro
- Layer: mixed (frontend React UI-панель + services PDF Jinja/Python секция; presentation-only — нет math/schema/Haskell)
- Risk tier: B (presentation двух клиентских поверхностей; математика и контракт уже landed Phase B-D)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase E (финальная) эпика «возвраты планет» (мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` § 3.2/3.3). Phase B-D дали Core-движок (`a1e0c75`), контракт (`37db1c2`) и Python endpoint `GET /persons/{id}/returns` (`4bdf1b1`). Теперь — **видимая часть**: показать возвраты человеку.

Две поверхности (решение владельца «оба»):
1. **UI-панель** «Ближайшие возвраты» — live от сегодня (вводишь person → таблица дат).
2. **Секция в соляр-PDF** — reference = дата рендера.

Плюс **JD→дата** конвертация (контракт несёт JD — конвертация это презентация) и финальная **регрессия** (Phase F свёрнута сюда: соляр-PDF и существующие секции не сломаны).

## Decisions (locked, мемо + методология)

- **MVP = только даты** (+ окно действия). **БЕЗ глубоких трактовок** (Дараган-стайл пассажи — волна 4). Секция = факт-таблица: планета → ближайший возврат → окно → пометка. Это снимает конфликт с гардами «≤2 предложения» / «no Daragan verbatim» (их волна 4).
- **JD→дата = презентация на каждой стороне**: Python для PDF (reuse существующего JD→date хелпера, которым рендерится транзит-календарь), TS для UI. Контракт остаётся JD (НЕ добавлять ISO в схему).
- **Reference**: UI = live сегодня; PDF = дата рендера. Передаётся как `as_of`/render_jd.
- **Приоритет презентации** (Марина): акцент на 6 ключевых (Луна/Солнце/Венера/Марс/Юпитер/Сатурн). Меркурий вторично. Уран — пометка «раз в жизнь»; Нептун/Плутон (`beyond_lifespan`) — пометка «вне продолжительности жизни» / справочно.
- **Медленные = серия проходов**: рендер серии (Worker предлагает форму — все 3 прохода vs headline+диапазон; TL смотрит на живом PDF).
- **Reuse Phase D orchestration** для PDF: `build_returns_snapshot(person, render_jd)` → `run_core_analysis` (НЕ ходить в HTTP endpoint из PDF — звать функцию напрямую). ОДИН вызов.

## Scope

### E.1 — PDF секция (services)

- Хелпер в `services/api-python/app/pdf/` (по образцу прочих pdf-хелперов): на person + render_jd → reuse Phase D `build_returns_snapshot` + `run_core_analysis` → returns-output → форматирование таблицы (JD→дата через существующий хелпер; группировка/акцент 6 ключевых; пометки внешних; серия медленных).
- Jinja-блок в `templates/solar.html.j2`: новая секция «Ближайшие возвраты планет» (заголовок/формулировку Worker предлагает). Размещение Worker предлагает (рядом со справочными/календарными разделами) — TL смотрит на живом PDF.
- **НЕ дублировать** math; JD→дата reuse существующего хелпера.

### E.2 — UI-панель (frontend)

- API-клиент: `getPersonReturns(id, asOf?)` → `GET /persons/{id}/returns` (по образцу `geocodePlace`). Типы из `types.ts` (`ReturnsComputedFacts`/`PlanetReturn` — landed Phase C).
- Компонент-панель «Ближайшие возвраты»: для person → таблица (планета, ближайшая дата, окно, пометка). JD→дата в TS (reuse если есть JD-хелпер; иначе малый util). Live от сегодня (default as_of).
- Размещение в UI (карточка person / отдельная панель) Worker предлагает — TL смотрит.
- `tsc --noEmit` чисто; существующий UI-флоу не сломан.

### E.3 — Презентация (правила)

- Акцент 6 ключевых; Меркурий вторично; Уран «раз в жизнь»; Нептун/Плутон «вне продолжительности жизни».
- Серия медленных читаемо (форма — предложение Worker).
- Формат даты (напр. «22 марта 2027» или «22.03.2027») — Worker предлагает, единый в UI+PDF по возможности.
- Факт-таблица, без трактовочной воды.

### E.4 — Регрессия (Phase F свёрнута)

- Соляр-PDF существующие секции (распределение планет, темы, транзиты, итоги, справочные) — БЕЗ изменений (кроме добавленной returns-секции).
- `pytest` зелёный (existing + новые pdf/ui тесты для returns-секции).
- `cabal test` не затронут (Haskell не менялся) — спот-проверка.
- Живой рендер соляр-PDF Марины (consultation 15): returns-секция присутствует + корректна + существующие секции целы.

## Files

- new:
  - `services/api-python/app/pdf/returns_section.py` (или по структуре pdf-модуля).
  - frontend: компонент панели (напр. `apps/web-react/src/components/ReturnsPanel.tsx`) + API-клиент метод.
  - тесты: `services/api-python/tests/test_returns_section.py` (+ frontend-тест если конвенция есть).
- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2` (+ builder wire-up).
  - `apps/web-react/src/api.ts` (или где API-клиент) + где панель встраивается.
  - `project-overlays/astro/STATUS_RU.md`.
- delete: —

## Do not touch

- `packages/contracts/*` — схема set (Phase C). НЕ добавлять ISO-поля.
- Haskell core / Bridge / Main — Phase B/C closed.
- `app/ephemeris/returns_sampler.py` / `app/api/returns.py` — Phase D closed (reuse, не менять логику).
- Solar compute / synthesis / outer_cards / прочие PDF-секции (кроме добавления returns-блока).
- DB schema.
- **NO глубоких трактовок** (волна 4) — только факт-таблица.
- **NO Daragan verbatim.**
- **NO math/JD-детекции** в presentation (reuse).
- **NO LLM.**

## Acceptance

### Primary
- [ ] PDF: секция «Ближайшие возвраты» в соляр-PDF (reference = дата рендера); JD→дата корректно; 6 ключевых акцент; внешние с пометкой; серия медленных читаема.
- [ ] UI: панель «Ближайшие возвраты» (live), таблица 10 планет, JD→дата, пометки.
- [ ] PDF reuse Phase D orchestration (ОДИН вызов; не HTTP из PDF).
- [ ] Существующие соляр-секции не сломаны (живой рендер Марины).

### Common
- [ ] `pytest --tb=short -q` зелёный (existing + новые).
- [ ] `tsc --noEmit` чисто.
- [ ] `cabal test` спот-проверка зелёный (Haskell не тронут).
- [ ] `git status --short` чисто для intended.
- [ ] Один product commit (PDF + UI + tests).
- [ ] Один overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity.
- [ ] Reviewer: client-facing PDF/UI → TL inline-verify + живой осмотр PDF/UI. Внешний Reviewer optional.

### Discipline
- [ ] NO schema/Haskell/Phase-D-логики правок.
- [ ] NO глубоких трактовок / Daragan verbatim.
- [ ] NO math в presentation.
- [ ] NO LLM.

## STOP triggers

- Worker добавляет ISO-поля в контракт → STOP (JD→дата это presentation).
- Worker дублирует return/JD-математику в presentation → STOP (reuse).
- Worker меняет Haskell / контракт / Phase D логику → STOP.
- Worker пишет глубокие трактовки / копирует Дарагана → STOP (волна 4).
- Worker ломает существующие соляр-секции → STOP.
- Worker зовёт HTTP endpoint из PDF-рендера (вместо прямой функции) → STOP.

## Context

**Mode normal + Tier B (presentation).**

**Baseline:**
- Product main @ `4bdf1b1` (Phase D CLOSED).
- Overlay master @ свежий.
- Endpoint `GET /persons/4/returns` работает; `build_returns_snapshot` + `run_core_analysis` (Phase D) — reuse для PDF.
- pytest 715/3/0; tsc clean; cabal 279/0 — baseline зелёные.
- Марина = person 4 / consultation 15 (для живого PDF).

**Cross-references:**
- Мемо § 3.2/3.3 (presentation), § 0.1/0.2 (приоритет 6 ключевых, пометки).
- `app/api/returns.py` + `app/ephemeris/returns_sampler.py` (Phase D) — reuse.
- `apps/web-react/src/types.ts` `ReturnsComputedFacts`/`PlanetReturn` (Phase C).
- `app/pdf/templates/solar.html.j2` + builder — образец секции + JD→date хелпер (транзит-календарь рендерит JD).
- `app/api/geocode.py` + frontend `geocodePlace` — образец API-клиента/панели.
- Phase A reference (Марина): Sun 2027-03-22, Saturn 2048-серия, внешние beyond-life.

**Не в scope:** самоаспекты/куспиды (волны 2-3), глубокие трактовки (волна 4), Lilith (волна 5).

**Ready: yes** — данные/endpoint/типы landed; презентация в мемо; трактовки отложены (факт-таблица). Презентационные мелочи (формат даты, размещение, форма серии) — Worker предлагает, TL смотрит на живом рендере.
