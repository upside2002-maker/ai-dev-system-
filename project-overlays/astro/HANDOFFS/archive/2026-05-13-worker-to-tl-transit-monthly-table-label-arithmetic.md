# HANDOFF: worker → tl — transit-monthly-table-label-arithmetic

- Status: closed
- Date: 2026-05-13 17:49
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-transit-monthly-table-label-arithmetic.md

## Summary

TASK 7a closed: `transit_matrix_by_month` теперь использует integer
calendar-month-advance вместо fractional `sr + i * 30.4375`. Case 07
Мария 13 labels теперь strictly консекутивны (Июль 2025 → Июль 2026),
никаких duplicates / skips; regression test зафиксирован. Natalya 149
baseline preserved 1:1 (mid-15 anchor одинаков независимо от того, как
вычислен row index — early-UT solar return не triggers bug-affected
arithmetic в любом случае). Test counts: 149 → 150 (+1 regression).

## Done

- **Fix scope (24 insertions / 11 deletions в одной функции):**
  - `services/api-python/app/pdf/transit_themes.py` lines 546-588:
    fractional `sr + i * 30.4375` iteration заменена на integer
    calendar-month-advance — начинаем с `(sr_y, sr_m)` (через
    existing `_jd_to_year_month(sr)`), на каждой iteration вычисляем
    `(next_y, next_m) = (y + 1, 1) if m == 12 else (y, m + 1)`,
    window bounds `[1st of (y, m), 1st of next-month)` UTC,
    mid-month JD = `datetime(y, m, 15, UTC)`. Existing helpers
    reused, никаких новых dependencies.
- **Regression test (new file):**
  - `services/api-python/tests/test_mariya_transit_matrix.py` —
    `EXPECTED_07_MARIYA_LABELS` list literal + strict-equality
    assertion `actual_labels == EXPECTED_07_MARIYA_LABELS` (полный
    equality, не subset, не length-only).
- **Reused JD↔datetime utilities** (no new code paths introduced):
  - `_jd_to_year_month(jd)` (line 455-464) — для (sr_y, sr_m) от
    solar_return_jd.
  - Inline pattern `2440587.5 + dt.timestamp() / 86400.0` для JD
    derivation от naive UTC `datetime(...)` — тот же pattern уже
    используется в `_jd_to_year_month` body и в
    `transit_aspects_by_month` (Phase 6 baseline).
  - Pattern advance `m += 1; if m > 12: m = 1; y += 1` mirrors
    `_months_between` (line 683-702).

## Remaining

Не относится к TASK 7a; ожидается TL:

- Inline verify Naталья baseline (149 → 150 passed) + regression test
  green.
- Open TASK 7b (Phase 7 Stage A re-validation + Stage B closed-config:
  outer cards allowlist extensions для cases 05/07/10, render_case.py,
  per-case acceptance tests).

## Artifacts

- branch:               main
- commit(s):            8a4865e (fix(pdf): transit monthly table calendar-month advance (Phase 7 / TASK 7a))
- PR:                   N/A (committed direct to main per Phase 7 sequence)
- tests:                149/0/0 → **150/0/0** (passed/xfailed/failed); new regression test `test_matrix_labels_case_07_mariya_strict_sequence`; full suite `pytest --tb=no -q` clean.
- Product repo status:  committed (backup push parity verified: backup/main = 8a4865e)

### Regression test assertion snippet

```python
EXPECTED_07_MARIYA_LABELS: list[str] = [
    "Июль 2025", "Август 2025", "Сентябрь 2025", "Октябрь 2025",
    "Ноябрь 2025", "Декабрь 2025", "Январь 2026", "Февраль 2026",
    "Март 2026", "Апрель 2026", "Май 2026", "Июнь 2026", "Июль 2026",
]

def test_matrix_labels_case_07_mariya_strict_sequence(mariya_facts: dict) -> None:
    att = mariya_facts["annual_transit_table"]
    sr_jd = mariya_facts["solar_chart"]["return_jd"]
    rows = transit_matrix_by_month(att, sr_jd)
    actual_labels = [row["label"] for row in rows]
    assert actual_labels == EXPECTED_07_MARIYA_LABELS, ...
```

### Natalya baseline preservation check

Direct call `transit_matrix_by_month(natalya_facts.annual_transit_table,
natalya_facts.solar_chart.return_jd)` post-fix returns:

```
Август 2025, Сентябрь 2025, Октябрь 2025, Ноябрь 2025, Декабрь 2025,
Январь 2026, Февраль 2026, Март 2026, Апрель 2026, Май 2026,
Июнь 2026, Июль 2026, Август 2026
```

Все 13 labels уникальны и консекутивны (как и до fix — sr = 07.08.2025
~02:13 UT не triggered bug). **Cells unchanged 1:1** — `_jd_to_year_month`
извлекает `(sr_y=2025, sr_m=8)` от Natalya's sr_jd; на каждой iteration
mid-15 datetime тот же UTC instant что и до fix (15.08.2025 00:00 UTC,
15.09.2025 00:00 UTC, ...) — а cells это `house_at(planet, mid_jd)`,
который зависит только от mid_jd. Phase 4b structured overrides не
тронуты, test_natalya_transits_acceptance.py не изменялся.

### Test counts before / after

```
before: 149 passed + 0 xfailed + 0 failed   (HEAD a1891cc)
after:  150 passed + 0 xfailed + 0 failed   (HEAD 8a4865e)
delta:  +1 (new regression test)
```

### Visual confirm PDFs

- `/tmp/natalya-task7a.pdf` + `.provenance.json` — canonical render
  via `scripts/render_natalya.py --mode fixture-render`. SHA в
  sidecar = 8a4865e.
- `/tmp/mariya-task7a.pdf` + `.provenance.json` — render через
  `render_natalya.py` с `--facts` / `--input` override на case 07
  fixture (sidecar `case_label` shows `08-natalya-...` — known
  hardcoding в render_natalya, Stage B render_case.py fixes это).
  Распарсенный PDF text содержит точно 13 уникальных
  консекутивных labels Июль 2025 → Июль 2026.

## Conflicts / risks

Нет. Fix строго ограничен `transit_matrix_by_month` function. Phase 1-6
artefacts (`transit_aspects_by_month`, `solar_year_transits`,
`loop_transit_windows`, `houses_visited`, `rulership_houses.py`,
`outer_cards.py`, `synthesis_themes.py`, `builder.py`, `solar.html.j2`,
`provenance.py`, `render_natalya.py`, Phase 4b structured overrides,
golden fixtures, schema, Haskell core) — 0 lines changed. Pre-existing
untracked `.claude/scheduled_tasks.lock` остался untracked.

Note (for TL awareness, not blocker): Mariya monthly cells при post-fix
render показывают 11 of 13 строк exactly matching Marina pp. 6-7;
последние 2 строки (Июнь 2026, Июль 2026) показывают small house-1-
boundary differences ожидаемые из-за нашей mid-15 convention vs
Marina's day-1 anchor convention. Это не TASK 7a scope — Stage B
(closed-config Phase 4b structured tolerance overrides per case) или
TYPE-A fast-mover boundary item (§ 4 calibration report) для адресации.

## Next step

TL inline verifies:
1. `cd services/api-python && .venv/bin/pytest --tb=no -q` → 150/0/0
   на свежем checkout `main @ 8a4865e`.
2. Visual confirm `/tmp/mariya-task7a.pdf` p. 6-7 показывает 13
   uникальных labels Июль 2025 → Июль 2026.
3. Visual confirm `/tmp/natalya-task7a.pdf` неизменён vs Phase 6
   baseline (тот же 13-label sequence Август 2025 → Август 2026,
   те же cells).

После accept: TL opens TASK 7b «Phase 7 Stage A re-validation + Stage B
closed-config»: re-run Stage A на cases 05/07/10 с фиксом → extend
`OUTER_CARD_ALLOWLIST` + add card-facts для cases 05/10 (3 cards
каждая, per § 6 of calibration report) → render_case.py + per-case
acceptance tests.

После TASK 7b + user ack → recovery program closes; PDF Марине можно
показывать.
