# TASK: phase-8e-before-buffer-extension

- Status: open
- Ready: no
- Date: 2026-05-15
- Project: astro
- Layer: services (Python `bridge.py` BEFORE buffer parameter) + tests
- Risk tier: B (engine sample-window parameter touch via Python `bridge.py`; same layer as TASK 8B AFTER buffer; escalation to Tier A if schema cascade triggered)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

TASK 8D Reviewer subagent (2026-05-15) empirically confirmed the **pre-buffer truncation finding** flagged in audit § A.2.1.D:

- Case 01 (Кseniya) `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540` truncates Neptune outer-card W1 starts:
  - N-Sun W1: engine emits `29.05.2023 06:14 GMT+3` = **SR-540d to-the-second**; Marina W1 = `17.04.2023` (SR-582d, +42d into pre-buffer zone).
  - N-Mars W1: engine emits same `29.05.2023 06:14 GMT+3` = SR-540d; Marina W1 = `12.05.2023` (SR-557d, +17d into pre-buffer zone).

This is **symmetric to TASK 8B Path 1** AFTER-buffer finding: engine sample window cuts off Marina-derivable boundaries that lie just past the horizon. Phase 4a memo correctly identified Marina-editorial boundaries elsewhere (e.g. 08 N-N W1 start +178d Δ — empirically inside current buffer, not on boundary), but the BEFORE side has its own truncation cases analogous to AFTER side fixed by TASK 8B.

Per user direction 2026-05-15 Option δ:
- Symmetric to TASK 8B: **systemic** `outer_card_lookbehind_days` rule, NOT case-01 tuning.
- Empirical check on 08 N-N W1 start: if converges to Marina post-fix → retract second part of Phase 4a memo (would be analogous Path 1 erratum); if stays divergent → true editorial, keep ±200d override.
- Calendar/monthly clipping guards mandatory.
- **NOT in scope:** Pluto display rule, single-window alignment, case 03 P-Mars typo, Анастасия TYPE-D (all remain audit § A.2.1.D future work items).

## Stages

### Stage E.1 — Trace current BEFORE buffer

Worker locates `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE` parameter в `services/api-python/app/ephemeris/bridge.py` (likely line 204 per existing TASK 8B Reviewer trace).

Reports current value (540), location, scope (outer-planet hits only / all annual_transit_table entries / both).

### Stage E.2 — Determine target BEFORE buffer (SYSTEMIC, not case-01-specific)

Worker introduces or extends systemic named parameter `outer_card_lookbehind_days` (mirror of TASK 8B `outer_card_lookahead_days`).

**Default proposal:** `outer_card_lookbehind_days = 365.25 * 2` (~730 days, ~2 solar years).

Rationale:
- Mirrors TASK 8B AFTER buffer (540 → 730 already landed).
- Solar return charts narrate the year ahead; "before SR" context typically extends only to the previous outer-card touch (rarely > 2 years).
- TASK 8D Reviewer empirical: Marina 01 N-Sun = SR-582d; N-Mars = SR-557d. Both within proposed 730d buffer with ~150d / 173d margin respectively.
- Worker bloat impact analysis BEFORE committing default (per Stage E.5.b).

**Anti-pattern (STOP trigger):** if Worker tunes `outer_card_lookbehind_days = max(Marina 01 N-Sun W1 start delta, Marina 01 N-Mars W1 start delta) + 60d` — that's case-01 tuning, NOT systemic. STOP, reread E.2.

If `365.25 * 2 = 730d` overshoots presentation-calendar bloat threshold for any case → Worker proposes tighter alternative (e.g. `365.25 * 1.5` = 548d — barely above current 540d) with row-count reasoning в HANDOFF.

### Stage E.3 — Schema-cascade detection

Verify whether BEFORE buffer change touches `packages/contracts/*.schema.json`:
- Runtime parameter, same JSON output shape → no cascade, Tier B sufficient.
- New schema fields needed → **STOP**, Tier A escalation memo, separate TASK with full schema cascade (Bright Line #8).

### Stage E.4 — Apply BEFORE buffer extension

Change `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540 → 730` (or per E.2 reasoning). Minimal change.

**DO NOT change AFTER buffer** (`_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 730` from TASK 8B stays at 730).

### Stage E.5 — Regression guards (CRITICAL)

All must pass:

**a. Phase 4b 08 N-N W1 start empirical check (KEY DECISION POINT):**
- Re-extract 08 N-N W1 start via `outer_cards_for_case` post-fix.
- **If Δ stays at -178d ±2d:** N-N W1 start is true Marina-editorial. Phase 4b ±200d override STAYS. Phase 4a memo erratum stands (only N-J W3 retracted, N-N W1 still editorial per memo).
- **If Δ converges to within ±2d of Marina:** N-N W1 was ALSO horizon truncation (same family as N-J W3 retracted by TASK 8B Path 1). Phase 4a memo gets **second erratum subsection**: «N-N W1 start was also misclassified as editorial; Phase 8E BEFORE-buffer extension proves it was also horizon truncation». Phase 4b ±200d override gets removed in Stage E.6.2. **This would be the second retraction.**
- TL prediction (pre-Worker): Δ stays -178d (ours at SR-491d is inside even current 540d buffer; engine's orb_enter doesn't depend on buffer being wider). Worker confirms empirically.

**b. Case 01 boundary convergence:**
- 01 N-Sun W1 start: must converge to Marina `17.04.2023` within ±2d.
- 01 N-Mars W1 start: must converge to Marina `12.05.2023` within ±2d.
- If either does NOT converge → horizon margin insufficient; investigate or propose wider `outer_card_lookbehind_days`.

**c. Presentation calendar does NOT bloat (post-clipping, not raw):**
- Phase 6 `[sr_jd, sr_jd + 365.25]` clipping filters pre-SR rows out of presentation calendar.
- Theoretical impact on presentation calendar = 0 (no rows BEFORE SR appear in client PDF). Worker verifies empirically.
- Raw `annual_transit_table` row count may grow per case — that's the point. Report raw + presentation ratios per case в HANDOFF.
- Presentation threshold ≤ 1.5× per case (any case bloats > 1.5× → STOP).

**d. Monthly transit tables preserved:**
- Cases 05/07/08/10 monthly cells matrix bit-identical pre/post (none should shift; monthly snapshot is mid-15 of solar-year months, BEFORE buffer extension doesn't affect snapshots).
- **STOP** if any cell shifts.

**e. Non-Данила, non-N-N-W1, non-01-N-Sun, non-01-N-Mars boundaries preserved:**
- All 92 existing `MARINA_OUTER_CARD_BOUNDARIES` entries retain pre-fix Δ values (within ±2d of current).
- Only intended changes: 01 N-Sun + N-Mars W1 starts converge to Marina; PLUS possibly 08 N-N W1 start converges (if TL prediction wrong).
- Any other Δ value shift → STOP, escalation.

**f. Pytest pre-Stage-E.6:**
- `286 passed + 0 xfailed + 0 failed` baseline preserved (before any test changes from E.6).

### Stage E.6 — Test contract updates

**E.6.1 — Enroll case 01 N-Sun + N-Mars W1 starts in MARINA_OUTER_CARD_BOUNDARIES:**
- Add 2 cards × 3 windows × 2 sides = 12 new boundary points.
- Per Phase 8C C.1 helper (date-only ±2d tolerance).
- `# SoT: ... § A.2.1.D` cross-ref comment.
- Update audit § A.2.1.D table row for 01 N-Sun and 01 N-Mars: mark `[ENROLLED post-Phase-8E]`.

**E.6.2 — Phase 4b 08 N-N W1 start override (conditional on E.5.a):**
- **If 08 N-N W1 start Δ stays -178d (TL prediction):** Override stays. Phase 4a memo unchanged. No test changes for Натальи.
- **If 08 N-N W1 start Δ converges to Marina:** Override REMOVED from `test_natalya_transits_acceptance.py` (analogous to TASK 8B B3.2). Phase 4a memo gets second erratum subsection.

Worker decides based on Stage E.5.a empirical result. Do NOT silently keep override if values converged; do NOT silently remove if values stay divergent.

### Stage E.7 — Calibration report + audit updates

- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` § 6: new verdict subsection «Verdict update (post-Phase-8E, 2026-05-15)» — final program closure verdict.
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` § A.2.1.D: 2 case-01 rows marked `[ENROLLED post-Phase-8E]`; future work item 1 (pre-buffer extension) marked `[RESOLVED via TASK 8E]`.
- If E.6.2 retracts: append second erratum to `transit-contact-window-semantics-2026-05-13.md` Phase 4a memo (analogous to first erratum 2026-05-14).
- `project-overlays/astro/STATUS_RU.md` narrative update.

## Reviewer subagent (REQUIRED, narrow-scope per Tier B)

After Stage E.4-E.7 complete, spawn Reviewer subagent (`general-purpose`). Reviewer scope:

1. Verify `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE 540 → 730` is the only product code change in `bridge.py` (one-line minimal).
2. Verify AFTER buffer untouched (stays 730 from TASK 8B).
3. Verify 01 N-Sun + N-Mars W1 starts converge to Marina ±2d.
4. Verify 08 N-N W1 start empirical result + appropriate override action (stays / removed per Stage E.6.2).
5. Verify per-case presentation calendar ≤ 1.5×; monthly tables bit-identical.
6. Verify fixture regen justification table per case (per Bright Line #8 + TASK 8B precedent).
7. Independent pytest run.

Reviewer reports APPROVE / REQUEST CHANGES / ESCALATE. Worker incorporates feedback before final commit.

## Fixture regen safeguard

Mirror of TASK 8B safeguard:
- DO NOT silently overwrite expected.json / input.json.
- HANDOFF must include per-case justification table:
  | case | raw row count before | raw row count after | Δ rows | why changed | downstream assertion proving intended |
- Worker walks through prose line-by-line.
- Reviewer verifies independently.
- Atomic commit per Bright Line #8.

## Files

- modify:
  - `services/api-python/app/ephemeris/bridge.py` (E.4 — one-line BEFORE buffer change).
  - `services/api-python/tests/test_multi_case_calibration.py` (E.6.1 — 12 new boundary points for 01 N-Sun + N-Mars).
  - `services/api-python/tests/test_natalya_transits_acceptance.py` (E.6.2 ONLY if 08 N-N W1 converges; otherwise UNCHANGED).
  - `packages/test-fixtures/golden-cases/*.expected.json` + `*.input.json` (fixture regen if engine output for BEFORE buffer rows differs; per Bright Line #8).
  - `project-overlays/astro/STATUS_RU.md`.
  - `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` (§ A.2.1.D row updates).
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (§ 6 final verdict subsection).
  - `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` (E.6.2 second erratum subsection ONLY if 08 N-N W1 converges).

- new: —

- delete: —

## Do not touch (STRICT)

- **`_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER`** — stays at 730 from TASK 8B; do NOT change.
- **All product semantic code** (`transit_themes.py`, `rulership_houses.py`, `synthesis_themes.py`, `builder.py`, `provenance.py`, `outer_cards.py`).
- **Schema** (`packages/contracts/*.schema.json`) — unless Stage E.3 forces cascade → STOP.
- **`solar.html.j2`** — 0 lines.
- **TASK 8D archived items** (allowlist + facts entries для 01/02/03/04/09) — не менять (Worker's outer-card facts стоят).
- **Pluto display rule** (audit § A.2.1.D rows for 01 P-J, 03 P-Sun, 03 P-Mars) — NOT in scope; future work.
- **Single-window alignment** (audit § A.2.1.D rows for 02 U-P, U-U; 03 N-Mer, N-Mars; 04 U-Sat, U-P) — NOT in scope; future work.
- **Case 03 P-Mars Marina typo** — NOT in scope; data-quality follow-up.
- **Анастасия TYPE-D** (case 09) — NOT in scope; data-revision backlog вне Phase 8.
- **Existing 56 boundary assertions** для 05/10 — не менять; должны остаться bit-identical post-fix.
- **Existing 36 TASK-8D boundary assertions** для 01 Uranus + 03 Uranus/Neptune — не менять; должны остаться bit-identical post-fix.

## Acceptance

### Stage E.1 — Trace

- [ ] Current BEFORE buffer value, location, scope reported в HANDOFF.

### Stage E.2 — Target horizon (systemic)

- [ ] `outer_card_lookbehind_days` named parameter introduced (analogous to TASK 8B `outer_card_lookahead_days`).
- [ ] Default proposal `365.25 * 2 ≈ 730` days with reasoning in HANDOFF.
- [ ] Anti-pattern check: NOT tuned to case-01 W1 starts + 60d.
- [ ] Bloat impact analysis BEFORE committing default.

### Stage E.3 — Schema cascade

- [ ] Confirmed «no cascade» OR STOP + escalation.

### Stage E.4 — Apply extension

- [ ] `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE 540 → 730` (or per E.2 final value).
- [ ] AFTER buffer untouched (stays 730).
- [ ] Minimal one-line change (plus comment doc update if any).

### Stage E.5 — Regression guards

- [ ] **(a) Phase 4b 08 N-N W1 start empirical result reported** (stays -178d OR converges to ±2d).
- [ ] **(b) 01 N-Sun W1 start converges to Marina 17.04.2023 ±2d.**
- [ ] **(b) 01 N-Mars W1 start converges to Marina 12.05.2023 ±2d.**
- [ ] (c) Presentation calendar bit-identical pre/post all cases (Phase 6 clipping filters pre-SR).
- [ ] (c) Raw `annual_transit_table` row count ratio per case reported.
- [ ] (d) Monthly tables bit-identical pre/post all cases.
- [ ] (e) All non-affected boundaries Δ values preserved.
- [ ] (f) Pytest 286/0/0 pre-Stage-E.6.

### Stage E.6 — Test contract updates

- [ ] E.6.1: 12 new boundary points for 01 N-Sun + N-Mars enrolled in `MARINA_OUTER_CARD_BOUNDARIES` with SoT cross-ref.
- [ ] E.6.1: Audit § A.2.1.D table rows for 01 N-Sun + N-Mars marked `[ENROLLED post-Phase-8E]`.
- [ ] E.6.2: 08 N-N W1 start override action documented (stays OR removed based on E.5.a empirical result).
- [ ] E.6.2 if removed: Phase 4a memo second erratum subsection appended.

### Stage E.7 — Reports

- [ ] § 6 final verdict update: «Ready for Marina show — pending user ack» (post-Phase-8E).
- [ ] § A.2.1.D future work item 1 marked `[RESOLVED via TASK 8E]`.
- [ ] STATUS_RU updated.

### Reviewer subagent

- [ ] Reviewer (REQUIRED) spawned; APPROVE received before Worker commits.

### Fixture regen safeguard

- [ ] Per-case justification table в HANDOFF (raw before/after + Δ + why + downstream assertion).
- [ ] Worker walks through prose line-by-line.
- [ ] Reviewer verifies justification.
- [ ] Atomic commit per Bright Line #8.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`:
  - `(286 baseline) + 12 new boundary tests passed + 0 xfailed + 0 failed`. If 08 N-N W1 override removed, tally adjusts.
- [ ] `git status --short` clean for intended changes.
- [ ] Product commit(s) ≤ 3 atomic per Bright Line #8 (engine + fixtures + tests).
- [ ] Overlay commit (STATUS_RU + audit + calibration + erratum if needed + HANDOFF).
- [ ] Push backup; parity verified.

### STOP triggers

- Schema cascade triggered → Tier A escalation, separate TASK.
- 01 N-Sun OR N-Mars W1 starts DO NOT converge to Marina ±2d → horizon margin insufficient OR finding mis-diagnosed.
- 08 N-N W1 start Δ shifts beyond ±2d but NOT to Marina (i.e. wanders into uncharted territory) → unexpected.
- Presentation calendar > 1.5× for any case.
- Monthly tables shift for any case.
- Any non-affected boundary Δ value changes (regression).
- Pluto display rule / single-window / TYPE-D items get touched (scope creep).
- Reviewer escalates.
- AFTER buffer accidentally modified.

## Context

**Mode normal + Tier B** (Haskell engine touch via Python `bridge.py` — same layer as TASK 8B). **Reviewer subagent REQUIRED.** Worker mode: normal.

**Baseline:**
- Product main @ `ce35be1` (TASK 8D submitted to review; pre-buffer finding documented in audit § A.2.1.D; not yet accepted as final).
- Overlay master @ `0114307` (post-TASK-8D submit + this TASK 8E draft will land on top).
- Pytest baseline: `286 passed + 0 xfailed + 0 failed`.
- Cabal build: Up to date.

**TASK 8D lifecycle:** Status «review»; will be accepted in cascade after TASK 8E lands. User direction 2026-05-15: «не закрывать 8D прямо сейчас как final. Reviewer first, then likely 8E».

**Architecture SoT:**
- `transit-section-program-2026-05-13.md` — recovery program SoT.
- `phase-8-audit-report-2026-05-14.md` § A.2.1.D — 14-card exclusion table; TASK 8E targets future work item 1 (pre-buffer extension).
- `transit-multi-case-calibration-report-2026-05-13.md` — § 6 verdict will move to «Ready for Marina show — pending user ack» post-Phase-8E.
- `transit-contact-window-semantics-2026-05-13.md` — Phase 4a memo + Path 1 erratum (TASK 8B); may get second erratum (TASK 8E if N-N W1 converges).

**Phase 8 sequence post-TASK-8E:**
- TASK 8.0 — CLOSED (audit trail reopen).
- TASK 8A+8C — CLOSED (audit + test contract).
- TASK 8B — CLOSED (lexical + AFTER horizon + Path 1 reclassification + unmark).
- TASK 8D — review (closure cascade with 8E).
- **TASK 8E (this)** — BEFORE buffer extension + case 01 enrollment + 08 N-N W1 empirical recheck.
- After 8E closure + 8D cascade closure + user explicit ack on final calibration report → Recovery program closes finally.

**Future work items (out of TASK 8E scope; documented для traceability):**
- Pluto display rule (3 cards in audit § A.2.1.D).
- Single-window alignment helper (6 cards в audit § A.2.1.D).
- Case 03 P-Mars Marina typo (data-quality follow-up).
- Анастасия TYPE-D (data-revision backlog).

**Ready: no** — TL flips after user ack on TASK 8E spec + any refinements.
