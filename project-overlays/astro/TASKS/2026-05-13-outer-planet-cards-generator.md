# TASK: outer-planet-cards-generator

- Status: open
- Ready: no
- Date: 2026-05-13
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 4 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 4, § 4 архитектурное решение часть 4, § 6 Outer-planet structure + Outer-planet intervals, § 8 TASK 4). Цель — восстановить структуру outer-planet карточек по эталону Марины.

В эталоне Марины (`Соляр 2025-2026_5.pdf` pp. 17-22) для каждого outer-transit аспекта, который Марина считает «значимым» в этом соляре, есть отдельная **карточка** со структурой:

1. Заголовок карточки в форме «тр <Планета> в <Аспекте> c нат <Целью>» (e.g. «тр Уран в квадрате c нат Венерой»).
2. **Интервалы реализации** — таблица или bullet-list трёх касаний (1st direct → retrograde return → direct return), каждое со своими датами в формате `DD.MM.YYYY HH:MM (GMT+3) - DD.MM.YYYY HH:MM (GMT+3) — N-е касание`.
3. **Таблица «Золотое правило транзита»** — структурированная таблица с колонками «Естественная сигнификация планет», «Положение планеты в доме радикса», «Управление домами радикса», «Натальный дом, по которому идёт транзитная планета», и значениями для транзит / аспект / радикс (причина / способ / следствие).
4. **Психологический уровень** — описание внутреннего переживания/смысла.
5. **Событийный уровень** — описание во внешних обстоятельствах.

Для Натальи в эталоне три такие карточки:
- тр Уран в квадрате c нат Венерой (3 касания: 03.06.2025 — 12.07.2025; 02.11.2025 — 22.12.2025; 19.03.2026 — 30.04.2026)
- тр Нептун в квадрате c нат Юпитером (3 касания: 21.04.2026 — 28.09.2026; 21.02.2027 — 16.04.2027; 10.10.2027 — 16.02.2028)
- тр Нептун в квадрате c нат Нептуном (3 касания: 27.09.2024 — 12.10.2024; 31.01.2025 — 29.03.2025; 25.10.2025 — 24.01.2026)

Сейчас в PDF этой структуры **нет**. После Phase 1-3 у нас есть:
- календарь аспектов (короткие строки по месяцам) — это presentation для широкого набора, не deep-dive карточки;
- «Аспекты транзитных социальных и высших планет» как общий блок с pre-card дисскуссией.

Задача — добавить генератор outer-planet cards в `transit_themes.py` (или новый модуль) + render их в template после общего блока «Аспекты», но до календаря. Использовать `loop_transit_windows` view (Phase 3 reserved name) — карточкам нужен **full-loop horizon** включая касания за пределами солярного года (Нептун-Юпитер уходит до 2028, Нептун-Нептун начинается в 2024).

После закрытия TASK 4 → 11 xfail tests должны flip → passed (см. § Test contract).

## Scope discipline — какие именно карточки генерировать

**ТОЛЬКО** outer-transit aspects, которые Marina reference показывает как card. Для Натальи — те три, перечисленные выше.

**НЕ** генерировать карточку для:
- **`Уран 150° Юпитер`** — он в эталоне Марины присутствует только в календаре (стр. 23, строка июня-июля 2026), не в card-блоке. Остаётся календарным пунктом.
- Любого outer-transit aspect которого Marina reference не показывает как card.

**Identification rule** для карточек (выводимо из engine output):
- transit planet ∈ {Uranus, Neptune, Pluto};
- aspect ∈ {Conjunction, Square, Opposition, Trine, Sextile} (Marina-style major; Quincunx out);
- aspect intensity / Marina criterion: **3 касания (D → R → DR)** в `loop_transit_windows` view + значимый target (планета или Asc/MC).

Дополнительный фильтр (для NATALYA specifically — Worker уточняет через сверку с эталоном): **target ∈ значимые натальные точки**. Для Натальи — Венера (12 дом, очень indicated), Юпитер (стеллиум в Стрельце, ruler соляра), Нептун (Neptune square Neptune — generation transit).

Если engine эмитит outer-transit aspect 3-касания которого нет в Marina reference как карточка — **НЕ генерировать**. Worker формализует identification rule в HANDOFF и применяет его. Если rule даёт > 3 карточек для Натальи — обсуждать с TL до landing.

## Files

- new:
  - `services/api-python/app/pdf/outer_cards.py` — главный generator (alternative: extend `transit_themes.py` если Worker предпочитает; default — отдельный модуль для cleanliness). Содержит:
    - `identify_outer_cards(loop_transit_windows, natal_chart, marina_filter)` → list of card-eligible aspects.
    - `build_outer_card(planet, target, aspect, loop_data, natal_data, rulership_data)` → structured dict со всеми 5 секциями карточки.
    - Closed-dictionary text для:
      - aspect typology (Conjunction = «соединение», Square = «квадрат» etc.);
      - psychology level templates (per planet × aspect combinations Marina'иной reference);
      - event level templates (per Marina'иной reference).
  - `services/api-python/app/pdf/outer_cards_text.py` — closed-dictionary text для интерпретаций (psychology / event level). Worker может объединить с outer_cards.py если хочет (single-file модуль).

- modify:
  - `services/api-python/app/pdf/builder.py` — register `outer_cards` Jinja global; pass natal_chart + rulership data.
  - `services/api-python/app/pdf/templates/solar.html.j2` — render outer cards loop после блока «Аспекты транзитных социальных и высших планет», до «Календарь транзитных аспектов».
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — **unmark `@pytest.mark.xfail`** для 11 tests которые ожидают flip после Phase 4 (см. Test contract ниже). НЕ менять Phase 5/6 xfails.

- delete: —

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — Phase 4 is presentation-level.
- **`packages/contracts/`, `packages/rulesets/`, `packages/test-fixtures/`** — engine output stable.
- **Phase 1-3 artefacts**: `provenance.py`, `render_natalya.py`, `transit_themes.py` solar_year/loop view filters, `synthesis_themes.py` solar_year wiring — НЕ менять (Phase 3 baseline зафиксирован).
- **Календарь аспектов** в `transit_themes.py` (`transit_aspects_by_month`) — Phase 6 будет clipping; не трогать в этой задаче.
- **Quincunx в календаре** — Уран 150° Юпитер ОСТАЁТСЯ в календаре (Phase 1-3 baseline). НЕ переносить его в outer cards.
- **Other PDF sections** (Натальная карта, Солярная карта, Прогрессии, Дирекции, Wheel, Темы года) — out of scope.
- **TS types** (`apps/web-react/`) — Phase 4 presentation, не schema cascade.
- **Phase 5/6 xfail tags** — НЕ трогать.

## Acceptance

### Outer-planet structure (passing после landing TASK 4)

- [ ] В PDF Натальи присутствует **отдельный блок** outer-planet cards между «Аспекты транзитных социальных и высших планет» (общий блок) и «Календарь транзитных аспектов».
- [ ] Блок содержит **строго 3 карточки**:
  - «тр Уран в квадрате c нат Венерой»
  - «тр Нептун в квадрате c нат Юпитером»
  - «тр Нептун в квадрате c нат Нептуном»
- [ ] Каждая карточка содержит все 5 секций:
  1. Заголовок «тр <Planet> в <Aspect> c нат <Target>».
  2. Интервалы реализации (3 касания, формат Marina-style: `DD.MM.YYYY HH:MM (GMT+3) - DD.MM.YYYY HH:MM (GMT+3) — N-е касание`).
  3. Таблица «Золотое правило транзита» (структурированная, 4 строки + 4 колонки per Marina pp. 18, 20, 21).
  4. «Психологический уровень» (раздел с paragraph текста).
  5. «Событийный уровень» (раздел с paragraph текста).

### Outer-planet intervals (tolerance per § 6 architecture doc: ±2 дня на границы, строго 3 касания, строго D → R → DR)

- [ ] Уран ⬜ Венера: 3 интервала в карточке матчат reference в пределах ±2 дней. D → R → DR порядок.
- [ ] Нептун ⬜ Юпитер: 3 интервала матчат reference ±2 дней. D → R → DR.
- [ ] Нептун ⬜ Нептун: 3 интервала матчат reference ±2 дней. D → R → DR.

### Scope discipline

- [ ] **Карточка для Уран 150° Юпитер НЕ генерируется** — он остаётся в календаре, не в cards. Worker проверяет PDF на отсутствие card-блока для Уран-Юпитер.
- [ ] Только 3 outer card в PDF Натальи. Не 4, не 0.

### Test contract (Phase 4 xfail flips → passed)

После landing TASK 4 `pytest tests/test_natalya_transits_acceptance.py -v` показывает 11 xfail tests перешли в **passed**, Worker unmark'нул их декораторы:

Category 3 (outer-planet structure, 6 xfail Phase 4):
- `test_pdf_contains_uranus_square_venus_card` → passed
- `test_pdf_contains_neptune_square_jupiter_card` → passed
- `test_pdf_contains_neptune_square_neptune_card` → passed
- `test_each_outer_card_has_golden_rule_table` → passed
- `test_each_outer_card_has_psychology_level` → passed
- `test_each_outer_card_has_event_level` → passed

Category 4 (outer-planet intervals, 2 xfail Phase 4 — `Уран-Венера` already passing as regression guard):
- `test_neptune_square_jupiter_three_touches_tolerance_2d` → passed
- `test_neptune_square_neptune_three_touches_tolerance_2d` → passed

Category 7 (regression bans, 1 xfail Phase 4 + 1 should-stay-passing):
- `test_outer_cards_always_present_when_marina_shows_them` → passed (unmark xfail)
- Category 3 `test_pdf_contains_outer_transits_section_heading` — was passing already, must stay passing.

Phase 5/6 xfails остаются xfail. Worker не трогает их.

**Если Worker наблюдает xpass на тестах **ВНЕ** Phase 4 mapping (например, в Phase 5 или Phase 6) — это сигнал, investigate, НЕ unmark.**

### Common acceptance

- [ ] `cabal build` сделан (Phase 2 lesson) — даже если Path B не трогает core.
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green; ожидание `117+ passed + 6- xfailed` (Phase 4 flips увеличивают passed на 11 единиц, xfail уменьшают на 11).
- [ ] `git status --short` чисто **для intended product changes**.
- [ ] Один commit (или ≤ 2 при чистой границе: generator module отдельно от template wiring + tests unmark).
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C матрица — TL inline verifies сравнением PDF с эталоном Марины pp. 17-22.
- [ ] HANDOFF содержит:
  - identification rule что Worker применил (3 карточки только, не 4);
  - per-card render verification (extracted text proves каждая секция присутствует);
  - xfail flip status таблица (which tests flipped, Worker unmarked decorators);
  - example screenshot/extract от Marina reference vs нашего PDF для visual parity.

## Context

**Mode normal + Tier C** (presentation generator). Worker subagent. Reviewer subagent необязателен; TL inline visual verification после Worker'а.

**Baseline:** main @ `70185b0` (Phase 3 closed, Path B). Tests 106 passed + 17 xfailed.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 4 архитектурное решение часть 4 (`outer_transit_cards` model).
- § 5 Phase 4.
- § 6 Outer-planet structure + Outer-planet intervals — acceptance assertions.
- § 8 TASK 4 — formal spec.

**Marina reference (oracle):** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 17-22:
- p. 17 — типы аспектов (taxonomy intro перед card-блоком).
- p. 18 — карточка «тр Уран в квадрате c нат Венерой» + Золотое правило таблица + Психология/Событие.
- p. 19 — карточка «тр Нептун в квадрате c нат Юпитером» + таблица + уровни.
- p. 21 — карточка «тр Нептун в квадрате c нат Нептуном» + таблица + уровни.
- p. 22-23 — Календарь транзитных аспектов (это уже не cards).

Worker внимательно изучает эти страницы для understanding card format и content style. Marina-style psychology/event тексты — closed dictionary (не свободная prose, а constraint'нутые шаблоны).

**xfail flip discipline:** Phase 4 Worker при closing своего commit'а должен:
1. Запустить `pytest tests/test_natalya_transits_acceptance.py -v`.
2. Идентифицировать tests переход xfailed → xpassed.
3. **В том же commit** убрать `@pytest.mark.xfail` decorator с 11 Phase 4 mapping tests. Иначе strict xpass отвалит CI.
4. Если другой test (Phase 5/6) xpass'ит — investigate, не unmark.

**Cabal build hygiene:** работа Path B не трогает core, но `cabal build` рекомендуется перед тестами (Phase 2 lesson о stale cache).

**Default тон interpretations:** Marina psychology/event level в эталоне написан в **второй личной** форме («Аспект приносит внезапные перемены...»), сжато (2-4 предложения per уровень), без bizdev/metafизики. Worker сверяет тон с эталоном, не выдумывает свободную прозу.

**Ready: no** — TL flip'ает в `yes` после ack пользователя.
