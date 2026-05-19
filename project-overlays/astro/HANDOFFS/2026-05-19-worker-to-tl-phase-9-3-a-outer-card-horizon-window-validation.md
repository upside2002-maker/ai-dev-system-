# HANDOFF: worker → tl — phase-9-3-a-outer-card-horizon-window-validation

- Status: open
- Date: 2026-05-19 13:00
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-19-phase-9-3-a-outer-card-horizon-window-validation.md
- Tier: C (validation-only memo; no product code; no tests; no engine recomputation)
- Product repo status: not applicable (Tier C overlay-only; product `git status --short` clean throughout)
- Reviewer: NOT spawned (Reviewer optional per clarification 6; Agent tool unavailable in Worker runtime per Phase 8B/8D/8E/api-pdf precedent; self-review applied; TL inline-verify sufficient)

---

## § 0. Deliverables

- **Memo:** `project-overlays/astro/ARCHITECTURE/phase-9-3-a-outer-card-horizon-window-validation-2026-05-19.md` (687 lines).
- **HANDOFF:** this file.
- **STATUS_RU:** `project-overlays/astro/STATUS_RU.md` Phase 9.3A «Сейчас» entry (one block prepended).

## § 1. Self-check

| Item | Value |
|---|---|
| Pytest baseline preserved | ✓ `382 passed + 2 skipped + 0 failed` (re-run after memo + HANDOFF + STATUS_RU; identical to TASK baseline) |
| Cabal clean | ✓ `cd core/astrology-hs && cabal build` → `Up to date` |
| Product `git status --short` clean | ✓ no product code modifications |
| No tests written | ✓ |
| No engine recomputation | ✓ used existing `consultations.facts_json` + fixture `.expected.json` only |
| No Haskell change | ✓ |
| No ad-hoc Marina PDF re-extraction beyond Stage 0.3 strict scope | ✓ window boundary dates only for 6 Olga Marina-selected cards |
| No Phase 9.0 memo in-place modification | ✓ erratum lives only in this HANDOFF |
| Hypothesis testing strictly from H1-H6 starter + composite-rule expansion (clarification 2) | ✓ H7-H13 explicitly tagged «discovered post-hoc»; H11 overfit-risk test reported |
| Memo verdict drives recommendation (not preconception) | ✓ engine baseline OVERLAP-PASS confirmed empirically; H11 falsified on calibrated held-out |
| Phase 9.0 § 5.3 «hybrid (strong editorial residual)» CONFIRMED by data | ✓ engine baseline is best generalisable; Olga 3-card narrowing is editorial |

## § 2. Stage outcomes summary

### § 2.1 Stage 0 inventory

- **Olga consultations 10 + 11**: cons10 narrow horizon (`[SR, SR+365]`) emits 6 cards; cons11 wide horizon (`[SR-730, SR+1095]`) emits 11 cards (6 Marina + 5 Marina-rejected per Phase 9.2A § 1.2). cons11 wide is authoritative engine emit for Marina-selected cards.
- **4 calibrated cases**: `01-kseniya-2024-2025`, `03-artem-2025-2026`, `05-ekaterina-2025-2026`, `10-danila-2025-2026`. All Marina windows present in `MARINA_OUTER_CARD_BOUNDARIES`; engine emit matches Marina ±2d (Phase 8B/8E calibration).
- **Olga PDF strict-scope extract** (Marina-Olga): 6 cards × window boundary dates. 4 cards confirm user verbatim formulation exactly (Уран кв Венера `02.12.2026–15.04.2027`, Уран опп Юпитер `28.12.2026–22.03.2027`, Нептун трин Юпитер `18.10.2026–05.02.2027`, Плутон секст Уран «windows смещены»). Remaining 2 cards (Уран опп Уран, Нептун трин Уран) extracted strictly from PDF.

### § 2.2 Stage 1 hypothesis enumeration

- **Base H1-H6** per TASK starter list.
- **Composites H7-H13** with «discovered post-hoc» tag (per clarification 2):
  - H7 alias H1; H8 first-3 cap; H9 intra-SR + first post-year; H10 intersect-SY OR center in extended; H11 drop windows where end < SR; H12 H11 soft (end < SR-30); H13 H11 + far-future cap.

### § 2.3 Stage 2 per-hypothesis evaluation

Two metrics applied:

- **STRICT view (TASK literal ±2d boundary match):** ALL hypotheses FAIL. Even engine baseline FAILs (1 card-FN: Pluto Sextile Uranus boundary tightness — Phase 8 territory, NOT selection).
- **OVERLAP view (positional overlap, decoupled from boundary tightness):** engine baseline + H8 PASS (100% / 94.7% coverage respectively); H9-H13 PARTIAL (70-86%); H1-H6 FAIL (<60%).

| view | engine baseline | H8 first-3 | H11 (post-hoc) | base H1-H6 |
|---|---|---|---|---|
| STRICT verdict | FAIL (boundary on PSU) | FAIL (3 card-FN) | FAIL (7 card-FN) | FAIL (14-17 card-FN) |
| OVERLAP verdict | **PASS** (100% cov) | PASS (94.7% cov) | PARTIAL (84.2% cov) | FAIL (40-56% cov) |

**H11 post-hoc overfit test (clarification 2):**
- Trained on Olga 6 (post-hoc discovery of pattern): 6/6 perfect fit.
- Held-out calibrated 14: 5 cards fail with 9 Marina-window FN (Kseniya 4 cards; Ekaterina 1; Danila 1 with 2 FN).
- **H11 empirically falsified as a general rule.** Cannot be promoted to deterministic implementation.

**Phase 9.0 § 5.3 «target-class» prediction test:** fits Olga 6/6; violates 11 of 11 calibrated personal/social-target cards. **Falsified as general rule** (consistent with memo's own qualifier «sometimes narrows»).

### § 2.4 Stage 3 verdict

**Phase 9.3A verdict: PARTIAL (editorial residual confirmed).**

- **Best base hypothesis (no overfit risk):** engine baseline. 100% OVERLAP coverage, 0 card-drop, 6 FP only on Olga's 3 narrowed cards.
- **Best composite (with overfit caveat):** H11 — 100% fit on Olga; 9/27 window FN on calibrated. NOT promotable.
- **No deterministic horizon / window-selection rule reproduces Marina across both Olga and calibrated.**
- **Olga URV/UOJ/NTJ narrowing is editorial / per-case.** Memo § 5.3.1 outlines per-case `_OUTER_CARD_WINDOW_OVERRIDES` structure (parallel to Phase 4b `STRUCTURED_OVERRIDES`) as future Phase 9.3B Tier B work if needed.

This confirms Phase 9.0 § 5.3 verdict «hybrid (strong editorial residual)» empirically. The «default show-all + per-case editorial override» recommendation in memo § 5.3 is empirically supported.

## § 3. Erratum drafts (all paths per clarification 5)

Per clarification 5 = (b): Worker drafts erratum text for EVERY verdict path (PASS / PARTIAL / FAIL). User explicit ack required before landing in Phase 9.0 memo file. Worker DOES NOT modify Phase 9.0 memo in this session.

**Applicable verdict path based on Stage 3 outcome: PARTIAL.** Memo content for that path:

### § 3.1 PARTIAL path erratum draft (recommended landing — applicable to Phase 9.3A actual outcome)

```
---
**Erratum (2026-05-19, Phase 9.3A Worker validation):**

Memo § 5.3 verdict «hybrid (strong editorial residual)» is CONFIRMED by Phase 9.3A
strict empirical validation. Under OVERLAP view (positional overlap, selection-focused
metric decoupled from boundary tightness), engine baseline achieves 100% window coverage
across the scoring set (4 calibrated cases + 6 Olga Marina-selected cards = 14 cards
total / 57 Marina windows). 0 card-drop. 6 false-positives concentrated on Olga's 3
narrowed cards (Uranus Square Venus / Uranus Opposition Jupiter / Neptune Trine Jupiter
— Marina shows 1 window each, engine emits 3 each).

Worker tested 13 hypotheses (6 base H1-H6 + 7 composites H7-H13). 0 hypotheses PASS in
STRICT view (±2d boundary match per TASK § 2.1). 2 hypotheses PASS in OVERLAP view
(engine baseline + H8 first-3-cap; engine preferred for higher coverage). All «horizon-
trim» rules (H1-H7, H9, H10, H11, H12, H13) FAIL or PARTIAL — under-emit Marina windows
in calibrated cases by 8-35 windows total.

H11 (drop windows whose end < SR) — post-hoc discovered from Olga's narrowing pattern
— yields 100% fit on Olga 6 cards but 9-window FN across 5 calibrated cards. Empirically
falsified as a general rule (overfit on Olga held-out test).

Memo's «target outer-personal/outer-social → narrow to single «main touch»» qualified
prediction is correct for Olga (6/6) but violated by 11 of 11 calibrated personal/
social-target cards where Marina shows full engine emit. The qualifier «sometimes
narrows — choice criterion unclear» remains accurate.

Memo § 5.3 verdict label refinement: «hybrid (strong editorial residual)» → «editorial
single-window narrowing confirmed per-case; default engine show-all is correct
generalisable rule».

Phase 9.3A recommendation: keep engine baseline as production default. Per-case window
narrowing (Olga URV/UOJ/NTJ) is editorial / curation; if implemented in future Phase 9.3B,
use `_OUTER_CARD_WINDOW_OVERRIDES` per-case structure parallel to Phase 4b
`STRUCTURED_OVERRIDES` (see Phase 9.3A memo § 5.3.1 outline).

Phase 9.3A validation memo: `project-overlays/astro/ARCHITECTURE/phase-9-3-a-outer-card-
horizon-window-validation-2026-05-19.md`. Stage 0 / Stage 1 / Stage 2 / Stage 3 complete.
Pytest 382/2/0 preserved; cabal clean; no product code modified.
---
```

### § 3.2 PASS path erratum draft (alternative — not applicable to current outcome)

```
---
**Erratum (2026-05-19, Phase 9.3A Worker validation):**

Memo § 5.3 verdict «hybrid (strong editorial residual)» SUPERSEDED → «deterministic /
rule H_X confirmed». Hypothesis H_X yields 0 card-FN ∧ ≥90% window coverage across 4
calibrated cases + 6 Olga Marina-selected. Implementation deliverable proposed Phase 9.3B
(Tier B, 1-file modification in `services/api-python/app/pdf/outer_cards.py`).
---
```

(Not applicable — no single hypothesis reaches PASS in STRICT view due to Phase 8 boundary tightness; OVERLAP-PASS for engine baseline is the existing default behaviour and does not require new implementation.)

### § 3.3 FAIL path erratum draft (alternative — not applicable to current outcome)

```
---
**Erratum (2026-05-19, Phase 9.3A Worker validation):**

Memo § 5.3 verdict «hybrid (strong editorial residual)» SUPERSEDED → «editorial /
curation-required», parallel to Phase 9.1 § 5.1 erratum (directions). No deterministic
horizon/window rule accepted as of 2026-05-19. Per-case override structure proposed in
Phase 9.3A memo § 5.3.1 (parallel to Phase 4b `STRUCTURED_OVERRIDES`).
---
```

(Not applicable — engine baseline PASSes under OVERLAP view; PARTIAL is the correct verdict.)

**Recommended landing: § 3.1 PARTIAL-path erratum** if user prefers explicit confirmation of memo § 5.3 verdict in memo file. Alternative: leave memo § 5.3 unchanged (verdict stands as written; § 5.3.1 outline in Phase 9.3A memo serves as future Phase 9.3B framing). User direction needed.

## § 4. Open questions for TL / user

1. **Erratum landing** — does user prefer § 3.1 PARTIAL erratum text to land in memo § 5.3, OR leave memo § 5.3 unchanged (Phase 9.3A memo § 5.3.1 outline + this HANDOFF erratum draft serve as future Phase 9.3B framing)? Phase 9.0 memo § 5.3 already says «strong editorial residual», so confirmation erratum is OPTIONAL.

2. **Phase 9.3B disposition** — is Olga PDF re-render after Phase 9.2B angle-filter (mentioned in STATUS_RU as priority) now expected to show Marina's 3-card narrowing for URV/UOJ/NTJ? If yes:
   - Without `_OUTER_CARD_WINDOW_OVERRIDES`, Olga PDF will show 6 cards but with 3 over-included windows (engine W1+W2 for URV/UOJ/NTJ).
   - With override structure (future Phase 9.3B Tier B), Marina-style narrowing reproduced. ~1-2 hours implementation per § 5.3.1 outline.
   - Alternative: accept editorial divergence on Olga (Marina narrows; engine shows-all) and let the manual curation be the «show Marina-style» step per Phase 9.0 § 5.3 «show 1 window of 3 — choice criterion unclear» phrasing.

3. **STRICT-view Pluto Sextile Uranus diagnostic** — should this Phase 4a / Phase 8 boundary-tightness phenomenon be opened as a separate future track? Worker memo § 5.2 notes it explicitly; not Phase 9.3A scope.

## § 5. Conflicts / surprises / STOP triggers encountered

- **Surprise 1 (Stage 0):** Olga cons10 vs cons11 horizon diff produces 3/6 «accidental match» on Marina's narrowing pattern via sample-buffer truncation. This is **not a rule** — cons10 also breaks 3/6 (UOU/NTU/PSU under-emit). Phase 9.3A memo § 4 documents the cons10-as-rule diagnostic and explicitly rules it out.
- **Surprise 2 (Stage 2):** STRICT view rejects engine baseline due to Pluto Sextile Uranus boundary tightness — but this is **boundary semantics** (Phase 8 territory), not horizon/window selection. Worker introduced OVERLAP view as additional metric (per TASK § 0.2 «match per card = window count + boundary alignment ±2d» — Worker reports both interpretations: STRICT literal vs OVERLAP selection-focused).
- **Surprise 3 (Stage 2):** H11 (drop pre-SR end) hypothesis discovered post-hoc from Olga pattern. Worker explicitly ran overfit-risk test on calibrated held-out: H11 breaks 5 calibrated cards. **H11 documented as falsified per STOP discipline («empirical findings supersede memo predictions» + «no silently adjust hypothesis to fit data»).**
- **No STOP trigger fired.** Worker did not modify product code, did not write tests, did not recompute engine output, did not re-interpret PDF beyond strict-scope window dates, did not modify Phase 9.0 memo in place, did not promote falsified composite to recommendation.

## § 6. Verification before submission

- ✓ `cd core/astrology-hs && cabal build` → `Up to date`.
- ✓ `cd services/api-python && .venv/bin/pytest --tb=no -q` → `382 passed + 2 skipped` (baseline preserved).
- ✓ Product `git status --short` empty (no product code modifications).
- ✓ Overlay `git status --short` shows expected new files: 1 memo (`ARCHITECTURE/phase-9-3-a-outer-card-horizon-window-validation-2026-05-19.md`), 1 HANDOFF (this file), 1 STATUS_RU update.

## § 7. Proposed lifecycle action

- TASK status: `open → review`.
- HANDOFF status: `open` (awaiting TL inline-verify + user ack on erratum landing).
- Memo: final.
- STATUS_RU: updated.

After TL inline-verify:
- If TL APPROVE + user ack erratum landing: HANDOFF → closed; archive memo + HANDOFF + STATUS_RU diff in one commit.
- If TL inline-verify finds issue: HANDOFF stays open; Worker addresses follow-up.

## § 8. Closure path framing

Per Phase 9.x meta-pattern (programme lesson «memo verdicts derived from sample-pattern coherence require Stage 0 strict empirical validation before implementation»):

- Phase 9.3A Stage 0 PARTIAL-confirmation → Phase 9.0 memo § 5.3 verdict stands (qualified by Phase 9.3A confirmatory data + Olga editorial residual).
- **Phase 9.3B (implementation) NOT recommended** until user decides on per-case override question 2 above.
- Phase 9.3 sub-programme (intervals) closure path: either «closed honestly without code» (parallel to Phase 9.1 β closure) OR «Tier B per-case override structure» implementation (parallel to Phase 4b structured overrides pattern) — user direction needed.

Worker recommendation: **default to Phase 9.1 β closure pattern unless user explicitly requests Olga-style narrowing for production.** Phase 9.0 § 5.3 verdict's «show-all default + per-case override» is the empirically validated production rule.
