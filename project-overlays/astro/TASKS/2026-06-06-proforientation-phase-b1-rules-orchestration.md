# TASK: proforientation-phase-b1-rules-orchestration

- Status: open
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: services (Python: правила-данные толкования + оркестрация runVocation + composer + endpoint; математики НЕТ — она в ядре)
- Risk tier: B (presentation/content; движок и контракт landed A1/A2; клиентский текст — гард no-Daragan-verbatim)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет — Tier B)

## Problem

Phase B1 эпика профориентации (мемо `ARCHITECTURE/proforientation-module-architecture-2026-06-06.md` §4.3–4.4). Phase A (ядро A1 `7dc313e` + schema-gate A2 `b7cf858`) дал `vocation` workflow: на натал+куспиды → топ-2–3 «планета+дом» + таблица факторов с **машинными ключами** (без текста). B1 добавляет **стадию 5 (толкование)** как редактируемые правила-данные + Python-оркестрацию + endpoint. **Выдача в PDF/UI — Phase B2.**

**Граница (критично):** математика и отбор — в ядре (bright line #7, A1). Python в B1 ТОЛЬКО: собирает вход из натала → ОДИН вызов `vocation` workflow → берёт ключи факторов → подставляет текст из правил-данных. Никакой значимость-логики в Python (AST-ARCH-1).

## Decisions (locked)
- **Толкование = правила-данные** в `packages/rulesets/vocation/` (JSON), которые **Марина правит сама**, без программиста. Базовый набор — **черновой**, помечен «правится Мариной».
- **Источник текста:** сигнификатор-маппинги из `RESEARCH/daragan-proforientation-method-extract.md` § 5 + Phase 0 HANDOFF (планета→сфера, дом→способ дохода, знак→сужение). **Парафраз, НЕ verbatim Дарагана** (гард). Полное толкование в голос Марины — отдельный трек после (TZ), черновик честно помечен «черновой, не финал».
- **Standalone per-person** (натальный анализ): endpoint `GET /persons/{id}/vocation`. Натал не меняется → можно не кэшировать (compute on demand, как возвраты).
- **Reuse:** натальный расчёт (как `build_returns_snapshot`/geocode-натал) + `run_core_analysis` subprocess (Phase D возвратов) с `workflow:"vocation"`.

## Scope

### B1.1 — Правила-данные толкования
`packages/rulesets/vocation/` (новые JSON, по образцу существующих `packages/rulesets/`):
- `planet_activity.json` — планета → сфера деятельности (Марс→спорт/борьба/соревнования; Венера→искусство/сцена/красота; Юпитер→право/преподавание/экспертиза; и т.д. — 10 планет). Парафраз § 5 + сигнификаторы Phase 0.
- `house_income_mode.json` — дом → способ дохода (X→успех/руководство/своё дело; II→работа на себя/талант напрямую; VI→найм/контракт; VIII→инвестиции/риск). Парафраз § 1.
- `sign_narrowing.json` — знак → сужение (водные→вода/море; огненные→активность; и т.д.) для уточнения.
- Шапка каждого файла: `"_note": "Черновой набор, правится Мариной; парафраз метода Дарагана, не финальный голос."`

### B1.2 — Оркестрация (`app/`)
- Хелпер: person natal (lat/lon/tz из БД) → натальные позиции + Placidus куспиды (reuse существующего натал-расчёта) → собрать `vocation-input` JSON (валиден против `vocation-input.schema.json`).
- ОДИН subprocess-вызов `run_core_analysis` с `workflow:"vocation"` → `vocation-output` (combos + factor_table). **Никакой math в Python.**

### B1.3 — Composer толкования
- На каждое из топ-2–3 сочетаний: взять planet + connected_houses (приоритетный, напр. X) + знак планеты из натала → собрать черновой текст из правил-данных: «[planet_activity] — [house_income_mode], уточнение: [sign_narrowing]». 2–3 коротких предложения. Честная рамка «черновое толкование».
- Подстановка по ключам факторов из output (не пере-вычислять).

### B1.4 — Endpoint
`GET /persons/{id}/vocation` → JSON: top combos + composed draft text + factor_table. Router (по образцу `app/api/returns.py`). Не писать в БД.

### B1.5 — Тесты
`services/api-python/tests/test_vocation_endpoint.py`:
- vocation-input собирается валидным против схемы.
- `GET /persons/4/vocation` → HTTP 200; топ-3 (Юпитер X→II / Венера / Солнце per A1).
- Composer даёт черновой текст с правильной сферой (Юпитер→экспертиза/право/преподавание; помечен «черновой»).
- **No-Daragan-verbatim guard:** проверить, что текст правил не копирует предложения книги дословно (парафраз).
- ОДИН subprocess-вызов (не серия); нет math в Python.

## Files
- new: `packages/rulesets/vocation/*.json` (3+ файла); `services/api-python/app/vocation_orchestration.py` (или по структуре); `services/api-python/app/api/vocation.py` (endpoint+router); `services/api-python/app/pdf/` composer helper (или в orchestration); `tests/test_vocation_endpoint.py`.
- modify: роутер-регистрация (`app/main.py`); возможно `app/ephemeris/bridge.py` (vocation-вход, аддитивно); `OPERATING/journal/2026-06.md`.
- delete: —

## Do not touch
- Ядро (`Domain.*`, `Bridge.*`, `Main.hs`) — A1/A2 closed.
- Контракт `vocation-*.schema.json` — set (A2). НЕ менять.
- Возвраты/соляр/synthesis/outer_cards.
- PDF-секция + UI-панель профориентации — **Phase B2** (только endpoint+правила+composer здесь).
- DB schema.
- **NO math/отбор в Python** (#7). **NO серии subprocess** (#6). **NO Daragan verbatim.** **NO выдача чернового текста за финал.** **NO LLM.**

## Acceptance
- [ ] Правила-данные `packages/rulesets/vocation/` (планета/дом/знак), помечены «правится Мариной», парафраз.
- [ ] Оркестрация: натал → vocation-input (валиден) → ОДИН вызов → output.
- [ ] Composer: топ-2–3 → черновой текст из правил (без пере-вычисления).
- [ ] `GET /persons/{id}/vocation` → 200; Marina топ-3 = Юпитер X→II/Венера/Солнце + черновой текст.
- [ ] No-Daragan-verbatim: текст парафраз, не копия.
- [ ] `pytest --tb=short -q` зелёный (existing + новые); один subprocess; нет math в Python.
- [ ] `cabal test` не затронут (спот). Один product commit; один overlay (HANDOFF+journal); push, parity.
- [ ] Reviewer: client-текст → TL inline-verify + проверка парафраза; внешний Reviewer optional (Tier B).

## STOP triggers
- Worker считает отбор/факторы в Python (а не из output ядра) → STOP (#7).
- Серия subprocess на расчёт → STOP (#6).
- Daragan verbatim в правилах → STOP. Черновик выдан за финал → STOP.
- Worker трогает ядро/контракт/возвраты, или делает PDF/UI (Phase B2) → STOP.
- Worker зашивает толкование в Python-код вместо правил-данных → STOP.

## Context
**Mode normal + Tier B.**
**Baseline:** product `b7cf858` (A2); `vocation` workflow готов (`echo '<vocation-input>' | core-cli` → output). pyswisseph venv; DB person 4.
**Cross-references:**
- `RESEARCH/daragan-proforientation-method-extract.md` § 1/5 (дома, сужение) + Phase 0 HANDOFF (сигнификатор-маппинги, страницы).
- `vocation-output.schema.json` (ключи факторов: `ruler_of_house_N`, `doryphoros`, `conj_or_harmonic_to_sun`, …).
- `app/api/returns.py` + Phase D возвратов (orchestration + один subprocess образец).
- `packages/rulesets/` (образец правил-данных).
**Не в scope:** Phase B2 (PDF-секция + UI-панель), полный голос Марины (отдельный трек).
**Ready: yes** — движок+контракт готовы, маппинги извлечены, образец (возвраты D) есть.
