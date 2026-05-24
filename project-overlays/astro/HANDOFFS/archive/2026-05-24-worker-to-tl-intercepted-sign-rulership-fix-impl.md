# HANDOFF: worker → tl — intercepted-sign-rulership-fix (Stages 1-6 implementation)

- Status: closed
- Date: 2026-05-24
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-24-intercepted-sign-rulership-fix.md (Path 1 revised acceptance)
- Predecessor: 2026-05-24-worker-to-tl-intercepted-sign-rulership-fix.md (Stage 0 STOP gate)
- Product repo status: committed (`d43e05e` on `main`, backup pushed `732759d..d43e05e`)

## Summary

Stage 0 НЕ переисполнялся (предыдущий Worker-цикл; archived HANDOFF `e02e9b8` использован как inventory reference only). Path 1 (revise expectations to empirical) принят user'ом 2026-05-24. Worker выполнил Stages 1-6:

* **Stage 1**: `house_signs(cusps)` helper added (3 edge cases handled); `rulership_houses` extended to intercepted-aware logic.
* **Stage 2**: `target_house_set` auto-propagated through helper.
* **Stage 3**: `_OUTER_CARD_FACTS` curated → calibrated cards immune (confirmed, NOT modified per STOP trigger).
* **Stage 4**: `_useful_people_block` full rewrite (axis 1-7 cusp+intercepted + co-rulers + 1st-house planets + solar match). Legacy 5-channel preserved as `_useful_people_block_legacy` для rollback.
* **Stage 5**: 31 new tests (synthetic edge cases + Olga regression + calendar). 3 existing Натальи tests updated to reflect intercepted-aware values (diff documented below).
* **Stage 6**: All 6 calibrated cases (02/03/05/07/08/10) → `provenance=calibrated`, row 3 «Управление домами радикса» reads curated values bit-identical.

**Pytest baseline**: 673 passed + 3 skipped + 0 failed → **697 passed + 3 skipped + 0 failed** (+24 net). 0 xfailed.
**Cabal**: clean.
**Product baseline**: `732759d` → product commit `d43e05e`.

## Stage 1 — Rulership helper extension

### 1.1 `house_signs(cusps)` (new)

`services/api-python/app/pdf/rulership_houses.py:138-242` (+105 lines).

Returns `{house: {"cusp_sign", "intercepted_signs", "all_signs"}}`. For each house 1-12 walks the arc from `cusp[i]` to `cusp[(i+1)%12]` (CCW, wraps); identifies sign at lower cusp; collects signs whose 30° boundaries fit STRICTLY inside the arc.

**Edge cases handled** (3, per TASK Stage 1.2):

| Case | Test | Result |
|---|---|---|
| Wrap 0° Aries (cusp 355° Pisces → cusp 35° Taurus) | `test_house_signs_synthetic_wrap_around_zero_aries` | Aries intercepted в Дом 12 ✓ |
| Cusp at boundary (30.0° = start of Taurus) | `test_house_signs_synthetic_cusp_at_sign_boundary` | Cusp = Taurus, NO Aries-intercepted ✓ |
| Empty list (5° arc within single sign) | `test_house_signs_synthetic_empty_intercepted_in_short_arc` | Returns `[]` ✓ |

Plus defensive: `None` / wrong length → `{}`.

### 1.2 `rulership_houses` extension

Same file, lines 245-320 (preserved signature; extended logic). Per TASK § Stage 1.3:

```
planet rules house IFF planet rules ANY sign in house_signs(cusps)[h]["all_signs"]
```

`PLANET_RULES` dict (modern convention) **preserved exactly** per clarification 3 = (c). No convention ambiguity discovered.

### 1.3 Olga rulership regression (Stage 5.2 ✅)

```python
# All assertions PASS via test_intercepted_signs.py
set(rulership_houses("Mercury", olga_cusps)) == {5, 12}    # Gemini intercepted в 12
set(rulership_houses("Venus",   olga_cusps)) == {5, 12}    # Libra intercepted в 5
set(rulership_houses("Mars",    olga_cusps)) == {6, 11}    # Aries intercepted в 11
set(rulership_houses("Jupiter", olga_cusps)) == {6, 11}    # Sag intercepted в 6
# Unchanged:
set(rulership_houses("Sun",     olga_cusps)) == {3, 4}     # Leo cusps 3-4
set(rulership_houses("Moon",    olga_cusps)) == {1, 2}     # Cancer cusps 1-2
set(rulership_houses("Saturn",  olga_cusps)) == {7, 8, 9, 10}
set(rulership_houses("Uranus",  olga_cusps)) == {9, 10}
set(rulership_houses("Neptune", olga_cusps)) == {11}
set(rulership_houses("Pluto",   olga_cusps)) == {6}
```

## Stage 2 — `target_house_set` extension

Same file, lines 322-368 — docstring updated; logic auto-propagates through extended `rulership_houses`. Asc/MC special cases preserved.

Olga calendar «Дома цели» now includes:
* Mercury → +Дом 12 (Gemini intercepted)
* Venus → +Дом 5 (Libra intercepted)
* Mars → +Дом 11 (Aries intercepted)
* Jupiter → +Дом 6 (Sag intercepted)

## Stage 3 — Outer cards investigation (CALIBRATED IMMUNITY CONFIRMED)

**Path inspection (`outer_cards.py`):**

* **Generic path** (`_build_generic_card`, line 1879): `transit_ruled_houses = rulership_houses(tp, cusps)` / `target_ruled_houses = rulership_houses(tgt, cusps)` → **auto-updates** with new helper. For Olga consultation 12 (`case_label=None`, generic-fallback): Venus row3 = `5, 12 дома`, Jupiter row3 = `6, 11 дома`. Confirmed via direct render of all 6 Olga outer cards.
* **Calibrated path** (`build_outer_card`, line 1193): row 3 reads `facts.get("transit_ruled_houses")` / `facts.get("target_ruled_houses")` from hand-curated `_OUTER_CARD_FACTS` dict (line 503). **NO `rulership_houses` call in this branch.** Helper change has zero effect on calibrated cards.

**`_OUTER_CARD_FACTS` UNTOUCHED** per STOP trigger directive.

**Calibrated 6-case verification (Stage 6 ✅):**

| Case | ncards | provenance | row 3 source |
|---|---|---|---|
| 02-maksim-2025-2026 | 2 | calibrated | curated (`{1, 5, 6}` for target Pluto etc.) |
| 03-artem-2025-2026 | 9 | calibrated | curated |
| 05-ekaterina-2025-2026 | 3 | calibrated | curated |
| 07-mariya-2025-2026 | 0 | (calibrated empty) | n/a |
| 08-natalya-2025-2026 | 3 | calibrated | curated (Venus row 3 = `2, 9 дома` — Marina golden-rule) |
| 10-danila-2025-2026 | 3 | calibrated | curated |

0 calibrated regression.

## Stage 4 — `_useful_people_block` full rewrite

`services/api-python/app/pdf/synthesis_themes.py:1497-1683` (~190 lines new logic; +130 lines net).

### Architecture

New block reads:
1. `house_signs(cusps)[1]["all_signs"]` — Дом 1 cusp + intercepted.
2. `house_signs(cusps)[7]["all_signs"]` — Дом 7 cusp + intercepted.
3. Co-rulers of Дом 1 / Дом 7 — planets ruling any sign in those houses (via `PLANET_RULES` walk; results not used in current sentence composition but available для future expansion).
4. `_natal_first_house_planets` — reused existing helper.
5. Natal Sun sign cross-check — emits «солнечные {sign}» phrase IFF Sun is in axis 1-7 signs (ensures phrase is evidence-based, NOT generic).

### Olga production output (verbatim from rendered PDF, consultation 12)

```
Вам опорно рядом Раки — люди вашей собственной оси, через которых год
даёт опору и понятный контур.
По партнёрской оси — Козероги: люди структурные, договороспособные,
готовые разделять ответственность.
Также в этом году хорошо рядом — люди с яркой марсианской инициативой
и готовностью действовать; и солнечные Раки по той же оси.
```

* **Required phrases present**: Раки ✓ (Cancer Asc), Козероги ✓ (Capricorn Дом 7), договороспособные ✓, структурные ✓, ответственность ✓, марсианской ✓ (Mars в Дом 1), солнечные Раки ✓ (Sun in axis).
* **Forbidden phrases absent**: no Овны / Львы / Скорпион / Тельцы / «солнечное присутствие» / «меркурианская лёгкость» ✓.

### Legacy preserved

`_useful_people_block_legacy` (line 1660+) preserves the 5-channel algorithm verbatim for rollback / regression comparison. NOT called in production path. `summary_table` calls only the new `_useful_people_block`.

## Stage 5 — Tests (31 new + 3 updated)

### 5.1 — Synthetic rulership tests

`services/api-python/tests/test_intercepted_signs.py` (NEW, +330 lines, 25 tests):

* 11 `house_signs` tests (Olga 4 intercepted houses + Olga angular houses + 5 synthetic edges + defensive).
* 5 `rulership_houses` Olga regression tests (Mercury / Venus / Mars / Jupiter / unaffected planets).
* 6 `target_house_set` Olga regression tests (Mercury / Venus / Mars / Jupiter / Neptune unchanged / Asc/MC special cases).
* 3 invariant tests (determinism / sort / dedup).

### 5.2 — Olga regression

Covered via 5.1; canonical Olga cusps imported from HANDOFF `e02e9b8`.

### 5.3 — Calendar tests

Covered via 5.1 `test_olga_target_house_set_*` tests (Mercury/Venus/Mars/Jupiter include intercepted; Neptune unchanged; Asc/MC `[1]`/`[10]`).

### 5.4 — Useful people Olga assertions

`tests/test_consultation_summary_evidence.py::test_olga_useful_people_block_present` rewritten to Path 1 acceptance:

* Required: Раки + Козероги + солнечные Раки + марсианск*.
* Forbidden: Овны / Львы / Скорпион / Тельцы / солнечное присутствие / меркурианская лёгкость.

Also extended `_olga_facts_extended()` fixture to include real DB cusps (was only ascendant / mc longitudes — necessary for the new helper's intercepted-aware logic).

### 5.5 — Natalya regression diff (DOCUMENTED)

Натальи's natal chart has 2 intercepted signs:
* Дом 3: Scorpio intercepted (arc cusp 3 ≈ 29°48' Libra → cusp 4 ≈ 5°23' Sagittarius)
* Дом 9: Taurus intercepted (arc cusp 9 ≈ 29°48' Aries → cusp 10 ≈ 5°23' Gemini)

This causes 3 raw `rulership_houses` values to expand vs cusp-only convention:

| Planet | Old (cusp-only) | New (intercepted) | Diff |
|---|---|---|---|
| Venus | `[2, 3]` | `[2, 3, 9]` | +9 (Taurus intercepted в 9) |
| Mars | `[8, 9]` | `[3, 8, 9]` | +3 (Scorpio intercepted в 3) |
| Pluto | `[]` | `[3]` | +3 (Scorpio intercepted в 3) |

**`target_house_set` impact**: Marina's reference shows `Venus → {2, 3, 12}` and `Mars → {3, 8, 9}` (calendar pp. 22-23).

* Venus: new union = `{2, 3, 9, 12}` — **diverges from Marina's `{2, 3, 12}` by +9**.
* Mars: new union = `{3, 8, 9}` — **identical to Marina** (placement-3 dedups with new Scorpio-intercepted-3).

The Venus diff is documented and the existing test `test_natalya_target_house_set_venus_matches_marina` updated to `[2, 3, 9, 12]`. Reviewer must judge: does Marina's reference systematically exclude intercepted signs (in which case Path 1 produces a stricter superset; conceptually still correct per modern astrology), or did Marina simply not editorially highlight Дом 9 in this case?

This is the kind of substantive diff the TASK § Stage 6 directive expects: "Worker documents diff в HANDOFF". User direction will determine whether to keep or reverse for this specific case.

**Other calibrated cases — rulership_houses diffs (all expand-only, no narrowing):**

| Case | Planets with new rulership houses |
|---|---|
| 02-maksim | Sun +9, Uranus +3 |
| 03-artem | Mercury +12, Venus +5, Mars +11, Jupiter +6 (same intercepted pattern as Olga — Cancer Asc) |
| 05-ekaterina | Mercury +7, Jupiter +1, Neptune +1 |
| 07-mariya | (none — no intercepted signs) |
| 08-natalya | Venus +9, Mars +3, Pluto +3 (documented above) |
| 10-danila | Mercury +9, Jupiter +3, Neptune +3 |

**Important**: NONE of these diffs propagate to calibrated outer-card PDF output because `_OUTER_CARD_FACTS` is curated (Stage 3 confirmation). They only affect:
1. Calendar «Дома цели» tail (via `target_house_set`).
2. Generic-fallback outer-card row 3 (only for non-calibrated cases like Olga consultation 12).
3. `_useful_people_block` for axis 1-7 sign extraction.

## Verification

* `cabal --project-dir core/astrology-hs build` → clean.
* `pytest --tb=no -q` → **697 passed, 3 skipped, 0 failed** (was 673/3/0; +24 net new tests; 0 regression in existing passing tests except Натальи docstring-pinned values updated per Stage 5.5 above).
* Olga PDF rendered fresh (`/tmp/olga-12-render.html`, 158 564 bytes):
  - «Полезные люди» section: required phrases present, forbidden absent (verbatim quoted above).
  - 6 outer cards (generic-fallback) include intercepted-sign co-rulerships in row 3:
    - тр Уран ☐ Венера: target_ruled = `5, 12 дома` (intercepted Libra в 5)
    - тр Уран ⚹ Юпитер: target_ruled = `6, 11 дома` (intercepted Sag в 6)
    - тр Нептун △ Юпитер: target_ruled = `6, 11 дома`
    - тр Нептун △ Уран: target_ruled = `9, 10 дома` (Saturn-domain, unchanged)
    - тр Плутон ⚹ Уран: target_ruled = `9, 10 дома`
* `git status --short` → clean (intended changes committed).

## STOP triggers (per TASK § STOP triggers)

* Worker fabricates signs/houses → **NOT FIRED** (all values empirical-derived).
* Worker touches Haskell core / engine / schema → **NOT FIRED** (zero core changes).
* Worker modifies `_OUTER_CARD_FACTS` → **NOT FIRED** (untouched).
* Worker fabricates Useful people Scorpio/Taurus axis → **NOT FIRED** (axis Cancer-Capricorn per empirical natal cusps).
* Worker copies Daragan verbatim → **NOT FIRED** (compositional Russian generated from helper + dict lookups; phrases like «опора через близких», «структурные партнёрства» are Worker-composed, no Daragan).
* Worker introduces LLM → **NOT FIRED**.
* Worker breaks meeting_place invariant → **NOT FIRED** (no consultation plumbing touched).
* Worker breaks existing calibrated outer-card tests → **NOT FIRED** (all 6 cases preserve `provenance=calibrated` with curated row 3 values; 342 calibrated-related tests pass).

## Self-review checklist

- [x] Stage 0 NOT re-executed (referenced archived HANDOFF `e02e9b8`).
- [x] `house_signs` handles all 3 edge cases (wrap / boundary / empty).
- [x] Olga rulership: Mercury {5,12}, Venus {5,12}, Mars {6,11}, Jupiter {6,11}; other planets unchanged.
- [x] Useful people: Cancer + Capricorn + Mars present; Aries/Leo/Scorpio/Taurus + vague phrases absent.
- [x] `_OUTER_CARD_FACTS` UNTOUCHED.
- [x] Calibrated 6 cases: 0 regression in `_OUTER_CARD_FACTS`-driven PDF output. Натальи helper-level diff documented (3 expansions); only Venus's `target_house_set` diverges from Marina's reference by +9 (other cases auto-dedup via placement).
- [x] pytest 697 passed (>= 673 + 24 new). 0 failed.
- [x] cabal clean.
- [x] No engine touch, no DB schema, no LLM, no Daragan verbatim, no fabrication.
- [x] Reviewer REQUIRED noted in HANDOFF status (this section).

## Artifacts

- branch:           main (product) / master (overlay)
- product commit:   `d43e05e` (this implementation)
  - Predecessor:    `732759d` (Solar Planets House Distribution CLOSED)
- overlay commit:   (created in same submit)
- PR:               (none — direct main, per repo convention)
- tests:            pytest **697 passed + 3 skipped + 0 failed** (+24 new)
- Files product:
  * `services/api-python/app/pdf/rulership_houses.py` — +148/-50 (house_signs, rulership_houses extension, target_house_set docstring)
  * `services/api-python/app/pdf/synthesis_themes.py` — +190/-75 (useful_people rewrite + legacy preserved + cusps helper)
  * `services/api-python/tests/test_intercepted_signs.py` — NEW +331
  * `services/api-python/tests/test_consultation_summary_evidence.py` — +35/-24 (fixture cusps + Olga useful-people assertions Path 1)
  * `services/api-python/tests/test_rulership_houses.py` — +35/-15 (Натальи Venus/Mars docstring + values updated per intercepted-aware behaviour)

## Reviewer-Ready

**Reviewer REQUIRED** per user direction 2026-05-24 (`ae055ad`): «Reviewer REQUIRED. This touches astrology semantics, not just text.»

External Reviewer должен independently confirm:
1. `house_signs` synthetic fixture correctness (4+ intercepted-sign edge cases).
2. Olga empirical match: Mercury/Venus/Mars/Jupiter rulership matches Path 1 (Stage 0 archived inventory).
3. Useful people Olga acceptance: required phrases present, forbidden absent in rendered PDF.
4. Натальи Venus diff: judge whether Marina's reference systematically excludes intercepted signs (potentially revert Natalya assertion if Reviewer/user disagrees with Path 1 logic for Натальи).
5. 0 STOP triggers fired (verified above).
6. Calibrated 6 cases: `provenance=calibrated` preserved, row 3 values unchanged (Stage 6 ✅).
7. No engine touch / no Daragan verbatim / no fabrication.

## Next step

TL spawns external Reviewer; on Reviewer APPROVE → user closure ack → submit-task.sh. On Reviewer non-blocking comments → TL decision; on Reviewer blocking issue → Worker re-engage with delta scope.
