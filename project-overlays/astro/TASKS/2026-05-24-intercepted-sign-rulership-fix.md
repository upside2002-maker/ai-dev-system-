# TASK: intercepted-sign-rulership-fix

- Status: review
- Ready: yes
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

### Stage 0 — Empirical baseline (Olga + STOP gate) per user clarification 6 = (a)

User direction 2026-05-24 verbatim: «Нельзя сейчас шить правило под ожидания, если фактические cusps Ольги их не подтверждают. Пусть Worker сначала докажет, какой слой карты он читает: натал/соляр, Placidus/другая система, birth place/meeting place. Только после этого можно решать, где реально включённые знаки и какие управители должны попасть в 1/7/11/12 дома.»

**0.1 — Chart layer identification (NEW critical step):**

Worker MUST explicitly document **which chart layer / house system** rulership_houses reads from:
- `facts.natal_chart.house_systems.Placidus.cusps`? — natal Placidus.
- `facts.natal_chart.house_systems.WholeSign.cusps`? — natal whole-sign (if engine emits).
- `facts.solar_chart.house_systems.Placidus.cusps`? — solar Placidus.
- Some derived structure?

Read existing `rulership_houses.py:137` signature + callsites. **Document chart layer used today.** Confirm whether change is needed (e.g. user expects solar cusps but software reads natal).

This is the **first STOP check**: if rulership_houses currently uses natal Placidus but user expects solar cusps (or vice versa), это primary discrepancy. Resolution requires user clarification BEFORE intercepted-sign work.

**0.2 — Compute Olga's intercepted signs per house (for identified chart layer):**

Worker reads cusps from the layer identified в 0.1. Для каждого Дом i (cusp i → cusp i+1):
- Identify sign of cusp i and cusp i+1.
- Identify any signs **fully contained** between (intercepted signs).
- Output: `{house: {"cusp_sign": str, "intercepted_signs": [str], "all_signs": [str]}}`.

**0.3 — Compute current vs expected rulership:**

Run current `rulership_houses("Mars", olga_cusps)`, `..."Uranus"...`, etc. Document current output.

Compute expected output using intercepted-sign logic. Compare to user expectations from § Problem (Mars → 1; Uranus → 11, 12; Jupiter → 1, 9, 10; Venus → 7).

**0.4 — Useful people empirical:**

Worker reads Olga's:
- Natal Asc sign.
- Natal Дом 1 cusp sign + intercepted signs (per identified chart layer).
- Natal Дом 7 cusp sign + intercepted signs.

Compare to user expectations («Асц в Скорпионе или Тельце; Венера/Марс/Плутон в 1 доме»).

**0.5 — STOP gate criteria:**

If ANY of:
- Chart layer not identifiable / ambiguous.
- Intercepted signs не подтверждают user-expected co-rulership (Mars → 1; Uranus → 11/12; Venus → 7; Jupiter → 1/9/10).
- Useful people Asc axis не Scorpio/Taurus (e.g. natal Asc = Cancer).

→ **STOP. Document discrepancy в Worker HANDOFF. Escalate user clarification BEFORE Stage 1.**

Worker MUST NOT fabricate rulership logic to match user expectations if empirics contradict. Possibilities for user clarification:
- Whole-sign houses (different intercepted signs than Placidus).
- SOLAR cusps (Olga solar Asc = Libra, не Cancer; check solar intercepted).
- Different rulership convention (esoteric / Egyptian terms / classical-only / etc.).
- Misremembered Olga's chart — user revises expectations.

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

**1.4 — Modern vs classical rulers (per user clarification 3 = (c) preserve current convention):**

Worker reads existing `rulership_houses.py:137` source + matches its rulership scheme exactly (whatever it currently uses — modern only, classical+modern, или other). This preserves backward compatibility для calibrated cards и existing tests.

If Worker discovers convention ambiguity (e.g. comment says modern but logic includes classical co-rulers), document в HANDOFF; preserve current behaviour without change.

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

**Calibrated cards check (per user clarification 5 = (c) Worker investigates):**

Worker investigates code path:
1. Read `outer_cards.py` to identify how «Управление домами радикса» строка is generated for calibrated vs generic cards.
2. Check `_OUTER_CARD_FACTS` schema — does it contain hand-curated `rulership_houses` field, or derived at render-time via helper?
3. Document findings в HANDOFF.

**Decision tree:**
- If hand-curated в `_OUTER_CARD_FACTS` → calibrated cards NOT auto-affected; new logic applies only to generic path. Document.
- If auto-derived via `rulership_houses(...)` helper → calibrated cards auto-update; document diff per case в HANDOFF; if substantive regression on calibrated → STOP, escalate.

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

**Rewrite approach (per user clarification 4 = (a) full rewrite):**

Worker replaces 5-channel approach с new principles:

1. **Axis 1-7 signs:** natal Дом 1 cusp sign + intercepted signs + Дом 7 cusp sign + intercepted signs (per identified chart layer от Stage 0.1).
2. **Co-rulers of Дом 1 / Дом 7:** planets ruling all signs in those houses (via updated `rulership_houses`).
3. **Planets in natal 1st house:** reuse existing `_natal_first_house_planets` helper.
4. **Solar signs matching axis 1-7:** people с solar Sun в axis signs are «полезные» year-anchor.

Compositional output: 2-3 short sentences referencing real signs + planets. NO Daragan verbatim. NO fabrication if Stage 0 STOP fired.

Existing 5-channel logic preserved as `_useful_people_block_legacy` (или similar) for rollback / regression reference; not called в production path.

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

**Ready: yes** — 6 clarifications applied 2026-05-24 + critical Stage 0 STOP gate:

1. **Edge cases = (a)** — Worker handles 3 cases: wrap 0° Aries / cusp at sign boundary / empty intercepted list. Synthetic fixtures verify. Applied Stage 1.2.

2. **«Включённые знаки» = (a) strict intercepted** — only signs FULLY contained within single house. Applied Stage 1.

3. **Rulership convention = (c) preserve current.** Worker reads existing `rulership_houses.py:137` + matches existing scheme. Documents any ambiguity в HANDOFF без changing behaviour. Applied Stage 1.4.

4. **Useful people = (a) full rewrite.** New principles: axis 1-7 cusp+intercepted signs + co-rulers + house-1 planets + solar matches. Existing 5-channel preserved as legacy для rollback reference. Applied Stage 4.

5. **`_OUTER_CARD_FACTS` policy = (c) Worker investigates.** Reads code path; documents whether calibrated cards use auto-derived OR curated rulership_houses; proposes accordingly. Applied Stage 3.

6. **Stage 0 = (a) empirics first + STOP gate.** User direction verbatim: «Нельзя сейчас шить правило под ожидания, если фактические cusps Ольги их не подтверждают. Пусть Worker сначала докажет, какой слой карты он читает: натал/соляр, Placidus/другая система, birth place/meeting place. Только после этого можно решать, где реально включённые знаки и какие управители должны попасть в 1/7/11/12 дома.»

**Critical Stage 0 chart-layer identification added (per user emphasis 2026-05-24):**

Worker MUST explicitly identify в Stage 0.1:
- Chart layer: natal / solar.
- House system: Placidus / whole-sign / другое.
- Birth place / meeting place lattice.

BEFORE computing intercepted signs OR rulership. If chart layer ambiguous → STOP, escalate.

If chart layer identifiable + empirics ≠ user expectations → STOP, escalate user clarification (whole-sign? solar cusps? esoteric rulers? misremembered?). NO fabrication.
