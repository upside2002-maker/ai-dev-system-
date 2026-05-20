# TASK: current-year-generic-cards-and-psychology-upgrade

- Status: review
- Ready: yes
- Date: 2026-05-20
- Project: astro
- Layer: services (Python presentation: `outer_cards.py` — solar-year overlap filter в `generic_outer_cards` + specific psychology dict + tests)
- Risk tier: B+ (two-concern multi-block change: filtering logic в generic-fallback path + phrase library upgrade с new override dict; new tests; no architecture rewrite; no engine touch; no calibrated data touch)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User Marina-show preparation audit 2026-05-20 на Olga consultation 12 PDF (`/Users/ilya/Projects/astro/data/pdf/consultation-12.pdf` @ product `3d36b2f`) identified **2 separate bugs**:

### Bug 1 — Previous-year transits leak into current solar year

`generic_outer_cards` reads full `annual_transit_table` без filtering by current solar year. Engine buffer (per Phase 8E) extends ±730d before/after SR, so multi-year touches leak в раздел «Транзиты высших планет» для current consultation.

**Concrete example (Olga consultation 12, solar 2026-2027):**

`тр Уран в секстиле c нат Меркурием` displays only past-year windows:
- 13.07.2024 – 13.08.2024 (pre-SR'2026)
- 20.09.2024 – 20.11.2024 (pre-SR'2026)
- 19.04.2025 – 21.05.2025 (pre-SR'2026)

ALL three windows fall **outside Olga's current solar year [SR'2026, SR'2026+365d]**. Карточка не должна попадать в раздел текущего соляра.

### Bug 2 — Generic psychology too template-driven for key combinations

`_generic_psychology_text` hybrid 3-dim composition produces correct layer-separated output, но **семантическая конкретика для key (transit, aspect, target) combinations слабая**.

**Concrete example (Olga «Уран кв Меркурий» если бы он остался):**

Current generic psychology:

> «Внутри поднимается потребность в свежести и свободе, тяга к новому и неожиданному. Эта тема касается того, как устроены ум, способ думать и общаться с миром. И это идёт через мягкое открывающееся окно — внутренний шанс, который важно разглядеть и поддержать встречным движением.»

**Target style (user-provided 2026-05-20):**

> «Гармоничный транзит ментального обновления: ум становится быстрее, гибче, оригинальнее. Хорошее время для обучения, новых тем, технологий, генерации идей и нестандартных решений. Могут приходить внезапные инсайты; легче общаться, выражать необычные мысли и смотреть на привычные вещи свежо.»

Key semantic differences:
- «Гармоничный транзит» (explicit aspect-tone descriptor, не «мягкое окно»).
- «Ментальное обновление» (specific to Uranus-Mercury combination).
- Concrete activities: обучение / технологии / идеи / инсайты.
- «Быстрее, гибче, оригинальнее» (concrete adjectives, не «свежесть и свобода»).
- Lighter, more practical tone (не «внутренний шанс, который важно разглядеть»).

**Programme classification:** code-quality two-concern TASK. Bug 1 = filter logic в `generic_outer_cards`; Bug 2 = phrase library enrichment via new override dict.

## Worker framing (verbatim user direction 2026-05-20)

### Bug 1 direction

> «Софт сейчас действительно тащит транзиты из расширенного buffer'а, а не только из текущего солярного года. Поэтому в соляр 2026-2027 попал, например, тр Уран в секстиле c нат Меркурием с окнами 2024 года. Это не должно показываться в PDF текущего соляра.»

### Bug 2 direction

> «Психологический уровень стал лучше, но всё ещё слишком шаблонный. Для Уран секстиль Меркурий он должен звучать примерно так: ментальное обновление, идеи, обучение, быстрый и изобретательный ум, инсайты, технологии, лёгкое общение.»

> «Можно опираться на Дарагановскую логику транзитов и общую астрологическую традицию, но: не копировать книгу дословно; не вставлять длинные цитаты; формулировки должны быть авторскими; в коде не должно появиться copyrighted prose dump.»

## Scope (Tier B+ two-concern fix)

### Stage 1 — Current-year overlap filter (Bug 1)

**1.1 — Filter rule:**

```python
solar_start = facts["solar_chart"]["return_jd"]
solar_end = solar_start + 365.25  # OR per § Ready clarification 1 — pull exact next-return JD

# Window-level overlap (per user verbatim):
window_overlaps_year = (window_end >= solar_start) and (window_start <= solar_end)

# Card-level: keep card iff ≥1 window passes
card_eligible = any(window_overlaps_year(w) for w in card.display_windows)
```

**1.2 — Two-level filtering applied per user direction:**
- **Card-level:** if zero display_windows overlap current solar year → drop card entirely.
- **Window-level:** within kept card, filter display_windows array — show only windows overlapping year boundaries.

Per user verbatim: «display intervals generic карточки должны быть отфильтрованы: не показывать окна, которые целиком до solar_start или целиком после solar_end».

**1.3 — Location в `generic_outer_cards`:**

After `aggregate_display_windows(raw)` call, apply window-level filter; if remaining windows empty → continue (drop card).

**1.4 — Boundary precision (per user clarification 1 = (a) approximate):**

`solar_end = solar_start + 365.25` (tropical year approximation). Достаточно — для Marina-показа precision ±1 day vs exact next-SR не существенна. Simple, generic, не требует engine field check.

### Stage 2 — Specific psychology override dict (Bug 2)

**2.1 — New phrase library `_SPECIFIC_PSYCHOLOGY_RU` (per user clarification 2 = (c) Worker proposes 6-12 with mandatory minimum):**

Curated dict keyed by `(transit_planet, aspect, target)` для key combinations.

**Mandatory minimum 4 entries (per user direction verbatim 2026-05-20):**

```python
_SPECIFIC_PSYCHOLOGY_RU: dict[tuple[str, str, str], str] = {
    ("Uranus", "Sextile", "Mercury"): "...",  # ментальное обновление
    ("Uranus", "Square", "Venus"):    "...",  # романтика свободы / обновление вкусов
    ("Neptune", "Trine", "Jupiter"):  "...",  # мечта расширения / вдохновение
    ("Pluto", "Sextile", "Uranus"):   "...",  # глубинная перестройка свободы
    # + Worker proposes 2-8 more entries по частотности / важности (per user direction).
}
```

**Worker scope:** 6-12 total entries. NOT Olga-only (filter logic dimension), NOT 90-entry prose dump. Worker prioritizes по frequency / archetypal importance для personal targets (Sun/Moon/Mercury/Venus/Mars/Jupiter typically) или high-significance outer-outer (e.g. Neptune-Pluto).

Each entry must include explicit aspect-tone descriptor («гармоничный транзит» / «напряжённый транзит» / «глубинный транзит» / etc.) per Stage 2.3 (clarification 3 = (a) embedded).

**2.2 — Composition routing:**

```python
def _generic_psychology_text(transit_planet, aspect, target, ...):
    # Same-planet route preserved (highest priority)
    if transit_planet == target:
        return _SAME_PLANET_PSYCHOLOGY_RU.get((transit_planet, aspect), "")
    
    # NEW: specific override route (second priority)
    specific = _SPECIFIC_PSYCHOLOGY_RU.get((transit_planet, aspect, target))
    if specific:
        return specific
    
    # Fallback: hybrid 3-dim composition (existing)
    # ... existing logic ...
```

**2.3 — Tone-descriptor strategy (per user clarification 3 = (a) embedded directly):**

User direction 2026-05-20 verbatim: «Aspect tone embedded directly в specific entries. Пусть конкретные entries звучат цельно: "Гармоничный транзит ментального обновления…", а не собираются механически из prefix'ов.»

Worker weaves aspect-tone descriptor **naturally в prose** каждой `_SPECIFIC_PSYCHOLOGY_RU` entry. NOT mechanical assembly via separate `_ASPECT_TONE_PREFIX_RU` dict. Each curated entry — целостный paragraph с tone inline:

✅ Good: «Гармоничный транзит ментального обновления: ум становится быстрее, гибче, оригинальнее. ...»

❌ Bad (mechanical assembly): «Гармоничный транзит. Внутри... Эта тема... И идёт через...»

Hybrid fallback path: `_ASPECT_PSYCHOLOGY_RU` closer уже encodes tone implicitly («идёт через мягкое окно» = sextile tone). No separate prefix dict needed.

### Stage 3 — Test extension (per user clarification 4 = (a) extend existing)

Extend `services/api-python/tests/test_transit_section_generic.py`. NO new file. Consistent с предшественниками (Generic Psychology landed +38 tests там).

**3.1 — Current-year filter tests:**

```python
def test_olga_generic_cards_no_2024_only_uranus_mercury():
    """Olga consultation 12: card with all windows in 2024-2025 must be dropped."""
    facts = _olga_facts()
    cards = generic_outer_cards(facts, tz_id="Europe/Moscow")
    titles = {c["title"] for c in cards}
    assert "тр Уран в секстиле c нат Меркурием" not in titles, (
        "Card with no current-year windows should be filtered"
    )

def test_olga_all_displayed_cards_overlap_current_solar_year():
    """Every displayed card has ≥1 window overlapping [SR, SR+365.25]."""
    facts = _olga_facts()
    sr = facts["solar_chart"]["return_jd"]
    cards = generic_outer_cards(facts, tz_id="Europe/Moscow")
    for c in cards:
        assert _any_window_overlaps_year(c, sr, sr + 365.25), (
            f"Card {c['title']} has no current-year window"
        )

def test_olga_display_intervals_only_within_current_year():
    """Within each card, all displayed intervals overlap current solar year."""
    facts = _olga_facts()
    sr = facts["solar_chart"]["return_jd"]
    cards = generic_outer_cards(facts, tz_id="Europe/Moscow")
    for c in cards:
        for iv in c.get("intervals", []):
            assert _window_overlaps_year(iv, sr, sr + 365.25), (
                f"Card {c['title']} has out-of-year interval {iv}"
            )
```

**3.2 — Specific psychology tests:**

```python
def test_uranus_sextile_mercury_psychology_specific():
    psych = _generic_psychology_text("Uranus", "Sextile", "Mercury", None)
    # Semantic positive
    must_contain_at_least_one_of = {
        "ment": ["ментал", "мышлен", "ум"],
        "novelty": ["нов", "обновлен"],
        "ideas": ["иде"],
        "learning": ["обуч"],
        "insight": ["инсайт", "озарен"],
        "communication": ["общ"],
        "flexibility": ["гибк", "оригиналь"],
    }
    for theme, candidates in must_contain_at_least_one_of.items():
        assert any(c in psych for c in candidates), (
            f"Uranus-Sextile-Mercury psychology missing {theme} keywords"
        )
    # Strict negative
    for forbidden in ["дом", "натального дома", "сферы", "Ситуация коснётся"]:
        assert forbidden not in psych
```

**3.3 — Preserved acceptance tests** (no regression):
- Layer-separation guard across all generic cards.
- Same-planet routing для Uranus-Uranus / Neptune-Neptune / Pluto-Pluto.
- Calibrated allowlist bit-identical.

### Stage 4 — Calibrated regression check

All 6 calibrated cases (`OUTER_CARD_ALLOWLIST` entries) must render unchanged:
- Card count preserved.
- Window content preserved (calibrated cases may have pre-SR windows by design; allowlist branch is не affected by Bug 1 filter — filter applies ONLY к generic-fallback path).
- Psychology / event_level texts unchanged.

Worker verifies via existing calibrated tests (`test_calibrated_cards_bit_identical_except_provenance`) — must still PASS.

## Files

- modify:
  - `services/api-python/app/pdf/outer_cards.py` — filter в `generic_outer_cards` + `_SPECIFIC_PSYCHOLOGY_RU` dict + routing в `_generic_psychology_text`.
  - `services/api-python/tests/test_transit_section_generic.py` — extension per § Ready clarification 4.
  - `project-overlays/astro/STATUS_RU.md`.

- new: —

- delete: —

## Do not touch

- **Engine buffer** (Phase 8E `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE/AFTER`) — preserved для calibrated cases с multi-year touch windows.
- `OUTER_CARD_ALLOWLIST` — calibrated allowlist data.
- `_OUTER_CARD_FACTS` — Marina-curated calibrated cards.
- Calibrated branch в `outer_cards_for_case` — **only generic-fallback path affected per Guard #1 (see § Additional guards below).**
- `_generic_event_level_text` — event-level houses preserved.
- `_TRANSIT_PSYCHOLOGY_RU` / `_TARGET_PSYCHOLOGY_RU` / `_ASPECT_PSYCHOLOGY_RU` / `_SAME_PLANET_PSYCHOLOGY_RU` — existing libraries used as fallback; entries preserved.
- Engine: Haskell core, schema, fixtures.
- `solar.html.j2` template.
- `builder.py`.
- Phase 9.x artifacts.
- `_legacy_compose_theme_prose` (synthesis module orphan).
- **NO LLM / GPT API.**
- **NO Daragan verbatim copying.** Use Daragan-style archetypal logic; author's own short phrasings.
- **NO Olga-only hardcoded behavior.** Filter logic + dict apply to ANY chart.
- **NO removing valid current-year cards** while filtering out-of-year cards (false-positive guard).

## Acceptance

### Bug 1 — Current-year filter (Olga consultation 12)

- [ ] `тр Уран в секстиле c нат Меркурием` NOT в Olga's generic outer cards (all 3 windows 2024-2025 outside SR'2026).
- [ ] Every displayed generic card has ≥1 display window overlapping `[return_jd, return_jd + 365.25]`.
- [ ] Within each kept card, display intervals filtered — no windows ending before `solar_start` OR starting after `solar_end`.
- [ ] Total generic card count для Olga: ≤ pre-filter count (some cards may drop).
- [ ] Other generic cards с valid current-year windows preserved (Uranus-Venus, Uranus-Uranus, Uranus-Jupiter, Neptune-Jupiter, Neptune-Uranus, Pluto-Uranus + over-includes if they have current-year windows).

### Bug 2 — Specific psychology (Olga consultation 12)

- [ ] If `тр Уран в секстиле c нат Меркурием` НЕ filtered out (test fixture с current-year window для Uranus-Sextile-Mercury), его psychology contains specific keywords:
  - `ментал` / `мышлен` / `ум` (≥1).
  - `нов` / `обновлен` (≥1).
  - `иде` (≥1).
  - `обуч` (≥1).
  - `инсайт` / `озарен` (≥1).
  - `общ` (≥1).
  - `гибк` / `оригиналь` (≥1).
- [ ] Psychology layer-separation preserved (no house language).
- [ ] Aspect-tone descriptor («гармоничный» / «напряжённый» / etc.) present для specific overrides.
- [ ] Fallback hybrid composition preserved для combinations not в `_SPECIFIC_PSYCHOLOGY_RU`.

### Calibrated regression

- [ ] All 6 calibrated cases (`OUTER_CARD_ALLOWLIST` entries) render с unchanged psychology / event / windows / card count.
- [ ] `test_calibrated_cards_bit_identical_except_provenance` passes.
- [ ] `_OUTER_CARD_FACTS` bit-identical.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 565 + N` (N new tests). 0 failed, 0 xfailed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (filter + dict + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 5.

### Discipline

- [ ] NO engine buffer change (filter is presentation-layer; engine output preserved).
- [ ] NO calibrated allowlist modifications.
- [ ] NO LLM.
- [ ] NO Daragan verbatim copy.
- [ ] NO Olga-only hardcoded text.
- [ ] Filter logic generic — works на любой chart с любым SR JD.
- [ ] Specific psychology dict entries are author's own; spot-checks pass (no 3+ word match с published Daragan phrasings).
- [ ] Fabrication-guard preserved: if `_SPECIFIC_PSYCHOLOGY_RU` entry missing AND hybrid composition missing dimension → return empty string, NOT generic-padding.

## STOP triggers

- Worker tempted to shrink engine buffer → STOP, filter is presentation-layer only.
- Worker tempted to modify calibrated allowlist → STOP, scope is generic-fallback path.
- Worker tempted to put houses back в psychology → STOP, layer-separation preserved.
- Worker tempted to copy Daragan verbatim → STOP, author own short phrasings.
- Worker tempted to hardcode Olga-only behavior → STOP, generator generic.
- Worker tempted to remove valid current-year cards while filtering past-year → STOP, false-positive guard.
- Worker cannot trace displayed card windows к `facts["solar_chart"]["return_jd"]` → STOP, escalate.
- Worker tempted to add LLM → STOP, deterministic only.
- Worker tempted to add generic-padding fallback when `_SPECIFIC_PSYCHOLOGY_RU` entry missing → STOP, fabrication-guard-consistent empty.
- **Worker tempted to apply current-year filter к calibrated cards** → STOP per Guard #1, scope is generic-fallback only.
- **Worker tempted to keep out-of-year windows «для контекста» в generic output** → STOP per Guard #2, strict window-level filter.
- Worker writes `_SPECIFIC_PSYCHOLOGY_RU` entry без embedded aspect-tone descriptor → STOP, tone должен быть woven naturally per clarification 3.
- Worker writes <4 mandatory entries (Uranus-Sextile-Mercury, Uranus-Square-Venus, Neptune-Trine-Jupiter, Pluto-Sextile-Uranus) → STOP, mandatory minimum violation.
- Worker writes >12 entries «for completeness» → STOP, scope creep beyond 6-12 user direction.

## Reviewer subagent — REQUIRED (per user clarification 5 = (a))

External Reviewer pass REQUIRED после Worker self-submit. Parallel к Tier B+ predecessor pattern. If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- **Bug 1 verification (current-year filter):**
  - Olga `тр Уран в секстиле c нат Меркурием` NOT в generic cards (all windows 2024-2025).
  - Every displayed generic card has ≥1 window overlapping `[SR, SR+365.25]`.
  - Within each card, NO out-of-year display intervals (strict per Guard #2).
  - Calibrated allowlist cards bit-identical (filter NOT applied to calibrated path per Guard #1).
- **Bug 2 verification (specific psychology):**
  - 4 mandatory minimum entries present (Uranus-Sextile-Mercury, Uranus-Square-Venus, Neptune-Trine-Jupiter, Pluto-Sextile-Uranus).
  - 6-12 total entries (Worker propose remainder с justification).
  - Each entry embeds aspect-tone descriptor naturally (NOT mechanical assembly).
  - Specific entries pass user-listed semantic keywords (Uranus-Sextile-Mercury: ментал/ум, нов/обновлен, иде, обуч, инсайт, общ, гибк/оригиналь).
  - Hybrid fallback preserved для non-curated combos.
  - Empty-string fallback preserved (NO generic-padding when no entry в any dict).
  - No Daragan verbatim copy (Reviewer spot-checks 3+ specific entries).
- **Layer-separation preserved** (psychology no houses; event_level has houses).
- **No Olga-only hardcoded behavior** в either Bug 1 или Bug 2 fix.
- **0 STOP triggers fired.**

## Context

**Mode normal + Tier B+ (Reviewer REQUIRED per user clarification 5).** Worker mode: normal.

## Additional guards (per user direction 2026-05-20)

### Guard #1 — Filter scope (calibrated cards preserved)

> «Current-year filtering applies only to generic fallback cards. Calibrated allowlist cards keep their existing display-window behavior.»

Filter logic применяется **только в `generic_outer_cards` path** (non-calibrated dispatch). Calibrated cases (01/02/03/04/05/07/08/09/10) routed через `outer_cards_for_case` allowlist branch — sets display windows из curated `_OUTER_CARD_FACTS` data, не from `annual_transit_table`. Filter NOT applied к этим cards.

Worker test: `test_calibrated_cards_bit_identical_except_provenance` passes без изменений. Worker manually verifies multi-year windows (e.g. 01-kseniya Uranus Opposition Sun multi-touch 2024-2026) preserved в calibrated render.

### Guard #2 — Window-level strict filtering (no «context» retention)

> «If a card has multiple windows, keep only windows overlapping the current solar year. Do not keep old windows "for context" in generic output.»

Window-level filter strict: каждое окно tested независимо.
- Окно «целиком до solar_start» (window_end < solar_start) → drop.
- Окно «целиком после solar_end» (window_start > solar_end) → drop.
- Окно overlapping (window_end ≥ solar_start AND window_start ≤ solar_end) → keep.

Если after window filtering все окна dropped → drop card entirely.

**No «context» retention:** не оставляем pre-SR / post-SR windows «для понимания контекста». Текущий solar year only.

**Baseline:**
- Product main @ `3d36b2f` (Generic Psychology closed).
- Overlay master @ `c33a53b` (Generic Psychology closure).
- Pytest baseline: `565 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Bug 1 location: `services/api-python/app/pdf/outer_cards.py` `generic_outer_cards` function (filter goes here).
- Bug 2 location: `services/api-python/app/pdf/outer_cards.py` `_generic_psychology_text` (after `_SAME_PLANET_PSYCHOLOGY_RU` route, add `_SPECIFIC_PSYCHOLOGY_RU` route before hybrid fallback).
- Predecessor TASKs: `evidence-based-rewrite` (`a6a3331`) → `human-readable` (`7644d7f`) → `tail-template-polish` (`1074cf8`) → `specificity-enrichment` (`8e59ea9`) → `generic-psychology` (`3d36b2f`).
- Phase 8E buffer extension (engine, NOT modified): `services/api-python/app/ephemeris/bridge.py:_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE/AFTER`.
- Olga DB consultation 12 (acceptance target).
- Marina-Olga reference PDF (style anchor для Bug 2): `/Users/ilya/Downloads/Соляр 2026-2027 (2).pdf`.

**Not in scope (explicit):**
- Engine buffer modifications.
- Calibrated allowlist changes.
- Phase 9.x sub-problems (closed/deferred).
- LLM integration.
- Daragan verbatim copying.
- Other PDF sections (Натальная карта / Соляр tables / монт-аспект calendar / Дирекции).

**Ready: yes** — 5 clarifications applied 2026-05-20 + 2 additional guards:

1. **Solar-year boundary = (a) approximate.** `solar_end = solar_start + 365.25`. Достаточно; не усложняем next-SR field для marginal precision. Applied Stage 1.4.

2. **`_SPECIFIC_PSYCHOLOGY_RU` coverage = (c) Worker proposes 6-12** с mandatory minimum 4 entries:
   - `("Uranus", "Sextile", "Mercury")`
   - `("Uranus", "Square", "Venus")`
   - `("Neptune", "Trine", "Jupiter")`
   - `("Pluto", "Sextile", "Uranus")`
   Worker proposes 2-8 more по frequency / importance. Not Olga-only, not 90-entry prose dump. Applied Stage 2.1.

3. **Aspect tone = (a) embedded directly.** Tone descriptor («Гармоничный транзит ментального обновления…») woven naturally в каждой specific entry. NOT mechanical prefix assembly. Applied Stage 2.3.

4. **Test file = (a) extend** `test_transit_section_generic.py`. NO new file. Applied Stage 3.

5. **Reviewer = (a) REQUIRED.** External pass after Worker submit. Applied Reviewer section.

**Additional guards (per user direction 2026-05-20, verbatim):**

### Guard #1 — Filter scope:
> «Current-year filtering applies only to generic fallback cards. Calibrated allowlist cards keep their existing display-window behavior.»

### Guard #2 — Window-level strict filtering:
> «If a card has multiple windows, keep only windows overlapping the current solar year. Do not keep old windows "for context" in generic output.»

Both applied across Stage 1 implementation + Do not touch + STOP triggers + Reviewer criteria + Acceptance.
