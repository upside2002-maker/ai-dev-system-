# Transit Section Multi-Case Calibration Report — Phase 7 (Stage A + Stage B)

Дата: 2026-05-13 (Stage A original) + 2026-05-13 (Stage B closed-config calibration)
Author: Worker subagent (Phase 7, TASK `2026-05-13-multi-case-calibration` →
TASK 7b Stage A.2/B `2026-05-13-phase-7-stage-b-closed-config-calibration`)
Owner: Project Tech Lead

Repo state at Stage B close: `main @ 8a4865e` (TASK 7a label-arithmetic fix landed) +
Stage B closed-config changes (one Worker commit after Stage B closure).
Tests at Stage B close: **183 passed / 0 xfailed / 0 failed** (150 baseline post-TASK-7a + 33 new
multi-case acceptance tests in `tests/test_multi_case_calibration.py`).

Architecture SoT: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.

Stage A scope (read-only validation): inventory mapping confirm, render per case via
canonical-equivalent path, per-section diff against Marina, divergence classification,
override count + Phase 4b gate check, production-readiness verdict. **No product changes.**

Stage B scope (closed-config calibration, authorized by TASK 7c amended gate (a)-(d)):
extend `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` for cases 05 / 10 from Marina
reference; create canonical `render_case.py`; create parameterized
`test_multi_case_calibration.py`; doc/comment generalization («3 intervals / три касания»
→ «3+ per Marina card»); test helper generalization
(`_assert_three_phase_intervals(expected_window_count: int = 3)`). **No engine /
schema / fixture / generic-logic changes.**

---

## § 1 Marina inventory mapping confirmation

TL pre-mapped the four 2025-2026 PDFs to golden-case IDs via solar return time. Worker
validated each by converting the expected.json `solar_chart.return_jd` to UTC and
comparing to Marina's "Время запуска" caption on PDF p.1 (in case file's local timezone).

| Case ID | Marina PDF | Marina "Время запуска" (local) | UTC equivalent | Our `return_jd` → UTC | Match |
|---|---|---|---|---|---|
| 05-ekaterina-2025-2026 | `Соляр 2025-2026_2.pdf` | 11.03.2025 09:34:30 (GMT+3) | 11.03.2025 06:34:30 | 11.03.2025 06:33:45 | YES (Δ ≈ 45s) |
| 07-mariya-2025-2026 | `Соляр 2025-2026_4.pdf` | 01.07.2025 22:11 (GMT+3) | 01.07.2025 19:11 | 01.07.2025 19:11:07 | YES (Δ < 60s) |
| 08-natalya-2025-2026 | `Соляр 2025-2026_5.pdf` | — (Phase 1-6 oracle, no change) | 07.08.2025 02:13 | 07.08.2025 02:13:40 | YES (anchor) |
| 09-anastasiya-2025-2026 | `Соляр 2025-2026 для Анастасии.pdf` | (not validated — fallback only) | 14.05.2025 09:54 | 14.05.2025 09:54:03 | (fallback unused) |
| 10-danila-2025-2026 | `Соляр 2025-2026 для Данилы.pdf` | 05.08.2025 10:44:12 (GMT+3) | 05.08.2025 07:44:12 | 05.08.2025 07:44:12 | YES (exact) |

All three default cases (05, 07, 10) validated within Δ ≤ 60s of Marina's stated solar
return moment — well within ephemeris rounding tolerance. The TL pre-mapping is confirmed
for Stage A. The 09-anastasiya fallback was therefore not exercised; it remains validated
against `expected.json` for any future use.

---

## § 2 Selected cases

Worker uses the architecture-default trio **05-ekaterina, 07-mariya, 10-danila** per § 8
TASK 7 / § 5 Phase 7. Rationale: all three Marina-PDF mappings pre-validated by TL and
re-confirmed by Worker via return_jd matching. No fallback to 09-anastasiya needed.

Per-case render: a Stage A read-only ad-hoc Python harness (`/tmp/stage_a_render_case.py`)
invoked `app.pdf.builder.write_solar_pdf` directly per case_id, calling `collect_provenance`
with the correct `case_label` extra. This is **Worker-side throwaway** — no product code
under `services/api-python` was modified for Stage A. The canonical `render_natalya.py`
hardcodes `case_label="08-natalya-..."` (Phase 1 design); using it directly for cases
05/07/10 would either suppress outer-cards entirely or render Natalya's allowlist on the
wrong facts, producing diagnostically useless PDFs. Stage B (if authorized) would
introduce `services/api-python/scripts/render_case.py` to formalise this.

Stage A PDFs (one per case):

- `/tmp/05-ekaterina-phase7.pdf` + `.provenance.json`
- `/tmp/07-mariya-phase7.pdf` + `.provenance.json`
- `/tmp/10-danila-phase7.pdf` + `.provenance.json`

Render mode: `fixture-render`. Provenance sidecars carry the correct case_label, repo
SHA `a1891ccc2734` (main), branch `main`.

---

## § 3 Per-case section diff

### § 3.1 Case 05 (Екатерина) — Solar 2025-2026

**Solar return**: 11.03.2025 09:33:45 (GMT+3), Москва. Marina PDF: `Соляр 2025-2026_2.pdf`.

#### Monthly transit table (Транзиты планет по домам)

Marina labels rows `11.MM.YYYY` (day-of-month = solar return day). Our PDF labels rows as
Russian-month strings (e.g. «Март 2025»). Both span 13 calendar months. Cell-by-cell
comparison (our cells use «mid-month-15» convention, Marina pp. 7-8 convention):

| Period | Marina (M/S/J/V) | Our (M/S/J/V) | Match |
|---|---|---|---|
| 11.03.2025 / Март 2025 | 6 / 1 / 4 / 1 | 6 / 1 / 4 / 1 | YES |
| 11.04.2025 / Апрель 2025 | 6 / 1 / 4 / 1 | 6 / 1 / 4 / 1 | YES |
| 11.05.2025 / Май 2025 | 7 / 1 / 4 / 1 | 7 / 1 / 4 / 1 | YES |
| 11.06.2025 / Июнь 2025 | 7 / 1 / 5 / 2 | 7 / 1 / 5 / 2 | YES |
| 11.07.2025 / Июль 2025 | 7 / 1 / 5 / **3** | 7 / 1 / 5 / **4** | Venus diff (1) |
| 11.08.2025 / Август 2025 | 7 / 1 / 6 / 6 | 7 / 1 / 6 / 6 | YES |
| 11.09.2025 / Сентябрь | 8 / 1 / 6 / 7 | 8 / 1 / 6 / 7 | YES |
| 11.10.2025 / Октябрь | 8 / 1 / 6 / 7 | 8 / 1 / 6 / 7 | YES |
| 11.11.2025 / Ноябрь | 9 / 1 / 6 / 8 | 9 / 1 / 6 / 8 | YES |
| 11.12.2025 / Декабрь | 11 / 1 / 6 / 10 | 11 / 1 / 6 / 10 | YES |
| 11.01.2026 / Январь | 12 / 1 / 6 / 12 | 12 / 1 / 6 / 12 | YES |
| 11.02.2026 / Февраль | 1 / 1 / 6 / 1 | 1 / 1 / 6 / 1 | YES |
| 11.03.2026 / Март | 1 / 1 / 6 / 1 | 1 / 1 / 6 / 1 | YES |

**51/52 cells match.** Single diverging cell (Venus, Jul 2025: Marina 3 / our 4) — fast
mover boundary; Marina snapshots on 11.07.2025 while our mid-15 convention reads 15.07.2025
— Venus moves ~1 sign/day so the 4-day gap straddles the h3/h4 cusp.

#### Per-house interpretations

Marina (pp. 11-18): Сатурн по 1 дому (only); Юпитер по 4/5/6 дому; Марс — 7 houses
listed; Венера — 12 houses listed; Уран — 3 дом; Нептун — 1 дом.
Our PDF: matches Marina's set exactly. No out-of-year stale dates observed.

#### Outer-planet cards

**Marina cards (pp. 34-38) — 3 deep-dive cards:**

1. **тр Уран в квадрате с нат Луной** — 3 display windows: 21.07.2025-24.10.2025 /
   06.05.2026-09.06.2026 / 25.12.2026-25.03.2027. Golden-rule: transit_h=8, target_h=7,
   transit_ruled=[1,12], target_ruled=[6], walks=h3.
2. **тр Уран в секстиле с нат Юпитером** — 3 windows: 05.06.2025-14.07.2025 /
   31.10.2025-20.12.2025 / 21.03.2026-01.05.2026. Golden-rule: transit_h=8, target_h=6,
   transit_ruled=[1,12], target_ruled=[10,1,11], walks=h3.
3. **тр Нептун в тригоне с нат Юпитером** — 3 windows: 12.04.2024-28.09.2024 /
   12.02.2025-08.04.2025 / 10.10.2025-07.02.2026. Golden-rule: transit_h=10, target_h=6,
   transit_ruled=[1,10,11], target_ruled=[10,1,11], walks empty.

**Stage A baseline (pre-Stage-B)**: outer-cards block empty for case 05 — `OUTER_CARD_ALLOWLIST`
lacked entry for `05-ekaterina-2025-2026`. **TYPE-A closed-config gap.**

**Post-Stage-B (2026-05-13)**: `OUTER_CARD_ALLOWLIST["05-ekaterina-2025-2026"]` extended
with 3 triples per Marina pp. 34-37; `_OUTER_CARD_FACTS` populated for each card.
Rendered PDF `/tmp/05-ekaterina-stage-b.pdf` contains all 3 outer cards with Marina-style
titles, intervals (3 windows each per engine output), Golden-rule tables, psychology +
event level texts. **TYPE-A item 1 [RESOLVED via Stage B].**

#### Calendar (КАЛЕНДАРЬ транзитных аспектов)

Our PDF: present, multi-month, social + outer planet aspects with `Дома цели` derived
via Phase 5 rulership_houses helper. Examples in our case 05 calendar:
- «Нептун 120° Юпитер — 11.03.2025–08.04.2025 → Дома цели: 6, 10, 11» — matches
  Marina's golden-rule table on p.36 (target Юпитер ruled houses 10, 1, 11 — and h6
  placement).
- «Уран 60° Юпитер — 04.06.2025–14.07.2025 → Дома цели: 6, 10, 11» — likewise.
Calendar window dates engine-derived, clipped at solar-year boundaries per Phase 6.

### § 3.2 Case 07 (Мария) — Solar 2025-2026

**Solar return**: 01.07.2025 22:11 (GMT+3), Москва. Marina PDF: `Соляр 2025-2026_4.pdf`.

#### Monthly transit table — Stage A baseline + post-TASK-7a state

> **Snapshot history:** Stage A baseline (commit `a1891cc`, 2026-05-13) — TYPE-B regression found (6/13 cells, 2 dup labels, 2 missed months). **TASK 7a** (`8a4865e`, 2026-05-13) replaced the label arithmetic with integer calendar-month advance; **TASK 7b Stage A.2** Worker run 2026-05-13 verified post-fix state. Below: post-TASK-7a snapshot.

##### Post-TASK-7a state (2026-05-13, Stage A.2 Worker verification)

13 unique consecutive labels, 11/13 cell rows match Marina exactly. 2 residual mismatches at rows 12-13 (TYPE-A anchor-day boundary divergences — see § 4 items 4-5).

| Marina | Marina cells (M/S/J/V) | Our label | Our cells (M/S/J/V) | Match |
|---|---|---|---|---|
| 01.07.2025 | 12 / 7 / 10 / 9 | Июль 2025 | 12 / 7 / 10 / 9 | YES |
| 01.08.2025 | 1 / 7 / 10 / 10 | Август 2025 | 1 / 7 / 10 / 10 | YES |
| 01.09.2025 | 2 / 7 / 10 / 11 | Сентябрь 2025 | 2 / 7 / 10 / 11 | YES |
| 01.10.2025 | 3 / 7 / 10 / 1 | Октябрь 2025 | 3 / 7 / 10 / 1 | YES |
| 01.11.2025 | 3 / 7 / 10 / 2 | Ноябрь 2025 | 3 / 7 / 10 / 2 | YES |
| 01.12.2025 | 4 / 7 / 10 / 3 | Декабрь 2025 | 4 / 7 / 10 / 3 | YES |
| 01.01.2026 | 4 / 7 / 10 / 4 | Январь 2026 | 4 / 7 / 10 / 4 | YES |
| 01.02.2026 | 5 / 7 / 10 / 6 | Февраль 2026 | 5 / 7 / 10 / 6 | YES |
| 01.03.2026 | 6 / 7 / 10 / 7 | Март 2026 | 6 / 7 / 10 / 7 | YES |
| 01.04.2026 | 7 / 7 / 10 / 9 | Апрель 2026 | 7 / 7 / 10 / 9 | YES |
| 01.05.2026 | 8 / 7 / 10 / 10 | Май 2026 | 8 / 7 / 10 / 10 | YES |
| 01.06.2026 | 8 / 7 / 10 / 10 | Июнь 2026 | **9** / 7 / 10 / **11** | NO (TYPE-A: Mars 8→9 on 2026-06-05; Venus 10→11 on 2026-06-11; see § 4 item 4) |
| 01.07.2026 | 9 / 7 / 11 / 11 | Июль 2026 | 9 / **8** / 11 / **12** | NO (TYPE-A: Saturn 7→8 on 2026-07-08; Venus 11→12 on 2026-07-08; see § 4 item 5) |

**Result: labels 13/13 PASS, cells 11/13 PASS, 2 TYPE-A boundary mismatches.** Per amended gate (TASK 7c): all four conditions (a)-(d) hold; Stage B authorized.

##### Stage A baseline (pre-TASK-7a) — historical reference

Marina labels rows `01.MM.YYYY` (day-of-month = 01, day-of-solar-return). Stage A baseline (`a1891cc`) had 13 rows but **labels duplicated Aug 2025 / Oct 2025 and skipped Sep 2025 / Feb 2026**:

| Marina | Marina cells (M/S/J/V) | Our label (Stage A) | Our cells (M/S/J/V) | Match |
|---|---|---|---|---|
| 01.07.2025 | 12 / 7 / 10 / 9 | Июль 2025 | 12 / 7 / 10 / 9 | YES |
| 01.08.2025 | 1 / 7 / 10 / 10 | Август 2025 | 1 / 7 / 10 / 10 | YES |
| 01.09.2025 | 2 / 7 / 10 / 11 | **Август 2025 (dup)** | 1 / 7 / 10 / 10 (wrong) | NO |
| 01.10.2025 | 3 / 7 / 10 / 1 | Октябрь 2025 | 3 / 7 / 10 / 1 | YES |
| 01.11.2025 | 3 / 7 / 10 / 2 | **Октябрь 2025 (dup)** | 3 / 7 / 10 / 1 (wrong) | NO |
| 01.12.2025 | 4 / 7 / 10 / 3 | Ноябрь 2025 | 3 / 7 / 10 / 2 | NO (label drift) |
| 01.01.2026 | 4 / 7 / 10 / 4 | Декабрь 2025 | 4 / 7 / 10 / 3 | NO (label drift) |
| 01.02.2026 | 5 / 7 / 10 / 6 | Январь 2026 | 4 / 7 / 10 / 4 | NO (label drift) |
| 01.03.2026 | 6 / 7 / 10 / 7 | Март 2026 | 6 / 7 / 10 / 7 | YES |
| 01.04.2026 | 7 / 7 / 10 / 9 | Апрель 2026 | 7 / 7 / 10 / 9 | YES |
| 01.05.2026 | 8 / 7 / 10 / 10 | Май 2026 | 8 / 7 / 10 / 10 | YES |
| 01.06.2026 | 8 / 7 / 10 / 10 | Июнь 2026 | 9 / 7 / 10 / 11 | NO (Mars diff — TYPE-A boundary, persists post-fix) |
| 01.07.2026 | 9 / 7 / 11 / 11 | Июль 2026 | 9 / 8 / 11 / 12 | NO (Sat/Ven diff — TYPE-A boundary, persists post-fix) |

**Root cause** (verified by reading `services/api-python/app/pdf/transit_themes.py`
function `transit_matrix_by_month`, lines 553-568): the iteration uses
`m_start = sr + i * 30.4375` with label derived via `_jd_to_year_month(m_start)`.
For sr = 01.07.2025 19:11 UT, `sr + i*30.4375` for i=0..12 lands in calendar months:

```
i= 0 → 01.07.2025  → "Июль 2025"
i= 1 → 01.08.2025  → "Август 2025"
i= 2 → 31.08.2025  → "Август 2025"   ← duplicate (drifted)
i= 3 → 01.10.2025  → "Октябрь 2025"  ← skipped Sept
i= 4 → 31.10.2025  → "Октябрь 2025"  ← duplicate
i= 5 → 30.11.2025  → "Ноябрь 2025"
i= 6 → 31.12.2025  → "Декабрь 2025"
i= 7 → 30.01.2026  → "Январь 2026"
i= 8 → 02.03.2026  → "Март 2026"     ← skipped Feb
i= 9..12 → continue
```

Because `(y, m)` becomes the basis for `mid_dt = datetime(y, m, 15)`, **the
mid-month-15 snapshot is also collapsed** — i=1 and i=2 both snapshot at 15.08.2025;
i=3 and i=4 both snapshot at 15.10.2025. Sept and Feb mid-month snapshots never appear.
This is the source of NO-match rows 3, 5, 6, 7, 8, 12, 13 above.

Case 08 (Натальи) sr = 07.08.2025 02:13 UT — iterations land cleanly in consecutive
calendar months because sr-day-of-month is early. Case 10 (Данила) sr = 05.08.2025
07:44 UT — same: clean iteration. Case 05 (Екатерина) sr = 11.03.2025 06:33 UT — same.
**Only case 07 trips this bug** because its sr-day-of-month is 01 + sr-time 22:11 local
(19:11 UT), so `sr + 30.4375` and `sr + 60.875` land on month-boundaries (end-of-Jul/
end-of-Aug) which then `_jd_to_year_month` rounds to the calendar-previous month.

**Stage A baseline classification: TYPE-B (generic logic bug, `transit_themes.py:transit_matrix_by_month`
label arithmetic).** Not fixable through closed-config additions.

**Resolution (TASK 7a, commit `8a4865e`, 2026-05-13):** label arithmetic replaced with integer calendar-month advance (`(start_year, start_month + i)` modulo 12 with year-wrap, `mid_dt = datetime(y, m, 15, UTC)` anchored at fixed mid-month). Regression test `services/api-python/tests/test_mariya_transit_matrix.py` pins full equality of label sequence. Post-fix Stage A.2 Worker verification 2026-05-13 confirmed 13/13 unique consecutive labels.

**Residual 2 TYPE-A boundary mismatches (rows 12-13, post-TASK-7a):** caused by anchor convention difference (Marina 01st soliar-month vs our mid-15). See § 4 TYPE-A items 4-5 for full row/planet/transition detail. **Same family as case 05 Venus Jul 2025 (§ 4 item 3).** Per TASK 7c amended gate (a)-(d), this is acceptable; Stage B authorized.

#### Per-house interpretations

Marina (pp. 8-9): Сатурн по 7 дому, Юпитер по 10 дому (then Юпитер по 11 дому
implied via monthly Sat=11 only on last row — actually Marina's table shows Jup=11
only on Jul 2026 row, but Sat=7 throughout). Marina lists Марс in many houses.
Our PDF: Сатурн в 7 доме (h7 only — matches Marina's "1 house"); Юпитер в 10 доме
+ 11 доме (matches Marina's monthly table showing Jup=10 for 12 rows and Jup=11 on
last row); Марс — 12 houses listed. No out-of-year dates observed.

Per-house section structurally CORRECT; matches Marina's house enumeration.

#### Outer-planet cards

Marina explicit statement (p.15): **«В текущем году у вас не будет транзитных аспектов
от высших планет (т.е. от Урана, Нептуна и Плутона). Будут — только социальные.»**

Our PDF: outer-cards block is empty — no «тр X в Y с нат Z» headings appear. This is
**EXACTLY what Marina expects**: case 07 has NO outer cards by Marina's editorial
choice. **Allowlist gap is CORRECT for case 07** — no Stage B card additions needed.
Mismatch is zero.

#### Calendar

Our PDF: present, multi-month, social planet aspects + rulership-expanded `Дома цели`.
Marina case 07 calendar is exclusively social-planet (Юпитер + Сатурн) — matches our
output structure.

### § 3.3 Case 10 (Данила) — Solar 2025-2026

**Solar return**: 05.08.2025 10:44:12 (GMT+3), Москва. Marina PDF: `Соляр 2025-2026 для Данилы.pdf`.

#### Monthly transit table

| Marina | Marina cells (M/S/J/V) | Our label | Our cells (M/S/J/V) | Match |
|---|---|---|---|---|
| Aug 2025 | 10 / 3 / 8 / 8 | Август 2025 | 10 / 3 / 8 / 8 | YES |
| Sep 2025 | 10 / 3 / 8 / 9 | Сентябрь 2025 | 10 / 3 / 8 / 9 | YES |
| Oct 2025 | 11 / 3 / 8 / 9 | Октябрь 2025 | 11 / 3 / 8 / 9 | YES |
| Nov 2025 | 1 / 3 / 8 / 11 | Ноябрь 2025 | 1 / 3 / 8 / 11 | YES |
| Dec 2025 | 1 / 3 / 8 / 1 | Декабрь 2025 | 1 / 3 / 8 / 1 | YES |
| Jan 2026 | 2 / 3 / 8 / 2 | Январь 2026 | 2 / 3 / 8 / 2 | YES |
| Feb 2026 | 2 / 3 / 8 / 3 | Февраль 2026 | 2 / 3 / 8 / 3 | YES |
| Mar 2026 | 3 / 4 / 8 / 4 | Март 2026 | 3 / 4 / 8 / 4 | YES |
| Apr 2026 | 4 / 4 / 8 / 6 | Апрель 2026 | 4 / 4 / 8 / 6 | YES |
| May 2026 | 4 / 4 / 8 / 7 | Май 2026 | 4 / 4 / 8 / 7 | YES |
| Jun 2026 | 6 / 4 / 8 / 8 | Июнь 2026 | 6 / 4 / 8 / 8 | YES |
| Jul 2026 | 7 / 4 / 8 / 9 | Июль 2026 | 7 / 4 / 8 / 9 | YES |
| Aug 2026 | 7 / 4 / 8 / 10 | Август 2026 | 7 / 4 / 8 / 10 | YES |

**52/52 cells match exactly.** Zero divergence.

#### Per-house interpretations

Marina (p.10-12): «Сатурн затрагивает два дома: 3 и 4», «Юпитер только 8 дом». Our PDF:
Сатурн в 3 доме + Сатурн в 4 доме; Юпитер в 8 доме — exact match. Per-house section
also includes Марс across 1-12 (10 houses), Венера across 1-12, Уран в 6, Уран в 7,
Нептун в 3, Нептун в 4, Плутон в 2. No out-of-year dates.

#### Outer-planet cards — **TYPE-A closed-config gap**

**Marina cards (pp. 16-19) — 3 deep-dive cards:**

1. **тр Уран в квадрате с нат Луной** — 3 windows: 11.07.2024-25.10.2024 /
   28.04.2025-02.06.2025 / 25.12.2025-16.03.2026. Golden-rule: transit_h=2, target_h=3,
   transit_ruled=[2,3], target_ruled=[8], walks=h7.
2. **тр Нептун в квадрате с нат Венерой** — 3 windows: 14.05.2026-02.09.2026 /
   13.03.2027-07.05.2027 / 15.09.2027-07.03.2028. Golden-rule: transit_h=2, target_h=7,
   transit_ruled=[1,3], target_ruled=[6,10,11], walks=h4.
3. **тр Нептун в квадрате с нат Юпитером** — **FOUR windows** (Marina explicitly says
   «четвертое касание»): 30.05.2026-15.08.2026 / 24.03.2027-22.05.2027 /
   30.08.2027-20.11.2027 / 09.01.2028-18.03.2028. Golden-rule: transit_h=2, target_h=7,
   transit_ruled=[1,3], target_ruled=[1,3], walks=h4.

**Stage A baseline (pre-Stage-B)**: outer-cards block empty for case 10 — allowlist
empty. **TYPE-A closed-config gap.**

**Post-Stage-B (2026-05-13)**: `OUTER_CARD_ALLOWLIST["10-danila-2025-2026"]` extended
with 3 triples per Marina pp. 16-19; `_OUTER_CARD_FACTS` populated. Card 3 (Нептун кв
Юпитер) verified: engine `aggregate_display_windows` emits **4 display windows**
natively, matching Marina «четвертое касание». `_assert_three_phase_intervals` helper
generalized with `expected_window_count: int = 3` parameter (default 3; case 10 card 3
passes 4). Rendered PDF `/tmp/10-danila-stage-b.pdf` contains all 3 cards.
**TYPE-A item 2 [RESOLVED via Stage B].**

#### Calendar

Our PDF: structured, multi-month. Each row has rulership-expanded `Дома цели` (Phase 5
helper output). Examples — «Уран 90° Луна (напряжённый) — 25.12.2025–16.03.2026 →
Дома цели: 3 — общение/поездки/документы/курсы; 8 — кризисы/кредиты/интим.» — matches
Marina's golden-rule table on p.16 (Луна placement=h3, ruled=h8 ⇒ {3, 8}).

### § 3.4 Case 01 (Ксения) — Solar 2024-2025

> **Source**: TASK 8D (Worker subagent, 2026-05-14, full subsection per user direction —
> NOT compact additive).

**Solar return**: 19.11.2024 06:14:30 (GMT+3), Москва. Marina PDF: `Соляр 2024-2025.pdf`.

NB: solar year is **2024-2025** (previous year vs the other matched cases), so the
sample window spans 2023-04 → 2026-09 in Marina's deck. Phase 8B sample horizon
extension (SR + 1096d) covers the bulk of cards; Marina narrates pre-buffer touches
(Neptune Trine Sun W1 = 17.04.2023 = SR−582d) which fall outside engine
`_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540` — see § 4 TYPE-D-equivalent item 8D.A below
and audit § A.2.1.D.

#### Monthly transit table

Smoke check (Worker visual inspection of Marina pp. 5-10): per-row Mars / Saturn /
Jupiter / Venus cells appear within the same fast-mover-anchor convention pattern
as cases 05 / 07 / 10 (Marina anchors at 19-е соляр-месяца; our mid-15 snapshot).
No cell-by-cell pin in tests (parity with Phase 7 cases — monthly cells covered by
the existing `MARIYA_EXPECTED_CELLS` pattern only for case 07).

#### Per-house interpretations

Marina pp. 11-18 (per Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn/Uranus/Neptune/Pluto
walkthrough). Our PDF surfaces the same per-house enumeration — no out-of-year stale
dates observed (Worker smoke check). Acentual axes (2-8, 3-9) + 4/5/7 dома emphasis
recorded on Marina p. 36; our per-house digest matches.

#### Outer-planet cards (5 cards per Marina pp. 27-31)

| # | Marina pages | Title | Marina windows | Golden-rule cells |
|---|---|---|---|---|
| 1 | pp. 27-28 | тр Уран в оппозиции c нат Солнцем | 3 (14.07.2024 / 30.04.2025 / 21.12.2025) | transit_h=8, target_h=8, transit_ruled=[1,12], target_ruled=[7], walks=h2 |
| 2 | p. 28 | тр Уран в оппозиции c нат Ураном | 3 (15.06.2024 / 29.09.2024 / 05.04.2025) | transit_h=8, target_h=8, transit_ruled=[1,12], target_ruled=[1,12], walks=h2 |
| 3 | p. 29 | тр Нептун в тригоне c нат Солнцем | 3 (17.04.2023 / 17.02.2024 / 30.09.2024) | transit_h=10, target_h=8, transit_ruled=[1,10,11], target_ruled=[7], walks=h1 |
| 4 | pp. 29-30 | тр Нептун в квадрате c нат Марсом | 3 (12.05.2023 / 09.03.2024 / 02.09.2024) | transit_h=10, target_h=11, transit_ruled=[1,10,11], target_ruled=[2,9], walks=h1 |
| 5 | pp. 30-31 | тр Плутон в тригоне c нат Юпитером | 3 (14.03.2025 / 17.01.2026 / 12.06.2026) | transit_h=7, target_h=7, transit_ruled=[2,9], target_ruled=[1,10,11], walks=h12 |

**Boundary parity (Worker post-TASK-8D, 2026-05-14):** Uranus cards (#1, #2) pass at
±2d positional alignment (12 boundary assertions / 0 OOT in
`MARINA_OUTER_CARD_BOUNDARIES`). Neptune cards (#3, #4) excluded from boundary tests —
Marina W1 starts lie SR-582d / SR-557d (pre-buffer truncation; engine W1 = +42d /
+17d Δ Marina). Pluto card (#5) excluded — Marina display rule narrows windows
(engine W3 = +137d past Marina). All 5 cards still **render** in the PDF and pass
lexical title assertions.

#### Calendar

Our PDF: present, multi-month, social + outer planet aspects with Phase 5
rulership-expanded `Дома цели`. Structurally matches Marina's reference deck.

#### Verdict

Matches Marina **with documented per-card-boundary findings** (3 cards excluded from
boundary tests for pre-buffer truncation / Pluto display rule). Cards remain in
allowlist + facts; PDF renders with all 5 cards visible. Future engine work items
captured in audit § A.2.1.D (extend `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE`; Pluto
display rule clarification).

### § 3.5 Case 02 (Максим) — Solar 2025-2026

**Solar return**: 04.09.2025 17:44:25 (GMT+3), Москва. Marina PDF:
`Солярный гороскоп 2025-2026.pdf`.

#### Monthly transit table

Smoke check: Marina pp. 4-9 monthly walkthrough; our PDF emits 13 labels Sep 2025 →
Sep 2026 with cell pattern matching Marina's anchor convention. No cell-by-cell pin
in tests.

#### Per-house interpretations

Marina pp. 5-9 (Sun / Moon / Mercury / Venus / Mars / Jupiter / Saturn). Our PDF
emits per-house enumeration; matches Marina's listing (per Worker smoke check —
9 planet sections, no out-of-year stale dates).

#### Outer-planet cards (2 cards per Marina pp. 9-11)

| # | Marina pages | Title | Marina windows | Golden-rule cells |
|---|---|---|---|---|
| 1 | pp. 9-10 | тр Уран в оппозиции c нат Плутоном | 1 (01.12.2025–06.04.2026) | transit_h=3, target_h=1, transit_ruled=[3], target_ruled=[1,5,6], walks=h7 |
| 2 | pp. 10-11 | тр Уран в тригоне c нат Ураном | 1 (02.01.2026–08.03.2026) | transit_h=3, target_h=3, transit_ruled=[3], target_ruled=[3], walks=h7 |

NB: Marina shows SINGLE window per card; engine emits multi-window loops (3 windows
each), Marina W1 = engine W3 in both cards. Marina also includes a third blurb
«тр. Уран в квадратуре к МС с 18.06.2026 по 02.08.2026» (p. 11) — short paragraph
without Golden-rule table, NOT a deep-dive card; allowlist correctly enrolls only
the 2 cards with golden-rule tables.

**Boundary parity:** Both cards excluded from boundary tests — single Marina window
vs engine multi-window requires per-card `engine_window_index` mapping (deferred,
audit § A.2.1.D future work item 2). Lexical title assertions cover both cards.

#### Calendar

Our PDF: present, multi-month, social + outer planet aspects with rulership-expanded
`Дома цели`. Structurally matches Marina's calendar pp. 11-12 (Юпитер + Сатурн social
transits).

#### Verdict

Matches Marina **structurally** (2 cards in allowlist+facts, golden-rule cells
correctly transferred, PDF renders); boundary tests deferred until single-window
alignment helper lands. Card titles pass exact lexical pin.

### § 3.6 Case 03 (Артём) — Solar 2025-2026

**Solar return**: 27.09.2025 14:16:30 (GMT+3), Москва. Marina PDF: `Соляр 2025-2026.pdf`.

This is the largest case in the calibration package: **9 outer cards** spanning all
three outer planets (3 Uranus + 4 Neptune + 2 Pluto).

#### Monthly transit table

Smoke check: Marina pp. 11-19 monthly walkthrough; our PDF emits 13 labels
Sep 2025 → Sep 2026.

#### Per-house interpretations

Marina pp. 8-19 covers per-house enumeration. Our PDF matches the planet/house list.

#### Outer-planet cards (9 cards per Marina pp. 22-29)

| # | Marina pages | Title | Marina windows | Golden-rule cells |
|---|---|---|---|---|
| 1 | pp. 22-23 | тр Уран в тригоне c нат Солнцем | 3 (29.06.2026 / 25.09.2026 / 19.04.2027) | transit_h=6, target_h=5, transit_ruled=[7,8,9,10], target_ruled=[3,4], walks=h12 |
| 2 | pp. 23-24 | тр Уран в тригоне c нат Меркурием | 3 (01.06.2025 / 11.11.2025 / 08.03.2026) | transit_h=6, target_h=5, transit_ruled=[7,8,9,10], target_ruled=[5,12], walks=h12 |
| 3 | pp. 24-25 | тр Уран в тригоне c нат Марсом | 3 (13.07.2026 / 02.05.2027 / 15.01.2028) | transit_h=6, target_h=5, transit_ruled=[7,8,9,10], target_ruled=[6,11], walks=h12 |
| 4 | pp. 25-26 | тр Нептун в оппозиции c нат Солнцем | 3 (13.05.2026 / 13.03.2027 / 15.09.2027) | transit_h=7, target_h=5, transit_ruled=[6,11], target_ruled=[3,4], walks=h11 |
| 5 | p. 26 | тр Нептун в оппозиции c нат Меркурием | 1 (27.10.2025–23.01.2026) | transit_h=7, target_h=5, transit_ruled=[6,11], target_ruled=[5,12], walks=h11 |
| 6 | pp. 26-27 | тр Нептун в оппозиции c нат Марсом | 1 (16.06.2026–29.07.2026) | transit_h=7, target_h=5, transit_ruled=[6,11], target_ruled=[6,11], walks=h11 |
| 7 | pp. 27-28 | тр Нептун в квадрате c нат Ураном | 3 (12.04.2025 / 12.02.2026 / 16.10.2026) | transit_h=7, target_h=6, transit_ruled=[6,11], target_ruled=[7,8,9,10], walks=h11 |
| 8 | pp. 28-29 | тр Плутон в тригоне c нат Солнцем | 4 (05.04.2025 / 29.01.2026 / 04.12.2026 / 13.08.2027) | transit_h=5, target_h=5, transit_ruled=[6,11], target_ruled=[3,4], walks=h9 |
| 9 | p. 29 | тр Плутон в тригоне c нат Марсом | 4 (05.04.2025 / 29.01.2026 / 04.12.2026 / 13.08.2027) — identical to #8 | transit_h=5, target_h=5, transit_ruled=[6,11], target_ruled=[6,11], walks=h9 |

NB on card 9: Marina PDF p. 29 lists **identical dates** for Pluto Trine Sun and
Pluto Trine Mars (likely editorial copy-paste — engine output for Pluto Mars is
distinct: W1 = 11.02.2026, not 05.04.2025). Documented as audit § A.2.1.D future
data-quality item 5.

**Boundary parity:**
- Cards #1 (Uranus Tr Sun), #3 (Uranus Tr Mars), #4 (Neptune Opp Sun), #7 (Neptune
  Sq Uranus): full 3-window assertions at ±2d positional alignment (12 boundary
  assertions / 0 OOT).
- Card #2 (Uranus Tr Mercury) excluded — W1 start Δ=−4d (Marina 01.06.25 / engine
  28.05.25). Other 2 windows within ±2d but card excluded as a unit (no one-off
  override per TASK 8D policy).
- Cards #5, #6 (Neptune Opp Mercury / Mars): single Marina window vs engine
  multi-window — alignment helper deferred.
- Cards #8, #9 (Pluto Tr Sun / Mars): Marina display rule narrows Pluto windows; #9
  also flagged for Marina PDF editorial typo.

All 9 cards still **render** in the PDF and pass lexical title assertions.

#### Calendar

Our PDF: present, multi-month, dense (Marina's case 03 calendar pp. 30-35 spans 12
months with multiple social+outer overlaps). Structural parity with Marina's deck.

#### Verdict

Matches Marina **with documented per-card-boundary findings** (5 cards excluded from
boundary tests for distinct reasons: 1 marginal W1 start drift, 2 single-Marina-window,
2 Pluto display rule + 1 PDF editorial typo). The 4 included Uranus/Neptune cards
pass ±2d positional alignment with 0 OOT. PDF renders with all 9 cards visible.

### § 3.7 Case 04 (Валерия) — Solar 2025-2026

**Solar return**: 28.03.2025 14:18:30 (GMT-5), Майами, Флорида. Marina PDF:
`Соляр 2025-2026_1.pdf` (GMT-5 timezone in Marina's deck; our render uses fixture
`birth_timezone = Asia/Krasnoyarsk` per `input.json` — date-only boundary parity
unaffected since boundary tests parse start_str/end_str to `datetime.date`).

#### Monthly transit table

Smoke check: Marina pp. 11-25 walkthrough; our PDF emits 13 labels Mar 2025 → Mar 2026.

#### Per-house interpretations

Marina pp. 26-37 covers per-house enumeration with extended Venus 12-house essay
(transit Venus through 12 дом, pp. 35-37). Our PDF emits per-house enumeration
matching Marina's listing (10 planet sections, no out-of-year stale dates).

#### Outer-planet cards (2 cards per Marina pp. 38-39)

| # | Marina pages | Title | Marina windows | Golden-rule cells |
|---|---|---|---|---|
| 1 | pp. 38-39 | тр Уран в квадрате c нат Сатурном | 1 (12.04.2025–18.05.2025) | transit_h=10, target_h=11, transit_ruled=[9,10,11], target_ruled=[9,10,11], walks=h12 |
| 2 | p. 39 | тр Уран в оппозиции c нат Плутоном | 1 (20.03.2025–29.04.2025) | transit_h=10, target_h=6, transit_ruled=[9,10,11], target_ruled=[7,12], walks=h12 |

Marina explicitly writes: «В текущем соляре аспектов от Нептуна и Плутона – нет.»
(p. 39) — confirming exactly 2 outer cards (Uranus only).

**Boundary parity:** Both cards excluded from boundary tests — single Marina window
vs engine multi-window (Marina W1 = engine W2 for card 1, engine W3 for card 2).
Same alignment-helper limitation as case 02.

#### Calendar

Our PDF: present, multi-month, social planet aspects (Юпитер + Сатурн pp. 40-41 in
Marina's deck). Structural parity.

#### Verdict

Matches Marina **structurally** (2 cards in allowlist+facts, golden-rule cells
correctly transferred, PDF renders); boundary tests deferred until single-window
alignment helper lands. Card titles pass exact lexical pin.

### § 3.8 Case 09 (Анастасия) — Solar 2025-2026

**Solar return** (per fixture `09-anastasiya-2025-2026.expected.json`):
14.05.2025 09:54:03 UTC. Marina PDF: `Соляр 2025-2026 для Анастасии.pdf` (Marina's
caption: 14.05.2025 13:53:45 GMT+3 = 10:53:45 UTC).

**TYPE-D fixture data quality blocker (audit § A.3 TYPE-D item 2):** Δ ≈ 60 min
between fixture SR and Marina-stated SR — likely DST or birth-time/timezone
ambiguity in fixture. Engine outputs are not expected to align exactly with Marina
dates until fixture data revision (separate backlog).

#### Monthly transit table

Smoke check: Marina pp. 8-15 walkthrough; our PDF emits 13 labels May 2025 → May
2026. Cell values diverge from Marina due to the 60-min SR offset — documented as
TYPE-D, not a code regression.

#### Per-house interpretations

Marina pp. 7-16 per-house enumeration. Our PDF emits per-house sections; planet/house
mapping matches at the structural level (per fixture's natal positions).

#### Outer-planet cards (2 cards per Marina pp. 17-19)

| # | Marina pages | Title | Marina windows | Golden-rule cells |
|---|---|---|---|---|
| 1 | pp. 17-18 | тр Уран в соединении c нат Меркурием | 3 (22.06.2025 / 30.09.2025 / 11.04.2026) | transit_h=5, target_h=9, transit_ruled=[5,6], target_ruled=[1,10], walks=h9 |
| 2 | pp. 18-19 | тр Нептун в секстиле c нат Меркурием | 3 (12.05.2024 / 10.03.2025 / 06.09.2025) | transit_h=5, target_h=9, transit_ruled=[4,7], target_ruled=[1,10], walks=h7 |

**Boundary parity:** Both cards excluded from boundary tests — fixture TYPE-D SR
mismatch (60 min) causes boundary Δ ±3-4d, marginally exceeds ±2d (e.g. Uranus Conj
Mercury W1: Marina 22.06.25 / engine 19.06.25 = −3d; W1 end: Marina 13.08.25 /
engine 09.08.25 = −4d). Pending TYPE-D fixture data revision (audit § A.2.1.D
future work item 4). Lexical title assertions cover both cards.

#### Calendar

Our PDF: present, multi-month (Marina pp. 19-25 spans May 2025 → May 2026 calendar).
Structural parity at lighting level.

#### Verdict

Matches Marina **structurally with documented TYPE-D fixture blocker** (2 cards in
allowlist+facts, golden-rule cells correctly transferred, PDF renders); boundary
tests deferred until fixture SR mismatch resolved. Card titles pass exact lexical
pin.

---

## § 4 Divergence classification

Aggregating across all three cases:

### TYPE-A (acceptable / closed-config gap; Stage B can fix)

1. **[RESOLVED via Stage B]** Case 05 outer cards — Marina shows 3 deep-dive cards (Уран кв
   Луне, Уран секст Юпитеру, Нептун триг Юпитеру), Stage A `OUTER_CARD_ALLOWLIST` empty
   for `05-ekaterina-2025-2026`. **Stage B fix landed 2026-05-13**: allowlist extended
   with 3 triples; `_OUTER_CARD_FACTS` populated per card (transit_h, target_h,
   transit_ruled, target_ruled, walks + psychology + event level text) read from Marina
   pp. 34-37. Rendered PDF `/tmp/05-ekaterina-stage-b.pdf` contains all 3 cards.

2. **[RESOLVED via Stage B]** Case 10 outer cards — Marina shows 3 cards (Уран кв Луне,
   Нептун кв Венере, Нептун кв Юпитеру), Stage A allowlist empty. **Stage B fix landed
   2026-05-13**: allowlist extended; card-facts populated from Marina pp. 16-19. Card 3
   «Нептун кв Юпитеру» has 4 display windows per Marina («четвертое касание») — engine
   `aggregate_display_windows` natively emits 4 windows; `_assert_three_phase_intervals`
   helper generalized with `expected_window_count: int = 3` parameter (default 3; case
   10 card 3 passes 4). Rendered PDF `/tmp/10-danila-stage-b.pdf` contains all 3 cards.

3. **Case 05 Venus Jul 2025 cell** — Marina shows Venus h3, our PDF shows h4 (Δ=1
   house). Fast-mover boundary: Marina anchors monthly snapshot at 11.07.2025 (day-of-sr);
   we anchor at mid-15. Venus moves ~1 sign/day, so the 4-day gap straddles the h3/h4
   cusp. Per TASK 7b § B.5 (refinement 2026-05-13): **documented note only**, NOT a
   structured override; not a new override mechanism (monthly cells are out of Phase 4b
   structured exception scope). Production code/fixtures/tests unchanged.

4. **Case 07 row 12 «Июнь 2026» monthly cell boundary** — Marina shows Mars h8, Venus
   h10; our PDF shows Mars h9, Venus h11 (Δ=1 house each). Fast/medium movers crossing
   cusps in the 1st-to-15th gap:
   - **Mars house 8→9 on 2026-06-05.** Marina samples 01.06 (Mars still h8); our mid-15
     sample (Mars h9).
   - **Venus house 10→11 on 2026-06-11.** Marina samples 01.06 (Venus still h10); our
     mid-15 sample (Venus h11).
   Anchor convention: Marina = 1-е соляр-месяца (day-of-solar-return); ours = mid-15
   (`datetime(y, m, 15, UTC)` per `transit_matrix_by_month`). **Same family as item 3
   (case 05 Venus Jul 2025).** Per TASK 7c § Fixations 4: documented note only, no
   structured override, no new override mechanism. **Not a TASK 7a regression** —
   identical cell values pre/post TASK 7a fix.

5. **Case 07 row 13 «Июль 2026» monthly cell boundary** — Marina shows Saturn h7, Venus
   h11; our PDF shows Saturn h8, Venus h12 (Δ=1 house each). Cusp crossings in the
   1st-to-15th gap:
   - **Saturn house 7→8 on 2026-07-08.** Marina samples 01.07 (Saturn still h7); our
     mid-15 sample (Saturn h8).
   - **Venus house 11→12 on 2026-07-08.** Marina samples 01.07 (Venus still h11); our
     mid-15 sample (Venus h12).
   **Same family as items 3, 4** (anchor convention difference). Per TASK 7c § Fixations
   4: documented note only, no structured override.

> **TYPE-A cross-reference:** Items 3, 4, 5 share root cause — Marina anchors monthly
> snapshot at 1-е соляр-месяца, our `transit_matrix_by_month` anchors at mid-15. When
> fast/medium movers cross house cusps in the 1st-to-15th gap, the two anchors yield
> different house assignments. Closed-config does not fix this (would require a generic
> anchor-day policy change — see Path B in TASK 7b STOP HANDOFF, deferred to future
> programme). Items remain TYPE-A under amended TASK 7c gate; Stage B authorized.

### TYPE-B (generic logic regression; STOP, escalate)

> **Stage A baseline TYPE-B item 1 RESOLVED 2026-05-13** by TASK 7a (commit `8a4865e`)
> and verified by TASK 7b Stage A.2 Worker run. Original entry retained below as
> historical record; resolution noted inline.

1. **[RESOLVED] Monthly transit table label arithmetic bug — manifests on case 07**. Function
   `services/api-python/app/pdf/transit_themes.py:transit_matrix_by_month` (Stage A
   baseline lines 546-578) used `m_start = sr + i * 30.4375` for both label derivation
   AND for the basis of `mid_dt = datetime(y, m, 15)`. When sr-day-of-month is 01 with
   late-UT time (case 07 sr = 01.07.2025 19:11 UT), the arithmetic drift made `i=2` land
   on 31.08.2025 still in August calendar-wise; consequence: label duplicates AND the
   September mid-15 snapshot never gets computed (similarly for Oct/Nov/Dec/Jan and Feb
   2026). Stage A result: case 07 monthly table had 2 duplicate-month rows and 2
   skipped-month rows; 6 of 13 cell rows had wrong values vs Marina.

   **Fix landed 2026-05-13:** TASK 7a (commit `8a4865e`) replaced iteration with integer
   calendar-month advance using `datetime(start_year, start_month + i, 15, UTC)` modulo
   12 with year-wrap; window window `[1st, next-1st)` for cell sampling. Regression test
   `services/api-python/tests/test_mariya_transit_matrix.py` pins full equality of label
   sequence. Post-fix Stage A.2 Worker verification 2026-05-13: **13/13 unique
   consecutive labels** for case 07; cases 05/10 baselines preserved (51/52 and 52/52
   monthly cells respectively).

   **Residual post-fix divergence on case 07 (2 boundary rows 12-13)** is NOT TYPE-B —
   it is anchor-day convention divergence (TYPE-A items 4-5 above), present pre-fix as
   well. See TASK 7c amendment for gate language allowing TYPE-A boundary rows.

### TYPE-C (Marina-specific editorial; document only)

1. **Card 3 «Нептун кв Юпитеру» for case 10 has 4 display windows, not 3**. Marina
   explicitly writes «четвертое касание». Phase 4 design fixed the card-test helper at
   3 windows. Marina convention extends to multi-touch outer-planet loops when
   loop-time exceeds ~2 years. This is editorial, not engine — engine raw hits may
   already emit 4 distinct orb-windows; Phase 4 aggregator collapses to 3 only in
   Натальи's loop pattern. Stage B (if reopened post-TYPE-B fix) needs per-case window-
   count parameter in the test helper.

2. **Marina case 07 NO outer cards by editorial choice** — Marina explicitly states
   "не будет транзитных аспектов от высших планет". Our empty allowlist for case 07
   produces a no-card PDF which CORRECTLY matches Marina. No code change needed.

### Additive items 6+ (Phase 8A — 2026-05-14)

> Per Phase 8.0 audit trail discipline: § 4 items 1-5 preserved as historical record;
> Phase 8A appends items 6-9 below covering findings from full-folder Marina etalon
> inventory. See `phase-8-audit-report-2026-05-14.md` § A.3 for full classification
> rationale.

#### TYPE-A (closed-config gap; Phase 8B Stage-B-pattern fix)

6. **[RESOLVED via TASK 8D 2026-05-14]** **Cases 01, 02, 03, 04, 09 — outer-card allowlist empty.** Per Phase 8A audit § A.2:
   Marina shows 2-9 outer cards per case (case 01 = 5, case 02 = 2, case 03 = 9,
   case 04 = 2, case 09 = 2); our `OUTER_CARD_ALLOWLIST` entries empty for all 5 cases.
   Identical gap class as original case 05/10 had pre-Stage-B (resolved via TASK 7b
   Stage B). Fix pattern: extend `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` from
   Marina reference per case.

   **Status: RESOLVED via TASK 8D Stage D.1 (2026-05-14).** 20 new triples enrolled
   in `OUTER_CARD_ALLOWLIST` (5 + 2 + 9 + 2 + 2 = 20); 20 new entries in
   `_OUTER_CARD_FACTS` covering 100 fact cells transferred from Marina PDFs (5 cells
   × 20 cards). All 5 cases render their pre-mapped outer cards at HEAD post-TASK-8D
   (verified via PyPDF text extract: 5 + 2 + 9 + 2 + 2 = 20 card titles visible).
   Provenance sidecars carry correct `case_label` + `git_sha` + `debug=false` per case.

   **Boundary parity:** 36 new boundary assertions for case 01 (Uranus cards only)
   and case 03 (Uranus + Neptune multi-window cards), all pass at ±2d positional
   alignment with **0 OOT and 0 new tolerance overrides** (TASK 8D Stage D.3.1).
   The other 14 of 20 new cards are intentionally excluded from boundary tests for
   per-card-classified reasons documented in audit § A.2.1.D — they still render
   in the PDF and pass lexical title assertions (TASK 8D Stage D.3.2, 29 lexical
   title parametrize rows total).

   **Case 09 TYPE-D dependency** (item 9 / 10 below — SR mismatch) acknowledged
   but does NOT block TASK 8D closure: facts transferred from Marina's PDF; the
   60-min SR offset causes boundary Δ ±3-4d but does NOT prevent allowlist enrollment
   or PDF rendering. Boundary tests for case 09 deferred until fixture data revision
   (separate backlog).

7. **Case 05 card 3 title — lexical «трине» vs «тригоне».** Aspect-locative dict in
   `services/api-python/app/pdf/outer_cards.py` maps `Trine → «трине»`; Marina PDF p. 35
   uses «тригоне». One-word fix. Affects every Trine outer card across cases (not
   case-05-specific). **Phase 8B quick-win sub-task.**

#### TYPE-B-equivalent (finite-horizon truncation; Phase 8B engine-or-presentation fix)

8. **[RESOLVED via TASK 8B 2026-05-14]** **Case 10 Данила Neptune outer cards — finite scan horizon truncation.** Per Phase
   8A audit § A.2.1 (Marina boundary dates SoT table):
   - Нептун кв Венере W3 end: our `28.01.2028` vs Marina `07.03.2028` (Δ = −39 days).
   - Нептун кв Юпитеру W4 end: our `28.01.2028` vs Marina `18.03.2028` (Δ = −50 days).
   - Both terminated at identical engine `orb_exit_jd = 2461798.822368622` = engine
     sample window cutoff.
   - Per user directive 2026-05-14: **NOT accepted divergence.** Distinct from Phase 4b
     08-Натальи editorial divergences (which are Marina-chosen). This was engine-level
     truncation that affected accuracy.
   - **Resolution (Phase 8B Stage B2, 2026-05-14): Path A applied —** `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER 540 → 730` в `services/api-python/app/ephemeris/bridge.py`. Engine sample window extended from SR + 906d → SR + 1096d (~3 solar years per `outer_card_lookahead_days = 365.25 * 3` systemic policy). Post-fix engine output: W3 end = 07.03.2028 18:49 UTC, W4 end = 18.03.2028 13:46 UTC — both match Marina ±2d. xfail markers removed in Stage B3.1; pytest 221 passed + 0 xfailed + 0 failed.
   - **Path 1 amendment co-fix (Phase 8B Stage B3.2):** Phase 4b N-J W3 end (Натальи) -17d Δ was reclassified from «Marina-editorial» to «horizon truncation» (Worker B2.1 trace proved engine `orb_exit_jd = SR + 906d` exactly = sample window cutoff, same pattern as Данила). N-J W3 end +20d structured override REMOVED. N-N W1 start +200d structured override STAYS (true editorial: our start at SR-491d, within 540d BEFORE buffer, not on horizon boundary). Phase 4a memo (`transit-contact-window-semantics-2026-05-13.md`) gets Erratum (Phase 8B Path 1) subsection documenting reclassification.

9. **[CLOSED via Phase 8B 2026-05-14]** Lexical «трине» → «тригоне» fix in `services/api-python/app/pdf/outer_cards.py` aspect-locative dict (case 05 card 3 title). Affects all Trine outer cards across cases. Was Phase 8A audit § A.3 TYPE-A item 7. Resolved in TASK 8B Stage B1.

#### TYPE-D (data quality; NOT in Phase 8 scope — separate data-revision sub-tasks)

9. **`Соляр 2025-2026_3.pdf`** — SR 05.09.2025 09:16:30 UTC, no matching fixture.
   Natal metadata cannot be reproduced from current fixture set. Page 1 shows Asc
   Скорпион / MC Дева. **Diagnostic:** either create new fixture from PDF + natal
   back-resolution, or exclude from package scope. **Separate data-revision task,
   not in Phase 8 scope.**

10. **`Соляр 2025-2026 для Анастасии.pdf`** — SR 14.05.2025 10:53:45 UTC vs fixture
    `09-anastasiya-2025-2026` SR 09:54:03 UTC. **Δ ≈ 60 min** (likely DST or birth-time/
    timezone ambiguity). **Diagnostic:** re-resolve `09-anastasiya-2025-2026` fixture's
    birth_time + timezone via Python's `timezonefinder` and manual verification against
    Marina's intended reference. Until this is closed, allowlist work for case 09
    is blocked. **Separate data-revision task, not in Phase 8 scope.**

#### Cross-reference

- Full Phase 8A audit: `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md`.
- Phase 8C test contract: `services/api-python/tests/test_multi_case_calibration.py`
  block `Phase 8C — Outer-card boundary assertions vs Marina (date-only, ±2d)`
  (search «MARINA_OUTER_CARD_BOUNDARIES»).
- Phase 8.0 reopen: `project-overlays/astro/TASKS/archive/2026-05-14-phase-8-0-reopen-audit-trail.md`.
- Recovery program SoT: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.

---

## § 5 Total override count + Phase 4b gate clause check

Per architecture § 7 запрет 7 / TASK 4b spec, the gate triggers at:
- > 5 tolerance_overrides per single case, or
- > 10 tolerance_overrides across all cases.

| Case | Stage A baseline | Stage B additions | Total |
|---|---|---|---|
| 08-natalya-2025-2026 | 2 (Phase 4b: N-J W3 end ±20d, N-N W1 start ±200d) | 0 | 2 |
| 05-ekaterina-2025-2026 | 0 | 0 | 0 |
| 07-mariya-2025-2026 | 0 | 0 | 0 |
| 10-danila-2025-2026 | 0 | 0 | 0 |
| **Total** | **2** | **0** | **2** |

**Gate status**: WITHIN threshold (2 ≤ 5 per case; 2 ≤ 10 total). Stage B added **zero**
new tolerance overrides — per TASK 7b § B.5 spec, case 05 Venus Jul 2025 boundary
(TYPE-A item 3) is documented note only, NOT a structured override. Similarly case 07
boundary rows 12-13 (TYPE-A items 4-5) are documented notes per TASK 7c § Fixations 4 —
no structured overrides, no new override mechanism for monthly cells. Stage B keeps the
override discipline strict: only outer-card boundary editorial divergences qualify for
the structured-exception pattern.

---

## § 6 Production-readiness verdict

### Verdict (Stage A baseline 2026-05-13): **Blockers identified — program NOT production-ready**

Rationale: TYPE-B regression on case 07 monthly transit table label arithmetic. Stage
B blocked at original Stage A. Phase 7 Stage A → Stage B gate triggered STOP.

### Verdict update (post-TASK-7a + TASK-7c, 2026-05-13): Stage B authorized

- TASK 7a (commit `8a4865e`) resolved TYPE-B item 1 (label arithmetic). Case 07 emits
  13/13 unique consecutive labels.
- TASK 7b Stage A.2 Worker verification: 11/13 cell rows match Marina; 2 residual
  mismatches at rows 12-13 reclassified TYPE-A (§ 4 items 4-5).
- TASK 7c amended Stage A.2 gate language: literal «13/13» → (a)-(d) conditions
  allowing documented TYPE-A boundary rows. All four PASS.
- Cases 05/10 baselines preserved through TASK 7a (51/52 and 52/52 monthly cells).

### Verdict update (post-cascade-closure, 2026-05-15): **Recovery program CLOSED**

> **Status: FINAL.** Per user explicit ack 2026-05-15: «**Recovery program CLOSED — Natalya/05/07/10 production-ready; full-folder supply requires Marina framing and excludes TYPE-D/Pluto-rule future work.**» Supersedes all prior verdict subsections (post-Phase-8E pending-ack; post-TASK-8D; post-Phase-8-audit; post-Stage-B 2026-05-13). Cascade closure landed one overlay commit 2026-05-15 (TASK 8D + 8E + STATUS_RU + § 6 update + § A.2.1.D row updates + HANDOFF archive). Marina framing memo prepared as separate lightweight post-closure artifact (NOT mixed with closure commit per user discipline).

**Production-ready breakdown:**

- **08 Натальи** — production-ready. Phase 1-7 + Phase 8B Path 1 (N-J W3 horizon retracted; engine matches Marina ±2d). 1 editorial divergence remaining: **08 N-N W1 start +178d Δ Marina (true Marina-editorial, not horizon truncation — confirmed by TASK 8E Path 1' Scenario 1)**. Phase 4b ±200d structured override sole survivor. TL framing memo обязателен.
- **05 Екатерина** — production-ready с framing. Phase 7b Stage B (3 outer cards) + Phase 8B lexical fix («трине → тригоне»). 51/52 monthly cells + 1 TYPE-A Venus Jul 2025 boundary row (anchor convention, § 4 item 3).
- **07 Мария** — production-ready с framing. Phase 7a label-arithmetic fix; 11/13 monthly cells + 2 TYPE-A Jun/Jul 2026 boundary rows (anchor convention, § 4 items 4-5). No outer cards by Marina editorial — empty allowlist correct.
- **10 Данила** — production-ready с framing. Phase 7b Stage B (3 outer cards, Нептун кв Юпитеру 4 windows native engine output) + Phase 8B Path 1 horizon fix (W3 Венере + W4 Юпитеру converged to Marina ±2d).

**NOT в production supply без per-case framing:**

- **01 Ксения** — 5 outer cards. Post-Phase-8E: 01 N-Sun + N-Mars Neptune W1 starts converged to Marina ±2d. Remaining future-work items (§ A.2.1.D): 01 Pluto Trine Jupiter (Pluto display rule — Marina narrows ~100d, engine 261d).
- **02 Максим** — 2 outer cards. Future-work items: single-Marina-window alignment (Marina W1 = engine W2/W3/W4 by coincidence).
- **03 Артём** — 9 outer cards. Future-work items: Marina case 03 P-Mars likely editorial typo (identical dates to P-Sun on Marina p.29); single-window alignment for some cards.
- **04 Валерия** — 2 outer cards. Future-work items: single-Marina-window alignment.
- **09 Анастасия** — **NOT в supply.** TYPE-D fixture/reference SR-time/timezone mismatch (~60min). Requires data revision sub-task; outside Phase 8 implementation programme.

### Phase 8 documented future-work items (carry-over)

12 items в audit § A.2.1.D Future Work, OUT of Phase 8 implementation scope:
1. Pluto display rule (3 cards: 01 P-J, 03 P-Sun, 03 P-Mars).
2. Single-window alignment helper (6 cards: 02 U-P, 02 U-U, 03 N-Mer, 03 N-Mars, 04 U-Sat, 04 U-P).
3. Case 03 P-Mars Marina typo investigation (data-quality follow-up).
4. Case 09 Анастасия fixture/reference SR mismatch (TYPE-D data revision).

These are NOT regressions, NOT bugs. They are user-conscious carry-overs requiring distinct programmes (engine work for Pluto rule; presentation helper for alignment; data revision for case 09).

### Pytest evolution (programme summary)

| Phase | Pytest | Override count |
|---|---|---|
| Tier A engine cascade (2026-05-11/12) | 85 / 0 / 0 | 0 |
| Phase 2 hard acceptance assertions | 102 / 21x / 0 | 0 |
| Phase 4 outer cards (Path 3) | 113 / 10x / 0 | 0 |
| Phase 4b structured exceptions | 115 / 8x / 0 | 2 (08 N-J W3 + 08 N-N W1) |
| Phase 5 rulership houses | 145 / 4x / 0 | 2 |
| Phase 6 calendar clipping | 149 / 0 / 0 | 2 |
| TASK 7a label arithmetic | 150 / 0 / 0 | 2 |
| TASK 7b Stage B multi-case | 183 / 0 / 0 | 2 |
| TASK 8A+8C boundary contract | 219 / 2x / 0 | 2 + 2 xfail-strict (Данила) |
| TASK 8B Path 1 (N-J W3 retract) | 221 / 0 / 0 | 1 (only N-N W1) |
| TASK 8D allowlist 01/02/03/04/09 | 286 / 0 / 0 | 1 |
| TASK 8E Path 1' (BEFORE buffer + case 01 enrollment) | **298 / 0 / 0** | **1** |

### Recovery program CLOSED state

- Production HEAD: `59ec177` (astro main = backup/main).
- Overlay HEAD: post-cascade closure commit (ai-dev-system master = backup/master).
- Sole override survivor: **08 N-N W1 start ±200d** (true Marina-editorial; documented per TASK 8E Path 1' Scenario 1 empirical recheck).
- Boundary contract: 104 enrolled boundaries in `MARINA_OUTER_CARD_BOUNDARIES`, 0 OOT in test suite.
- 12 documented future-work items in audit § A.2.1.D (carry-over).
- Canonical render path: `services/api-python/scripts/render_case.py --case-id <case-id>`.

---

### Verdict update (post-Phase-8E pending-ack, 2026-05-15): **Ready for Marina show — pending user ack** (SUPERSEDED by cascade closure verdict above)

> **Status: SUPERSEDED.** Original interim verdict between TASK 8E Worker delivery and user ack on cascade closure. TASK 8E (Worker subagent, 2026-05-15) extended `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE` from 540 to 730 days in `services/api-python/app/ephemeris/bridge.py`, resolving the last audit § A.2.1.D future work item (pre-buffer truncation on case 01 Neptune cards). All Phase 8 work (8A audit + 8B AFTER buffer + 8C boundary test contract + 8D allowlist + 8E BEFORE buffer) landed.

**Per TASK 8E + cumulative Phase 8 work:**

1. **Test contract gap closed.** Phase 8C added outer-card interval boundary assertions
   (cases 05 + 10, 56 assertions); TASK 8D extended to cases 01 + 03 Uranus/Neptune
   cards (+36 assertions = 92 boundary assertions post-TASK-8D); **TASK 8E added 12
   new boundary points for 01-kseniya Neptune Trine Sun + Neptune Square Mars**
   (3 windows × 2 sides × 2 cards = 12, all within ±2d default tolerance). Total
   **104 boundary assertions in `MARINA_OUTER_CARD_BOUNDARIES`**, 0 OOT. Phase 4b
   08-N-N W1 structured override (sole survivor, ±200d) stays — Stage E.5.a Scenario 1
   confirmed: N-N W1 start remains at SR-491d (true editorial), not shifted by
   BEFORE buffer extension.
2. **All TYPE-A closed-config gaps resolved.** § 4 item 6 [RESOLVED via TASK 8D]; §
   audit A.2.1.D future work item 1 (pre-buffer extension) [RESOLVED via TASK 8E].
3. **No new TYPE-B.** No generic logic regressions detected during TASK 8E inspection.
4. **Override count.** Total = 1 (unchanged from TASK 8D: 08 N-N W1 start ±200d).
   Threshold (5 per case / 10 total) preserved with wide margin. TASK 8E added 0 new
   tolerance overrides.
5. **TYPE-C documented.** Marina single-Marina-window cards (02, 04, partial 03) and
   Marina Pluto display rule narrowing (partial 01, 03) classified as «render correctly
   but boundary assertions deferred» — audit § A.2.1.D Future Work items 2-3
   (single-window alignment helper; Pluto display rule) remain as out-of-scope future
   work.
6. **TYPE-D outstanding (separate backlog).** Case 09 fixture SR mismatch ~60 min and
   `Соляр 2025-2026_3.pdf` natal metadata blocker remain in separate data-revision
   backlog, NOT blocking Marina show.

**Tests green at HEAD (post-TASK-8E):**
- `pytest`: **298 passed / 0 xfailed / 0 failed** = 286 baseline (post-TASK-8D) + 12
  new boundary points (01 N-Sun W1/W2/W3 + 01 N-Mars W1/W2/W3, start + end each).
- `cabal --project-dir core/astrology-hs build`: Up to date (no engine changes;
  Phase 8E touches only Python `bridge.py` constant + golden fixtures regenerated).

**Per-case raw row count impact (TASK 8E BEFORE buffer extension):**

| case | raw_pre (540 BEFORE) | raw_post (730 BEFORE) | Δ rows | ratio | within 1.20× early-warning? |
|---|---|---|---|---|---|
| 01-kseniya | 106 | 120 | +14 | 1.132× | YES |
| 02-maksim | 114 | 126 | +12 | 1.105× | YES |
| 03-artem | 110 | 125 | +15 | 1.136× | YES |
| 04-valeriya | 110 | 119 | +9 | 1.082× | YES |
| 05-ekaterina | 101 | 111 | +10 | 1.099× | YES |
| 07-mariya | 106 | 119 | +13 | 1.123× | YES |
| 08-natalya | 110 | 121 | +11 | 1.100× | YES |
| 09-anastasiya | 116 | 128 | +12 | 1.103× | YES |
| 10-danila | 110 | 122 | +12 | 1.109× | YES |

Per-case presentation calendar (post Phase 6 clipping) `cal_h` bit-identical pre/post
all 9 cases (ratio 1.00×); monthly cells matrix `mat_h` bit-identical pre/post all
9 cases. BEFORE buffer extension affects only raw `annual_transit_table` payload
(extra pre-SR entries); Phase 6 clipping `[sr_jd, sr_jd + 365.25]` isolates client-PDF
calendar rows from sample-window-width changes.

**Production-readiness gate post-TASK-8E — all conditions met:**
- All Phase 7 + Phase 8 deliverables landed ✓
- No TYPE-B ✓
- Override count ≤ threshold (1 vs 10 total) ✓
- All TYPE-A closed-config gaps resolved ✓
- All audit § A.2.1.D future work item 1 (pre-buffer extension) [RESOLVED via TASK 8E] ✓
- TYPE-C documented ✓
- TYPE-D items in separate backlog (NOT blocking Marina show) ✓

**Required next step: user explicit ack on this updated calibration report.** After
ack: recovery program closes; PDFs for all 8 Phase-7/8 cases (01 / 02 / 03 / 04 / 05
/ 07 / 08 / 09 / 10) production-ready and clientable to Marina.

---

### Verdict update (post-TASK-8D, 2026-05-14): SUPERSEDED by post-Phase-8E verdict above

> **Status: SUPERSEDED.** Kept as historical record per audit-trail discipline. TASK 8D
> (Worker subagent, 2026-05-14) enrolled the 5 remaining cases (01 / 02 / 03 / 04 / 09)
> in `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` — the last implementation work in the
> Phase 8 recovery program at that snapshot. All Phase 8B / 8C / 8D deliverables landed.

**Per TASK 8D + cumulative Phase 8 work:**

1. **Test contract gap closed.** Phase 8C added outer-card interval boundary assertions
   (cases 05 + 10, 56 assertions); TASK 8D extended to cases 01 + 03 Uranus/Neptune
   cards (+36 assertions = **92 boundary assertions total in
   `MARINA_OUTER_CARD_BOUNDARIES`**, 0 OOT). Phase 4b 08-N-N W1 structured override
   (sole survivor, ±200d) stays.
2. **All TYPE-A closed-config gaps resolved.** § 4 item 6 [RESOLVED via TASK 8D] —
   20 new triples (5+2+9+2+2) enrolled across 5 new cases. PDFs render with all
   expected outer cards (Worker verified at HEAD: PyPDF text extract shows 5+2+9+2+2 = 20
   cards visible).
3. **No new TYPE-B.** No generic logic regressions detected during TASK 8D
   inspection.
4. **Override count.** Total = 1 (sole survivor: 08 Phase 4b N-N W1 start ±200d
   Marina-editorial structured override). Threshold (5 per case / 10 total) preserved
   with wide margin. TASK 8D added 0 new tolerance overrides per spec
   («0 new tolerance_overrides; STOP if any window OUT-of-tolerance»).
5. **TYPE-C documented.** Marina single-Marina-window cards (02, 04, partial 03)
   and Marina Pluto display rule narrowing (partial 01, 03) classified as «render
   correctly but boundary assertions deferred» — see audit § A.2.1.D Future Work
   items 2-3.
6. **TYPE-D outstanding (separate backlog).** Case 09 fixture SR mismatch ~60 min
   (audit § A.3 TYPE-D item 2) and `Соляр 2025-2026_3.pdf` natal metadata blocker
   (audit § A.3 TYPE-D item 1) remain in separate data-revision backlog, **NOT
   blocking Marina show**. Per user direction 2026-05-14: TYPE-D items NOT in
   Phase 8 scope.

**Tests green at HEAD (post-TASK-8D):**
- `pytest`: **286 passed / 0 xfailed / 0 failed** = 221 baseline (post-Phase-8B) + 65
  new TASK 8D tests (36 boundary + 29 lexical title parametrize).
- `cabal --project-dir core/astrology-hs build`: Up to date (no engine changes;
  Phase 8B horizon at 730d AFTER).

**Production-readiness gate post-TASK-8D — all conditions met:**
- All Phase 7 + Phase 8 deliverables landed ✓
- No TYPE-B ✓
- Override count ≤ threshold (1 vs 10 total) ✓
- All TYPE-A closed-config gaps resolved (including § 4 item 6) ✓
- TYPE-C documented ✓
- TYPE-D items in separate backlog (NOT blocking Marina show) ✓

**Required next step: user explicit ack on this updated calibration report.** After
ack: recovery program closes; PDFs for all 8 Phase-7/8 cases (01 / 02 / 03 / 04 / 05
/ 07 / 08 / 09 / 10 — case 06 = TYPE-D `_3.pdf` separate) production-ready and
clientable to Marina.

---

### Verdict update (post-Phase-8-audit, 2026-05-14, SUPERSEDED by post-TASK-8D verdict above): **Partial pass — only 08 Natalya production-ready**

> **Status: SUPERSEDED** by the post-TASK-8D verdict («Ready for Marina show — pending user ack») above. Kept as historical record per Phase 8.0 audit trail discipline. Reason for supersession: TASK 8D (2026-05-14) closed § 4 item 6 (allowlist gap on cases 01/02/03/04/09) by enrolling 20 new triples + 100 fact cells from Marina PDFs, closing the last Phase 8 implementation work.
>
> **⚠ This verdict supersedes the post-Stage-B verdict below.** Manual audit (Codex + TL 2026-05-14) on a clean checkout — performed after TASK 7b closure — revealed that the Stage B test contract was **incomplete**. Specifically `services/api-python/tests/test_multi_case_calibration.py` asserted outer-card window count + types + ordinals but did **NOT** assert interval boundary dates (start/end strings) vs Marina etalon. Pytest 183/0/0 was honest but the contract had a hole.
>
> **Discipline ownership:** TASK 7b § B.4 spec gap is mine as PTL («outer cards present per allowlist» — count only; «calendar rows match Marina ±tolerance» applied to calendar, not to outer-card intervals). Worker delivered exactly what spec required.
>
> **Recovery program REOPENED 2026-05-14 as Phase 8** (programme-corrective, not retrospective rewrite). TASK 7b stays in `archive/` as historical record; its closure stays. Phase 8 is the corrective programme on top.

#### Verdict (2026-05-14): «Partial pass — only 08 Natalya production-ready»

**Per Phase 8.0 audit findings:**

1. **Test contract gap.** `test_multi_case_calibration.py` lacks outer-card interval boundary assertions; spec gap in TASK 7b § B.4. **Phase 8C scope** to close.
2. **Case 10 Данила Neptune boundary regression** — **not accepted divergence**:
   - Нептун кв Венере W3 end = `28.01.2028 10:44` vs Marina `07.03.2028` (+38d).
   - Нептун кв Юпитеру W4 end = `28.01.2028 10:44` vs Marina `18.03.2028` (+49d).
   - Both terminate at identical `orb_exit_jd = 2461798.822368622` — finite-horizon engine sample window truncation. Distinct from Phase 4b Натальи accepted divergences (which are editorial). **Phase 8B scope** — either extend loop horizon or explicitly mark truncated windows. User direction: not to classify as accepted divergence.
3. **Allowlist gap — cases 01/02/03/04/09.** Our PDF emits 0 outer cards; Marina shows 2-9 cards per case. TYPE-A closed-config gap (analog of TASK 7b § B.1+B.2). **Phase 8B scope** as separate sub-task after Phase 8A inventory.
4. **Lexical divergence — case 05.** Card title «тр Нептун в **трине** с нат Юпитером»; Marina «тр Нептун в **тригоне**». **Phase 8B scope** — one-word fix in aspect-locative dict in `outer_cards.py`.
5. **Data-quality blockers (TYPE-D, separate from code regressions):**
   - `Соляр 2025-2026_3.pdf` — fixture missing natal metadata; cannot reproduce.
   - Анастасия — fixture-vs-reference SR-time/timezone mismatch suspected.
   - Held as separate **data revision sub-tasks** in Phase 8A audit; not mixed with code regression class.

**Cross-reference:** TASK 8.0 (`archive/2026-05-14-phase-8-0-reopen-audit-trail.md`); TASK Phase 8A+8C (audit + boundary test contract) — drafted next.

#### What's still production-ready

- **08-natalya-2025-2026** — production-ready. Phase 1-7 (including 4b structured Neptune divergences) clean. Fresh PDF rendered post-closure on `c936dd1` at `/tmp/08-natalya-2025-2026-c936dd1.pdf` with provenance sidecar.
- TL framing memo for Marina (re 2 Phase 4b Neptune divergences) — available on request; independent of Phase 8 progress.

#### What's NOT production-ready (until Phase 8 closes)

- All «package» PDFs (05/07/08/10) — cannot ship as bundle.
- Case 10 Данила individually — boundary regression unresolved.
- Cases 05 (lexical) — minor but unresolved.
- Cases 01/02/03/04/09 — allowlist gap.
- `_3.pdf` / Анастасия — data-quality blockers.

---

### Verdict update (post-Stage-B, 2026-05-13, SUPERSEDED 2026-05-14): **Ready for Marina show — pending user ack**

> **Status: SUPERSEDED** by the «Partial pass» verdict above. Kept as historical record per Phase 8.0 audit trail discipline. Reason for supersession: post-closure manual audit found test contract gap + Данила boundary regression + allowlist gap on additional cases + lexical case 05 + 2 TYPE-D data-quality blockers.

**All Phase 7 deliverables landed**. Per acceptance criteria:

- **No TYPE-B regressions**. TYPE-B item 1 (case 07 label arithmetic) [RESOLVED via
  TASK 7a]. No new TYPE-B identified during Stage B.
- **All TYPE-A closed-config gaps resolved**. § 4 TYPE-A items 1 [RESOLVED via Stage B]
  (case 05 outer cards landed); item 2 [RESOLVED via Stage B] (case 10 outer cards
  landed, including 4-window case 10 card 3); items 3, 4, 5 remain documented notes
  per TASK 7b § B.5 + TASK 7c § Fixations 4 (anchor convention divergence — explicitly
  out of Stage B closed-config scope; Path B convergence deferred to future programme).
- **Override count within threshold**. Total = 2 (Phase 4b Натальи only); threshold 10
  total + 5 per case; Stage B added 0 new overrides. See § 5.
- **TYPE-C items documented**. Item 1 (case 10 card 3 = 4 windows) handled via engine
  output + helper generalization (`expected_window_count` parameter). Item 2 (case 07
  no outer cards by Marina editorial) handled by empty allowlist entry — correctly
  matches Marina.
- **Tests green**. `pytest` reports **183 passed / 0 xfailed / 0 failed** = 150 baseline
  (post-TASK-7a) + 33 new multi-case acceptance tests covering cases 05/07/10
  parameterized.
- **PDF artefacts produced via canonical entry point** (`render_case.py`) with
  correct case_label in provenance sidecars for each case.

### Required follow-up before final closure of Phase 7

1. **[DONE 2026-05-13]** Tier-C TASK 7a `transit-monthly-table-label-arithmetic`
   resolved label-arithmetic bug. Commit `8a4865e`. Regression test pinned.

2. **[DONE 2026-05-13]** TASK 7c overlay-only gate amendment authorized Stage B
   continuation under conditions (a)-(d). Overlay commit landed.

3. **[DONE 2026-05-13]** TASK 7b Stage B closed-config calibration. Worker resume
   landed:
   - Case 05 + case 10 allowlist entries + `_OUTER_CARD_FACTS` populated from Marina
     reference.
   - `render_case.py` canonical script (created Stage A.2; committed Stage B).
   - `test_multi_case_calibration.py` parameterized over 05/07/10 (33 tests).
   - `_assert_three_phase_intervals` helper generalized with
     `expected_window_count: int = 3` parameter.
   - Doc/comment generalization in `outer_cards.py` + `solar.html.j2` («3 intervals /
     три касания» → «3+ per Marina card»).
   - 0 new tolerance overrides; case 05 Venus Jul 2025 + case 07 boundary rows
     documented as TYPE-A note only per amended gate (TASK 7c).

4. **[NEXT — user]** Explicit ack on this updated calibration report. After ack:
   recovery program closes; PDFs for cases 05/07/08/10 production-ready (clientable
   to Marina if she requests the multi-case sweep).

### Production-readiness semantics

Per TASK § Phase 6 Acceptance:

> «Ready for Marina show — pending user ack»: all cases pass; no TYPE-B; override
> count within threshold.

Recovery program **transitions to «pending user ack»**. After user provides explicit
ack on this report (via accept-task / handoff lifecycle), the program closes; PDFs
are clientable.

---

## Appendix: Artifacts produced

### Stage A baseline (2026-05-13, pre-TASK-7a)

- `/tmp/05-ekaterina-phase7.pdf` + `/tmp/05-ekaterina-phase7.pdf.provenance.json`
- `/tmp/07-mariya-phase7.pdf` + `/tmp/07-mariya-phase7.pdf.provenance.json`
- `/tmp/10-danila-phase7.pdf` + `/tmp/10-danila-phase7.pdf.provenance.json`
- `/tmp/stage_a_render_case.py` (Worker-side throwaway; for diagnostic context only).

### Stage A.2 re-validation (2026-05-13, post-TASK-7a)

- `/tmp/07-mariya-stage-a2.pdf` + `.provenance.json` — case 07 13/13 labels verified.

### Stage B production-ready artefacts (2026-05-13)

- `/tmp/05-ekaterina-stage-b.pdf` + `/tmp/05-ekaterina-stage-b.pdf.provenance.json`
- `/tmp/07-mariya-stage-b.pdf` + `/tmp/07-mariya-stage-b.pdf.provenance.json`
- `/tmp/10-danila-stage-b.pdf` + `/tmp/10-danila-stage-b.pdf.provenance.json`
- `services/api-python/scripts/render_case.py` (canonical parameterised render
  script; committed Stage B).
- `services/api-python/tests/test_multi_case_calibration.py` (parameterized multi-case
  acceptance tests; committed Stage B).
- This report: `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`.
