# TASK: intercepted-sign-rulership-fix

- Status: open
- Ready: no
- Date: 2026-05-24
- Project: astro
- Layer: services (Python presentation: `rulership_houses.py` helper + downstream propagation в outer_cards / transit_themes / synthesis_themes Полезные люди block)
- Risk tier: B+ (astrology semantics fix; helper module change auto-propagates 3 downstream consumers; Useful People rewrite content-authoring; new tests; no engine touch; no DB schema change)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User PDF audit 2026-05-24 на Olga consultation 12 identified **3 bugs одного класса**: software учитывает только знак на куспиде дома, не учитывает **включённые знаки внутри дома** (intercepted signs). Из-за этого:

1. **Outer-card «Управление домами радикса»** строки неполные — Mars / Jupiter / Venus / Uranus / Neptune как co-rulers выпадают когда они rule intercepted-sign.
2. **Календарь транзитов «Дома цели»** неполные — `target_house_set` пропускает co-ruled houses.
3. **«Полезные люди» block** выехал в неверные знаки и неверные формулировки.

**Root cause:** `services/api-python/app/pdf/rulership_houses.py:137` `rulership_houses(planet, cusps)` ходит только по знакам на cusps. Intercepted signs (полностью внутри дома между двумя cusps) не учитываются.

**Concrete bugs Worker должен зафиксировать на Stage 0:**

User expectations (per direction 2026-05-24):
- Uranus: rules / co-rules `1, 11, 12` (currently incomplete).
- Mars: co-rules `1` (Aries intercepted).
- Jupiter: co-rules `1, 9, 10`.
- Venus: co-rules `7` (Taurus intercepted).
- Calendar «Дома цели»: includes co-ruled houses from included signs.
- Useful people: «Асц в Скорпионе или Тельце; солнечные Тельцы / Скорпионы; люди с Венерой / Марсом / Плутоном в 1 доме». NOT «Овны / Львы / солнечное присутствие / меркурианская лёгкость».

**Critical Stage 0 caveat (TL prelim verification 2026-05-24):** Olga's natal cusps:
```
[94.15, 108.33, 123.56, 143.31, 173.99, 224.85, 274.15, 288.33, 303.56, 323.31, 353.99, 44.85]
```
- Дом 1 = 4° Cancer cusp → 18° Cancer cusp; NO intercepted signs в Дом 1 (just Cancer).
- Дом 11 = 23° Pisces cusp → 14° Taurus cusp; **Aries intercepted в Дом 11**.
- Дом 12 = 14° Taurus cusp → 4° Cancer cusp; **Gemini intercepted в Дом 12**.
- Aquarius is cusp Дом 9 (3° Aquarius) → cusp Дом 10 (23° Aquarius); Aquarius spans 9-10 only.

This means Worker's empirical verification на Stage 0 **может НЕ совпасть с user expectations**:
- Mars co-rules 1? Aries intercepted в Дом 11, не Дом 1 (per actual cusps).
- Uranus rules 11, 12? Aquarius spans 9-10, не 11/12 (per actual cusps).
- Useful people Scorpio/Taurus axis? Olga natal Дом 1 = Cancer only; natal axis 1-7 = Cancer-Capricorn.

**Worker MUST run empirical Stage 0 first** и если expectations ≠ empirics → **STOP и escalate user clarification.** Может быть user counts via different house system (whole-sign?), uses SOLAR cusps instead of natal, OR misremembers Olga's chart. NOT fabricate to match expectations.

## Worker framing (verbatim user direction 2026-05-24)

> «Софт сейчас учитывает только знак на куспиде дома, но не учитывает включённые знаки / соуправителей.»

> «Исправить правило управления домами радикса: учитывать не только знак на куспиде, но и включённые знаки внутри дома.»

> «Если Worker не может вывести эти ожидания из фактов — STOP, не фантазировать.»

## Scope (Tier B+ astrology semantics fix)

### Stage 0 — Empirical baseline (Olga + STOP gate)

**0.1 — Compute Olga's intercepted signs per house:**

Worker reads `facts.natal_chart.house_systems.Placidus.cusps` (12 floats). Для каждого Дом i (cusp i → cusp i+1):
- Identify sign of cusp i and cusp i+1.
- Identify any signs **fully contained** between (intercepted signs).
- Output: `{house: {"cusp_sign": str, "intercepted_signs": [str], "all_signs": [str]}}`.

**0.2 — Compute current vs expected rulership:**

Run current `rulership_houses("Mars", olga_cusps)`, `..."Uranus"...`, etc. Document current output.

Compute expected output using intercepted-sign logic. If expected matches user expectations from § Problem (Mars → 1; Uranus → 11, 12; Jupiter → 1, 9, 10; Venus → 7) — proceed Stage 1.

**If empirical expected ≠ user expectations (e.g. Olga natal cusps show Aries intercepted в Дом 11 не Дом 1):**
- **STOP.** Document discrepancy в Worker HANDOFF.
- Possibilities: user may use whole-sign houses, OR SOLAR cusps not natal, OR misremembers chart, OR uses different rulership convention.
- Escalate user clarification before proceeding к implementation.

**0.3 — Useful people empirical:**

Worker reads Olga's natal Asc sign, Дом 1 cusp sign + intercepted signs, Дом 7 cusp sign + intercepted signs.

Compare to user expectations («Асц в Скорпионе или Тельце; Венера/Марс/Плутон в 1 доме»). If natal data shows Asc = 4° Cancer (Дом 1 = Cancer only, no Scorpio/Taurus involvement) → STOP, escalate.

### Stage 1 — Rulership helper extension (включённые знаки)

**1.1 — `house_signs` helper:**

```python
def house_signs(cusps: list[float]) -> dict[int, dict]:
    """For each house 1-12, identify cusp sign + intercepted signs.
    
    Returns:
        {
          1: {
            "cusp_sign": "Cancer",
            "intercepted_signs": [],  # or e.g. ["Aries"]
            "all_signs": ["Cancer"]   # cusp + intercepted, sorted
          },
          ...
        }
    """
```

**1.2 — Edge case handling:**

- Wrap around 0° Aries (e.g. cusp Дом 12 = 25° Pisces, cusp Дом 1 = 5° Taurus → Aries intercepted).
- Cusp exactly at sign boundary (e.g. cusp = 0° Cancer).
- Empty intercepted list (cusps within same sign).
- Deterministic / sorted output.

**1.3 — `rulership_houses` update:**

```python
# Current logic:
planet rules house IFF planet rules sign_on_cusp

# New logic:
planet rules house IFF planet rules ANY sign in all_signs[house]
```

**1.4 — Modern vs classical rulers (per § Ready clarification 3):**

Worker investigates existing `rulership_houses` rulership scheme:
- (a) Modern only (Mars→Aries; Pluto→Scorpio; Saturn→Capricorn; Uranus→Aquarius; Jupiter→Sagittarius; Neptune→Pisces).
- (b) Classical + Modern co-rulers.
- (c) Preserve current convention (Worker reads existing code + matches).

### Stage 2 — Calendar `target_house_set` update

`services/api-python/app/pdf/rulership_houses.py:194` `target_house_set(target, natal_chart)` extends:

```python
# Current:
placement_house ∪ houses_ruled_by_cusp_signs

# New:
placement_house ∪ houses_ruled_by_cusp_signs ∪ houses_ruled_by_intercepted_signs
```

Asc / MC special cases preserved (`[1]` / `[10]`).

### Stage 3 — Outer cards (auto-propagation)

`outer_cards.py` generic path использует `rulership_houses(...)` — изменение helper'а auto-fixes outer-card «Управление домами радикса» строки.

**Calibrated cards check:**
- `_OUTER_CARD_FACTS` has hand-curated «rulership_houses» field per card?
- Worker investigates: if hand-curated, calibrated cards NOT auto-affected; preserve.
- If auto-derived, calibrated cards may change — Worker documents diff per case в HANDOFF, escalate if substantive regression.

User direction: «calibrated allowlist cards не переписывать руками; `_OUTER_CARD_FACTS` не трогать без отдельного решения.»

### Stage 4 — Useful people rewrite (per § Ready clarification 4)

Current `synthesis_themes.py:1519` `_useful_people_block` uses 5-channel multi-sign emission:
- Solar Asc sign
- Opposite sign
- Natal Sun sign
- Solar MC sign
- Natal 1st-house planets

User-identified bugs:
- «Овны, Львы, солнечное присутствие, меркурианская лёгкость» appear — wrong для Olga.

User-expected новый algorithm:
- Axis 1-7 signs **с учётом включённых знаков** (natal Дом 1 + Дом 7 cusps + intercepted).
- Управители / соуправители Дом 1 и Дом 7.
- Планеты реально в Дом 1.
- Solar signs matching axis 1-7 signs.

**Acceptance for Olga (per user 2026-05-24, contingent on Stage 0 verification):**
- Required: «Асц в Скорпионе или Тельце; солнечные Тельцы / Скорпионы; Венера / Марс / Плутон в 1 доме».
- Forbidden: «Овны, Львы, солнечное присутствие, меркурианская лёгкость».

**Critical:** if Stage 0 empirics не support Scorpio/Taurus axis (Olga natal Asc = Cancer) → STOP, escalate. Не fabricate.

**Rewrite approach (per § Ready clarification 4):**
- (a) **Full rewrite** based on new principles (axis 1-7 signs + co-rulers + house-1 planets + solar matches).
- (b) **Extend existing 5-channel** с intercepted-sign awareness.
- (c) Worker proposes.

### Stage 5 — Tests

**5.1 — Rulership tests (synthetic fixtures):**

```python
def test_house_signs_intercepted_aries():
    """Cusp Дом 12 = 25° Pisces; cusp Дом 1 = 5° Taurus.
    Aries (intercepted в Дом 12)."""
    
def test_house_signs_intercepted_taurus_in_house_7():
    """Verify Venus rules house 7 when Taurus intercepted."""

def test_house_signs_wrap_around_aries():
    """Cusp 358° Pisces → cusp 5° Taurus: Aries intercepted."""

def test_rulership_includes_intercepted():
    """rulership_houses("Venus", cusps) includes house with intercepted Taurus."""
```

**5.2 — Olga regression (contingent on Stage 0 PASS):**

```python
def test_olga_uranus_rulership():
    assert set(rulership_houses("Uranus", olga_cusps)) >= {1, 11, 12}  # IF Stage 0 confirms
    # OR per actual empirics:
    assert set(rulership_houses("Uranus", olga_cusps)) == {9, 10}  # IF empirics differ
```

**5.3 — Calendar tests:**

`target_house_set("Neptune", natal_chart)` includes co-ruled houses от intercepted signs.

**5.4 — Useful people tests (per user spec, contingent на Stage 0):**

Olga required phrases present; forbidden phrases absent.

### Stage 6 — Calibrated regression

All 6 calibrated cases (02 / 03 / 05 / 07 / 08 / 10):
- Existing tests pass без regression.
- Per-case diff если outer cards «rulership_houses» row changes.
- Worker documents diff в HANDOFF.

## Files

- new (likely):
  - `services/api-python/tests/test_intercepted_signs.py` (rulership unit tests).
  - `services/api-python/tests/test_useful_people_intercepted.py` (Useful people regression, if separate from existing).

- modify:
  - `services/api-python/app/pdf/rulership_houses.py` (add `house_signs` + extend `rulership_houses` + extend `target_house_set`).
  - `services/api-python/app/pdf/synthesis_themes.py:1519` (`_useful_people_block` rewrite).
  - Possibly `services/api-python/app/pdf/transit_themes.py` (if uses `target_house_set` differently).
  - Existing test files extended.
  - `project-overlays/astro/STATUS_RU.md`.

- delete: —

## Do not touch

- Haskell core / engine / schema / fixtures.
- DB schema.
- PDF layout outside affected text.
- Outer-card `_OUTER_CARD_FACTS` (calibrated allowlist — preserved unless explicit auto-derivation change documented per § Ready clarification 5).
- Direction logic.
- Solar Meeting Place plumbing.
- Geocode endpoint.
- `house_meanings.py` canonical dict.
- `planet_archetypes.py`.
- `solar_house_distribution.py` (separate concern).
- **NO LLM.**
- **NO fabrication** if Stage 0 empirics не match user expectations.
- **NO Daragan verbatim** в Useful people rewrite.

## Acceptance

### Stage 0 gate (prerequisite)

- [ ] Empirical baseline computed для Olga (intercepted signs per house, current rulership per planet).
- [ ] If empirics ≠ user expectations → STOP, escalate user clarification BEFORE Stage 1 implementation.
- [ ] If empirics match user expectations → proceed Stage 1.

### Primary (if Stage 0 PASS)

- [ ] `rulership_houses` accepts intercepted signs (Stage 1.3).
- [ ] `target_house_set` includes co-ruled houses от intercepted signs (Stage 2).
- [ ] Outer-card «Управление домами радикса» строки correct для Olga (Stage 3).
- [ ] Calendar «Дома цели» expanded for Olga (Stage 2).
- [ ] Useful people for Olga: required phrases present, forbidden phrases absent (Stage 4).
- [ ] Calibrated cases preserved or diff documented (Stage 6).

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 673 + N`. 0 failed, 0 xfailed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (helper + 3 downstream + tests).
- [ ] One overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity verified.
- [ ] Reviewer REQUIRED per user direction.

### Discipline

- [ ] NO engine touch.
- [ ] NO DB schema change.
- [ ] NO `_OUTER_CARD_FACTS` modification без explicit Stage 6 escalation.
- [ ] NO fabrication when empirics disagree с user expectations.
- [ ] NO LLM.
- [ ] NO Daragan verbatim в Useful people.
- [ ] All emitted phrases trace к natal chart facts + house-sign/rulership logic.

## STOP triggers

- **Stage 0 empirics ≠ user expectations** → STOP, escalate user clarification BEFORE Stage 1.
- Worker fabricates signs/houses to match user expectations → STOP.
- Worker touches Haskell core → STOP.
- Worker modifies `_OUTER_CARD_FACTS` calibrated data без escalation → STOP.
- Worker fabricates Useful people Scorpio/Taurus axis when natal Asc = Cancer → STOP, escalate.
- Worker copies Daragan verbatim → STOP.
- Worker introduces LLM → STOP.
- Worker breaks meeting_place invariant → STOP.
- Worker breaks existing calibrated outer-card tests → STOP.

## Reviewer subagent — REQUIRED (per user direction 2026-05-24)

User direction verbatim: «Reviewer REQUIRED. This touches astrology semantics, not just text.»

External Reviewer pass REQUIRED после Worker self-submit. If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- `house_signs` correctness: synthetic fixtures (intercepted Aries / Taurus / Pisces / wrap-around 0° Aries).
- Olga empirical match (per Stage 0 verification): expected rulership houses confirmed by Reviewer independently.
- Calendar «Дома цели» expanded correctly per case.
- Useful people Olga acceptance: required phrases present, forbidden absent.
- Calibrated cases: no regression OR diff documented + acceptable.
- No fabrication: every Useful people phrase traces to natal chart facts.
- No Daragan verbatim.
- 0 STOP triggers fired.

## Context

**Mode normal + Tier B+ (Reviewer REQUIRED per user 2026-05-24).** Worker mode: normal.

**Baseline:**
- Product main @ `732759d` (Solar Planets House Distribution closed).
- Overlay master @ `d8ca443` (latest closure).
- Pytest baseline: `673 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- `rulership_houses.py:137` `rulership_houses(planet, cusps)` — current cusp-only logic.
- `rulership_houses.py:194` `target_house_set(target, natal_chart)` — extends.
- `synthesis_themes.py:1519` `_useful_people_block(facts)` — current 5-channel algo.
- `synthesis_themes.py:1005` `_natal_first_house_planets(facts)` — preserved.
- `outer_cards.py` generic path — auto-affected via `rulership_houses`.
- `transit_themes.py` — uses `target_house_set`.
- Olga natal cusps: `[94.15, 108.33, 123.56, 143.31, 173.99, 224.85, 274.15, 288.33, 303.56, 323.31, 353.99, 44.85]` (TL prelim verified).
- Olga natal Asc = 4° Cancer (94.15°).

**Not in scope (explicit):**
- Engine modifications (Haskell rules unchanged).
- DB schema.
- House system change (Placidus preserved).
- LLM.
- Solar Meeting Place / Geocode / House Meanings dictionaries.
- `_OUTER_CARD_FACTS` (calibrated curated data).

**Ready: no** — pending 6 clarifications below.

## Ready clarifications (pending user direction 2026-05-24)

1. **Intercepted-sign algorithm edge cases.**
   - (a) Worker handles 3 cases: wrap around 0° Aries / cusp at sign boundary / empty intercepted list. Synthetic test fixtures верифицируют.
   - (b) Worker proposes additional edge case handling.

2. **«Включённые знаки» definition.**
   - (a) Strict «intercepted» — only signs FULLY contained within a single house.
   - (b) Loose «all signs touching house arc» — any sign overlapping house span (включая partial overlap).
   - (c) Worker proposes (likely (a) per user-expected behaviour).

3. **Modern vs classical rulers convention.**
   - (a) Modern only (Mars→Aries; Pluto→Scorpio; Saturn→Capricorn; Uranus→Aquarius; Jupiter→Sagittarius; Neptune→Pisces).
   - (b) Classical + Modern co-rulers (Mars rules both Aries+Scorpio; Saturn rules both Capricorn+Aquarius; Jupiter rules both Sagittarius+Pisces).
   - (c) Preserve current `rulership_houses.py` convention (Worker reads existing code + matches).

4. **Useful people algorithm strategy.**
   - (a) Full rewrite based on new principles (axis 1-7 cusp+intercepted signs + co-rulers + house-1 planets + solar matches).
   - (b) Extend existing 5-channel с intercepted-sign awareness.
   - (c) Worker proposes.

5. **Calibrated `_OUTER_CARD_FACTS` impact policy.**
   - (a) Hands-off — calibrated cards preserve current curated «rulership_houses» строки даже если new logic disagrees.
   - (b) Auto-derive — calibrated cards regenerate «rulership_houses» строки на basis of new logic; document diff per case в HANDOFF.
   - (c) Worker investigates code path; documents whether calibrated cards use auto-derived OR curated rulership_houses; propose accordingly.

6. **Stage 0 empirics vs user expectations.**
   - Olga natal cusps show: Дом 1 = Cancer only (no intercepted); Дом 11 = Pisces+Aries+Taurus; Дом 12 = Taurus+Gemini+Cancer. User expects Mars co-rules 1; Uranus 11+12; Useful people Scorpio/Taurus axis.
   - Discrepancy: Mars would rule 11 (не 1); Uranus would still be 9-10 (Aquarius cusp); Asc-axis Cancer-Capricorn (не Scorpio-Taurus).
   - (a) Worker proceeds with empirical Stage 0 verification; if empirics ≠ user expectations → STOP, escalate user clarification (user may use whole-sign houses OR misremember Olga's chart OR have other reasoning).
   - (b) User confirms expectations override empirics (Worker computes regardless).
   - (c) User confirms expectations correct + provides correction для chart reading.
