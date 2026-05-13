# TASK: multi-case-calibration

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

Phase 7 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 7, § 8 TASK 7). **Финальная phase программы.** Цель — доказать что Phase 1-6 работают не только для одной Натальи, но и для других golden cases.

Phase 1-6 работа была откалибрована на case 08 (Наталья). Phase 7 — verification что новый transit-section presentation:
- Корректно рендерится для других cases без regression;
- Соответствует Marina эталонам где они доступны;
- Не подгонка под Наталью (universal logic — Phase 5 rulership, Phase 6 clipping, Phase 4 outer cards allowlist per case_id).

После closing Phase 7 — программа Transit Section Recovery **полностью завершена**. PDF status можно повысить до production-ready (Марине можно показывать) только после **явного ack пользователя** по всему набору calibration cases.

## Marina reference inventory

В `/Users/ilya/Downloads/Gmail (3)/` присутствуют Marina solar PDFs:

```
Соляр 2024-2025.pdf
Соляр 2025-2026 для Анастасии.pdf       ← case 09 (Анастасия) match by filename
Соляр 2025-2026 для Данилы.pdf           ← case 10 (Данила) match by filename
Соляр 2025-2026.pdf                      ← case unknown, requires natal-data inspection
Соляр 2025-2026_1.pdf                    ← case unknown
Соляр 2025-2026_2.pdf                    ← case unknown
Соляр 2025-2026_3.pdf                    ← case unknown
Соляр 2025-2026_4.pdf                    ← case unknown
Соляр 2025-2026_5.pdf                    ← case 08 (Наталья) — Phase 1-6 oracle
Солярный гороскоп 2025-2026.pdf          ← case unknown
```

**Phase 0:** Worker identifies which `_N.pdf` maps to which golden case by natal-data inspection (birth date / place / Asc / MC из first page each). Output → identification table в HANDOFF.

## Calibration case selection

Architecture default: **05-ekaterina, 07-mariya, 10-danila** (per Phase 7 § 5 + § 8 TASK 7).

**Worker может выбрать иные 3 cases** из `{01, 02, 03, 04, 05, 07, 09, 10}` с обоснованием в HANDOFF — например, если Marina PDF для одного из default cases не найдена в inventory, а для другого case — есть. Случай 09 (Анастасия) имеет confirmed Marina PDF — может стать кандидатом если 07-mariya не identified.

**Final selection rule:** ≥ 3 cases с подтверждённым Marina PDF. Если в inventory только 2 cases с Marina PDF — Worker calibrates на тех 2 + flag к TL для extension scope или partial Phase 7.

## Per-case calibration scope

Для каждого выбранного case Worker:

1. Сгенерить PDF через canonical render: `python scripts/render_natalya.py --output /tmp/<case_id>-phase7.pdf --case-id <case_id>` (или эквивалент — если canonical render hardcoded к Наталье, Worker создаёт `services/api-python/scripts/render_case.py` parameterised по case_id).
2. Извлечь Marina reference dates через pypdf или manual visual.
3. Сравнить per-section:
   - **Monthly transit table** (`Транзиты планет по домам`): cell-by-cell match Marina table.
   - **Per-house interpretations**: planets / houses listed matches Marina; no out-of-year dates (2024/2027/2028 если соляр 2025-2026).
   - **Outer-planet cards** (Phase 4): если case имеет outer cards у Marina — extend allowlist в `outer_cards.py:OUTER_CARD_ALLOWLIST` с card-facts per case (визуально считанные с Marina таблиц «Золотое правило транзита»).
   - **Calendar (`КАЛЕНДАРЬ транзитных аспектов`)**: rows match Marina list; `Дома цели` use rulership-expanded sets (Phase 5).
4. Document divergences per section в **calibration report**.

## Divergence handling

Per case Worker classifies каждую divergence:

- **TYPE-A (acceptable / known)** — known editorial divergence (Phase 4b pattern: Marina boundary differs from engine за пределами ±2d). Add `tolerance_overrides` per outer-card-window если в acceptance test для этого case есть, иначе document только в report.
- **TYPE-B (regression)** — Phase 1-6 logic produces wrong output. Bug in our helper или config; **STOP**, document в HANDOFF, escalate к TL для отдельного TASK на fix.
- **TYPE-C (Marina-specific editorial)** — Marina manually adjusted boundary / dropped/added row для этого case. Document как case-specific note; не требует code change.

## Phase 4b gate clause check (override accumulation)

Per architecture document § 7 запрет 7 / TASK 4b spec:

> «Если TASK 7 multi-case calibration покажет накопление similar Neptune (или другие slow-mover) overrides (>5 за case или >10 across all cases) — это сигнал что Path 4 структура не масштабируется и нужно пересмотреть продуктовый подход».

Worker считает total tolerance overrides applied across calibration cases. Если threshold exceeded — **STOP**, escalation memo к TL.

## Files

- new:
  - **`services/api-python/scripts/render_case.py`** (или эквивалентное расширение `render_natalya.py`) — parameterised render по `--case-id`. Reuse `provenance.py` (Phase 1).
  - **`services/api-python/tests/test_<case_id>_transits_acceptance.py`** per calibration case (3 файла, если выбраны 3 cases). Each file — copy of `test_natalya_transits_acceptance.py` structure adapted to case-specific Marina reference. Includes Phase 4b structured exceptions per case if needed.
  - **`project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`** — calibration report markdown:
    - § 1 Marina inventory mapping (file → case_id).
    - § 2 Selected cases + rationale.
    - § 3 Per-case section diff (monthly table / per-house / outer cards / calendar).
    - § 4 Divergence classification (TYPE A/B/C per case per row).
    - § 5 Total override count + Phase 4b gate clause check.
    - § 6 Production-readiness verdict: «Ready for Marina show» / «Blockers identified» / «Partial pass».
- modify:
  - **`services/api-python/app/pdf/outer_cards.py:OUTER_CARD_ALLOWLIST`** — extend with allowlist entries per calibration case (если Marina shows outer cards для них). Closed card-facts (transit_h / target_h / ruled / walks) per case считываются визуально с Marina pp. golden-rule tables. **НЕ generic deduction** — closed facts per case.
  - **`services/api-python/app/pdf/transit_themes.py`** (минимально если требуется) — wiring updates для multi-case (e.g. дефолтное значение case_id берётся из `provenance.extra.case_label`).
  - (Optionally) `services/api-python/tests/test_natalya_transits_acceptance.py` — refactor common helpers (`_assert_three_phase_intervals`, etc.) в shared module если нужно избежать code duplication across test files.

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

- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green. Phase 4/5/6 Натальи xfailed count = 0 (preserved baseline 149 passed); добавлены **N_new** tests per calibration case (3+ files × ~20-30 tests each). Final: **≥ 200 passed + 0 xfailed + 0 failed** (rough estimate; actual N зависит от Worker'овского test coverage per case).
- [ ] **Pre-existing Натальи tests НЕ regression** — все 149 продолжают passing.

### Phase 6 — Production-readiness verdict

- [ ] Calibration report § 6 содержит **explicit verdict**:
  - **«Ready for Marina show»** — все cases pass per acceptance assertions; нет TYPE-B regressions; override count в пределах threshold.
  - **«Blockers identified»** — найдены TYPE-B regressions; список + recommended fix tasks.
  - **«Partial pass»** — некоторые sections pass, другие требуют follow-up; per-case status.

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
