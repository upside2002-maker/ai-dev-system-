# TASK: phase-9-2-b-outer-cards-angle-filter-implementation

- Status: open
- Ready: yes
- Date: 2026-05-18
- Project: astro
- Layer: services (Python presentation: `outer_cards.py` filter + tests)
- Risk tier: B (1 file modification + 1 property test; no schema; no fixtures)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 9.2A validation memo (2026-05-18) verdict: **Stage 0 PASS**. Filter `target ∉ {Asc, MC, IC, DC}` applied to engine outer-card emit set:

- 0 false negatives across all 10 cases.
- 35/35 Marina-selected card targets are non-angle planets.
- Engine ADT (`core/astrology-hs/src/Domain/TransitCalendar.hs:79-94`) constructively эмитит только `Asc`/`MC` для angle-class targets (IC/DC unreachable by engine construction).

Per Phase 9.2A memo § 5.1 + user direction 2026-05-18: implement angle-exclusion filter as **conservative** `{Asc, MC, IC, DC}` (defensive boundary даже если IC/DC currently unreachable).

## Worker framing (verbatim user direction 2026-05-18)

> Tier B; one product file: `outer_cards.py`; one strict property test; no allowlist changes; no significator heuristic; no interval logic; no template changes.

## Scope (Tier B implementation)

### Stage 1 — Single-line filter in `generic_outer_cards`

Target: `services/api-python/app/pdf/outer_cards.py:1656-1748` (`generic_outer_cards` function per Phase 9.2A § 5.1 reference).

Add filter constraint **in the candidate triple iteration**:

```python
ANGLE_TARGETS = frozenset({"Asc", "MC", "IC", "DC"})

# Inside generic_outer_cards, where candidate (transit, aspect, target) tuples are iterated:
if target in ANGLE_TARGETS:
    continue  # Marina never selects angle-target outer cards (Phase 9.2A Stage 0 PASS verdict)
```

**Conservative discipline (per user direction):** filter writes `{Asc, MC, IC, DC}` всех четырёх angles, даже если engine currently emits только `Asc`/`MC`. Defensive boundary; future-proofs if engine ever adds IC/DC support.

**Filter location (per user direction 2026-05-18):** **BEFORE `aggregate_display_windows`** call. Rationale: «Нет смысла агрегировать/строить карточку для target-angle, который всё равно будет отброшен.» Early filter at candidate iteration; угловые targets никогда не доходят до aggregation.

**`ANGLE_TARGETS` constant placement (per user direction 2026-05-18):** **module-level constant** в `outer_cards.py`, рядом с другими policy-constants («чтобы было видно как policy»). Worker locates appropriate spot near existing module-level constants (e.g. allowlist, planet-name dicts).

### Stage 2 — Strict property test

Add to `services/api-python/tests/test_transit_section_generic.py` (existing test file from Phase B 2026-05-16; check structure) OR new `test_outer_cards_angle_filter.py`.

Test must assert: **for all 10 fixture cases, `generic_outer_cards()` output contains zero cards с `target ∈ {Asc, MC, IC, DC}`.**

Pattern:
```python
@pytest.mark.parametrize("case_id", [
    "01-kseniya-2024-2025", "02-maksim-2025-2026", "03-artem-2025-2026",
    "04-valeriya-2025-2026", "05-ekaterina-2025-2026", "07-mariya-2025-2026",
    "08-natalya-2025-2026", "09-anastasiya-2025-2026", "10-danila-2025-2026",
    "11-olga-2026-2027",  # if fixture exists; else skip с reason
])
def test_generic_outer_cards_excludes_angle_targets(case_id):
    facts = json.loads(FIXTURE_PATH.read_text())
    cards = generic_outer_cards(facts, ...)
    angle_targets = {"Asc", "MC", "IC", "DC"}
    for card in cards:
        assert card["target"] not in angle_targets, \
            f"{case_id}: card with angle target {card['target']} should be filtered out"
```

**Discipline (per user direction):** strict property assertion — NOT pin Olga count или Marina-selected list. Test asserts «filter doesn't emit angle targets», nothing more.

### Stage 3 — Documentation: significator-supplement editorial note

Add comment / docstring в `outer_cards.py` near filter location (per user verbatim formulation 2026-05-18):

```python
# Significator supplement empirically drops Marina-selected cards for Olga;
# therefore it is not accepted as implementation gate and remains
# editorial/curation territory. See Phase 9.2A validation memo § 3 / § 4.3
# for diagnostic data. Filter restricted to angle-exclusion only.
```

This documents для future maintainers что значимостный фильтр исследовался и явно отвергнут.

## Files

- modify:
  - `services/api-python/app/pdf/outer_cards.py` (filter + significator docstring/comment).
  - `services/api-python/tests/test_transit_section_generic.py` (если extend; else add new file).
  - `project-overlays/astro/STATUS_RU.md`.

- new (optional, if Worker prefers):
  - `services/api-python/tests/test_outer_cards_angle_filter.py`.

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures.
- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` — calibrated data untouched.
- `solar.html.j2` template — no changes.
- `builder.py` — no changes.
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs.
- Phase 9.0 memo (archived; § 5.2 verdict stays «hybrid»).
- Phase 9.2A validation memo (archived; reference document).
- Phase 9.4 tests (`test_summary_themes.py`) — preserve.
- 12 future-work items audit § A.2.1.D.
- Other test files (e.g. `test_directions_section.py`).
- **DO NOT add significator heuristic** to filter — explicit per user direction 2026-05-18.
- **DO NOT add interval logic** to filter.
- **DO NOT add allowlist changes.**
- **DO NOT introduce new filter rule beyond `target ∉ {Asc, MC, IC, DC}`.**

## Acceptance

### Primary

- [ ] `generic_outer_cards` includes filter `target ∉ {Asc, MC, IC, DC}` (conservative).
- [ ] Property test asserts filter compliance для всех 10 fixture cases.
- [ ] Significator-supplement editorial note добавлена в `outer_cards.py` per user verbatim formulation 2026-05-18.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: pytest passes `>= 372 + N`, where N = parametrized expansion count (could be 1 single test or 10 instances per pytest convention; Worker reports actual в HANDOFF per user direction 2026-05-18 «pytest count flexible»). **Critical gate: 0 xfailed + 0 failed AND property actually exercises all 10 cases.**
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (filter + test).
- [ ] Overlay commit: STATUS_RU + HANDOFF.
- [ ] Push backup, parity verified.

### Discipline

- [ ] Filter scope strictly `target ∉ {Asc, MC, IC, DC}` (no significator, no other criteria).
- [ ] Property test does NOT pin specific Marina-selected counts (e.g. NOT «Olga has 12 cards after filter»). Test asserts only property: «filter excludes angle targets».
- [ ] No allowlist data modifications.
- [ ] No new files в `app/pdf/` beyond filter в `outer_cards.py`.

## STOP triggers

- Worker tempted to add significator heuristic → STOP, explicit user direction 2026-05-18.
- Worker tempted to pin Olga count or Marina-selected list в test → STOP, strict property scope.
- Property test fails (filter doesn't exclude angle targets in some case) → STOP, investigate engine output вместо «adjusting filter».
- Existing tests break (calibrated allowlist cases) → STOP, regression.
- Filter inadvertently drops Marina-selected card в calibrated case → STOP, Phase 9.2A finding не holds in implementation; investigate.
- Worker tempted to modify allowlist OR `_OUTER_CARD_FACTS` → STOP, untouched scope.

## Reviewer subagent — OPTIONAL (per user direction 2026-05-18)

Tier B normally Reviewer-required, но user explicit: «Reviewer optional. TL inline-verify достаточно. Implementation теперь one-line + property test.»

If Worker prefers Reviewer pass — может spawn'нуть, не блокер.

## Context

**Mode normal + Tier B (Reviewer optional per user direction).** Worker mode: normal. Minimal implementation scope (1 file + 1 test + 1 comment).

**Baseline:**
- Product main @ `941b78f` (Phase 9.4 β tests landed; Phase 9.2A no code changes).
- Overlay master @ `aebefb2` (Phase 9.2A closure).
- Pytest baseline: `372 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Phase 9.2A validation memo: `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md` § 4 (Stage 0 PASS verdict) + § 5.1 (this implementation outline).
- Phase 9.0 memo § 5.2 verdict «hybrid»: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Engine ADT (constructively eliminates IC/DC): `core/astrology-hs/src/Domain/TransitCalendar.hs:79-94`.
- `generic_outer_cards` location: `services/api-python/app/pdf/outer_cards.py:1656-1748`.

**Not in scope (explicit):**
- Significator-set heuristic (deferred / editorial only per user direction 2026-05-18).
- Interval logic / single-window narrowing (Phase 9.3 scope; deferred).
- Allowlist changes для non-calibrated cases.
- Template / synthesis / engine changes.

**Ready: yes** — flipped 2026-05-18 after user ack + 5 clarifications:

1. **Spec clean** — no new requirements.
2. **Filter location:** BEFORE `aggregate_display_windows` («нет смысла агрегировать/строить карточку для target-angle, который всё равно будет отброшен»).
3. **`ANGLE_TARGETS`:** module-level constant near other policy-constants («чтобы было видно как policy»).
4. **Test file:** Worker discretion. Extend `test_transit_section_generic.py` if natural fit; new file if clutter.
5. **Pytest count flexible.** Worker reports actual count в HANDOFF. Critical gate: 0 failed / 0 xfailed AND property actually exercises all 10 cases.
