# TASK: phase-7-stage-b-closed-config-calibration

- Status: in-progress
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

Phase 7 follow-up после TASK 7a (label-arithmetic fix landed commit `8a4865e`). TASK 7 Stage A был closed с verdict «Blockers identified» из-за TYPE-B regression в `transit_matrix_by_month`. TASK 7a fix теперь permits:

1. **Phase 7 Stage A re-validation** — verify case 07 monthly table теперь 13/13 cells (post-fix); confirm cases 05/10 без regression.
2. **Phase 7 Stage B closed-config calibration** — extend `outer_cards.py:OUTER_CARD_ALLOWLIST` для cases 05 и 10 с closed card-facts из Marina эталонов; create per-case acceptance test infrastructure; create canonical `render_case.py` для parametrized rendering.

Это **финальная implementation TASK программы Transit Section Recovery.** После closing + явного user ack на updated calibration report → recovery program closes, PDF можно показывать Марине.

## Stages

### Stage A.2 — Re-validation (case 07 fix verification)

> **Gate amended 2026-05-13 by TASK 7c** (`2026-05-13-phase-7c-gate-amendment-typea-monthly-boundary.md`). Original literal «13/13 cells match» replaced with amended (a)-(d) gate below. Background: Worker run 2026-05-13 produced 13/13 labels + 11/13 cells; 2 residual mismatches (case 07 rows 12-13) classified TYPE-A anchor-day boundary divergences (same family as case 05 Venus Jul 2025), not regression.

Worker запускает Stage A diff заново на case 07 после TASK 7a fix:
- Render case 07 PDF через canonical render (TASK 7b creates `render_case.py` first, OR throwaway script если render_case.py creation deferred). **NOTE:** `services/api-python/scripts/render_case.py` уже создан в Worker session 2026-05-13 (untracked); resume Worker re-validates на нём.
- Monthly table label sequence: **13/13 unique consecutive labels** `[Июль 2025, Август 2025, ..., Июль 2026]` (per TASK 7a regression test pinned in `test_mariya_transit_matrix.py`).
- Monthly table cell values: **≥11/13 exact**, с cell mismatches только в TYPE-A boundary rows (case 07 rows 12-13 documented в calibration report § 4 items 4-5).

Cases 05 и 10 re-validated quickly (no expected regression — фикс не должен влиять на их monthly tables; они работали 51/52 и 13/13 соответственно). **Re-validation Worker run 2026-05-13 confirmed:** case 05 = 51/52 sustained, case 10 = 52/52 sustained.

Update calibration report § 3.2 (case 07) с post-fix results — 13/13 labels, 11/13 cells, 2 TYPE-A boundary rows referenced.

#### Amended Stage A.2 → Stage B gate (per TASK 7c)

Stage B is authorized **iff** all four conditions hold:

- **(a) No duplicate or missing month labels.** Each row label unique and consecutive per `[sr-month, sr-month + 1, ..., sr-month + 12]`. Verified by `test_mariya_transit_matrix.py` equality assertion.
- **(b) No TYPE-B regressions in monthly tables.** Cell values for non-boundary rows match Marina exactly. Cell-value mismatches outside documented TYPE-A boundary rows trigger STOP.
- **(c) Any monthly cell mismatch must be classifiable as TYPE-A boundary divergence** (cusp crossing within the 1st-to-15th gap of a calendar month), explicitly listed in calibration report § 4 with row label + planet + house transition + transition date.
- **(d) Calibration report verdict keeps the program state honest** — TYPE-A items enumerated, no rug-sweep, no implicit re-classification. Boundary rows remain visible to readers of the report.

If any of (a)-(d) fails → STOP, escalate, do not proceed to Stage B.

**Current state at TASK 7c closure (2026-05-13):** (a) PASS — 13/13 labels post-TASK 7a; (b) PASS — only TYPE-A boundary rows mismatch (verified by transit_matrix_by_month independent reproduction); (c) PASS — items 4-5 added to calibration report § 4 with full row/planet/transition data; (d) PASS — verdict updated honestly.

**Stage B authorized.** Worker resume on B.1 → B.2 → B.4 → doc/comment generalization → test helper generalization → B.5 → B.6.

### Stage B — Closed-config calibration

**Stage B authorized по amended gate (a)-(d) выше.** Original literal «13/13» gate replaced by TASK 7c; see preceding section for current condition statuses.

#### B.1 — Allowlist extension для case 05 Екатерина

Per Marina pp. 34-37 (`Соляр 2025-2026_2.pdf`), case 05 outer cards:
- `Уран кв Луне` (Uranus Square Moon)
- `Уран секст Юпитеру` (Uranus Sextile Jupiter)
- `Нептун триг Юпитеру` (Neptune Trine Jupiter)

Extend `OUTER_CARD_ALLOWLIST["05-ekaterina-2025-2026"]` с 3 triples. Populate `_OUTER_CARD_FACTS` per card (`transit_h`, `target_h`, `transit_ruled`, `target_ruled`, `walks`) визуально считанные с Marina pp. 34-37 «Золотое правило транзита» таблиц.

#### B.2 — Allowlist extension для case 10 Данила

Per Marina pp. 16-19 (`Соляр 2025-2026 для Данилы.pdf`), case 10 outer cards:
- `Уран кв Луне` (Uranus Square Moon)
- `Нептун кв Венере` (Neptune Square Venus)
- `Нептун кв Юпитеру` (Neptune Square Jupiter)

Extend `OUTER_CARD_ALLOWLIST["10-danila-2025-2026"]` с 3 triples. Populate `_OUTER_CARD_FACTS` per card.

**Case-10 card 3 = 4 windows (Marina editorial):** Production logic уже iterates `card.intervals` и ordinals покрывают 1..5 — generic rendering уже поддерживает N windows. **Worker НЕ меняет semantic logic.** Только:

- **Test side:** generalize `_assert_three_phase_intervals` helper для optional `expected_window_count` parameter (default 3); case 10 card 3 uses 4. Test-helper-only change, не production code.
- **Engine output discipline:** если `aggregate_display_windows` уже возвращает **4 windows** для `Нептун кв Юпитеру` Данилы — Stage B принимает как есть, тест assertion `len(windows) == 4`. Если engine возвращает другое число (например 3 или 5) — **STOP, escalation memo, не хардкодить window в production facts**. Engine source of truth — если расходится с Marina, это TYPE-B или TYPE-C, не «накладной патч».
- **Doc/comment side:** comments/docstrings в `outer_cards.py` и `solar.html.j2` всё ещё могут говорить «3 intervals / три касания» — Worker может заменить на «3+ / per Marina card» (без semantic code change). Это explicitly authorized в Files section.

#### B.3 — Canonical render script

Create `services/api-python/scripts/render_case.py` — parameterised render с `--case-id` argument. Replaces Stage A throwaway script. Reuse `provenance.py` (Phase 1). `render_natalya.py` остаётся (existing canonical для case 08), но может стать тонкой wrapper над `render_case.py --case-id 08-natalya-2025-2026`.

#### B.4 — Per-case acceptance tests

Single parameterised test файл `services/api-python/tests/test_multi_case_calibration.py` с tests per case (05, 07, 10). Shared helpers reuse `_assert_three_phase_intervals` (or generalized `_assert_n_phase_intervals` per B.2).

Per case assertions:
- Monthly table label sequence equality (case 07 уже covered TASK 7a; добавить для 05 и 10).
- Outer cards present per allowlist.
- Calendar rows match Marina rows (количество и dates ±tolerance).
- Дома цели through `rulership_houses.target_house_set`.

#### B.5 — Case 05 Venus monthly boundary — documented note only

Calibration report § 4 TYPE-A item 3: case 05 Venus Jul 2025 cell boundary diff ±1 house. **НЕ структурный override** — это не outer-card interval (Phase 4b structured override mechanism применим только к outer card intervals, не к monthly table cells). Также не new override mechanism — Stage B closed-config scope не расширяется до cell-level overrides для monthly table.

**Решение:** документировать как **TYPE-A note** в calibration report § 4 («case 05 Venus Jul 2025 cell boundary differs from Marina by ±1 house — known case-specific divergence; not regression»). Production code, fixtures, tests не меняются для этого item.

### Stage B.6 — Update calibration report

Update `transit-multi-case-calibration-report-2026-05-13.md`:
- § 3 per-case diff: post-fix Stage A.2 results.
- § 4 divergence reclassification (TYPE-A items resolved через closed-config; TYPE-C items documented).
- § 5 final override count + gate check.
- § 6 **final production-readiness verdict**: «Ready for Marina show — pending user ack» / «Blockers identified» / «Partial pass».

## Files

- new:
  - **`services/api-python/scripts/render_case.py`** — parameterised render.
  - **`services/api-python/tests/test_multi_case_calibration.py`** — single parameterised test file для cases 05, 07, 10.

- modify:
  - **`services/api-python/app/pdf/outer_cards.py`**:
    - Extend `OUTER_CARD_ALLOWLIST` с entries для `05-ekaterina-2025-2026` и `10-danila-2025-2026` (3 triples each).
    - Extend `_OUTER_CARD_FACTS` с closed card-facts per card (читать с Marina pp. 34-37 для case 05, pp. 16-19 для case 10).
    - **Doc/comment generalization authorized:** заменить comments/docstrings про «3 intervals / три касания» на «3+ intervals / per Marina card» где они привязаны к hardcoded 3. **НИКАКОГО semantic code change** — production уже iterates `card.intervals` + ordinals 1..5 уже cover up to 5 windows. Only docs/comments.
    - **`aggregate_display_windows` / `build_outer_card` core logic НЕ меняется.**
  - **`services/api-python/app/pdf/templates/solar.html.j2`** — **doc/comment generalization** (если есть Jinja comments или wording про «три касания» hardcoded для 3-only). Template уже iterates `card.intervals` generically — no semantic change.
  - **`services/api-python/tests/test_natalya_transits_acceptance.py`** — generalize `_assert_three_phase_intervals` helper для parametrized window count (case 10 card 3 = 4 windows). Add optional parameter `expected_window_count: int = 3`. **НЕ менять Phase 4b structured overrides на Натальи.**
  - **`services/api-python/scripts/render_natalya.py`** — может стать тонкой wrapper над `render_case.py` (optional refactor; Worker decides).
  - **`project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`** — update sections per Stage B.6 above.

- delete: —

## Do not touch

- **Haskell core, schema, fixtures, rulesets** — engine output stable.
- **Phase 1-6 generic logic** (anything semantic вне closed-config + tests):
  - `transit_themes.py` (Phase 3/5/6, теперь fixed) — НЕ менять semantic. Re-uses теперь правильный label arithmetic.
  - `rulership_houses.py` (Phase 5) — generic, не менять.
  - `outer_cards.py` `aggregate_display_windows` / `build_outer_card` функции — Phase 4 generic, не менять. **Только `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` data structures extend.**
  - `synthesis_themes.py` (Phase 3) — не менять.
  - `provenance.py`, `builder.py`, `solar.html.j2` — не менять.
- **Phase 4b structured overrides** на Натальи — Cat 4 Neptune `tolerance_overrides` остаются неизменными.
- **`test_natalya_transits_acceptance.py` Phase 4b xfail flips** — не менять; helper generalization для parametrized window count не должна regression'ить Натальи assertions.
- **expected.json fixtures** — не перезаписывать.

## Acceptance

### Stage A.2 — Re-validation (amended gate per TASK 7c)

- [ ] Case 07 Мария monthly table label sequence: **13/13 unique consecutive labels** (`[Июль 2025, ..., Июль 2026]`).
- [ ] Case 07 monthly cells: **≥11/13 exact**, mismatches only in TYPE-A boundary rows (rows 12-13 per calibration report § 4 items 4-5).
- [ ] Amended gate (a)-(d) all PASS (see Stages > Stage A.2 section).
- [ ] Case 05, 10 monthly tables: no regression (51/52 и 52/52 sustained respectively, verified Worker run 2026-05-13).
- [ ] Calibration report § 3.2 updated с post-fix results.

### Stage B.1 — Case 05 allowlist + card-facts

- [ ] `OUTER_CARD_ALLOWLIST["05-ekaterina-2025-2026"]` = 3 triples per Marina pp. 34-37.
- [ ] `_OUTER_CARD_FACTS` populated per card (transit_h, target_h, transit_ruled, target_ruled, walks).
- [ ] PDF case 05 рендерит 3 outer cards с Marina-style structure.

### Stage B.2 — Case 10 allowlist + card-facts + 4-window generalization

- [ ] `OUTER_CARD_ALLOWLIST["10-danila-2025-2026"]` = 3 triples per Marina pp. 16-19.
- [ ] `_OUTER_CARD_FACTS` populated per card.
- [ ] `_assert_three_phase_intervals` (или successor) supports parametrized `expected_window_count` parameter (default 3); case 10 card 3 uses 4.
- [ ] PDF case 10 рендерит 3 outer cards (one with 4 windows).

### Stage B.3 — Canonical render script

- [ ] `services/api-python/scripts/render_case.py` создан, accepts `--case-id` argument.
- [ ] Provenance sidecar generated per render с correct `case_label`.
- [ ] `render_natalya.py` либо тонкая wrapper, либо unchanged (Worker decides).

### Stage B.4 — Per-case acceptance tests

- [ ] `test_multi_case_calibration.py` создан с tests для cases 05, 07, 10.
- [ ] Tests assert monthly table labels (full equality per case sr month start).
- [ ] Tests assert outer cards present per allowlist.
- [ ] Tests assert calendar rows match Marina.

### Stage B.6 — Calibration report final

- [ ] Report § 6 содержит **explicit verdict**:
  - «Ready for Marina show — pending user ack» — все cases pass; нет TYPE-B; override count в threshold.
  - «Partial pass — program NOT production-ready» — некоторые sections не closed; per-case status.
  - «Blockers identified — program NOT production-ready» — TYPE-B regressions found.

### Override count + Phase 4b gate clause

- [ ] Total tolerance overrides applied (Натальи Phase 4b + B.5 если done) = **M**.
- [ ] M ≤ 10 across all cases И ≤ 5 per single case → within threshold.
- [ ] Если M > threshold → STOP, escalation, "Blockers identified".

### Common acceptance

- [ ] `cabal build` (Phase 2 lesson).
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. **Acceptance count formula:** `(150 baseline) + (N new multi-case tests) passed, 0 xfailed, 0 failed`. Не фиксировать конкретное число — N зависит от Worker'овского test coverage.
- [ ] `git status --short` чисто для intended product changes. Pre-existing `.claude/scheduled_tasks.lock` разрешён.
- [ ] Один commit (или ≤ 3 при чистой границе: render_case.py + allowlist extensions + tests). Worker обосновывает.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verify calibration report + production-readiness verdict + sample PDFs per case.
- [ ] HANDOFF содержит:
  - Stage A.2 re-validation results (case 07 13/13 cells confirmed).
  - Stage B per-section completion status.
  - Override count + gate clause status.
  - Production-readiness verdict.
  - Path к updated calibration report.
  - Paths to 3 PDFs per case (Stage A.2 outputs).

### Scope discipline

- [ ] Затронуты: `outer_cards.py` (ALLOWLIST + FACTS data extend only), `test_natalya_transits_acceptance.py` (helper generalization, no Phase 4b changes), `scripts/render_case.py` (new), `tests/test_multi_case_calibration.py` (new), `calibration-report.md` (update).
- [ ] Engine, schema, fixtures, Haskell core — 0 lines changed.
- [ ] `outer_cards.py` core logic (aggregate_display_windows, build_outer_card) — не меняется.
- [ ] `transit_themes.py` — не меняется (fix landed в TASK 7a).
- [ ] `rulership_houses.py`, `synthesis_themes.py`, `builder.py`, `solar.html.j2`, `provenance.py` — не меняются.

## Context

**Mode normal + Tier C** (validation + closed-config calibration). Worker subagent. Reviewer subagent необязателен.

**Baseline:** main @ `8a4865e` (TASK 7a label-arithmetic fix landed). Tests `150 passed + 0 xfailed + 0 failed`.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` + `transit-multi-case-calibration-report-2026-05-13.md` (Stage A baseline).

**Phase 7 sequence recap:**
- TASK 7 (Stage A original) — CLOSED with verdict «Blockers identified» (case 07 monthly table failure).
- TASK 7a (label-arithmetic fix) — CLOSED, commit `8a4865e`, 150 passed.
- **TASK 7b (this — Stage A.2 re-validation + Stage B closed-config calibration)** — current TASK.
- After TASK 7b с «Ready for Marina show — pending user ack» verdict + явный user ack → recovery program closes, PDF can be shown to Marina.

**Production-readiness gate (per TASK 7 spec semantics):** TASK 7b closing **не automatically** = production-ready. Достаточное условие = «Ready for Marina show» verdict + явный отдельный user ack после reading updated calibration report.

**Worker scope discipline:**
- Stage A.2 = read-only validation (no product changes).
- Stage B = closed-config only (allowlist + card-facts data + test infrastructure + render_case.py).
- **Любая попытка trogать generic logic вне config = TYPE-B / scope miss → STOP, escalation memo.**

**Phase 4b gate clause check** (per architecture document § 7 запрет 7): Total tolerance overrides applied across all calibration cases (Натальи Phase 4b = 2 + any new B.5) ≤ 10 total и ≤ 5 per case. Worker reports M в HANDOFF; если exceeded → STOP, escalation.

**Ready: yes** — flipped после ack пользователя на TASK 7b spec (3 refinements applied: doc/comment generalization, case 10 4-window engine discipline, B.5 documented-note-only).
