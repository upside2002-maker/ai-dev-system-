# TASK: rulership-expanded-target-houses

- Status: done
- Ready: yes
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

Phase 5 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 5, § 4 архитектурное решение часть 3 — `transit_target_house_sets`, § 6 «Target houses», § 8 TASK 5). Цель — устранить root cause #4 из § 3 документа («Логика домов-целей не использует rulerships»), **scope = calendar только**.

Сейчас в календаре аспектов (`services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month` + рендер в `solar.html.j2`) поле «Дома цели» содержит **только натальный дом target планеты** (placement-only). Marina эталон показывает **расширенный house-set** в календаре (pp. 22-23): placement дома + дома, которыми target управляет через cusps своих signs (включая **repeated cusp signs** — sign может встретиться на нескольких consecutive cusps).

**Calendar oracle для Натальи (Marina pp. 22-23, validated reference sets):**
- `Уран 90° Венера` → `{2, 3, 12}` (Venus placement = 12; Venus rules Libra; Libra на cusps 2 и 3 — repeated).
- `Нептун 90° Юпитер` → `{4, 7}` (Jupiter placement = 4; Jupiter rules Sagittarius cusp 4 + Pisces cusp 7).
- `Нептун 90° Нептун` → `{4, 7}` (Neptune placement = 4; Neptune rules Pisces cusp 7).
- `Юпитер 120° Марс` / `Сатурн 120° Марс` → `{3, 8, 9}` (Mars placement = 3; Mars rules Aries; Aries на cusps 8 и 9 — repeated, cusp 9 = `29°48' Aries` всё ещё Aries).

**Calendar vs Golden-rule semantics — две разные единицы.** В Phase 4 outer cards `outer_cards.py` уже использует **closed card-facts per case_id** для golden-rule таблиц (выверено визуально с Marina pp. 18, 20-21). Эти golden-rule values отличаются от calendar `Дома цели`:
- Уран-Венера golden-rule table даёт Venus ruled houses = `{2, 9}` (только rulership, без placement; Marina convention для этой таблицы).
- Уран-Венера calendar даёт Venus target = `{2, 3, 12}` (placement ∪ rulership с repeated cusps).

**Phase 5 авторизует ТОЛЬКО calendar `Дома цели`.** `outer_cards.py` НЕ трогается — closed card-facts оставляются как Phase 4 baseline (они правильные для golden-rule semantic; trogание создаст regression). Generic helper применяется **только** для calendar context.

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
- Используется **только** в `transit_aspects_by_month` (calendar context). `outer_cards.py` НЕ трогается — Phase 4 closed card-facts остаются для golden-rule semantic.

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

## Marina calendar reference (oracle для validation)

Worker валидирует helper output против Marina **календаря** `Соляр 2025-2026_5.pdf` pp. 22-23 (строки типа «Уран 90° Венера ... → Дома цели: 2, 3, 12»).

**Validated calendar target sets для Натальи (golden):**
- `Уран 90° Венера` → `{2, 3, 12}`
- `Нептун 90° Юпитер` → `{4, 7}`
- `Нептун 90° Нептун` → `{4, 7}`
- `Юпитер 120° Марс` → `{3, 8, 9}`
- `Сатурн 120° Марс` → `{3, 8, 9}`

**Sign-to-cusp mapping для Натальи** (валидировано против `08-natalya-2025-2026.expected.json:natal_chart.house_systems.Placidus.cusps`):

| Дом | Cusp | Sign |
|---|---|---|
| 1 (Asc) | 12°22' Virgo | Virgo |
| 2 | 4°46' Libra | **Libra** |
| 3 | 27°11' Libra | **Libra** (repeated — cusp всё ещё Libra) |
| 4 (IC) | ?° Sagittarius | **Sagittarius** |
| 5 | ?° Capricorn | Capricorn |
| 6 | ?° Aquarius | Aquarius |
| 7 (Dsc) | 12°22' Pisces | **Pisces** |
| 8 | ?° Aries | **Aries** |
| 9 | **29°48' Aries** | **Aries** (repeated — cusp ещё на Aries, не Taurus) |
| 10 (MC) | 5°24' Gemini | Gemini |
| 11 | ?° Cancer | Cancer |
| 12 | ?° Leo | Leo |

(Worker заполняет пропущенные cusp значения из expected.json при validation.)

**Derivation rule per planet (modern rulership, Marina convention):**
- **Venus** rules Taurus + Libra → Libra на cusps 2, 3 → ruled `{2, 3}`. Placement = 12. Calendar set = `{2, 3, 12}`. ✓
- **Mars** rules Aries + Scorpio (classical co-ruler Pluto) → Aries на cusps 8, 9; Scorpio не присутствует на cusps → ruled `{8, 9}`. Placement = 3. Calendar set = `{3, 8, 9}`. ✓
- **Jupiter** rules Sagittarius + Pisces (classical co-ruler Neptune) → Sagittarius на cusp 4, Pisces на cusp 7 → ruled `{4, 7}`. Placement = 4. Calendar set = `{4, 7}` (placement 4 dedup'нут в union). ✓
- **Neptune** rules Pisces → Pisces на cusp 7 → ruled `{7}`. Placement = 4. Calendar set = `{4, 7}`. ✓

**Critical observation про repeated cusp signs:** Один и тот же sign может встречаться на нескольких consecutive cusps (Libra на 2/3, Aries на 8/9 у Натальи из-за inequality Placidus houses). Helper должен включать **все** дома, на куспидах которых лежит ruled sign — не только первый.

## Files

### Path B (presentation-level, authorized) — calendar only

- new:
  - **`services/api-python/app/pdf/rulership_houses.py`** — новый модуль:
    - `PLANET_RULES: dict[str, set[str]]` — closed dict planet → set of signs ruled. Современная астрология (Phase 0.4 Архипова lock-in): Sun={Leo}, Moon={Cancer}, Mercury={Gemini, Virgo}, Venus={Taurus, Libra}, Mars={Aries, Scorpio (classical co-ruler с Pluto)}, Jupiter={Sagittarius, Pisces (classical co-ruler с Neptune)}, Saturn={Capricorn, Aquarius (classical co-ruler с Uranus)}, Uranus={Aquarius}, Neptune={Pisces}, Pluto={Scorpio}. (Marina использует современный rulership, Worker валидирует).
    - `cusp_sign(cusp_longitude: float) → str` — utility (longitude % 360 → sign из 30°-bucket).
    - `rulership_houses(planet: str, natal_cusps: list[float]) → list[int]` — для каждого дома radix (1-12) определить sign на куспиде; если planet rules этот sign — добавить дом в result. **Включает repeated cusps** (e.g. если Aries встречается на cusps 8 и 9 — оба дома в result).
    - `target_house_set(target: str, natal_chart: dict) → list[int]` — `{placement_house}` ∪ `rulership_houses(target, natal_cusps)`. Возвращает sorted list of ints (dedup'нутый union).
  - **Cusps access path:** `natal_chart["house_systems"]["Placidus"]["cusps"]` (список из 12 longitudes). **НЕ** `natal_chart.house_cusps` (этого пути нет в JSON). Worker валидирует через `08-natalya-2025-2026.expected.json` schema.
- modify:
  - `services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month` — переключить «Дома цели» с placement-only на `target_house_set`. **Signature update authorized**: function сейчас получает `natal_positions`; нужен дополнительный параметр `natal_chart` или `natal_cusps` (Worker выбирает minimum-disruption form). Импорт `from app.pdf.rulership_houses import target_house_set`. Update formatter с указанием домов в строке Marina-style: `Дома цели: 2 — деньги/ресурсы; 3 — общение/поездки/документы/курсы; 12 — уединение/тайны`.
  - **`services/api-python/app/pdf/templates/solar.html.j2`** — **explicitly authorized**. Template сейчас рендерит только `e.target_house` (singular int). После Phase 5 entry получает `target_houses` (sorted list of ints) либо preformatted string. Worker выбирает: (a) template loop рендерит каждый дом через house-name dict, либо (b) `transit_themes` formatter возвращает full preformatted string. Cleanliness — option (b) уменьшает template complexity. Minimal patch ≤ 30 lines.
  - **`services/api-python/app/pdf/builder.py`** (если требуется minimum) — для прокидывания `natal_chart` в Jinja context или для обеспечения availability `target_house_set`. ≤ 15 lines, ТОЛЬКО если необходимо для wiring.
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — **unmark `@pytest.mark.xfail`** для 4 Cat 6 Phase 5 tests (см. Test contract). НЕ unmark Phase 6 xfails.
- new (tests):
  - `services/api-python/tests/test_rulership_houses.py` — unit tests для helper'а. Минимум:
    - `test_planet_rules_table` — verify modern rulership convention: Sun → {Leo}; Mercury → {Gemini, Virgo}; Venus → {Taurus, Libra}; Mars → {Aries, Scorpio}; Jupiter → {Sagittarius, Pisces}; Saturn → {Capricorn, Aquarius}; Uranus → {Aquarius}; Neptune → {Pisces}; Pluto → {Scorpio}.
    - `test_cusp_sign_at_30_degree_boundaries` — 0° = Aries, 29.9° = Aries, 30° = Taurus; verify repeated bucket boundary + 360° wrap.
    - `test_natalya_venus_ruled_houses_matches_marina` — для Натальи helper возвращает **{2, 3}** (Libra repeated на cusps 2 и 3). `target_house_set("Venus")` = `{2, 3, 12}` (placement 12 + ruled 2, 3). **Validated against calendar oracle p. 22-23.**
    - `test_natalya_mars_ruled_houses_matches_marina` — **{8, 9}** (Aries repeated на cusps 8 и 9; cusp 9 = `29°48' Aries`). `target_house_set("Mars")` = `{3, 8, 9}` (placement 3 + ruled 8, 9). **Validated against calendar.**
    - `test_natalya_jupiter_ruled_houses_matches_marina` — {4, 7} (Sagittarius cusp 4 + Pisces cusp 7). `target_house_set("Jupiter")` = `{4, 7}` (placement 4 dedup'нут в union).
    - `test_natalya_neptune_ruled_houses_matches_marina` — {7} (Pisces cusp 7). `target_house_set("Neptune")` = `{4, 7}` (placement 4 union with ruled 7).

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

- [ ] Helper `target_house_set(target, natal_chart)` возвращает sorted list of ints, включая placement house и rulership houses; **включая repeated cusp signs** (если один sign на нескольких consecutive cusps — все эти дома в result).
- [ ] Для Натальи (08-natalya-2025-2026) **calendar oracle** (Marina pp. 22-23):
  - `target_house_set("Venus")` == `[2, 3, 12]` — placement 12 + ruled Libra на cusps 2 и 3.
  - `target_house_set("Jupiter")` == `[4, 7]` — placement 4 + ruled Sagittarius cusp 4 (dedup в union) + Pisces cusp 7.
  - `target_house_set("Neptune")` == `[4, 7]` — placement 4 + ruled Pisces cusp 7.
  - `target_house_set("Mars")` == `[3, 8, 9]` — placement 3 + ruled Aries на cusps 8 и 9 (cusp 9 = 29°48' Aries, repeated).
- [ ] Calendar `transit_aspects_by_month` строки Натальи показывают rulership-expanded house sets, не placement-only. Visual self-verify через render PDF + extracted text check.

### Test contract (Phase 5 xfail flips → passed)

После landing TASK 5 (Path B) `pytest tests/test_natalya_transits_acceptance.py -v` показывает **4 xfail tests перешли в passed**:

Category 6 (target houses, 3 xfail Phase 5):
- `test_target_houses_not_placement_only_for_multi_house_targets` → passed
- `test_uranus_square_venus_target_houses_match_marina_reference` → passed — expected `[2, 3, 12]` per calendar oracle (Marina pp. 22-23). Important: это **calendar semantic**, не golden-rule table semantic (golden-rule даёт `{2, 9}` ruled only).
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
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. **Acceptance count formula:** `(115 baseline) + (4 Phase 5 xfail flips) + (N new helper tests passed)` passed, **4 xfailed** (Phase 6 calendar clipping остаются), **0 failed**. **НЕ фиксировать конкретный `119 passed`** — новые helper unit tests добавляют к passed count. Ожидание: ≥ 119 passed + 4 xfailed + 0 failed.
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

- [ ] Path B затрагивает **только** этот set файлов:
  - `services/api-python/app/pdf/rulership_houses.py` (new module).
  - `services/api-python/app/pdf/transit_themes.py` (wiring + signature update для access к natal_cusps).
  - `services/api-python/app/pdf/templates/solar.html.j2` (template wiring для multi-house render, ≤ 30 lines).
  - `services/api-python/app/pdf/builder.py` (Jinja context update if minimum required, ≤ 15 lines, ТОЛЬКО при необходимости).
  - `services/api-python/tests/test_natalya_transits_acceptance.py` (xfail unmark — 4 Phase 5 tests).
  - `services/api-python/tests/test_rulership_houses.py` (new unit tests).
- [ ] **`services/api-python/app/pdf/outer_cards.py` НЕ трогается.** Phase 4 closed card-facts остаются (они для golden-rule semantic, отличается от calendar semantic). Trogание создаёт regression — outer_cards.py Phase 4 baseline зафиксирован.
- [ ] Engine, schema, fixtures, rulesets, Haskell core — 0 lines changed.
- [ ] Phase 4b structured overrides (в `test_natalya_transits_acceptance.py`) не тронуты.
- [ ] Phase 6 xfails не тронуты.

## Context

**Mode normal + Tier C** на default Path B. **Tier A + Mode strict** на Path A (Worker escalates BLOCKED if path needed).

**Baseline:** main @ `d44d7c6` (Phase 4b closed). Tests `115 passed + 8 xfailed`. После Phase 5 expected: `(115 + 4 flipped + N new helper tests) passed + 4 xfailed + 0 failed`. **Не фиксировать конкретное число passed** — N зависит от количества unit tests которые Worker напишет для `rulership_houses`.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 4 архитектурное решение часть 3 (`transit_target_house_sets`).
- § 5 Phase 5.
- § 6 Target houses (acceptance assertions).
- § 8 TASK 5 — formal spec (зеркальная).

**Marina reference oracle:** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 18, 20-21 «Золотое правило транзита» таблицы для 3 outer cards Натальи. Дополнительно — календарные строки pp. 22-23 с «Дома цели» для quick-cross-validation.

**Natal data:** `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json:natal_chart.house_cusps` (or `natal_chart.cusps`) — sign mapping для validation rulership houses output.

**Phase 5 ⇄ Phase 4 boundary fixed:** Phase 4 `outer_cards.py` использует closed card-facts (per case_id) для golden-rule таблиц — это **отдельная semantic** (Marina pp. 18, 20-21 «Управление домами радикса» без placement). Calendar (Marina pp. 22-23) показывает другой set («Дома цели» = placement ∪ ruled с repeated cusps). **Phase 5 авторизует ТОЛЬКО calendar context.** outer_cards.py НЕ трогается, никаких optional «Worker decides» — оставляется Phase 4 baseline. Если Phase 7 calibration выявит несоответствие golden-rule semantic generic helper'у — это отдельный TASK после Phase 7.

**Phase 6 на ожидании:** TL открывает TASK 6 (per-context cutoff policy) только после accept Phase 5.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 5 spec.
