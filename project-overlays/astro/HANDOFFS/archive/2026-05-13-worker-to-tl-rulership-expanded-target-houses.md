# HANDOFF: worker → tl — rulership-expanded-target-houses

- Status: closed
- Date: 2026-05-13 15:11
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-rulership-expanded-target-houses.md

## Summary

Phase 5 closed: presentation-level Python helper landed (Path B), calendar `Дома цели` now surface placement ∪ rulership houses per Marina pp. 22-23 oracle. 4 xfails flipped, 26 new helper unit tests added. `outer_cards.py` untouched per TASK Do-not-touch list. One atomic commit; `cabal build` clean; tests `145 passed + 4 xfailed + 0 failed`.

## Done

### Path decision (Path B)

Chose Path B (presentation-only Python helper). Rationale (per TASK § "Worker decision criteria"):

1. **No Frontend / API consumers** for rulership houses through JSON contract — Phase 5 scope is calendar-only, and Frontend does not surface calendar `Дома цели` at the data level.
2. **Single consumer per TASK § Do not touch** — only `transit_aspects_by_month` (calendar context) needs this logic. Phase 4 `outer_cards.py` uses **closed card-facts per case_id** for golden-rule semantic (different from calendar semantic — calendar = placement ∪ rulership; golden-rule = ruled only). Path A would create avoidable Tier-A cascade pressure without adding shared-helper benefit.
3. **Marina convention** is **modern rulership** (Архипова Phase 0.4 lock-in): Sun→{Leo}, Moon→{Cancer}, Mercury→{Gemini, Virgo}, Venus→{Taurus, Libra}, Mars→{Aries, Scorpio}, Jupiter→{Sagittarius, Pisces}, Saturn→{Capricorn, Aquarius}, Uranus→{Aquarius}, Neptune→{Pisces}, Pluto→{Scorpio}. Closed dict in Python is the lightest-weight expression.
4. **Engine output stable** — no schema change, no fixture regen, no Haskell core delta. Tier C / Mode normal preserved. Schema cascade gate (bright line #8) not crossed.
5. **Reversibility** — if Phase 7 calibration surfaces inconsistency between calendar semantic and outer-cards golden-rule semantic across more cases, the helper can graduate to a shared `Domain/RulershipHouses` Haskell module via a focused Tier-A TASK. Path B keeps the option open at lower cost.

### Cusp validation report (Натальи vs TL spec)

Validated `natal_chart["house_systems"]["Placidus"]["cusps"]` from `08-natalya-2025-2026.expected.json` (12 longitudes), confirmed against TL spec sign mapping:

| Cusp | Longitude | Sign | TL spec match |
|---|---|---|---|
| 1 (Asc) | 162.3695° | 12°22' Virgo | yes |
| 2 | 182.6597° | **2°39' Libra** | sign yes; minute differs (TL spec listed 4°46') |
| 3 | 209.8121° | **29°48' Libra** (repeated) | yes |
| 4 (IC) | 245.3967° | 5°23' Sagittarius | yes |
| 5 | 284.7895° | 14°47' Capricorn | yes |
| 6 | 317.2453° | 17°14' Aquarius | yes |
| 7 (Dsc) | 342.3695° | 12°22' Pisces | yes |
| 8 | 2.6597° | **2°39' Aries** | yes |
| 9 | 29.8121° | **29°48' Aries** (repeated, **not Taurus**) | yes — critical regression guard |
| 10 (MC) | 65.3967° | 5°23' Gemini | yes |
| 11 | 104.7895° | 14°47' Cancer | yes |
| 12 | 137.2453° | 17°14' Leo | yes |

Sign-on-cusp mapping matches TL spec across all 12 cusps. **Cusp 9 = 29°48' Aries** confirmed — Mars rulership houses correctly include both h8 and h9 (the regression guard for Marina oracle `{3, 8, 9}`). Cusp 2 minor calibration note: TL spec text said `4°46' Libra` but fixture has `2°39' Libra`. The **sign** is Libra in both, so it does not affect any computation. Treated as a transcription detail in the TASK spec, not a fixture issue.

### Per-file diff overview (3 modify + 2 new)

* **new** `services/api-python/app/pdf/rulership_houses.py` (~210 lines, mostly docstring):
  * `PLANET_RULES: dict[str, set[str]]` — 10-planet closed dict (modern convention).
  * `cusp_sign(longitude) → str` — 30°-bucket mapping with negative + 360° wrap.
  * `rulership_houses(planet, natal_cusps) → list[int]` — walks 12 cusps, returns houses whose cusp's sign is ruled, **includes repeated cusps**.
  * `target_house_set(target, natal_chart) → list[int]` — sorted, deduplicated `{placement_house}` ∪ `rulership_houses(target, cusps)`. Asc → `[1]`, MC → `[10]`. Cusps path: `natal_chart["house_systems"]["Placidus"]["cusps"]`.
* **modify** `services/api-python/app/pdf/transit_themes.py` (+92 / -8):
  * Import `target_house_set` as `_target_house_set`.
  * Add `natal_chart: dict | None = None` kwarg to `transit_aspects_by_month` (back-compat: when omitted, legacy placement-only path runs).
  * New helper `_format_target_house_label(houses)` builds Marina-style "N — label; M — label" preformatted string from a list.
  * Each calendar entry gains new keys: `target_house_set` (list), `placement_house` (int), `rulership_houses` (list excluding placement to avoid double-counting). Legacy `target_house` (singular int) retained for back-compat (= placement_house). `target_house_label` now multi-house preformatted string.
* **modify** `services/api-python/app/pdf/templates/solar.html.j2` (+9 / -4, ≤ 30-line budget):
  * Calendar block passes `natal_chart=facts.natal_chart` kwarg to `transit_aspects_by_month`.
  * Multi-house render: drops the `{{ e.target_house }} — ` prefix (label is now preformatted), keeps the single `{% if e.target_house_label %}` guard. Option (b) chosen per TASK § "Files modify template" — formatter returns full preformatted string; reduces template branching.
* **modify** `services/api-python/tests/test_natalya_transits_acceptance.py` (+17 / -39):
  * `_calendar_entries` helper now passes `natal_chart=facts["natal_chart"]` (required for new helper output).
  * 4 xfail decorators removed (3 Cat 6 + 1 Cat 7 regression ban). Docstrings updated to "flipped from xfail to passing" wording per Phase 3/4 pattern.
* **new** `services/api-python/tests/test_rulership_houses.py` (26 tests):
  * `PLANET_RULES` shape + every planet's ruled signs + every sign covered.
  * `cusp_sign` boundary behaviour: 0°, 29.9° (still Aries), 30° (next sign), 360° wrap, negative wrap, full 12-sign walk; **direct regression guard for Натальи cusp 9 = 29.812° Aries**.
  * Натальи sign-on-cusp mapping vs TL spec (12-cell golden assertion).
  * `rulership_houses` per Натальи: Venus={2,3}, Mars={8,9}, Jupiter={4,7}, Neptune={7}. Defensive: unknown planet/None/empty cusps → [].
  * `target_house_set` per Натальи: Venus=[2,3,12], Mars=[3,8,9], Jupiter=[4,7], Neptune=[4,7] — **Marina calendar oracle directly**. Asc=[1], MC=[10]. Robustness: None / empty natal_chart → [].

`outer_cards.py` is **not** in the diff. Verified via `git diff --stat`:

```
services/api-python/app/pdf/rulership_houses.py    | (new, +210)
services/api-python/app/pdf/templates/solar.html.j2 | +9 -4
services/api-python/app/pdf/transit_themes.py      | +92 -8
services/api-python/tests/test_natalya_transits_acceptance.py | +17 -39
services/api-python/tests/test_rulership_houses.py | (new, +280)
```

### Calendar oracle validation (4 Натальи targets)

Helper output vs Marina pp. 22-23 oracle (validated via unit tests + PDF extracted text):

| Target | Computed `target_house_set` | Marina oracle | Match |
|---|---|---|---|
| Venus | `[2, 3, 12]` | `{2, 3, 12}` | yes |
| Mars | `[3, 8, 9]` | `{3, 8, 9}` | yes |
| Jupiter | `[4, 7]` | `{4, 7}` | yes |
| Neptune | `[4, 7]` | `{4, 7}` | yes |

### xfail flip status

4 unmarked (per TASK § Test contract):

* `test_target_houses_not_placement_only_for_multi_house_targets` — Cat 6 Phase 5.
* `test_uranus_square_venus_target_houses_match_marina_reference` — Cat 6 Phase 5.
* `test_target_houses_distinguish_placement_from_rulership` — Cat 6 Phase 5.
* `test_target_houses_no_placement_only_regression` — Cat 7 regression ban.

Phase 4b Neptune Cat 4 xfails not touched. Phase 6 calendar clipping xfails (4) remain.

### Visual PDF verification

`python scripts/render_natalya.py --output /tmp/natalya-phase5.pdf` succeeded against current main (`1d59431`).

Extracted text confirms multi-house render in calendar block:

* `Уран 90° Венера (напряжённый) — 02.11.2025–22.12.2025 → Дома цели: 2 — деньги/ресурсы; 3 — общение/поездки/документы/курсы; 12 — уединение/тайны.`
* `Нептун 90° Юпитер (напряжённый) — 21.04.2026–28.09.2026 → Дома цели: 4 — семья/недвижимость; 7 — партнёрство.`
* `Нептун 90° Нептун (напряжённый) — 24.10.2025–24.01.2026 → Дома цели: 4 — семья/недвижимость; 7 — партнёрство.`
* `Юпитер 120° Марс (благоприятный) — 12.10.2025–11.12.2025 → Дома цели: 3 — общение/поездки/документы/курсы; 8 — кризисы/кредиты/интим; 9 — вера/обучение/путешествия.`
* `Сатурн 120° Марс (благоприятный) — 03.11.2025–22.12.2025 → Дома цели: 3 — общение/поездки/документы/курсы; 8 — кризисы/кредиты/интим; 9 — вера/обучение/путешествия.`

All four Marina oracle entries render exactly as expected; Уран 150° Юпитер calendar row also surfaces `{4, 7}` (consistent with Jupiter rulership).

## Remaining

Phase 5 fully closed for case-08 Натальи. Open follow-ups (separate TASKs, not part of this HANDOFF):

* **Phase 6** — per-context cutoff policy (calendar clipping to solar-year end; 4 Cat 5 xfails remain).
* **Phase 7** — multi-case calibration (default cases `05-ekaterina`, `07-mariya`, `10-danila` or TL-chosen set; verify helper holds across additional natal charts).

## Artifacts

- branch:               main
- commit(s):            1d59431 (Phase 5: rulership-expanded target houses)
- PR:                   n/a (direct main commit per Tier C convention)
- tests:                145 passed + 4 xfailed + 0 failed (baseline was 115 + 8 xfailed). Delta: +30 (4 Phase 5 flips + 26 new helper unit tests).
- Product repo status:  committed

`cabal build` (Phase 2 lesson) — `Up to date` (no Haskell touched).
`git status --short` clean for intended product changes; only untracked `.claude/scheduled_tasks.lock` (unrelated tooling lockfile).
`git push backup main` — `d44d7c6..1d59431  main -> main` (clean fast-forward).

## Conflicts / risks

None identified. Highlights for TL inline verification:

1. **outer_cards.py untouched** — verified via `git diff --stat` and per `git show 1d59431 --stat`. Phase 4 closed baseline intact.
2. **Cusp 2 minute discrepancy** between TL spec text (`4°46' Libra`) and fixture (`2°39' Libra`). Sign is Libra in both; helper computation unaffected; flagging only for spec-text accuracy if relevant for future calibration.
3. **Back-compat surface preserved** — `transit_aspects_by_month` legacy positional/kwarg calling form (without `natal_chart`) still works; existing test `test_calendar_target_house_resolved_from_natal` in `test_transit_aspects_tables.py` still passes because legacy `target_house` (= `placement_house`) keeps its singular int semantic. Only behaviour change visible to legacy callers: `target_house_label` is now a multi-house preformatted string when `natal_chart` is supplied; legacy callers that pass no `natal_chart` keep getting single-house labels.
4. **Schema not touched** — `packages/contracts/*.schema.json` and `packages/test-fixtures/` are byte-identical to baseline.

## Next step

TL inline-verifies:

* Cross-check `target_house_set` output for Венера/Юпитер/Нептун/Марс against Marina pp. 22-23 (already done above; numbers match).
* Verify PDF calendar lines show multi-house labels (already confirmed via extracted text in this HANDOFF; TL may open `/tmp/natalya-phase5.pdf` if desired).
* Accept Phase 5 → open TASK 6 (per-context cutoff policy) per § 8 in architecture document.
