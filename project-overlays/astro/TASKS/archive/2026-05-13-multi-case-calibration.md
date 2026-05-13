# TASK: multi-case-calibration

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

Phase 7 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 7, § 8 TASK 7). **Финальная phase программы.** Цель — доказать что Phase 1-6 работают не только для одной Натальи, но и для других golden cases.

Phase 1-6 работа была откалибрована на case 08 (Наталья). Phase 7 — verification что новый transit-section presentation:
- Корректно рендерится для других cases без regression;
- Соответствует Marina эталонам где они доступны;
- Не подгонка под Наталью (universal logic — Phase 5 rulership, Phase 6 clipping, Phase 4 outer cards allowlist per case_id).

После closing Phase 7 — программа Transit Section Recovery **полностью завершена**. PDF status можно повысить до production-ready (Марине можно показывать) только после **явного ack пользователя** по всему набору calibration cases.

## Marina reference inventory (pre-mapped by TL via solar return time)

В `/Users/ilya/Downloads/Gmail (3)/` присутствуют Marina solar PDFs. TL pre-mapped via solar return time inspection:

```
Соляр 2024-2025.pdf                       ← previous year, out of scope for Phase 7
Соляр 2025-2026 для Анастасии.pdf         ← case 09 (Анастасия) CONFIRMED
Соляр 2025-2026 для Данилы.pdf            ← case 10 (Данила) CONFIRMED
Соляр 2025-2026.pdf                       ← case unknown (low priority — not in default selection)
Соляр 2025-2026_1.pdf                     ← case unknown (low priority)
Соляр 2025-2026_2.pdf                     ← case 05 (Екатерина) CONFIRMED
Соляр 2025-2026_3.pdf                     ← case unknown (low priority)
Соляр 2025-2026_4.pdf                     ← case 07 (Мария) CONFIRMED
Соляр 2025-2026_5.pdf                     ← case 08 (Наталья) — Phase 1-6 oracle
Солярный гороскоп 2025-2026.pdf           ← case unknown (low priority)
```

**Worker validates pre-mapping** via `return_jd` from each case's `expected.json` matched against Marina PDF p.1 / first chart date. Does **not** rebuild mapping from scratch. If validation fails for any default mapping — flag в HANDOFF, fallback к alternative case selection.

## Calibration case selection — default confirmed

Architecture default: **05-ekaterina, 07-mariya, 10-danila** (per Phase 7 § 5 + § 8 TASK 7). **TL pre-confirmed all three** через inventory mapping above.

**Worker uses defaults без re-selection.** Если return_jd validation для одного из defaults fails (е.g. PDF не соответствует case) — Worker falls back к `09-anastasiya` (4th confirmed Marina PDF) с явным обоснованием в HANDOFF.

## Two-stage execution discipline

**Stage A (read-only validation) — обязательно first.** Любые product changes в Stage A запрещены.

- A.1. Validate pre-mapped Marina inventory против return_jd per case.
- A.2. Для каждого из 3 selected cases — сгенерить PDF через canonical render (using existing `render_natalya.py` for case 08 or new `render_case.py` если требуется для других cases — но это **read-only generation**, не feature work).
- A.3. Extract Marina reference dates (pypdf / visual).
- A.4. Per-section diff Marina vs our PDF — **результат = markdown diff report**, без code/test changes.
- A.5. Classify each divergence as TYPE A / TYPE B / TYPE C (см. ниже).
- A.6. Compute total override count + Phase 4b gate check.

**Stage A deliverable:** `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` § 1-4 (inventory, selection, per-case diff, classification + gate check). **Без product code changes.**

**Stage B (closed-config calibration) — только при Stage A approval.**

Stage B авторизован только если Stage A diff показывает:
- Нет TYPE-B regressions (если есть TYPE-B → STOP, escalate; Phase 7 closes как "Blockers identified").
- Override threshold не превышен.
- TYPE-A / TYPE-C divergences укладываются в closed-config-only fixes.

Stage B scope **строго ограничен closed-config additions**:
- Extend `outer_cards.py:OUTER_CARD_ALLOWLIST` entries per calibration case (allowlist + closed card-facts только; aggregate/build logic не меняется).
- Per-case acceptance test файлы (shared helpers + targeted assertions).
- `services/api-python/scripts/render_case.py` если canonical render parametrization требуется.

**Любая попытка добавить semantic logic вне closed config — TYPE-B regression / scope miss → STOP.** Это включает:
- Modifications в `transit_themes.py` (Phase 5/6 logic должна быть generic; multi-case change в неё — sign of regression).
- Modifications в `rulership_houses.py`, `outer_cards.py` aggregate/build функции, `synthesis_themes.py`.
- New presentation helpers за пределами test scaffolding.

## Per-case calibration sections (Stage A diff)

Для каждого выбранного case Worker сравнивает:

- **Monthly transit table** (`Транзиты планет по домам`): cell-by-cell match Marina table.
- **Per-house interpretations**: planets / houses listed matches Marina; no out-of-year dates.
- **Outer-planet cards** (Phase 4): если case имеет outer cards у Marina — **отсутствие allowlist entry для этого case = allowed closed-config gap (TYPE-A)**, не TYPE-B. Reportable as Stage-B-required addition.
- **Calendar (`КАЛЕНДАРЬ транзитных аспектов`)**: rows match Marina list; `Дома цели` use rulership-expanded sets (Phase 5).

## Divergence handling

Per case Worker classifies каждую divergence:

- **TYPE-A (acceptable / known — closed-config calibration gap)** — known editorial divergence (Phase 4b pattern: Marina boundary differs from engine за пределами ±2d) OR missing closed-config entry (allowlist / card-facts / tolerance_overrides) для нового case. Stage B authorizes structured additions through closed config only. **Если после добавления closed facts структура / render / card sections ломаются — это TYPE-B**, не TYPE-A.
- **TYPE-B (regression / scope miss)** — Phase 1-6 generic logic produces wrong output, не fixable через closed config. Включает:
  - Modifications требуемые в `transit_themes.py` / `rulership_houses.py` / `outer_cards.py` aggregate/build / `synthesis_themes.py` / `solar.html.j2` semantic logic.
  - Engine output mismatch (требует Tier A engine adjustment).
  - **STOP**, document в HANDOFF, escalate к TL для отдельного TASK на fix.
- **TYPE-C (Marina-specific editorial)** — Marina manually adjusted boundary / dropped/added row для этого case. Document как case-specific note; не требует code change.

## Phase 4b gate clause check (override accumulation)

Per architecture document § 7 запрет 7 / TASK 4b spec:

> «Если TASK 7 multi-case calibration покажет накопление similar Neptune (или другие slow-mover) overrides (>5 за case или >10 across all cases) — это сигнал что Path 4 структура не масштабируется и нужно пересмотреть продуктовый подход».

Worker считает total tolerance overrides applied across calibration cases. Если threshold exceeded — **STOP**, escalation memo к TL.

## Files

### Stage A (read-only validation)

- new:
  - **`project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`** — calibration report markdown:
    - § 1 Marina inventory mapping confirmation (TL pre-mapped; Worker validates return_jd).
    - § 2 Selected cases (default 05/07/10, или fallback к 09 если return_jd validation fails для одного из defaults).
    - § 3 Per-case section diff (monthly table / per-house / outer cards / calendar).
    - § 4 Divergence classification (TYPE A/B/C per case per row).
    - § 5 Total override count + Phase 4b gate clause check.
    - § 6 Production-readiness verdict.

- modify: — (Stage A read-only, no product changes)

### Stage B (closed-config calibration) — только при Stage A approval

- new:
  - **`services/api-python/scripts/render_case.py`** (если canonical render для multi-case parametrization требуется) — parameterised render по `--case-id`. Reuse `provenance.py` (Phase 1). Если existing `render_natalya.py` accepts case_id parameter — reuse без нового файла.
  - **Per-case test файлы**: shared helpers + targeted per-case acceptance tests. Worker chooses structure:
    - Option A: `services/api-python/tests/test_multi_case_calibration.py` — single file с parameterized tests per case.
    - Option B: `services/api-python/tests/_calibration_helpers.py` (shared) + `test_<case_id>_transits_acceptance.py` per case (targeted).
    Default — Option A для меньшего code duplication; Worker decides per scope.
- modify:
  - **`services/api-python/app/pdf/outer_cards.py:OUTER_CARD_ALLOWLIST`** — extend with allowlist entries per calibration case (если Marina shows outer cards для них). Closed card-facts (transit_h / target_h / ruled / walks) per case считываются визуально с Marina pp. golden-rule tables. **НЕ generic deduction** — closed facts per case. **`aggregate_display_windows` / `build_outer_card` функции НЕ меняются.**
  - (Optionally) `services/api-python/tests/test_natalya_transits_acceptance.py` — refactor common helpers (`_assert_three_phase_intervals`, etc.) в shared module если нужно избежать code duplication across test files.

### Запрещены modifications в Stage B (TYPE-B if Worker tries)

- `services/api-python/app/pdf/transit_themes.py` — Phase 5/6 logic должна быть generic для всех cases. Любая правка тут — TYPE-B.
- `services/api-python/app/pdf/rulership_houses.py` — Phase 5 helper generic.
- `services/api-python/app/pdf/outer_cards.py` aggregate / build функции — Phase 4 generic.
- `services/api-python/app/pdf/synthesis_themes.py` — Phase 3 generic.
- `services/api-python/app/pdf/builder.py` — case-agnostic через provenance.
- `services/api-python/app/pdf/templates/solar.html.j2` — generic template.

- delete: —

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — engine output stable across cases.
- **Schema, rulesets, fixtures** — `expected.json` per case stable; НЕ перезаписывать.
- **Phase 1-6 implementation artefacts** (provenance, render_natalya, transit_themes core logic, synthesis_themes, outer_cards aggregation/structure, rulership_houses, calendar clipping logic) — НЕ менять semantic. Только wiring updates для multi-case если необходимо.
- **`solar.html.j2`, `builder.py`** — НЕ трогать (template/builder агностичны к case через provenance.case_label).
- **`expected.json` files** для calibration cases — НЕ regenerate. Test contracts читают как input.
- **Phase 4b structured overrides** for Натальи — НЕ trogать (Path 4 baseline).

## Acceptance

### Phase 0 — Marina inventory mapping

- [ ] Worker идентифицирует каждый `Соляр 2025-2026_N.pdf` через natal-data inspection.
- [ ] Identification table в calibration report § 1.
- [ ] Confirmed Marina PDFs для ≥ 3 golden cases (default 05/07/10 или alternative per Worker decision).

### Phase 1 — Calibration case selection

- [ ] ≥ 3 cases selected с confirmed Marina PDF.
- [ ] Selection rationale в calibration report § 2 (мин. 3 sentences если default cases изменены).

### Phase 2 — Per-case calibration (для каждого case)

- [ ] PDF сгенерён через canonical render с provenance sidecar; SHA из current main HEAD.
- [ ] Monthly table cell-by-cell diff Marina vs our PDF.
- [ ] Per-house section: planets / houses listed match Marina; no out-of-year dates.
- [ ] Outer cards (если Marina показывает): allowlist extended; card-facts validated.
- [ ] Calendar rows match Marina list; Дома цели через rulership_houses helper.

### Phase 3 — Divergence classification

- [ ] Each divergence classified as TYPE A / B / C в calibration report § 4.
- [ ] TYPE B (regression) → STOP, escalation memo, blocker HANDOFF.
- [ ] TYPE A (acceptable known) → structured tolerance_overrides added if в acceptance test.
- [ ] TYPE C (case-specific editorial) → documented в report, no code change.

### Phase 4 — Phase 4b gate clause

- [ ] Total tolerance overrides applied across calibration cases + Phase 4b Натальи = **N**.
- [ ] Worker reports N в HANDOFF.
- [ ] **Если N > 10 across cases или > 5 per single case** → STOP, escalation memo (Phase 4b structure не масштабируется; нужен product-level review).

### Phase 5 — Tests

- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. **Acceptance count formula:** `149 baseline preserved + N new calibration tests, 0 xfailed, 0 failed`. **Не фиксировать конкретный ≥ 200** — N зависит от Worker'овского test coverage per case (shared helpers may reduce N below naïve 3× duplication).
- [ ] **Pre-existing Натальи tests НЕ regression** — все 149 продолжают passing.

### Phase 6 — Production-readiness verdict

- [ ] Calibration report § 6 содержит **explicit verdict**:
  - **«Ready for Marina show — pending user ack»** — все selected cases pass acceptance assertions; нет TYPE-B regressions; override count в пределах Phase 4b threshold. **Это НЕ автоматический production-ready** — требует **отдельного explicit ack пользователя** после reading calibration report. Recovery program closes только после ack.
  - **«Blockers identified — program NOT production-ready»** — найдены TYPE-B regressions либо override count exceeded threshold. Список + recommended fix tasks. Phase 7 closes с этим verdict; PDF Марине **не показывается**; recovery program остаётся open для resolution.
  - **«Partial pass — program NOT production-ready»** — некоторые sections pass, другие требуют follow-up. Per-case status + recommended next steps. PDF Марине **не показывается** до closing follow-ups.

**Production-readiness semantics:** TASK 7 closing **не** automatically повышает PDF до production-ready. Это **необходимое но не достаточное** условие. Достаточное = «Ready for Marina show» verdict + явный отдельный user ack после reading report.

### Common acceptance

- [ ] `cabal build` (Phase 2 lesson).
- [ ] `git status --short` чисто для intended product changes. Pre-existing untracked `.claude/scheduled_tasks.lock` разрешён, не commit'ить.
- [ ] Один commit (или ≤ 3 при чистой границе: render_case.py + test files + report + outer_cards allowlist extension). Worker обосновывает в HANDOFF.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия. Phase 7 = большая task (3 cases × multi-section validation); Worker может потребовать больше времени.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verify calibration report + production-readiness verdict + sample PDFs per case.
- [ ] HANDOFF содержит:
  - Marina inventory mapping table.
  - Selected cases + rationale.
  - Per-case PDF paths + extracted-text-vs-Marina diff summary.
  - Divergence classification counts (TYPE A/B/C per case).
  - Total override count + gate clause status.
  - Production-readiness verdict.
  - Path к calibration report.

### Scope discipline

- [ ] Затронуты: `scripts/render_case.py` (new), `app/pdf/outer_cards.py` (allowlist extension), `tests/test_<case>_transits_acceptance.py` (3+ new files), calibration report markdown в overlay ARCHITECTURE.
- [ ] Engine, schema, fixtures, Haskell core — 0 lines changed.
- [ ] `outer_cards.py` core logic (aggregate_display_windows, build_outer_card) — не меняется, только `OUTER_CARD_ALLOWLIST` config extension.
- [ ] Phase 4b Натальи structured overrides — не меняются.

## Context

**Mode normal + Tier C** (validation + calibration phase). Worker subagent. Reviewer subagent необязателен.

**Baseline:** main @ `a1891cc` (Phase 6 closed). Tests `149 passed + 0 xfailed + 0 failed`.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 5 Phase 7 (formal definition).
- § 7 запрет 7 («Не показывать Марине до closing Phase 7 + явного ack пользователя»).
- § 8 TASK 7 — formal spec (зеркальная).

**Worker scope discipline — это финальная phase, не новая implementation:**
- Calibration работа = validation + closed-config-extension. Не новая core logic.
- Если Worker обнаружит что Phase 1-6 implementation требует change для multi-case support — это сигнал regression / scope miss, STOP, escalation memo.
- TYPE-B regressions → отдельный TASK после Phase 7. Phase 7 не fixит regressions; identifies them.

**Production-readiness gate:** после Phase 7 closing + production-readiness verdict "Ready for Marina show" + **явного ack пользователя** — программа полностью closed, PDF можно показывать Марине. До этого PDF — внутренний debug/QA артефакт.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 7 spec.
