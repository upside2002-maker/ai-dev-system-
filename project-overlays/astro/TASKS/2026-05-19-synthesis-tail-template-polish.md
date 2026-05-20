# TASK: synthesis-tail-template-polish

- Status: open
- Ready: no
- Date: 2026-05-19
- Project: astro
- Layer: services (Python presentation: `synthesis_themes.py` Layer 3 phrase helpers — style polish only)
- Risk tier: C (style polish on existing 3-layer architecture; no architectural change; no evidence/scoring touch; no new tests of behavior, only of style)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Previous TASK `human-readable-consultation-summary` (closed 2026-05-19, product `7644d7f`) landed 3-layer evidence-driven architecture. **Lead-ins / opener / closer звучат как consultation prose** (TL + external Reviewer APPROVE). **Но astrology-tail helpers повторяются как штампы через блоки** — typical engine-dump style возвращается в tail-фрагментах.

**Concrete patterns** обнаружены user visual review 2026-05-19 на Olga consultation 12:

1. **Tail-template repeat #1** (повторяется **6 раз**: ФИНАНСЫ + ДОКУМЕНТЫ + НЕДВИЖИМОСТЬ + ЗАГРАНИЦА + СТАТУС-вариант + ПЛАНЫ):

   > «По этой теме одновременно идут несколько транзитов высших и социальных планет (включая X) — тема прорабатывается медленно и глубоко.»

2. **Tail-template repeat #2** (3 раза: РАБОТА + ПАРТНЁРСТВО + СТАТУС):

   > «Сразу несколько дирекций (N конфигураций) держат тему в фокусе — это устойчивый акцент.»

3. **Tail-template repeat #3** (2 раза: ЛЮБОВЬ + ПЛАНЫ):

   > «соляр выстраивается вокруг оси 5-11.»

4. **Cross-block duplicates:**
   - «Год партнёрства и договорённостей» — Выводы + ЛИЧНОСТЬ (last not logically connected к personality block).
   - «Цель — обретение почвы под ногами, дом, семья» — Выводы + СТАТУС (twice).

5. **Concrete canclerite phrases** (engine-dump style, не consultation style):
   - `тема прорабатывается медленно и глубоко` (passive + штамп) × 6.
   - `устойчивый акцент` (бюрократизм) × 3.
   - `длинный транзит Уран` (жаргон, не для клиента) × 1.
   - `звучит выраженно` × 1.
   - `живые жизненные процессы` (тавтология / абстракция) × 1.
   - `обретение почвы под ногами` (формальный оборот).

6. **Logical disconnect**: Asc Libra phrase «Год партнёрства и договорённостей» вставляется в ЛИЧНОСТЬ block без logical связи с personality content.

**Programme classification:** style polish TASK, no architecture change. **Lead-ins / opener / closer NOT touched** (work correctly). **Layer 3 phrase-tail helpers only.**

## Worker framing (verbatim user direction 2026-05-19)

> «Это уже следующий правильный слой: не архитектура и не факты, а редакторская полировка хвостов.»

> «Scope: Только `synthesis_themes.py`, Layer 3 phrase helpers. Не трогать scoring, evidence extraction, opener, themed headings, closer. Не менять engine, fixtures, template, API.»

> «Цель: Убрать канцелярит из хвостов. Снизить повторяемость. Не превращать текст в универсальную "красивую воду". Сохранить evidence-driven связь с фактами.»

> «Implementation hint: Сделать небольшой набор живых вариантов для: outer transits tail; directions tail; axis tail; angle/Asc/MC tail. Выбирать вариант по теме, а не случайно. Например для финансов одно, для семьи другое, для планов третье. Фразы должны быть короткими. Лучше меньше текста, но точнее.»

## Scope (Tier C style polish)

### Stage 1 — Tail helper inventory

Identify Layer 3 phrase-helper functions в `services/api-python/app/pdf/synthesis_themes.py` that produce tail-fragments:

- `_phrase_transits(...)` — outer transit tail.
- `_phrase_directions(...)` — directions tail.
- `_phrase_axis_touch(...)` — axis-touch tail.
- `_phrase_angle(...)` — Asc / MC tail.
- `_phrase_personality_partner(...)` / `_phrase_status_partner(...)` — partner-house tails (audit for canclerite).
- `_phrase_solar_row(...)` / `_phrase_prog_moon(...)` — additional context tails.

Worker maps which helper produces which observed canclerite phrase.

### Stage 2 — Canclerite removal (verbatim user-listed)

Hard removal targets — phrases MUST NOT appear in rendered output for any case:

- `тема прорабатывается медленно и глубоко`
- `устойчивый акцент`
- `длинный транзит Уран`
- `звучит выраженно`
- `живые жизненные процессы`
- `обретение почвы под ногами` (replace с «найти опору» / «опереться на дом и семью» / similar living phrasings)

### Stage 3 — Variant pools (per implementation hint)

Worker creates **small living variant pools** для каждого tail type:

- **Outer transits tail**: ≥4 distinct phrasings, each evoking medium-term inevitability differently (e.g. «эта тема в этом году тянется долго», «по этой теме год просит терпения», «эта тема не уходит фоном целый год», «эта тема разворачивается не быстро, а слоями»).
- **Directions tail**: ≥4 distinct phrasings (e.g. «дирекции держат тему в фокусе» → «эта тема не отпускает», «несколько конфигураций в дирекциях возвращают к ней», «дирекции год за годом возвращают на этот круг»).
- **Axis tail**: ≥3 distinct phrasings (drop «соляр выстраивается вокруг оси X-Y» monolith — vary phrasings per theme: для дома-семьи одно, для творчества другое).
- **Angle (Asc/MC) tail**: ≥3 distinct phrasings — drop «Год партнёрства и договорённостей» repeat; phrase appears once (in Выводы) unless block content naturally connects.

### Stage 4 — Variant selection algorithm (per user clarification — see § Ready)

User direction: «по теме, а не случайно». Worker implements deterministic theme-aware selection. Options for clarification:
- (a) Per-theme assignment (each themed block has preferred variant per tail type).
- (b) Per-(theme, evidence-shape) selection (e.g. outer-transit tail varies by which planet — Pluto-led financial gets one phrasing, Neptune-led creative gets another).
- (c) Worker proposes selection algorithm.

### Stage 5 — Cross-block dedup (per user direction)

User direction: «Цель — найти опору / дом / семья звучит максимум в opener/status/closing, не размазывается по нескольким блокам». Implementation per § Ready clarification:
- (a) Global state tracker — phrase emitted once, blocked for subsequent blocks.
- (b) Per-block whitelist — «Цель» (MC-Cancer phrase) allowed only в opener / СТАТУС / closer; «Год партнёрства» (Asc-Libra phrase) allowed only в opener / ПАРТНЁРСТВО / closer.
- (c) Worker proposes mechanism.

### Stage 6 — Logical-connectivity gate для angle phrases

User direction: «Asc Libra / партнёрство не вставляется в блок `ЛИЧНОСТЬ`, если там нет логической связки.» Implementation per § Ready clarification:
- (a) Hard restriction: Asc/MC angle phrases emit only в blocks where their content overlaps (Asc Libra ∈ {opener / ПАРТНЁРСТВО / closer}; MC Cancer ∈ {opener / СТАТУС / НЕДВИЖИМОСТЬ-СЕМЬЯ / closer}).
- (b) Theme-overlap gate: emit angle phrase if its sphere keyword overlaps with block's theme keyword set (more nuanced, requires keyword classification).
- (c) Worker proposes.

### Stage 7 — Acceptance verification

For Olga consultation 12 fresh render:
- All hard-removal target phrases absent.
- Tail-templates не повторяются ≥3 раза identical.
- Asc Libra «Год партнёрства» не в ЛИЧНОСТЬ.
- MC Cancer «Цель —» appears max once в opener + max once в СТАТУС/closer.
- Reads as consultation, не engine dump.
- PDF text-extract diff (pre-polish vs post-polish) shows reduced repetition + canclerite absence.

For calibrated 6 cases (02/03/05/07/08/10):
- No regressions: блоки рендерятся, evidence cited correctly.
- Same canclerite removal applies universally.
- Tail variety improves PDF quality для всех cases.

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` (Layer 3 tail helpers only — phrase pools + selection algorithm + cross-block dedup + angle-gate).
  - `services/api-python/tests/test_consultation_summary_evidence.py` (extend per § Ready clarification 6 — new canclerite-absence + tail-variety tests).
  - `project-overlays/astro/STATUS_RU.md`.

- new: —

- delete: —

## Do not touch

- **Layer 1** `_collect_theme_evidence`.
- **Layer 2** `_score_themes` + scoring numerics (predecessor TASK established).
- **Opener** `_compose_opener_paragraphs`.
- **Themed block lead-ins** `_THEME_DEEP_PHRASES` (case-specific, already work).
- **Closer** `_compose_closing_paragraphs`.
- **Section structure** (12 sections established).
- `solar.html.j2` template.
- `builder.py`.
- Engine: Haskell core, schema, fixtures.
- Phase 4/7/8 calibrated data (`OUTER_CARD_ALLOWLIST`, `_OUTER_CARD_FACTS`, `MARINA_OUTER_CARD_BOUNDARIES`).
- Phase 9.2B / 9.3A artifacts.
- Phase 9.4 / Phase 4b acceptance tests.
- `_legacy_compose_theme_prose` (orphan, do not touch — separate follow-up).
- **DO NOT add LLM / GPT.**
- **DO NOT change evidence-driven semantics** — every tail phrase must still trace к concrete facts evidence.
- **DO NOT make text «универсальной красивой водой»** — short, precise, case-anchored phrasings only.
- **DO NOT introduce new evidence collection или scoring channels.**

## Acceptance

### Primary (Olga consultation 12)

- [ ] PDF Olga renders без single canclerite phrase из list:
  - `тема прорабатывается медленно и глубоко`
  - `устойчивый акцент`
  - `длинный транзит Уран`
  - `звучит выраженно`
  - `живые жизненные процессы`
  - `обретение почвы под ногами`
- [ ] No tail-template repeated ≥3 times identical в same PDF.
- [ ] Asc Libra phrase «Год партнёрства и договорённостей» НЕ в ЛИЧНОСТЬ block (logical-connectivity gate per Stage 6).
- [ ] MC Cancer phrase «Цель —» appears max once в opener AND max once в СТАТУС/closer (cross-block dedup per Stage 5).
- [ ] Human-read smoke passes (preserved from predecessor TASK).
- [ ] Section structure (12 sections) preserved.
- [ ] Strict-negatives preserved (no «1-12» / «наедине с собой» / etc.).

### Calibrated regression

- [ ] All 6 calibrated cases (02 / 03 / 05 / 07 / 08-Natalya / 10) render без errors.
- [ ] No client's hardcoded phrasings leak.
- [ ] Hard-removal target phrases absent universally.
- [ ] Tail variety applies к всем cases (Worker shows diff per case в HANDOFF).

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `412 + N` (N = new style tests). **0 failed AND 0 xfailed.**
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (tail polish + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 7.

### Discipline

- [ ] NO architecture / scoring / evidence-extraction touch.
- [ ] NO opener / closer / themed lead-in touch.
- [ ] NO LLM.
- [ ] Tail variety preserves evidence-citation (each tail still traces к specific facts channel).
- [ ] Variant selection deterministic (not random).
- [ ] Short tail phrases preferred over long elaborate ones (user: «лучше меньше текста, но точнее»).

## STOP triggers

- Worker tempted to refactor Layer 1 или Layer 2 → STOP, Tier C scope is Layer 3 tails only.
- Worker tempted to add LLM → STOP, deterministic templates only.
- Worker tempted to write generic «red-water» phrases applicable к any client → STOP, anchor each variant к specific evidence-shape.
- Worker finds calibrated case regression (lost meaningful content) → STOP, escalate.
- Worker tempted to introduce randomness в variant selection → STOP, must be deterministic.
- Tail polish breaks predecessor's case-specificity test → STOP, refine (case-specific lead-ins MUST remain case-specific; tails MUST add variety без removing specificity).
- Worker tempted to touch `_legacy_compose_theme_prose` (orphan) → STOP, separate follow-up scope.

## Reviewer subagent — per § Ready clarification 7

Tier C style polish. Per recent precedent:
- Phase 9.2A / 9.3A (Tier C validation): Reviewer optional + TL inline-verify.
- Predecessor `human-readable-consultation-summary` (Tier B+): Reviewer REQUIRED.

This TASK Tier C — Reviewer disposition per § Ready.

## Context

**Mode normal + Tier C.** Worker mode: normal.

**Baseline:**
- Product main @ `7644d7f` (predecessor `human-readable-consultation-summary` closed).
- Overlay master @ `c51e606` (predecessor closure).
- Pytest baseline: `412 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Predecessor TASK: `project-overlays/astro/TASKS/archive/2026-05-19-human-readable-consultation-summary.md` + HANDOFF.
- Reviewer report (predecessor APPROVE): inline в Worker HANDOFF + TL closure commit `c51e606`.
- Buggy phrase locations: `services/api-python/app/pdf/synthesis_themes.py` Layer 3 phrase helpers (lines vary per Worker inventory Stage 1).
- Existing acceptance tests (preserve / extend): `services/api-python/tests/test_consultation_summary_evidence.py` (30 tests).
- Olga DB consultations: rows 10/11/12; consultation 12 = primary acceptance target.
- Marina-Olga reference PDF: `/Users/ilya/Downloads/Соляр 2026-2027.pdf` (style anchor).

**Not in scope (explicit):**
- Layer 1 / Layer 2 architecture (predecessor TASK).
- Opener / themed lead-ins / closer (work correctly).
- New evidence channels / new scoring.
- LLM / GPT integration.
- `_legacy_compose_theme_prose` cleanup (separate follow-up).
- Calibrated cases beyond regression check.

**Ready: no** — pending 4 clarifications below.

## Ready clarifications (pending user direction 2026-05-19)

1. **Variant selection algorithm (Stage 4).**
   - (a) Per-theme assignment — each themed block has 1 preferred variant per tail type, deterministic mapping.
   - (b) Per-(theme, evidence-shape) — variant depends on which planet/aspect drives the evidence (Pluto-led financial → one phrasing; Neptune-led creative → another).
   - (c) Worker proposes algorithm в HANDOFF.

2. **Cross-block dedup mechanism (Stage 5).**
   - (a) Global state tracker — emit phrase first time, block subsequent (stateful).
   - (b) Per-block whitelist — explicit mapping which phrase allowed in which blocks (declarative).
   - (c) Worker proposes.

3. **Logical-connectivity gate для angle phrases (Stage 6).**
   - (a) Hard restriction — Asc/MC phrases emit only в pre-defined blocks (Asc Libra ∈ {opener / ПАРТНЁРСТВО / closer}; MC Cancer ∈ {opener / СТАТУС / НЕДВИЖИМОСТЬ-СЕМЬЯ / closer}).
   - (b) Theme-overlap keyword gate — emit if angle's sphere keyword overlaps with block's theme keyword set.
   - (c) Worker proposes.

4. **Reviewer subagent.**
   - (a) Optional + TL inline-verify (consistent с 9.2A / 9.3A Tier C precedent).
   - (b) REQUIRED external Reviewer (Tier C polish but visible end-user impact).
