# TASK: outer-planet-cards-generator

- Status: open
- Ready: yes
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

После закрытия TASK 4 → **7 xfail tests** должны flip → passed (см. § Test contract).

**Phase 4 scope correction (после preflight BLOCKED 2026-05-13, TL Path 3 decision):** Engine эмитит hits **по одному per motion phase** внутри orb-окна, а не per окно. Для медленных планет (Нептун) одно orb-окно содержит несколько фаз — Marina'ы «3 касания» = «3 display windows», не «3 raw hits». Test contract `_assert_three_phase_intervals` имеет design gap (Phase 2 erratum). **TL Path 3 decision:** Phase 4 строит карточки с консолидацией raw hits в display windows best-effort (для PDF parity), но **НЕ закрывает Category 4 Neptune interval xfails** — они остаются xfail до отдельного TASK 4a про contact-window semantics. Phase 4 acceptance: 7 xfail flips (6 Cat 3 структура + 1 Cat 7 regression ban), не 9.

**Жёсткие запреты Path 3:**
- НЕ модифицировать `_assert_three_phase_intervals` (Path 1 маскирует проблему — 178d Neptune-Neptune window 1 shift останется).
- НЕ хардкодить Marina-date overrides в production code (`outer_cards.py` или другие). Карточки строятся **из engine output путём агрегации** raw hits в display windows. Date parity с Marina по Нептуну **не гарантируется** в этой задаче.
- НЕ перезаписывать `expected.json` для «подгонки» под Marina даты.
- НЕ unmark Category 4 xfails (`test_neptune_square_jupiter_three_touches_tolerance_2d`, `test_neptune_square_neptune_three_touches_tolerance_2d`) — они остаются `@pytest.mark.xfail(strict=True)` с **обновлённым reason**: `"TASK 4a — Neptune slow-loop contact window semantics"`.

**Aggregation logic для карточек (best-effort, без overrides):**
- Каждая карточка показывает **3 display windows** (это что Marina показывает в эталоне).
- Worker группирует raw hits engine output по уникальным `(orb_enter, orb_exit)` тuples → unique windows.
- Если unique_windows = 3 (e.g. Нептун-Юпитер, Нептун-Нептун) — отлично, ровно 3 окна в карточке.
- Если unique_windows ≠ 3 (например, engine эмитит 4 уникальных окна для какого-то аспекта) — это **сигнал**, Worker фиксирует в HANDOFF, может потребоваться корректировка allowlist или дополнительная aggregation logic для конкретного случая.
- Phase order (D/R/DR) показывается как **set of phases per window** (one display window может содержать `[Direct, Retrograde]` или просто `[DirectReturn]` — это OK).

## Scope discipline — какие именно карточки генерировать

**Allowlist-based selection.** Для Натальи генерируются **строго эти 3 triples** (planet, aspect, target):

1. `(Uranus, Square, Venus)` — Уран ⬜ Венера.
2. `(Neptune, Square, Jupiter)` — Нептун ⬜ Юпитер.
3. `(Neptune, Square, Neptune)` — Нептун ⬜ Нептун.

Любой другой outer-transit aspect — **в карточки не идёт**. Особо:

- **`(Uranus, Quincunx, Jupiter)`** (Уран 150° Юпитер) — остаётся **только в календаре** (Marina эталон показывает его на стр. 23 в календарной строке июня-июля 2026, **не в card-блоке**). Worker не создаёт карточку для этого аспекта.

**Allowlist-config:** Worker реализует allowlist как явный configuration (per case_id) — например, dict `OUTER_CARD_ALLOWLIST = {"08-natalya-2025-2026": [...]}`. Так разные case'ы получат свои списки в Phase 7 calibration без переписывания generator'а.

**Generic detector — auxiliary, не extending list.** Worker может реализовать generic detector (transit planet ∈ {Uranus, Neptune, Pluto}, aspect ∈ Marina-major, 3 касания D→R→DR в loop_transit_windows) для понимания engine output и self-check. Но **generic detector НЕ расширяет allowlist** — это два разных concept'а:

- **Allowlist** = что Marina показывает как card.
- **Generic detector** = что engine эмитит как 3-passes outer-transit aspect.

Detector может найти больше aspects чем allowlist (например, Uranus 150° Jupiter — у нас в engine есть 3 касания, но Marina не показывает как card). В этом случае detector НЕ перекрывает allowlist — allowlist primary, detector только для diagnostic покрытия в HANDOFF.

Если generic detector находит aspect **не в allowlist** для Натальи — это **сигнал** (engine эмитит того что Marina не считает card-worthy), Worker отмечает в HANDOFF но **не создаёт карточку**.

## Files

- new:
  - **`services/api-python/app/pdf/outer_cards.py`** — **обязательно отдельный модуль**, не extension `transit_themes.py`. `transit_themes.py` это Phase 3 artifact, дополнительные правки в нём — лишний риск. Worker может **импортировать** публичные helpers из `transit_themes` (например `loop_transit_windows`, `_solar_year_jd_window` если оно publicly exported), но НЕ модифицирует `transit_themes.py`.

    Модуль содержит:
    - `OUTER_CARD_ALLOWLIST: dict[str, list[tuple[str, str, str]]]` — explicit per-case allowlist. Для `08-natalya-2025-2026` — 3 triples перечисленных выше.
    - `identify_cards_for_case(case_id, annual_transit_table) → list[tuple]` — читает allowlist для case_id, фильтрует engine output, возвращает eligible triples с loop data.
    - `build_outer_card(triple, loop_data, natal_data, golden_rule_facts) → dict` — структурированный dict со всеми 5 секциями карточки.
    - **Closed-dictionary text** для интерпретаций (psychology / event level) — **Marina-style paraphrase** (NOT verbatim chunks из эталона); 2-4 предложения per уровень, в Marina's второй-личной форме, без свободной prose.
  - `services/api-python/app/pdf/outer_cards_text.py` (опционально, Worker выбирает) — closed-dictionary text если выделяется в отдельный модуль для cleanliness. Если объединено с `outer_cards.py` — этот файл не нужен.

- modify:
  - `services/api-python/app/pdf/builder.py` — register `outer_cards` Jinja global; pass natal_chart данные для рендера карточек.
  - `services/api-python/app/pdf/templates/solar.html.j2` — render outer cards loop после блока «Аспекты транзитных социальных и высших планет», до «Календарь транзитных аспектов».
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — **unmark `@pytest.mark.xfail`** для **9 tests** которые flip после Phase 4 (см. Test contract ниже). **НЕ менять Phase 5/6 xfails** — особенно Phase 5 target-house xfails остаются untouched.

**Запрет на `transit_themes.py` modifications:** новые правки в нём — out of scope для TASK 4. Phase 3 baseline зафиксирован.

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

### Test contract (Phase 4 xfail flips → passed) — Path 3 scope

После landing TASK 4 `pytest tests/test_natalya_transits_acceptance.py -v` показывает **7 xfail tests** перешли в **passed**, Worker unmark'нул их декораторы:

Category 3 (outer-planet structure, 6 xfail Phase 4):
- `test_pdf_contains_uranus_square_venus_card` → passed
- `test_pdf_contains_neptune_square_jupiter_card` → passed
- `test_pdf_contains_neptune_square_neptune_card` → passed
- `test_each_outer_card_has_golden_rule_table` → passed
- `test_each_outer_card_has_psychology_level` → passed
- `test_each_outer_card_has_event_level` → passed

Category 7 (regression bans, 1 xfail Phase 4):
- `test_outer_cards_always_present_when_marina_shows_them` → passed (unmark xfail)
- (Category 3 `test_pdf_contains_outer_transits_section_heading` — was passing already, остаётся passing.)

**Категория 4 (Neptune interval tests) — ОСТАЁТСЯ XFAIL** per Path 3 decision:
- `test_neptune_square_jupiter_three_touches_tolerance_2d` — xfail остаётся; reason обновить: `"TASK 4a — Neptune slow-loop contact window semantics"`.
- `test_neptune_square_neptune_three_touches_tolerance_2d` — xfail остаётся; reason обновить: то же.
- Worker **только обновляет `reason` строку** в декораторах; **не unmark, не fix**.
- `test_uranus_square_venus_three_touches_tolerance_2d` — это уже passing (regression guard), не трогать.

**Итого 7 xfail flips:** 6 (Cat 3) + 1 (Cat 7 regression ban) = 7. Phase 5/6 xfails + Category 4 Neptune intervals **остаются xfail**. Worker НЕ трогает их (только обновляет reason text у 2 Neptune tests).

**Phase 5 target-house xfails — особое внимание:** golden-rule таблица каждой карточки содержит ссылки на дома (radix дома цели, ruled дома). Worker реализует их через **closed card-facts (per case_id)** из Marina oracle pp. 18/20/21 — НЕ через generic rulership-expanded helper (это работа Phase 5). Поэтому Phase 5 xfails (`test_target_houses_not_placement_only_for_multi_house_targets`, `test_target_houses_distinguish_placement_from_rulership` и др.) остаются xfail — они проверяют generic API surface, который Phase 4 не строит.

**Если Worker наблюдает xpass на тестах ВНЕ Phase 4 mapping (Phase 5, Phase 6, или Category 4 Neptune intervals) — это сигнал, investigate, НЕ unmark.**

### Preflight check для Neptune interval tests (Category 4)

Два xfail-теста — `test_neptune_square_jupiter_three_touches_tolerance_2d` и `test_neptune_square_neptune_three_touches_tolerance_2d` — читают **fact-level данные** из engine output (loop_transit_windows → annual_transit_table). Прежде чем строить карточку и unmark эти xfail-теги, Worker делает **preflight check**:

1. Запустить `pytest tests/test_natalya_transits_acceptance.py::test_neptune_square_jupiter_three_touches_tolerance_2d --runxfail -v` — увидеть actual failure trace.
2. Запустить `pytest tests/test_natalya_transits_acceptance.py::test_neptune_square_neptune_three_touches_tolerance_2d --runxfail -v` — увидеть actual failure trace.
3. Анализ failure:
   - **Если факты есть в engine output (annual_transit_table содержит 3 касания с правильными датами в пределах ±2 дня от reference) и провал теста — только в presentation layer**: продолжать Phase 4, fix presentation, unmark xfail.
   - **Если факты в engine output не совпадают с reference** (например, engine эмитит 5 touches вместо 3, или даты вне ±2 дней, или порядок фаз не D→R→DR): **STOP**. Это **contract mismatch на engine/facts уровне**, НЕ Phase 4 presentation. Worker заполняет **contract-mismatch memo** в HANDOFF:
     - Какие именно факты engine эмитит (raw из annual_transit_table).
     - Что ожидает Marina reference.
     - Гипотеза о root cause (orb width? sample window? clipping? quincunx scope?).
     - Recommendation: separate Tier A/Tier C TASK для engine adjustment.
   - Submit HANDOFF с `BLOCKED — Phase 4 contract mismatch (Neptune intervals)`.
   - **Worker НЕ исправляет contract mismatch хардкодом** в presentation, НЕ перезаписывает `expected.json`.

Запрет § 7 архитектурного документа явен: «Не перезаписывать `expected.json`», «Не считать зелёные snapshot tests достаточным доказательством близости к Марине». Worker Phase 4 — presentation layer. Если facts нарушены — это другая task'а.

### Common acceptance

- [ ] `cabal build` сделан (Phase 2 lesson) — даже если presentation-only не трогает core.
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green; ожидание `~113 passed + ~10 xfailed` (Phase 4 flips увеличивают passed на 7 единиц, xfailed уменьшают на 7: было 106 passed + 17 xfailed → стало 113 passed + 10 xfailed; 2 Neptune Cat 4 остаются xfail).
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

**Default тон interpretations:** Marina psychology/event level в эталоне написан в **второй личной** форме («Аспект приносит внезапные перемены...»), сжато (2-4 предложения per уровень), без bizdev/метафизики. Тексты — **Marina-style paraphrase**, **НЕ дословные куски** из эталона (IP discipline + closed-dictionary дизайн). Worker сверяет тон с эталоном, не выдумывает свободную прозу.

**Не смешивать Phase 4 и Phase 5.** Phase 4 владеет outer card structure + closed card-facts per case (включая дома цели в golden-rule таблице для 3 карточек Натальи). Phase 5 владеет **generalized rulership-expanded `Дома цели`** для календаря аспектов и любых других контекстов. Если Phase 4 Worker нашёл что нужна generic rulership API — STOP, открываем Phase 5 первым через TL. Phase 5 xfail-теги (`test_target_houses_*`) остаются untouched в Phase 4.

**Ready: no** — TL flip'ает в `yes` после ack пользователя.
