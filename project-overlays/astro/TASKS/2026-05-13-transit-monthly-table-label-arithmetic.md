# TASK: transit-monthly-table-label-arithmetic

- Status: open
- Ready: no
- Date: 2026-05-13
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 7 Stage A calibration (TASK `2026-05-13-multi-case-calibration`, accepted с verdict «Blockers identified») обнаружил TYPE-B regression в `services/api-python/app/pdf/transit_themes.py:transit_matrix_by_month` (строки 547-557).

**Корневой bug:** Function использует fractional-day iteration для определения month-window bounds + labels:

```python
m_start = sr + i * 30.4375
m_end   = sr + (i + 1) * 30.4375
```

Для cases где solar return JD имеет late-day-of-month UT time (e.g. case 07 Мария: `sr=01.07.2025 19:11 UT`), iteration index `i=2` даёт `m_start ≈ 31.08.2025 ~02:11 UT`, который остаётся августом (по calendar rounding), не сентябрём. Результат:
- Month labels duplicate (Август 2025 повторяется на i=1 и i=2).
- Months missing (Сентябрь 2025 never computed — labels skip к Октябрь).
- 6 of 13 cells в monthly table wrong vs Marina эталон (Соляр 2025-2026_4.pdf, case 07).

**Natalya был "lucky":** `sr=07.08.2025 ~02:30 UT` — early-morning UT 7th — fractional iteration лendет cleanly в consecutive calendar months. 149 baseline зелёный потому что Natalya не triggers bug.

**Existing fix template available:** Line 687 уже использует calendar-month-advance для **другой** функции (`transit_aspects_by_month` calendar — Phase 6 work). Comment явно говорит «advancing by calendar month (not by 30.4375 days) so we never miss». Это refactor pattern, применённый к `transit_aspects_by_month`, нужно применить к `transit_matrix_by_month`.

**Fix scope:** ~10 lines в одной функции. Заменить fractional iteration на calendar-month-advance, чтобы month label and snapshot середины always corresponds к unique consecutive months.

После closing TASK 7a → reopen Phase 7 Stage A re-validation (separate follow-up TASK 7b), потом Stage B.

## Files

- modify:
  - **`services/api-python/app/pdf/transit_themes.py:transit_matrix_by_month`** — fix iteration: вместо `sr + i * 30.4375` использовать calendar-month-advance pattern (как в `transit_aspects_by_month`, line 687). Конкретный approach Worker выбирает (один из):
    - Option A: Generate `(year, month)` pairs starting from sr's calendar month, advance by `relativedelta(months=1)` (если doesn't break Phase 5 logic).
    - Option B: Use sr-based JD for sub-day precision but advance label by calendar month (decouple label from JD-fraction-based snapshot).
    - Option C: pre-compute 13 anchor JDs (`sr_jd`, `month_start(sr_year, sr_month+1)`, `month_start(sr_year, sr_month+2)`, ...) using calendar arithmetic.
    
    Worker chooses option, documents в HANDOFF rationale.

- new (mandatory):
  - **Regression test в `services/api-python/tests/`** — Worker выбирает где (`test_natalya_transits_acceptance.py` extension OR new `test_mariya_transit_matrix.py`). Test asserts:
    - case 07 Мария monthly table has **13 unique consecutive month labels** (no duplicates, no skips), starting from sr's calendar month.
    - Test reads case 07 fixture, calls `transit_matrix_by_month`, asserts label uniqueness + monotonic ordering.

- delete: —

## Do not touch

- **Haskell core, schema, fixtures, rulesets** — engine output stable, fix purely Python presentation.
- **Phase 1-6 generic logic** — fix СТРОГО ограничен `transit_matrix_by_month` function (lines 547-557 area). НЕ менять:
  - `transit_aspects_by_month` (Phase 3/6 baseline) — line 687 calendar-month-advance уже corectly работает там; не trogать.
  - `solar_year_transits`, `loop_transit_windows`, `houses_visited` (Phase 3 helpers) — не менять.
  - `rulership_houses.py` (Phase 5) — не менять.
  - `outer_cards.py` (Phase 4) — не менять.
  - `synthesis_themes.py` (Phase 3) — не менять.
  - `builder.py`, `solar.html.j2`, `provenance.py` — не менять.
- **Phase 4b structured overrides** в test_natalya_transits_acceptance.py — не менять.
- **expected.json fixtures** — не перезаписывать.

## Acceptance

### Bug fix

- [ ] `transit_matrix_by_month` использует calendar-month-advance для label generation + month snapshot timing, не fractional `sr + i * 30.4375`.
- [ ] 13 month labels всегда unique consecutive (no duplicates Aug/Aug, no skips Sep missing).
- [ ] Month snapshot середина computed из calendar mid-month per advanced month, не fractional offset.

### Regression test (case 07 Мария)

- [ ] Test asserts case 07 monthly table = 13 unique consecutive month labels.
- [ ] Test asserts no duplicate labels (e.g. «Август 2025» appears exactly once).
- [ ] Test asserts monotonic month ordering (Jul/Aug/Sep/Oct/.../Jul next year).
- [ ] Test uses canonical fixture path `packages/test-fixtures/golden-cases/07-mariya-2025-2026.expected.json`.

### Natalya baseline preservation

- [ ] **149 passed + 0 xfailed + 0 failed** sustained на Натальи tests после fix.
- [ ] Если fix shifts Natalya monthly table cells (vs current 50/52 Marina match) — Worker investigates:
  - Если shift ≤ ±1 day boundary in cells (Marina parity maintained or improved) → acceptable.
  - Если shift breaks existing Natalya tests with currently-passing assertions → STOP, investigate, либо test update либо fix recalibration. Документировать в HANDOFF.

### Common acceptance

- [ ] `cabal build` (Phase 2 lesson).
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. `149 baseline + 1 new regression test = 150 passed + 0 xfailed + 0 failed`.
- [ ] `git status --short` чисто для intended product changes. Pre-existing `.claude/scheduled_tasks.lock` разрешён.
- [ ] Один commit. Conventional message + cross-ref на calibration report § 4 / TASK 7 finding.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verify через test count + Natalya baseline preserved.
- [ ] HANDOFF содержит:
  - Fix approach choice (Option A/B/C) + rationale;
  - Diff stat (≤ 30 lines в transit_themes.py);
  - Regression test path;
  - Natalya baseline preservation check result;
  - Case 07 monthly table validation snippet (13 labels unique).

### Scope discipline

- [ ] Затронуты только `services/api-python/app/pdf/transit_themes.py` (lines around 547-557) + regression test file.
- [ ] Engine, schema, fixtures — 0 lines changed.
- [ ] Phase 1-6 artefacts кроме `transit_matrix_by_month` — 0 lines changed.
- [ ] Phase 4b structured overrides не тронуты.

## Context

**Mode normal + Tier C** (bug fix in presentation). Worker subagent. Reviewer subagent необязателен.

**Baseline:** main @ `a1891cc` (Phase 6 closed). Tests `149 passed + 0 xfailed + 0 failed`.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`. **Дополнительно:**
- `transit-multi-case-calibration-report-2026-05-13.md` — Stage A finding, § 4 divergence classification (TYPE-B item для case 07).

**Calibration report cross-ref:** Stage A diff показал case 07 monthly table 6/13 cells wrong, 2 duplicate labels (Aug/Oct), 2 missing months (Sep/Feb). Specific cell mismatches вынесены в report § 3.07.

**После closing TASK 7a:**

1. TL inline verifies fix preserves Natalya 149 baseline + adds case 07 regression test passing.
2. Open separate **TASK 7b**: «Phase 7 Stage A re-validation + Stage B closed-config calibration». Worker re-runs Stage A на cases 05/07/10 после fix; если case 07 теперь passes monthly table check → Stage B authorized (allowlist extensions + per-case tests + render_case.py).
3. After TASK 7b closes с «Ready for Marina show — pending user ack» → user reads updated calibration report → explicit ack → recovery program closes → PDF можно показывать Марине.

**Phase 7 sequence:**
- TASK 7 (multi-case-calibration, Stage A original) — CLOSED with verdict «Blockers identified».
- TASK 7a (this — fix label-arithmetic bug) — open, ждёт ack.
- TASK 7b (Phase 7 Stage A re-validation + Stage B) — после TASK 7a.
- User ack → recovery program closes.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 7a spec.
