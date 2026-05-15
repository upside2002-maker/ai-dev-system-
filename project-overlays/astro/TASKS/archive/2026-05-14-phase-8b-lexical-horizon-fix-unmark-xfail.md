# TASK: phase-8b-lexical-horizon-fix-unmark-xfail

- Status: done
- Ready: yes
- Date: 2026-05-14
- Project: astro
- Layer: services + core (Haskell engine + Python presentation + tests)
- Risk tier: B (Haskell engine `Domain.TransitCalendar` horizon parameter touch; escalation to Tier A if schema cascade triggered)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 8A audit (audit report § A.4) identified two Phase 8B fixes:

1. **Lexical:** case 05 card 3 title shows «тр Нептун в **трине** с нат Юпитером»; Marina (`Соляр 2025-2026_2.pdf` p. 36) shows «в **тригоне**». One-word fix in `outer_cards.py` aspect-locative dict.

2. **Данила finite-horizon truncation:** case 10 outer-card windows Нептун кв Венере W3 + Нептун кв Юпитеру W4 both terminate at engine `orb_exit_jd = 2461798.822368622 = 28.01.2028 10:44 GMT+3` — engine sample window cutoff. Marina ends:
   - W3 Венере: `07.03.2028` (Δ -39d).
   - W4 Юпитеру: `18.03.2028` (Δ -50d).
   Both currently marked `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon ...")` per Phase 8C contract.

Per user directive 2026-05-14 + audit § A.4 § 3 Worker recommendation: **Path A primary** (engine sample horizon extension); **Path B optional defensive fence** (not first fix).

## Stages

### Stage B1 — Lexical fix (Tier C, ~1 line)

`services/api-python/app/pdf/outer_cards.py` — aspect-locative dict (Russian instrumental case for aspect names). Search for «трине» (Trine→локатив). Replace with «тригоне».

Likely location: aspect-name dict mapping `("Trine", "instr")` or similar. Worker identifies exact location, applies one-word fix.

**Acceptance:** rendered case 05 card 3 title contains «в тригоне с нат Юпитером»; case 10 card titles unchanged (cases 10 has no Trine aspects in allowlist); case 08 Натальи titles unchanged (no Trine).

### Stage B2 — Данила horizon fix (Tier B engine; possibly Tier A if schema cascade)

#### B2.1 — Trace current horizon

Worker locates current sample-window horizon parameter в Haskell `Domain.TransitCalendar` (or wherever outer-planet hits sampling window is bounded). Reports:
- Current horizon value (e.g. «540 days post-solar-return» per recovery program SoT, or different value).
- Where horizon enters the calculation (function signature, module constant, CLI flag default).
- Whether horizon affects only outer-planet hits, or all `annual_transit_table` entries.

#### B2.2 — Determine target horizon (systemic, not Данила-specific)

Worker MUST first locate the **current horizon formula** in the engine code (per B2.1) — likely a constant like `outer_card_lookahead_days` or `sample_window_post_solar_return_days`, or a hardcoded numeric. Report explicitly.

Target: introduce or extend a **named systemic parameter**, NOT pin a number tuned to Данила:

- **Recommended rule:** `horizon_end = solar_return + outer_card_lookahead_days` (named constant, no magic number).
- **Default proposal:** `outer_card_lookahead_days = 365.25 * 3` (3 solar years, ~1095.75 days). Rationale:
  - Covers slow Neptune/Pluto loops with multiple Direct/Retrograde passes.
  - Future-proofs against analogous regressions on cases not yet calibrated (Phase 8A § A.2.1 found Данила; nothing prevents another future case hitting same horizon limit).
  - Marina's typical outer-card windows fit within 3 years post-SR per Phase 8A observations.
- **Bloat impact analysis BEFORE committing default** — Worker runs B2.5.b presentation-calendar bloat check against the proposed `outer_card_lookahead_days` value FIRST.
- If `365.25 * 3` overshoots the threshold for any case → Worker proposes alternative (e.g. `365.25 * 2.5` или `365.25 * 2`) with row-count reasoning в HANDOFF.
- This is a **systemic policy for future slow loops**, not a Данила-specific tuning fence.

**Anti-pattern (STOP trigger):** if Worker is tempted to set `outer_card_lookahead_days = max(Marina W3 end Данила, Marina W4 end Данила) + 60d` — that's tuning to Данила, not systemic. STOP, reread B2.2.

#### B2.3 — Schema-cascade detection

Worker verifies whether horizon extension triggers `packages/contracts/*.schema.json` cascade:
- If horizon is implementation-only (runtime parameter, no new fields/types in JSON output) → no cascade; Tier B sufficient.
- If new schema fields needed (e.g. `truncated: bool` flag) → **STOP**, escalate to Tier A + schema cascade discipline (bright-line #8 atomic commit: schema + Haskell roundtrip + Python contract + TS types + fixtures regen).

#### B2.4 — Apply horizon extension

Worker makes the minimal Haskell change to extend sample window. NO other engine logic touched.

#### B2.5 — Regression guards (CRITICAL)

Worker MUST verify all the following pass post-fix:

**a. Phase 4b Натальи — partial reclassification (AMENDMENT 2026-05-14 Path 1):**

> **Amendment context:** Worker B2.1 trace 2026-05-14 empirically proved that 08 N-J W3 end ≠ Marina-editorial divergence — it was **finite-horizon truncation** (engine `orb_exit_jd = 2461800.5928 = SR + 906d = sample window cutoff`, identical artifact to Данила). Phase 4a memo misclassified this window. 08 N-N W1 start IS still editorial (our `02.04.2024` is at SR-491d, **within** 540d BEFORE-buffer, not at boundary). User/TL ack on reclassification 2026-05-14.

- **08 N-J W3 end** (Marina `16.02.2028`): post-fix engine expected to converge to Marina within **±2 days** (worker empirical preview: `16.02.2028 10:24 UTC` matches Marina `16.02.2028 12:00 MSK = 09:00 UTC` within 1.4 hours).
- **08 N-N W1 start** (Marina `27.09.2024` vs ours `02.04.2024`): Δ **stays -178d** (true Marina-editorial; not truncation; ours -491 is within 540d BEFORE-buffer, not on horizon boundary). Phase 4b ±200d structured override **STAYS**.
- Verified by: rerun audit § A.2.1 boundary extraction.

**b. Presentation calendar does NOT bloat (post-clipping count, not raw):**
- Threshold applies to **rendered PDF calendar rows** — i.e. `transit_aspects_by_month` output AFTER Phase 6 two-window-pair clipping (visible to Marina).
- Raw `annual_transit_table` row count в expected.json **may grow** — that's the point of horizon extension. Not a violation per se (but see fixture-regen safeguard below).
- Presentation calendar post-clipping row count для каждого case (Натальи / 05 / 07 / 08 / 10) ≤ 1.5× pre-fix.
- Worker reports actual ratios в HANDOFF table — **both raw (for context) and presentation-clipped (for threshold check)**.
- If presentation ratio > 1.5× for any case → STOP, escalation memo, tighter `outer_card_lookahead_days` proposal in B2.2.

**c. Non-Данила boundaries preserved, with ONE explicit reclassification (AMENDMENT 2026-05-14 Path 1):**
- Rerun audit § A.2.1 extraction; verify Δ values unchanged for ALL entries EXCEPT:
  - **2 Данила targets** (10 N-V W3 end, 10 N-J W4 end) — must converge to within ±2d.
  - **08 N-J W3 end (Натальи)** — must improve to within ±2d (reclassified as horizon truncation per amendment; Phase 4a memo gets erratum subsection separately).
- All other **53 entries**: Δ unchanged.
- 08 N-N W1 start Δ = -178d **stays** (truly editorial; not on horizon boundary).

**d. Monthly transit tables preserved:**
- Cases 05 (51/52 + 1 TYPE-A Venus Jul 2025 boundary) — preserved.
- Cases 07 (11/13 + 2 TYPE-A Jun/Jul 2026 boundary rows) — preserved.
- Cases 08, 10 — preserved.

**e. Pytest baseline preserved:**
- `(219 baseline) - 2 unmarked + 2 newly-passing` = 219 still passes; 0 xfailed; 0 failed.
- Or expressed differently: 219 collected, 219 passed, 0 xfailed, 0 failed.

### Stage B3 — Unmark Данила xfail + remove N-J W3 override (Tier C, amended scope)

After Stage B2 lands and Stage B2.5 regression guards pass:

**B3.1 — Unmark Данила xfail in `test_multi_case_calibration.py`:**

Remove `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon ...")` from:
- `10-danila-2025-2026 :: Neptune Square Venus :: W3 :: end`.
- `10-danila-2025-2026 :: Neptune Square Jupiter :: W4 :: end`.

Remove associated `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` data structure.

**B3.2 — Remove N-J W3 end ±20d override in `test_natalya_transits_acceptance.py` (AMENDMENT 2026-05-14 Path 1):**

Per amendment: Phase 4b N-J W3 end was misclassified; horizon extension makes engine output match Marina within ±2 days. Override `tolerance_overrides[3]["end"]` (or analogous) for Neptune-Jupiter Square must be **removed**.
- Find current override structure (likely in test method or shared fixture for Neptune-Jupiter Square assertions).
- Remove the W3 end ±20d tolerance entry.
- N-N W1 start ±200d override **STAYS** (untouched — true editorial).
- Any other Phase 4b structured overrides — **DO NOT TOUCH**.

After both unmarks, pytest must report:
- `xpass(strict=True)` does NOT fire on Данила tests (because Worker explicitly removed xfail markers).
- `xpass(strict=True)` does NOT fire on N-J W3 (because Worker explicitly removed override).
- N-N W1 start ±200d override fires as before (still required).
- Final: `221 passed + 0 xfailed + 0 failed` (or equivalent — depends on collection style).

**STOP triggers:**
- If Данила boundary tests still fail post-unmark → horizon extension didn't reach Marina dates → revert + escalation (need wider margin or Path B fallback).
- If 08 N-J W3 end still fails post-override-removal → horizon extension undershot for Натальи — investigate; may need wider `outer_card_lookahead_days`.
- If 08 N-N W1 start fails (unexpected) → BEFORE buffer also extended somehow (shouldn't be per spec) — STOP, revert any unintended BEFORE buffer change.

### Stage B4 — Optional Path B defensive fence (deferred)

**NOT in this TASK by default.** User directive: Path B as «optional guardrail, not first fix».

Future TASK 8B-2 (or extension of this TASK if scope permits): add presentation-layer marker for windows whose `orb_exit_jd` reaches the new extended horizon. Detect cases that still exceed extended horizon → render «(окно truncated)» marker. This catches edge cases where Path A's new horizon is insufficient.

If Worker has time/scope, may propose this as optional add-on в HANDOFF for user to ack separately. Don't apply unilaterally.

## Files

- modify:
  - `core/astrology-hs/src/Domain/TransitCalendar.hs` (or wherever horizon parameter lives) — extend sample window.
  - `services/api-python/app/pdf/outer_cards.py` — lexical «трине → тригоне» в aspect-locative dict.
  - `services/api-python/tests/test_multi_case_calibration.py` — remove 2 Данила xfail markers + associated structures.
  - `packages/test-fixtures/golden-cases/*.expected.json` — **possibly** if Haskell output for sample window changes; Worker assesses.
  - `project-overlays/astro/STATUS_RU.md` — narrative for Phase 8B closure.
  - `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — update § A.4 item 3 status to [RESOLVED via TASK 8B] + § A.2.1 table re-extracted post-fix (or new appendix with post-fix table).
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 4 TYPE-B-equivalent item 8 [RESOLVED via TASK 8B].

- new: —

- delete: —

## Do not touch

- Schema `packages/contracts/*.schema.json` — UNLESS horizon extension forces it. If schema cascade triggers → STOP, escalation memo, separate Tier A TASK.
- Phase 4b Натальи `test_natalya_transits_acceptance.py` (AMENDMENT 2026-05-14 Path 1):
  - **N-J W3 end ±20d override:** **MUST BE REMOVED** in Stage B3.2 — reclassified as horizon truncation; horizon extension makes engine output converge to Marina within ±2d.
  - **N-N W1 start ±200d override:** **STAYS UNCHANGED** — true Marina-editorial divergence (our start at SR-491d is within 540d BEFORE buffer, not on boundary).
  - **All other Phase 4b structured overrides:** DO NOT TOUCH.
- Cases 07 Мария TYPE-A boundary rows (Jun/Jul 2026) — anchor-day convention, separate concern.
- Cases 05 Venus Jul 2025 TYPE-A monthly cell — separate concern.
- TASK 7b / 7c / 8.0 / 8A+8C archived files — historical records.
- Allowlist для 01/02/03/04/09 — separate TASK 8D scope.
- `_3.pdf` / Анастасия — TYPE-D, separate data-revision backlog.

## Acceptance

### Stage B1 — Lexical

- [ ] Rendered case 05 card 3 title: «тр Нептун в **тригоне** с нат Юпитером» (or grammatically appropriate Russian instrumental form).
- [ ] No other case titles affected.
- [ ] No other lexical regression.

### Stage B2 — Horizon fix (amended)

- [ ] Stage B2.1: current horizon traced + reported в HANDOFF (value, **language [Python or Haskell]**, location, scope). **Note: TASK initially assumed Haskell; Worker B2.1 trace 2026-05-14 found parameter in Python `bridge.py` — that's correct; spec amendment confirms.**
- [ ] Stage B2.2: target horizon = `outer_card_lookahead_days` named parameter; default proposal `365.25 * 3 ≈ 1096` days; bloat impact analysis BEFORE commit; reasoning in HANDOFF.
- [ ] Stage B2.3: schema-cascade check — confirmed «no cascade» OR STOP+escalation.
- [ ] Stage B2.4: horizon extension applied — minimal change (Python `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER` adjustment OR named-parameter introduction per B2.2). BEFORE buffer **NOT changed** (only AFTER).
- [ ] Stage B2.5 regression guards (ALL must pass; AMENDMENT 2026-05-14 Path 1):
  - [ ] (a) **08 N-J W3 end converges to within ±2d of Marina `16.02.2028`** (reclassified as horizon truncation per amendment).
  - [ ] (a) **08 N-N W1 start Δ stays -178d** (true editorial; not on horizon boundary; BEFORE buffer not extended).
  - [ ] (b) Presentation calendar (post-clipping) row count ratio post/pre ≤ 1.5× для каждого case. Report both raw + presentation ratios.
  - [ ] (c) All 53 OTHER non-Данила boundary entries retain pre-fix Δ values (08 N-J W3 end is the only intended reclassification).
  - [ ] (d) Monthly tables 05 / 07 / 08 / 10 unchanged. **STOP if any change** (per user direction 2026-05-14).
  - [ ] (e) Pytest `219 passed + 2 xfailed + 0 failed` baseline preserved pre-unmark (Натальи N-J W3 ±20d override still active при этой проверке — он removed только в Stage B3.2).

### Stage B3 — Unmark + remove override (amended)

- [ ] **B3.1:** 2 `@pytest.mark.xfail(strict=True, ...)` markers removed for Данила W3 end (Венере) + W4 end (Юпитеру).
- [ ] **B3.1:** `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` (or analogous structure) removed.
- [ ] **B3.2:** Phase 4b N-J W3 end ±20d override removed from `test_natalya_transits_acceptance.py` (per amendment 2026-05-14 Path 1).
- [ ] **B3.2:** N-N W1 start ±200d override **untouched**.
- [ ] **B3.2:** All other Phase 4b structured overrides untouched.
- [ ] Pytest post-unmark: `221 passed + 0 xfailed + 0 failed` (or equivalent — depends on collection style).
- [ ] CI green.

### Common

- [ ] `cabal --project-dir core/astrology-hs build`: clean.
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q`: green per Stage B3.
- [ ] `git status --short` clean for intended product changes; pre-existing `.claude/scheduled_tasks.lock` allowed.
- [ ] Product commit(s): structured ≤ 3 (Haskell engine + Python lexical/xfail unmark + fixture regen if needed). Worker justifies split in HANDOFF.
- [ ] Overlay commit: STATUS_RU + audit report + calibration report + HANDOFF.
- [ ] Push backup, parity verified.

### Tier B discipline

- [ ] If schema cascade triggers → STOP, escalation, **Tier A separate TASK**.
- [ ] If fixture regen needed → atomic commit (Bright Line #8): regen + Haskell roundtrip test + Python contract test + TS types if any. **See § Fixture regen safeguard below — per-case justification table в HANDOFF обязательна.**
- [ ] **Reviewer subagent REQUIRED for Stage B2** (Haskell engine touch). Reviewer reviews horizon parameter change + regression guard evidence + fixture diff before Worker commits. TL inline-verify on top of Reviewer's report.

### Fixture regen safeguard (CRITICAL — no silent regen)

If `cabal build` post-horizon-change produces different `annual_transit_table` content в golden fixtures (`packages/test-fixtures/golden-cases/*.expected.json`):

- [ ] Worker **does NOT silently overwrite** all expected.json files. Each per-case regen requires explicit justification.
- [ ] HANDOFF includes a **per-case justification table**, one row per affected case:

  | case | raw row count before | raw row count after | Δ rows | why changed | downstream assertion proving intended |
  |------|----------------------|---------------------|--------|-------------|----------------------------------------|

  - "why changed" — must reference the horizon extension (e.g. «horizon extended from N to M days → 7 new outer-planet hits in extended window»). Anything beyond «horizon extended» = semantic shift → STOP.
  - "downstream assertion" — concrete test name or audit-report-section that verifies the change is intended (e.g. `test_multi_case_calibration.py :: test_outer_card_window_boundary :: 10-danila Neptune Square Venus W3 end`).

- [ ] Worker walks through table line-by-line in HANDOFF prose; не «таблица без комментария».
- [ ] If any "why changed" cannot be tied to horizon extension → STOP, escalation memo (means semantic shift beyond horizon scope).
- [ ] Reviewer subagent independently verifies justification table before Worker commits.
- [ ] Atomic commit per Bright Line #8: Haskell engine + (schema cascade if triggered, else not) + fixtures regen + Haskell roundtrip test + Python contract test + TS types if any — **all in one product commit**, with per-case justification table in commit message.

### Scope discipline

- [ ] Затронуты: Haskell horizon parameter, `outer_cards.py` aspect-locative, `test_multi_case_calibration.py` xfail unmark, overlay docs.
- [ ] **NOT затронуты:** allowlist 01-09; TYPE-D blockers; Phase 4b Натальи overrides; case 07 TYPE-A monthly rows; case 05 Venus Jul 2025 boundary.
- [ ] No new override mechanisms; no accepted-divergence reclassification.

## Context

**Mode normal + Tier B** (Haskell engine touch + Python presentation + tests). **Reviewer subagent REQUIRED for Stage B2 Haskell change.** Worker mode: normal.

**Baseline:**
- Product main @ `9740075` (TASK 8A+8C accepted).
- Overlay @ `c7df283` (TASK 8A+8C archived + Phase 8B drafted on top).
- Pytest baseline: `219 passed, 2 xfailed (Данила Венере W3 end + Юпитеру W4 end), 0 failed`.
- Cabal build: Up to date.

**Architecture SoT:**
- `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` (recovery program).
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (§ 6 has Phase 8 verdict).
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` (audit + Phase 8B proposals; § A.2.1 SoT).

**STOP triggers (do not commit + escalate; AMENDED 2026-05-14 Path 1):**
- Schema cascade triggered by horizon extension (Tier A territory).
- **08 N-N W1 start Δ shifts from -178d** post-fix (means BEFORE buffer was unintentionally extended; only AFTER should change).
- **08 N-J W3 end Δ does NOT converge to ±2d** of Marina (means horizon margin too tight; need larger `outer_card_lookahead_days`).
- Presentation calendar row count bloats > 1.5× for any case.
- Any non-Данила, non-N-J-W3-end boundary Δ values change (regression — only 1 reclassification authorized).
- **Monthly tables for 05 / 07 / 08 / 10 change** (per user direction 2026-05-14).
- Calendar clipping output for 05 / 07 / 08 / 10 changes (other than the planned outer-card-window expansions).
- Данила tests still fail after Stage B3 unmark (horizon insufficient → wider margin or Path B fallback; don't re-add xfail).
- 08 N-J W3 end test fails after Stage B3.2 override removal (override removal premature).
- Worker tempted to fix anything beyond scope (allowlist 01-09, TYPE-D, other Phase 4b overrides).
- Lexical fix breaks other case titles.
- Fixture regen justification cannot tie all changes to horizon extension scope.
- Reviewer subagent escalates.

**Phase 8B sequence:**
- Stage B1 (lexical) first — quick warmup, low risk.
- Stage B2 (horizon) main work — careful regression guards.
- Stage B3 (unmark xfail) — depends on B2 passing.
- Stage B4 (Path B fence) deferred — optional separate ack required.

**After TASK 8B closes + user explicit ack:** draft TASK 8D (allowlist expansion 01/02/03/04/09 per audit § A.4 item 4). Phase 8 implementation programme = 8B + 8D. TYPE-D остаётся отдельным data-revision backlog вне Phase 8.

**Parallel artifact track — Наталя:** unaffected by 8B (Phase 4b Натальи overrides preserved per regression guard B2.5.a). Marina show готовность не меняется.

**Ready: yes** — flipped 2026-05-14 после user ack + 4 refinements applied + AMENDMENT 2026-05-14 Path 1.

### Amendment 2026-05-14 Path 1 (post-Worker-B2.1-escalation)

Worker B2.1 trace empirically showed: Phase 4b N-J W3 end -17d = horizon truncation, not editorial. User ack 2026-05-14:
1. Systemic horizon: `outer_card_lookahead_days = 365.25 * 3 ≈ 1096` days (AFTER buffer only; BEFORE buffer untouched).
2. Phase 4a memo erratum subsection added (not memo rewrite).
3. N-J W3 ±20d override REMOVED in Stage B3.2 (engine post-fix matches Marina ±2d).
4. N-N W1 ±200d override STAYS (true editorial: ours at SR-491d, within 540d BEFORE buffer).
5. Fixture regen with per-case justification table (refinement 4 still applies).
6. B2.5.a expectations changed: «N-J W3 to ±2d (improve); N-N W1 stays -178d».
7. Only ONE reclassification authorized — all other Δ values stay.
8. Monthly tables + presentation calendar clipping for 05/07/08/10 must stay unchanged.

Spec amendments above sections § Stage B2.5.a, § Stage B3.1+B3.2, § Do not touch, § Acceptance Stage B2+B3, § STOP triggers — all updated 2026-05-14.

1. **Horizon margin (B2.2):** не tuning под Данилу. Worker first traces current horizon formula, then introduces systemic named parameter `outer_card_lookahead_days` (default proposal `365.25 * 3` = 3 solar years). Bloat impact analysis BEFORE committing default. Anti-pattern STOP trigger: «pin to Marina Данила boundaries +60d» = scope-tuning, not systemic.

2. **Calendar bloat (B2.5.b):** threshold ≤ 1.5× considers **presentation calendar rows after Phase 6 clipping**, NOT raw `annual_transit_table` count. Raw expected may grow (that's the point). Worker reports both ratios в HANDOFF — raw for context, presentation for threshold check.

3. **Reviewer required (Tier B discipline):** Reviewer subagent **REQUIRED for Stage B2** (Haskell engine touch). Reviews horizon parameter change + regression guard evidence + fixture diff before Worker commits.

4. **Fixture regen safeguard:** explicit § «Fixture regen safeguard» added — no silent regen. HANDOFF must contain per-case justification table (raw row count before/after + Δ + why + downstream assertion). Worker walks through prose. Reviewer verifies independently. Atomic commit per Bright Line #8.

## Closure (2026-05-14)

**Worker delivered Path 1 fully + Reviewer subagent APPROVE + user explicit ack 2026-05-14.**

- **Product commit:** `f667a10` (Bright Line #8 atomic) — `feat(transit-engine): Phase 8B horizon extension + Path 1 reclassification`.
- **Overlay commits:** `75945fe` (closure: STATUS_RU + audit § A.2.1 post-fix + calibration § 4 item 8 [RESOLVED] + HANDOFF) + `b4c3fb2` (TASK status bump).
- **Stages executed:**
  - B1 (lexical): «трине → тригоне» в `outer_cards.py` aspect-locative dict + sync `test_multi_case_calibration.py`.
  - B2 (horizon): `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER 540 → 730` в `bridge.py:205`. BEFORE buffer untouched. Sample window SR + 906d → SR + 1096d per systemic `outer_card_lookahead_days = 365.25 * 3` policy. 9 cases × 2 files = 18 fixture files regen'd.
  - B3.1: 2 Данила xfail markers + `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` removed.
  - B3.2: Phase 4b N-J W3 end ±20d override removed (per amendment). N-N W1 start ±200d override stays (true editorial).
- **Boundary table post-fix:** 27 of 28 windows match Marina ±2d; 1 OUT (08 N-N W1 start -178d, true editorial — structured override preserves passing test).
- **Pytest:** **221 passed + 0 xfailed + 0 failed** (TL independent run with cabal on PATH; Reviewer independent run).
- **Cabal:** Up to date.
- **Backup parity:** astro main = backup/main = `f667a10` ✓; overlay master = backup/master = `b4c3fb2` ✓.

### Reviewer subagent APPROVE (2026-05-14, narrowed scope per user)

All 5 verification items PASS via independent empirical reproduction:

1. **Horizon parameter explains 3 convergences** — SR + 906d → SR + 1096d deterministic; Натальи N-J W3 end matches Marina ±1.4h post-fix; Данила N-V W3 + N-J W4 ends match Marina ±0d post-fix.
2. **BEFORE buffer untouched + N-N W1 stays editorial** — `bridge.py:216 BEFORE = 540` unchanged; N-N W1 start at SR-493d (within 540d buffer, not on boundary); ±200d override preserved.
3. **Fixture regen + thresholds** — all 9 cases raw ratio 1.089-1.152× (under presentation 1.5× spec threshold); diffs only in outer-planet hits, no semantic shift.
4. **Only necessary xfail/override removed** — 2 Данила xfail + N-J W3 override removed; N-N W1 override + all other Phase 4b overrides untouched.
5. **Pytest 221/0/0** — Reviewer independent reproduction `221 passed in 25.66s`.

**Reviewer verdict: APPROVE.**

### Reviewer informational notes (non-blocking accuracy nits)

1. **Case 01 raw fixture ratio = 1.152×** (HANDOFF округлил «≤ 1.15×»). Spec § B2.5.b threshold = 1.5× presentation rows; raw not bound by spec — это HANDOFF wording precision, не нарушение.
2. **18 fixture files** changed in commit (9 cases × 2 files each: `*.input.json` + `*.expected.json`); HANDOFF wording «9 fixtures regen'd» counts cases, not files. Audit trail accurate via commit diff.
3. **Lexical sites:** HANDOFF mentions 3 (lines 162, 193, 458) в `outer_cards.py`; фактически 2 (line 458 уже содержал «тригоне» в Marina-reference комменте pre-fix). Minor wording precision.
4. **Self-reviewer disclosure honest** — Worker зафиксировал runtime limitation; Reviewer (third pass) закрыл дыру дисциплины.
5. **Cross-refs verified:** Phase 4a erratum + calibration § 4 item 8 [RESOLVED] + audit § A.2.1.post — все совпадают.

Notes recorded для audit trail accuracy; ни одна не блокирует closure.

### User explicit ack — received 2026-05-14

User confirmed closure: «Reviewer закрывает главный риск. Ниты не блокируют, но в Closure section я бы коротко отметил их как 'Reviewer informational notes', особенно `case 01 raw ratio 1.152×` и '18 fixture files, 9 fixtures'».

### Status: done

Archive to `project-overlays/astro/TASKS/archive/`. HANDOFF archive to `project-overlays/astro/HANDOFFS/archive/`. TASK 8D drafted next (allowlist 01/02/03/04/09).
