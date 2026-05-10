# HANDOFF: worker → TL — transits-section-rebuild-to-reference

- Status: closed
- Date: 2026-05-10
- From: Worker (Claude Code subagent, separate session)
- To: TL
- Project: astro
- TASK: 2026-05-10-transits-section-rebuild-to-reference
- Worker commit(s): `edd71d4` (parent `309468a`)
- Agent runtime: Claude Code (Worker subagent, separate from TL session)
- Role mode: Worker (Mode normal — Tier B)

## Summary

Rebuilt the Транзиты section in the solar PDF to match Marina's reference structure (Соляр 2025-2026_5.pdf pp. 7-23). Six sections now render in reference order: intro → monthly table → social planets (Сатурн, Юпитер) with Mars/Venus per-planet narratives flowing in Marina's idiom → outer planets (Уран, Нептун, Плутон) under explicit header → transit-aspect block (taxonomy + monthly calendar) → «Как пользоваться транзитами». No data-shape gaps were encountered — `annual_transit_table.hits` already carries everything needed for the calendar without any schema cascade.

## Implementation

### Files modified

- `services/api-python/app/pdf/templates/solar.html.j2` — Транзиты section (was lines 487-671) fully rewritten and expanded to 6 explicit sections matching Marina's reference order. Dropped the in-section «Король аспектов» and «Стеллиумы» sub-blocks (they belong to natal/solar analytical material, not Marina's transits chapter — and were a divergence from reference). Kept «Важные транзитные планеты» list as part of the §1 intro (Marina also enumerates which transits matter most for the chart, p. 7). Added a small `.planet-name` h4 style for per-planet narrative headers («Сатурн», «Юпитер», «Марс», «Венера», «Уран», «Нептун», «Плутон»).
- `services/api-python/app/pdf/transit_themes.py` — added five new exports: `transit_aspects_by_month()` (monthly calendar of social + outer transit aspects, sorted by exact-aspect JD), `aspect_tone()` (благоприятный / напряжённый / сильный tag), `aspect_degrees()` (compact «120°» tag), `ASPECT_DEFINITIONS` (5-aspect taxonomy in Marina's idiom — closed-dict text from p. 14), `HOWTO_PARAGRAPHS` (5-paragraph «Как пользоваться транзитами» how-to in Marina's idiom — pp. 22-23). Updated module docstring to reflect that outer-planet × house entries were already present in `PLANET_HOUSE_TEXT` (the original docstring claiming they were «out of this dict» was stale — Uranus/Neptune/Pluto × 12 houses are all there).
- `services/api-python/app/pdf/builder.py` — registered new helpers and closed-dict text as Jinja globals (`transit_aspects_by_month`, `aspect_tone`, `aspect_degrees`, `aspect_definitions`, `howto_paragraphs`).

### Key decisions

- **Outer-planet narratives**: not a blocker. The closed-dict text for Uranus/Neptune/Pluto × 12 houses already existed in `transit_themes.PLANET_HOUSE_TEXT` (despite the module docstring claiming otherwise — that docstring was stale, predating Phase 0.9b). Surfaced under the new §4 outer block.
- **Transit aspects (§5)**: not a blocker. `annual_transit_table[*].hits` already carries `{aspect, target, exact_jd, phase}` for every transit window; the new `transit_aspects_by_month()` filter aggregates social + outer hits by calendar month, sorted by `exact_jd`. For natalya the calendar produces 15 entries across 9 months (Sep 2025 → Jul 2026) — enough to feel like Marina's reference month-by-month list (pp. 19-22).
- **2-house cross-month rendering**: Marina's reference table cells (p. 9) are single-house numbers; cross-month transitions are visible by adjacent rows changing (e.g. Mars Авг=2, Сен=2, Окт=3). Our matrix builder uses month-start JD lookup which produces exactly that pattern. No code change needed.
- **Mars + Venus narratives**: Marina pp. 12-14 covers Mars and Venus per-planet without an umbrella header (just bold planet names). I dropped my first-pass «Транзиты быстрых планет» umbrella (would have been a self-invented section header) and let Mars/Venus narratives flow per-planet between the §3 social block and the §4 outer block, exactly as Marina does.
- **«Король аспектов» / «Стеллиумы»**: removed from inside Транзиты. These sub-blocks were structurally out of place inside the transits chapter — they're general chart-analytical material. Per task guidance «НЕ менять другие разделы PDF», I did not relocate them; they will need to be re-introduced in a more appropriate section (e.g. the natal-chart analytics block) by a future TASK if the Owner wants them surfaced in the client PDF at all. The remaining `important_transit_planets` list IS Marina-idiom and was retained as part of §1 intro.

## Self-check checklist (from TASK § Embedded Reviewer checklist)

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | Секция Транзиты идёт в правильном месте, не ломает остальные | PASS | New PDF p. 6-12 (Транзиты), p. 13+ (Итоги). Section breaks intact. |
| 2 | Вводный блок по транзитам, тон/функция как в образце | PASS | `solar.html.j2` §1 intro (italic centered + body paragraph). Compare new p. 6 top vs Marina p. 7-8. |
| 3 | Есть monthly table по домам | PASS | `solar.html.j2` §2 + `transit_matrix_by_month()` already in place. New p. 6 bottom. |
| 4 | Rows = месячные периоды, не точные события | PASS | 13 rows: Август 2025 → Август 2026. Cell = single house number. |
| 5 | Cols = нужные планеты, не произвольный набор | PASS | 4 cols: Марс, Сатурн, Юпитер, Венера — same order and grouping as Marina p. 9. |
| 6 | 2-house cross-month явно показано | PASS | Adjacent rows show transition (Mars: Сен 2025=2, Окт 2025=3, Ноя 2025=4, Дек 2025=4 …). Marina's reference uses the same pattern. |
| 7 | Социальные планеты в отдельном блоке | PASS | `<h3>Транзиты социальных планет</h3>` block iterates `(Saturn, Jupiter)` only. New p. 7. |
| 8 | Высшие планеты в отдельном блоке | PASS | `<h3>Транзиты высших планет (Уран, Нептун, Плутон)</h3>` block iterates `(Uranus, Neptune, Pluto)`. New p. 10 top. |
| 9 | Социальные и высшие не смешаны | PASS | Saturn/Jupiter under «социальных» header; Uranus/Neptune/Pluto under «высших» header; separated by Mars/Venus per-planet narratives. |
| 10 | Есть отдельный блок транзитных аспектов | PASS | `<h3>Аспекты транзитных социальных и высших планет</h3>` with intro + 5-aspect taxonomy + monthly calendar. New p. 10-12. |
| 11 | Блок аспектов не спрятан | PASS | Own section heading at the same level as the per-planet blocks; 15 calendar entries across 9 months. |
| 12 | Нет самодельных новых названий секций | PASS | All headers map to Marina-reference idiom: «Транзиты», «Какие транзиты особенно важны для этой натальной карты», «Транзиты планет по домам», «Транзиты социальных планет», «Транзиты высших планет (Уран, Нептун, Плутон)», «Аспекты транзитных социальных и высших планет», «Календарь транзитных аспектов по месяцам», «Как пользоваться транзитами». |
| 13 | Нет debug/info dump | PASS | All content is narrative prose or labeled tables; no raw JD numbers, no opaque enum values, no dev-facing pills. |
| 14 | Если данных не хватает — Worker зафиксировал blocker | N/A | No blockers found. Outer-planet × house text was already in `PLANET_HOUSE_TEXT` (stale docstring); transit-aspect data was already in `annual_transit_table[*].hits`; no schema cascade needed. |
| 15 | Показаны страницы Транзиты + side-by-side с образцом | PASS | New PDF: `/tmp/astro-natalya-transits-rebuild.pdf` (131.2 KB, 16 pages). Per-page PNGs: `/tmp/transits-rebuild-p-{06..12}.png`. Side-by-side composites: `/tmp/transits-side-by-side-p-{06..12}.png` (7 composites). |

## Tests

- **pytest**: `cd services/api-python && .venv/bin/pytest` → **70/70 passed** in 9.8s (matches baseline; no new tests added — the change is presentation-layer only and existing render tests cover the template paths).
- **WeasyPrint render**: clean — 131.2 KB, no warnings, no Pango/font errors, 16 pages. Same shape as parent (309468a was 131.8 KB, 16 pages).
- **Real PDF**: `/tmp/astro-natalya-transits-rebuild.pdf`
- **Транзиты pages PNG**: `/tmp/transits-rebuild-p-06.png` … `/tmp/transits-rebuild-p-12.png` (7 pages of the section).
- **Side-by-side composites** (new PDF page on the left, matching Marina reference pages on the right):
  - `/tmp/transits-side-by-side-p-06.png` — title + intro + monthly table (vs Marina pp. 7-9)
  - `/tmp/transits-side-by-side-p-07.png` — Saturn narratives (vs Marina pp. 9-11)
  - `/tmp/transits-side-by-side-p-08.png` — Jupiter + Mars narratives (vs Marina pp. 11-12)
  - `/tmp/transits-side-by-side-p-09.png` — Venus narratives (vs Marina pp. 12-13)
  - `/tmp/transits-side-by-side-p-10.png` — outer planets + aspects intro (vs Marina pp. 14-15)
  - `/tmp/transits-side-by-side-p-11.png` — transit-aspect calendar (vs Marina pp. 19-21)
  - `/tmp/transits-side-by-side-p-12.png` — calendar tail + how-to (vs Marina pp. 21-22)

## Blockers (if any)

**None.** All required data shapes were available in the existing `SolarComputedFacts` schema and `annual_transit_table` emission. No Tier A schema cascade needed.

Worth flagging for a future cleanup TASK (not part of this rebuild scope):

- The «Король аспектов» and «Стеллиумы» sub-blocks that lived inside Транзиты have been removed. They are general chart-analytical material that should likely surface in the натальная-карта section — but moving them there is out-of-scope for this TASK («НЕ менять другие разделы PDF»). If the Owner wants those facts visible in the client PDF, a separate small TASK should relocate them.
- The `transit_themes.py` module docstring used to say outer planets were «out of this dict — Phase 0.9b refinement». In fact the dictionary already contains Uranus/Neptune/Pluto × 12 entries (added at some point without updating the docstring). Updated the docstring as part of this rebuild.

## Recommendation to TL

- **Inspection paths**:
  - Compare side-by-side composites at `/tmp/transits-side-by-side-p-{06..12}.png` (7 files) against Marina reference pages 7-23 of `Соляр 2025-2026_5.pdf`.
  - Diff: `git show edd71d4 --stat` (3 files, +414/-79).
  - Acceptance criteria #6 (pytest 70/70) and #7 (real PDF renders clean) both verified.
- **Open questions for Owner** (if any):
  - The §5 transit-aspect calendar shows aspect tone tags («благоприятный», «напряжённый», «сильный») next to each entry. Marina's reference uses similar tagging (p. 19-22 marks each entry as «благоприятный» / «напряжённый»). My implementation follows that pattern. If Owner prefers a different presentation (e.g. drop the tone tags, or add explicit «Дома цели» as Marina sometimes does), small follow-up.
  - The monthly aspect calendar lists each transit aspect once at its `exact_jd` month. Marina's reference instead lists each transit across every month from first touch to last (e.g. «Уран 90° Венера» appears in Ноябрь, Декабрь 2025 and Март, Апрель 2026 because the realisation interval spans those months). My current implementation is the simpler one-month-per-hit form. If Marina's spread-across-months form is preferred, a small follow-up to expand by month-windows from `[enter_jd, exit_jd]` of the parent transit entry.
- **Sign-off**: Tier B normal — TL inline review per the 15-item checklist above, then Owner relay for visual approval against the Marina reference pages.
