# TASK: rulership-expanded-target-houses

- Status: open
- Ready: no
- Date: 2026-05-13
- Project: astro
- Layer: services
- Risk tier: C — with explicit Tier-A escalation rule if implementation lands in shared Haskell `Domain/` helper or becomes schema-visible field
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal — with Mode: strict escalation if Tier-A path chosen
- Critical approved by: (нет; при Tier-A escalation — открывается отдельный Tier A TASK с новым approval)

## Problem

Phase 5 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 5, § 4 архитектурное решение часть 3 — `transit_target_house_sets`, § 6 «Target houses», § 8 TASK 5). Цель — устранить root cause #4 из § 3 документа («Логика домов-целей не использует rulerships»).

Сейчас в календаре аспектов (`services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month`) поле «Дома цели» содержит **только натальный дом target планеты** (placement-only). Marina эталон (`Соляр 2025-2026_5.pdf` pp. 18, 20-21 «Золотое правило транзита» tables) показывает **расширенный house-set**: placement дома + дома, которыми target управляет через cusps своих signs.

Пример (Натальи): для аспекта `Уран 90° Венера` Marina показывает «Дома цели: 2, 3, 12» — Венера в 12 доме (placement), Венера управляет Тельцом (на куспиде 9 дома?) и Весами (на куспиде 2/3 домов?). У нас сейчас в календаре выводится только `12` (placement). Это потеря части информации.

Задача — реализовать **shared house-set helper** (placement ∪ rulerships) и переиспользовать его в:
- `transit_aspects_by_month` календарь («Дома цели»);
- `outer_cards.py` golden-rule таблицы (там сейчас closed card-facts per case_id — Phase 5 может частично или полностью заменить их через generic helper).

После closing → 4 Cat 6 Phase 5 xfail tests должны flip → passed (см. § Test contract).

## Two paths (Worker chooses, justifies in HANDOFF)

### Path A — Core-level (Haskell `Domain/` shared helper, Tier-A escalation)

Изменения в Haskell core:
- Новый модуль `Domain/RulershipHouses` (или extension существующего `Domain/Dignities` где уже есть `rulersOfSign`) — функция `rulershipHousesOf :: Planet -> HouseCusps -> [HouseNumber]`. Возвращает дома radix, на куспидах которых лежат signs, которыми planet rules (через `rulersOfSign` reverse logic + cusp-to-sign mapping).
- Engine output расширяется: каждая planet получает поле `rulership_houses: [int]` (или эквивалент) в `natal_chart` или `solar_chart`. **Schema cascade**.
- Python presentation использует engine-emitted данные через provenance-tracked pipeline.

**Эскалация в Tier A автоматическая** если этот path выбран. Mode strict. Отдельный Worker + Reviewer subagent. Schema cascade per bright-line #8. Atomic commit.

### Path B — Presentation-level Python helper (остаётся Tier C)

Engine output не меняется. Python helper:
- Новый модуль `services/api-python/app/pdf/rulership_houses.py` — `rulership_houses_for(planet: str, natal_chart: dict) → list[int]`. Читает natal house cusps, mapping cusp longitude → sign, lookup rulers per sign (closed dict — Sun=Leo, Moon=Cancer, Mercury=Gemini+Virgo, etc., с modern co-rulers Uranus=Aquarius, Neptune=Pisces, Pluto=Scorpio per Phase 0.4 lock-in).
- `target_house_set(target, natal_chart) → set[int]` = `{placement_house}` ∪ `rulership_houses_for(target, natal_chart)`.
- Используется в `transit_aspects_by_month` и `outer_cards.py`.

Schema не меняется. Tier C, Mode normal. Worker subagent один.

### Worker decision criteria

Worker анализирует и выбирает path, **обосновывая в HANDOFF** (минимум 3-5 предложений). Default TL: **Path B**, если нет сильного основания для Path A. Path A нужен если:
- Frontend / API consumers нуждаются в rulership houses через JSON contract.
- Несколько contexts (PDF + JSON output + tests) нуждаются в одной consistent logic, и Python derivation создаёт risk drift.

### Path A gating — STOP-and-escalate

Per Phase 3 prior pattern: **этот TASK авторизует Path B только.** Если Worker приходит к выводу что Path A нужен:

1. STOP — не начинать schema/core cascade.
2. Заполнить escalation memo в HANDOFF (Rationale, Files, Contracts touched, Reviewer requirement, Cost estimate).
3. Submit HANDOFF с `BLOCKED — Path A escalation memo`.
4. TL эскалирует пользователю; ждёт explicit go перед открытием нового Tier A TASK'а.

## Marina golden-rule reference (oracle для validation)

Worker валидирует house-set logic против Marina эталона `Соляр 2025-2026_5.pdf` pp. 18, 20-21 — три «Золотое правило транзита» таблицы для outer cards Натальи. Колонки:
- «Естественная сигнификация планет» — natal placement (planet → его дом радикса).
- «Управление домами радикса» — rulership houses (planet → дома радикса, на куспидах которых его signs).

Reference для Натальи (Worker сверяет с PDF):
- **Венера**: Marina таблица Уран ⬜ Венера показывает «Управление домами радикса: 2, 9» (Венера управляет Тельцом и Весами; Телец на куспиде 9 дома, Весы на куспиде 2 дома согласно её натальной карте Asc Дева).
- **Юпитер**: Marina таблица Нептун ⬜ Юпитер показывает «Управление домами радикса: 4, 7» (Юпитер управляет Стрельцом и Рыбами; Стрелец на куспиде 4 дома, Рыбы на куспиде 7 дома).
- **Нептун**: Marina таблица Нептун ⬜ Нептун показывает «Управление домами радикса: 4, 7» (Нептун управляет Рыбами; Рыбы на куспиде 7 дома; плюс co-ruler Юпитер через классическую rulership — Marina сохраняет современный rulership only).
- **Марс**: для календарных строк типа `Юпитер 120° Марс` — Marina показывает «Дома цели: 3, 8, 9» (Марс в 3 доме placement; управляет Овном и Скорпионом; Овен на куспиде 8 дома, Скорпион на куспиде 3 дома; placement 3 совпадает с rulership 3 — union {3, 8, 9}).

**Sign-to-cusp mapping для Натальи** (для Worker reference, чтобы валидировать helper output):
- Asc 12°22' Virgo (1 дом cusp on Virgo).
- Cusp 2 (Libra cusp at 4°46' Libra).
- Cusp 3 (Libra at 27°11' Libra — пограничный, Marina может считать на Libra).
- Cusp 4 (Sagittarius).
- Cusp 5 (Capricorn).
- Cusp 6 (Aquarius).
- Cusp 7 (Pisces, 12°22' Pisces).
- Cusp 8 (Aries).
- Cusp 9 (Taurus, 29°49' Taurus — позже сменится на Gemini).
- Cusp 10 (MC, 5°24' Gemini).
- Cusp 11 (Cancer).
- Cusp 12 (Leo).

Точное mapping (включая Sagittarius/Pisces на куспидах 4/7 для Юпитер/Нептун rulership) Worker валидирует через `08-natalya-2025-2026.expected.json:natal_chart.house_cusps` или эквивалент.

## Files

### Path B (presentation-level, authorized)

- new:
  - **`services/api-python/app/pdf/rulership_houses.py`** — новый модуль:
    - `PLANET_RULES: dict[str, set[str]]` — closed dict planet → set of signs ruled. Современная астрология (Phase 0.4 Архипова lock-in): Sun=Leo, Moon=Cancer, Mercury={Gemini, Virgo}, Venus={Taurus, Libra}, Mars={Aries, Scorpio (classical co-ruler с Pluto)}, Jupiter={Sagittarius, Pisces (classical co-ruler с Neptune)}, Saturn={Capricorn, Aquarius (classical co-ruler с Uranus)}, Uranus=Aquarius, Neptune=Pisces, Pluto=Scorpio. (Marina использует современный rulership, Worker валидирует).
    - `cusp_sign(cusp_longitude: float) → str` — utility.
    - `rulership_houses(planet: str, natal_cusps: list[float]) → list[int]` — для каждого dома radix (1-12) определить sign на куспиде; если planet rules этот sign — добавить дом в result.
    - `target_house_set(target: str, natal_chart: dict) → set[int]` — `{placement_house}` ∪ `rulership_houses(target, natal_cusps)`. Возвращает sorted list of ints.
- modify:
  - `services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month` — переключить «Дома цели» с placement-only на `target_house_set`. Импорт `from app.pdf.rulership_houses import target_house_set`. Update formatter с указанием домов в строке Marina-style: `Дома цели: 2 — деньги/ресурсы; 9 — вера/обучение/путешествия; 12 — уединение/тайны`.
  - `services/api-python/app/pdf/outer_cards.py:OUTER_CARD_FACTS` — **Worker решает**: либо оставить closed card-facts per case_id (Phase 4 baseline, golden-rule table values считаны визуально с Marina), либо заменить `transit_ruled` и `target_ruled` поля через `rulership_houses` generic helper. Если заменить — closed card-facts остаются только для `transit_h`, `target_h`, `walks` (которые не deriviable из rulership). Documented decision в HANDOFF.
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — **unmark `@pytest.mark.xfail`** для 4 Cat 6 Phase 5 tests (см. Test contract). НЕ unmark Phase 6 xfails.
- new (tests):
  - `services/api-python/tests/test_rulership_houses.py` — unit tests для helper'а. Минимум:
    - `test_planet_rules_table` — Sun → {Leo}; Mercury → {Gemini, Virgo}; Mars → {Aries, Scorpio}; etc.
    - `test_natalya_venus_ruled_houses_matches_marina` — для Натальи helper возвращает {2, 9} (или whatever Worker validates from natal cusps).
    - `test_natalya_jupiter_ruled_houses_matches_marina` — {4, 7}.
    - `test_natalya_neptune_ruled_houses_matches_marina` — {7} (если современный rulership only) или {7, ...} (если co-rulership counted).
    - `test_natalya_mars_ruled_houses_matches_marina` — для Юпитер 120° Марс validation, {3, 8} или whatever validates.

### Path A (engine-level, Tier-A — escalation only)

Worker НЕ начинает Path A без TL go. Если choosen — files would include `core/astrology-hs/src/Domain/{Dignities,RulershipHouses}.hs`, schema cascade, fixtures regen, etc. — но это **отдельная Tier A TASK после user decision**.

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — Path B remains pure-Python. Path A — отдельный TASK.
- **`packages/contracts/*.schema.json`** — schema стабилен.
- **`packages/rulesets/`** — orb config стабилен.
- **`packages/test-fixtures/`** — НЕ regen golden-cases без explicit need; engine output не меняется.
- **Phase 1-4 artefacts** (`provenance.py`, `render_natalya.py`, `transit_themes.py:solar_year_transits/loop_transit_windows`, `synthesis_themes.py:_solar_year_transit_table`, `outer_cards.py` core structure) — не менять Phase logic. Только wiring updates per § Files.
- **PDF templates beyond transit calendar / outer cards** — Натальная карта, Солярная карта, Прогрессии, Дирекции, Темы года, Wheel — out of scope.
- **`apps/web-react/src/types.ts`** — schema стабилен; Path A добавил бы TS types, но не Path B.
- **Phase 4b structured overrides** — не трогать; Phase 5 — отдельная concern (target houses), не связана с tolerance overrides.
- **Phase 6 xfails** (4 Cat 5 calendar clipping) — не трогать.
- **Phase 7 multi-case calibration** — задача после Phase 5/6 close.

## Acceptance

### Path decision

- [ ] Worker в HANDOFF фиксирует выбранный path (A или B) с обоснованием минимум 3-5 sentences. Если Path A — explicit Tier-A escalation memo + BLOCKED HANDOFF + STOP.

### Common acceptance (Path B authorized — Worker stays on this path)

- [ ] Helper `target_house_set(target, natal_chart)` возвращает sorted list of ints, включая placement house и rulership houses.
- [ ] Для Натальи (08-natalya-2025-2026):
  - Венера: `target_house_set` ⊇ {12 (placement), плюс ruled houses validated против Marina таблицы p. 18 «Управление домами радикса: 2, 9»}.
  - Юпитер: `target_house_set` ⊇ {4 (placement), 7 (ruled) per Marina p. 20}.
  - Нептун: `target_house_set` ⊇ {4 (placement), 7 (ruled) per Marina p. 21}.
  - Марс: `target_house_set` ⊇ {3 (placement), 3, 8 (ruled) per Marina calendar Юпитер 120° Марс «Дома цели: 3, 8, 9»}.
- [ ] Calendar `transit_aspects_by_month` строки Натальи показывают rulership-expanded house sets, не placement-only. Visual self-verify через render PDF.

### Test contract (Phase 5 xfail flips → passed)

После landing TASK 5 (Path B) `pytest tests/test_natalya_transits_acceptance.py -v` показывает **4 xfail tests перешли в passed**:

Category 6 (target houses, 3 xfail Phase 5):
- `test_target_houses_not_placement_only_for_multi_house_targets` → passed
- `test_uranus_square_venus_target_houses_match_marina_reference` → passed (или TUNE если Marina ref требует точного {2, 3, 12} а helper выдаёт {2, 9, 12} — Worker валидирует)
- `test_target_houses_distinguish_placement_from_rulership` → passed

Category 7 regression bans (1 xfail Phase 5):
- `test_target_houses_no_placement_only_regression` → passed

**Итого 4 xfail flips:** 3 (Cat 6) + 1 (Cat 7 regression) = 4. Phase 6 (4 Cat 5 calendar clipping) остаются xfail.

**Если Worker наблюдает xpass на тестах ВНЕ Phase 5 mapping (Phase 6 calendar) — это сигнал, investigate, НЕ unmark.**

### Unit tests для helper

- [ ] `services/api-python/tests/test_rulership_houses.py` создан с минимум 5 тестами:
  - `PLANET_RULES` shape и contents validation.
  - Natal-specific tests для Натальи: Венера ruled houses match Marina, Юпитер, Нептун, Марс.

### Engine + presentation parity check

- [ ] `cabal build` (Phase 2 lesson) — даже если core не трогается.
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green; ожидание `~119 passed + ~4 xfailed` (Phase 5 flips увеличивают passed на 4, xfailed уменьшают на 4: было 115/8 → стало 119/4 + новые helper tests).
- [ ] `git status --short` чисто для intended product changes.
- [ ] Один commit (или ≤2 при чистой границе: helper module отдельно от wiring + tests).
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verify через сверку target_house_set output с Marina эталоном для 4 planets (Венера, Юпитер, Нептун, Марс).
- [ ] HANDOFF содержит:
  - path decision rationale (минимум 3-5 sentences);
  - validation report (target_house_set output vs Marina reference per planet);
  - xfail flip status (4 unmarked Phase 5 tests).

### Scope discipline

- [ ] Path B: затронуты только `services/api-python/app/pdf/rulership_houses.py` (new), `services/api-python/app/pdf/transit_themes.py` (wiring), `services/api-python/app/pdf/outer_cards.py` (optional wiring), `services/api-python/tests/test_natalya_transits_acceptance.py` (xfail unmark), `services/api-python/tests/test_rulership_houses.py` (new).
- [ ] Engine, schema, fixtures, Haskell core — 0 lines changed.
- [ ] Phase 4b structured overrides не тронуты.
- [ ] Phase 6 xfails не тронуты.

## Context

**Mode normal + Tier C** на default Path B. **Tier A + Mode strict** на Path A (Worker escalates BLOCKED if path needed).

**Baseline:** main @ `d44d7c6` (Phase 4b closed). Tests `115 passed + 8 xfailed`. После Phase 5 expected: `~119 passed + ~4 xfailed`.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 4 архитектурное решение часть 3 (`transit_target_house_sets`).
- § 5 Phase 5.
- § 6 Target houses (acceptance assertions).
- § 8 TASK 5 — formal spec (зеркальная).

**Marina reference oracle:** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 18, 20-21 «Золотое правило транзита» таблицы для 3 outer cards Натальи. Дополнительно — календарные строки pp. 22-23 с «Дома цели» для quick-cross-validation.

**Natal data:** `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json:natal_chart.house_cusps` (or `natal_chart.cusps`) — sign mapping для validation rulership houses output.

**Phase 5 ⇄ Phase 4b boundary:** Phase 4b `outer_cards.py` uses closed card-facts (per case_id) для golden-rule values, including `transit_ruled` и `target_ruled` поля. Worker Phase 5 может либо (а) оставить closed card-facts как baseline (PT cards используют их, calendar использует new `target_house_set`), либо (б) заменить outer_cards.py rulership fields через new helper (consistent generic source). Worker decision documented в HANDOFF.

**Phase 6 на ожидании:** TL открывает TASK 6 (per-context cutoff policy) только после accept Phase 5.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 5 spec.
