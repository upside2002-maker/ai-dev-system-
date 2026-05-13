# TASK: per-context-cutoff-policy

- Status: done
- Ready: yes
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

Phase 6 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 6, § 6 «Calendar dates and clipping», § 8 TASK 6). Цель — закрыть последний root cause из § 3 документа: **разные date cutoff rules** для разных contexts презентации (calendar / outer cards / final synthesis).

Сейчас calendar `transit_aspects_by_month` обрезает по солярному году частично/непоследовательно — какие-то row'ы тянут хвост за границу `[sr_jd, sr_jd + 365.25]`. Phase 3 horizon split дал чистое разделение на уровне underlying view filters (`solar_year_transits` vs `loop_transit_windows`), но calendar row period bounds сами по себе не клипались explicit правилом.

Marina эталон pp. 22-23 показывает strict clipping календаря по солярному году:
- `Нептун 90° Юпитер` в календаре `21.04.2026 - 07.08.2026` (обрезан на конце соляра Натальи `07.08.2026`), хотя в outer card (loop context) показано до `28.09.2026`.
- `Уран 0° MC` в календаре до `07.08.2026`, не тянет хвост в ноябрь 2026 даже если engine эмитит wider window.
- Calendar months показываются строго в пределах solar year span (Aug 2025 — Aug 2026 для Натальи).

**Explicit clipping rule (per architecture § 6):**
```
period_end   = min(actual_period_end,   sr_jd + 365.25)
period_start = max(actual_period_start, sr_jd)
```

Outer cards (Phase 4) — **не клипаются**, показывают full loop context per Marina pp. 18-21. Final synthesis (`synthesis_themes.py`, Phase 3) — уже использует `solar_year_transits` view, не должен содержать даты вне соляра. **Phase 6 фиксирует calendar context only**, плюс explicit rule documented per context.

После closing → 4 Cat 5 Phase 6 xfail tests должны flip → passed. После Phase 6 — **xfailed count = 0** (все Phase 4/5/6 закрыты, Phase 4b Neptune Cat 4 — passing через structured overrides).

## Files

- modify:
  - **`services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month`** — добавить clipping logic per row, **с явным разделением двух window pair'ов**:

    **Critical design rule — две пары вместо одной:**
    - `actual_start_jd` / `actual_end_jd` — raw engine values, **сохраняются для всех internal operations**:
      - dedup key (если клипнуть до dedup, разные orb-windows начавшиеся до `sr_jd` схлопнутся на одном `sr_jd` → collapse risk).
      - `_MIN_WINDOW_DAYS` filter (вычисляется на actual duration, не clipped).
      - Quincunx display filter (per-aspect orb threshold tracker).
    - `calendar_start_jd` / `calendar_end_jd` — clipped display bounds, **используются только для calendar entry presentation**:
      - `calendar_start_jd = max(actual_start_jd, sr_jd)`
      - `calendar_end_jd = min(actual_end_jd, sr_jd + 365.25)`
      - `period_start_str`, `period_end_str` (формирование строк календаря) — из `calendar_*`.
      - `orb_enter_jd`, `orb_exit_jd` в calendar entry output — **clipped display bounds** (`calendar_start_jd`, `calendar_end_jd`).
      - Bucket assignment (month-bucket filtering) — по `calendar_*`.

    **Row drop rule:** если `calendar_start_jd >= calendar_end_jd` (clipped row полностью вне solar year) — drop из календаря **после** dedup и `_MIN_WINDOW_DAYS` filter (т.е. dedup/filter работают на actual, drop по clipped).

    Constant `_SOLAR_YEAR_DAYS = 365.25` уже есть в `transit_themes.py` (Phase 3); переиспользовать.
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — **unmark `@pytest.mark.xfail`** для 4 Cat 5 Phase 6 tests. НЕ unmark остальные xfails (но после Phase 6 их и не остаётся — Phase 6 — последняя).

- new (optional, Worker decides):
  - `services/api-python/tests/test_calendar_clipping.py` — unit tests для clipping logic если Worker считает что existing test coverage недостаточен. Acceptance assertions в `test_natalya_transits_acceptance.py` уже покрывают behavioural contract; helper-level test опционален.

- new (mandatory): —
- delete: —

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — out of scope.
- **Schema, rulesets, fixtures** — engine output stable.
- **Phase 1-5 artefacts**:
  - `provenance.py`, `render_natalya.py` (Phase 1) — не трогать.
  - `transit_themes.py:solar_year_transits`, `loop_transit_windows`, `houses_visited`, `transit_matrix_by_month` (Phase 3) — не трогать (clipping добавляется только к `transit_aspects_by_month`).
  - `synthesis_themes.py` (Phase 3) — не трогать.
  - `outer_cards.py` (Phase 4) — не трогать. Outer cards intentionally показывают full loop context, **не** clipped по соляру.
  - `rulership_houses.py` (Phase 5) — не трогать.
- **`test_natalya_transits_acceptance.py` xfail tags вне Phase 6 mapping** — Phase 4b structured overrides сохраняются как passing (не xfail после Phase 4b unmark); Phase 5 уже unmark'нул свои 4. После Phase 6 — все xfails закрыты.
- **PDF templates** (`solar.html.j2`) — НЕ трогать (clipping happens в Python helper до passing в Jinja).
- **`builder.py`** — НЕ трогать (no new Jinja context needed).

## Acceptance

### Clipping logic (`transit_aspects_by_month`)

- [ ] **Две window pair'ы поддерживаются отдельно:**
  - `actual_start_jd`/`actual_end_jd` — raw engine values, используются для dedup key, `_MIN_WINDOW_DAYS` filter, quincunx display filter.
  - `calendar_start_jd`/`calendar_end_jd` — clipped per formula, используются для presentation.
- [ ] `calendar_end_jd = min(actual_end_jd, sr_jd + 365.25)`.
- [ ] `calendar_start_jd = max(actual_start_jd, sr_jd)`.
- [ ] Row dropped если `calendar_start_jd >= calendar_end_jd` (clipped row полностью вне solar year). **Drop происходит ПОСЛЕ dedup и `_MIN_WINDOW_DAYS` filter** — dedup/filter работают на actual values.
- [ ] Existing month-bucket filtering работает на `calendar_*`, корректно mapping row к правильным месяцам.

### Calendar entry output semantics (Phase 6 contract change)

- [ ] **`orb_enter_jd` в calendar entry output = `calendar_start_jd`** (clipped display bound), **не raw engine** `actual_start_jd`.
- [ ] **`orb_exit_jd` в calendar entry output = `calendar_end_jd`** (clipped display bound), **не raw engine** `actual_end_jd`.
- [ ] `period_start_str` / `period_end_str` форматируются из `calendar_*`.
- [ ] Cat 5 Phase 6 tests проверяют именно эти clipped fields — это формальное подтверждение что Phase 6 ввёл этот semantic shift для calendar context.
- [ ] **Outer cards (Phase 4) продолжают использовать raw engine `orb_enter_jd`/`orb_exit_jd`** через `outer_cards.aggregate_display_windows`, который читает raw fields из `annual_transit_table` напрямую (НЕ через `transit_aspects_by_month`). Phase 6 clipping не затрагивает outer cards.

### Calendar oracle для Натальи

- [ ] `Нептун 90° Юпитер` row clipped до `period_end ≈ 07.08.2026` (sr_jd + 365.25 = solar year end). Engine actual emission 28.09.2026; Marina pp. 22-23 показывает 07.08.2026.
- [ ] `Уран 0° MC` row clipped до `07.08.2026`. Engine actual emission 14.11.2026 (extends past solar year); Marina pp. 22-23 показывает 07.08.2026.
- [ ] Никакая calendar row не показывает месяц вне `[Aug 2025, Aug 2026]` span.
- [ ] Никакая calendar row не содержит даты `2024`, `2027`, или `2028`.

### Test contract (Phase 6 xfail flips → passed)

После landing TASK 6 `pytest tests/test_natalya_transits_acceptance.py -v` показывает **4 xfail tests перешли в passed**:

Category 5 (calendar dates and clipping, 4 xfail Phase 6):
- `test_calendar_neptune_square_jupiter_clipped_to_solar_year_end` → passed
- `test_calendar_uranus_conjunction_mc_clipped_to_solar_year_end` → passed
- `test_calendar_no_rows_outside_solar_year_span` → passed
- `test_calendar_period_start_clipped_to_solar_year_start` → passed

**Итого 4 xfail flips.** Это **все Phase 6 mapping** — после Phase 6 closing **xfailed count = 0**.

### Outer cards intact (regression guard)

- [ ] Outer-planet cards в PDF показывают **full loop context** unchanged: Нептун-Юпитер W3 до `30.01.2028`, Нептун-Нептун W1 от `02.04.2024`. Phase 6 clipping применяется ТОЛЬКО к calendar, не к cards.
- [ ] Visual verify через render PDF + extracted text: outer-planet card sections содержат даты 2024/2027/2028 (это loop context, разрешено); calendar section этих дат **не** содержит.

### Common acceptance

- [ ] `cabal build` (Phase 2 lesson).
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. **Acceptance count formula:** `(145 baseline) + (4 Phase 6 xfail flips) + (N new helper tests если Worker создаст test_calendar_clipping.py)` passed, **0 xfailed**, **0 failed**. Ожидание: ≥ 149 passed + 0 xfailed + 0 failed.
- [ ] `git status --short` чисто для **intended product changes**. **Pre-existing untracked `.claude/scheduled_tasks.lock` разрешён** (cron/scheduler lock file, не часть продуктового кода). Final commit **не должен** включать его. Если Worker видит другие untracked файлы вне intended scope — flag в HANDOFF.
- [ ] Один commit. Conventional message + cross-ref на architecture document § 5 Phase 6.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verify через сверку calendar section PDF Натальи с Marina pp. 22-23 + extracted text check на отсутствие 2024/2027/2028 в calendar block.
- [ ] HANDOFF содержит:
  - per-file diff overview;
  - calendar oracle validation (Neptune-Jupiter clipped, Uranus 0° MC clipped, no out-of-year dates);
  - outer cards regression check (full loop context intact);
  - xfail flip status (4 Phase 6 tests unmarked);
  - Path к новому PDF Натальи.

### Scope discipline

- [ ] Затронуты только `services/api-python/app/pdf/transit_themes.py` (clipping logic) + `services/api-python/tests/test_natalya_transits_acceptance.py` (4 xfail unmark) + optionally `services/api-python/tests/test_calendar_clipping.py` (new unit tests).
- [ ] Engine, schema, fixtures, Haskell core — 0 lines changed.
- [ ] Phase 1/2/3/4/4b/5 artefacts не тронуты (outer_cards.py, rulership_houses.py, synthesis_themes.py, builder.py, solar.html.j2, provenance.py, render_natalya.py).

## Context

**Mode normal + Tier C** (presentation cutoff logic). Worker subagent. Reviewer subagent необязателен.

**Baseline:** main @ `1d59431` (Phase 5 closed). Tests `145 passed + 4 xfailed`. После Phase 6 expected: **xfailed count = 0** (все Phase 4/5/6 закрыты). Final pytest result: ≥ 149 passed + 0 xfailed + 0 failed.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 5 Phase 6 (formal definition).
- § 6 «Calendar dates and clipping» — explicit rule formula + acceptance assertions.
- § 8 TASK 6 — formal spec (зеркальная).

**Marina reference oracle:** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 22-23 (календарь). Verify:
- Нептун 90° Юпитер calendar period: `21.04.2026 - 07.08.2026` (end clipped to solar year).
- Уран 0° MC calendar period: до `07.08.2026` (clipped).
- No rows показаны вне Aug 2025 — Aug 2026 span.

**Natalya solar year:** `sr_jd` из `08-natalya-2025-2026.expected.json:solar_chart.return_jd`. Solar year end = `sr_jd + 365.25` ≈ `07.08.2026`.

**Phase 6 ⇄ outer cards boundary fixed:** Phase 4 outer cards (`outer_cards.py`) intentionally показывают full loop context (включая даты 2024/2027/2028 для slow movers). Phase 6 clipping применяется ТОЛЬКО к `transit_aspects_by_month` calendar context. Worker НЕ применяет clipping к outer cards — это regression если сделает.

**После closing Phase 6 — Phase 7 (multi-case calibration).** Phase 7 — verification что Phase 1-6 work не подогнаны под одну Наталью, а работают на 3+ дополнительных cases (default `05-ekaterina`, `07-mariya`, `10-danila`). Phase 7 = последняя phase программы.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 6 spec.
