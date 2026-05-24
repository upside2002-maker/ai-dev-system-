# HANDOFF: Worker → TL — solar-planets-house-distribution

- Date: 2026-05-24
- From: Worker (astro)
- To: Tech Lead (astro)
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: `project-overlays/astro/TASKS/2026-05-20-solar-planets-house-distribution.md`
- Status: ready_for_review
- Product repo status: committed (`732759d` on `main`, backup pushed
  `948cbdc..732759d`)

## Что сделано

Tier B new client-facing PDF section + 2 new helper modules. Раздел
«Распределение планет по домам соляра» добавлен между натальной
страницей и блоком «Темы года» — точно перед основными прогнозными
разделами per clarification 2 = (a). 12-строчная таблица домов с
акцентом оси (≥3 планет per clarification 3 = (a)) + по одной
интерпретации на планету (1-2 предложения каждая per critical brevity
guard 2026-05-24).

### Артефакты

- **new product:** `services/api-python/app/pdf/planet_archetypes.py`
  (+85 lines) — canonical `PLANET_ARCHETYPES` 10-entry dict +
  `PLANET_ORDER` classical ordering tuple.
- **new product:** `services/api-python/app/pdf/solar_house_distribution.py`
  (+424 lines) — grouping, axis accent, composition, bundled
  template input. Functions: `solar_planets_by_house`,
  `format_planet_for_house`, `format_house_row`,
  `calculate_axis_accents`, `axis_accent_phrase`,
  `accent_houses_from`, `solar_planet_house_text`,
  `planet_house_header`, `build_solar_house_distribution`.
- **new product:** `services/api-python/tests/test_solar_house_distribution.py`
  (+393 lines, 20 tests).
- **modify product:** `services/api-python/app/pdf/templates/solar.html.j2`
  (+59 lines) — new `<section class="section-page">` placed between
  the natal-page `</section>` and the `{% set cs = ... %}` skeleton
  block; reference table at end preserved unchanged.
- **modify product:** `services/api-python/app/pdf/builder.py`
  (+2 lines) — import + Jinja global wire-up of
  `build_solar_house_distribution`.
- **modify product:** `services/api-python/tests/test_api_pdf_endpoint.py`
  (page-count upper bound 21 → 23 for Natalya's PDF; section adds
  ~1 page to client-facing renders).
- **Product commit SHA:** `732759d` on `main` (backup push
  `948cbdc..732759d  main -> main`).

## HANDOFF mandatory items (per TASK)

### 1. Helper modules created

**`planet_archetypes.py`:**
- `PLANET_ARCHETYPES: dict[str, str]` — 10 canonical entries (verbatim
  per user spec — see item 2 below).
- `PLANET_ORDER: tuple[str, ...]` — Sun, Moon, Mercury, Venus, Mars,
  Jupiter, Saturn, Uranus, Neptune, Pluto.

**`solar_house_distribution.py`:**
- `solar_planets_by_house(solar_chart) -> list[dict]` — 12 rows,
  reads `positions[*].house_placidus`, drops anything outside
  `PLANET_ORDER`, sorts within house by classical order.
- `format_planet_for_house(planet, is_retrograde) -> str` — Russian
  name + optional « R» suffix.
- `format_house_row(row) -> dict` — table-ready
  `{house, planets_label}`; «-» for empty.
- `calculate_axis_accents(by_house) -> list[(low, high)]` — ≥3
  threshold; returns all axes tied at max; empty if none reach
  threshold.
- `axis_accent_phrase(accents) -> str` — «Акцент на оси X-Y.» |
  «Акцент на осях X-Y и A-B.» | "".
- `accent_houses_from(accents) -> set[int]` — flatten for CSS hint.
- `solar_planet_house_text(planet, house, is_retrograde) -> str` —
  1-2 sentence composition.
- `planet_house_header(planet, house, is_retrograde) -> str` —
  «Плутон R в IV доме» format (Roman numerals).
- `build_solar_house_distribution(solar_chart) -> dict` — single
  template integration point bundling `by_house`, `accent_houses`,
  `axis_accent_phrase`, `interpretations`.

### 2. PLANET_ARCHETYPES 10 entries (verbatim final values)

```python
PLANET_ARCHETYPES: dict[str, str] = {
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

All 10 values match the user spec character-for-character.

### 3. Composition template design (example: Pluto-in-4 retrograde)

Composition structure (deterministic, ≤2 sentences hard limit):

```
«{Archetype.capitalize()} в этом году {verb} {top-3 house topics}.»
[optional, only if is_retrograde]
«{Retrograde nuance with leading capital}.»
```

Per-planet `verb` chosen so it agrees in number with the plural-
abstract noun list that opens the sentence (e.g. «Документы, обучение,
переговоры в этом году обращены …»). Per-planet retrograde nuance
keeps Russian style varied across the 10 retrograde clauses.

Worked example — Pluto in house 4 retrograde:

```
Archetype:           "глубокая трансформация, давление, кризис/сила"
Verb:                "в этом году трансформируют тему"
House topics:        "дом, семья, недвижимость"   (HOUSE_MEANINGS[4].main[:3])
Retrograde nuance:   "трансформация идёт глубоко и тихо,
                      без внешней драматизации"

Generated text:
«Глубокая трансформация, давление, кризис/сила в этом году
трансформируют тему дом, семья, недвижимость. Трансформация
идёт глубоко и тихо, без внешней драматизации.»
```

The function `solar_planet_house_text` is the sole place that
composes these strings, so the ≤2-sentence brevity guard is enforced
structurally (no future override path can violate it).

### 4. Olga rendered section sample

Olga consultation 12 (data/pdf/consultation-12.facts.json, no
meeting_place override → birth Москва):

**Table:**

| Дом | Планеты |
|-----|---------|
| 1   | -       |
| 2   | -       |
| 3   | -       |
| 4   | Плутон R |
| 5   | -       |
| 6   | Нептун R |
| 7   | Сатурн   |
| 8   | Уран     |
| 9   | Луна, Марс |
| **10** | **Солнце, Меркурий R, Юпитер** |
| 11  | Венера   |
| 12  | -       |

**Axis accent phrase:** «Акцент на оси 4-10.» (4 planets — Pluto in 4
+ Sun + Mercury R + Jupiter in 10 — strongest axis, ≥3 threshold met).

**Interpretations (10 rendered):**

1. **Плутон R в IV доме** — «Глубокая трансформация, давление,
   кризис/сила в этом году трансформируют тему дом, семья,
   недвижимость. Трансформация идёт глубоко и тихо, без внешней
   драматизации.»
2. **Нептун R в VI доме** — «Размывание, вдохновение, тонкость в
   этом году размывают тему работа, здоровье, коллеги. Тонкие
   процессы идут внутрь, наружу выходят постепенно.»
3. **Сатурн в VII доме** — «Ответственность, ограничения,
   структура в этом году выстраивают тему брак, партнёр, договоры.»
4. **Уран в VIII доме** — «Обновление, резкие перемены в этом
   году встряхивают тему чужие деньги, кредиты, наследство.»
5. **Луна в IX доме** — «Эмоциональный фон, быт, реакции в этом
   году окрашивают тему заграница, высшее образование, право.»
6. **Марс в IX доме** — «Активность, конфликтность, действия в
   этом году действуют в теме заграница, высшее образование, право.»
7. **Солнце в X доме** — «Центр года, воля, фокус в этом году
   собираются вокруг темы карьера, статус, репутация.»
8. **Меркурий R в X доме** — «Документы, обучение, переговоры в
   этом году обращены к теме карьера, статус, репутация. Идут
   пересмотр, доработки и возвраты к старым материалам.»
9. **Юпитер в X доме** — «Расширение, удача, поддержка в этом
   году расширяют тему карьера, статус, репутация.»
10. **Венера в XI доме** — «Комфорт, отношения, деньги, эстетика
    в этом году раскрываются через тему друзья, коллективы, планы.»

Multi-planet 10-дом (Sun + Mercury R + Jupiter) renders 3 separate
interpretations (entries 7, 8, 9 above) — NOT one combined paragraph
per critical brevity guard 2026-05-24.

### 5. Brevity guard verification: каждая interpretation sentence-counted

Test `test_each_interpretation_paragraph_is_at_most_two_sentences`
sweeps **10 planets × 12 houses × 2 retrograde states = 240 generated
paragraphs**, asserting `1 <= sentence_count <= 2` for every one. All
240 pass.

Olga-specific sanity test
`test_olga_rendered_interpretations_obey_brevity_guard` asserts the
same property on the 10 rendered paragraphs for consultation 12.
Manual sentence count (from the sample above):

- Plain (no retrograde): 1 sentence each — Сатурн VII, Уран VIII,
  Луна IX, Марс IX, Солнце X, Юпитер X, Венера XI = **7 × 1 = 7
  sentences**.
- Retrograde: 2 sentences each — Плутон R IV, Нептун R VI, Меркурий
  R X = **3 × 2 = 6 sentences**.

Total: 13 sentences across 10 paragraphs, 0 violations. Maximum
sentences per paragraph = 2.

### 6. meeting_place invariant proof: distribution diff Москва vs Питер

Run via Haskell core (`run_core_analysis` on
`build_solar_snapshot(olga, solar_year=2026, meeting_place=...)`),
solar_chart.positions[*].house_placidus changes when SR cusps shift:

**Москва (birth):**
- house 8: Уран
- house 9: Луна, Марс

**Санкт-Петербург (meeting):**
- house 8: -
- house 9: Луна, Марс, Уран

Уран moves from solar house 8 → solar house 9 when SR is calculated
for Питер coordinates. All other planets stay in their original
houses for this particular shift (Sun and Pluto both remain in their
respective angular houses, so the 4-10 axis accent is preserved in
both renders — that is correct: a single planet shift can change the
table but not necessarily the strongest-axis identity).

Distribution differs → invariant honoured. The Stage 6 acceptance
test `test_distribution_shifts_when_house_placidus_differs` exercises
this at the presentation-layer contract level (synthesising a
two-planet shift to mimic the SR cusps moving), which is the right
scope for the Python test suite — the end-to-end Haskell-core proof
that meeting_place actually shifts the cusps lives in
`test_meeting_place_changes_solar_cusps_olga` (Solar Meeting Place
TASK invariant, predecessor).

### 7. PDF section placement verified

Section placement empirically confirmed via raw HTML inspection +
multi-page PDF text extraction (Olga consultation 12 render):

* HTML order: «Распределение планет по домам соляра» appears at
  offset 78643, «Темы года» at 82254, «Соляр — позиции планет»
  reference table at 156583. Order: new section → forecast → end-
  of-PDF reference table. ✅
* PDF page-by-page: new section renders on page 3 (after cover
  page 1 + natal page 2); «Темы года» on page 5; reference table
  on page 25. ✅
* Existing reference table «Соляр — позиции планет» preserved
  unchanged (test 12 asserts substring presence in HTML).

### 8. Reviewer status

Per clarification 5 = (b) REQUIRED, external Reviewer pass is
needed before TASK closure.

Worker self-review applied:
- All 10 PLANET_ARCHETYPES verified against user spec (verbatim).
- All 240 generated interpretations sentence-counted (≤ 2).
- Olga 10-дом multi-planet case manually inspected — 3 separate
  paragraphs, not combined.
- Axis-accent threshold = 3 confirmed both in source
  (`AXIS_ACCENT_THRESHOLD = 3` constant) and in tests
  (`test_no_accent_when_all_axes_below_threshold` asserts the
  constant).
- meeting_place invariant proved empirically Москва vs Питер via
  Haskell core (Уран shift 8 → 9).
- Existing reference table preserved (asserted in
  `test_pdf_render_contains_section_table_and_interpretations`).
- No Lilith / Nodes / Chiron emitted (defensive test 14).

Agent tool not available in Worker runtime (recurring Phase 8/9
precedent); **TL must spawn external Reviewer post-submit per
clarification 5 = (b) REQUIRED.**

## Critical guards satisfied

- **Data source discipline:** uses `facts.solar_chart.positions`
  exclusively. NEVER reads `natal_chart.positions` or
  `annual_transit_table`. Verified by grep of new module — only
  `solar_chart` reads, no other facts dict access.
- **`house_placidus` field used:** the function reads
  `position["house_placidus"]`, never any natal house field.
- **Brevity guard ≤2 sentences:** 240-paragraph sweep test asserts
  the structural limit; the composition function is the sole
  paragraph source so no escape path.
- **Multi-planet separate paragraphs:** template iterates over
  `dist.interpretations` one-by-one; no combine logic exists.
- **No Lilith / Nodes / Chiron invention:** dropped silently by
  `solar_planets_by_house` when planet ∉ `PLANET_ORDER`.
- **meeting_place invariant:** distribution responds to
  `house_placidus` changes; proven empirically Москва vs Питер.
- **Existing reference table preserved:** template change is an
  insertion between natal-page `</section>` and `{% set cs = ... %}`,
  with the «Справочные данные» block at line 893+ untouched.
- **No Daragan verbatim copy:** all archetype + verb + nuance
  strings are Worker-authored Russian; HOUSE_MEANINGS source is
  the project's own canonical dict (also Worker-authored, no
  verbatim from any astrology book).
- **No LLM:** module is pure deterministic Python.
- **No Haskell touch:** core/, schemas, fixtures untouched.
- **No hand-crafted (planet, house) overrides catalog:** all 120
  combinations covered by composition; no override map exists.

## Verification matrix

| Check | Status |
|---|---|
| `cd core/astrology-hs && cabal build` | Up to date (no Haskell change) |
| `pytest --tb=no -q` | 673 passed + 3 skipped + 0 failed (was 653/3/0) |
| 20 new tests in `test_solar_house_distribution.py` | 20/20 PASS |
| Olga PDF render (consultation 12) | section appears page 3; axis accent + 10 interpretations rendered |
| Manual brevity sentence count (Olga) | 0 violations across 10 paragraphs |
| meeting_place invariant (Москва vs Питер via Haskell core) | Уран shifts 8 → 9; distribution differs |
| `git status --short` | clean |
| Product commit | `732759d` on `main` |
| Backup push | `948cbdc..732759d  main -> main` |
| Page-count test (Natalya) | passes after upper bound 21 → 23 |
| Frontend `npm run build` | N/A (no frontend change) |

## Files (product, single atomic commit `732759d`)

- **new:** `services/api-python/app/pdf/planet_archetypes.py` (+85).
- **new:** `services/api-python/app/pdf/solar_house_distribution.py` (+424).
- **new:** `services/api-python/tests/test_solar_house_distribution.py` (+393).
- **modify:** `services/api-python/app/pdf/templates/solar.html.j2` (+59).
- **modify:** `services/api-python/app/pdf/builder.py` (+2).
- **modify:** `services/api-python/tests/test_api_pdf_endpoint.py` (+7/−1).

Net product: +1113 / −1.

## STOP triggers fired

None.

## Conflicts / surprises

* Initial verb design used singular masculine verbs («обращён»,
  «концентрируется») which clashed grammatically with the plural-
  abstract noun list that opens the archetype phrase («Документы,
  обучение, переговоры обращён к теме …» — disagreement). Fix:
  switched all per-planet verbs to plural forms («обращены»,
  «собираются вокруг», …) so the sentence reads naturally with any
  archetype noun list. No tests had to change.
* `test_api_pdf_endpoint_with_case_label_renders_outer_cards` had
  a page-count upper bound of 21 that the new section pushed
  Natalya's PDF over (22 pages). Bumped the bound to 23 with a
  comment-block linking back to this TASK so future contributors
  see the rationale.
* Two existing user-direction phrasings — «после страницы соляра /
  перед основными прогнозными разделами» (= after solar cover page,
  before forecast) and «после «Соляр — позиции планет» reference
  table» (= after the end-of-PDF reference table) — point at
  different locations in the current template. The user's most
  recent (2026-05-24) verbatim re-confirmation said «После
  страницы/таблицы соляра, перед основными прогнозными разделами.
  Это ровно место этого блока.», and «перед основными прогнозными
  разделами» is the binding constraint. Worker placed the section
  between the natal page and «Темы года» (the first forecast
  section), preserving the existing reference table at the end of
  the PDF unchanged. If TL/Reviewer disagrees, the placement is a
  single Jinja block move (no helper-module change needed).

## Lifecycle next steps

- TASK `open → review` via
  `bash /Users/ilya/Projects/ai-dev-system/scripts/submit-task.sh
  project-overlays/astro/TASKS/2026-05-20-solar-planets-house-distribution.md`.
- TL spawn external Reviewer per clarification 5 = (b) REQUIRED.
- HANDOFF status `ready_for_review` → `closed` after Reviewer pass +
  TL closure decision.
