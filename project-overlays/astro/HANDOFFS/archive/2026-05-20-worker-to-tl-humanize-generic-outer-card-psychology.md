# HANDOFF: worker → tl — humanize-generic-outer-card-psychology

- Status: closed
- Date: 2026-05-20
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-20-humanize-generic-outer-card-psychology.md
- Product repo status: committed + pushed (1 product commit `3d36b2f`)
- Overlay repo status: pending (HANDOFF + STATUS_RU; one overlay commit)
- Risk tier: B (single helper rewrite + 4 phrase libraries; +33 new tests; no architecture rewrite; no engine touch; no calibrated data touch)
- Reviewer policy: REQUIRED per clarification 5 = (b)
- Reviewer status: Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 8th occurrence) → Worker self-review applied; TL must spawn external Reviewer per TASK clarification 5.

## Summary

Rewrote `_generic_psychology_text` (`services/api-python/app/pdf/outer_cards.py:1470-1504` pre-task → completely replaced) to fix the 4-layer bug user identified 2026-05-20: psychology layer was emitting engine technical strings («Транзит Уран в квадрате c натальной Венерой в области 4 натального дома. Транзитная планета приносит неожиданные перемены...») which mixed (1) engine technical string + (2) house language + (3) tonality + (4) archetype in a single paragraph that read like engine-comment, not consultation.

New implementation builds 4 controlled phrase libraries and composes them into a single coherent paragraph per the hybrid algorithm (clarification 1 = (c)):

  - `_TRANSIT_PSYCHOLOGY_RU` (3 outer planets) — opener phrase.
  - `_TARGET_PSYCHOLOGY_RU` (10 natal targets) — middle phrase.
  - `_ASPECT_PSYCHOLOGY_RU` (5 Ptolemaic aspects) — closer phrase.
  - `_SAME_PLANET_PSYCHOLOGY_RU` (15 entries: 3 outer planets × 5 aspects each) — generational age-stage signatures for same-planet outer aspects (clarification 3 = (a) specialized routing).

Empty-string fallback when dimension dict entry absent (clarification 2 = (b) skip; no generic-padding). Layer-separation guard enforced: psychology NEVER mentions houses; event_level (`_generic_event_level_text`) untouched and continues to surface house language.

Pytest **527 → 565 passed + 2 skipped + 0 failed** (+38 new tests). Cabal `Up to date`. NO LLM. NO Daragan verbatim copy. NO engine modifications. NO `_OUTER_CARD_FACTS` / `_generic_event_level_text` / `OUTER_CARD_ALLOWLIST` modifications. Calibrated 6-case regression PASS bit-identical (`test_calibrated_cards_bit_identical_except_provenance`).

## Stage 1 — Audit (pre-implementation)

Worker inventoried current state and verified strict prohibitions:

| File / Symbol | State | Action |
|---|---|---|
| `outer_cards.py:1470-1504` `_generic_psychology_text` | Buggy engine-string emit | **Rewrite (in scope)** |
| `outer_cards.py:1507-1543` `_generic_event_level_text` | Correctly uses houses | **Preserve verbatim (DO NOT TOUCH)** |
| `outer_cards.py:~496-810` `_OUTER_CARD_FACTS` | Calibrated Marina cards (psychology curated) | **Preserve bit-identical (DO NOT TOUCH)** |
| `outer_cards.py:271-318` `_PLANET_*_RU` / `_ASPECT_*_RU` | Existing helper dicts | **Preserve unchanged** |
| `outer_cards.py:1413-1427` `_ASPECT_CHARACTER_RU` / `_ASPECT_NOM_RU` | Used by event_level only | **Preserve unchanged** |
| `OUTER_CARD_ALLOWLIST` | Calibrated allowlist | **Preserve** |
| `solar.html.j2`, `builder.py`, engine Haskell core | Not in scope | **Untouched** |

Olga consultation 12 baseline output captured (6 generic cards):

```
1. тр Уран в квадрате c нат Венерой  (Uranus Square Venus)
2. тр Уран в оппозиции c нат Юпитером  (Uranus Opposition Jupiter)
3. тр Уран в оппозиции c нат Ураном  (Uranus Opposition Uranus — same-planet)
4. тр Нептун в тригоне c нат Юпитером  (Neptune Trine Jupiter)
5. тр Нептун в тригоне c нат Ураном  (Neptune Trine Uranus)
6. тр Плутон в секстиле c нат Ураном  (Pluto Sextile Uranus)
```

Each pre-rewrite psychology started «Транзит X в Y c натальным Z в области N натального дома. Транзитная планета ...» — bug surface verified verbatim.

## Stage 2 — Phrase library design

### 2.1 — `_TRANSIT_PSYCHOLOGY_RU` (3 entries)

Each value: opener phrase describing the inner process the transit brings. Length ~12-18 words. Anchored к Daragan-style archetypes (NOT verbatim copy).

```python
_TRANSIT_PSYCHOLOGY_RU = {
    "Uranus":  "Внутри поднимается потребность в свежести и свободе, тяга к новому и неожиданному",
    "Neptune": "Внутри усиливается чувствование и тяга к большой мечте, привычные границы становятся прозрачнее",
    "Pluto":   "Внутри разворачивается глубинная перестройка, тянет к концентрации внутренней силы",
}
```

Coverage of TASK keywords (semantic positive test):
- Uranus: contains `свеж`, `свобод`, `нов` (matches `свежесть` / `свобода` / `новизн` test patterns by root).
- Neptune: contains `чувств`, `мечт`, `границ` (matches `вер` indirectly via Jupiter target, `мечт` directly).
- Pluto: contains `перестройк`, `глубин` (matches `перестройк` / `глубин` directly).

### 2.2 — `_TARGET_PSYCHOLOGY_RU` (10 entries)

Middle phrase used after the connector «Эта тема касается того, как устроены …». Genitive/accusative form fitting that connector.

```python
_TARGET_PSYCHOLOGY_RU = {
    "Sun":     "жизненная воля и самоощущение, ощущение собственного «я»",
    "Moon":    "эмоциональная база, переживание уюта и внутренней опоры",
    "Mercury": "ум, способ думать и общаться с миром",
    "Venus":   "близость, удовольствие, вкусы и способ выбирать красивое",
    "Mars":    "действие, напор и способ заявлять о себе",
    "Jupiter": "вера, ощущение смысла и широкого горизонта",
    "Saturn":  "структура, ответственность и внутренние границы",
    "Uranus":  "свобода, самостоятельность и отношение к необычному",
    "Neptune": "мечта, вдохновение и способность растворяться в большем",
    "Pluto":   "глубинная сила и тёмные ресурсы психики",
}
```

Each entry archetypal and case-agnostic. Worker designed phrasings within Daragan's archetypal envelope без verbatim copy. Each entry differs lexically — no «универсальная вода». Verified semantic positive coverage (Venus→`вкус`; Jupiter→`вер`/`смысл`/`горизонт`; Uranus→`свобод`/`самостоятельност`).

### 2.3 — `_ASPECT_PSYCHOLOGY_RU` (5 entries)

Closer phrase characterising the tonality of the contact. Each starts with «И …» providing natural Russian connector to the previous sentence (single-paragraph flow).

```python
_ASPECT_PSYCHOLOGY_RU = {
    "Conjunction": "И тема перепрошивается на глубоком уровне — старое и новое сливаются вплотную, отдельной дистанции между ними больше нет.",
    "Sextile":     "И это идёт через мягкое открывающееся окно — внутренний шанс, который важно разглядеть и поддержать встречным движением.",
    "Square":      "И старые формы начинают казаться тесными — нужно преодоление, чтобы пустить новое внутрь.",
    "Trine":       "И это идёт легко, как естественная поддержка — раскрывается само, если довериться процессу.",
    "Opposition":  "И возникает внутренний диалог двух сторон — нужно увидеть зеркало и сделать выбор между двумя картинами мира.",
}
```

Tonalities distinct: merge / soft window / tension / natural ease / mirror-choice. Quincunx intentionally absent (Correction 009 — Quincunx excluded from generic outer cards).

### 2.4 — `_SAME_PLANET_PSYCHOLOGY_RU` (15 entries)

Generational age-stage signatures for same-planet outer aspects. Routed when `transit_planet == target` (clarification 3 = (a)). Each entry is a complete paragraph (2 sentences) — no 3-dim composition needed; the «возрастной» framing carries the meaning directly.

Coverage: all 5 Ptolemaic aspects (Conjunction / Sextile / Square / Trine / Opposition) × 3 outer planets (Uranus / Neptune / Pluto) = 15 entries.

```python
_SAME_PLANET_PSYCHOLOGY_RU = {
    ("Uranus", "Conjunction"): "Внутри начинается новый круг темы свободы и самостоятельности. ...",
    ("Uranus", "Sextile"):     "Внутри открывается мягкое окно к собственной свободе — лёгкая возможность пересобрать привычное по-новому...",
    ("Uranus", "Square"):      "Внутри проходит возрастной перелом темы свободы и самостоятельности. ...",
    ("Uranus", "Trine"):       "Внутри открывается возрастной момент лёгкости в теме свободы ...",
    ("Uranus", "Opposition"):  "Внутри проходит возрастной перелом темы свободы — зеркало, в котором видно, что отжило ...",
    ("Neptune", "Conjunction"):"Внутри начинается новый виток мечты и веры ...",
    ("Neptune", "Sextile"):    "Внутри открывается тонкое окно к мечте ...",
    ("Neptune", "Square"):     "Внутри проходит возрастная проверка большой мечты ...",
    ("Neptune", "Trine"):      "Внутри открывается возрастной момент тонкого слышания ...",
    ("Neptune", "Opposition"): "Внутри встают друг напротив друга мечта и реальность ...",
    ("Pluto", "Conjunction"):  "Внутри начинается новый круг темы силы ...",
    ("Pluto", "Sextile"):      "Внутри открывается мягкое окно к собственной глубине ...",
    ("Pluto", "Square"):       "Внутри проходит возрастная инициация в собственную силу ...",
    ("Pluto", "Trine"):        "Внутри открывается возрастной момент спокойной силы ...",
    ("Pluto", "Opposition"):   "Внутри встают друг напротив друга прежнее и нарождающееся «я» ...",
}
```

(Full text in `outer_cards.py:1470-1597`.)

Generational framings honour user's clarification 3 spec verbatim:
- «Uranus aspect Uranus = возрастной перелом темы свободы и самостоятельности» ✓
- «Neptune aspect Neptune = возрастная проверка большой мечты» ✓
- «Pluto aspect Pluto = возрастная инициация в собственную силу» ✓

## Stage 3 — Composition algorithm

`_compose_hybrid_psychology(transit_phrase, target_phrase, aspect_closer)`:

```python
def _compose_hybrid_psychology(transit_phrase, target_phrase, aspect_closer):
    return (
        f"{transit_phrase}. "
        f"Эта тема касается того, как устроены "
        f"{target_phrase}. "
        f"{aspect_closer}"
    )
```

Three sentences joined via:
1. Period after transit opener.
2. Bridge connector «Эта тема касается того, как устроены …» introducing the target-psyche middle.
3. Aspect closer starts with «И …» (built into `_ASPECT_PSYCHOLOGY_RU` entries) — provides natural continuity to the previous sentence WITHOUT an explicit bridge connector.

Result reads as a single coherent consultation paragraph, NOT three glued cards. Worker validated visually on Olga's 5 hybrid-composition cards (6th is same-planet routed):

**Sample 1 — Uranus Square Venus (Olga, card 1):**

> «Внутри поднимается потребность в свежести и свободе, тяга к новому и неожиданному. Эта тема касается того, как устроены близость, удовольствие, вкусы и способ выбирать красивое. И старые формы начинают казаться тесными — нужно преодоление, чтобы пустить новое внутрь.»

User-provided envelope (NOT copied):
> «Внутри появляется потребность в свежести: иначе чувствовать, иначе выбирать, иначе реагировать на близость, красоту и удовольствие. Может тянуть к новому стилю, новым симпатиям, свободе в чувствах. Старые вкусы и привычные способы получать радость начинают казаться тесными.»

Worker's version is structurally distinct (3-dim composition, not user's free-flow paragraph) but semantically anchored on the same archetypal axes: свежесть / свобода / новое / близость / удовольствие / вкусы / старые формы тесны. ✓

**Sample 2 — Neptune Trine Jupiter (Olga, card 4):**

> «Внутри усиливается чувствование и тяга к большой мечте, привычные границы становятся прозрачнее. Эта тема касается того, как устроены вера, ощущение смысла и широкого горизонта. И это идёт легко, как естественная поддержка — раскрывается само, если довериться процессу.»

User-provided envelope: «Этот транзит усиливает веру, воображение и ощущение большого смысла...» — same archetypal axes (вера / мечта / смысл / широкий горизонт). ✓

**Sample 3 — Pluto Sextile Uranus (Olga, card 6):**

> «Внутри разворачивается глубинная перестройка, тянет к концентрации внутренней силы. Эта тема касается того, как устроены свобода, самостоятельность и отношение к необычному. И это идёт через мягкое открывающееся окно — внутренний шанс, который важно разглядеть и поддержать встречным движением.»

User-provided envelope: «Психологически это период глубокой внутренней перестройки: меняется отношение к свободе, самостоятельности и будущему...» — same archetypal axes (перестройка / свобода / самостоятельность / будущее → у Worker «новому и неожиданному» в transit + «необычному» в Uranus target). ✓

## Stage 4 — Same-planet specialized routing

Routing implemented at function entry:

```python
def _generic_psychology_text(transit_planet, aspect, target, target_natal_house):
    if transit_planet == target:
        return _SAME_PLANET_PSYCHOLOGY_RU.get((transit_planet, aspect), "")
    # ... standard 3-dim hybrid ...
```

Standard 3-dim composition does NOT fire for same-planet aspects. Verified on Olga card 3 (Uranus Opposition Uranus):

> «Внутри проходит возрастной перелом темы свободы — зеркало, в котором видно, что отжило и что просит обновления. Идёт пересборка собственной самостоятельности и способа жить иначе.»

This reads as generational/age-stage signature, NOT as «Uranus archetype + Uranus target + Opposition tone». User's clarification 3 spec verbatim implemented.

Worker added entries for all 5 Ptolemaic aspects per planet, not just the «especially» ones from TASK — this covers Uranus return (Conjunction ~84y) and Pluto/Neptune Sextile (younger generations contacting their own planet) even though they're rarer in adult consultations. Saturn / Jupiter / inner planets aspecting themselves are NOT outer-card territory (would be progressed-planet aspects, separate scope).

Empty fallback covered: `("Uranus", "Quincunx")` not in dict (Quincunx excluded per Correction 009) → returns empty string. Tested.

## Stage 5 — Acceptance tests (33 new + 1 retired = +32 net assertions)

Extended `services/api-python/tests/test_transit_section_generic.py` (clarification 4 = (a) extend; no new file). Imports added:

```python
from app.pdf.outer_cards import (
    _ASPECT_PSYCHOLOGY_RU,
    _SAME_PLANET_PSYCHOLOGY_RU,
    _TARGET_PSYCHOLOGY_RU,
    _TRANSIT_PSYCHOLOGY_RU,
    _generic_event_level_text,
    _generic_psychology_text,
)
```

**Strict-string negative (8 cards × 5 forbidden patterns = 40 assertions):**
`test_generic_psychology_no_house_language` parametrized on 8 (transit, aspect, target) triples. Each card: assert psychology contains none of `дом` / `натального дома` / `в области` / `Ситуация коснётся` / `сферы N дома` regex / legacy engine `Транзит ... c натальн` regex.

**Semantic positive (3 spotlight cards):**
`test_generic_psychology_semantic_positive` parametrized:
- Uranus-Square-Venus → matches at least one of `свежест` / `свобод` / `вкус` / `чувств` / `новизн`.
- Neptune-Trine-Jupiter → matches at least one of `вер` / `мечт` / `смысл` / `вдохновен` / `идеализ`.
- Pluto-Sextile-Uranus → matches at least one of `перестройк` / `глубин` / `свобод` / `трансформ` / `смел`.

**Layer-separation guard (4 cards, ≥3 mandated):**
`test_psychology_no_houses_event_level_has_houses` parametrized on Uranus-Square-Venus, Neptune-Trine-Jupiter, Pluto-Sextile-Uranus, Uranus-Opposition-Jupiter. For each: psychology MUST NOT contain any of {`дом`, `натального дома`, `в области`, `сфер`}; event_level MUST contain at least one of {`дом`, `сфер`}.

**Distinct output (2 tests):**
- `test_psychology_distinct_per_transit_planet` — for (Venus, Square) and (Jupiter, Trine), all three transits (Uranus / Neptune / Pluto) produce distinct strings.
- `test_psychology_distinct_per_aspect` — for (Uranus, Venus) and (Neptune, Jupiter), all five aspects produce 5 distinct strings.

**Same-planet specialized routing (6 (planet, aspect) tuples + 1 explicit distinct-from-standard):**
- `test_same_planet_specialized_routing` parametrized on 6 tuples (Uranus-Square, Uranus-Opposition, Uranus-Trine, Neptune-Square, Pluto-Square, Pluto-Sextile): asserts output == `_SAME_PLANET_PSYCHOLOGY_RU[(planet, aspect)]` bit-identical, AND no house tokens leaked.
- `test_same_planet_uranus_uranus_distinct_from_standard` — same-planet output must NOT contain the hybrid-composition signature «Эта тема касается того, как устроены».

**Empty fallback (4 tests):**
- Unknown transit (`Vulcan`) → empty.
- Unknown target (`Vulcan`) → empty.
- Unknown aspect (`Quincunx` — never in 3-dim path) → empty.
- Same-planet with unknown aspect (`Uranus, Quincunx, Uranus`) → empty.

**Determinism + signature stability (2 tests):**
- Identical inputs yield identical output.
- `target_natal_house` parameter ignored: house=1, house=4, house=None all produce identical psychology for (Uranus, Square, Venus). Layer-separation guard reinforced at signature level.

**Dict cardinality sanity (4 tests):**
- `_TRANSIT_PSYCHOLOGY_RU` covers exactly {Uranus, Neptune, Pluto}.
- `_TARGET_PSYCHOLOGY_RU` covers all 10 natal targets (Sun..Pluto).
- `_ASPECT_PSYCHOLOGY_RU` covers 5 Ptolemaic aspects.
- `_SAME_PLANET_PSYCHOLOGY_RU` covers 5 Ptolemaic aspects for each of {Uranus, Neptune, Pluto} (≥15 entries verified).

**Olga consultation 12 end-to-end (2 tests):**
- `test_olga_psychology_no_house_language` — all 6 Olga generic outer cards: psychology contains none of `дом` / `натального дома` / `в области` / `Ситуация коснётся` / regex; legacy engine regex absent.
- `test_olga_event_level_has_house_language` — all 6 cards: event_level contains `дом` or `сфер`.

**Modified existing test (1 retirement):**
- `test_olga_generic_cards_do_not_use_calibrated_texts` — retired `card["psychology"].startswith("Транзит ")` assertion (that template was THE bug fixed by this TASK). Replaced with `assert not _LEGACY_ENGINE_RE.search(psych)` + non-empty assertion. Event_level startswith check preserved.

Pytest counts:
- Before: 527 passed + 2 skipped + 0 failed
- After: **565 passed + 2 skipped + 0 failed** (+38 new tests)

The 2 skipped tests are existing case 07-mariya calibrated allowlist-empty skips — pre-existing baseline behaviour, unchanged.

## Olga acceptance — all 6 cards rendered

Full verbatim output (Olga consultation 12, DB-only):

### Card 1 — тр Уран в квадрате c нат Венерой (hybrid composition)

- **Psychology:** «Внутри поднимается потребность в свежести и свободе, тяга к новому и неожиданному. Эта тема касается того, как устроены близость, удовольствие, вкусы и способ выбирать красивое. И старые формы начинают казаться тесными — нужно преодоление, чтобы пустить новое внутрь.»
- **Event level:** «По характеру аспекта это напряжённая ситуация, требующая преодоления. Ситуация коснётся сфер 4, 12 дома. Транзитный Уран в этом году проходит по 12 натальному дому.»
- Layer separation: psychology 0 house tokens ✓; event_level 3 house tokens (`сфер`, `дом`, `натальному дому`) ✓.

### Card 2 — тр Уран в оппозиции c нат Юпитером (hybrid composition)

- **Psychology:** «Внутри поднимается потребность в свежести и свободе, тяга к новому и неожиданному. Эта тема касается того, как устроены вера, ощущение смысла и широкого горизонта. И возникает внутренний диалог двух сторон — нужно увидеть зеркало и сделать выбор между двумя картинами мира.»
- **Event level:** «По характеру аспекта это выбор, при котором чем-то придётся пожертвовать. Ситуация коснётся сфер 6, 11 дома. Транзитный Уран в этом году проходит по 12 натальному дому.»
- Layer separation: psychology 0 house tokens ✓; event_level 3 house tokens ✓.

### Card 3 — тр Уран в оппозиции c нат Ураном (same-planet specialized)

- **Psychology:** «Внутри проходит возрастной перелом темы свободы — зеркало, в котором видно, что отжило и что просит обновления. Идёт пересборка собственной самостоятельности и способа жить иначе.»
- **Event level:** «По характеру аспекта это выбор, при котором чем-то придётся пожертвовать. Ситуация коснётся сфер 6, 9, 10 дома. Транзитный Уран в этом году проходит по 12 натальному дому.»
- Same-planet routed to `_SAME_PLANET_PSYCHOLOGY_RU[("Uranus", "Opposition")]` ✓; standard hybrid connector absent ✓; layer separation: 0 house tokens в psychology, 3 в event_level ✓.

### Card 4 — тр Нептун в тригоне c нат Юпитером (hybrid composition)

- **Psychology:** «Внутри усиливается чувствование и тяга к большой мечте, привычные границы становятся прозрачнее. Эта тема касается того, как устроены вера, ощущение смысла и широкого горизонта. И это идёт легко, как естественная поддержка — раскрывается само, если довериться процессу.»
- **Event level:** «По характеру аспекта это гармоничная ситуация, которая может произойти сама. Ситуация коснётся сфер 6, 11 дома. Транзитный Нептун в этом году проходит по 11 натальному дому.»
- Layer separation: psychology 0 house tokens ✓; event_level 3 house tokens ✓.

### Card 5 — тр Нептун в тригоне c нат Ураном (hybrid composition)

- **Psychology:** «Внутри усиливается чувствование и тяга к большой мечте, привычные границы становятся прозрачнее. Эта тема касается того, как устроены свобода, самостоятельность и отношение к необычному. И это идёт легко, как естественная поддержка — раскрывается само, если довериться процессу.»
- **Event level:** «По характеру аспекта это гармоничная ситуация, которая может произойти сама. Ситуация коснётся сфер 6, 9, 10 дома. Транзитный Нептун в этом году проходит по 11 натальному дому.»
- Layer separation: psychology 0 house tokens ✓; event_level 3 house tokens ✓.

### Card 6 — тр Плутон в секстиле c нат Ураном (hybrid composition)

- **Psychology:** «Внутри разворачивается глубинная перестройка, тянет к концентрации внутренней силы. Эта тема касается того, как устроены свобода, самостоятельность и отношение к необычному. И это идёт через мягкое открывающееся окно — внутренний шанс, который важно разглядеть и поддержать встречным движением.»
- **Event level:** «По характеру аспекта это шанс на гармоничное развитие, который нужно разглядеть. Ситуация коснётся сфер 6, 9, 10 дома. Транзитный Плутон в этом году проходит по 9 натальному дому.»
- Layer separation: psychology 0 house tokens ✓; event_level 3 house tokens ✓.

## Layer-separation verification (manual proof)

Quick grep across all 6 Olga psychology strings:

| Forbidden token | Card 1 | Card 2 | Card 3 | Card 4 | Card 5 | Card 6 |
|---|---|---|---|---|---|---|
| `дом` | 0 | 0 | 0 | 0 | 0 | 0 |
| `натального дома` | 0 | 0 | 0 | 0 | 0 | 0 |
| `в области` | 0 | 0 | 0 | 0 | 0 | 0 |
| `сфер` | 0 | 0 | 0 | 0 | 0 | 0 |
| `Ситуация коснётся` | 0 | 0 | 0 | 0 | 0 | 0 |
| `Транзит ... c натальн` | 0 | 0 | 0 | 0 | 0 | 0 |

| Expected token | Event 1 | Event 2 | Event 3 | Event 4 | Event 5 | Event 6 |
|---|---|---|---|---|---|---|
| `сфер` | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ |
| `дом` | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ | ≥1 ✓ |

All 6 cards satisfy layer-separation guard. Automated tests `test_olga_psychology_no_house_language` + `test_olga_event_level_has_house_language` lock this.

## Calibrated allowlist preservation proof

`test_calibrated_cards_bit_identical_except_provenance` parametrized on 8 calibrated cases (01, 02, 03, 04, 05, 08, 09, 10 — 07 skipped per allowlist empty). All 8 PASS post-rewrite. This is the regression guard: rebuilt cards via `build_outer_card` match `outer_cards_for_case` output byte-for-byte. If `_generic_psychology_text` had leaked into the calibrated path or `_OUTER_CARD_FACTS` had been disturbed, this test would fail.

Additional explicit guard: `_OUTER_CARD_FACTS` not in `git diff outer_cards.py` (verified via grep: only `_generic_psychology_text` body and 4 new dicts added; `_OUTER_CARD_FACTS` lines 496-810 untouched).

## STOP triggers — final accounting

All 12 STOP triggers from TASK § STOP triggers verified clear:

- [x] No Daragan verbatim copy — phrasings author's own; Worker channeled archetypal logic (свобода/перемены/мечта/перестройка) without lexical copy. Each entry visibly distinct from Daragan's published wording.
- [x] No LLM call.
- [x] No house phrase в psychology text — 6 Olga cards verified 0 matches × 6 forbidden patterns.
- [x] `_generic_event_level_text` NOT modified — `git diff` shows zero changes to lines 1507-1543.
- [x] `_OUTER_CARD_FACTS` NOT modified — `git diff` shows zero changes to lines 496-810.
- [x] No generic «красивая вода» — each entry archetype-specific; semantic positive test enforces keyword anchoring per (transit, target, aspect) class.
- [x] Calibrated regression PASS — `test_calibrated_cards_bit_identical_except_provenance` × 8 cases.
- [x] Engine output / facts shape NOT requiring changes — used existing signature `(transit_planet, aspect, target, target_natal_house)`.
- [x] No generic-padding fallback — empty string emitted when dimension dict entry missing; 4 explicit tests verify.
- [x] No house language в psychology — verified.
- [x] Event_level WITH house language — verified.
- [x] Same-planet outer aspect routes к `_SAME_PLANET_PSYCHOLOGY_RU` — verified on Olga card 3 + 6 parametrized tuples + explicit distinctness test.
- [x] Composition reads as single coherent paragraph — natural connectors («Эта тема касается того, как устроены …» + closer starting with «И …»); 5 hybrid samples + 1 same-planet sample reviewed.

## Files touched

**Product (1 commit `3d36b2f`):**
- `services/api-python/app/pdf/outer_cards.py` — added 4 dicts + helper composition function + rewrote `_generic_psychology_text`. Net +199 lines, -33 lines = +166 net.
- `services/api-python/tests/test_transit_section_generic.py` — added 33 new tests + retired 1 legacy assertion + extended imports. Net +421 lines, -12 lines = +409 net.

**Overlay (pending, 1 commit planned):**
- `project-overlays/astro/HANDOFFS/2026-05-20-worker-to-tl-humanize-generic-outer-card-psychology.md` — this file.
- `project-overlays/astro/STATUS_RU.md` — append delivery entry.

**Untouched (verified):**
- `_OUTER_CARD_FACTS` (lines 496-810).
- `_generic_event_level_text` (lines 1507-1543).
- `OUTER_CARD_ALLOWLIST`.
- `_PLANET_NOM_RU` / `_PLANET_INSTR_RU` / `_ASPECT_LOC_RU` / `_ASPECT_NOM_RU` / `_ASPECT_CHARACTER_RU`.
- `solar.html.j2`.
- `builder.py`.
- Engine Haskell core (`core/astrology-hs`) — `cabal build` Up to date.
- Schema (`packages/contracts/*.schema.json`).
- Fixtures.
- Predecessor `synthesis_themes.py` (separate module).

## Verification

```
$ cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q
565 passed, 2 skipped in 59.49s

$ cd core/astrology-hs && PATH="/Users/ilya/.ghcup/bin:$PATH" cabal build all
Up to date

$ git status --short
(clean)

$ git log -1 --oneline
3d36b2f feat(pdf): humanize generic outer-card psychology — 3-dim hybrid composition + 4 phrase libraries

$ git push backup main
   8e59ea9..3d36b2f  main -> main
```

Product main `3d36b2f` ↔ Backup `3d36b2f` parity ✓.

## Reviewer policy

Per TASK clarification 5 = (b), external Reviewer pass is REQUIRED post-Worker-submit. **Agent tool unavailable в Worker runtime (8th occurrence per recurring Phase 8/9 precedent)** — Worker self-review applied; TL must spawn external Reviewer after this HANDOFF lands.

**Reviewer criteria from TASK § Reviewer:**
- [ ] Composition follows hybrid algorithm (transit opener + target-psyche middle + aspect tone closer); reads as single coherent paragraph, NOT three glued cards.
- [ ] 4 phrase library dicts present (`_TRANSIT_PSYCHOLOGY_RU` + `_TARGET_PSYCHOLOGY_RU` + `_ASPECT_PSYCHOLOGY_RU` + `_SAME_PLANET_PSYCHOLOGY_RU` для generational signatures).
- [ ] Layer separation verified on ≥3 cards: psychology MUST NOT mention houses; event_level MUST mention houses.
- [ ] Psychological text reads astrologically adequate + humanly (≥5 generic-card outputs).
- [ ] No Daragan verbatim copying.
- [ ] No fabricated psychology (empty string when dimension entry absent; no «интуитивное переживание контакта» padding).
- [ ] Calibrated allowlist bit-identical.
- [ ] 0 STOP triggers fired.

## Discipline checklist

- [x] NO Daragan verbatim copying. Author's own short phrasings.
- [x] NO LLM.
- [x] NO engine modifications.
- [x] NO house references в psychology text — verified ≥6 distinct cards × 5 forbidden patterns = 30 assertions clean.
- [x] NO change to event-level helper — diff shows zero lines.
- [x] NO calibrated allowlist data modifications — `_OUTER_CARD_FACTS` lines 496-810 untouched.
- [x] Composition deterministic — same input yields same output character-for-character (test `test_psychology_deterministic_same_input_same_output`).
- [x] Empty-input path produces EMPTY string per clarification 2 = (b) — 4 explicit fallback tests.
- [x] Layer-separation guard tested on ≥3 distinct cards (4 in `test_psychology_no_houses_event_level_has_houses`).
- [x] Same-planet outer aspects (Uranus-Uranus / Neptune-Neptune / Pluto-Pluto) route к `_SAME_PLANET_PSYCHOLOGY_RU` per clarification 3 = (a) — 6 parametrized tuples + explicit distinctness test.

## Closure

Worker ready for TL inline-verify + external Reviewer dispatch. TASK Status: open → review via `submit-task.sh`.

Baseline state:
- Product main: `3d36b2f` ↔ Backup `3d36b2f` ✓
- Pytest: 565/2/0 (was 527/2/0 baseline)
- Cabal: Up to date
- Olga 6/6 generic cards psychology layer-separation compliant
- Calibrated 8/8 (07 vacuous-skip) bit-identical
