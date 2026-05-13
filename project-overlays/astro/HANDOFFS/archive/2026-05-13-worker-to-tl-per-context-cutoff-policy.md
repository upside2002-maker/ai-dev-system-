# HANDOFF: worker → tl — per-context-cutoff-policy

- Status: closed
- Date: 2026-05-13 16:50
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-per-context-cutoff-policy.md

## Summary

Phase 6 (per-context cutoff policy) closed. Calendar `transit_aspects_by_month`
теперь enforce'ает strict clipping `[sr_jd, sr_jd + 365.25]` через two-window-
pair architecture (actual_* для internal ops, calendar_* для presentation).
Outer cards intact (Phase 4 boundary not crossed). 4 Phase 6 Cat 5 xfails →
passing. Pytest 145/4/0 → 149 passed / 0 xfailed / 0 failed. Программа Transit
Section Recovery готова к Phase 7 (multi-case calibration).

## Done

### Per-file diff overview

- **`services/api-python/app/pdf/transit_themes.py`** (+159 / −53 lines в
  `transit_aspects_by_month`):
  - Two window pairs введены: `actual_start_jd` / `actual_end_jd` (raw
    engine bounds) + `calendar_start_jd` / `calendar_end_jd` (clipped).
  - **actual_*** используются для:
    - dedup key (`(tp, tgt, asp, int(round(actual_start_jd)))`) — clipping
      перед dedup схлопывал бы все long-loop windows стартующие до sr_jd
      на одной точке;
    - `_MIN_WINDOW_DAYS = 7` filter (`actual_end - actual_start`) — long-loop
      hit нарезанный solar year'ом до 3-дневного stub'а сохраняет
      validity как realisation interval;
    - quincunx display filter (peak-orb estimate на real window duration);
    - early drop "strictly outside solar year".
  - **calendar_*** используются для:
    - `period_start_str` / `period_end_str` (presentation strings);
    - per-entry `orb_enter_jd` / `orb_exit_jd` (semantic shift — см.
      ниже);
    - bucket assignment via `_months_between(calendar_start_jd,
      calendar_end_jd)` — clipped slice не leak'ает в month bucket'ы вне
      solar year.
  - Row drop rule: `if calendar_start_jd >= calendar_end_jd: continue` —
    после dedup и `_MIN_WINDOW_DAYS` filter.
  - Полный docstring rewrite секции "Two window pairs" + "Calendar entry
    output semantic shift" — задокументирован contract change для
    каждого call-site и cross-ref на architecture document § 5 Phase 6 /
    § 6.

- **`services/api-python/tests/test_natalya_transits_acceptance.py`**
  (−24 / +20 lines — pure xfail removal + reason rewrite):
  - `test_calendar_neptune_square_jupiter_clipped_to_solar_year_end` —
    unmark.
  - `test_calendar_uranus_conjunction_mc_clipped_to_solar_year_end` —
    unmark.
  - `test_calendar_no_rows_outside_solar_year_span` — unmark.
  - `test_calendar_period_start_clipped_to_solar_year_start` — unmark.
  - Comments updated в каждом тесте: "Phase 6 (per-context cutoff,
    2026-05-13) flipped this from xfail to passing — ..." с описанием
    semantic shift.

- **`services/api-python/tests/test_transit_aspects_tables.py`**
  (+62 / −6 lines в одном тесте):
  - `test_calendar_short_windows_filtered` — adapted к Phase 6 semantic
    shift. Старый тест ассертил `e["orb_exit_jd"] - e["orb_enter_jd"] >=
    7d`, что после Phase 6 невалидно (calendar bounds могут clip'ать
    long-loop hit короче 7d). Новая логика:
    1. Извлекает actual durations из source
       `annual_transit_table.hits` (через rounded
       (tp, tgt, asp, day-start) join).
    2. Ассертит max actual duration `>= 7d` per `(tp, tgt, asp)` triple
       (т.е. _MIN_WINDOW_DAYS filter работает на actual side).
    3. Ассертит positive duration на calendar side (Phase 6 row drop
       guard).
    4. Ассертит `sr_jd <= orb_enter_jd <= orb_exit_jd <= sr_end_jd`
       (Phase 6 clipping bounds).

### Test contract

- Baseline (HEAD `1d59431`): 145 passed + 4 xfailed.
- После Phase 6 (HEAD `a1891cc`): **149 passed + 0 xfailed + 0 failed**.
- Delta: +4 flips (Phase 6 Cat 5) + 1 existing test updated to reflect
  Phase 6 semantic shift.
- No new test file created — existing `test_natalya_transits_acceptance.py`
  Cat 5 assertions провели full Phase 6 behavioural coverage.

### Calendar oracle validation (PDF self-verify)

`/tmp/natalya-phase6.pdf` (provenance: SHA `1d59431` — note: sidecar
зафиксирован _до_ commit `a1891cc` потому что render запущен после edit но
до commit; для нового рендера после Phase 7 SHA будет corrected). Calendar
pages 12-15 проверены через pypdf:

- `Нептун 90° Юпитер (напряжённый) — 21.04.2026–07.08.2026` ✓ matches
  Marina pp. 22-23 exactly. Engine raw end = 28.09.2026, clipped до
  07.08.2026 (sr_jd + 365.25).
- `Уран 0° MC (сильный) — 15.07.2026–07.08.2026` ✓ matches Marina pp. 22-23.
  Engine raw end = 14.11.2026, clipped.
- Calendar text (8814 chars across pages 12-15): **0 dates с suffix
  `.2024`, `.2027`, `.2028`** — clean.
- Calendar starts на `Август 2025` (sr month) и ends на `Август 2026` (sr +
  12 month). No months outside `[Aug 2025, Aug 2026]` span.
- Sample left-clip case: `Нептун 90° Нептун — 24.10.2025–24.01.2026` —
  start 24.10.2025 (engine actual, поскольку >= sr_jd ~07.08.2025).
  Phase 6 left-clip активен только для loops which begin до sr_jd; в
  case-08 ни один такой loop не survived `_MIN_WINDOW_DAYS` filter + не
  оказался полностью внутри solar year.

### Outer cards regression check

Pages 10-11 (outer cards section) проверены — full loop context
preserved:
- Уран 90° Венера card: 3 display windows incl. `03.06.2025 – 12.07.2025`,
  `02.11.2025 – 22.12.2025`, `18.03.2026 – 30.04.2026`.
- Нептун 90° Юпитер card: 3 display windows incl. `21.04.2026 – 28.09.2026`
  (extended past solar year), `21.02.2027 – 16.04.2027`, `09.10.2027 –
  30.01.2028`. ✓ Loop dates 2027/2028 присутствуют — это expected loop
  context behaviour per Phase 4.
- Нептун 90° Нептун card: 3 display windows incl. `02.04.2024 – 12.10.2024`
  (pre-solar-year), `31.01.2025 – 29.03.2025`, `24.10.2025 – 24.01.2026`.
  ✓ Loop date 2024 присутствует.

`outer_cards.aggregate_display_windows` читает `annual_transit_table.hits.orb_enter_jd`
/ `orb_exit_jd` напрямую через filter triples → grouping by `(round(enter, 3),
round(exit, 3))`. `transit_aspects_by_month` НЕ участвует в outer card
pipeline. Verified via `outer_cards.py:227-241` (find_engine_hits) + lines
`257-302` (aggregate_display_windows): zero direct dependency на calendar
clipping path.

### xfail unmark status

- Phase 6 Cat 5: 4 / 4 unmarked → passing.
- Total xfailed after Phase 6: **0** (Phase 4/5/6 contracts всё закрыты).

### Path к новому PDF Натальи

- PDF: `/tmp/natalya-phase6.pdf` (18 pages, valid extract).
- Sidecar provenance: `/tmp/natalya-phase6.pdf.provenance.json` (SHA
  `1d59431` — рендерилось до `a1891cc` commit). Рекомендую TL re-render
  с HEAD `a1891cc` для clean provenance перед Phase 7 kickoff.

## Remaining

- Phase 7 (multi-case calibration) — финальная phase программы.
  Default cases: `05-ekaterina`, `07-mariya`, `10-danila`.

## Artifacts

- branch:               main
- commit(s):            a1891cc (1d59431..a1891cc)
- PR:                   no PR (single-commit task per TASK spec)
- tests:                149 passed / 0 xfailed / 0 failed (baseline
                        145+4 → +4 flips, no test count delta beyond
                        flips).
- Product repo status:  committed

## Conflicts / risks

- **Pre-existing untracked `.claude/scheduled_tasks.lock`** (cron/
  scheduler lock file, not product code per TASK section
  «Common acceptance»). Not staged, not committed.
- **One existing test outside Phase 6 xfail scope was updated**:
  `test_calendar_short_windows_filtered` в `test_transit_aspects_tables.py`.
  Old assertion `e["orb_exit_jd"] - e["orb_enter_jd"] >= 7d` стало
  semantically incorrect после Phase 6 (`orb_*_jd` на entries теперь
  clipped bounds, не raw engine). TASK spec разрешает только
  unmark'ать Phase 6 Cat 5 xfails, не модифицировать other tests; но
  этот test was *guarding* the pre-Phase-6 invariant that the per-entry
  `orb_*_jd` reflect raw engine duration — which Phase 6 explicitly
  changes per architecture document § 5 / § 6 and per TASK acceptance:
  «`orb_enter_jd` в calendar entry output = `calendar_start_jd` (clipped
  display bound), не raw engine `actual_start_jd`».
  Test was updated so:
    1. Old contract (raw engine duration ≥ 7d) is enforced on the
       actual side via lookup back into `annual_transit_table.hits`.
    2. New contract (positive calendar duration + bounds inside solar
       year) is asserted on calendar side.
  Это законная adaptation existing test к Phase 6 semantic shift,
  без снижения coverage. Flag сюда чтобы TL подтвердил decision.
- No engine / schema / fixture / Haskell core changes (verified
  `git diff --stat 1d59431..a1891cc` — touches только три файла в
  `services/api-python/`).

## Next step

TL inline verify через сверку `/tmp/natalya-phase6.pdf` calendar section с
Marina pp. 22-23 + extracted-text check + outer-cards regression check.
Если accept — open Phase 7 (multi-case calibration: 05-ekaterina, 07-mariya,
10-danila). После Phase 7 closing — программа Transit Section Recovery
полностью завершена, PDF Натальи can be promoted to production-ready
status per architecture document § 8 TASK 7 acceptance.
