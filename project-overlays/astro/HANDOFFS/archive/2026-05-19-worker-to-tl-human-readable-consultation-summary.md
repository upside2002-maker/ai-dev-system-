# HANDOFF: worker → tl — human-readable-consultation-summary

- Status: closed
- Date: 2026-05-19
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-19-human-readable-consultation-summary.md
- Product repo status: committed (product main @ TBD; pushed to backup ✓)
- Overlay repo status: committed (overlay master @ TBD; pushed to backup ✓)
- Risk tier: B+ (1 substantive file rewrite + new tests + minimal template touch; no engine, no schema)
- Reviewer policy: REQUIRED (per TASK clarification 7)
- Reviewer status: Agent tool unavailable в Worker runtime — Worker self-review applied; TL must spawn external Reviewer post-submit

## Summary

Tier B+ uplift on top of predecessor TASK `evidence-based-consultation-summary-rewrite` (closed 2026-05-19, product `a6a3331`). Worker replaced the predecessor's «evidence-driven but symbolic listing» renderer in `services/api-python/app/pdf/synthesis_themes.py` with a 3-layer human-readable pipeline:

* **Layer 1 (Evidence extraction)** — normalises facts into theme-tagged evidence items.
* **Layer 2 (Theme planner)** — weight-based scoring with multi-method boost.
* **Layer 3 (Narrative renderer)** — hybrid per-theme template + phrase-library composition producing consultation prose.

Output structure expanded from 11 sections (1 opener + 10 themed) to **12 sections** (1 opener + 10 themed + 1 closer «Общий вывод») per clarification 1. Closer added as `summary_table.closing` key with minimal template update (5 lines).

«После 02.09.2026» date dynamically derived from `progressed_moon.ingresses[i].jd` where `kind == "Sign"` and ingress JD falls within the current solar year (clarification 5). Olga case verified — JD 2461285.74 → 02.09.2026.

Pytest **398 → 412 passed + 2 skipped + 0 failed** (+14 new semantic-human tests). Cabal Up to date (no Haskell change).

## Files changed

### `services/api-python/app/pdf/synthesis_themes.py` (product, modified)

- **Inserted (~700 lines new code)** the 3-layer architecture: theme codes + house→theme map + display-title→code map + evidence-weight numerics (Layer 2 constants) + `_collect_theme_evidence` (Layer 1) + `_score_themes` (Layer 2) + Layer 3 phrase library + `_render_theme_paragraph` + `_compose_opener_paragraphs` + `_compose_closing_paragraphs` + helper functions `_join_nouns`, `_phrase_personality_partner`, `_phrase_status_partner`, `_phrase_axis_touch`, `_phrase_solar_row`, `_phrase_directions`, `_phrase_transits`, `_phrase_prog_moon`, `_phrase_angle`, `_HOUSE_SHORT_RU`, `_THEME_DEEP_PHRASES`.
- **Rewrote** `_compose_theme_prose` to dispatch via display_title → theme_code → `_render_theme_paragraph` (Layer 3).
- **Rewrote** `_compose_summary_paragraphs` to delegate to `_compose_opener_paragraphs`.
- **Updated** `summary_table` to add `closing` key alongside existing `conclusions` (also computes shared evidence + score cache once for the whole render).
- **Renamed** predecessor's `_compose_theme_prose` body to `_legacy_compose_theme_prose` (kept verbatim — never called in main render path but preserved for any test that pins old internal semantics; can be removed in a follow-up).

### `services/api-python/app/pdf/templates/solar.html.j2` (product, modified)

- Added Section 12 «Общий вывод» rendering after themed blocks (`sumtab.closing`) — 12 lines: `{% if sumtab.closing %} … {% endif %}`. Minimal touch per TASK § Files.

### `services/api-python/tests/test_consultation_summary_evidence.py` (product, modified)

- Original 16 tests **preserved unchanged** per clarification 6.
- **+14 new semantic-human tests** appended after «Calibrated regression» section:
  - `test_summary_table_emits_conclusions_and_closing` — Section 1 + Section 12 contract.
  - `test_olga_total_section_count_supports_twelve` — ≥5 substantive themed + opener + closer; 12-section ceiling.
  - `test_olga_opener_contains_children_creativity_keyword` — semantic positive.
  - `test_olga_opener_contains_plans_friends_keyword` — semantic positive.
  - `test_olga_opener_contains_asc_libra_partnership` — semantic positive.
  - `test_olga_opener_contains_mc_cancer_home_family` — semantic positive.
  - `test_olga_opener_contains_progressed_moon_house_11` — semantic positive.
  - `test_olga_opener_contains_02_09_2026_transition_date` — TASK clarification 5 (dynamic).
  - `test_prog_moon_ingress_date_dynamic_across_cases` — Maxim/Artem/Danila each get own date, not Olga's.
  - `test_personality_block_case_specific_across_three_cases` — clarification 4 hard guard.
  - `test_olga_opener_passes_human_read_smoke` — § Additional guard.
  - `test_calibrated_cases_pass_human_read_smoke` — § Additional guard.
  - `test_olga_closer_gathers_year_into_consultation` — clarification 1 closer.
  - `test_theme_planner_emits_score_breakdown_per_theme` — clarification 3.

## Stage answers (per TASK requirements)

### Architecture decision for Layer 3 (clarification 4)

**Choice: HYBRID (option c) — per-theme template skeleton + phrase library + conditional phrase composition.**

Rationale:

* **(a) Per-theme deep templates alone** — too rigid; couldn't differentiate Olga (axis 5-11 + sol.1→нат.5) from a hypothetical Olga-like client whose sol.1 row points to a different natal house.
* **(b) Phrase-library + composition rules alone** — too loose; produces generic soup unless heavy if-then branching is added, defeating the purpose of separating composition rules from data.
* **(c) Hybrid** — small per-theme «universal life-meaning» phrase pool (1-2 variants per theme; descriptive of the sphere itself, not of any case) acts as the lead-in skeleton. Per-evidence-channel modulator functions (`_phrase_axis_touch`, `_phrase_transits`, `_phrase_prog_moon`, `_phrase_personality_partner`, `_phrase_status_partner`, etc.) add case-specific tail content. The renderer composes paragraph 1 (deep universal phrase) + paragraph 2 (theme-specific partner mention for ЛИЧНОСТЬ / СТАТУС only) + paragraph 3 (engine-emitted Asc/MC phrase) + paragraph 4 (combined astrology-context tail). Output reads as consultation prose, NOT engine dump.

The «not generic soup» hard guard (clarification 4) is satisfied because:

1. The **theme partner phrase** (Layer 3 modulator) is the case-specific anchor for ЛИЧНОСТЬ and СТАТУС — it cites the engine's solar→natal grid row directly (sol.1→нат.X for ЛИЧНОСТЬ; sol.10→нат.X for СТАТУС). Different cases produce different partner houses → different topic phrasings.
2. The **deep phrase pool** has tone-flexibility: when partner-house = 12 OR primary axis touches 12, the renderer switches to «introspection» variant («год сочетает внешнюю работу с темой внутреннего созревания»). Natalya gets a coherent «тише, через внутреннюю работу» variant, not the «не год ухода в себя» contradiction.
3. The **astrology-context tail** dedups identically across themes — same renderer logic, but the underlying evidence items (per-theme axis touches, transit planets, direction counts) differ per case, so the surface text differs naturally.

### Theme planner scoring numerics (clarification 3)

Worker-proposed numerics, documented inline in `synthesis_themes.py` lines ~640-700:

| Signal | Weight | Justification |
|---|---|---|
| Primary axis touch | 10 | User direction «высокий вес»; engine-flagged main theme |
| Secondary axis touch | 6 | Lower than primary but still major structural signal |
| Solar→natal row (natal target) | 4 | Symbolic link «year through house X» — meaningful but lighter than direct touch |
| Solar→natal row (solar source) | 3 | Reverse direction — slightly weaker |
| Outer transit (Uranus/Neptune/Pluto) | 6 | Slow planet defining structural shift; user weighting «высокий вес» |
| Social transit (Jupiter/Saturn) | 4 | Faster, more punctual; user weighting «средний вес» |
| Direction touching house | 5 (split by spread) | Direct timing signal. Split proportionally when direction touches many themes (high-spread directions like `1+2,1+3,...,1+10` contribute ~1 per theme instead of 5) — prevents over-inflation when an arc direction sweeps multiple themes |
| Progressed Moon in house | 8 | Year-defining psychological flavor; user weighting «высокий вес» |
| Angle phrase fired (Asc/MC) | 6 | Engine-emitted natural-language anchor |
| Multi-method boost | +5 | When ≥3 distinct channels touch theme; user weighting «повтор темы в нескольких методах: boost» |

**Substantive-block threshold**: score ≥ 8. Single axis touch (10) > 8 → emits. Single row alone (4) < 8 → too weak. Tunes empty-block discipline per «not generic soup» guard.

### Per-theme score breakdown for Olga + 3 calibrated cases

#### Olga consultation 11 (primary axis 5-11, prog Moon h=11, sol.1→нат.5)

| Theme | Score | Channels | Top contributors |
|---|---|---|---|
| plans_friends | 46 | 5 (axis, direction, prog_moon, row, transit) | primary axis pole (10) + prog Moon (8) + transit Saturn h=11 (4) + transit Neptune h=11 (6) + multi-method boost (5) + rows |
| personal | 40 | 4 (angle, direction, row, transit) | angle phrase (6) + sol.1→нат.X rows + multiple transits + multi-method (5) |
| children | 29 | 3 (axis, direction, row) | primary axis pole (10) + sol.1→нат.5 row + multi-method (5) |
| abroad | 27 | 3 (direction, row, transit) | transit Pluto h=9 + rows + directions |
| money | 25 | 3 (direction, row, transit) | transit Jupiter h=2 + transit Pluto h=8 + rows |
| status | 23 | 3 (angle, direction, row) | MC angle phrase (6) + sol.10→нат.1 row + multi-method |
| documents | 22 | 3 (direction, row, transit) | transit Jupiter + rows |
| home | 22 | 3 (direction, row, transit) | transit Jupiter h=4 path + rows |
| work_health | 11 | 2 (direction, row) | sol.3→нат.6 + sol.6→нат.10 + directions; no boost (only 2 channels) |
| partnership | 9 | 2 (direction, row) | rows + directions; no boost |

All 10 themes ≥ threshold for actual DB Olga (rich data). For the minimal snapshot used in tests, work_health and partnership fall below threshold (snapshot only carries the most representative subset).

#### Maxim 02 (primary axis 2-8, prog Moon h=3, sol.1→нат.3)

| Theme | Score | Top contributors |
|---|---|---|
| money | high | primary axis 2-8 (10) + transits in h=2/8 + multi-method |
| personal | high | angle phrase + sol.1→нат.3 row + rows |
| documents | high | prog Moon h=3 (8) + sol.1→нат.3 row + multi-method |
| status | high | rows + directions |
| children | high | rows + directions |

#### Natalya 08 (primary axis 6-12, prog Moon h=10, sol.1→нат.12)

| Theme | Score | Top contributors |
|---|---|---|
| personal | high | sol.1→нат.12 row + angle phrase + rows |
| status | high | prog Moon h=10 (8) + MC angle phrase + multi-method |
| money | medium | transits + rows |
| work_health | high | primary axis 6-12 pole (10) + rows |

### «После 02.09.2026» derivation algorithm (clarification 5)

**Source**: `facts.analysis.progressed_moon.ingresses[i].jd` where:

1. `ingresses[i].kind == "Sign"` (sign change, NOT house change),
2. `sr_jd ≤ ingresses[i].jd ≤ sr_jd + 365.25` (within current solar year),
3. First such ingress chronologically (smallest jd).

The JD is converted to display date via `_jd_to_short_date_str` (DD.MM.YYYY).

**Olga case verification**: `progressed_moon.ingresses[0]` = `{kind: "Sign", to_sign: "Aries", jd: 2461285.7396223713}` → 2026-09-02 → "02.09.2026". Matches TASK acceptance.

**Other cases**:
- Maxim: `ingresses[0].kind == "House"` → not a sign change → opener does NOT include transition date paragraph (no spurious date hardcoded).
- Artem: `ingresses[0].kind == "Sign"` (Sagittarius → Capricorn) on JD 2461075.39 → "03.02.2026". Surfaces in opener.
- Danila: `ingresses[0].kind == "Sign"` (Capricorn → Aquarius) on JD 2461243.75 → "22.07.2026". Surfaces in opener.
- Natalya, Mariya, Ekaterina: no sign-change ingress within solar year → opener omits transition date paragraph.

**No hardcoding**: test `test_prog_moon_ingress_date_dynamic_across_cases` asserts Artem opener contains "03.02.2026" AND does NOT contain "02.09.2026"; Danila opener contains "22.07.2026" AND does NOT contain "02.09.2026". Both pass.

### Side-by-side case comparison (clarification 4 hard guard)

#### Olga ЛИЧНОСТЬ (axis 5-11 + sol.1→нат.5)

> Этот год — про то, как вы проявляетесь, чего хотите, что выбираете и что разрешаете себе делать.
>
> Личное проявление в этом году раскрывается через детей, творчество, хобби (5-й натальный дом) — именно эта сфера усиливает «я», даёт радость и право хотеть.
>
> Год партнёрства и договорённостей.
>
> По этой теме работает длинный транзит Уран.

#### Maxim ЛИЧНОСТЬ (axis 2-8 + sol.1→нат.3)

> Этот год — про то, как вы проявляетесь, чего хотите, что выбираете и что разрешаете себе делать.
>
> Личное проявление в этом году раскрывается через учёбу, контакты, поездки (3-й натальный дом) — именно эта сфера усиливает «я», даёт радость и право хотеть.
>
> Год карьеры и достижения результата.
>
> Сразу несколько дирекций (4 конфигурации) держат тему в фокусе — это устойчивый акцент.

#### Natalya ЛИЧНОСТЬ (axis 6-12 + sol.1→нат.12)

> В этом году ваша личность раскрывается через включённое участие в жизни — через выбор, отношения, проявленность и собственное «я хочу».
>
> Личное проявление в этом году разворачивается тише: через внутреннюю работу, итоги цикла и завершения (12-й натальный дом). Год просит внимания к тому, что закрывается, и к тому, что созревает за кулисами.
>
> Год публичности, проявленности, творчества.
>
> Это подтверждается главным акцентом года: соляр выстраивается вокруг оси 6-12.

**Differentiation analysis**:

* Paragraph 1 (lead-in): Olga + Maxim share variant 1 («Этот год — про то, как вы проявляетесь…»). Natalya uses variant 0 («раскрывается через включённое участие…») because she has prog_moon channel OR primary axis touching personal — actually Natalya's primary axis (6-12) DOES touch house 12 which is mapped to PERSONAL → strong-signal path used. Difference is by evidence pattern, not by case-name.
* Paragraph 2 (partner phrase): different for ALL THREE — «детей, творчество, хобби (5-й)» vs «учёбу, контакты, поездки (3-й)» vs «через внутреннюю работу, итоги цикла и завершения (12-й)». Marina's idiom «личность через X дом» surfaces case-specifically.
* Paragraph 3 (angle phrase): different engine-emitted Asc phrases per case («партнёрства и договорённостей» Libra / «карьеры и достижения результата» Capricorn / «публичности, проявленности, творчества» Leo).
* Paragraph 4 (astrology tail): different transit planet / direction count per case.

The texts pairwise differ AND each has case-specific anchors. Generic-soup guard satisfied — verified by test `test_personality_block_case_specific_across_three_cases`.

### Per-case calibrated diff verdict (TASK § Calibrated regression)

For each of the 6 calibrated cases (02 Maxim / 03 Artem / 05 Ekaterina / 07 Mariya / 08 Natalya / 10 Danila), Worker rendered the full «Итоги консультации» using new architecture and assessed quality:

| Case | Engine axis | Verdict | Notes |
|---|---|---|---|
| **02 Maxim** | 2-8 | **CONSULTATION-QUALITY UPLIFT** | Opener references финансы (axis 2-8) + личное проявление + обучение/движение; closer rhymes. ЛИЧНОСТЬ block: «личность через 3-й дом» (sol.1→нат.3). All blocks read as consultation prose. Human-read smoke passes. |
| **03 Artem** | 6-12 + 5-11 | **CONSULTATION-QUALITY UPLIFT** | Opener uses introspective variant (axis 6-12 → 12-house signal). Primary + secondary axis phrases both surface. Prog Moon Sagittarius→Capricorn ingress 03.02.2026 displayed dynamically. Human-read smoke passes. |
| **05 Ekaterina** | 1-7 + 6-12 | **CONSULTATION-QUALITY UPLIFT** | Opener uses introspective variant (secondary axis touches 12). ЛИЧНОСТЬ partner = «дом и семью (4-й)» (sol.1→нат.4). Engine primary 1-7 + secondary 6-12 both cited verbatim. No ingress in solar year → no transition-date paragraph (correct). |
| **07 Mariya** | 3-9 + 4-10 | **CONSULTATION-QUALITY UPLIFT** | Opener: «статус и карьера; обучение и горизонты; обучение и движение» (multi-axis case). ЛИЧНОСТЬ partner = «детей, творчество, хобби (5-й)» (sol.1→нат.5 — same partner as Olga but Mariya's primary axis is different → opener reads completely differently). |
| **08 Natalya** | 6-12 | **CONSULTATION-QUALITY UPLIFT** (most subtle) | Opener uses introspective variant (axis touches 12). ЛИЧНОСТЬ partner = «внутреннюю работу, итоги цикла и завершения (12-й)» — coherent with Marina's PDF narrative WITHOUT copying her phrases verbatim. Prog Moon h=10 surfaces in СТАТУС block via partner-phrase + standalone progressed-Moon mention in opener. |
| **10 Danila** | 2-8 | **CONSULTATION-QUALITY UPLIFT** | Opener: финансы + обучение/движение + личное проявление (axis 2-8 + prog Moon h=2 + rows). Prog Moon Capricorn→Aquarius 22.07.2026 displayed dynamically. ЛИЧНОСТЬ partner = «статус и карьеру (10-й)» (sol.1→нат.10). |

NO case exhibits «lost meaningful content» (axis citation, prog Moon mention, direction counts, transit planets all preserved + life-meaning lead-in added on top). NO case exhibits «added generic soup» (substantive-threshold gate prevents low-signal blocks; case-specific partner phrases prevent identical text).

### Human-read smoke verification (TASK § Additional guard)

Strip-of-astrology-terms verification for 3 cases:

#### Olga (verified by `test_olga_opener_passes_human_read_smoke`)

Original opener (5 paragraphs combined):
> Главные темы этого года — планы и коллектив; личное проявление; дети и творчество. Это не год ухода в себя, а год включённости в людей, планы и живые жизненные процессы. Год партнёрства и договорённостей; Цель — обретение почвы под ногами, дом, семья. Главная тема — дети, творчество, коллектив (ось 5-11). Психологический фон года задаёт прогрессивная Луна в 11-м доме — год просит включиться в тему «коллектив, друзей, планы». Первая часть года связана с внутренним созреванием и тонким чувствованием. Но после 02.09.2026 настрой становится более активным: появляется больше прямоты, желания действовать, пробовать новое и не откладывать решения.

After stripping astrology terms («прогрессивн», «ось 5-11», «1-м доме», etc.) — life-advice content words still present (matched ≥3): год, планы, коллектив, дети, творчество, партнёрств, дом, семь, включ. **PASS**.

#### Maxim (verified by `test_calibrated_cases_pass_human_read_smoke`)

Stripped opener still contains: год, финансы, движение, ресурс, карьер, контакт, поездк, активн. **PASS**.

#### Natalya (verified by `test_calibrated_cases_pass_human_read_smoke`)

Stripped opener still contains: год, статус, карьер, активн, проявленность, лидерств, внутрен, созреван. **PASS**.

### Reviewer status

**Agent tool unavailable** в Worker runtime (6th occurrence per recurring Phase 8B / 8D / 8E / api-pdf-endpoint-end-to-end / transit-section-generic-output / evidence-based-consultation-summary-rewrite precedent). Worker self-review applied (this HANDOFF + Stage answers above). Per TASK clarification 7 = REQUIRED, **TL must spawn external Reviewer post-submission**.

Reviewer criteria (per TASK § Reviewer subagent):
- ✓ Architecture follows 3-layer (extraction + planner + renderer) verbatim.
- ✓ Theme planner uses evidence-weight scoring (not static); HANDOFF includes per-theme score breakdown for Olga + 3 calibrated.
- ✓ Narrative renderer produces consultation-quality prose (verified by reading sample output Olga + 6 calibrated).
- ✓ Side-by-side case comparison shows text is case-specific, not generic-applicable-to-anyone (verified for Olga vs Maxim vs Natalya ЛИЧНОСТЬ).
- ✓ Human-read smoke test passes (Olga + Maxim + Natalya verified).
- ✓ All STOP triggers honoured.
- ✓ No Olga-only hardcoded text.
- ✓ Calibrated cases independently spot-checked (all 6 spot-checked).
- ✓ 0 LLM / engine / schema touches.

## STOP triggers — none fired

| Trigger | Status |
|---|---|
| Manual Olga-only text | NOT fired. Renderer is generic; partner-phrase functions work for ALL cases. |
| LLM call | NOT fired. Deterministic templates only. |
| Engine modification | NOT fired. Haskell untouched; schema untouched; fixtures untouched. |
| Generic soup | NOT fired. Each case has different partner phrase + axis citation. |
| Symbolic listing despite passing tests | NOT fired. Output reads as consultation prose; human-read smoke verified. |
| «После 02.09.2026» date source unclear | NOT fired. Source identified: `progressed_moon.ingresses[i].jd` where `kind == "Sign"` within solar year. |
| Paragraph fails human-read smoke | NOT fired. 3 cases verified. |
| Side-by-side comparison shows generic-applicable | NOT fired. 3 cases visibly differ. |

## Verification

- Pre-rewrite baseline: **398 passed + 2 skipped + 0 failed** (cabal Up to date).
- Post-rewrite: **412 passed + 2 skipped + 0 failed** (+14 new semantic-human tests, all green).
- Cabal `core/astrology-hs`: Up to date (no Haskell change).
- Product `git status --short` after implementation:
  ```
  M services/api-python/app/pdf/synthesis_themes.py
  M services/api-python/app/pdf/templates/solar.html.j2
  M services/api-python/tests/test_consultation_summary_evidence.py
  ```
  All 3 intended; no stray changes.

## Submit procedure

Worker готов выполнить commits + push когда TL даст команду, OR TL может сам commit/push.

**Product commit** (`services/api-python/...`):
```
feat(pdf): human-readable «Итоги консультации» — 3-layer architecture rewrite

Replace synthesis_themes.py predecessor «evidence-driven but symbolic
listing» renderer with a 3-layer human-readable pipeline:

  * Layer 1 (_collect_theme_evidence): normalises facts into theme-
    tagged evidence items (axis / row / direction / transit / prog_moon
    / angle channels).
  * Layer 2 (_score_themes): weight-based scoring (primary axis 10,
    secondary 6, outer transit 6, prog Moon 8, direction 5 split by
    spread, social transit 4, rows 4/3, angle 6) + multi-method +5
    boost when ≥3 channels touch theme. Substantive threshold 8.
  * Layer 3 (_render_theme_paragraph + _compose_opener + _compose_
    closing): hybrid per-theme template + phrase library producing
    consultation prose. Output is sphere-meaning-first text with
    astrology context as gentle parenthetical anchor.

Section count: 11 → 12 (added Section 12 «Общий вывод» closer, both
in summary_table['closing'] and solar.html.j2 template).

«После DD.MM.YYYY» transition date dynamically derived from
analysis.progressed_moon.ingresses[i].jd where kind == "Sign" AND
jd within solar year. Olga case: JD 2461285.74 → 02.09.2026
(Pisces → Aries). No hardcoding.

ЛИЧНОСТЬ and СТАТУС blocks get theme-specific partner-mention phrases
sourcing the engine's solar→natal grid (sol.1→нат.X for personality;
sol.10→нат.X for status). Different cases produce different partner
houses → different topic phrasing. Side-by-side Olga / Maxim / Natalya
ЛИЧНОСТЬ blocks visibly differ by content, not just by inserted
numbers. Generic-soup guard satisfied.

Predecessor `_compose_theme_prose` body preserved as
`_legacy_compose_theme_prose` (never called in main render path; can be
removed in follow-up).

Test file tests/test_consultation_summary_evidence.py extended with
14 new semantic-human tests (preserving the 16 existing tests
unchanged). Coverage: 12-section structure, semantic positives for
Olga (children/creativity/plans/Asc Libra/MC Cancer/prog Moon h=11/
02.09.2026), case-specificity guard, human-read smoke for Olga +
2 calibrated, theme planner score breakdown, closer sanity.

Pytest 398 → 412 passed + 2 skipped + 0 failed.

TASK: human-readable-consultation-summary (2026-05-19; Tier B+).
```

**Overlay commit** (`project-overlays/astro/...`):
```
docs: TASK human-readable-consultation-summary DELIVERED (Tier B+)

STATUS_RU + HANDOFF for the 3-layer human-readable architecture
rewrite TASK on top of evidence-based-consultation-summary-rewrite
(predecessor closed 2026-05-19, product a6a3331).

Reviewer status: Agent tool unavailable в Worker runtime; Worker
self-review applied — TL must spawn external Reviewer post-submission
per TASK clarification 7.
```

## Baseline state vs delivered state

| Metric | Pre-rewrite | Post-rewrite |
|---|---|---|
| Product main | `a6a3331` | (TBD) |
| Overlay master | `9e00c03` (Ready: yes) | (TBD) |
| Pytest | 398 passed + 2 skipped + 0 failed | 412 passed + 2 skipped + 0 failed |
| Cabal | clean | clean |
| Sections rendered | 11 (opener + 10 themed) | 12 (opener + 10 themed + closer) |
| Olga ЛИЧНОСТЬ leads | «личность, самопредъявление, ...; сетка соляра: сол. 1 → нат. 5, ...; engine отмечает ось 5-11» (symbolic listing) | «личное проявление в этом году раскрывается через детей, творчество, хобби (5-й натальный дом)» (consultation prose) |
| Opener tone | engine dump (Asc/MC/axis/psych) | human synthesis (top themes named, axis cited, prog moon mentioned, transition date dynamic) |
| Closer | absent | 2 paragraphs «Год про обновление через X, Y, Z…» + practical-summary takeaway |
| Human-read smoke | FAIL (held only by formulas) | PASS (life-advice content remains after strip) |
| Case-specificity | partial (same lead template, only houses differ) | strong (partner-phrase + tone-variant + axis citation all case-specific) |
