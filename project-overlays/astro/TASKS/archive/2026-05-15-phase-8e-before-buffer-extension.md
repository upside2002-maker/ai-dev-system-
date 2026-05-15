# TASK: phase-8e-before-buffer-extension

- Status: done
- Ready: yes
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

**Default proposal:** `outer_card_lookbehind_days = 730` days (~2 solar years).

**Rationale (per user direction 2026-05-15, fixed in spec — do NOT change rationale string):**

> **`730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin`**.

Reasoning:
- NOT symmetry-for-symmetry's sake with TASK 8B AFTER buffer (1096d). The cost-benefit differs: solar return narrative typically looks ahead 3+ years (multi-year outer loops resolve into "third touch this year"), but looks back at most to the «previous touch» of a current loop (rarely > 2 years).
- TASK 8D Reviewer empirical: Marina 01 N-Sun W1 start = SR-582d; N-Mars W1 start = SR-557d. Both within proposed 730d buffer with ~150d / ~173d margin respectively — meets the «>150d margin» criterion exactly.
- 730 is the **minimum extension** to cover confirmed Marina cases; tightens raw-row bloat impact compared to 1096d mirror.

Worker MUST run B2.5.b/E.5.c presentation-calendar bloat check + Reviewer raw-row ratio check against `730d` value FIRST (before committing).

**Anti-pattern (STOP trigger):** if Worker tunes `outer_card_lookbehind_days = max(Marina 01 N-Sun W1 start delta, Marina 01 N-Mars W1 start delta) + 60d` — that's case-01 tuning, NOT systemic policy. STOP, reread E.2.

If `730d` overshoots presentation-calendar bloat threshold for any case → Worker proposes tighter alternative (e.g. `600d` covering Marina 01 N-Sun SR-582d with ~18d margin) with row-count reasoning в HANDOFF. **Going wider** (e.g. 1096d for systemic mirror with AFTER) is **explicitly NOT authorized** without user/TL ack — user direction 2026-05-15 rejected symmetry-for-symmetry argument.

### Stage E.3 — Schema-cascade detection

Verify whether BEFORE buffer change touches `packages/contracts/*.schema.json`:
- Runtime parameter, same JSON output shape → no cascade, Tier B sufficient.
- New schema fields needed → **STOP**, Tier A escalation memo, separate TASK with full schema cascade (Bright Line #8).

### Stage E.4 — Apply BEFORE buffer extension

Change `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540 → 730` (or per E.2 reasoning). Minimal change.

**DO NOT change AFTER buffer** (`_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 730` from TASK 8B stays at 730).

### Stage E.5 — Regression guards (CRITICAL)

All must pass:

**a. Phase 4b 08 N-N W1 start empirical check (KEY DECISION POINT; STOP-gated per user direction 2026-05-15):**

Re-extract 08 N-N W1 start via `outer_cards_for_case` post-fix.

**Three scenarios, AMENDED 2026-05-15 (Worker no longer auto-retracts):**

- **Scenario 1 — Δ stays at -178d ±2d** (TL prediction; most likely): N-N W1 start is true Marina-editorial. Phase 4b ±200d override STAYS. Phase 4a memo erratum stands (only N-J W3 retracted, N-N W1 still editorial per existing memo body). Worker proceeds to Stage E.6 normally (override untouched). **No new erratum.**

- **Scenario 2 — Δ converges to within ±2d of Marina:** N-N W1 was ALSO horizon truncation (would be analogous Path 1 retraction для BEFORE side). **Worker MUST STOP and escalate** — do NOT auto-remove override; do NOT auto-write second erratum subsection. Per user direction 2026-05-15: «08 N-N W1 retract только через TL/user ack. Если вдруг converges, Worker должен STOP и эскалировать, как в 8B. Это уже второй retract Phase 4a memo, нельзя автоматом.» Escalation memo includes:
  - Pre-fix Δ, post-fix Δ, Marina target date, our pre/post engine `orb_enter_jd`.
  - Analogous discipline pattern referenced (TASK 8B Worker B2.1 escalation 2026-05-14).
  - Worker recommends path (likely Path 1' = retract + remove override) but does NOT apply.
  - TL + user ack required before Worker resumes Stage E.6.2 retraction work.

- **Scenario 3 — Δ shifts but neither stays -178d nor converges to ±2d Marina** (e.g. Δ becomes -50d or +50d — wanders into uncharted territory): **STOP, escalation memo.** Unexpected pattern; not horizon truncation by simple reading; possible cusp boundary interaction or other artifact. Do NOT proceed.

TL prediction (pre-Worker): Scenario 1 (Δ stays -178d) — ours at SR-491d is inside even current 540d buffer; engine's orb_enter doesn't depend on buffer being wider. Reviewer 2026-05-14 confirmed this math. Empirical answer expected to match prediction; Scenario 2 would be programmatically significant pivot.

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

**E.6.2 — Phase 4b 08 N-N W1 start override (AMENDED 2026-05-15: STOP-gated, not auto):**

Per amendment 2026-05-15: Worker does NOT auto-decide. Conditional on Stage E.5.a scenario:

- **Scenario 1 (stays -178d, TL prediction):** Override stays. Phase 4a memo unchanged. No test changes for Натальи. Worker proceeds with normal Stage E.6 completion.

- **Scenario 2 (converges to Marina):** Worker STOPped at Stage E.5.a per amendment; Stage E.6.2 is NOT executed by Worker. TL + user ack required (mirror of TASK 8B Path 1 ack process). After user ack on second Phase 4a retraction:
  - Override REMOVED from `test_natalya_transits_acceptance.py`.
  - Phase 4a memo gets second erratum subsection.
  - TASK 8E spec amendment landed (TL inline) before Worker resumes.

- **Scenario 3 (Δ wanders):** Worker STOPped at Stage E.5.a; TL/user determine root cause + path forward.

DO NOT silently keep override if values converged; DO NOT silently remove if values stay divergent. **DO NOT take retraction action without TL/user ack.**

### Stage E.7 — Calibration report + audit updates

- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` § 6: new verdict subsection «Verdict update (post-Phase-8E, 2026-05-15)» — final program closure verdict.
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` § A.2.1.D: 2 case-01 rows marked `[ENROLLED post-Phase-8E]`; future work item 1 (pre-buffer extension) marked `[RESOLVED via TASK 8E]`.
- If E.6.2 retracts: append second erratum to `transit-contact-window-semantics-2026-05-13.md` Phase 4a memo (analogous to first erratum 2026-05-14).
- `project-overlays/astro/STATUS_RU.md` narrative update.

## Reviewer subagent (REQUIRED, narrow-scope per Tier B)

After Stage E.4-E.7 complete (or after Stage E.5.a STOP+escalation if Scenario 2/3), spawn Reviewer subagent (`general-purpose`). Reviewer scope (8 points; AMENDED 2026-05-15 +item 8):

1. Verify `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE 540 → 730` is the only product code change in `bridge.py` (one-line minimal). Rationale string `730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin` present in HANDOFF.
2. Verify AFTER buffer untouched (stays 730 from TASK 8B).
3. Verify 01 N-Sun + N-Mars W1 starts converge to Marina ±2d.
4. Verify 08 N-N W1 start empirical scenario classification (1 / 2 / 3) + appropriate action (override stays / Worker STOPped per amendment).
5. Verify per-case presentation calendar ≤ 1.5×; monthly tables bit-identical.
6. Verify fixture regen justification table per case (per Bright Line #8 + TASK 8B precedent).
7. Independent pytest run.
8. **Verify per-case raw row count ratio before/after** (early-warning, even when presentation unchanged): report `raw_after / raw_before` per case. Threshold not bound by spec (raw growth expected from horizon extension), but ratio is useful early-warning signal — if any case > 1.20× raw ratio, Reviewer flags as informational note (potential systemic over-extension); if > 1.50× raw ratio, ESCALATE.

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

**Closure cascade discipline (AMENDED 2026-05-15):**
- TASK 8D + TASK 8E lifecycle close in single overlay commit (cascade).
- **Marina framing memo NOT mixed with closure commit.** Per user direction 2026-05-15: «framing memo не смешивать с closure commit. После 8D+8E closure отдельным lightweight artifact.» TL prepares framing memo as separate post-closure artifact (lightweight markdown, не overlay-tracked TASK file). User decides when/if to ship to Marina.

**Future work items (out of TASK 8E scope; documented для traceability):**
- Pluto display rule (3 cards in audit § A.2.1.D).
- Single-window alignment helper (6 cards в audit § A.2.1.D).
- Case 03 P-Mars Marina typo (data-quality follow-up).
- Анастасия TYPE-D (data-revision backlog).

**Ready: yes** — flipped 2026-05-15 после user ack + 5 refinements applied:

1. **Lookbehind = 730d** with fixed rationale string «`730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin`». NOT symmetry-for-symmetry with TASK 8B 1096d AFTER.
2. **08 N-N W1 retract — STOP-gated, not auto.** Per user 2026-05-15: Scenario 2 (converges to Marina) triggers Worker STOP + escalation memo; TL+user ack required before retraction; mirror of TASK 8B Path 1 ack process.
3. **Reviewer scope** + item 8: per-case raw row count ratio before/after (early-warning; informational if > 1.20×, escalate if > 1.50×).
4. **Calendar threshold ≤ 1.5×** preserved (presentation rows, post Phase 6 clipping).
5. **Closure cascade discipline:** Marina framing memo NOT mixed with closure commit — separate lightweight post-closure artifact, user decides shipping.

## Closure (2026-05-15, cascade with TASK 8D — Phase 8 program CLOSED)

**TASK 8E + TASK 8D closed in cascade per user explicit ack 2026-05-15.** This is the **final implementation TASK of the Transit Section Recovery program**.

- **Product commit:** `59ec177` (Bright Line #8 atomic: bridge.py + test_multi_case_calibration.py + 18 fixture files).
- **Worker self-review** + **external Reviewer subagent APPROVE** (2026-05-15, narrow 8-point scope):

### Stage results

- **Stage E.1-E.2 trace:** `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540` в `bridge.py:204`. Rationale fixed in spec: «`730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin`».
- **Stage E.3 schema-cascade:** no cascade (runtime parameter, same JSON shape). Tier B sufficient.
- **Stage E.4 apply:** `540 → 730` one-line minimal change. AFTER buffer untouched (stays 730 from TASK 8B). Both lines now equal 730 (symmetric ±730d around SR).
- **Stage E.5.a Scenario 1 confirmed (TL prediction correct):** 08 N-N W1 start stays Δ-178d (true Marina-editorial; our orb_enter at SR-491d is inside buffer; not horizon truncation). Phase 4b ±200d structured override STAYS. Phase 4a memo has ONLY 1 erratum (TASK 8B Path 1). **No second retraction needed.**
- **Stage E.5.b convergence:** 01 N-Sun W1 16.04.2023 (Δ-1d Marina 17.04); 01 N-Mars W1 11.05.2023 (Δ-1d Marina 12.05). Both ±2d.
- **Stage E.5.c-d preservation:** presentation calendar `cal_h` + monthly cells matrix `mat_h` bit-identical pre/post all 9 cases (Phase 6 clipping isolates client PDF to solar year).
- **Stage E.5.e non-affected boundaries preserved:** 92 existing entries unchanged.
- **Stage E.5.f pytest pre-Stage-E.6:** 286/0/0 preserved.
- **Stage E.6.1:** 12 new boundary points enrolled (01 N-Sun + N-Mars × 3 windows × 2 sides) with SoT cross-ref.
- **Stage E.6.2:** N/A (Scenario 1 — no override action needed).
- **Stage E.7:** STATUS_RU + audit § A.2.1.D row updates + calibration § 6 final verdict — all updated.

### Reviewer 8-point APPROVE (2026-05-15)

All 8 items PASS empirical reproduction (case 01 W1 dates re-extracted; case 08 N-N W1 Δ re-verified -178d; cal_h + mat_h bit-identity confirmed on cases 05/08/10; fixture regen justification spot-checked 3 cases — all changes in `[SR-730d, SR-540d)` zone; pytest 298 independent; raw row ratios 1.082×-1.136× reproduced exactly).

### Reviewer informational notes (non-blocking)

1. `analysis` field в fixtures grew (priority_windows, cautions, extended_themes, key_periods entries) — **NOT surface'ит в Marina PDF** (clipped by Phase 3 horizon split в `synthesis_themes.py`). Reviewer verified `themed_synthesis` + `summary_table` bit-identical for spot-checked cases. Optional future work: `synthesis_h` hash в regression guards (no current issue).
2. 7 removed rows per case at exact SR-540d boundary marker — engine semantics of old buffer-boundary marker replaced by new SR-730d marker (not regression).

### User explicit ack — received 2026-05-15

User confirmed cascade closure with final verdict formulation:
> «Recovery program CLOSED — Natalya/05/07/10 production-ready; full-folder supply requires Marina framing and excludes TYPE-D/Pluto-rule future work.»

### Tests + build

- pytest: **298 passed + 0 xfailed + 0 failed** (298 = 85 baseline → 298 across Phase 1-8).
- cabal build: Up to date (no Haskell changes; bridge.py is Python-side parameter).
- Override count: **1** (08 Phase 4b N-N W1 ±200d, confirmed true Marina-editorial; sole survivor).

### Boundary state final

- 104 enrolled boundaries in `MARINA_OUTER_CARD_BOUNDARIES`; 0 OOT.
- 1 structured override in `test_natalya_transits_acceptance.py` (N-N W1 ±200d).
- 12 future-work items documented в audit § A.2.1.D — out of Phase 8 implementation scope.

### Backup parity

- astro main = backup/main = `59ec177` ✓
- overlay master = backup/master (post-cascade commit) ✓

### Status: done

Archive to `project-overlays/astro/TASKS/archive/`. HANDOFF archive to `project-overlays/astro/HANDOFFS/archive/`. **Phase 8 program CLOSED.** Marina framing memo prepared as separate lightweight post-closure artifact (per user direction).
