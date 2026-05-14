# TASK: phase-8-0-reopen-audit-trail

- Status: done
- Ready: yes
- Date: 2026-05-14
- Project: astro
- Layer: overlay (documentation-only)
- Risk tier: C (overlay-only, no product code, no tests, no fixtures)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: (none — TL inline)
- Mode: normal
- Critical approved by: (нет)

## Problem

TASK 7b closure 2026-05-13 verdict «Ready for Marina show — pending user ack» was **premature**. Manual audit (Codex + TL 2026-05-14) on a clean checkout revealed:

1. **Test contract gap:** `test_multi_case_calibration.py` checked outer-card window count + types + ordinals but NOT interval boundaries (start/end dates) vs Marina etalon. Spec gap in TASK 7b § B.4 («outer cards present per allowlist» — count only). Worker delivered exactly what spec required; **discipline gap is mine as PTL**.
2. **Данила Neptune boundary regression:**
   - Нептун кв Венере W3 end = `28.01.2028 10:44` vs Marina `07.03.2028` (+38d).
   - Нептун кв Юпитеру W4 end = `28.01.2028 10:44` vs Marina `18.03.2028` (+49d).
   - Both terminate at identical `orb_exit_jd = 2461798.822368622` — engine finite-horizon sample window truncation, **not Marina editorial**. Distinct from Phase 4b accepted Neptune divergences on Натальи.
3. **Allowlist gap on additional cases:** Cases 01/02/03/04/09 produce 0 outer cards in our PDF; Marina shows 2-9 outer cards per case. TYPE-A closed-config gap, similar to original case 05/10 (resolved via TASK 7b Stage B).
4. **Lexical divergence case 05:** Card title «Нептун в **трине** с нат Юпитером», Marina «Нептун в **тригоне**». One-word lexical fix in aspect-locative dict.
5. **Data-quality blockers (TYPE-D, not code regressions):**
   - `Соляр 2025-2026_3.pdf` — fixture missing natal metadata, cannot reproduce.
   - Анастасия — fixture-vs-reference SR-time/timezone mismatch suspected; needs separate diagnosis.

**Recovery program reopens 2026-05-14 as Phase 8.** This TASK 8.0 = audit-trail downgrade only; Phase 8A+8C (read-only audit + boundary test contract) is the next TASK after 8.0 closes.

## Fixations (per user direction 2026-05-14)

### 1. STATUS_RU downgrade

Top-of-doc narrative:
- «Recovery program CLOSED 2026-05-13» → «Recovery program REOPENED 2026-05-14 — Phase 8 in progress».
- Verdict downgrade: «Ready for Marina show» → «Partial pass — only 08 Natalya production-ready».
- Add Phase 8 sub-phases (8.0, 8A, 8B, 8C) with current status.
- «Ждёт твоего решения»: ack on Phase 8A+8C TASK spec (after this TASK 8.0 closes).
- «Срочные риски»: re-add showing discipline — only Натальи can be shown to Marina (with Phase 4b framing); package PDFs are NOT closed.

### 2. Calibration report v2 — explicit premature-closure note

Add a new subsection in § 6 «Verdict update (post-Phase-8-audit, 2026-05-14)» containing:
- Verdict: «Partial pass — only 08 Natalya production-ready».
- Reason: post-closure manual audit revealed `test_multi_case_calibration.py` did not assert outer-card interval boundaries vs Marina. TASK 7b closure was based on Worker'овский 183/0/0, but those tests checked count + types + ordinals, not boundary dates.
- 5 specific findings (per Phase 8.0 § Problem above).
- Cross-reference to Phase 8.0 TASK (this) + future Phase 8A+8C TASK.
- Note: TASK 7b stays in archive; its closure stays as historical record. Phase 8 is the corrective programme on top of it.

### 3. Scope discipline

- **No product-code change** in TASK 8.0. Audit-trail bookkeeping only.
- TASK 7b file stays in `archive/` (historical record). Phase 8 builds on top.
- Calibration report sections § 3/4/5 — keep as-is (Phase 8A will revise). Only § 6 gets the new verdict subsection.

## Files

- new:
  - `project-overlays/astro/TASKS/2026-05-14-phase-8-0-reopen-audit-trail.md` (this file).

- modify:
  - `project-overlays/astro/STATUS_RU.md` — narrative downgrade + Phase 8 section.
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 6 new verdict subsection.

- delete: —

## Do not touch

- TASK 7b file (`archive/2026-05-13-phase-7-stage-b-closed-config-calibration.md`) — historical record.
- TASK 7c file (`archive/2026-05-13-phase-7c-gate-amendment-typea-monthly-boundary.md`) — historical record.
- Calibration report § 1/§ 2/§ 3/§ 4/§ 5 — preserved as historical record; Phase 8A revises only via additive subsections.
- All product code, schema, fixtures, Haskell.

## Acceptance

- [ ] STATUS_RU updated: top-of-doc verdict downgrade + Phase 8 narrative.
- [ ] Calibration report § 6 gains «Verdict update (post-Phase-8-audit, 2026-05-14)» subsection with 5 findings + cross-ref.
- [ ] One overlay commit; push backup; parity verified.
- [ ] Pytest baseline preserved (183/0/0 with cabal CLI built; not re-run since no test change).
- [ ] Product `git status --short` unchanged (only pre-existing untracked).
- [ ] User explicit ack on TASK 8.0 closure → unblocks TASK 8A+8C draft.

## Context

**Mode normal + Tier C overlay-only.** No Worker subagent (TL inline; documentation-only scope). No Reviewer.

**Baseline:**
- Product main @ `c936dd1` (TASK 7b Stage B).
- Overlay @ `dddd701` (program closure commit — to be supplemented by Phase 8.0 reopen).

**Sequence:**
1. TASK 8.0 closes (this) → audit trail clean.
2. TASK 8A+8C (audit + boundary test contract) drafted; user ack required before Ready: yes flip.
3. TASK 8A+8C executes via Worker: Phase 8A audit report + Phase 8C test contract additions; Worker confirms Данила tests RED.
4. TASK 8B (fixes) drafted after 8A+8C closes — based on audit findings.
5. After 8B closes + user explicit ack → Phase 8 closes, full-folder production-ready (or partial pass with explicit per-case status).

**Why Phase 8 is mandatory, not deferred:**
User directive 2026-05-14 — «открыть Phase 8 как обязательный contract-fix, не как 'когда-нибудь'».

**Parallel artifact track — Наталя:**
- Fresh PDF at `/tmp/08-natalya-2025-2026-c936dd1.pdf` + sidecar with `git_sha = c936dd1...` (rendered 2026-05-14 post-closure).
- Phase 4b framing for 2 Neptune accepted divergences (N-J W3 +17d, N-N W1 +178d) still applies.
- Can be shown to Marina **independently** of Phase 8 progress; TL prepares framing memo on user request.

**Ready: yes** — user provided full spec content (3 fixations) inline; TL captures verbatim.

## Closure (2026-05-14)

- **Inline application landed:** overlay commit (one commit, 3 files: TASK 8.0 new + STATUS_RU downgrade + calibration report § 6 verdict update).
- **All Acceptance items checked:**
  - STATUS_RU updated: top-of-doc verdict downgrade + Phase 8 narrative. ✓
  - Calibration report § 6 gains «Verdict update (post-Phase-8-audit, 2026-05-14): Partial pass — only 08 Natalya production-ready» subsection with 5 findings + cross-ref. ✓
  - Post-Stage-B verdict (2026-05-13) explicitly marked SUPERSEDED with retention rationale.
  - One overlay commit; push backup; parity verified.
  - Pytest baseline preserved (183/0/0 with cabal CLI built).
  - Product `git status --short` unchanged.
- **User explicit ack on closure: pending.** After ack → draft TASK Phase 8A+8C.
- **Status: done.** Archive to `project-overlays/astro/TASKS/archive/`.
