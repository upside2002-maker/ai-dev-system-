# TASK: solar-planets-house-distribution

- Status: open
- Ready: no
- Date: 2026-05-20
- Project: astro
- Layer: services (Python presentation: new helper module + new PDF section + tests)
- Risk tier: B (new helper module + new PDF template section + content authoring (planet archetypes) + tests; uses existing canonical house_meanings; no DB schema change; no engine touch; no meeting_place invariant break)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User PDF audit 2026-05-20 после Geocode closure: раздел «Распределение планет по домам соляра» (из образца Марины) **в текущем PDF отсутствует**. Есть только справочная таблица «Соляр — позиции планет» в конце PDF (planet / sign / degree / house / retro), но это techical reference, не client-facing trактовки.

**Stage 0 prelim verification (TL code review 2026-05-20):**

Schema `facts.solar_chart.positions[*]` confirmed для Olga consultation 12:
```python
{"planet": "Sun", "longitude": 111.00, "house_placidus": 10, "is_retrograde": False}
```
- Fields: `planet`, `longitude`, `house_placidus`, `is_retrograde`, `latitude`, `degree`, `minute`, `sign`, `speed`.
- 10 планет exactly (Sun..Pluto) — no Asc/MC bodies, no Lilith / Nodes.
- Olga's distribution: Sun, Mercury, Jupiter в 10 доме; Moon, Mars в 9; Venus в 11; Saturn в 7; Uranus в 8; Neptune R в 6; Pluto R в 4; Mercury R в 10.
- Axis accent: 4-10 = 4 planets (strongest).

**Programme classification:** new client-facing PDF section + new helper module. Содержит content authoring (planet × house archetype interpretations) на базе уже-существующего canonical `house_meanings.py` + new planet archetype dict.

## Worker framing (verbatim user direction 2026-05-20)

> «Раздел из образца Марины отсутствует. Добавить в PDF отдельный раздел: таблица 12 домов + акцент оси + краткие трактовки планет по домам соляра.»

> **«Использовать дома соляра, не натальные дома; значит, при `meeting_place` этот раздел должен меняться вместе с ASC/MC/куспидами соляра; не использовать `annual_transit_table`; не использовать `natal_chart.positions`.»**

> «Если в facts нет Лилит / Северного узла — не выдумывать. В этом TASK рендерить только реально вычисленные тела. Лилит/узлы — отдельный future engine/schema TASK.»

## Scope (Tier B new section + helper)

### Stage 0 — Data verification

Worker confirms (already done в TL prelim):
- `facts.solar_chart.positions[*].house_placidus` (1-12 integer).
- `facts.solar_chart.positions[*].is_retrograde` (boolean).
- `facts.solar_chart.positions[*].planet` (string: Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn/Uranus/Neptune/Pluto).
- 10 planets exactly; no Asc/MC; no Lilith/Nodes (для Olga consultation 12 confirmed).

**Critical guard:** worker reads ONLY `solar_chart.positions`, NEVER:
- `natal_chart.positions` (those are natal houses, wrong source).
- `annual_transit_table` (transit data, wrong scope).

### Stage 1 — Helper module `solar_house_distribution.py`

**1.1 — New file:** `services/api-python/app/pdf/solar_house_distribution.py`

**1.2 — Main grouping function:**

```python
_PLANET_ORDER = (
    "Sun", "Moon", "Mercury", "Venus", "Mars",
    "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
)

def solar_planets_by_house(solar_chart: dict) -> list[dict]:
    """Group planets by their solar Placidus house.
    
    Returns 12 rows (one per house, house 1-12). Empty houses
    have planets=[]. Planets sorted by _PLANET_ORDER (natural
    classical order).
    """
    # Filter positions to known planets only (strict 10 per user spec)
    # Group by house_placidus
    # Sort within each house by _PLANET_ORDER
    # Return [{"house": 1, "planets": []}, {"house": 2, "planets": ["Moon"]}, ...]
```

**1.3 — Render helper для retrograde marker:**

```python
def format_planet_for_house(planet: str, is_retrograde: bool) -> str:
    """Format planet name with optional R suffix.
    
    «Mercury» + retro=True → «Меркурий R»
    «Sun»     + retro=False → «Солнце»
    """
```

Russian planet names — reuse `_PLANET_NOM_RU` или similar existing dict (verify в outer_cards.py:1488 OR synthesis_themes.py).

### Stage 2 — Axis accent calculation

**2.1 — Axis sum:**

6 axes: (1,7), (2,8), (3,9), (4,10), (5,11), (6,12).

```python
def calculate_axis_accents(by_house: list[dict]) -> list[tuple[int, int]]:
    """Return axes with maximum planet count.
    
    Returns list of (low, high) tuples for strongest axes.
    If max < threshold (per § Ready clarification 3) → return [].
    If multiple axes tie at max → return all.
    """
```

**2.2 — Render:**

```python
def axis_accent_phrase(accents: list[tuple[int, int]]) -> str:
    """Format axis accent phrase.
    
    Single accent: «Акцент на оси 4-10.»
    Multiple: «Акцент на осях 2-8 и 4-10.»
    Empty: ""  (skip phrase when no strong axis)
    """
```

**2.3 — Threshold (per § Ready clarification 3):**

- (a) ≥3 planets on axis = considered accent.
- (b) ≥4 (more conservative).
- (c) Worker proposes (e.g. ≥ (total_planets // 4)).

### Stage 3 — Planet-in-solar-house interpretations

**3.1 — Approach (per § Ready clarification 4):**

- (a) **Compositional generic** — combine planet archetype + house meaning to produce 1-2 sentence text (e.g. «Pluto archetype: глубокая трансформация» + «House 4 meaning: дом, семья, недвижимость» → «Глубокие перемены затрагивают дом, семью, недвижимость и внутреннюю опору.»). Covers all 120 (10×12) combinations через generic composition.
- (b) **Per-(planet, house) overrides catalog** — Worker authors 30-50 hand-crafted entries для high-significance combinations + compositional fallback for rest.
- (c) Worker proposes.

**3.2 — Planet archetype dict location (per § Ready clarification 1):**

- (a) **Embedded в `solar_house_distribution.py`** — self-contained.
- (b) **Extend `house_meanings.py`** — single source of truth для astrological vocabulary (но pattern conflicts: house_meanings is house-focused, не planet-focused).
- (c) **New module `planet_archetypes.py`** — separate planet vocabulary.
- (d) Worker proposes.

**3.3 — Planet archetypes (per user verbatim 2026-05-20):**

```python
_PLANET_ARCHETYPES_RU = {
    "Sun":     "центр года, воля, фокус",
    "Moon":    "эмоциональный фон, быт, реакции",
    "Mercury": "документы, обучение, переговоры",
    "Venus":   "комфорт, отношения, деньги, эстетика",
    "Mars":    "активность, конфликтность, действия",
    "Jupiter": "расширение, удача, поддержка",
    "Saturn":  "ответственность, ограничения, структура",
    "Uranus":  "обновление, резкие перемены",
    "Neptune": "размывание, вдохновение, тонкость",
    "Pluto":   "глубокая трансформация, давление, кризис/сила",
}
```

Worker may refine wording в author's own style, keep архетипы verbatim per user spec.

**3.4 — Render helper:**

```python
def solar_planet_house_text(planet: str, house: int, is_retrograde: bool) -> str:
    """Generate 1-2 sentence interpretation для planet in solar house.
    
    Uses _PLANET_ARCHETYPES_RU + HOUSE_MEANINGS[house]["main"]/"additional".
    Retrograde adds nuance phrase if applicable.
    
    Example output:
      «Плутон R в IV доме»  (header)
      
      «Глубокие перемены затрагивают дом, семью, недвижимость и
       внутреннюю опору. Возможны ремонт, переезд, перестройка
       семейной ситуации или необходимость иначе выстроить домашнюю
       территорию.»
    """
```

**NO Daragan verbatim copy.** Author's own short Russian prose, channeling planet archetype + house meaning combinatorially.

### Stage 4 — PDF template integration

**4.1 — Section placement (per § Ready clarification 2):**

- (a) После «Соляр — позиции планет» reference table (at top of forecast region).
- (b) Перед «Итоги консультации» (near end, as synthesis context).
- (c) Worker proposes.

User direction 2026-05-20 verbatim: «после страницы соляра / перед основными прогнозными разделами».

**4.2 — Template content** (в `solar.html.j2`):

```jinja
<section class="solar-house-distribution">
  <h2>Распределение планет по домам соляра</h2>
  
  <table>
    <thead><tr><th>Дом</th><th>Планеты</th></tr></thead>
    <tbody>
      {% for row in solar_house_distribution.by_house %}
        <tr {% if row.house in solar_house_distribution.accent_houses %}class="accent"{% endif %}>
          <td>{{ row.house }}</td>
          <td>{% if row.planets %}{{ row.planets | join(", ") }}{% else %}-{% endif %}</td>
        </tr>
      {% endfor %}
    </tbody>
  </table>
  
  {% if solar_house_distribution.axis_accent_phrase %}
    <p>{{ solar_house_distribution.axis_accent_phrase }}</p>
  {% endif %}
  
  {% for interp in solar_house_distribution.interpretations %}
    <h3>{{ interp.header }}</h3>
    <p>{{ interp.text }}</p>
  {% endfor %}
</section>
```

**4.3 — Builder integration:**

Modify `builder.py` (или wherever template data assembled) to pass `solar_house_distribution` dict with:
- `by_house: list[dict]` (12 rows).
- `accent_houses: set[int]` (houses в strongest axes — для CSS highlighting).
- `axis_accent_phrase: str` (single phrase или empty).
- `interpretations: list[dict]` (planets с non-empty interp text, each `{"header": "Плутон R в IV доме", "text": "..."}`).

**4.4 — Existing reference table preservation:**

«Соляр — позиции планет» reference table в конце PDF остаётся unchanged. New section дополняет, не заменяет.

### Stage 5 — Tests

**5.1 — New test file** `services/api-python/tests/test_solar_house_distribution.py`.

**5.2 — Test categories:**

1. `solar_planets_by_house` возвращает 12 домов.
2. Пустые дома: `planets == []`.
3. Группировка by `house_placidus`.
4. Sort within house по `_PLANET_ORDER`.
5. Retrograde marker «R» формат.
6. Axis accent: Olga (4-10 = 4 planets) → «Акцент на оси 4-10.»
7. Multi-tied axes → «Акцент на осях X-Y и A-B.»
8. No-accent case (all axes ≤ threshold) → empty phrase.
9. Interpretation: `Pluto + 4` mentions дом/семья/недвижимость/перестройка.
10. Interpretation: `Sun + 10` mentions статус/карьера/цель.
11. Interpretation: `Venus + 5` mentions любовь/творчество/удовольствие.
12. PDF render contains: section title «Распределение планет по домам соляра», `Дом / Планеты` table, ≥1 interpretation.
13. **meeting_place invariant:** rendering Olga с different meeting_place (Питер) shifts house assignments → different distribution + different accent (regression test).
14. **No Lilith/Nodes:** if positions does not contain Lilith / North Node → не появляются в section (defensive test).

### Stage 6 — meeting_place invariant verification

This section depends on `solar_chart.positions[*].house_placidus`, which DOES change when `meeting_place` differs (per Solar Meeting Place TASK invariants). Test:

```python
def test_solar_house_distribution_changes_with_meeting_place():
    facts_birth = build_solar_snapshot(olga, solar_year=2026, meeting_place=None)
    facts_spb   = build_solar_snapshot(olga, solar_year=2026, meeting_place=PETERSBURG)
    
    dist_birth = solar_planets_by_house(facts_birth["solar_chart"])
    dist_spb   = solar_planets_by_house(facts_spb["solar_chart"])
    
    # At least one planet moved between houses (per meeting_place test from prior TASK)
    assert dist_birth != dist_spb
```

## Files

- new:
  - `services/api-python/app/pdf/solar_house_distribution.py` (helper module).
  - `services/api-python/tests/test_solar_house_distribution.py` (~14 tests).

- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2` (new section).
  - `services/api-python/app/pdf/builder.py` (pass data к template) — verify location.
  - `project-overlays/astro/STATUS_RU.md`.

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures.
- `core/astrology-hs/`.
- `meeting_place` invariant (don't break Solar Meeting Place TASK).
- `_OUTER_CARD_FACTS` / `OUTER_CARD_ALLOWLIST` / outer_cards.py.
- Phase 4b structured overrides.
- Phase 9.x artifacts.
- `synthesis_themes.py` Итоги pipeline.
- `house_pair_themes.py` 144 cells.
- `house_meanings.py` (can READ for house values; do NOT modify).
- `annual_transit_table` (don't use as source).
- `natal_chart.positions` (don't use as source).
- Existing «Соляр — позиции планет» reference table в конце PDF (preserve, не заменять).
- **NO Lilith / North Node / South Node / Chiron / asteroids** — рендерить только то, что engine actually computes (10 planets).
- **NO Daragan verbatim copying** — author's own short prose using planet archetypes + house meanings.
- **NO LLM.**
- **NO new engine fields requested.**

## Acceptance

### Primary

- [ ] Helper module `solar_house_distribution.py` существует с `solar_planets_by_house` + axis accent + interpretation helpers.
- [ ] PDF содержит новую секцию «Распределение планет по домам соляра» (после позиций соляра / перед основными прогнозными разделами per Stage 4.1).
- [ ] Таблица 12 домов: пустые → `-`; multi-planet houses → comma-separated; retrograde → `R` suffix.
- [ ] Axis accent phrase: для Olga → «Акцент на оси 4-10.» (4 planets там).
- [ ] Interpretations rendered: «Плутон R в IV доме» + текст; «Солнце в X доме» + текст; etc.
- [ ] Interpretations используют planet archetype × house meaning composition (no Daragan verbatim).

### Meeting place invariant

- [ ] Distribution для same Olga с meeting_place=Питер DIFFERS from meeting_place=None (per Stage 6 test).
- [ ] Existing «Соляр — позиции планет» reference table preserved unchanged.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 653 + N` (N = 14 new tests). 0 failed, 0 xfailed.
- [ ] Frontend `npm run build` — N/A (no frontend change).
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (helper + template + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 5.

### Discipline

- [ ] Used `solar_chart.positions` (NOT `natal_chart.positions`).
- [ ] Used `house_placidus` (NOT natal house).
- [ ] Lilith / Nodes NOT invented if absent from facts.
- [ ] No engine touch.
- [ ] No meeting_place invariant break.
- [ ] No Daragan verbatim copy.
- [ ] Existing reference table preserved.
- [ ] Interpretations cover all 10 planets across encountered houses.

## STOP triggers

- Worker uses `natal_chart.positions` instead of `solar_chart.positions` → STOP, wrong source.
- Worker uses `annual_transit_table` instead → STOP, wrong scope.
- Worker invents Lilith / North Node / etc. when absent from facts → STOP, render only computed bodies.
- Worker touches Haskell core → STOP, scope is presentation only.
- Worker breaks meeting_place invariant (distribution must respond to meeting_place changes) → STOP.
- Worker replaces existing «Соляр — позиции планет» reference table → STOP, add new section, не заменять.
- Worker copies Daragan book verbatim → STOP, author's own short prose.
- Worker introduces LLM → STOP, deterministic only.

## Reviewer subagent — per § Ready clarification 5

Tier B feature with content authoring. Per recent precedent: similar Tier B content TASKs (specificity / generic-psychology) used REQUIRED Reviewer. Geocode (B UX feature) used optional. This TASK has both new helper logic + content authoring — could go either way.

## Context

**Mode normal + Tier B (Reviewer disposition per § Ready).** Worker mode: normal.

**Baseline:**
- Product main @ `948cbdc` (Geocode Autocomplete closed).
- Overlay master @ `2bf7a8d` (latest closure).
- Pytest baseline: `653 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Schema source: `facts.solar_chart.positions[*]` (TL-verified для Olga consultation 12).
- Canonical house meanings (READ only, don't modify): `services/api-python/app/pdf/house_meanings.py`.
- Solar Meeting Place predecessor (preserved invariant): product commit `5070ea0` + meeting_place plumbing.
- Existing reference table: `solar.html.j2` (preserve unchanged).
- Russian planet names dict (reuse if exists): `outer_cards.py:1488` (`_PLANET_NOM_RU`) или similar.
- Marina reference style: образец `Соляр 2026-2027 (2).pdf` (already used as anchor в previous TASKs).

**Not in scope (explicit):**
- Engine modifications.
- Lilith / Nodes / Chiron / asteroids (engine doesn't compute them).
- Natal chart distribution (separate concept).
- Transit table.
- LLM.
- Modifying canonical `house_meanings.py` или `house_pair_themes.py`.
- Modifying existing «Соляр — позиции планет» reference table.

**Ready: no** — pending 5 clarifications below.

## Ready clarifications (pending user direction 2026-05-20)

1. **Planet archetype dict location.**
   - (a) **Embedded в `solar_house_distribution.py`** — self-contained.
   - (b) **Extend `house_meanings.py`** — single source of truth (но conflicts с house-focused pattern).
   - (c) **New module `planet_archetypes.py`** — separate planet vocabulary, future-reusable.
   - (d) Worker proposes.

2. **PDF section placement.**
   - (a) После «Соляр — позиции планет» reference table (at top of forecast region).
   - (b) Перед «Итоги консультации» (near end, as synthesis context).
   - (c) After monthly transit table (mid PDF).
   - (d) Worker proposes.

3. **Axis accent threshold.**
   - (a) ≥3 planets on axis = accent.
   - (b) ≥4 (more conservative).
   - (c) Worker proposes (e.g. `≥ total_planets // 4` = 2-3 planets for 10-planet typical).

4. **Interpretation coverage strategy.**
   - (a) **Compositional generic** (10 archetypes × 12 house_meanings) — covers all 120 combinations via composition.
   - (b) **Per-(planet, house) overrides catalog** — Worker authors 30-50 hand-crafted entries для high-significance combinations + compositional fallback.
   - (c) Worker proposes.

5. **Reviewer subagent.**
   - (a) Optional + TL inline-verify + manual PDF inspection.
   - (b) REQUIRED external Reviewer (Tier B content authoring; parallel к specificity-enrichment / generic-psychology pattern).
