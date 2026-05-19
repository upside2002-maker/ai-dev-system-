# Phase 9.3A — Outer Card Horizon / Window Selection Validation (Stage 0 gate)

Дата: 2026-05-19
Tier: C (analytical / empirical validation memo only — no product code, no tests, no engine recomputation).
Source TASK: `project-overlays/astro/TASKS/2026-05-19-phase-9-3-a-outer-card-horizon-window-validation.md`.
Baseline: product main @ `7751d46` (Phase 9.2B angle-filter landed); overlay master @ `486f359` (TASK Ready: yes commit). Pytest baseline `382 passed + 2 skipped + 0 failed` (preserved — no test files written). Cabal: clean.

Cross-references:
- Phase 9.0 memo § 5.3 (target sub-problem C verdict): `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Phase 9.2A validation memo (parallel pattern + Olga § 1.3 inventory): `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md`.
- `MARINA_OUTER_CARD_BOUNDARIES` data source (read-only): `services/api-python/tests/test_multi_case_calibration.py:870-967`.
- `generic_outer_cards()` (read-only reference): `services/api-python/app/pdf/outer_cards.py:1671-1769`.
- `aggregate_display_windows()` / `_collect_raw_hits()` (read-only): `services/api-python/app/pdf/outer_cards.py:363-422`, `:445-475`.
- Olga DB consultations: `data/astro.db` row id=10 (narrow horizon, 6 cards) + id=11 (wide horizon, 11 cards = 6 + 5 over-include).
- Marina-Olga reference PDF (strict-scope window extraction): `/Users/ilya/Downloads/Соляр 2026-2027.pdf` pp. 28-32.

---

## § 0. Validation framing

### § 0.1 Question (per user direction 2026-05-19 + Phase 9.0 § 5.3 hybrid verdict)

Phase 9.0 § 5.3 verdict for sub-problem C («touch intervals»):

> «**Verdict: `hybrid (strong editorial residual)`**. Default «show all» is deterministic match for ~60-70% of cards; editorial single-window choice не reverse-engineerable from current 10-case data.»

User manual verification 2026-05-19 surfaced two phenomena outside Phase 9.2B scope (which closed only the angle-target filter):

1. **Planet-target over-include** (5 для Olga cons11): Уран секст Меркурий, Уран кв Луна, Нептун кв Марс, Нептун кв Нептун, Плутон секст Юпитер. All have first-touch outside solar-year window.

2. **Wide intervals within Marina-selected cards**: Marina shows 1 window where engine emits 3 (Уран кв Венера, Уран опп Юпитер, Нептун триг Юпитер); Marina shows 4 windows where engine emits 4 with much narrower orb tightness (Плутон секст Уран).

Stage 0 question: is there a deterministic **horizon / window-selection rule** that produces Marina's selection from engine emit across 4 calibrated cases + 6 Olga Marina-selected cards?

### § 0.2 Methodology (per TASK Stage 2 + 6 Ready clarifications)

- **Engine output sources (read-only):**
  - Calibrated 4 cases — `packages/test-fixtures/golden-cases/{01-kseniya-2024-2025,03-artem-2025-2026,05-ekaterina-2025-2026,10-danila-2025-2026}.expected.json` `annual_transit_table` → `_collect_raw_hits` → `aggregate_display_windows`. Allowlist branch bypasses `generic_outer_cards` для calibrated, но raw hits identical (allowlist is a curation of triples, не engine modification).
  - Olga 11 — `data/astro.db` consultation id=11 `facts_json.annual_transit_table` → `generic_outer_cards(facts, tz_id='Europe/Moscow')` → `.intervals` per emitted card.
  - Olga 10 — `data/astro.db` consultation id=10 (narrow horizon, sample buffer ~`[SR, SR+365]` only) — informational diagnostic для § 4 (NOT в Stage 2 hypothesis scoring per user clarification 3).

- **Marina reference sources:**
  - Calibrated 4 — `MARINA_OUTER_CARD_BOUNDARIES` (read-only).
  - Olga 11 — `/Users/ilya/Downloads/Соляр 2026-2027.pdf` strict-scope extract (window boundary dates only for 6 Marina-selected cards per user clarification 1; NO secondary inference).

- **Match metric** (TASK § 2.1):
  - **STRICT view** (TASK literal `±2d boundary tolerance`): a hypothesis output window matches Marina iff `|enter − marina_enter| ≤ 2d ∧ |exit − marina_exit| ≤ 2d`. This is consistent with `_OUTER_CARD_BOUNDARY_TOLERANCE_DAYS` Phase 8 convention.
  - **OVERLAP view** (additional, selection-focused): a hypothesis output window matches Marina iff non-empty date-interval overlap exists. Decouples «which windows Marina shows» (selection) from «how tight Marina's window boundaries are» (Phase 8 territory).

  Both views computed; § 2 reports both. Stage 2.3 verdict uses STRICT per TASK literal.

- **Card-FN counting** (per TASK § 2.3): `card-FN` per hypothesis = count of cards where ≥1 Marina window is unmatched by hypothesis output. PASS = 0 card-FN ∧ ≥90% window coverage.

### § 0.3 Hypothesis enumeration (per user clarification 2 — starter + composite expansion)

Base hypotheses H1-H6 per TASK Stage 1 starter:

- **H1** — window overlaps `[SR, SR + 365]` (operational reading of TASK formulation, with the broad `window.end ≥ SR-N` literally tested as **H1_broad** below using `N = 365`).
- **H2** — window intersects `[SR − 30, SR + 365]`.
- **H3** — window intersects `[SR − 90, SR + 365]`.
- **H4** — window center lies inside `[SR, SR + 365]`.
- **H5** — «last pre-SR touch + intra-SR cluster» (list-level rule).
- **H6** — planet-conditional cap on top of intersect-solar-year base (`Uranus ≤ 3`, `Neptune ≤ 4`, `Pluto ≤ 2`).

Worker-added composites (per clarification 2 — base score first, then composite delta + overfit-risk test):

- **H7** — alias for H1 (operational identity).
- **H8** — «first 3 windows emitted by engine (cap 3, no horizon)».
- **H9** — «intra-SR cluster + first post-solar-year window».
- **H10** — «intersect `[SR, SR+365]` OR center in `[SR-30, SR+730]`».
- **H11** — «drop windows whose END date is strictly before SR» (= «keep windows with end ≥ SR»). **Discovered post-hoc from Olga cons11 analysis** (see § 2.4 below).
- **H12** — H11 soft variant: «keep windows with end ≥ SR − 30 days».
- **H13** — H11 with far-future cap: «end ≥ SR AND start ≤ SR + 1095 days».

H7-H13 explicit «discovered post-hoc» tagging per clarification 2. Overfit-risk evaluation: each H7-H13 trained-on-fit observation flagged; Olga held-out check applied to H11 (the only post-hoc rule that perfectly fits Olga's narrowed-card pattern).

### § 0.4 Olga PDF strict-scope window inventory (per clarification 1 + user verbatim cross-check)

Worker extracted window boundary dates from Marina-Olga reference PDF, scope strictly limited to 6 Marina-selected cards. Output dictionary (parallel `MARINA_OUTER_CARD_BOUNDARIES` shape):

```python
MARINA_OLGA = {
    ("Uranus", "Square", "Venus"): [
        (date(2026, 12, 2), date(2027, 4, 15)),  # одно касание
    ],
    ("Uranus", "Opposition", "Uranus"): [
        (date(2026, 7, 18), date(2026, 11, 6)),   # первое касание
        (date(2027, 5, 5),  date(2027, 6, 8)),    # второе касание
        (date(2028, 1, 8),  date(2028, 3, 19)),   # третье касание
    ],
    ("Uranus", "Opposition", "Jupiter"): [
        (date(2026, 12, 28), date(2027, 3, 22)),  # одно касание
    ],
    ("Neptune", "Trine", "Jupiter"): [
        (date(2026, 10, 18), date(2027, 2, 5)),   # одно касание
    ],
    ("Neptune", "Trine", "Uranus"): [
        (date(2027, 4, 4),   date(2027, 6, 13)),  # первое касание
        (date(2027, 8, 6),   date(2027, 10, 27)), # второе касание
        (date(2028, 1, 31),  date(2028, 3, 30)),  # третье касание
        (date(2028, 11, 10), date(2029, 1, 22)),  # четвертое касание
    ],
    ("Pluto", "Sextile", "Uranus"): [
        (date(2026, 7, 1),   date(2026, 7, 19)),  # первое касание
        (date(2027, 1, 5),   date(2027, 3, 13)),  # второе касание
        (date(2027, 7, 7),   date(2028, 1, 17)),  # третье касание
        (date(2028, 10, 3),  date(2028, 11, 4)),  # четвертое касание
    ],
}
```

**Confirmation against user verbatim formulation (clarification 1):**

| Card | User verbatim | PDF extract | Match? |
|---|---|---|---|
| Уран кв Венера | `02.12.2026–15.04.2027` | `2026-12-02 → 2027-04-15` | ✓ exact |
| Уран опп Юпитер | `28.12.2026–22.03.2027` | `2026-12-28 → 2027-03-22` | ✓ exact |
| Нептун трин Юпитер | `18.10.2026–05.02.2027` | `2026-10-18 → 2027-02-05` | ✓ exact |
| Плутон секст Уран | «windows смещены» (no dates) | 4 windows extracted (see above) | ✓ no contradiction |
| Уран опп Уран | not given verbatim | 3 windows extracted | n/a |
| Нептун трин Уран | not given verbatim | 4 windows extracted | n/a |

All 4 user-verbatim dates match PDF extract exactly (±0d). No secondary re-interpretation needed. Stage 0.3 strict-scope discipline preserved.

### § 0.5 Olga sample-horizon root cause (cons10 vs cons11, per user direction)

`consultation 10` (id=10) и `consultation 11` (id=11) share the same `solar_chart.return_jd = 2461234.877` (UTC `2026-07-13T09:02:16`) and same natal data. They differ only in **`annual_transit_table` sample horizon**:

| Consultation | Sample horizon (engine `annual_transit_table`) |
|---|---|
| cons10 | `[SR, SR + 365d]` (narrow: 2026-07-13 → 2027-07-13) |
| cons11 | `[SR − 730d, SR + 1095d]` (wide: 2024-07-13 → 2029-07-12) |

Engine `_TRANSIT_SAMPLE_BUFFER_DAYS_{BEFORE,AFTER}` (Phase 8B settings 730/730 → updated to 730/730 + 0 post-buffer adjustments) controls this; cons10 was produced by an earlier configuration. **Marina selection inventory is identical between consultations** (the same 6 Olga cards) — the diff is **only in window count per card** for cards whose engine emit extends pre-SR:

| Olga card | cons10 windows | cons11 windows | Marina windows |
|---|---|---|---|
| Uranus Square Venus | 1 (engine W3 only) | 3 (engine W1+W2+W3) | 1 |
| Uranus Opposition Uranus | 2 (engine W1+W2) | 3 (engine W1+W2+W3) | 3 |
| Uranus Opposition Jupiter | 1 (engine W3 only) | 3 (engine W1+W2+W3) | 1 |
| Neptune Trine Jupiter | 1 (engine W3 only) | 3 (engine W1+W2+W3) | 1 |
| Neptune Trine Uranus | 1 (engine W1 only) | 4 (engine W1+W2+W3+W4) | 4 |
| Pluto Sextile Uranus | 3 (engine W1+W2+W3) | 4 (engine W1+W2+W3+W4) | 4 |

cons10 narrow horizon **accidentally produces Marina-matching window count for 3 of 6 cards** (the URV / UOJ / NTJ singletons) because it truncates pre-SR windows that Marina also drops. But cons10 also **under-emits** Uranus Opposition Uranus, Neptune Trine Uranus, Pluto Sextile Uranus — Marina shows 3-4 windows; cons10 shows 1-3. **cons10 horizon is not the correct selection rule** because its post-SR cutoff at `SR+365` excludes Marina-shown post-solar-year windows.

cons11 wide horizon **matches Marina's complete window inventory positionally** (all 6 cards: count matches Marina for UOU/NTU/PSU; over-emits W1+W2 for URV/UOJ/NTJ — these are the «narrowed» cards). Hence Stage 2 hypothesis testing uses cons11 as authoritative engine emit (per TASK § 0.2 «use existing facts»).

---

## § 1. Per-case empirical window inventory

### § 1.1 Calibrated 4 cases (Stage 2.1 / 2.3 main scoring set)

Engine emit windows ≡ Marina windows (1:1 ordinal + boundary alignment ±2d per Phase 8 audit). All Marina windows have non-empty overlap with the corresponding engine window. Full count alignment (calibrated cases match by construction — Phase 7b/8D allowlist + Phase 8B/8E boundary calibration).

#### 01-kseniya-2024-2025 (SR = 2024-11-19)

| Card | Marina windows (count = 3) | Engine windows (count = 3) | ±2d match |
|---|---|---|---|
| Uranus Opposition Sun | `(2024-07-14, 2024-10-22)`, `(2025-04-30, 2025-06-04)`, `(2025-12-21, 2026-03-20)` | `(2024-07-14, 2024-10-21)`, `(2025-04-30, 2025-06-03)`, `(2025-12-21, 2026-03-19)` | ✓ |
| Uranus Opposition Uranus | `(2024-06-15, 2024-08-05)`, `(2024-09-29, 2024-11-24)`, `(2025-04-05, 2025-05-12)` | `(2024-06-15, 2024-08-05)`, `(2024-09-29, 2024-11-24)`, `(2025-04-05, 2025-05-11)` | ✓ |
| Neptune Trine Sun | `(2023-04-17, 2023-09-19)`, `(2024-02-17, 2024-04-11)`, `(2024-09-30, 2025-02-11)` | `(2023-04-16, 2023-09-19)`, `(2024-02-17, 2024-04-11)`, `(2024-09-29, 2025-02-11)` | ✓ |
| Neptune Square Mars | `(2023-05-12, 2023-08-21)`, `(2024-03-09, 2024-05-04)`, `(2024-09-02, 2025-03-04)` | `(2023-05-11, 2023-08-21)`, `(2024-03-08, 2024-05-04)`, `(2024-09-02, 2025-03-04)` | ✓ |

Marina-windows SR-classification (relative to SR=2024-11-19):
- Uranus Opposition Sun: pre-SR-entirely (W1) + intra-SR (W2) + post-solar-year-entirely (W3) — **mixed pre+intra+post**.
- Uranus Opposition Uranus: pre-SR-entirely (W1) + pre-SR-straddling-SR (W2) + intra-SR (W3) — **mixed pre+intra**.
- Neptune Trine Sun: pre-SR-entirely (W1) + pre-SR-entirely (W2) + pre-SR-straddling-SR (W3) — **all pre-SR** (none entirely intra-solar-year).
- Neptune Square Mars: same shape as Neptune Trine Sun — **all pre-SR**.

#### 03-artem-2025-2026 (SR = 2025-09-27)

| Card | Marina windows (count = 3) | Engine windows (count = 3) | ±2d match |
|---|---|---|---|
| Uranus Trine Sun | `(2026-06-29, 2026-08-27)`, `(2026-09-25, 2026-11-27)`, `(2027-04-19, 2027-05-24)` | `(2026-06-29, 2026-08-27)`, `(2026-09-24, 2026-11-27)`, `(2027-04-18, 2027-05-24)` | ✓ |
| Uranus Trine Mars | `(2026-07-13, 2026-11-11)`, `(2027-05-02, 2027-06-05)`, `(2028-01-15, 2028-03-12)` | `(2026-07-13, 2026-11-11)`, `(2027-05-01, 2027-06-05)`, `(2028-01-15, 2028-03-12)` | ✓ |
| Neptune Opposition Sun | `(2026-05-13, 2026-09-03)`, `(2027-03-13, 2027-05-07)`, `(2027-09-15, 2028-03-07)` | `(2026-05-12, 2026-09-03)`, `(2027-03-12, 2027-05-07)`, `(2027-09-14, 2028-03-07)` | ✓ |
| Neptune Square Uranus | `(2025-04-12, 2025-10-04)`, `(2026-02-12, 2026-04-08)`, `(2026-10-16, 2027-02-06)` | `(2025-04-12, 2025-10-03)`, `(2026-02-12, 2026-04-08)`, `(2026-10-15, 2027-02-06)` | ✓ |

SR-classification (SR=2025-09-27):
- Uranus Trine Sun: intra-SR + post-solar-year-straddling + post-solar-year-entirely — **mixed intra+post**.
- Uranus Trine Mars: post-solar-year-straddling + post-solar-year-entirely × 2 — **all post-solar-year** (none entirely intra-SR).
- Neptune Opposition Sun: intra-SR + post-solar-year-entirely × 2 — **mixed intra+post**.
- Neptune Square Uranus: pre-SR-straddling + intra-SR + post-solar-year-entirely — **mixed pre+intra+post**.

#### 05-ekaterina-2025-2026 (SR = 2025-03-11)

| Card | Marina windows (count = 3) | Engine windows (count = 3) | ±2d match |
|---|---|---|---|
| Uranus Square Moon | `(2025-07-21, 2025-10-24)`, `(2026-05-06, 2026-06-09)`, `(2026-12-25, 2027-03-25)` | `(2025-07-20, 2025-10-24)`, `(2026-05-05, 2026-06-09)`, `(2026-12-24, 2027-03-25)` | ✓ |
| Uranus Sextile Jupiter | `(2025-06-05, 2025-07-14)`, `(2025-10-31, 2025-12-20)`, `(2026-03-21, 2026-05-01)` | `(2025-06-04, 2025-07-14)`, `(2025-10-30, 2025-12-20)`, `(2026-03-20, 2026-05-01)` | ✓ |
| Neptune Trine Jupiter | `(2024-04-12, 2024-09-28)`, `(2025-02-12, 2025-04-08)`, `(2025-10-10, 2026-02-07)` | `(2024-04-12, 2024-09-28)`, `(2025-02-12, 2025-04-08)`, `(2025-10-09, 2026-02-07)` | ✓ |

SR-classification (SR=2025-03-11):
- Uranus Square Moon: intra-SR + post-solar-year-entirely × 2 — **mixed intra+post**.
- Uranus Sextile Jupiter: intra-SR × 2 + post-solar-year-entirely — **mixed intra+post**.
- Neptune Trine Jupiter: pre-SR-entirely + pre-SR-straddling + intra-SR — **mixed pre+intra**.

#### 10-danila-2025-2026 (SR = 2025-08-05)

| Card | Marina windows (count = 3 / 3 / 4) | Engine windows (count = 3 / 3 / 4) | ±2d match |
|---|---|---|---|
| Uranus Square Moon | `(2024-07-11, 2024-10-25)`, `(2025-04-28, 2025-06-02)`, `(2025-12-25, 2026-03-16)` | `(2024-07-11, 2024-10-25)`, `(2025-04-28, 2025-06-01)`, `(2025-12-24, 2026-03-16)` | ✓ |
| Neptune Square Venus | `(2026-05-14, 2026-09-02)`, `(2027-03-13, 2027-05-07)`, `(2027-09-15, 2028-03-07)` | `(2026-05-13, 2026-09-02)`, `(2027-03-12, 2027-05-07)`, `(2027-09-14, 2028-03-07)` | ✓ |
| Neptune Square Jupiter | `(2026-05-30, 2026-08-15)`, `(2027-03-24, 2027-05-22)`, `(2027-08-30, 2027-11-20)`, `(2028-01-09, 2028-03-18)` | `(2026-05-30, 2026-08-15)`, `(2027-03-23, 2027-05-22)`, `(2027-08-29, 2027-11-20)`, `(2028-01-08, 2028-03-18)` | ✓ |

SR-classification (SR=2025-08-05):
- Uranus Square Moon: pre-SR-entirely × 2 + intra-SR — **mixed pre+intra**.
- Neptune Square Venus: post-solar-year-straddling + post-solar-year-entirely × 2 — **all post-solar-year**.
- Neptune Square Jupiter: post-solar-year-straddling + post-solar-year-entirely × 3 — **all post-solar-year**.

### § 1.2 Olga consultation 11 (wide horizon, authoritative engine emit)

Engine emit set per `generic_outer_cards(facts_cons11, tz_id='Europe/Moscow')`: 11 cards total (6 Marina-selected + 5 Marina-rejected per Phase 9.2A § 1.2 + Phase 9.2B closure). Worker scores only the 6 Marina-selected cards (per TASK § Stage 2.2 «Cards Marina-selected (6) → check if hypothesis preserves all 6»).

| Card | Marina windows | Engine windows | Marina ⊆ Engine positional? |
|---|---|---|---|
| Uranus Square Venus | 1: `(2026-12-02, 2027-04-15)` | 3: `(2025-08-29, 2025-09-13)`, `(2026-05-21, 2026-06-25)`, `(2026-12-01, 2027-04-15)` | ✓ (Marina W1 ⊆ Engine W3) |
| Uranus Opposition Uranus | 3: `(2026-07-18, 2026-11-06)`, `(2027-05-05, 2027-06-08)`, `(2028-01-08, 2028-03-19)` | 3: `(2026-07-17, 2026-11-06)`, `(2027-05-04, 2027-06-08)`, `(2028-01-08, 2028-03-19)` | ✓ all positions ±2d match |
| Uranus Opposition Jupiter | 1: `(2026-12-28, 2027-03-22)` | 3: `(2025-07-17, 2025-10-28)`, `(2026-05-03, 2026-06-07)`, `(2026-12-28, 2027-03-22)` | ✓ (Marina W1 ⊆ Engine W3) |
| Neptune Trine Jupiter | 1: `(2026-10-18, 2027-02-05)` | 3: `(2025-04-11, 2025-10-05)`, `(2026-02-10, 2026-04-06)`, `(2026-10-17, 2027-02-05)` | ✓ (Marina W1 ⊆ Engine W3) |
| Neptune Trine Uranus | 4: `(2027-04-04, 2027-06-13)`, `(2027-08-06, 2027-10-27)`, `(2028-01-31, 2028-03-30)`, `(2028-11-10, 2029-01-22)` | 4: `(2027-04-04, 2027-06-13)`, `(2027-08-05, 2027-10-27)`, `(2028-01-31, 2028-03-30)`, `(2028-11-09, 2029-01-22)` | ✓ all positions ±2d match |
| Pluto Sextile Uranus | 4: `(2026-07-01, 2026-07-19)`, `(2027-01-05, 2027-03-13)`, `(2027-07-07, 2028-01-17)`, `(2028-10-03, 2028-11-04)` | 4: `(2026-02-17, 2026-07-30)`, `(2026-12-27, 2027-03-24)`, `(2027-06-23, 2028-01-25)`, `(2028-09-11, 2028-11-24)` | ✓ (positional contained but boundary loose) |

**Critical finding: Olga's narrowing pattern.** Marina shows **1 window** (Marina_W1) for Uranus Square Venus / Uranus Opposition Jupiter / Neptune Trine Jupiter. In all three cases, Marina_W1 is **positionally Engine_W3** (the post-SR window, the third in engine's ordinal sequence). Engine_W1 and Engine_W2 (which precede SR or are entirely pre-SR) are dropped by Marina but emitted by engine.

For Uranus Opposition Uranus, Neptune Trine Uranus, Pluto Sextile Uranus — Marina shows **all engine windows** (3 / 4 / 4 respectively). For Pluto Sextile Uranus the four Marina windows are positionally contained within the four engine windows (Marina_W_i ⊆ Engine_W_i, ∀ i ∈ {1..4}), but boundary tightness differs significantly (e.g. Engine_W1 = `2026-02-17 → 2026-07-30` is 164 days wide, Marina_W1 = `2026-07-01 → 2026-07-19` is 18 days wide — both contain the same Direct exact `2026-04-23` + Retrograde exact `2026-05-19`).

**Pluto Sextile Uranus boundary tightness diagnostic** (per § 0.2 STRICT vs OVERLAP rationale): Marina W_i = strict-orb interval (typical orb ≤ 1°); Engine W_i = aggregate orb-enter / orb-exit per `aggregate_display_windows` (Phase 4a contract semantics — covers loose orb). Engine emits Pluto loops with **two exact moments inside a single orb-window** (W1 contains Direct + Retrograde exacts); aggregate logic merges them into one window with wide outer boundary. Marina narrows to the inner exact-cluster orb. **This boundary divergence is a Phase 4a / Phase 8 «interval semantics» problem, NOT a Phase 9.3A window-selection problem.** Worker explicitly separates these two phenomena in metrics (§ 2 STRICT vs OVERLAP).

### § 1.3 Olga consultation 10 (narrow horizon, informational diagnostic — § 4)

cons10 emits exactly 6 cards (no over-include) because narrow `[SR, SR+365]` sample buffer truncates pre-SR Uranus/Neptune/Pluto loops. cons10 window counts (URV=1, UOU=2, UOJ=1, NTJ=1, NTU=1, PSU=3) reflect **sample-horizon truncation, not Marina selection rule**:

- cons10 «narrow horizon W1+W2+W3 → keep W3» for URV/UOJ/NTJ — accidentally matches Marina's 3 narrowed cards.
- cons10 «truncates engine W2/W3/W4» for UOU/NTU/PSU — **does NOT match Marina** (Marina shows 3/4/4 windows; cons10 shows 2/1/3). Specifically:
  - UOU cons10 = 2 windows (W1+W2 intra-SR); Marina = 3 (adds 2028-01-08 → 2028-03-19 post-SR-year window).
  - NTU cons10 = 1 window (only W1 = 2027-04-04 → 2027-06-13); Marina = 4 (adds 3 post-SR-year windows).
  - PSU cons10 = 3 windows (W1+W2+W3 intra+near-SR-year); Marina = 4 (adds 2028-10-03 → 2028-11-04 post-SR-year window).

cons10 narrow horizon **is not the rule** because it fails on UOU/NTU/PSU. It accidentally matches on 3 of 6 because Marina's narrowing for those happens to coincide with cons10 buffer truncation. cons11 wide horizon is the authoritative engine emit — Marina drops W1+W2 for URV/UOJ/NTJ as an **editorial choice**, not as a buffer-controlled filter.

### § 1.4 Aggregate Olga inventory (per Marina-selected card)

| Card | Marina #W | Engine cons11 #W | Marina narrowed? | Target class | Engine ordinal that Marina shows |
|---|---|---|---|---|---|
| Uranus Square Venus | 1 | 3 | YES (drops W1+W2, keeps W3) | personal (Venus) | W3 |
| Uranus Opposition Uranus | 3 | 3 | NO (full alignment) | outer (Uranus) | W1+W2+W3 |
| Uranus Opposition Jupiter | 1 | 3 | YES (drops W1+W2, keeps W3) | social (Jupiter) | W3 |
| Neptune Trine Jupiter | 1 | 3 | YES (drops W1+W2, keeps W3) | social (Jupiter) | W3 |
| Neptune Trine Uranus | 4 | 4 | NO (full alignment) | outer (Uranus) | W1+W2+W3+W4 |
| Pluto Sextile Uranus | 4 | 4 | NO (full alignment) | outer (Uranus) | W1+W2+W3+W4 |

Olga-specific observation: Marina narrows precisely on cards with **non-outer target** (Venus / Jupiter / Jupiter — personal + social) and shows **all engine windows** for cards with outer target (Uranus). This matches Phase 9.0 § 5.3 prediction («For outer-personal/outer-social cards: sometimes narrows to single «main touch». For outer-outer cards: always show all (3-4 windows)»).

§ 2 tests whether this rule generalises beyond Olga.

---

## § 2. Per-hypothesis evaluation (Stage 2)

### § 2.1 Aggregate scoreboard

Total Marina windows in scoring set (4 calibrated + 6 Olga Marina-selected):
- Calibrated 01: 12 windows (4 cards × 3).
- Calibrated 03: 12 windows (4 cards × 3).
- Calibrated 05: 9 windows (3 cards × 3).
- Calibrated 10: 10 windows (3 cards: 3+3+4).
- Olga 11: 14 windows (1+3+1+1+4+4).
- **Total: 57 Marina windows across 20 cards.**

#### STRICT view (TASK § 2.1 ±2d boundary match)

| Hypothesis | card-FN | card-drop | Total FN | Total FP | Window cov-% | Verdict |
|---|---|---|---|---|---|---|
| `engine` (no filter) | 1/20 | 0/20 | 4 | 10 | 93.0 | **FAIL** |
| H1 (overlap `[SR, SR+365]`) | 17/20 | 0/20 | 32 | 3 | 43.9 | FAIL |
| H1_broad (`[SR-365, SR+365]`) | 14/20 | 0/20 | 25 | 9 | 56.1 | FAIL |
| H2 (`[SR-30, SR+365]`) | 17/20 | 0/20 | 31 | 4 | 45.6 | FAIL |
| H3 (`[SR-90, SR+365]`) | 17/20 | 0/20 | 30 | 5 | 47.4 | FAIL |
| H4 (center `∈ [SR, SR+365]`) | 17/20 | 0/20 | 35 | 1 | 38.6 | FAIL |
| H5 (last pre-SR + intra-SR) | 15/20 | 0/20 | 26 | 6 | 54.4 | FAIL |
| H6 (planet-conditional cap) | 17/20 | 0/20 | 32 | 2 | 43.9 | FAIL |
| H7 (alias H1) | 17/20 | 0/20 | 32 | 3 | 43.9 | FAIL |
| H8 (first-3 windows) | 3/20 | 0/20 | 6 | 9 | 89.5 | FAIL |
| H9 (intra-SR + first post-year) | 13/20 | 0/20 | 21 | 4 | 63.2 | FAIL |
| H10 (intersect-SY OR center `∈ [SR-30, SR+730]`) | 12/20 | 0/20 | 19 | 3 | 66.7 | FAIL |
| H11 (drop end < SR) | 7/20 | 0/20 | 13 | 4 | 77.2 | FAIL |
| H12 (drop end < SR − 30) | 6/20 | 0/20 | 12 | 5 | 78.9 | FAIL |
| H13 (H11 + start ≤ SR+1095) | 7/20 | 0/20 | 13 | 4 | 77.2 | FAIL |

Notable: under STRICT view, **even the engine baseline FAILs** (1 card-FN, 4 total FN, 93% coverage). The 4 FN are all from Pluto Sextile Uranus boundary tightness — engine W_i loose-orb boundaries fail ±2d match against Marina W_i tight-orb boundaries, even though positional ordinality is preserved (Marina_W_i ⊆ Engine_W_i for all 4 i). 0 hypotheses PASS / PARTIAL in STRICT view.

#### OVERLAP view (selection-focused, decoupled from boundary tightness)

| Hypothesis | card-drop (all FN) | Total FN | Total FP | Window cov-% | Verdict |
|---|---|---|---|---|---|
| `engine` (no filter) | 0/20 | 0 | 6 | 100.0 | **PASS** |
| H1 | 0/20 | 29 | 0 | 49.1 | FAIL |
| H1_broad | 0/20 | 22 | 6 | 61.4 | PARTIAL |
| H2 | 0/20 | 28 | 1 | 50.9 | FAIL |
| H3 | 0/20 | 27 | 2 | 52.6 | FAIL |
| H4 | 0/20 | 34 | 0 | 40.4 | FAIL |
| H5 | 0/20 | 23 | 3 | 59.6 | FAIL |
| H6 | 0/20 | 30 | 0 | 47.4 | FAIL |
| H7 | 0/20 | 29 | 0 | 49.1 | FAIL |
| H8 | 0/20 | 3 | 6 | 94.7 | **PASS** |
| H9 | 0/20 | 17 | 0 | 70.2 | PARTIAL |
| H10 | 0/20 | 16 | 0 | 71.9 | PARTIAL |
| H11 | 0/20 | 9 | 0 | 84.2 | PARTIAL |
| H12 | 0/20 | 8 | 1 | 86.0 | PARTIAL |
| H13 | 0/20 | 9 | 0 | 84.2 | PARTIAL |

Under OVERLAP view: `engine` baseline **PASSes** (100% coverage, 0 card-drop, 6 FP from Olga's 3 narrowed cards). H8 (first-3 cap) **PASSes** at 94.7% coverage (3 FN from cards with Marina #W = 4 — danila Neptune Square Jupiter; Olga Neptune Trine Uranus; Olga Pluto Sextile Uranus). H11 / H12 / H13 land PARTIAL (76–86% coverage).

### § 2.2 Per-card detail — base hypotheses H1-H6 (calibrated cases)

Worker shows H1 detail (others follow similar pattern — see § 2.1 aggregate). H1 = «overlap `[SR, SR+365]`».

**01-kseniya-2024-2025** (SR=2024-11-19):
- Uranus Opposition Sun: Marina 3 / H1 out 1 (only W2). FN = 2 (W1 pre-SR-entirely + W3 post-SR-year-entirely).
- Uranus Opposition Uranus: Marina 3 / H1 out 2 (W2 + W3). FN = 1 (W1 pre-SR-entirely).
- Neptune Trine Sun: Marina 3 / H1 out 1 (only W3 pre-SR-straddling). FN = 2 (W1 + W2 entirely pre-SR).
- Neptune Square Mars: Marina 3 / H1 out 1 (W3 only). FN = 2.

**03-artem-2025-2026** (SR=2025-09-27):
- Uranus Trine Sun: M=3 / H1=2 (W1+W2). FN = 1 (W3 post-SR-year-entirely).
- Uranus Trine Mars: M=3 / H1=1 (W1 only). FN = 2 (W2+W3 post-SR-year).
- Neptune Opposition Sun: M=3 / H1=1 (W1). FN = 2.
- Neptune Square Uranus: M=3 / H1=2 (W1+W2). FN = 1.

**05-ekaterina-2025-2026** (SR=2025-03-11):
- Uranus Square Moon: M=3 / H1=1 (W1). FN = 2.
- Uranus Sextile Jupiter: M=3 / H1=2 (W1+W2). FN = 1.
- Neptune Trine Jupiter: M=3 / H1=2 (W2+W3). FN = 1 (W1 pre-SR-entirely).

**10-danila-2025-2026** (SR=2025-08-05):
- Uranus Square Moon: M=3 / H1=1 (W3). FN = 2 (W1+W2 pre-SR-entirely).
- Neptune Square Venus: M=3 / H1=1 (W1). FN = 2 (W2+W3 post-SR-year-entirely).
- Neptune Square Jupiter: M=4 / H1=1 (W1). FN = 3 (W2/W3/W4 post-SR-year).

**11-olga-cons11** (SR=2026-07-13):
- Uranus Square Venus: M=1 / H1=1 (engine W3 matches Marina W1). ✓ FN=0 FP=0.
- Uranus Opposition Uranus: M=3 / H1=2 (W1+W2). FN = 1 (W3 post-SR-year-entirely).
- Uranus Opposition Jupiter: M=1 / H1=1 (engine W3). ✓ FN=0 FP=0.
- Neptune Trine Jupiter: M=1 / H1=1 (engine W3). ✓ FN=0 FP=0.
- Neptune Trine Uranus: M=4 / H1=1 (only W1 intersects SR-year). FN = 3 (W2/W3/W4 post-year).
- Pluto Sextile Uranus: M=4 / H1=3 (W1+W2+W3). FN = 1 (W4 post-year).

H1 succeeds **only** on Olga's 3 narrowed cards (URV / UOJ / NTJ) — because engine W3 happens to be the intra-SR window AND Marina also chose just W3. **For all other cards H1 under-emits**, missing 29 Marina windows total.

The same shape holds for H2 / H3 / H4 / H6 / H7 (all are «intersect solar year» variations). H5 («last pre-SR + intra-SR») slightly improves by retaining one pre-SR window (cov-% 59.6 vs H1 49.1), still FAIL.

### § 2.3 H8 detail — «first 3 windows of engine emit»

H8 = «take first 3 windows of engine emit, no horizon test». Window coverage 94.7% in OVERLAP view, 3 FN total.

- Danila Neptune Square Jupiter: Marina M=4, engine 4, H8 out 3 (drops W4). FN_marina = `(2028-01-09, 2028-03-18)`.
- Olga Neptune Trine Uranus: M=4, engine 4, H8 out 3 (drops W4). FN_marina = `(2028-11-10, 2029-01-22)`.
- Olga Pluto Sextile Uranus: M=4, engine 4, H8 out 3 (drops W4). FN_marina = `(2028-10-03, 2028-11-04)`.

H8 succeeds at 94.7% **only** because Marina's typical window count is 3, and engine emits cards in a stable ordinal sequence aligned with Marina. The 3 FN come from rare Marina-W=4 cases.

H8 **breaks Olga's 3 narrowed cards** (URV / UOJ / NTJ): H8 emits engine W1+W2+W3 = 3 windows, but Marina shows only W3. 6 FP, no card-drop, but selection-noise.

H8 is **not a rule for window selection**; it's a near-stable cap that approximates Marina's typical pattern. It doesn't capture Marina's narrowing decision for Olga.

### § 2.4 H11 detail (post-hoc discovered — overfit-risk evaluation)

H11 = «drop windows whose end_date is strictly before SR».

**Olga held-out check (per clarification 2 — Olga as held-out, calibrated as training):**

If Worker trained H11 on the Olga 6 cards as «what rule reproduces Marina's narrowing for URV / UOJ / NTJ?»:
- Olga URV: engine W1 ends 2025-09-13 (pre-SR-end), W2 ends 2026-06-25 (pre-SR-end), W3 ends 2027-04-15 (post-SR). H11 keeps only W3. ✓ matches Marina.
- Olga UOJ: engine W1 ends 2025-10-28 (pre-SR-end), W2 ends 2026-06-07 (pre-SR-end), W3 ends 2027-03-22 (post-SR). H11 keeps W3. ✓ matches Marina.
- Olga NTJ: engine W1 ends 2025-10-05 (pre-SR-end), W2 ends 2026-04-06 (pre-SR-end), W3 ends 2027-02-05 (post-SR). H11 keeps W3. ✓ matches Marina.
- Olga UOU / NTU / PSU: all engine windows have end_date ≥ SR. H11 keeps all. ✓ matches Marina (3 / 4 / 4).

H11 yields **6/6 perfect match on Olga**. Promising on the trained set.

**Calibrated held-out application** (calibrated as test, H11 trained-on-Olga):
- 01-kseniya Uranus Opposition Sun: Marina shows 3 windows, but W1 ends 2024-10-22 (pre-SR-end SR=2024-11-19). H11 drops W1 → 2 windows. FN = 1 (Marina W1 = `2024-07-14 → 2024-10-22`).
- 01-kseniya Uranus Opposition Uranus: W1 ends 2024-08-05 (pre-SR-end). H11 drops → 2 windows. FN = 1.
- 01-kseniya Neptune Trine Sun: W1+W2 entirely pre-SR-end; W3 ends 2025-02-11 (post-SR). H11 keeps only W3 → 1 window. FN = 2 (Marina W1, W2).
- 01-kseniya Neptune Square Mars: same shape. FN = 2.
- 05-ekaterina Neptune Trine Jupiter: W1 pre-SR-end (2024-09-28 ≤ SR=2025-03-11). H11 drops W1 → 2 windows. FN = 1.
- 10-danila Uranus Square Moon: W1+W2 pre-SR-end (W1 = 2024-10-25, W2 = 2025-06-02 ≤ SR=2025-08-05); W3 ends 2026-03-16 (post-SR). H11 keeps only W3 → 1 window. FN = 2 (Marina W1, W2).

H11 breaks **5 calibrated cards** with **9 Marina-window FN** while perfectly fitting all 6 Olga cards. This is **textbook training-set overfit**. H11 hypothesis discovered post-hoc on Olga **does NOT generalise** to calibrated cases.

| Hypothesis discovery context | Olga fit | Calibrated fit | Aggregate window cov-% (OVERLAP) | Card-FN (any FN) STRICT |
|---|---|---|---|---|
| H11 trained on Olga 6 (full fit) | 6/6 perfect | 9/27 calibrated windows FN; 5 cards with ≥1 FN | 84.2% | 7/20 cards |
| Engine baseline (no rule) | 3/6 over-emit | 6 Marina-windows over-emit on Olga 3 cards | 100.0% | 1/20 cards (boundary, not selection) |

**H11 is empirically falsified as a general rule.** It captures only Olga's editorial narrowing decision; it does not reproduce Marina's actual behaviour on calibrated cases where pre-SR-end windows are shown in full (e.g. Kseniya Neptune Trine Sun has 2 entirely pre-SR windows, Marina shows all 3; Danila Uranus Square Moon has 2 entirely pre-SR windows, Marina shows all 3).

H12 (soft variant: drop only if end < SR-30) and H13 (H11 + far-future cap) behave similarly — same trained-on-Olga / falsified-on-calibrated pattern.

### § 2.5 Phase 9.0 § 5.3 «target-class» prediction test

Phase 9.0 § 5.3 predicted: «For outer-personal/outer-social cards: sometimes narrows to single «main touch»; for outer-outer cards: always show all».

Apply this rule («if target ∈ {personal-or-social}: show 1 window; else: show all»):
- Olga URV (target Venus = personal): show 1 → predicted; Marina shows 1. ✓
- Olga UOJ (target Jupiter = social): show 1; Marina 1. ✓
- Olga NTJ (target Jupiter = social): show 1; Marina 1. ✓
- Olga UOU (target Uranus = outer): show all (3); Marina 3. ✓
- Olga NTU (target Uranus = outer): show all (4); Marina 4. ✓
- Olga PSU (target Uranus = outer): show all (4); Marina 4. ✓

**Olga: 6/6 perfect.** Aligned with Phase 9.0 § 5.3 hypothesis.

But Phase 9.0 hypothesis applied to calibrated cases:
- 01-kseniya Uranus Opposition Sun (target Sun = personal): predicted 1; Marina shows 3. ✗ violation.
- 01-kseniya Neptune Trine Sun (target Sun = personal): predicted 1; Marina shows 3. ✗ violation.
- 01-kseniya Neptune Square Mars (target Mars = personal): predicted 1; Marina shows 3. ✗ violation.
- 03-artem Uranus Trine Sun (personal): predicted 1; Marina 3. ✗ violation.
- 03-artem Uranus Trine Mars (personal): predicted 1; Marina 3. ✗ violation.
- 03-artem Neptune Opposition Sun (personal): predicted 1; Marina 3. ✗ violation.
- 05-ekaterina Uranus Square Moon (personal): predicted 1; Marina 3. ✗ violation.
- 05-ekaterina Uranus Sextile Jupiter (social): predicted 1; Marina 3. ✗ violation.
- 05-ekaterina Neptune Trine Jupiter (social): predicted 1; Marina 3. ✗ violation.
- 10-danila Uranus Square Moon (personal): predicted 1; Marina 3. ✗ violation.
- 10-danila Neptune Square Venus (personal): predicted 1; Marina 3. ✗ violation.
- 10-danila Neptune Square Jupiter (social): predicted 1; Marina 4. ✗ violation.

**11 of 11 calibrated personal/social-target cards violate the Phase 9.0 § 5.3 prediction.** Marina shows the full window list on these cases, not 1 window.

**Phase 9.0 § 5.3 hypothesis is empirically falsified as a general rule.** It fits Olga but breaks on every calibrated case with personal/social target. The target-class explanation is **specific to Olga's PDF, not a programme-wide Marina decision pattern**.

### § 2.6 Summary of base + composite hypothesis empirical findings

| Finding | Evidence |
|---|---|
| Marina's window selection ≈ engine emit on calibrated 4 (under positional / OVERLAP match) | § 1.1: every calibrated card has Marina_W_i ≡ Engine_W_i ±2d (per `MARINA_OUTER_CARD_BOUNDARIES` data and Phase 8B/8E calibration). 14/14 calibrated cards match positionally + boundary at ±2d. |
| Marina narrows 3 of 6 Olga cards (URV/UOJ/NTJ → 1 window each) | § 1.2 + § 1.4: Marina shows W3 only (engine ordinal 3), drops engine W1+W2. |
| Marina shows full engine emit for outer-outer Olga cards (UOU/NTU/PSU) | § 1.2 + § 1.4: 3/3/4/4 windows respectively. |
| All horizon-only hypotheses H1-H6 under-emit Marina by 22-35 windows across the 57-window scoring set | § 2.1 OVERLAP view: cov% range 40.4 – 70.2 for H1-H6. |
| H1-H6 do not preserve Marina's pre-SR-shown windows in calibrated cases (Kseniya Neptune Trine Sun: 3 Marina pre-SR-windows, all dropped by H1) | § 2.2 detail. |
| H11 (drop pre-SR-end) fits Olga perfectly (6/6) but breaks 5 calibrated cards (9 window FN) | § 2.4 overfit test. |
| Phase 9.0 § 5.3 «target-class» rule fits Olga 6/6 but violates 11 of 11 calibrated personal/social-target cards | § 2.5. |
| Engine baseline (no horizon trim) achieves 100% window coverage in OVERLAP view; 6 FP (Olga narrowed cards over-emit) | § 2.1 + § 2.2: engine matches Marina on every calibrated card and 3 of 6 Olga cards (UOU/NTU/PSU); over-emits on 3 Olga cards (URV/UOJ/NTJ). |
| Engine baseline STRICT FAILs only due to Pluto Sextile Uranus boundary tightness (Phase 4a / Phase 8 territory), NOT selection | § 1.2 PSU diagnostic. |

**Aggregate finding: no horizon / window-selection rule reproduces Marina across both Olga and calibrated.** Olga's narrowing is editorial / per-case-curated, exactly as Phase 9.0 § 5.3 predicted.

---

## § 3. Aggregate scoreboard — which hypothesis approximates Marina best

### § 3.1 Verdict per hypothesis (STRICT view, TASK § 2.3 literal)

| Hypothesis | Verdict | Notes |
|---|---|---|
| engine | FAIL | 4 boundary-FN on Pluto Sextile Uranus (Phase 8 territory) |
| H1 / H1_broad / H2 / H3 / H4 / H5 / H6 / H7 | FAIL | 14-17 card-FN, 25-35 window-FN, 38-56% coverage |
| H8 | FAIL | 3 card-FN, 6 window-FN, 89.5% coverage (just below PASS threshold) |
| H9 / H10 / H11 / H12 / H13 | FAIL | 6-13 card-FN, 12-21 window-FN, 63-79% coverage |

**STRICT verdict: 0 hypotheses PASS.**

### § 3.2 Verdict per hypothesis (OVERLAP view, selection-focused)

| Hypothesis | Verdict | Notes |
|---|---|---|
| engine | **PASS** | 0 card-drop, 100% coverage, 6 FP on Olga's 3 narrowed cards |
| H8 | **PASS** | 0 card-drop, 94.7% coverage, 3 FN (Marina-W=4 cases), 6 FP (Olga narrowed) |
| H9 / H10 / H11 / H12 / H13 | PARTIAL | 0 card-drop, 70-86% coverage, 8-17 window-FN |
| H1_broad | PARTIAL | 61.4% coverage |
| H1 / H2 / H3 / H4 / H5 / H6 / H7 | FAIL | < 60% coverage |

**OVERLAP verdict: 2 hypotheses PASS (engine baseline + H8 first-3 cap).** Both over-emit on Olga's narrowed cards but preserve all Marina-selected windows.

### § 3.3 Best base hypothesis (per clarification 2 — no overfit risk)

**Best base hypothesis: engine baseline (show all engine windows; no horizon trim).**

- STRICT cov-% 93.0 (only Pluto Sextile Uranus boundary mismatch failing ±2d strict tolerance).
- OVERLAP cov-% 100.0 (preserves every Marina window across all 4 calibrated + 6 Olga cards).
- 0 card-drop.
- FP count 6 (3 Olga cards over-emit W1+W2 vs Marina W3 only).
- No overfit risk: rule is «no rule».
- No training-on-data: behaviour is engine emit as-shipped.

H8 (first-3 cap) is a near-equivalent (OVERLAP cov-% 94.7) with same overfit-free property but introduces a cap that breaks 3 of 20 cards (Marina-W=4 cases). H8 is not preferred over engine baseline because it loses correct windows on Marina-W=4 cards without gaining any selection on Olga's narrowed cards (Olga URV / UOJ / NTJ engine W1+W2+W3 → H8 still emits 3 = 2 FP each).

### § 3.4 Best composite (with overfit caveat)

**H11 (drop windows where end < SR) yields 100% fit on Olga (6/6 cards) but 9 calibrated window-FN (5 of 14 calibrated cards have ≥1 FN).**

- Trained on Olga 6 (post-hoc discovery from § 2.4 narrowing pattern analysis).
- Held-out validation on calibrated 14: 5 cards fail, 9 Marina windows missed.
- Overfit caveat: H11 reproduces Olga's editorial narrowing decision but mis-fits Marina's typical calibrated pattern (which shows all engine windows including pre-SR-entirely).
- Cannot be promoted to deterministic implementation rule without breaking calibrated.

**Best composite with caveat: H11 — descriptively correct for Olga, prescriptively wrong for calibrated.**

Per clarification 2: «Final aggregate recommendation must distinguish: «best base hypothesis (no overfit risk)» vs «best composite (with overfit caveat)»». Worker recommendation:

- **Best base (no overfit risk):** engine baseline.
- **Best composite (with overfit caveat):** H11, applicable only as per-case editorial override (NOT default rule).

---

## § 4. Olga horizon root-cause analysis (cons10 vs cons11)

### § 4.1 cons10 vs cons11 engine emit diff

Both consultations share natal data + solar_chart.return_jd (= `2461234.877`). Difference is `annual_transit_table` sample horizon:

| Aspect | cons10 | cons11 |
|---|---|---|
| Sample buffer config (effective) | ≈ `[SR, SR+365]` narrow | ≈ `[SR-730, SR+1095]` wide |
| Card count emitted by `generic_outer_cards` | 6 (exact Marina inventory) | 11 (6 Marina + 5 over-include) |
| Per-card window counts vs Marina | 3/6 match; 3/6 under-emit | 3/6 match; 3/6 over-emit |

cons10 «accidentally» matches Marina's URV/UOJ/NTJ narrowing because the post-SR window-3 is the only engine window inside `[SR, SR+365]`. But cons10 fails on UOU/NTU/PSU: it truncates engine W2/W3/W4 which Marina shows.

cons11 matches Marina's complete window inventory positionally on UOU/NTU/PSU; over-emits on URV/UOJ/NTJ (engine W1+W2 are pre-SR; Marina drops them as editorial choice).

**Neither consultation's horizon is the rule.** cons10 narrow is a sample-buffer truncation accident that happens to match Marina's editorial narrowing for 3 cards while breaking 3 others. cons11 wide is correct engine emit; Marina narrows 3 cards editorially over this emit.

### § 4.2 What Marina actually does for Olga (descriptive, not prescriptive)

Marina's PDF narrowing decision for URV/UOJ/NTJ correlates with:
- Target class: personal (Venus) or social (Jupiter), NOT outer (Uranus).
- Engine W1+W2 are entirely pre-SR (end_date < SR), Marina drops them.
- Engine W3 is intra-SR (the «first post-SR window»), Marina keeps it.

But Marina's calibrated PDF behaviour for the same target-class + same horizon-relation **does NOT narrow** (e.g. Kseniya Uranus Opposition Sun shows pre-SR-entirely W1; Danila Uranus Square Moon shows pre-SR-entirely W1+W2). The target-class + horizon-relation rule applies to Olga but not to anyone else, so it's not a deterministic Marina rule. It's an Olga-PDF-specific editorial decision.

### § 4.3 Information-only background: cases 02 / 04 / 08 / 09 (per clarification 3)

Cases 02, 04, 08, 09 are not in main scoring set per user clarification 3 (Marina shows single Marina W per card; positional alignment with engine intervals[i] often partial per Phase 8 audit § A.2.1.D). Background observation only:

- **02-maksim**: Marina single-W per card (engine W3 of engine ordinal 3). NOT a horizon rule — Marina editorially narrows to last-touch (post-Phase 7b calibration pattern).
- **04-valeriya**: Marina single-W per card (engine W2/W3 of engine ordinal). Same editorial-narrowing pattern as 02.
- **08-natalya**: Phase 4b structured override structure exists (test_natalya_transits_acceptance.py); Marina single-W W1 with editorial start +200d offset.
- **09-anastasiya**: TYPE-D SR mismatch ~60 min vs Marina caption; boundary tests opt out (audit § A.2.1.D).

These cases reinforce the Phase 9.0 § 5.3 «strong editorial residual» verdict but are not within Stage 2 verdict scoring.

---

## § 5. Recommendation

### § 5.1 OVERLAP-view PASS path — engine baseline is the rule

Under OVERLAP view (selection-focused metric decoupling from boundary tightness), **the engine baseline PASSes (0 card-drop, 100% coverage, 6 FP)**. The 6 FP are all on Olga's 3 narrowed cards (URV/UOJ/NTJ over-emit pre-SR W1+W2 vs Marina-shown W3 only).

**Recommended action: keep engine baseline as production default; Marina's Olga-specific narrowing is editorial / per-case.**

This is consistent with Phase 9.0 § 5.3 written verdict («Default «show all» is deterministic match for ~60-70% of cards; editorial single-window choice не reverse-engineerable from current 10-case data») and the explicit recommendation «Continue engine default (show all). Accept divergence на 30-40% non-calibrated cases — this is editorial per-card choice. For specific clients (when Marina explicitly narrows), use per-case overrides (allowlist-style).»

Phase 9.3A empirical validation **confirms** Phase 9.0 § 5.3 verdict. The 14-window OVERLAP super-set hypothesis (engine baseline + nothing) is the best generalisable behaviour.

### § 5.2 STRICT-view PARTIAL path — boundary tightness is a separate concern

Under STRICT view, **engine baseline FAILs only because of Pluto Sextile Uranus boundary tightness** (4 Marina windows fail ±2d match against engine windows, even though all 4 are positionally contained). This is Phase 8 territory (`_OUTER_CARD_BOUNDARY_TOLERANCE_DAYS` semantics) or Phase 4a aggregate-display-windows territory — NOT Phase 9.3A horizon/window-selection.

**Recommended action: explicitly separate «boundary tightness» from «window selection» in Phase 9 programme classification.** Phase 9.3A scope is window-selection only; STRICT-view fail on Pluto Sextile Uranus does NOT count as 9.3A failure mode. A future Phase 9.5 / 8.x sub-track could investigate orb-tightness for Pluto cards if Marina's narrower-than-engine boundary needs reproducing.

### § 5.3 Editorial verdict + per-case override proposal

No deterministic horizon / window-selection rule reproduces Marina across both Olga and calibrated 4. Olga's narrowing for URV/UOJ/NTJ is editorial; Marina's «show all engine windows» for calibrated is also editorial (in the sense that Marina explicitly accepts the engine's pre-SR + post-solar-year windows). Hypothesis testing yields:

- **0 hypotheses PASS** under STRICT view.
- **2 hypotheses PASS** under OVERLAP view (engine + H8). Engine is preferred (94.7% → 100% cov gain, no Marina-W=4 cap penalty).
- **All «horizon-trim» hypotheses (H1-H7, H9, H10, H11, H12, H13) FAIL** as generalisable rules.

**Verdict per TASK § 2.3 + clarification 4 thresholds:**

- **STRICT view: ALL FAIL.** Card-FN 1-17 across hypotheses.
- **OVERLAP view: engine + H8 PASS; remainder FAIL or PARTIAL.**

Per TASK Stage 3 § 5.3 «If all hypotheses FAIL → § 5.3 editorial verdict + per-case override proposal»: STRICT view applies. Engine baseline OVERLAP-PASS is the existing production behaviour.

**Phase 9.3A verdict: PARTIAL (editorial residual confirmed).**

- Engine baseline is empirically the best generalisable rule.
- 3 Olga-specific narrowed cards (URV/UOJ/NTJ) require editorial override for Marina-style narrowing.
- No deterministic horizon trim accepted as production filter.

#### § 5.3.1 Per-case override structure proposal

For future Phase 9.3B (if Marina explicitly requests Olga-PDF style narrowing for new consultations), a per-case override mechanism — parallel to `_OUTER_CARD_FACTS` Phase 4b `STRUCTURED_OVERRIDES` — would be:

```python
# Hypothetical Phase 9.3B addition to `services/api-python/app/pdf/outer_cards.py`
# Not implementation — outline only per TASK Stage 3 § 5.3 framing.

_OUTER_CARD_WINDOW_OVERRIDES: dict[
    str,  # case_id
    dict[
        tuple[str, str, str],  # (transit_planet, aspect, target)
        list[int],  # ordinal indices (0-based) of engine windows to keep
    ]
] = {
    "11-olga-2026-2027": {
        ("Uranus", "Square", "Venus"): [2],       # keep engine W3 only
        ("Uranus", "Opposition", "Jupiter"): [2], # keep engine W3 only
        ("Neptune", "Trine", "Jupiter"): [2],     # keep engine W3 only
        # outer-outer cards: no override; default all-windows
    },
}
```

This is **parallel to Phase 4b `STRUCTURED_OVERRIDES`** pattern (`services/api-python/tests/test_natalya_transits_acceptance.py`) — narrow scope, per-case, no global rule change. Calibrated 01-10 cases would have no override entries; default = show all.

**Implementation cost (Tier B estimate):**
- 1 file modification: `services/api-python/app/pdf/outer_cards.py` — add `_OUTER_CARD_WINDOW_OVERRIDES` constant + `build_outer_card`/`outer_cards_for_case` window-index filter logic.
- 1 test addition: `services/api-python/tests/test_outer_card_windows.py` — pin Olga URV/UOJ/NTJ 1-window output when override applied; pin calibrated cases unchanged.
- No engine, schema, fixtures, template changes.
- Allowlist branch (`outer_cards_for_case`) unchanged — overrides apply after generic-fallback or calibrated cards built.

**This is NOT Phase 9.3A scope. Outline only for future TL framing.**

#### § 5.3.2 Programme implication — Phase 9.0 meta-pattern reinforced

Phase 9.3A continues the Phase 9.x lesson recurrence:

| Phase | Memo verdict | Empirical validation outcome |
|---|---|---|
| 9.1 directions | «hybrid / deterministic-leaning» | FALSIFIED — no deterministic A1+A2+A3 reproduces Marina across calibrated. Memo § 5.1 erratum landed; editorial / curation-required verdict. |
| 9.2 outer cards (filter) | «hybrid» | CONFIRMED for angle-target component (Stage 0 PASS). Significator-supplement diagnostic over-prunes (3/6 Olga drop), not promoted. |
| 9.3 intervals | «hybrid (strong editorial residual)» | **CONFIRMED** — engine baseline is best generalisable; Olga 3-card narrowing is per-case editorial. No new deterministic rule. |
| 9.4 summary | «deterministic 8/8» | FALSIFIED — engine matches Marina 4/6 (cases 05/09 differ in tie-break). Memo § 5.4 erratum landed; partial deterministic + editorial residual verdict. |

**Phase 9 meta-pattern: 4 sub-problems, 4 strict empirical validations — 1 confirmation, 2 falsifications, 1 partial confirmation.** Phase 9.x lesson: «memo verdicts derived from sample-pattern coherence require strict empirical validation before implementation».

Phase 9.3A specifically confirms memo § 5.3 verdict's «strong editorial residual» qualification — the empirical data supports the original «default show-all + per-case editorial override» recommendation. No erratum DOWNGRADE warranted; an erratum CONFIRMATION (per clarification 5 — all-paths erratum drafted in HANDOFF) may strengthen the verdict's empirical footing.

---

## § 6. Phase 9.0 memo § 5.3 erratum draft

Per clarification 5 (= b, all-paths erratum drafted in HANDOFF for user ack before landing in memo file). Worker proposes erratum text per current verdict path (PARTIAL with OVERLAP-PASS engine baseline + editorial residual on 3 Olga cards).

**Erratum draft (PARTIAL-path):** see HANDOFF § Erratum drafts.

PARTIAL path applies because:
- 2 hypotheses PASS in OVERLAP view (engine + H8) — verdict NOT FAIL.
- 0 hypotheses PASS in STRICT view due to Phase 8 boundary tightness on Pluto Sextile Uranus (orthogonal to selection question).
- Editorial residual confirmed for Olga's 3 narrowed cards.

Per Phase 9.1 erratum landing pattern (parallel precedent), erratum lands in memo file only after user explicit ack. Worker does NOT modify Phase 9.0 memo in-place per STOP discipline.

---

## Appendix A — Files inspected (read-only)

- TASK: `project-overlays/astro/TASKS/2026-05-19-phase-9-3-a-outer-card-horizon-window-validation.md` (6 clarifications applied).
- Phase 9.0 memo § 5.3: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.
- Phase 9.2A validation memo: `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md`.
- `MARINA_OUTER_CARD_BOUNDARIES`: `services/api-python/tests/test_multi_case_calibration.py:870-967`.
- `OUTER_CARD_ALLOWLIST`, `generic_outer_cards`, `_collect_raw_hits`, `aggregate_display_windows`: `services/api-python/app/pdf/outer_cards.py` (lines 160-254, 363-422, 445-475, 1671-1769).
- Marina-Olga PDF: `/Users/ilya/Downloads/Соляр 2026-2027.pdf` pp. 28-32 (Uranus Square Venus, Uranus Opposition Uranus, Uranus Opposition Jupiter, Neptune Trine Jupiter, Neptune Trine Uranus, Pluto Sextile Uranus — window dates only per Stage 0.3 strict scope).
- Olga DB facts: `data/astro.db` rows id=10 (narrow horizon), id=11 (wide horizon) `consultations.facts_json.annual_transit_table`.
- Calibrated 4 expected fixtures: `packages/test-fixtures/golden-cases/{01-kseniya-2024-2025,03-artem-2025-2026,05-ekaterina-2025-2026,10-danila-2025-2026}.expected.json`.

**NO product code modified.** **NO tests written.** **NO Haskell engine recomputation.** **NO ad-hoc Marina PDF re-extraction beyond window dates for the 6 Olga Marina-selected cards (strict Stage 0.3 scope).** **NO Phase 9.0 memo in-place modification.**

## Appendix B — Worker scope discipline

- ✓ Read TASK spec + 6 clarifications + Phase 9.0 § 5.3 + Phase 9.2A precedent + CLAUDE.md + architecture-invariants + corrections.
- ✓ Stage 0 inventory: Olga cons10 + cons11 + 4 calibrated cases + Olga PDF strict-scope extract.
- ✓ Stage 1: 6 base hypotheses (H1-H6) + 7 composites (H7-H13) explicitly tagged.
- ✓ Stage 2 per-hypothesis evaluation matrix populated.
- ✓ Stage 3 verdict synthesis + § 5 PARTIAL recommendation + § 5.3.1 override structure outline.
- ✓ § 6 erratum draft in HANDOFF (all-paths convention).
- ✓ Pytest baseline 382/2/0 preserved (NO test files written).
- ✓ Cabal clean (NO Haskell changes).
- ✓ Product `git status --short` clean (NO product code modifications).
- ✓ OVERLAP-view PASS for engine baseline DOES NOT trigger erratum DOWNGRADE — erratum landing pattern per clarification 5 requires user ack.
- ✓ Overfit-risk test for H11 + Phase 9.0 § 5.3 «target-class» prediction explicitly run on Olga held-out vs calibrated trained.
- ✓ STOP discipline observed:
  - No product code modifications (Tier C strict).
  - No tests written (validation-only).
  - No engine recomputation (existing facts only).
  - No ad-hoc PDF re-extraction beyond strict-scope window dates.
  - Hypothesis testing strictly from listed H1-H6 + composite-rule expansion per clarification 2.
  - No silent «adjust hypothesis to fit data» — H11 documented as falsified, not promoted.
  - No Phase 9.0 memo in-place edit — erratum lives in HANDOFF only.
- ✓ Olga inventory ambiguity from Phase 9.2A § 0.4 partial extract NOT pinned in conclusions — § 1.2 + § 1.3 use cons11 wide horizon authoritative engine emit + strict-scope Marina PDF extract.
