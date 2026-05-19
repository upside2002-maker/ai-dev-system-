# TASK: phase-9-2-a-outer-cards-filter-validation

- Status: in-progress
- Ready: yes
- Date: 2026-05-18
- Project: astro
- Layer: overlay (analytical/empirical validation memo only — NO product code, NO tests, NO PDF changes)
- Risk tier: C (validation-only; gate before implementation)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 9.0 memo § 5.2 verdict: outer cards sub-problem = `hybrid`. Rule «target ∉ {Asc, MC, IC, DC} (angles); target ∈ per-client significator set» fits 10/10 cases per memo § 3.2.

**However** — Phase 9.x meta-lesson (recorded в Phase 9.4 memo erratum 2026-05-18):

> All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation. This is confirmed by Phase 9.1 directions and Phase 9.4 summary findings.

Phase 9.1 STOP showed memo § 5.1 «hybrid/deterministic-leaning» was overstated empirically. Phase 9.4 STOP→β showed memo § 5.4 «deterministic 8/8» was overstated for 2 cases (tie-break + super-solar fallback). **Memo § 5.2 verdict 10/10 must be empirically re-verified before any implementation TASK ships.**

This TASK is **validation-only, gate before implementation**. Per user direction 2026-05-18:

> 9.2 не запускать как implementation сразу. Сначала re-spec с обязательным Stage 0 strict validation: применить `target ∉ angles` ко всем 10 cases и доказать, что он не drop'ает Marina-selected cards и не оставляет критичных false positives. Только после Stage 0 PASS можно implementation.

## Worker framing (verbatim user direction 2026-05-18)

> **Stage 0 mandatory. Проверить `target ∉ angles` на всех 10 cases. Доказать no Marina-selected drops. Зафиксировать false positives / false negatives. Только если Stage 0 PASS — implementation proposal. Если Stage 0 FAIL — memo/erratum, no code changes.**

## Scope (Tier C validation-only)

### Stage 0 — Empirical validation per case

Per case (10 cases: 01 / 02 / 03 / 04 / 05 / 07 / 08 / 09 / 10 / 11-olga):

1. **Load engine outer-card emit set** для case (engine pre-filter generic output):
   - Calibrated cases (01-10): allowlist + `_OUTER_CARD_FACTS` represents Marina-curated set (engine emit before filter == Marina selection by Phase 4/7b/8D design).
   - Non-calibrated (11-olga): `generic_outer_cards(facts)` output (~13 cards per Phase 9.0 memo § 0).

2. **Apply hypothetical `target ∉ {Asc, MC, IC, DC}` filter** to engine emit set.

3. **Compare filter output к Marina-curated selection** (per memo § 1.1 / § 1.2):
   - **False negatives:** Marina-selected cards filter DROPS (Marina has angle-target card но filter removes).
   - **False positives:** filter keeps cards NOT в Marina-selected set.
   - **True positives:** Marina-selected cards filter keeps (correct).
   - **True negatives:** non-Marina cards filter correctly drops.

4. **Compute per-case match rate:**
   - 10/10 → memo verdict confirmed; implementation TASK 9.2B can proceed.
   - <10/10 → memo verdict overstated; STOP+escalation; document as memo § 5.2 erratum analogous Phase 9.1/9.4 pattern.

### Stage 0 output

Worker produces **validation memo** в `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md`:

- **§ 1 Per-case empirical table:**
  - Columns: case_id / engine emit count / Marina-selected count / filter `target ∉ angles` output count / FP count / FN count / FP list / FN list / verdict (match / over-include / drop).
  
- **§ 2 Aggregate score:** Stage 0 PASS если 10/10 cases match Marina without false negatives. Filter MAY over-include (false positives = «engine emits more than Marina; filter doesn't enforce Marina significator subset») — this is acceptable if filter's role is «remove invalid angle-targets», not «enforce full Marina significator subset».

- **§ 3 Significator hypothesis additional check (DIAGNOSTIC ONLY, NOT a gate per user direction 2026-05-18):**

  > «Significator supplement оставить как secondary check. Но это не должен быть gate для implementation. Gate только: `target ∉ angles` не drop'ает Marina-selected cards. Significator-гипотеза пусть будет диагностикой false positives, не основанием молча усложнять фильтр.»

  Worker tests significator-supplement как **secondary diagnostic** (NOT as gate criterion):
  - Compute significator set per case (Asc-ruler, MC-ruler, 1st-house planets, Sun-sign ruler, stellium-ruler) per memo § 6 TASK 2 proposal.
  - Apply hypothetical both-rules combination: `target ∉ angles` AND `target ∈ significator-set OR target ∈ outers (U/N/P)`.
  - Compute per-case match rate.
  - Output is **informational** для understanding false-positive structure. **DO NOT use this as gate** для implementation proposal. Gate is angle-exclusion alone.

- **§ 4 Verdict (AMENDED 2026-05-18 per user direction — gate is angle-exclusion alone):**
  - **PASS** — `target ∉ angles` filter yields 10/10 без false negatives для Marina-selected cards. Recommend Phase 9.2B implementation TASK с angle-only scope (significator-supplement deferred OR documented as informational only).
  - **FAIL** — `target ∉ angles` drops Marina-selected cards в M cases. STOP, Worker drafts memo § 5.2 erratum text в HANDOFF (NOT lands erratum в memo himself per user direction 5; TL/user ack formulation first, then separate overlay commit). NO implementation TASK ships.

  Note: значительный significator-supplement false-positive count is **informational** в § 3, не gate condition. Even если significator-supplement reduces false-positive count, gate decision уже locked by § 4 angle-exclusion result.

- **§ 5 Recommended next step (AMENDED 2026-05-18 per user direction 5):**
  - If **PASS** → Worker writes validation memo (§ 1-4 above) + Phase 9.2B implementation TASK draft outline. NO implementation в этом TASK; that's 9.2B.
  - If **FAIL** → Worker writes validation memo (§ 1-4 above) + **erratum draft text в HANDOFF** (NOT lands erratum в memo himself). TL/user ack erratum formulation first, then separate overlay commit lands erratum into Phase 9.0 memo. NO implementation proposal. NO code changes.

### Stage 0 acceptance

- [ ] Memo file `phase-9-2-a-outer-cards-validation-2026-05-18.md` created.
- [ ] § 1 per-case empirical table for 10 cases.
- [ ] § 2 aggregate score (PASS / PARTIAL / FAIL).
- [ ] § 3 significator-hypothesis check.
- [ ] § 4 verdict с explicit Stage 0 outcome (PASS / FAIL only; significator-supplement informational).
- [ ] § 5 next step recommendation (implementation proposal if PASS, OR erratum draft text in HANDOFF if FAIL — NOT landed in memo by Worker).
- [ ] If FAIL: erratum draft text **в HANDOFF** for TL/user ack; **Worker does NOT land erratum в Phase 9.0 memo** (per user direction 5 — TL/user must ack formulation first, separate overlay commit lands erratum).

### Stage 0 stop discipline (AMENDED 2026-05-18 per user direction)

**If `target ∉ angles` filter DROPS any Marina-selected card в any of 10 cases (GATE):**
- **STOP** Stage 0 main verdict path.
- Document false-negative case в memo § 1 + § 4.
- Verdict = **FAIL**.
- Worker may STILL complete § 3 significator-diagnostic для informational value (does NOT change FAIL verdict; merely diagnoses false-positive structure).
- No implementation TASK 9.2B drafted.
- Worker drafts memo § 5.2 erratum text **в HANDOFF** (NOT lands в memo himself). TL/user ack first.

**If significator-set supplement reduces false-positive count (informational only):**
- Record в § 3 as diagnostic.
- **Does NOT change § 4 verdict** (gate is angle-exclusion alone per user direction).

**If angle-exclusion yields 10/10 без false negatives:**
- Verdict = **PASS**.
- Recommend Phase 9.2B implementation TASK с angle-only scope (significator-supplement deferred OR documented as informational only).

## Files

- new:
  - `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md` (validation memo).

- modify:
  - `project-overlays/astro/STATUS_RU.md`.
  - `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` (only if Stage 0 FAIL: add § 5.2 erratum analogous Phase 9.1 / 9.4 patterns).

- delete: —

- **NO product code modifications:** zero changes к `services/api-python/app/*` or `core/astrology-hs/*`.

## Strict prohibitions

- DO NOT touch product code.
- DO NOT add entries к `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS`.
- DO NOT modify `generic_outer_cards()` или any filter logic.
- DO NOT modify tests (Phase 9.4 tests stable).
- DO NOT modify engine, schema, fixtures, PDFs.
- DO NOT propose «improve» filter logic to make 10/10 if empirical reality < 10/10.
- DO NOT silently «adjust» significator-set definition to make scores match — Phase 9.1 lesson.

## STOP triggers

- Filter drops Marina-selected card в any case → STOP at FAIL verdict; no implementation proposal.
- Stage 0 finds memo § 1.1 Marina-selection inventory data missing / ambiguous for any case → Worker reports gap; do NOT extract from Marina PDFs ad-hoc (per user direction 2026-05-18 «не добывать заново из PDF»).
- Worker tempted to ship implementation TASK 9.2B prematurely без Stage 0 PASS → STOP, validation-only scope.

## Reviewer subagent — OPTIONAL

Tier C validation-only memo, analogous Phase 9.0 memo TASK. Reviewer not required; TL inline-verify acceptable.

## Context

**Mode normal + Tier C validation-only.** Worker mode: analytical-thinking-heavy, similar Phase 9.0 memo or Phase 9.1 Stage 0 attempt.

**Baseline:**
- Product main @ `941b78f` (Phase 9.4 β tests landed; zero code modifications beyond test file).
- Overlay master @ `3df1eec` (Phase 9.4 closure cascade).
- Pytest baseline: `372 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Phase 9.0 memo § 5.2 verdict «hybrid» + memo § 6 TASK 2 proposal: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Phase 9.1 erratum precedent (memo § 5.1 superseded): same memo file.
- Phase 9.4 erratum precedent (memo § 5.4 superseded): same memo file.
- Programme lesson (validation-first discipline): same memo, Phase 9.4 erratum.

**Not in scope (explicit):**
- Implementation work — that's Phase 9.2B if Stage 0 PASSes.
- Phase 9.3 (intervals) — deferred until 9.2A / 9.2B settled.
- Engine changes, schema cascade.
- Marina PDF re-extraction (use memo § 1.1 / § 1.2 inventory).

**Sequencing:**
- This (9.2A) — validation-only.
- 9.2B — implementation TASK, drafted ONLY if 9.2A PASSes.
- 9.3 — deferred.

**Ready: yes** — flipped 2026-05-18 after user ack + 5 clarifications:

1. **Spec clean** — no new requirements.
2. **Memo path** `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md` confirmed.
3. **Significator-supplement** = diagnostic-only (NOT gate). Gate is `target ∉ angles` no-Marina-drop. Significator informational для understanding false-positive structure; не reason to silently complicate filter.
4. **Reviewer optional** confirmed (TL inline-verify acceptable).
5. **Erratum pattern (CRITICAL):** if Stage 0 FAIL → Worker drafts erratum text **в HANDOFF** для TL/user ack first. Worker **does NOT land erratum в Phase 9.0 memo** himself. Separate overlay commit lands erratum after ack.
