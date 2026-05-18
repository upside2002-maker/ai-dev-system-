# TASK: phase-9-4-summary-axis-regression-tests

- Status: open
- Ready: no
- Date: 2026-05-17
- Project: astro
- Layer: services (Python tests only — NO product code changes)
- Risk tier: C (tests-only; no schema; no engine; no template; no allowlist)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 9.0 memo § 5.4 verdict: **summary themes sub-problem = `deterministic`**. Engine post-`transit-section-generic-output` (commit `aca694b` 2026-05-16) axis-density via cusp-count uже matches Marina **8/8 cases** (Ольга consultation 11: «ось 5-11, подсчёт 4 из 12» = Marina's verbatim primary theme; calibrated cases similarly).

User prediction 2026-05-17 was «summary почти точно editorial» — Worker findings inverted: **engine already implements correctly**. Surprise win.

Per user direction 2026-05-17 (Phase 9.4 priority decision):
> «После урока 9.1 я бы не прыгал прямо в карточки. Даже если `target ∉ angles` fits 10/10, надо сначала зафиксировать маленький deterministic win. Следующим сделать 9.4 — Summary regression tests. Это low-risk, tests-only, и Worker уже нашёл, что summary axis-density совпадает с Мариной 8/8.»

Phase 9.4 цель: **regression tests pinning engine's existing correct behavior** для primary-axis match. No product code change. Lock in the deterministic win.

## Worker framing

> **Tests-only TASK. NO product code changes, NO engine changes, NO new helpers. Worker pins Marina-matching primary-axis output для 4-5 cases.**

## Scope (Tier C tests-only)

### Stage 9.4.1 — Identify test target

Per Phase 9.0 memo § 5.4 + § 6 TASK 4 proposal: engine's `synthesis_themes.primary_axis` (or analog field) для each case has Marina-matching primary theme:

| Case | Marina-primary theme | Engine output (per Phase 9.0 memo § 5.4) |
|---|---|---|
| 02-maksim | (per memo § 1.1) | matches |
| 05-ekaterina | (per memo § 1.1) | matches |
| 08-natalya | (per memo § 1.1) | matches |
| 10-danila | (per memo § 1.1) | matches |
| 11-olga (consultation 11) | «ось 5-11, подсчёт 4 из 12» | matches |

Worker reads Phase 9.0 memo § 1.1 + § 5.4 to extract Marina-primary theme per case (case 02 / 05 / 08 / 10 / Ольга 11). Cases 01/03/04/07/09 — Worker checks memo для availability; if Marina-primary not extracted в memo → either skip OR extract from Marina-reference PDFs (но это пограничная zone — Worker discretion).

### Stage 9.4.2 — Locate engine primary-axis output

Worker traces где в codebase emit'ится primary-axis theme:
- `services/api-python/app/pdf/synthesis_themes.py` (Phase 3 horizon split + post-`transit-section-generic-output` axis-density logic).
- `facts.analysis.synthesis.primary_axis` (or similar field name — Worker confirms).
- Template `solar.html.j2` секция «Итоги консультации» (или analog) reads which field?

Worker reports actual field path в HANDOFF.

### Stage 9.4.3 — Write regression tests

New `services/api-python/tests/test_summary_themes.py` (или extend existing if naturally fitting):

Per case (case 02 / 05 / 08 / 10 / Ольга 11 minimum; expand если Marina-primary extractable for additional cases):

- **Test:** Load case fixture → invoke `synthesis_themes.primary_axis(facts)` (или actual function name) → assert returned primary theme matches Marina-curated value.

Tests structure:
- Parametrize over cases с Marina-primary known.
- Each test: assert primary-axis == expected per memo § 1.1.

Worker decides if 1 parametrized test or multiple single-case tests — pick идиома consistent с existing test patterns в repo.

### Stage 9.4.4 — Manual smoke verification (optional)

After tests pass: render PDF консультации (e.g. consultation 11 Ольга) и confirm summary section primary-axis text still appears correctly. Optional — tests-only nature means this is bonus, не required acceptance.

## Files

- new:
  - `services/api-python/tests/test_summary_themes.py` (или extend `test_synthesis_themes.py` если existing — Worker decides).

- modify:
  - `project-overlays/astro/STATUS_RU.md`.

- delete: —

- **NO product code modifications:**
  - `services/api-python/app/pdf/synthesis_themes.py` NOT touched.
  - `services/api-python/app/pdf/transit_themes.py` NOT touched.
  - `services/api-python/app/pdf/outer_cards.py` NOT touched.
  - `services/api-python/app/pdf/builder.py` NOT touched.
  - `services/api-python/app/pdf/templates/solar.html.j2` NOT touched.
  - Engine, schema, fixtures NOT touched.

## Do not touch

- All product code (per «tests-only» scope).
- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS`.
- Phase 4b structured overrides.
- Phase 8 archived TASKs.
- Phase 9.0 memo (archived; reference).
- Phase 9.1 closure decision (archived; «show all active» remains production default).
- Phase 9.2 / 9.3 scope (deferred per user direction 2026-05-17).
- 12 future-work items audit § A.2.1.D.

## Acceptance

### Primary

- [ ] Tests added для 4-5 cases minimum (case 02, 05, 08, 10, Ольга 11) — each asserts engine primary-axis matches Marina-curated value per Phase 9.0 memo § 1.1.
- [ ] Tests pass at HEAD `aca694b` (engine already correct).
- [ ] **No product code modified** — `git diff aca694b -- services/api-python/app/` returns empty.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: `(368 baseline) + N new tests passed + 0 xfailed + 0 failed`. N ≥ 4 expected (one per case).
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit ideal (test file only).
- [ ] Overlay commit: STATUS_RU + HANDOFF.
- [ ] Push backup, parity verified.

### Discipline

- [ ] Tests-only: zero modifications to product code.
- [ ] If any test fails: STOP, escalation memo. Engine's primary-axis correctness was Phase 9.0 memo finding (8/8) — test failure means memo finding was wrong OR engine drifted; investigate before «fixing» test.

## STOP triggers

- Worker tempted to modify `synthesis_themes.py` или any product code → STOP, tests-only.
- Engine primary-axis output для test case differs from Marina expected → STOP, escalation (don't silently «fix» test to match engine; verify memo § 5.4 finding first).
- Engine field name / function signature不 found per Phase 9.0 memo references → STOP, escalation memo с diagnostic.
- Marina-primary theme not extractable from memo § 1.1 для targeted case → expand или skip (Worker discretion).

## Reviewer subagent — NOT REQUIRED

Per user direction 2026-05-17 Phase 9.4 series: «9.4 Reviewer не нужен, tests-only». TL inline-verify acceptable.

## Context

**Mode normal + Tier C tests-only.** Worker mode: normal. Zero risk to production.

**Baseline:**
- Product main @ `aca694b` (Phase 9.1 closed без code change; engine primary-axis correct since post-`transit-section-generic-output` 2026-05-16).
- Overlay master @ `62332ee` (Phase 9.1 closure + memo erratum).
- Pytest baseline: `368 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Phase 9.0 memo § 1.1 (Marina selections inventory): `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Phase 9.0 memo § 5.4 (sub-problem D verdict deterministic): same file.
- Phase 9.0 memo § 6 TASK 4 proposal (Phase 9.4 scope outline): same file.
- Phase 9.1 closure (precedent: «don't ship code without empirical validation»): `project-overlays/astro/TASKS/archive/2026-05-17-phase-9-1-directions-filter.md`.

**Not in scope (explicit):**
- Product code changes.
- Engine modifications.
- New helpers / filters.
- Phase 9.2 (outer cards) — deferred.
- Phase 9.3 (single-window narrowing) — deferred.
- Any «improve summary» heuristics beyond pinning current correct behavior.

**Ready: no** — TL flips after user ack + any refinements.
