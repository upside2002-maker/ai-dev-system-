# TASK: phase-9-4-summary-axis-regression-tests

- Status: open
- Ready: yes
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

### Stage 9.4.1 — Identify test target (AMENDED 2026-05-18 Option β scope)

**Original spec** had minimum 02/05/08/10/Ольга 11. **Empirical validation (prior Worker Stage 9.4.2 attempt) revealed memo § 5.4 «8/8 deterministic» overstated** — strict fixture check showed:

| Case | Engine output | Marina-primary | Match? |
|---|---|---|---|
| **02-maksim** | 2-8 | 2-8 (per memo § 1.1) | ✓ **PIN** |
| **03-artem** | 6-12 + 5-11 | 6-12 + 5-11 (per memo § 1.1) | ✓ **PIN** |
| 05-ekaterina | **1-7** @ strength 4 | **6-12** @ strength 4 | ✗ tie-break divergence — **DO NOT PIN** |
| **08-natalya** | 6-12 | 6-12 (per memo § 1.1) | ✓ **PIN** |
| 09-anastasiya | **None** (super-solar SR) | **1-7** (chart-anchor editorial) | ✗ super-solar fallback divergence — **DO NOT PIN** |
| **10-danila** | 2-8 | 2-8 (per memo § 1.1) | ✓ **PIN** |
| 11-olga | 5-11 | «ось 5-11» (memo § 1.3) | ✓ match BUT **DO NOT PIN** — no fixture in `packages/test-fixtures/golden-cases/`; DB-only; do not pull DB into tests-only TASK |

**Pin exactly 4 cases (β scope per user direction 2026-05-18): 02 / 03 / 08 / 10.** Each test asserts engine primary-axis == Marina-curated per memo § 1.1.

Cases 01/04/07: Marina-primary not extracted в memo § 1.1 (per Phase 9.0 documentation) — **skip per user direction «не добывать заново из PDF в этой задаче»**.

### Stage 9.4.2 — Locate engine primary-axis output

Worker traces где в codebase emit'ится primary-axis theme:
- `services/api-python/app/pdf/synthesis_themes.py` (Phase 3 horizon split + post-`transit-section-generic-output` axis-density logic).
- `facts.analysis.synthesis.primary_axis` (or similar field name — Worker confirms).
- Template `solar.html.j2` секция «Итоги консультации» (или analog) reads which field?

Worker reports actual field path в HANDOFF.

### Stage 9.4.3 — Write regression tests (β scope: 4 cases)

New `services/api-python/tests/test_summary_themes.py` (или extend existing if naturally fitting — per user direction Worker decides).

**Pin exactly 4 cases:** 02 / 03 / 08 / 10. Each test:

- Load case fixture (`packages/test-fixtures/golden-cases/<case>-*.expected.json`).
- Invoke `synthesis_themes.primary_axis(facts)` (или actual function name per Stage 9.4.2 trace).
- Assert returned primary theme matches Marina-curated value per memo § 1.1.

Tests structure:
- Parametrize over 4 cases с known Marina-primary.
- Each test: `assert engine_primary_axis == expected_marina_value`.

Worker decides if 1 parametrized test or 4 single-case tests — pick идиома consistent с existing test patterns в repo.

**Cases EXPLICITLY NOT pinned (per Worker findings + user direction β):**
- 05-ekaterina (tie-break divergence: engine 1-7 vs Marina 6-12).
- 09-anastasiya (super-solar fallback: engine None vs Marina 1-7 chart-anchor).
- 11-olga (no fixture; DB-only; do not pull DB into tests-only TASK).

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

### Primary (β scope per user direction 2026-05-18)

- [ ] **Exactly 4 tests** added для cases **02 / 03 / 08 / 10** — each asserts engine primary-axis matches Marina-curated value per memo § 1.1.
- [ ] Cases 05 / 09 / Ольга 11 — **NOT pinned** (divergence rationale documented в § Stage 9.4.1).
- [ ] Tests pass at HEAD `aca694b` (engine matches Marina for 4 pinned cases).
- [ ] **No product code modified** — `git diff aca694b -- services/api-python/app/` returns empty.
- [ ] **Memo § 5.4 erratum landed** в `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` per user verbatim formulation 2026-05-18 (see § Erratum spec below).
- [ ] **Programme lesson note added** в memo erratum per user direction.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: **`368 baseline + 4 new tests passed = 372 passed`**, 2 skipped, 0 failed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit ideal (test file only).
- [ ] Overlay commit: memo § 5.4 erratum + STATUS_RU + HANDOFF.
- [ ] Push backup, parity verified.

### Memo erratum spec (per user verbatim formulation 2026-05-18)

Add new subsection в `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` (после Phase 9.1 Erratum subsection or new «Erratum (Phase 9.4 empirical validation, 2026-05-18)» analogous heading):

```
> Phase 9.4 empirical validation revises Phase 9.0 § 5.4. The previous "deterministic 8/8" verdict was overstated. Strict fixture validation shows Marina match for 4/6 analyzable fixture cases: 02, 03, 08, 10. Case 05 diverges on equal-strength tie-break: engine selects numeric low-pole axis 1-7, Marina selects editorially significant 6-12. Case 09 diverges on super-solar fallback: engine returns no primary axis, Marina uses chart-anchor/editorial 1-7. Olga 11 matches Marina but is DB-only/no fixture and is not pinned in this tests-only task. Revised verdict: partial deterministic with editorial residual.
```

### Programme lesson note (per user direction 2026-05-18)

Add к memo erratum (separate paragraph, same subsection или just after):

```
> All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation. This is confirmed by Phase 9.1 directions and Phase 9.4 summary findings.
```

### Discipline

- [ ] Tests-only: zero modifications to product code.
- [ ] If any test fails: STOP, escalation memo. Engine's primary-axis correctness was Phase 9.0 memo finding (8/8) — test failure means memo finding was wrong OR engine drifted; investigate before «fixing» test.

## STOP triggers

- Worker tempted to modify `synthesis_themes.py` или any product code → STOP, tests-only.
- Engine primary-axis output для one of 4 pinned cases (02/03/08/10) differs from Marina expected → STOP, escalation (memo § 1.1 finding was wrong OR engine drifted; investigate before «fixing» test).
- Engine field name / function signature not found per Phase 9.0 memo references → STOP, escalation memo с diagnostic.
- Worker tempted to pin 05 / 09 / Ольга 11 — STOP, explicit β scope excludes these per user direction 2026-05-18.
- Worker tempted to «improve» engine to match Marina on 05 (tie-break) or 09 (super-solar fallback) — STOP, scope is tests-only.

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

**Ready: yes** — flipped 2026-05-18 after user ack + 5 clarifications + Option β scope amendment 2026-05-18:

1. **Spec clean** — no new requirements.
2. **Case selection AMENDED 2026-05-18 (Option β):** prior Worker Stage 9.4.2 empirical validation revealed memo § 5.4 «8/8» overstated. **Pin exactly 4 cases: 02 / 03 / 08 / 10** (deterministic-confirmed). DROP 05 (tie-break divergence), 09 (super-solar fallback), Ольга 11 (no fixture; DB-only). Cases 01/04/07 — Marina-primary not extracted в memo § 1.1; **Worker не extract'ит из Marina PDFs заново**.
3. **Test file:** Worker chooses (new preferred; extend existing if natural fit).
4. **Field name:** Worker traces; pre-mapped not required.
5. **STOP discipline (CRITICAL):** if engine output ≠ memo § 5.4 finding для **4 pinned cases** — **NOT fix code, NOT adjust test**; STOP + escalation memo. Memo § 5.4 may be wrong OR engine drifted. Worker investigates root cause before any «fix».
6. **Memo § 5.4 erratum** (per user verbatim 2026-05-18) + **programme lesson note** — both landed in memo as part of this TASK's overlay commit. See § Memo erratum spec + § Programme lesson note above for exact wording.
