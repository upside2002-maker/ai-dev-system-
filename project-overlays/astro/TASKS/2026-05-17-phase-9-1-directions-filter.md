# TASK: phase-9-1-directions-filter

- Status: open
- Ready: yes
- Date: 2026-05-17
- Project: astro
- Layer: services (Python presentation: directions filter helper + template wiring + tests)
- Risk tier: B (1 filter function + 1 template wiring + 1 regression test; no schema; no fixtures)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 9.0 memo § 5.1 verdict: directions sub-problem = `hybrid` (deterministic-leaning). **Marina explicitly writes the rule** в каждом calibrated PDF:

> «Чтобы событие произошло, то, в первую очередь, мы должны рассмотреть аспекты к Асц (1 дом), элементам 1 дома и МС.»

Это **deterministic, не editorial**. Predicted by user 2026-05-17: «directions могут оказаться hybrid/deterministic» — verified empirically (8/8 calibrated cases + Ольга).

Current state (post TASK `directions-show-all-active` 2026-05-16):
- Template `solar.html.j2:450,453` no longer narrows directions to direct Asc/MC.
- All `facts.analysis.directions.active` rendered.
- Result: Ольга consultation 11 shows **9 directions vs Marina's curated 4** — inverted pendulum from previous «hidden important» to «over-broad».

User direction 2026-05-17:
> «9.1 должен строго опираться на явно найденное правило Марины, а не на новый heuristic soup. Если rule A2/A3 начнут спорить с текстом Марины — Worker обязан STOP, не "улучшать" правило молча.»

## Marina's explicit rule (memo § 5.1)

Per Worker's hypothesis testing на 10 cases (memo § 3.1 + § 5.1):

### Rule A1 (Marina's verbatim, deterministic)

A direction is Marina-significant **iff** at least ONE of `direction.directed` or `direction.target` is in the set:
- `Asc` (ascendant point).
- `MC` (midheaven point).
- Any planet placed in natal 1st house (in `natal_chart.houses[1]`).
- Asc-ruler (the planet ruling the sign of the Asc).
- **Fallback if Asc-ruler not determinable:** Moon (universal personal-life significator). **Discipline (per user direction 2026-05-17):** Moon fallback applies **ONLY** if Asc-ruler cannot be determined (no data, missing sign, edge case). If Asc-ruler is known, Moon is **NOT** added to S — fallback must NOT expand selection when primary value exists. Worker codes this as explicit fallback gate, not as «include both» logic.

### Rule A2 (Worker supplement — verify against Marina text before applying)

Among directions matching A1: if `direction.directed` (the directing planet) is transpersonal (Uranus / Neptune / Pluto), include only if its `formulas` field contains house combinations NOT already covered by a personal-source direction (Sun / Moon / Mercury / Venus / Mars / Jupiter / Saturn) in the current emit set.

**Marina-text trace:** Marina does not explicitly state A2 в memo § 5.1 finding. A2 is Worker's empirical observation that Marina prefers personal-source directions over duplicate-formula transpersonal directions.

**STOP trigger:** If applying A2 would EXCLUDE a Marina-selected direction (false negative) — Worker MUST STOP, escalation memo, do NOT silently «adjust» A2. Marina's verbatim A1 is the contract; A2/A3 are supplements that may turn out wrong.

### Rule A3 (Worker supplement — verify against Marina text before applying)

Deduplicate by formula overlap: among 2+ directions matching A1 AND A2 that share > 80% of formula tokens (e.g. «1+7, 1+8, 1+9, 1+10» appearing on multiple directions), keep ONLY the first by `enter_jd` ordering.

**Marina-text trace:** Worker's empirical observation (memo § 3.1 case 02/04 deduplication pattern). Marina does not state A3 explicitly.

**STOP trigger:** Same as A2 — if A3 excludes Marina-selected → STOP.

## Worker framing (verbatim user direction 2026-05-17)

> **9.1 должен строго опираться на явно найденное правило Марины, а не на новый heuristic soup. Если rule A2/A3 начнут спорить с текстом Марины — Worker обязан STOP, не «улучшать» правило молча.**

## Stages

### Stage 0 — Validate A1 alone before A2/A3

Worker first tests **A1 alone** against Ольгины 9 emit-set:
- Count matches: how many of 9 satisfy A1? 4? 6? 9?
- If A1 alone yields exactly 4 matching Marina's curated set → **A2/A3 NOT NEEDED**; Worker implements A1 only.
- If A1 yields > 4 → A2 needed; Worker tests A2 next.
- If A1 yields < 4 (false negatives) → **STOP, escalation** — A1 doesn't reproduce Marina's selection; rule needs re-examination.

Worker reports A1-alone count в HANDOFF BEFORE proceeding.

### Stage 1 — Filter implementation

In `services/api-python/app/pdf/directions.py` (NEW file — directions presentation logic doesn't yet have dedicated module; Worker decides naming):

```python
def is_marina_significant_direction(
    direction: dict[str, Any],
    natal_chart: dict[str, Any],
    *,
    emit_set: list[dict[str, Any]] | None = None,
) -> bool:
    """Per Phase 9.1 spec: filter directions to Marina-significant subset.
    
    Rule A1 (deterministic, Marina verbatim from calibrated PDFs):
      direction.directed ∈ S OR direction.target ∈ S
      where S = {Asc, MC, 1st-house planets, Asc-ruler, Moon-fallback}.
    
    Rule A2 (Worker supplement, applied iff A1 alone over-includes):
      ...
    
    Rule A3 (Worker supplement, applied iff A2 over-includes):
      ...
    """
```

If Stage 0 shows A1 alone is sufficient — implement A1 only; **omit A2/A3 entirely** (don't add code for unused rules).

### Stage 2 — Template wiring

In `services/api-python/app/pdf/templates/solar.html.j2` directions section (lines 440-475 per TASK `directions-show-all-active` 2026-05-16):
- Inject filter call to `is_marina_significant_direction(d, facts.natal_chart, emit_set=all_active)` per direction in the `for` loop.
- Skip non-significant directions.

OR: helper applied in builder.py — `filter_marina_significant_directions(directions, natal_chart)` returning filtered list, passed to template.

Worker decides cleaner approach.

### Stage 3 — Regression test

Add `services/api-python/tests/test_directions_filter.py` (NEW):

- **Test 1 — Ольга consultation 11:** Load fixture (or live render API endpoint). Apply filter. Assert filtered list contains EXACTLY 4 directions matching Marina:
  - `MC 90° Asc`.
  - `MC 120° Уран`.
  - `Солнце 60° Asc`.
  - `Сатурн 150° Марс`.
  - (no others; no «Луна 90 Солнце», «Сатурн 90 Луна», «Нептун 150 Марс», «Нептун 150 Луна», «Плутон 150 Марс»).

- **Test 2 — Calibrated cases preserved:** For each of 9 calibrated cases, apply filter; assert filtered set matches Marina's curated set (as documented in Phase 9.0 memo § 1.1).

- **Test 3 — A1 self-match contract:** Property test — every direction whose `directed` or `target` is in `S` MUST be selected; every direction outside MUST be excluded (regardless of A2/A3 effects).

### Stage 4 — Smoke на consultation 11

After Stage 1-3 commits:
- Force fresh render consultation 11 via API endpoint.
- pdftotext extraction: assert 4 directions present по списку Marina; assert 5 over-broad directions absent.

Worker reports verbatim text extract в HANDOFF.

## Files

- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2` (directions section filter wiring).
  - `services/api-python/app/pdf/builder.py` (Jinja env registration of new filter function).
  - `project-overlays/astro/STATUS_RU.md` (narrative).

- new:
  - `services/api-python/app/pdf/directions.py` (filter module).
  - `services/api-python/tests/test_directions_filter.py` (3 tests).

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures.
- `houses_visited`, `houses_from_transit_matrix`, `transit_matrix_by_month` (Phase 3/8/9.0 contracts preserved).
- `outer_cards.py` — Phase 9.2 scope.
- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` — calibrated data untouched.
- `test_directions_section.py` (TASK 2026-05-16) — sort + non-Asc/MC presence tests stay valid; do NOT remove or weaken.
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs.
- 12 future-work items audit § A.2.1.D.
- Phase 9.0 memo (archived; reference document).
- **DO NOT silently "improve" A2/A3 rules.** If A2/A3 contradict Marina's text or exclude Marina-selected directions — STOP, escalation memo.

## Acceptance

### Primary

- [ ] Stage 0: A1-alone count для Ольги reported в HANDOFF before Stage 1 implementation.
- [ ] PDF Ольги consultation 11 shows EXACTLY 4 directions matching Marina:
  - `MC 90° Asc`
  - `MC 120° Уран`
  - `Солнце 60° Asc`
  - `Сатурн 150° Марс`
- [ ] PDF Ольги does NOT contain: «Луна 90 Солнце», «Сатурн 90 Луна», «Нептун 150 Марс», «Нептун 150 Луна», «Плутон 150 Марс».
- [ ] All 9 calibrated cases bottom directions section preserved per Marina's curated set.

### Tests

- [ ] `test_directions_filter.py` 3 new tests passing.
- [ ] Pytest baseline: `(368 baseline) + 3 new tests passed + 0 xfailed + 0 failed = 371 passed + 2 skipped + 0 failed`.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `git status --short` clean for intended product changes.
- [ ] Product commit: 1 ideal (filter + template + tests). Justify split в HANDOFF if needed.
- [ ] Overlay commit: STATUS_RU + HANDOFF.
- [ ] Push backup, parity verified.

### Stage 4 Manual UI smoke

- [ ] Force fresh render consultation 11 via curl.
- [ ] pdftotext extract: 4 Marina directions present; 5 over-broad absent.

## STOP triggers

- Stage 0 A1-alone count yields < 4 (false negatives Marina-selected) → STOP, escalation, A1 rule re-examination.
- A2 implementation excludes Marina-selected direction → STOP, A2 not Marina-supported.
- A3 implementation excludes Marina-selected direction → STOP, A3 not Marina-supported.
- Filter breaks existing `test_directions_section.py` tests (TASK 2026-05-16) → STOP, regression.
- Worker tempted to introduce new heuristic beyond A1/A2/A3 → STOP, scope creep.
- Filter changes calibrated case directions output → STOP, regression (calibrated cases should already match Marina; filter should pass them through).

## Reviewer subagent — OPTIONAL (per user direction 2026-05-17)

Tier B normally has Reviewer REQUIRED, but user direction explicit: «9.1 Reviewer optional, TL inline verification достаточно».

Rationale: Rule A1 is Marina-verbatim (memo finding); scope is narrow (1 file + 1 template + 1 test); A2/A3 are STOP-gated against Marina contradiction.

If Worker prefers Reviewer pass — может spawn'нуть, не блокер.

## Context

**Mode normal + Tier B (Reviewer optional per user direction).** Worker mode: normal.

**Baseline:**
- Product main @ `aca694b` (post 3-follow-ups + Phase 9.0 memo archived).
- Overlay master @ `398eea5` (Phase 9.0 closure).
- Pytest baseline: `368 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Critical guard:** Rule A1 is **Marina's explicit verbatim rule** from calibrated PDFs (verified 8/8 calibrated cases per memo § 5.1). A2 + A3 are Worker's empirical supplements. If A2/A3 fail Marina-text validation (exclude Marina-selected directions) → STOP, do NOT silently «improve» rules.

**Cross-references:**
- Phase 9.0 memo: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` § 5.1 verdict + § 6 TASK 1 proposal.
- TASK A precedent (2026-05-16): `project-overlays/astro/TASKS/archive/2026-05-16-directions-show-all-active.md` (filter widening; this TASK narrows back per Marina rule).
- Solar PDF Ольги (script output): `/Users/ilya/Downloads/solar-11.pdf` (9 directions, pre-filter).
- Marina эталон Ольги (reference): `/Users/ilya/Downloads/Соляр 2026-2027 (1).pdf` (4 directions, curated).

**Not in scope (explicit):**
- Outer cards filter (Phase 9.2).
- Single-window narrowing (Phase 9.3).
- Summary regression tests (Phase 9.4).
- Engine changes.
- New heuristic rules beyond A1 (A2/A3 already STOP-gated against Marina text).

**Ready: yes** — flipped 2026-05-17 after user ack + 5 clarifications:

1. **Spec clean** — no new requirements.
2. **A1-alone discipline confirmed:** Stage 0 validates A1 alone first; if exactly 4 matches Marina → A2/A3 NOT coded.
3. **Moon fallback discipline (per user direction):** Moon applies ONLY if Asc-ruler not determinable (no data / missing sign / edge case). If Asc-ruler known → Moon NOT added (fallback must NOT expand selection when primary value exists). Worker codes as explicit fallback gate, not «include both» logic.
4. **Reviewer optional** confirmed (TL inline-verify acceptable).
5. **New file `services/api-python/app/pdf/directions.py`** confirmed (avoid bloating `transit_themes.py`).
