# TASK: planet-returns-python-endpoint

- Status: done
- Ready: yes
- Date: 2026-05-24
- Project: astro
- Layer: services (Python: эфемеридный сэмплер + orchestration `returns`-workflow + FastAPI endpoint; схему НЕ трогаем — landed в Phase C)
- Risk tier: B (Services; sampling + subprocess-вызов Haskell + endpoint; математики аспектов НЕТ — делегируется в Core)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase D эпика «возвраты планет» (мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` § 3.2 / § 4). Phase B (`Domain.Returns`, `a1e0c75`) + Phase C (`returns` workflow контракт + `Bridge.Returns.runReturns` + Main dispatch, `37db1c2`) дали Core-движок и границу процесса. Теперь нужен **Python-слой**: собрать эфемеридный вход, вызвать `returns`-workflow Haskell, отдать JSON через endpoint.

**Граница слоёв (критично):** Python владеет ТОЛЬКО сырыми эфемеридами (pyswisseph) + сборкой входа + subprocess-вызовом Haskell + endpoint'ом. **Математика возвратов — в Haskell** (bright line #7). **Один snapshot** — все sample'ы собираются в один проход, ОДИН вызов Haskell (bright line #6).

## Decisions (locked, мемо)

- **Standalone per-person feature** (не привязан к consultation). Результат зависит от `as_of` (текущей даты) → **НЕ кэшируется в БД** (протухнет). Считается on-demand.
- **reference_date** = endpoint-параметр `as_of` (ISO), default = «сейчас» (серверное время) → конвертируется в `reference_jd`.
- **Per-planet окна/каденция** (мемо § 4): Луна ~35 дн / ~6ч; Солнце, Меркурий, Венера ~400 дн / daily; Марс ~800 дн / daily; Юпитер ~13 л / ~неделя; Сатурн ~30 л / ~10 дн; Уран ~85 л / coarse; Нептун ~166 л / coarse; Плутон ~249 л / coarse. Каденция выбирается так, чтобы угловой шаг был мал для брекетинга (Haskell бисекция уточняет → внешние можно грубо). Payload залогировать.
- **Геоцентрика, тропик, `FLG_SWIEPH|FLG_SPEED`** — та же конвенция, что существующий движок (Phase A это зафиксировал). Sidereal НЕ вводить.

## Scope

### D.1 — Эфемеридный сэмплер (`app/ephemeris/`)

Новая функция (рядом с существующим pyswisseph-кодом, по его образцу): по birth data + `reference_jd` →
- натальные позиции 10 планет (reuse существующего natal-расчёта если есть; иначе pyswisseph `calc_ut` тем же flagом),
- per-planet транзитные sample'ы `[(jd, lon, speed)]` вперёд от reference по § 4 окнам/каденции,
- сборка returns-input JSON (`workflow:"returns"`, `natal_positions`, `reference_jd`, `samples`, `meta`) — соответствует `packages/contracts/returns-input.schema.json`.

**НЕ вычислять** аспекты/пересечения/возвраты в Python (bright line #7).

### D.2 — Orchestration (вызов Haskell `returns`)

Reuse существующего паттерна вызова Haskell-CLI (тот, что используется для solar-workflow — найти helper, напр. в `app/ephemeris/bridge.py` или где runSolar зовётся). Передать returns-input JSON → получить returns-output JSON → распарсить. **ОДИН subprocess-вызов** (bright line #6). Workflow-поле = `"returns"` (Main.hs диспетчеризует).

### D.3 — Endpoint

`GET /persons/{id}/returns?as_of=<iso>` (default `as_of`=now):
- загрузить person birth data (lat/lon/tz — уже резолвлены в БД),
- `as_of` → `reference_jd`,
- D.1 сэмплер → D.2 Haskell → returns-output,
- вернуть JSON (returns-output как есть; JD остаются JD — конвертация в даты это Phase E).
- Зарегистрировать router (по образцу geocode/прочих endpoint'ов).
- **НЕ писать в БД** (on-demand, не кэшируется).

### D.4 — Тесты

`services/api-python/tests/` (новый файл, напр. `test_returns_endpoint.py`):
- Сэмплер: для person 4 (Марина) собирает валидный returns-input (проходит против `returns-input.schema.json`).
- Endpoint: `GET /persons/4/returns?as_of=2026-05-24` → HTTP 200, 10 планет в `returns[]`.
- Sanity (сверка с Phase A reference, overlay `3471e64`): Sun-return ≈ следующий ДР Марины; Saturn — серия проходов (pass_number); Нептун/Плутон `beyond_lifespan=true`.
- Payload-guard: размер собранных sample'ов залогирован/разумен.
- (Опц.) 404 на несуществующего person; default `as_of` работает.

## Files

- new:
  - `services/api-python/app/ephemeris/returns_sampler.py` (или по существующей структуре ephemeris-модуля).
  - `services/api-python/app/api/returns.py` (endpoint + router) — по образцу `app/api/geocode.py`.
  - `services/api-python/tests/test_returns_endpoint.py`.
- modify:
  - роутер-регистрация (где подключаются routers, напр. `app/main.py` / `app/api/__init__.py`).
  - возможно `app/ephemeris/bridge.py` (returns-вариант subprocess-вызова, additive).
  - `project-overlays/astro/STATUS_RU.md`.
- delete: —

## Do not touch

- `packages/contracts/*` — схема landed в Phase C, НЕ менять.
- Haskell core (`Domain.*`, `Bridge.*`, `app/Main.hs`) — Phase B/C closed.
- Solar compute path / consultations / synthesis / outer_cards / PDF.
- UI (frontend) — Phase E.
- DB schema / миграции (returns не кэшируется — таблиц не нужно).
- **NO математики аспектов/возвратов в Python** (bright line #7 — делегировать в Haskell).
- **NO серии subprocess-вызовов** (bright line #6 — один snapshot, один вызов).
- **NO кэширования returns в БД** (зависит от as_of).
- **NO sidereal** (геоцентрика тропик как движок).
- **NO LLM.**

## Acceptance

### Primary
- [ ] Сэмплер собирает returns-input, валидный против `returns-input.schema.json`.
- [ ] Per-planet окна/каденция per § 4; payload залогирован/разумен.
- [ ] Orchestration: ОДИН subprocess-вызов Haskell `returns`-workflow; output распарсен.
- [ ] `GET /persons/{id}/returns?as_of=` → HTTP 200, 10 планет в returns[].
- [ ] Sanity (Phase A parity): Sun ≈ ДР; Saturn серия; Нептун/Плутон beyond_lifespan.
- [ ] returns не пишется в БД (on-demand).

### Common
- [ ] `cabal test` не затронут (Haskell не менялся) — спот-проверка зелёный.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=short -q` — все зелёные (existing + новые returns-тесты), 0 failed.
- [ ] `git status --short` чисто для intended changes.
- [ ] Один product commit (sampler + endpoint + router + tests).
- [ ] Один overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity.
- [ ] Reviewer: optional (Tier B Services; математики нет — делегирована). TL inline-verify достаточно; Reviewer по усмотрению.

### Discipline
- [ ] NO aspect/return math в Python.
- [ ] NO >1 subprocess за расчёт.
- [ ] NO schema/Haskell/UI правок.
- [ ] NO DB-кэш returns.
- [ ] NO sidereal.
- [ ] NO LLM.

## STOP triggers

- Worker считает возвраты/аспекты/пересечения в Python (а не делегирует Haskell) → STOP (bright line #7).
- Worker делает серию subprocess-вызовов на один расчёт → STOP (bright line #6).
- Worker трогает контракт / Haskell core / Main.hs → STOP (Phase B/C closed).
- Worker кэширует returns в БД → STOP.
- Worker вводит sidereal или иную эфемеридную конвенцию → STOP.
- Worker лезет в UI/PDF → STOP (Phase E).

## Context

**Mode normal + Tier B.**

**Baseline:**
- Product main @ `37db1c2` (Phase C schema-gate CLOSED).
- Overlay master @ свежий.
- `returns` workflow готов: `echo '<returns-input json>' | <haskell-cli>` → returns-output (Main.hs dispatch).
- pyswisseph в `services/api-python/.venv`; API DB `/Users/ilya/Projects/astro/data/astro.db` (person 4 = Марина).
- Phase A reference числа: HANDOFF `HANDOFFS/archive/2026-05-24-worker-to-tl-planet-returns-stage0-empirical-proof.md` (Sun 2027-03-22, Saturn 2048 серия, и т.д.).

**Cross-references:**
- Мемо § 3.2 (Services), § 4 (окна/каденция).
- `packages/contracts/returns-input.schema.json` / `returns-output.schema.json` (Phase C) — формат вход/выход.
- `core/astrology-hs/app/Main.hs` — dispatch `returns` (как вызывать).
- Существующий solar-вызов Haskell-CLI (паттерн subprocess) — найти и reuse.
- `app/api/geocode.py` — образец endpoint + router.
- Phase A sampler-логика (throwaway-скрипты упоминались в HANDOFF) — как считал ближайший возврат.

**Не в scope:** UI-панель + PDF-секция (Phase E), JD→дата конвертация (Phase E), самоаспекты/куспиды/Lilith (волны 2-5).

**Ready: yes** — формат вход/выход locked (Phase C), окна/каденция в мемо § 4, движок готов. Доп. уточнений не требуется.
