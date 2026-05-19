# TASK: phase-9-3-a-outer-card-horizon-window-validation

- Status: done
- Ready: yes
- Date: 2026-05-19
- Project: astro
- Layer: presentation analysis (Python: `outer_cards.py` window selection — analytical memo only, no code)
- Risk tier: C (validation-only memo; no product code; no schema; no fixtures)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Manual verification of Olga `solar-12.pdf` vs Marina reference `Соляр 2026-2027.pdf` (user, 2026-05-19) confirms Phase 9.2B angle-filter работает корректно (0 angle-target cards), но обнаруживает два явления вне 9.2B scope:

1. **Planet-target over-include cards** (5 для Olga cons11 / cons12): Уран секст Меркурий, Уран кв Луна, Нептун кв Марс, Нептун кв Нептун, Плутон секст Юпитер. Все имеют первое касание **вне solar-year окна** (pre-SR 2024-2025 или post-SR 2027-2029). Diagnostic 2026-05-18 (cons 10 vs cons 11) показал: cons 10 узкий sample horizon → emit set точно = Marina 6; cons 11 расширенный horizon → emit set = Marina 6 + 5 over-include.

2. **Wide intervals within Marina-selected cards** (примеры из user verify):
   - Уран кв Венера: Marina 1 окно `02.12.2026–15.04.2027`; engine 3 окна вкл. 2025/2026 ранние touches.
   - Уран опп Юпитер: Marina 1 окно `28.12.2026–22.03.2027`; engine 3 окна.
   - Нептун трин Юпитер: Marina 1 окно `18.10.2026–05.02.2027`; engine 3 окна.
   - Плутон секстиль Уран: engine windows смещены относительно Marina.

Оба явления — **horizon / window selection policy**, не filter-by-target. 9.2B explicitly drops only angle-targets per closure verdict. Это требует separate Stage 0 validation memo (как 9.2A для angle-filter) до любого implementation.

Phase 9.0 memo § 5.3 verdict: «**C — intervals (hybrid, strong editorial residual)**: Default `show engine N windows` fits 60-70%. Cases 02/04 + Ольга card-narrowing (1 of 3 engine windows shown) — editorial choice, не deterministic из 10-case sample.»

Per Phase 9.x meta-lesson (verbatim): «All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation.»

## Worker framing (verbatim user direction 2026-05-19)

> «Title: `Phase 9.3A — Outer Card Horizon / Window Selection Validation`. Scope: memo-only, no code. Проверить (1) Ольгу: сравнить cons10 vs cons11, какие карточки исчезают/появляются из-за horizon, какие окна внутри 6 Marina-selected совпадают с Мариной, какие окна pre-SR / post-SR overreach. (2) Calibrated cases: взять existing allowlist cards, сравнить window counts/boundaries с Marina reference, выявить где Marina показывает all windows, а где режет до 1 окна. (3) Протестировать гипотезы. (4) Выход: PASS/PARTIAL/FAIL по каждой гипотезе, какая политика лучше всего приближает Марину, implementation proposal только если правило устойчивое, иначе honest editorial verdict + per-case override predложение.»

## Scope (Tier C validation-only memo)

### Stage 0 — Inventory phase

**0.1 — Olga consultations 10 + 11 facts comparison:**
- Read `data/astro.db` consultations 10 + 11 `facts_json`.
- Inventory `(transit_planet, aspect, target)` triples emitted per consultation.
- Inventory display_windows per triple via `generic_outer_cards()` (read-only call).
- Cross-classify: Marina-selected (6 per Phase 9.2A § 1.1) vs over-include.
- For each over-include card: first-touch date relative to `solar_chart.return_jd`.
- For each Marina-selected card: full window inventory + per-window start/end дата + JD относительно SR.

**0.2 — Calibrated cases window inventory — main scoring set (per user clarification 3 = (a)):**
- Data source: `services/api-python/tests/test_multi_case_calibration.py:870-967` `MARINA_OUTER_CARD_BOUNDARIES`.
- **Main scoring set: 4 cases** — `01-kseniya-2024-2025`, `03-artem-2025-2026`, `05-ekaterina-2025-2026`, `10-danila-2025-2026` — full Marina window boundary data available.
- For each card в `MARINA_OUTER_CARD_BOUNDARIES[case_id]`: tabulate Marina window count + start/end dates + relation to solar return JD.
- Compare engine emit (via `_OUTER_CARD_FACTS` / `OUTER_CARD_ALLOWLIST` raw data OR re-derive via `generic_outer_cards`-style logic from `consultations.facts_json` if DB row exists) — count and boundary divergence.
- **Informational caveat set: 4 cases** — `02-maksim`, `04-valeriya`, `08-natalya`, `09-anastasiya` — NOT в main hypothesis scoring (single-Marina-window divergence; Marina W1 = engine W2/W3 partial alignment per Phase 8 audit § A.2.1.D). Worker может cite их в memo § 4 background only; NOT в Stage 2.3 verdict scoring.

**0.3 — Marina-Olga window source — strict-scope PDF extraction (per user clarification 1 = (b)):**
- Source PDF: `/Users/ilya/Downloads/Соляр 2026-2027.pdf`.
- **Strict scope:** extract window boundaries (start / end dates) ONLY для 6 Marina-selected Olga cards: Uranus Square Venus, Uranus Opposition Uranus, Uranus Opposition Jupiter, Neptune Trine Jupiter, Neptune Trine Uranus, Pluto Sextile Uranus.
- **NO free-form text re-interpretation**, NO secondary inference, NO scope creep beyond window dates.
- Output structure: dict `{(transit_planet, aspect, target): [(start_date, end_date), ...]}` parallel `MARINA_OUTER_CARD_BOUNDARIES` shape, stored в memo § 1 inventory table.
- Confirm against user verbatim formulation (4 cards explicit dates per user manual verify 2026-05-19): Uranus Square Venus `02.12.2026–15.04.2027`, Uranus Opposition Jupiter `28.12.2026–22.03.2027`, Neptune Trine Jupiter `18.10.2026–05.02.2027`, Pluto Sextile Uranus «windows смещены» (no Marina dates verbatim — Worker extracts from PDF). Remaining 2 cards (Uranus Opposition Uranus, Neptune Trine Uranus) — Worker extracts from PDF.
- Cross-reference Phase 9.2A § 1.3 partial extract for any consistency check.

### Stage 1 — Hypothesis enumeration

User-provided starter list (6 hypotheses):

1. **H1** — `window overlaps solar year` (`window.start <= SR+365d AND window.end >= SR-N`).
2. **H2** — `window intersects [SR - 30d, SR + 365d]`.
3. **H3** — `window intersects [SR - 90d, SR + 365d]`.
4. **H4** — `show windows whose exact/center point lies inside solar year` (window center JD ∈ `[SR, SR+365]`).
5. **H5** — `show latest touch before solar year + following loop within solar year` (Marina display rule «last pre-SR + intra-SR cluster»).
6. **H6** — `planet-specific cap` для Uranus / Neptune / Pluto (e.g., Uranus max 3 windows; Pluto max 1-2).

**Worker scope re: hypotheses (per user clarification 2 = (b) — starter + composite expansion):**

H1-H6 above are starter set. Worker authorized to propose дополнительные composite rules (e.g. `H_X AND H_Y`, `H_X OR H_Y`, planet-conditional variants), **обязательно separately:**

- Show base H1-H6 score first (raw, no composites).
- Show composite rule score with delta vs best base hypothesis.
- **Test for overfit risk:** apply composite rule к Olga set (6 Marina cards) AS HELD-OUT; document если composite rule trained на calibrated 4 cases ломается на Olga.
- Document «hypothesis discovered post-hoc» каждой composite rule с explicit naming convention (e.g. `H7 = H2 AND H6`, `H8 = (H4 OR H5) AND planet-cap`).
- **Final aggregate recommendation** must distinguish: «best base hypothesis (no overfit risk)» vs «best composite (with overfit caveat)».

### Stage 2 — Per-hypothesis evaluation

For each hypothesis H1-H6 (+ any added):

**2.1 — Apply to each card-case combination:**
- For each `(case_id, card)` ∈ {4 calibrated cases × cards available in MARINA_OUTER_CARD_BOUNDARIES}:
  - Engine emit windows = full list per `_OUTER_CARD_FACTS` (or recompute via aggregate_display_windows from raw hits).
  - Marina windows = `MARINA_OUTER_CARD_BOUNDARIES[case_id][(tp, asp, tgt)]`.
  - Hypothesis output = subset of engine windows passing H_i.
  - **FN per card** = Marina windows missing from H_i output.
  - **FP per card** = H_i output windows not present in Marina.
  - **Match per card** = window count + boundary alignment ±2d.

**2.2 — Apply to Olga (cons 10 + cons 11):**
- Card-set classification:
  - Cards Marina-selected (6) → check if hypothesis preserves all 6 (gate-like: 0 card-FN allowed).
  - Cards Marina-rejected (over-include) → check if hypothesis drops them (informational).
- Window-set classification per Marina-selected card:
  - Within each Marina-selected card, hypothesis selects subset of engine windows.
  - Compare with user-provided Marina window date (4 cards explicit; rest «no Marina reference»).

**2.3 — Tabulate per hypothesis:**
- Per-case + per-card FN / FP counts.
- Aggregate Marina-window-coverage rate (∑ Marina windows covered ÷ ∑ Marina windows total).
- Aggregate Marina-card-coverage rate (∑ Marina-selected cards preserved ÷ ∑ Marina-selected cards total).
- Verdict label per hypothesis (per user clarification 4 — confirmed):
  - **PASS** = 0 card-FN ∧ ≥90% window coverage.
  - **PARTIAL** = 0 card-FN ∧ 60-90% window coverage.
  - **FAIL** = 1+ card-FN OR <60% window coverage.
- Window coverage = (Marina windows matched by hypothesis ÷ total Marina windows across 4 calibrated cases). Match tolerance ±2 days (consistent с `_OUTER_CARD_BOUNDARY_TOLERANCE_DAYS` Phase 8 convention).
- Card-FN counted across 4 calibrated cases + 6 Olga Marina-selected cards (= 10-card гate).

### Stage 3 — Verdict synthesis

Memo output structure:

**§ 1.** Per-case window inventory (Marina + engine + over-include).
**§ 2.** Per-hypothesis evaluation table (H1-H6 × cases × cards).
**§ 3.** Aggregate scoreboard (which hypothesis приближает Marina наиболее).
**§ 4.** Olga horizon root-cause analysis (cons10 vs cons11 sample horizon diff).
**§ 5.** Recommendation:
- If 1+ hypothesis PASS → **§ 5.1 implementation outline** (Tier B-like proposal: which file, what one-line filter, expected test pattern). Parallel к Phase 9.2A § 5.1.
- If all hypotheses PARTIAL → **§ 5.2 partial-acceptance verdict** (best-fit hypothesis + residual editorial scope).
- If all hypotheses FAIL → **§ 5.3 editorial verdict** + per-case override proposal (extend `_OUTER_CARD_FACTS` или add separate window-override structure, similar to Phase 4b `STRUCTURED_OVERRIDES`). NOT implementation, just framing.

**§ 6.** Phase 9.0 memo § 5.3 erratum (per user clarification 5 = (b) — all-paths draft в HANDOFF):

Worker drafts erratum в HANDOFF for **every verdict path**, не FAIL-only convention:

- **PASS path erratum draft:** «Memo § 5.3 verdict `hybrid / strong editorial residual` superseded → `deterministic / rule H_i confirmed`. Hypothesis [name] yields 0 card-FN ∧ ≥90% window coverage across 4 calibrated cases + 6 Olga Marina-selected. Implementation deliverable proposed Phase 9.3B (Tier B, 1-file modification in `outer_cards.py`).»
- **PARTIAL path erratum draft:** «Memo § 5.3 verdict `hybrid / strong editorial residual` superseded → `partial deterministic [H_i] + editorial residual`. Hypothesis [name] yields 0 card-FN ∧ X% window coverage; residual Y% requires per-case override structure (similar Phase 4b `STRUCTURED_OVERRIDES`).»
- **FAIL path erratum draft:** «Memo § 5.3 verdict `hybrid / strong editorial residual` superseded → `editorial / curation-required`, parallel к Phase 9.1 § 5.1 erratum (directions). No deterministic horizon/window rule accepted as of 2026-05-19. Per-case override structure proposed в § 5.3 этого memo.»

Erratum landed в memo file **только после user explicit ack** (FAIL-only convention из 9.2A не applicable здесь — PASS/PARTIAL/FAIL all require user ack before memo § 5.3 modification, parallel Phase 9.1 erratum landing pattern).

## Files

- new:
  - `project-overlays/astro/ARCHITECTURE/phase-9-3-a-outer-card-horizon-window-validation-2026-05-19.md` (validation memo, ~800-1200 lines).
  - `project-overlays/astro/HANDOFFS/2026-05-19-worker-to-tl-phase-9-3-a-outer-card-horizon-window-validation.md`.

- modify:
  - `project-overlays/astro/STATUS_RU.md` (Phase 9.3A «Сейчас» entry).

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures (no engine output recomputation; use existing facts).
- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` — calibrated data read-only.
- `generic_outer_cards()` / `ANGLE_TARGETS` — Phase 9.2B closed; no filter modification.
- `solar.html.j2` template.
- `builder.py`.
- `MARINA_OUTER_CARD_BOUNDARIES` — read-only data source.
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs.
- Phase 9.0 memo — read-only reference document (erratum may be drafted в HANDOFF per § Ready clarification, NOT in product).
- Phase 9.1 / 9.2 / 9.4 closures — unaffected.
- Other test files (e.g. `test_directions_section.py`, `test_summary_themes.py`).
- **DO NOT modify product code** (Tier C scope).
- **DO NOT write tests** (validation-only memo).
- **DO NOT propose implementation в этом TASK** — implementation proposal в memo § 5.1 OR § 5.3 only as **outline for future Phase 9.3B TASK**, не deliverable этой phase.

## Acceptance

### Primary

- [ ] Stage 0 inventory complete (Olga cons10/11 + 4 calibrated cases per `MARINA_OUTER_CARD_BOUNDARIES`).
- [ ] Stage 1 hypothesis list finalised (≥6 per user starter; expansion per § Ready clarification).
- [ ] Stage 2 per-hypothesis evaluation table populated.
- [ ] Stage 3 verdict: clear PASS / PARTIAL / FAIL per hypothesis + aggregate recommendation.
- [ ] Memo § 5 implementation outline OR editorial verdict + override proposal.
- [ ] Memo § 6 Phase 9.0 § 5.3 erratum convention applied per § Ready clarification.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: pytest passes **382 + 2 skipped + 0 failed** baseline preserved (no test files written).
- [ ] `git status --short` clean for intended changes (overlay artifacts only; NO product code modified).
- [ ] One overlay commit (memo + HANDOFF + STATUS_RU).
- [ ] Push backup, parity verified.

### Discipline

- [ ] NO product code modifications (Tier C strict).
- [ ] NO tests written.
- [ ] NO engine recomputation (use existing `consultations.facts_json`).
- [ ] NO ad-hoc Marina PDF re-extraction (or per § Ready clarification subset).
- [ ] Hypothesis testing strictly from listed H1-H6 (or per § Ready expansion clarification).
- [ ] Memo verdict drives recommendation, NOT preconception.

## STOP triggers

- Worker tempted to modify product code → STOP, Tier C scope.
- Worker tempted to write tests → STOP, validation-only.
- Worker tempted to recompute engine output → STOP, use existing facts.
- Worker finds hypothesis empirically falsified mid-analysis → log + continue (per Phase 9.x meta-lesson «empirical findings supersede memo predictions»).
- Worker tempted к Phase 9.0 memo § 5.3 modification (in-place edit) → STOP, erratum convention applies (FAIL-only OR per user clarification).
- Worker tempted to propose multi-hypothesis combination rule («H_X AND H_Y») without empirical support → STOP, only test discrete hypotheses.

## Reviewer subagent — OPTIONAL (per user clarification 6)

Tier C validation-only. Reviewer optional; TL inline-verify достаточно per Phase 9.2A precedent. Если Worker prefers Reviewer pass — может spawn'нуть, не блокер.

## Context

**Mode normal + Tier C (Reviewer optional per user clarification 6).** Worker mode: normal.

**Baseline:**
- Product main @ `7751d46` (Phase 9.2B angle-filter landed; pytest 382/2/0).
- Overlay master @ `e66e67f` (Phase 9.2B closure).
- Cabal: clean.

**Cross-references:**
- Phase 9.0 memo § 5.3 «intervals: hybrid, strong editorial residual»: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Phase 9.2A validation memo (parallel pattern): `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md`.
- `MARINA_OUTER_CARD_BOUNDARIES` data source: `services/api-python/tests/test_multi_case_calibration.py:870-967`.
- `generic_outer_cards()` (read-only reference): `services/api-python/app/pdf/outer_cards.py:1671-1769`.
- Olga DB consultations: `/Users/ilya/Projects/astro/data/astro.db` rows id=10 (narrow horizon, 6 cards exact Marina) + id=11 (wide horizon, 11 cards = 6 + 5 over-include).
- User manual verify report 2026-05-19 (this TASK Problem § + Worker framing § verbatim).

**Not in scope (explicit):**
- Calendar-aspect over-include (Pluto 150° Asc/Venus) — new 5th sub-problem, separate future Phase 9.5A track per user direction 2026-05-19.
- Directions over-include (9 vs Marina 4) — Phase 9.1 editorial verdict, separate curation track.
- Summary axis editorial (Olga 5-11 axis) — Phase 9.4 editorial residual, separate track.
- Implementation (Phase 9.3B placeholder if 9.3A produces PASS hypothesis).

**Ready: yes** — 6 clarifications applied 2026-05-19:

1. **Marina-Olga window source = (b):** allow strict-scope PDF window-date extraction (`/Users/ilya/Downloads/Соляр 2026-2027.pdf`), window boundaries only для 6 Olga-selected cards; no free-form re-interpretation. Applied Stage 0.3.

2. **Hypothesis enumeration = (b):** H1-H6 starter + Worker может propose composite rules; обязательно показать base score first, composite delta, overfit risk (test on Olga as held-out). Applied Stage 1.

3. **Calibrated cases = (a):** main scoring restricted к 4 cases с full `MARINA_OUTER_CARD_BOUNDARIES` (01/03/05/10); cases 02/04/08/09 informational caveat only (memo § 4 background), NOT в Stage 2.3 verdict scoring. Applied Stage 0.2.

4. **Verdict thresholds confirmed:** PASS = 0 card-FN ∧ ≥90% window coverage; PARTIAL = 0 card-FN ∧ 60-90%; FAIL = 1+ card-FN OR <60%. Match tolerance ±2 days. Applied Stage 2.3.

5. **Erratum convention = (b):** ALL paths (PASS / PARTIAL / FAIL) draft erratum в HANDOFF for user ack; erratum landed в memo file только после user explicit ack. Applied § 6.

6. **Reviewer subagent = optional:** TL inline-verify достаточно per Phase 9.2A precedent. Applied Reviewer section.
