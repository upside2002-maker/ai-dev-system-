# HANDOFF: worker → tl — phase-9-2-b-outer-cards-angle-filter-implementation

- Status: open
- Date: 2026-05-18 21:30
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-18-phase-9-2-b-outer-cards-angle-filter-implementation.md
- Product repo status: committed (product main @ 7751d46)

## Summary

Tier B implementation TASK (Reviewer OPTIONAL per user direction 2026-05-18 `33d5dbe`). Worker shipped angle-target exclusion filter в `services/api-python/app/pdf/outer_cards.py` per Phase 9.2A Stage 0 PASS verdict (35/35 Marina-selected card targets are non-angle planets across 10 cases, validation memo landed `aebefb2`). Single product commit `7751d46`: `ANGLE_TARGETS` module-level frozenset constant + filter check inside `generic_outer_cards` candidate iteration + significator editorial note encoded в constant docstring + 10 new property test instances (9 fixture cases + 1 Olga DB case). Pytest 372 → 382 passed + 2 skipped + 0 failed. Cabal Up to date (no Haskell change).

## Done

### Product code (commit `7751d46`)

- `services/api-python/app/pdf/outer_cards.py`:
  - Lines 1392-1405 (new): `ANGLE_TARGETS: frozenset[str] = frozenset({"Asc", "MC", "IC", "DC"})` module-level policy constant + docstring (~14 lines).
  - Lines 1728-1732 (new): filter check `if tgt in ANGLE_TARGETS: continue` placed BEFORE `aggregate_display_windows` call (line 1758) — early-skip at candidate iteration.
  - Significator-supplement editorial note encoded в `ANGLE_TARGETS` docstring (lines 1392-1404) per user verbatim formulation 2026-05-18 `33d5dbe`.

- `services/api-python/tests/test_transit_section_generic.py`:
  - Line 35: import `ANGLE_TARGETS` from `app.pdf.outer_cards`.
  - Line 268: count assertion 7 → 6 with Phase 9.2B-aware comment (filter legitimately drops 1 angle-target triple Neptune Square Asc; 6 surviving cards match Marina-selected planet-target set per Phase 9.2A memo § 1.1).
  - Lines 396-454 (new): Phase 9.2B section header + 2 new tests (`test_generic_outer_cards_excludes_angle_targets` parametrized по 9 fixture cases + `test_olga_generic_outer_cards_excludes_angle_targets` для 11-olga DB-only).

### Overlay (commit `257bb09` master)

- `project-overlays/astro/STATUS_RU.md`: Phase 9.2B «Сейчас» entry prepended.
- `project-overlays/astro/HANDOFFS/2026-05-18-worker-to-tl-phase-9-2-b-outer-cards-angle-filter-implementation.md`: this file.

### Verification

- Pre-implementation baseline: 372 passed + 2 skipped + 0 failed.
- Post-implementation: **382 passed + 2 skipped + 0 failed** (Δ +10 instances).
- Property test parametrization actual exercise: 9 fixture cases (01/02/03/04/05/07/08/09/10) + 1 Olga DB case = **10 total**.
- Cabal `core/astrology-hs`: Up to date.
- Product `git status --short` clean after commit.
- Backup parity verified: product main `7751d46` == backup/main `7751d46`; overlay master `257bb09` == backup/master `257bb09`.

## Stage answers (per TASK HANDOFF requirements)

### Stage 1.1 — ANGLE_TARGETS placement

**Line 1405** в `outer_cards.py`. Neighbouring policy-constants:
- Line 1379: `_OUTER_TRANSIT_PLANETS = frozenset({"Uranus", "Neptune", "Pluto"})`.
- Line 1388: `_GENERIC_OUTER_ASPECTS = frozenset({"Conjunction", "Sextile", "Square", "Trine", "Opposition"})`.
- Line 1405 (new): `ANGLE_TARGETS = frozenset({"Asc", "MC", "IC", "DC"})`.

All three follow identical `frozenset[str]` policy-constant pattern с docstring summarising empirical justification. Visible as policy per user direction 2026-05-18 `33d5dbe`. `ANGLE_TARGETS` is exported (no leading underscore) для test-side import; private constants (`_OUTER_TRANSIT_PLANETS`, `_GENERIC_OUTER_ASPECTS`) used only inside module.

### Stage 1.2 — Filter placement

**Line 1732** — inside `generic_outer_cards` (function starts line 1671), inside candidate iteration loop (lines 1717-1734), **BEFORE** `aggregate_display_windows` call at line 1758.

Position relative к existing code:
- Line 1727: existing aspect filter (`if asp not in _GENERIC_OUTER_ASPECTS: continue`).
- Line 1729: existing target-truthiness check (`if not tgt: continue`).
- **Line 1732 (new):** `if tgt in ANGLE_TARGETS: continue` — angle-target filter.
- Line 1734: `seen[(tp, asp, tgt)] = None` — gathered triple set.
- Line 1758: `windows = aggregate_display_windows(raw)` — downstream aggregation.

Early-skip discipline per user direction 2026-05-18 `33d5dbe`: «нет смысла агрегировать/строить карточку для target-angle, который всё равно будет отброшен».

### Stage 1.3 — Significator editorial note placement

Encoded в `ANGLE_TARGETS` docstring (lines 1392-1404):

> Significator supplement empirically drops Marina-selected cards for Olga; therefore it is not accepted as implementation gate and remains editorial/curation territory. See Phase 9.2A validation memo § 3 / § 4.3 for diagnostic data. Filter restricted to angle-exclusion only.

Placement rationale: docstring on the constant — single point of truth for both empirical justification (Phase 9.2A `aebefb2`) и editorial-deferral note. Future maintainers reading `ANGLE_TARGETS` get full context inline.

### Stage 2.1 — Test file decision

**Extended `services/api-python/tests/test_transit_section_generic.py`** (TASK B 2026-05-16 file `aca694b`).

Rationale:
- File already exercises `generic_outer_cards` directly.
- Pre-existing parametrize fixture list `_CALIBRATED_CASES` (line 58-68) covers exactly 9 fixture cases needed.
- Existing Olga DB-fixture helper `_olga_facts_or_skip()` covers 11-olga path (DB-only, skips gracefully).
- Existing `test_generic_fallback_excludes_quincunx` (line 345) is structural sibling — same exclusion-property pattern.
- Pairing keeps related «exclusion property» tests together.
- New file would duplicate fixture-loading scaffolding for no gain.

No clutter risk — new tests sit в clearly-labelled `Phase 9.2B` section at file end с explanatory header.

### Stage 2.2 — Pytest count actual

Pre-implementation: 372 passed + 2 skipped + 0 failed.

Post-implementation: **382 passed + 2 skipped + 0 failed**.

Δ = +10 new test instances:
- 9 parametrized instances of `test_generic_outer_cards_excludes_angle_targets[<case_id>]` (one per `_CALIBRATED_CASES` entry: 01, 02, 03, 04, 05, 07, 08, 09, 10).
- 1 standalone `test_olga_generic_outer_cards_excludes_angle_targets`.

Critical gate satisfied:
- 0 failed.
- 0 xfailed.
- Property actually exercises all 10 cases.
- 2 skipped unchanged (same pre-existing DB-skip when DB absent).

Pre-existing `test_olga_generic_cards_present_and_well_formed` count assertion 7 → 6 — only existing test affected, anticipated update (regression-anchor refresh, not new Marina-count pin; Phase 9.2A memo § 1.2 named Neptune Square Asc as Marina-rejected angle-target).

### 11-olga test handling

**Included via existing `_olga_facts_or_skip()` helper.** Fixture absent in `packages/test-fixtures/golden-cases/` (verified via `ls`) — Ольга is DB-only per consultation 10 row в `data/astro.db`. Test skips gracefully when DB absent (same dispatch as other Ольга-targeted tests в this module).

DB-present outcome (this Worker session): filter drops 1 angle-target card (Neptune Square Asc) → 6 surviving cards, all planet-targets, matching Marina-selected set per Phase 9.2A memo § 1.1.

## Артефакты

- Product commit: `7751d46` (`feat(pdf): outer-card angle-target filter + property tests (Phase 9.2B)`).
- Overlay commit: `257bb09` master (`docs(astro): Phase 9.2B angle-filter Worker HANDOFF + STATUS_RU`).
- Modified product files:
  - `services/api-python/app/pdf/outer_cards.py` (lines 1392-1405 + 1728-1732).
  - `services/api-python/tests/test_transit_section_generic.py` (line 35 + line 268 + lines 396-454).
- New overlay file: `project-overlays/astro/HANDOFFS/2026-05-18-worker-to-tl-phase-9-2-b-outer-cards-angle-filter-implementation.md`.
- Modified overlay file: `project-overlays/astro/STATUS_RU.md`.
- Backup parity: product `7751d46` (`/Users/ilya/Backups/astro.git`) + overlay `257bb09` (`/Users/ilya/Backups/ai-dev-system.git`) — verified via `git rev-parse` both sides.

**Product repo status:** committed (product main @ `7751d46`).

## Conflicts / open questions

None. Implementation matched Phase 9.2A § 5.1 outline precisely (validation memo `aebefb2`). The pre-existing `test_olga_generic_cards_present_and_well_formed` count assertion update 7→6 was anticipated by Phase 9.2A memo § 1.2 (Neptune Square Asc named as Marina-rejected angle-target); routine regression-anchor refresh, not new Marina-count pin, documented inline в test docstring.

## STOP triggers / strict prohibitions

All STOP triggers honoured (none triggered). All strict prohibitions adhered:

- ✓ Haskell engine, schema, fixtures untouched.
- ✓ `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` untouched (calibrated data preserved).
- ✓ `solar.html.j2` template untouched.
- ✓ `builder.py` untouched.
- ✓ Significator-set heuristic NOT added (editorial-deferral note encoded instead).
- ✓ Filter rule strictly `target ∉ {Asc, MC, IC, DC}` — no other criteria.
- ✓ Olga count NOT pinned в new property test (existing test count anchor updated separately per Stage 2.2 explanation).
- ✓ Marina-selected list NOT pinned в property test (strict scope only).
- ✓ Phase 4b structured overrides untouched.
- ✓ Phase 9.4 tests untouched.
- ✓ Phase A directions test untouched.
- ✓ API endpoint tests untouched.

## Reviewer status

Reviewer subagent НЕ задействован per user direction 2026-05-18 `33d5dbe` («Reviewer optional. TL inline-verify достаточно. Implementation теперь one-line + property test.»). Worker ready for TL inline-verify + accept-cascade.

## Submit-task readiness

- ✓ All Acceptance items covered (filter shipped; property tests pass; significator editorial note encoded).
- ✓ All Common acceptance items covered (cabal clean; pytest 0 failed AND 0 xfailed AND property exercises 10 cases; git status clean; commits landed; backup parity verified).
- ✓ All Discipline items covered (filter scope strict; no count pin in property test; no allowlist modifications; no new files в `app/pdf/` beyond filter в `outer_cards.py`).
