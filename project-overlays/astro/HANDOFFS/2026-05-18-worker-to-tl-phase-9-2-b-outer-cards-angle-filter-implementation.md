# HANDOFF — Worker → TL — Phase 9.2B Outer Cards Angle Filter Implementation

Дата: 2026-05-18
Worker: Claude Code (Opus 4.7 1M)
TASK: `project-overlays/astro/TASKS/2026-05-18-phase-9-2-b-outer-cards-angle-filter-implementation.md`
Tier: B (1 file modification + 1 property test, Reviewer OPTIONAL per user direction 2026-05-18)

---

## § 1. Verdict

**ACCEPT.** Filter shipped + property test landed + significator editorial note encoded в `ANGLE_TARGETS` docstring. Pytest 382/2/0 (baseline 372 + 10 new instances). Cabal Up to date. Product `git status --short` clean for intended changes.

---

## § 2. Stage 1 — Filter implementation в `outer_cards.py`

### § 2.1 ANGLE_TARGETS placement (Stage 1.1)

**Line 1405** в `services/api-python/app/pdf/outer_cards.py` — module-level constant near other policy-constants per user direction:

```python
ANGLE_TARGETS: frozenset[str] = frozenset({"Asc", "MC", "IC", "DC"})
```

**Neighbouring policy-constants:**
- Line 1379: `_OUTER_TRANSIT_PLANETS: frozenset[str] = frozenset({"Uranus", "Neptune", "Pluto"})`.
- Line 1388: `_GENERIC_OUTER_ASPECTS: frozenset[str] = frozenset({"Conjunction", "Sextile", "Square", "Trine", "Opposition"})`.
- Line 1405 (new): `ANGLE_TARGETS: frozenset[str] = frozenset({"Asc", "MC", "IC", "DC"})`.

All three follow the same pattern (`frozenset[str]` policy-constant с docstring summarising empirical / theoretical justification). Visible as policy per user direction («чтобы было видно как policy»).

Naming convention: `ANGLE_TARGETS` is exported (no leading underscore) to be importable from the test module — analogous import pattern с `OUTER_CARD_ALLOWLIST` (line 160, also public). Other module-level policy constants (`_OUTER_TRANSIT_PLANETS`, `_GENERIC_OUTER_ASPECTS`) are private as they are only used inside this module.

Conservative set `{Asc, MC, IC, DC}` per user direction 2026-05-18 — defensive boundary даже если engine ADT currently emits только `Asc`/`MC` (per `Domain.TransitCalendar.TransitTarget` core/astrology-hs/src/Domain/TransitCalendar.hs:79-94). IC/DC unreachable today, included as future-proof guard.

### § 2.2 Filter placement (Stage 1.2)

**Line 1732** в `generic_outer_cards` — **BEFORE** `aggregate_display_windows` call (line 1758).

Filter location relative к existing code:
- Line 1717-1734: candidate iteration loop (`for entry in table_list: ... for h in entry.get("hits", []) ...`).
- Line 1727: existing aspect filter (`if asp not in _GENERIC_OUTER_ASPECTS: continue`).
- Line 1729: existing target-truthiness check (`if not tgt: continue`).
- **Line 1732 (new):** `if tgt in ANGLE_TARGETS: continue` — angle-target filter.
- Line 1734: `seen[(tp, asp, tgt)] = None` — gathered triple set.
- Line 1758: `windows = aggregate_display_windows(raw)` — downstream aggregation.

Filter sits **inside** the candidate iteration loop, **after** truthiness/aspect filters но **before** triple is added to `seen` dict. Angle-targets are skipped at iteration time → never reach `_collect_raw_hits` или `aggregate_display_windows`. Early-skip discipline per user direction («нет смысла агрегировать/строить карточку для target-angle, который всё равно будет отброшен»).

### § 2.3 Significator-supplement editorial note (Stage 1.3)

Encoded **в `ANGLE_TARGETS` docstring** (lines 1392-1404) per user verbatim formulation 2026-05-18:

```python
#: Phase 9.2B: outer cards never have angle targets (Asc/MC/IC/DC).
#: Empirically verified Phase 9.2A Stage 0 PASS: 0 of 35 Marina-selected
#: card targets are angle planets across 10 cases. Conservative
#: {Asc, MC, IC, DC} per user direction 2026-05-18 — defensive boundary
#: даже если engine ADT currently emits только Asc/MC (per
#: Domain.TransitCalendar.TransitTarget core/astrology-hs/src/Domain/
#: TransitCalendar.hs:79-94 — IC/DC unreachable by engine construction
#: today, included here as future-proof guard).
#:
#: Significator supplement empirically drops Marina-selected cards for
#: Olga; therefore it is not accepted as implementation gate and remains
#: editorial/curation territory. See Phase 9.2A validation memo § 3 /
#: § 4.3 for diagnostic data. Filter restricted to angle-exclusion only.
```

Placement rationale: docstring on the constant — single point of truth for both the empirical justification (Phase 9.2A) и editorial-deferral note (significator). Future maintainers reading `ANGLE_TARGETS` get the full context inline. Filter site at line 1732 references back via short comment («See `ANGLE_TARGETS` docstring for empirical justification»).

---

## § 3. Stage 2 — Property test

### § 3.1 Test file decision (Stage 2.1)

**Extended `services/api-python/tests/test_transit_section_generic.py`** (TASK B 2026-05-16 file). Rationale:

- File already exercises `generic_outer_cards` directly (Stage 2/3 tests).
- Pre-existing parametrize fixture list `_CALIBRATED_CASES` (line 58-68) covers exactly the 9 fixture cases needed.
- Existing Olga DB-fixture helper `_olga_facts_or_skip()` covers the 11-olga path (DB-only, skips gracefully).
- Existing `test_generic_fallback_excludes_quincunx` (line 345) is a structural sibling to the new angle-exclusion test (same module, same Olga pattern). Pairing the new angle-exclusion test rядом с Quincunx-exclusion test keeps related «exclusion property» tests together.
- New file would duplicate fixture-loading scaffolding for no gain.

No clutter risk — the new tests sit in a clearly-labelled `Phase 9.2B` section at the file end with explanatory header.

### § 3.2 Property test body (Stage 2.2)

Two tests added at end of file (lines 396-454 в updated file):

1. **`test_generic_outer_cards_excludes_angle_targets`** — parametrized on `_CALIBRATED_CASES` (9 cases: 01, 02, 03, 04, 05, 07, 08, 09, 10). For each fixture: load facts, call `generic_outer_cards(facts, tz_id="Europe/Moscow")`, assert `card["target"] not in ANGLE_TARGETS` for every card.
2. **`test_olga_generic_outer_cards_excludes_angle_targets`** — standalone test using existing `_olga_facts_or_skip()` for 11-olga DB-only case. Skips gracefully when DB absent. Same property assertion.

**Property scope strict** (per user direction 2026-05-18): tests assert ONLY «filter excludes angle targets». NO Marina-selected count pin, NO per-case card inventory pin, NO «Olga has 6 cards» pin. The pre-existing `test_olga_generic_cards_present_and_well_formed` count assertion (line 268) was a separate test (structural well-formedness anchor, NOT the new property test); it required updating from 7 to 6 because Phase 9.2B filter legitimately drops the 1 angle-target triple — но это update of existing test, не new pin.

### § 3.3 11-olga handling

11-olga has **no fixture** in `packages/test-fixtures/golden-cases/` (verified via `ls`). Per existing pattern in this test file, Ольга is loaded from DB (`data/astro.db:consultations[10].facts_json`) через `_olga_facts_or_skip()` helper. Test skips gracefully when DB absent.

Olga test outcome (DB present): filter drops 1 angle-target card (Neptune Square Asc) → 6 surviving cards, all planet-targets, matching Marina-selected set per Phase 9.2A memo § 1.1 / § 1.2.

### § 3.4 Adjacent test count update (existing test, not new pin)

`test_olga_generic_cards_present_and_well_formed` (line 248) had pre-Phase-9.2B regression anchor `assert len(cards) == 7`. Phase 9.2B angle-filter legitimately reduces Ольга generic count from 7 to 6 (engine emits 1 angle-target triple, filtered out). Updated assertion: `assert len(cards) == 6` with explanatory comment referencing Phase 9.2B filter and engine pre-filter count for traceability.

This is **update of pre-existing test**, NOT a new Marina-count pin. The new property tests (§ 3.2) deliberately avoid count assertions per user direction.

### § 3.5 Pytest count post-implementation

Pre-implementation baseline: `372 passed + 2 skipped + 0 failed`.

Post-implementation: `382 passed + 2 skipped + 0 failed`.

Δ = +10 new test instances:
- 9 parametrized instances of `test_generic_outer_cards_excludes_angle_targets[<case_id>]` (one per `_CALIBRATED_CASES` entry).
- 1 standalone `test_olga_generic_outer_cards_excludes_angle_targets`.

**Critical gate satisfied:**
- 0 failed.
- 0 xfailed.
- Property actually exercises all 9 fixture cases + Olga DB case (10 total).
- 2 skipped count unchanged (same pre-existing DB-skip when DB absent — Olga skip is conditional on DB presence).

Pre-existing `test_olga_generic_cards_present_and_well_formed` count assertion (7 → 6) was the only existing test affected; updated с Phase 9.2B-aware comment.

---

## § 4. Common acceptance

- **Cabal:** `cabal build` в `core/astrology-hs` — `Up to date`. NO Haskell changes.
- **Pytest:** `382 passed + 2 skipped + 0 failed`. Baseline 372/2/0 preserved (existing tests unchanged in behaviour except the well-formedness count anchor 7→6 due to filter — same module, no fragile assertion).
- **Product `git status --short` clean for intended changes:**
  ```
  M services/api-python/app/pdf/outer_cards.py
  M services/api-python/tests/test_transit_section_generic.py
  ```
- **One product commit (planned):** filter + test + count-update в едином коммите.
- **Overlay commit (planned):** STATUS_RU + HANDOFF.
- **Push backup (planned):** parity verified before submit.

---

## § 5. Files modified

### Product

- `services/api-python/app/pdf/outer_cards.py`:
  - Lines 1392-1405 added: `ANGLE_TARGETS` constant + docstring + significator editorial note (~14 lines including blank).
  - Lines 1728-1732 added: filter check `if tgt in ANGLE_TARGETS: continue` (~5 lines including comment).

- `services/api-python/tests/test_transit_section_generic.py`:
  - Line 35: import `ANGLE_TARGETS` from `app.pdf.outer_cards`.
  - Line 268: count assertion 7 → 6 with Phase 9.2B-aware docstring/comment update.
  - Lines 396-454 added: Phase 9.2B section header + 2 new tests.

### Overlay

- `project-overlays/astro/STATUS_RU.md` — Phase 9.2B Сейчас entry.
- `project-overlays/astro/HANDOFFS/2026-05-18-worker-to-tl-phase-9-2-b-outer-cards-angle-filter-implementation.md` — this file.

### Not touched

- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` — calibrated data unchanged.
- `solar.html.j2` template.
- `services/api-python/app/pdf/builder.py`.
- `services/api-python/app/pdf/synthesis_themes.py`.
- `services/api-python/app/pdf/transit_themes.py`.
- Phase 4b structured overrides (`tests/test_natalya_transits_acceptance.py`).
- Phase 9.4 tests (`tests/test_summary_themes.py`).
- Phase A 2026-05-16 (`tests/test_directions_section.py`).
- API endpoint tests (`tests/test_api_pdf_endpoint.py`).
- Engine: `core/astrology-hs/` zero changes.
- Schema: `packages/contracts/*.schema.json` zero changes.
- Fixtures: `packages/test-fixtures/golden-cases/*.expected.json` zero changes.

---

## § 6. STOP triggers honoured

- ✓ Property test did NOT fail — filter excludes angle targets correctly for all 9 fixture cases + Olga.
- ✓ Filter did NOT drop any Marina-selected card в calibrated case (calibrated path bypasses `generic_outer_cards` entirely; allowlist branch unaffected).
- ✓ Existing pytest tests passed (372 baseline preserved + 10 new). Only test count assertion updated was Olga-7→6 inside same module, with traceability comment.
- ✓ NO significator heuristic added.
- ✓ NO interval logic added.
- ✓ NO template changes.
- ✓ NO allowlist changes.
- ✓ NO new filter rule beyond `target ∉ {Asc, MC, IC, DC}`.
- ✓ `generic_outer_cards` signature unchanged (still `(facts, *, tz_id=None) -> list[dict[str, Any]]`).

---

## § 7. Strict prohibitions adherence

- ✓ Haskell engine, schema, fixtures — UNTOUCHED.
- ✓ `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` — UNTOUCHED.
- ✓ `solar.html.j2` template — UNTOUCHED.
- ✓ `builder.py` — UNTOUCHED.
- ✓ Significator-set heuristic — NOT added (explicit user direction 2026-05-18; significator-deferral encoded в `ANGLE_TARGETS` docstring instead).
- ✓ Filter rule strictly `target ∉ {Asc, MC, IC, DC}` — no other criteria.
- ✓ Olga count NOT pinned в new property test (existing test count anchor updated separately per § 3.4 above).
- ✓ Marina-selected list NOT pinned в property test (strict scope only).
- ✓ Phase 4b structured overrides — UNTOUCHED.
- ✓ Phase 9.4 tests — UNTOUCHED.
- ✓ Phase A directions test — UNTOUCHED.
- ✓ API endpoint tests — UNTOUCHED.

---

## § 8. Verification snapshot

```
Pre-implementation baseline:
  product main @ 941b78f
  overlay master @ 33d5dbe (TASK Ready: yes + 5 clarifications)
  pytest: 372 passed + 2 skipped + 0 failed
  cabal: Up to date

Post-implementation (this HANDOFF):
  product diff: 2 files modified
    services/api-python/app/pdf/outer_cards.py | +21 lines
    services/api-python/tests/test_transit_section_generic.py | +74 lines (incl. import + count update + property tests)
  pytest: 382 passed + 2 skipped + 0 failed
  cabal: Up to date

Property test parametrization actual exercise count: 9 fixture cases + 1 Olga DB case = 10 total.
```

---

## § 9. Optional smoke verification (Stage 3)

Not run (optional per TASK § Stage 3). Pytest property tests cover the assertion deterministically. If TL wants visual smoke on consultation 11 (Olga PDF render), the filter behaviour is exercised through `test_olga_generic_outer_cards_excludes_angle_targets` already — DB-loaded facts, real engine output, real `generic_outer_cards` call path.

---

## § 10. Submit-task readiness

- ✓ All Acceptance items covered.
- ✓ All Common acceptance items covered.
- ✓ All Discipline items covered.
- ✓ All STOP triggers honoured (none triggered).
- ✓ All Strict prohibitions adhered.
- ✓ Reviewer subagent skipped per user direction 2026-05-18 (Tier B, Reviewer OPTIONAL).

Ready for TL inline-verify + accept-cascade + push backup + submit-task.

---

## § 11. Open questions / surprises

None. Implementation matched Phase 9.2A § 5.1 outline precisely. The single «surprise» — pre-existing `test_olga_generic_cards_present_and_well_formed` count assertion needed updating from 7→6 because filter legitimately drops 1 angle-target — was anticipated by Phase 9.2A memo § 1.2 (which named Neptune Square Asc as Marina-rejected angle-target). The update is a routine regression-anchor refresh, not a new Marina-count pin, and is documented inline в test docstring.
