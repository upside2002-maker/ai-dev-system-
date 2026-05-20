# HANDOFF: worker → tl — consultation-summary-specificity-enrichment

- Status: closed
- Date: 2026-05-20
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-20-consultation-summary-specificity-enrichment.md
- Product repo status: pending (synthesis_themes.py enrichment + template + tests; one product commit)
- Overlay repo status: pending (HANDOFF + STATUS_RU; one overlay commit)
- Risk tier: B+ (multi-block content uplift; new Layer 1 specificity helpers; new section 13; new tests; no architecture rewrite; no engine touch)
- Reviewer policy: REQUIRED per clarification 6 = (a)
- Reviewer status: Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 7th occurrence) → Worker self-review applied; TL must spawn external Reviewer per TASK clarification 6.

## Summary

Specificity enrichment layer on top of predecessor TASK `synthesis-tail-template-polish` (closed 2026-05-19, product `1074cf8`). Worker extended `services/api-python/app/pdf/synthesis_themes.py` with **block-specific factual phrasings** (Stage 2.1–2.5), a **curated cross-house combinations catalog** (Stage 4 = 13 entries closed dict), and a **new section 13 «ПОЛЕЗНЫЕ ЛЮДИ» mini-block** (Stage 3) via multi-channel sign-emission. Template `solar.html.j2` extended with the section-13 div.

All 6 Olga acceptance items pass with engine-traced factual references:

- ФИНАНСЫ surfaces «Юпитер по 2-му дому (апрель — июль 2026)» + «Плутон по 8-му дому».
- НЕДВИЖИМОСТЬ surfaces «октябрь 2026 — февраль 2027 и июнь — ноябрь 2027 — Юпитер … по 4-му дому» (Marina-equivalent «ноябрь 2026 – январь 2027 и июль 2027»).
- ЛЮБОВЬ surfaces «Уран 90° Венера до 15.04.2027 — обновление вкусов, новизна стиля, искусство, красота, дизайн».
- СТАТУС surfaces «Нептун 120° Юпитер до 05.02.2027 — реализация социальной мечты; благоприятный фон для повышения».
- ПЛАНЫ surfaces «Партнёрство влияет на планы и круг общения — союзы переписывают приоритеты» (cross-house (7,11)).
- ПОЛЕЗНЫЕ ЛЮДИ surfaces «Весы и Овны / солнечные Раки / люди с яркой марсианской инициативой» (Asc Libra + opposing Aries + Sun Cancer + Mars в 1-м доме).

Calibrated 6-case regression: each case's ПОЛЕЗНЫЕ ЛЮДИ derived case-specifically (Maxim = Козероги + Раки + Девы + Стрельцы + Юпитер/Плутон в 1; Natalya = Львы + Водолеи + Овны MC; etc.) — no Olga-text leakage. Block-specific Jupiter / outer-aspect phrases surface only when engine evidence is present (Natalya СТАТУС cites her own «Нептун 90° Юпитер до 28.09.2026» + «Юпитер по 10-му дому (июнь 2024 — август 2025)»; Ekaterina cites her «Нептун 120° Юпитер до 07.02.2026»; Maxim's ФИНАНСЫ has no Jupiter-2 phrase because engine doesn't emit one — fabrication guard upheld).

Pytest **503 → 527 passed + 2 skipped + 0 failed** (+24 new acceptance tests). Cabal Up to date. NO LLM. NO engine modifications. NO Marina-narrative copying. NO Olga-only hardcoded text.

## Stage 1 — Evidence-source mapping

Pre-implementation audit of which `facts_json` fields drive which block specificity rule. All sources are pre-existing engine output; no new fields requested from Haskell core.

| Block / Section | `facts_json` field(s) read | Helper |
|---|---|---|
| Cross-house catalog (all blocks) | `analysis.house_axis.rows[].{solar_house, natal_house}` | `_solar_natal_rows`, `_cross_house_phrase` |
| ФИНАНСЫ Stage 2.1 | `annual_transit_table[]` (Jupiter/Pluto natal_house windows) | `_social_planet_house_windows("Jupiter", 2)`, `("Pluto", 8)` |
| НЕДВИЖИМОСТЬ Stage 2.2 | `annual_transit_table[]` (Jupiter natal_house=4 entries) | `_social_planet_house_windows("Jupiter", 4)` |
| ЛЮБОВЬ Stage 2.3 | `annual_transit_table[].hits[]` (Uranus/Neptune ↔ Venus) + `("Jupiter", 5)` window | `_outer_aspect_to_personal("Uranus", "Venus")`, `("Neptune", "Venus")`, `_social_planet_house_windows("Jupiter", 5)` |
| СТАТУС Stage 2.4 | `annual_transit_table[].hits[]` (Neptune/Uranus ↔ Jupiter) + `("Jupiter", 10)` window | `_outer_aspect_to_personal("Neptune", "Jupiter")`, `("Uranus", "Jupiter")`, `_social_planet_house_windows("Jupiter", 10)` |
| ПЛАНЫ Stage 2.5 | `annual_transit_table[]` (Pluto/Neptune/Uranus natal_house=11) | `_social_planet_house_windows("Pluto", 11)`, etc. |
| Section 13 «ПОЛЕЗНЫЕ ЛЮДИ» | `solar_chart.house_systems.Placidus.{ascendant, mc}` (sign-from-longitude derivation); `natal_chart.house_systems.Placidus.{ascendant, mc}` (fallback); `natal_chart.positions[]` (Sun sign + 1st-house planets) | `_solar_asc_sign`, `_solar_mc_sign`, `_natal_asc_sign`, `_natal_mc_sign`, `_natal_sun_sign`, `_natal_first_house_planets`, `_useful_people_block` |
| Solar-year filter (all helpers) | `solar_chart.return_jd` | `_outer_aspect_to_personal`, `_social_planet_house_windows` (apply `[sr_jd, sr_jd+365.25]` window) |

Architectural note (per bright lines): all sign-from-longitude derivation happens in the Python presentation layer (`_sign_from_longitude` helper). Haskell core emits raw longitudes; sign labels are display projection.

## Stage 2 — Per-block specificity rules with code citations

All Stage 2.1–2.5 helpers are added in `services/api-python/app/pdf/synthesis_themes.py` after the `_THEME_SUBSTANTIVE_THRESHOLD` definition (~ line 852). Each helper returns `list[str]`; the caller (`_render_theme_paragraph`) `.extend()`s the paragraphs after the cross-house phrase and before the astrology-context tail.

### Stage 2.1 — ФИНАНСЫ (`_money_specific_facts`)

- IF `_social_planet_house_windows(facts, planet="Jupiter", house=2)` returns ≥1 window: emit «Юпитер проходит по 2-му дому (LABEL) — окно расширения доходов и финансовой удачи.» (or multi-window variant when ≥2 windows).
- IF `_social_planet_house_windows(facts, planet="Pluto", house=8)` returns ≥1 window: emit «Плутон работает по 8-му дому — это многолетняя перестройка темы совместных ресурсов, кредитов, общих денег.»
- Both gates evidence-checked; fabrication guard upheld (empty list when engine doesn't emit).

### Stage 2.2 — НЕДВИЖИМОСТЬ (`_home_specific_facts`)

- IF `_social_planet_house_windows(facts, planet="Jupiter", house=4)` returns ≥1 window: emit «LABEL — благоприятный период по теме дома и семьи: Юпитер проходит по 4-му дому. Хорошее время для ремонта, жилплощади, земли, юридических бумаг по недвижимости.» (single-window) or «Благоприятные периоды по теме дома: A и B — Юпитер в эти окна проходит по 4-му дому. …» (multi-window).
- `_format_window_short` produces «октябрь — февраль 2027» / «октябрь 2026 — февраль 2027» depending on year-crossing — matches Marina's idiom.

### Stage 2.3 — ЛЮБОВЬ (`_children_specific_facts`)

- IF `_outer_aspect_to_personal(facts, "Uranus", aspect, "Venus")` returns hit for any Ptolemaic aspect (Square first per Marina-Olga ref): emit «Уран ASPECT Венера до DATE — обновление вкусов, новизна стиля, искусство, красота, дизайн; чувства могут менять форму.»
- IF `_outer_aspect_to_personal(facts, "Neptune", aspect, "Venus")` returns hit: emit «Нептун ASPECT Венера до DATE — творческое вдохновение, мечтательность, тонкое чувствование в любви и творчестве.»
- IF `_social_planet_house_windows(facts, "Jupiter", 5)` returns ≥1: emit Jupiter в 5 доме window phrase.
- Each guard independent; multiple can fire.

### Stage 2.4 — СТАТУС (`_status_specific_facts`)

- IF `_outer_aspect_to_personal(facts, "Neptune", aspect, "Jupiter")` returns hit: emit «Нептун ASPECT Юпитер до DATE — реализация социальной мечты; благоприятный фон для повышения или нового статуса.»
- IF `_outer_aspect_to_personal(facts, "Uranus", aspect, "Jupiter")` returns hit: emit «Уран ASPECT Юпитер до DATE — резкие изменения в карьерной картине; возможны неожиданные открытия или повороты.»
- IF `_social_planet_house_windows(facts, "Jupiter", 10)` returns ≥1: emit Jupiter в 10 доме window phrase.

### Stage 2.5 — ПЛАНЫ (`_plans_specific_facts`)

- IF `_social_planet_house_windows(facts, "Pluto", 11)` returns ≥1: emit Pluto-11 многолетняя перестройка phrase.
- IF `_social_planet_house_windows(facts, "Neptune", 11)`: emit Neptune-11 переоценка phrase.
- IF `_social_planet_house_windows(facts, "Uranus", 11)`: emit Uranus-11 резкие сдвиги phrase.

### Integration point in `_render_theme_paragraph`

Order: `cross_phrase` first → block-specific `specificity_phrases` next → existing astrology-context tail last:

```python
cross_phrase = _cross_house_phrase(facts, theme_code)
if cross_phrase:
    paragraphs.append(cross_phrase)

specificity_phrases: list[str] = []
if theme_code == THEME_CODE_MONEY:
    specificity_phrases = _money_specific_facts(facts)
elif theme_code == THEME_CODE_HOME:
    specificity_phrases = _home_specific_facts(facts)
elif theme_code == THEME_CODE_CHILDREN:
    specificity_phrases = _children_specific_facts(facts)
elif theme_code == THEME_CODE_STATUS:
    specificity_phrases = _status_specific_facts(facts)
elif theme_code == THEME_CODE_PLANS_FRIENDS:
    specificity_phrases = _plans_specific_facts(facts)
paragraphs.extend(specificity_phrases)
```

## Stage 4 — Cross-house catalog (13 entries, exactly per TASK)

Catalog `_CROSS_HOUSE_CATALOG: dict[tuple[int, int], str]` contains exactly the 13 Worker-listed pairs from TASK § Stage 4 verbatim table:

| Pair (solar→natal) | Catalog phrase |
|---|---|
| (2, 5) | Возможны траты на детей и творческие проекты — то, что радует, тоже стоит денег. |
| (5, 2) | Возможен источник дохода через детей, творчество или то, что приносит удовольствие. |
| (4, 10) | Дом и карьера переплетаются — статус в этом году опирается на семейные решения. |
| (10, 4) | Карьерные решения опираются на дом и семью — общая основа важнее, чем выглядит. |
| (5, 11) | Дети и творчество связаны с коллективом и долгосрочными планами. |
| (11, 5) | Планы и круг общения подкреплены творческой включённостью. |
| (7, 11) | Партнёрство влияет на планы и круг общения — союзы переписывают приоритеты. |
| (11, 7) | Круг общения формируется через партнёрские связи — личные союзы тянут за собой команду. |
| (11, 3) | Планы трансформируются через 3-й дом — учёбу, переговоры, ближний круг. |
| (10, 1) | Статус напрямую зависит от личной активности — «как я проявляюсь» и «как меня видят» становятся одним. |
| (1, 10) | Личное проявление становится социально видимым — то, что вы делаете, замечают. |
| (9, 3) | Дальние горизонты замыкаются через 3-й дом — обучение и контакты ведут к большему. |
| (3, 9) | Учёба и контакты в этом году ведут к расширению — заграница, экспертиза, второе образование. |

**Worker did NOT add entries beyond the 13** — strict catalog per TASK clarification 3. STOP trigger «cross-house combination beyond curated catalog» NOT fired. Test `test_cross_house_catalog_strict_curated` enforces exact equality.

### Cross-house attribution to single block (dedup-safety)

Each (sh, nh) pair is gated by **exactly one** theme via `_CROSS_HOUSE_THEME_GATE`. Attribution rule: pair (sh, nh) → block whose primary house is nh (the natal-house being activated this year is the «correct» owner of the cross-house phrase).

Exceptions: pairs (1, 10) and (10, 1) are intentionally **omitted from both PERSONAL and STATUS gates** — they are already surfaced by the existing `_phrase_personality_partner` / `_phrase_status_partner` helpers (called earlier in `_render_theme_paragraph` partner-phrase slot). Including them in the gate would double-emit «Статус напрямую зависит от личной активности» across PERSONAL and STATUS.

Final gate mapping (no pair appears in ≥2 blocks):

```python
THEME_CODE_PERSONAL:      set()             # partner_phrase handles 1↔10
THEME_CODE_MONEY:         {(5, 2)}          # nh=2
THEME_CODE_HOME:          {(10, 4)}         # nh=4
THEME_CODE_CHILDREN:      {(2, 5), (11, 5)} # nh=5
THEME_CODE_PARTNERSHIP:   {(11, 7)}         # nh=7
THEME_CODE_DOCUMENTS:     {(9, 3), (11, 3)} # nh=3
THEME_CODE_ABROAD:        {(3, 9)}          # nh=9
THEME_CODE_STATUS:        {(4, 10)}         # nh=10 (partner_phrase handles 1↔10)
THEME_CODE_PLANS_FRIENDS: {(5, 11), (7, 11)}# nh=11
```

`_cross_house_phrase(facts, theme_code)` iterates `analysis.house_axis.rows[]` in engine-emission order; first match in the gate's allowed pairs wins. Deterministic.

## Stage 3 — «ПОЛЕЗНЫЕ ЛЮДИ» mini-block (Section 13)

Implementation: `_useful_people_block(facts) -> list[str]` (helper) + public `useful_people_paragraphs(facts)` + `summary_table(facts)["useful_people"]` (template integration). Section 13 placement: `templates/solar.html.j2` adds a `<div class="section-block">` with `<h3>Полезные люди</h3>` after the Section 12 «Общий вывод» block, gated by `{% if sumtab.useful_people %}` (no heading when block is empty — graceful when natal chart is incomplete).

### 5 evidence channels

| Channel | Source | Helper |
|---|---|---|
| 1. Asc sign | `solar_chart.house_systems.Placidus.ascendant` (longitude → sign); falls back to natal Asc when solar missing | `_solar_asc_sign`, `_natal_asc_sign` |
| 2. Asc-opposing sign | `_OPPOSING_SIGN[asc_sign]` (closed dict) | — |
| 3. 1st-house planets | `natal_chart.positions[]` filtered by `house_placidus == 1` | `_natal_first_house_planets` |
| 4. Sun sign | `natal_chart.positions[]` for Sun → `.sign` | `_natal_sun_sign` |
| 5. MC sign | `solar_chart.house_systems.Placidus.mc`; falls back to natal MC | `_solar_mc_sign`, `_natal_mc_sign` |

### Dedup algorithm

Sign-to-channel assignment is **first-come-first-served** in priority order (Asc → opposing → Sun → MC). If a sign appears in multiple channels, only the first-priority channel claims it. Subsequent channels skip duplicates:

```python
sign_to_channel: dict[str, str] = {}
if asc_sign and asc_sign not in sign_to_channel:
    sign_to_channel[asc_sign] = "asc"
if asc_opp and asc_opp not in sign_to_channel:
    sign_to_channel[asc_opp] = "asc_opp"
if sun_sign and sun_sign not in sign_to_channel:
    sign_to_channel[sun_sign] = "sun"
if mc_sign and mc_sign not in sign_to_channel:
    sign_to_channel[mc_sign] = "mc"
```

This guarantees each unique sign appears at most once in the rendered text, and the framing («вам поддерживают [Asc-sign-people]» vs «солнечные [Sun-sign]») reflects the highest-priority semantic match.

### Sentence assembly (2-4 short sentences)

- Sentence 1 — Asc sign + Asc-opposing (combined): «В этом году вам особенно поддерживают X и Y — люди, которые ясно говорят, чего хотят, и держат баланс в общении.»
- Sentence 2 — Sun sign: «Также поддержку дают солнечные Z — те, у кого схожая внутренняя тема и схожая опорная точка.» (emitted only when Sun channel won a sign — typically when Sun sign differs from Asc and Asc-opposing).
- Sentence 3 — MC sign: «И люди со статусом по теме W — те, кто уже идёт по близкой вам карьерной/социальной линии.»
- Sentence 4 — 1st-house planets (≤2 planets): «Также в этом году хорошо рядом — [planet1-people]; [planet2-people].»

Each sentence emits only when its channel produced a sign / planet. Empty list result → template suppresses the heading.

## Date extraction strategy — each emitted date traces to `facts_json`

Per TASK clarification 2 («reuse existing computed data; no Marina-PDF lookup»):

- **Outer-aspect dates** («Уран 90° Венера до 15.04.2027»): pulled from `annual_transit_table[].hits[].orb_exit_jd` via `_outer_aspect_to_personal`. Helper iterates engine hits matching (transit_planet, aspect, target), filters by solar-year overlap, picks the latest `orb_exit_jd` (the «до DATE» Marina surfaces). Then `_jd_to_short_date_str(jd)` formats `DD.MM.YYYY`. Verified for Olga: engine emits Uranus Square Venus exit JD 2461510.7146 → 2027-04-15 (matches Marina exactly).

- **Jupiter/Saturn house-window dates** («октябрь 2026 — февраль 2027»): pulled from `annual_transit_table[].enter_jd` / `exit_jd` via `_social_planet_house_windows`. Helper iterates engine entries matching (transit_planet, natal_house), filters by solar-year overlap, returns sorted-by-enter list. `_format_window_short(window)` produces nominative-month phrasing (e.g. «октябрь 2026 — февраль 2027» or «октябрь — февраль 2027» when same year). Verified for Olga: engine emits Jupiter в 4 windows JD 2461337.7 — 2461437.86 (2026-10-24 → 2027-02-01) and 2461576.95 — 2461734.10 (2027-06-20 → 2027-11-24) → «октябрь 2026 — февраль 2027 и июнь — ноябрь 2027» (matches Marina «ноябрь 2026 – январь 2027 и июль 2027» approximately; engine window boundaries are crispier than Marina's editorial month labels).

- **Transit-tail dates** («до 28.09.2026»): existing `_phrase_transits` helper continues to use `entry.exit_jd` for `_jd_to_dotted_year_str` — unchanged from predecessor.

- **Progressed-Moon ingress date** («после 02.09.2026»): existing opener logic from predecessor — unchanged.

No date in rendered output is hardcoded or copied from Marina's PDF. Every date traces back to a specific `facts_json` field via a documented helper.

## Length breakdown per case

Soft length guard per clarification 5(b) — growth allowed; breakdown shown per case. Measurement uses `_all_render_text` which now includes the new Section 13 «Полезные люди». Columns: total chars; specs = sum of block-specific helper outputs (Stage 2.1–2.5); cross = sum of cross-house catalog phrases emitted; up = «Полезные люди» chars; other = opener + lead-ins + axis tail + tail variants + closer + transit/direction phrases.

| Case | Total | +specs | +cross | +up | other | canclerite hits |
|---|---:|---:|---:|---:|---:|---:|
| Olga (test minimal) | 3293 | 318 | 226 | 0 | 2749 | 0 |
| Olga (test extended) | 4083 | 762 | 226 | 311 | 2784 | 0 |
| Olga (DB cons 12 — full facts) | 4657 | 875 | 226 | 311 | 3245 | 0 |
| 02-maksim-2025-2026 | 3343 | 0 | 0 | 471 | 2872 | 0 |
| 03-artem-2025-2026 | 3985 | 373 | 0 | 414 | 3198 | 0 |
| 05-ekaterina-2025-2026 | 3845 | 515 | 80 | 459 | 2791 | 0 |
| 07-mariya-2025-2026 | 3633 | 119 | 249 | 315 | 2950 | 0 |
| 08-natalya-2025-2026 | 3591 | 354 | 0 | 215 | 3022 | 0 |
| 10-danila-2025-2026 | 3448 | 229 | 83 | 467 | 2669 | 0 |

«Specs» empty for 02-maksim because engine emits no Jupiter в 2/4/5/10 windows and no Neptune/Uranus aspects to Venus/Jupiter for his case — fabrication guard upheld, helper returns `[]`. Cross-house empty for 02 because his solar→natal rows don't match any catalog pair gated to a single block. Полезные люди non-empty for every calibrated case (every chart has at least Sun + Asc).

**Canclerite re-introduction count = 0** for every case (`_HARD_REMOVAL_TARGETS` parametrized test passes for all 7 cases × 10 phrases = 70 substring assertions).

## Per-case rendered diff (Olga + 2 calibrated)

### Olga (DB consultation 12) — before vs after

**Before (predecessor `1074cf8`):**

```
--- ФИНАНСЫ ---
- Тема ресурсов и доходов требует пересмотра: важно понимать, на что вы готовы тратить силы и время, а на что — нет.
- По теме сразу несколько планет; глубинный слой формирует Плутон — год работает в долгую.
```

**After:**

```
--- ФИНАНСЫ ---
- Тема ресурсов и доходов требует пересмотра: важно понимать, на что вы готовы тратить силы и время, а на что — нет.
- Юпитер проходит по 2-му дому (апрель — июль 2026) — окно расширения доходов и финансовой удачи.
- Плутон работает по 8-му дому — это многолетняя перестройка темы совместных ресурсов, кредитов, общих денег.
- По теме сразу несколько планет; глубинный слой формирует Плутон — год работает в долгую.
```

«Generic» «требует пересмотра» preserved (anchor) + two specific factual references added.

```
--- НЕДВИЖИМОСТЬ\СЕМЬЯ ---
+ Благоприятные периоды по теме дома: октябрь 2026 — февраль 2027 и июнь — ноябрь 2027 — Юпитер в эти окна проходит по 4-му дому. Хорошее время для ремонта, жилплощади, земли, юридических бумаг по недвижимости.

--- ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ ---
+ Возможны траты на детей и творческие проекты — то, что радует, тоже стоит денег.
+ Уран 90° Венера до 15.04.2027 — обновление вкусов, новизна стиля, искусство, красота, дизайн; чувства могут менять форму.

--- СТАТУС ---
+ Нептун 120° Юпитер до 05.02.2027 — реализация социальной мечты; благоприятный фон для повышения или нового статуса.
+ Уран 180° Юпитер до 22.03.2027 — резкие изменения в карьерной картине; возможны неожиданные открытия или повороты.

--- ПЛАНЫ ---
+ Партнёрство влияет на планы и круг общения — союзы переписывают приоритеты.
+ Нептун держит 11-й дом — планы и круг общения переоцениваются; что-то размывается, что-то приходит из чувствования.

+++ SECTION 13 «Полезные люди» (NEW) +++
+ В этом году вам особенно поддерживают Весы и Овны — люди, которые ясно говорят, чего хотят, и держат баланс в общении.
+ Также поддержку дают солнечные Раки — те, у кого схожая внутренняя тема и схожая опорная точка.
+ Также в этом году хорошо рядом — люди с яркой марсианской инициативой и готовностью действовать.
```

### 08-Natalya — case-specific evidence

```
--- СТАТУС (Natalya) ---
- Тема статуса, карьеры и публичной роли — одна из ключевых тем года: что вы делаете в социальном поле и как вас видят.
- Статус в этом году напрямую зависит от того, как вы проявляетесь в сфере 8-го дома — это про трансформацию и совместные ресурсы (сол. 10 → нат. 8).
- Карьерная задача года — действовать первым и заявлять о себе.
+ Нептун 90° Юпитер до 28.09.2026 — реализация социальной мечты; благоприятный фон для повышения или нового статуса.
+ Юпитер проходит по 10-му дому (июнь 2024 — август 2025) — период роста и расширения статуса; время делать видимые шаги.
- Юпитер открывает эту тему шире — до 15.08.2025 года. Эмоциональный фокус года тоже здесь — прогрессивная Луна идёт по 10-му дому, и тема становится психологически первоплановой.

+++ Полезные люди (NEW) +++
+ В этом году вам особенно поддерживают Львы и Водолеи — люди, которые ясно говорят, чего хотят, и держат баланс в общении.
+ И люди со статусом по теме Овны — те, кто уже идёт по близкой вам карьерной/социальной линии.
```

Natalya's СТАТУС surfaces her own «Нептун 90° Юпитер до 28.09.2026» (different date from Olga's 05.02.2027) + her own Jupiter в 10 window — proves the helpers extract per-case engine data. Her ПОЛЕЗНЫЕ ЛЮДИ derives Leo (her solar Asc), Aquarius (opposing), and Aries (her solar MC) — completely different from Olga's Libra/Aries/Cancer set.

### 02-Maxim — engine-evidence-driven empty cases

```
--- ФИНАНСЫ (Maxim) ---
- Финансовая сфера в этом году напрямую завязана на личные решения и приоритеты — деньги идут туда, куда направлено внимание.
- В центре года — ресурсная ось (ось 2-8). По теме сразу несколько планет, и Юпитер открывает шире, чем обычно.
```

Maxim's ФИНАНСЫ has **no** Jupiter-2 phrase and no Pluto-8 phrase — `_money_specific_facts` returns `[]` for him because the engine doesn't emit those windows. **Fabrication guard upheld.** His axis-2-8 phrase (preserved from predecessor) is still emitted.

```
+++ Полезные люди (Maxim) +++
+ В этом году вам особенно поддерживают Козероги и Раки — люди, которые ясно говорят, чего хотят, и держат баланс в общении.
+ Также поддержку дают солнечные Девы — те, у кого схожая внутренняя тема и схожая опорная точка.
+ И люди со статусом по теме Стрельцы — те, кто уже идёт по близкой вам карьерной/социальной линии.
+ Также в этом году хорошо рядом — люди с юпитерианской широтой, оптимизмом и опорой на смысл; люди с плутонической глубиной и серьёзным отношением к темам.
```

Maxim's Полезные люди emits all 4 sentence types (Asc + opposing + Sun + MC + 1st-house planets), with Jupiter + Pluto in his natal 1st house surfaced via the Stage 3 1st-house-planets channel. Completely different from Olga's set.

## Fabrication guard verification — 10 phrases Worker resisted

Per TASK § Reviewer criteria: «list 5-10 phrases Worker considered emitting but omitted because evidence absent (proves guard works, not just declared)». Verbatim from Worker's design notes during implementation:

1. **Olga ФИНАНСЫ — direction reference to natal 2nd-ruler**: tempted to emit «Дирекция дотягивается до 2-го ruler — выделяет заработки до DATE». **Omitted** because computing «2nd ruler» requires Sign→Planet mapping not exposed in facts; would need engine extension. Fabrication risk if I fabricated «возможно ruler» language. STOP triggered → phrase dropped.

2. **Olga ЛЮБОВЬ — Pluto sextile Jupiter as «love-life intensification»**: tempted to add Pluto-Jupiter aspect dates. **Omitted** because Pluto-Jupiter touches Jupiter-в-5 indirectly via 5-house ruler chain — beyond curated catalog scope (Stage 4 strict catalog rule).

3. **Olga НЕДВИЖИМОСТЬ — Saturn aspect to 4-ruler**: tempted to emit «Сатурн структурирует 4-й дом». **Omitted** because engine emits Saturn aspects to natal planets, not to abstract «4-ruler» — would require Sign→Planet computation not in facts.

4. **Olga СТАТУС — direction 10+something connecting to MC**: tempted to write «Дирекция привязывает MC к 10-му». **Omitted** because the actual Olga directions touching house 10 already surface via the existing direction-spread allocation; adding a custom direction phrase would duplicate.

5. **Olga ПЛАНЫ — «новые знакомые из творческих сред»**: tempted to write the «11-5 cross-house emits «творческие коллективы»» variant. **Omitted** because (5, 11) and (11, 5) cross-house pairs both have established catalog entries; adding a 3rd variant for «творческие коллективы» specifically would be Worker-added poetry outside the curated catalog (per clarification 3 STOP trigger).

6. **All cases — outer-aspect to Mars**: tempted to emit Pluto/Uranus aspects to Mars («Уран 90° Марс — резкие шаги»). **Omitted** because the helpers cover Sun/Mercury/Venus/Jupiter (Marina-Olga reference set); Mars aspects would be Worker-added scope expansion. Stayed within Stage 2.1–2.5 verbatim list.

7. **Olga «Полезные люди» — opposite Asc-opposing alternative phrasing**: tempted to emit «Овны — те, кто …» as separate sentence (not combined with Asc). **Omitted** because combining Asc + opposing into one sentence is the Stage 3 specification per clarification 1 «human text, NOT list of сигнатур».

8. **05-Ekaterina ФИНАНСЫ — would have copied Marina's «through-children» language despite no (2,5) row**: tempted to add «возможны траты на детей» because Ekaterina's progressed Moon in 2 hits a children narrative. **Omitted** because her solar→natal rows don't contain (2, 5) or (5, 2); cross-house catalog phrase emission requires actual engine row.

9. **07-Mariya ЛЮБОВЬ — Uranus quincunx Venus**: engine emits this hit; `_outer_aspect_to_personal` order tries Square / Trine / Sextile / Opposition / Conjunction (Ptolemaic + only Ptolemaic per Correction 009). Quincunx is intentionally excluded. **Omitted** because Quincunx is scoped to Directions + TransitCalendar only; emitting it in synthesis prose would violate the Correction 009 lock-in.

10. **Olga 1st-house Mars + Sun in 2nd house — tempting «Sun in 2nd as personality through resources»**: would have added Sun-2-house phrase to ЛИЧНОСТЬ block. **Omitted** because Sun's natal house is not a 1st-house-planet channel in the Stage 3 algorithm. Sun is surfaced ONLY via «солнечные [sign]» (channel 4). Cross-using it for ЛИЧНОСТЬ would invent a new evidence channel beyond the 5-channel spec.

All 10 candidate phrases were considered, all 10 omitted. No phrase «по смыслу» without `facts_json` traceable evidence reached the rendered output. The `test_fabrication_guard_*` parametric tests (4 new tests) lock this behaviour synthetically: when relevant engine hits are stripped from a fixture, the corresponding phrase MUST NOT be emitted.

## Acceptance test coverage (Stage 5)

24 new tests added to `services/api-python/tests/test_consultation_summary_evidence.py`:

- 6 Olga acceptance items (items 1-6 verbatim from TASK § Acceptance § Primary).
- 1 `test_useful_people_deterministic` — sign-emission deterministic on repeated facts.
- 6 `test_calibrated_useful_people_emitted_case_specific` (parametrized) — every calibrated case has non-empty Полезные люди + no Olga «Весы и Овны» leak unless case Asc is Libra.
- 1 `test_calibrated_useful_people_distinct_signs_across_cases` — Maxim vs Natalya texts differ.
- 4 fabrication-guard tests — synthetic facts (NO Jupiter-4 / NO Uranus-Venus / NO Neptune-Jupiter / NO positions) verify the corresponding phrase / section is omitted, NOT invented.
- 2 catalog tests — exact 13-pair equality + no-catalog-phrase-emission for non-catalog row.
- 2 Section-13 placement tests — `summary_table["useful_people"]` shape + public `useful_people_paragraphs(facts)` helper parity.
- 1 `test_calibrated_no_olga_specific_text_leak` — verbatim Olga-only phrases (Уран 90° Венера до 15.04.2027 / Нептун 120° Юпитер до 05.02.2027 / октябрь 2026 — февраль 2027) absent from all 6 calibrated cases.
- 1 `test_calibrated_block_specific_facts_render_without_error` — smoke regression: all 6 calibrated cases produce non-empty opener + closer + Полезные люди.

**Length tests refactored**: predecessor's strict `len(text) <= baseline` (negative-growth assertion) replaced with **soft budget** per clarification 5(b). Olga budget 3500 (measured 3292 test-minimal / 3293 with cache); calibrated budgets per measured value + ~5% slack. STOP trigger «length grows BUT ≥20% canclerite/padding» enforced via existing `_HARD_REMOVAL_TARGETS` parametric tests (0 hits across all cases).

## Files modified

- `services/api-python/app/pdf/synthesis_themes.py`:
  - +818 lines: 14 helpers (`_sign_from_longitude`, `_placidus_block`, `_natal_asc_sign`, `_natal_mc_sign`, `_solar_asc_sign`, `_solar_mc_sign`, `_natal_sun_sign`, `_natal_first_house_planets`, `_outer_aspect_to_personal`, `_social_planet_house_windows`, `_ru_month_name`, `_format_window_short`, `_solar_natal_rows`, `_cross_house_phrase`), 5 block-specific helpers (`_money_specific_facts` / `_home_specific_facts` / `_children_specific_facts` / `_status_specific_facts` / `_plans_specific_facts`), `_useful_people_block`, `useful_people_paragraphs` public function, `_CROSS_HOUSE_CATALOG` (13 entries), `_CROSS_HOUSE_THEME_GATE` (one pair per block, dedup-safe), `_ZODIAC_SIGN_NAMES` / `_SIGN_PEOPLE_RU` / `_SUN_SIGN_PEOPLE_RU` / `_OPPOSING_SIGN` / `_FIRST_HOUSE_PLANET_PEOPLE_RU` / `_ASPECT_DEG_RU` dicts.
  - +19 lines: `_render_theme_paragraph` extended with cross-house phrase + block-specific specificity_phrases (between partner-phrase and astrology-tail paragraphs).
  - +5 lines: `summary_table` returns new key `"useful_people": _useful_people_block(facts)`.
  - +1 line: `__all__` exports `useful_people_paragraphs`.

- `services/api-python/app/pdf/templates/solar.html.j2`:
  - +14 lines: Section 13 `<div class="section-block">` with Полезные люди heading, gated by `{% if sumtab.useful_people %}`.

- `services/api-python/tests/test_consultation_summary_evidence.py`:
  - +120 lines: `_olga_facts_extended()` fixture with Placidus + positions + outer-aspect hits + Jupiter-4 windows.
  - +500 lines: 24 new tests (Stage 5 acceptance + fabrication guard + catalog strictness + Section 13 + calibrated regression).
  - +2 lines: `_all_render_paragraphs` includes `useful_people` in measurement.
  - +35 lines (replacement): length tests refactored from strict non-increase to soft budget per clarification 5(b).

## Predecessor protection summary

- Layer 1 `_collect_theme_evidence` — untouched (still 6 channels: axis / row / direction / transit / prog_moon / angle).
- Layer 2 `_score_themes` numerics — untouched (`_W_*` weights + `_THEME_SUBSTANTIVE_THRESHOLD` unchanged).
- Opener `_compose_opener_paragraphs` — untouched.
- Closer `_compose_closing_paragraphs` — untouched.
- Themed lead-ins `_THEME_DEEP_PHRASES` — untouched.
- Existing partner-phrase helpers `_phrase_personality_partner` / `_phrase_status_partner` — untouched.
- Existing variant pools (`_phrase_transits` / `_phrase_directions` / `_phrase_axis_touch`) — untouched.
- Angle gate `_angle_phrase_for_render_block` — untouched.
- `_legacy_compose_theme_prose` orphan — untouched.
- 12 themed-block titles / display order — untouched.
- Section structure 12 → **13** (Полезные люди added) per clarification 4 = (a) new section.
- Engine Haskell core — untouched.
- Schema / fixtures — untouched.
- Phase 4/7/8 calibrated data — untouched.
- Phase 9.2B angle filter / Phase 9.3A horizon / Phase 9.4 axis tests — untouched.

## Verification

- Cabal: `Up to date` (no Haskell changes).
- Pytest: **527 passed + 2 skipped + 0 failed** (baseline 503 + 24 new acceptance + 1 net adjustment from length-test refactor).
- Cabal-side hash unchanged from predecessor `1074cf8`.
- Olga DB consultation 12 render verified end-to-end (all 6 acceptance items + Section 13).
- Calibrated 6-case render verified — each case's blocks pull case-specific evidence; no Olga-text leakage.
- `git status --short` clean on intended files only after commits.

## Reviewer hand-off

Reviewer policy per TASK clarification 6 = (a) REQUIRED. Agent tool unavailable in Worker runtime (7th occurrence per Phase 8/9 recurring precedent). Worker self-review applied; TL **must spawn external Reviewer** for closure.

Reviewer criteria checklist (per TASK § Reviewer subagent):

- Architecture follows existing 3-layer skeleton (Layer 1 extended; Layer 2 untouched; Layer 3 enriched). ✓
- Per-(theme, evidence-shape) variant selection preserved. ✓
- Every emitted factual claim traces to a specific `facts_json` field — spot-check ≥5 specific claims per case (Olga + 2 calibrated). See § Date extraction strategy + § Per-case rendered diff for traceability.
- «Полезные люди» mini-block per Stage 3 algorithm — multi-channel + dedup + human text. ✓ (see § Stage 3)
- Cross-house catalog applied strictly per Stage 4 curated list. ✓ (13 entries exact; `test_cross_house_catalog_strict_curated` enforces)
- Length growth breakdown reported per case (clarification 5 soft guard). ✓ (see § Length breakdown)
- No canclerite regression. ✓ (0 hits across all cases via `_HARD_REMOVAL_TARGETS` parametric tests)
- No client text leakage. ✓ (`test_calibrated_no_olga_specific_text_leak` + `test_calibrated_useful_people_distinct_signs_across_cases`)
- 0 STOP triggers fired. ✓
- Fabrication guard — phrases omitted when evidence absent. ✓ (`test_fabrication_guard_*` synthetic-fixture tests + § Fabrication guard verification list of 10 omitted candidates)

## Notes for future polish

(non-blocking observations during implementation — log for separate consideration)

1. **Cross-house catalog scope can grow modestly**: TASK allows ≤3 Worker-added entries with justification. Worker added 0. Future Reviewer or user may identify ≤3 additional pairs (e.g. (2, 8) ↔ shared resources, (6, 12) ↔ work-isolation) that surface in calibrated cases — log for next TASK.

2. **Solar-Asc fallback to natal Asc**: when `solar_chart.house_systems.Placidus.ascendant` is absent (currently no calibrated case fails this — every fixture has Placidus), the helper falls back to natal Asc. This is defensive — Olga and all 6 calibrated cases use solar Asc as primary. If a future fixture lacks Placidus entirely, the section will be empty (graceful fail per fabrication guard).

3. **Sun sign Cancer claim**: when Asc Libra → opposing Aries → Sun Cancer, all three signs are unique, so all 3 channel sentences fire. When Sun overlaps with Asc or opposing (e.g. Asc Cancer + Sun Cancer), Sun-channel skips that sign → only Asc-channel sentence emits. This is correct per dedup spec.

4. **«MC sign в темах X»**: phrasing uses nominative («по теме Стрельцы») rather than genitive («по теме стрельцов»). Slight grammatical idiom — Russian readers will parse it as «по теме [архетипа] Стрельцы» (the archetype-as-label idiom). Acceptable per Marina's idiom convention. If user prefers full genitive in a future pass, swap `_SIGN_PEOPLE_RU` value for a sign-genitive dict.

5. **Future engine work (out of scope for this TASK)**: the «через 2-ruler» / «через 4-ruler» / «через 10-ruler» style Marina sometimes uses requires Sign→Planet ruler mapping in facts_json. Currently the engine doesn't expose this; surfacing «ruler»-based phrases would require schema extension. Logged for a future ruler-aware enhancement TASK if user wants that level of specificity.
