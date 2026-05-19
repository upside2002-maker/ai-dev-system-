# TASK: evidence-based-consultation-summary-rewrite

- Status: open
- Ready: no
- Date: 2026-05-19
- Project: astro
- Layer: services (Python presentation: `synthesis_themes.py` + tests for Olga summary)
- Risk tier: B (1 file substantive rewrite + new acceptance tests; no schema; no fixtures; no engine)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Manual verify Olga `solar-12.pdf` vs Marina reference `Соляр 2026-2027.pdf` (user, 2026-05-19) выявил, что секция «Итоги консультации» **describes a different person, not Olga**. Root cause — concrete code bug в `services/api-python/app/pdf/synthesis_themes.py`:

1. **Line 103-104 comment:** «added 2026-05-08 (Phase 0.10c-c, synthesis-rewrite-toward-reference). Marina's reference reports open the «Итоги» themed list with this block: it covers self / identity / closure / transition / isolation / relocation — combinations like 1-12, завершение этапа, переход в новый цикл, подведение итогов, эмиграция / удалённая занятость / «вне общества».»
2. **Line 114-115:** `"ЛИЧНОСТЬ": { "houses": {1, 12}, ... }` — hardcoded mapping personality theme to houses 1+12 specifically.
3. **Line 367-373:** `_THEME_PROSE["ЛИЧНОСТЬ"].lead_in = «Год, в который вы будете больше обычного находиться наедине с собой и подводить итоги внутреннего цикла (1-12).»` — hardcoded Natalya-specific phrasing tied to 1-12 axis.

**For Natalya (Phase 0.10c-c reference Соляр 2025-2026):** this template was correct because у неё primary axis 1→12 — phrase «наедине с собой, подведение итогов внутреннего цикла» matched her chart evidence.

**For Olga (Соляр 2026-2027):** the same template is **factually incorrect**. Her primary axis is `1 → 5` (per Phase 9.4 verdict + Marina's actual reference). Olga's 1-house links к 5-house (creativity, kids, hobbies, self-expression), не 12-house (isolation, internal cycle close). Template's hardcoded «наедине с собой, подведение итогов внутреннего цикла» is ложь для её charts.

Same defect pattern likely affects other 9 themed blocks (`ФИНАНСЫ`, `ОТНОШЕНИЯ`, etc.) — they may carry Natalya-specific phrasings as defaults that don't generalize.

**Programme classification:** This is NOT Phase 9.x memo verdict question. Это code bug — copy-pasted reference template surviving as defaults for non-calibrated cases.

## Worker framing (verbatim user direction 2026-05-19)

> «Цель: переписать `Итоги консультации`, чтобы они собирались из текущих данных, а не из старого шаблона. Scope: `synthesis_themes.py` + tests for Olga summary; no engine changes; no outer-card/window changes.»

> «Что сделать: (1) Убрать case-specific hardcode `ЛИЧНОСТЬ = 1-12`. (2) Собирать итог из evidence: солярная сетка `солярный дом → натальный дом`, Asc / MC соляра, primary / secondary axis, прогрессивная Луна, активные дирекции / формулы, транзиты по домам, selected outer-card themes. (3) Для каждого раздела итогов брать только подтверждённые темы. (4) Текст строить deterministic templates, без LLM и без копирования натальиного блока.»

> «Финальный текст не должен тянуть формулировки из Натальи, если evidence Ольги их не подтверждает.»

## Scope (Tier B implementation + tests)

### Stage 1 — Evidence-source inventory

Per facts shape used by `synthesis_themes.py`:
- `facts["solar_chart"]["asc_sign"]`, `mc_sign` — angle signs.
- `facts["solar_chart"]["positions"]` — planet positions с solar / natal house mapping.
- `facts["analysis"]["house_axis"]["primary_axis"]`, `secondary_axis` — engine top-density.
- `facts["analysis"]["solar_to_natal_house_table"]` (если exists) — solar-house → natal-house mapping.
- `facts["progressed_chart"]["moon_house"]` — progressed Moon house.
- `facts["annual_transit_table"]` — transit aspect calendar.
- `facts["active_directions"]` — direction list (per TASK 2026-05-16 «show all active»).
- `facts["outer_cards"]` (or computed via `outer_cards_for_case` / `generic_outer_cards`) — selected outer-card themes.

Worker maps which evidence sources drive which themed block.

### Stage 2 — Remove case-specific hardcode

**2.1 — `ЛИЧНОСТЬ` block:** drop hardcoded `houses = {1, 12}` literal. Replace with dynamic derivation from `primary_axis` AND/OR `solar_to_natal_house_table` looking up solar 1st-house target.

**2.2 — `_THEME_PROSE["ЛИЧНОСТЬ"].lead_in`:** drop hardcoded «наедине с собой, подведение итогов внутреннего цикла (1-12)». Replace with conditional template — assembled from evidence per case.

**2.3 — Other 9 themed blocks:** audit for analogous Natalya-only phrasings. Worker decision per § Ready clarification: incremental fix (ЛИЧНОСТЬ only) OR full sweep all 10 blocks.

### Stage 3 — Evidence-driven template architecture

Worker proposes architecture; this is implementation choice. Sketch options:

- **(α) Conditional template builder:** for each block, collect evidence (axes touched, directions firing, transits, outer cards relevant). Template renders only confirmed-by-evidence phrasings.
- **(β) Per-house topical lookup:** for each natal house 1-12, store catalog of «when solar/natal/aspect activates this house» phrasings. Synthesis picks phrasings from the catalog based on what's active.
- **(γ) Hybrid:** keep current `LIFE_THEMES` houses+keywords structure, но drive narrative text from evidence presence (e.g., «если progressed Moon ∈ block.houses → mention it»).

Architecture choice per § Ready clarification 2.

### Stage 4 — Acceptance tests

New file `services/api-python/tests/test_consultation_summary_evidence.py` OR extend existing `test_summary_themes.py` (Worker discretion per § Ready clarification 3).

**Olga consultation 11 acceptance (per user verbatim 2026-05-19):**

Negative assertions (text MUST NOT contain):
- `"1-12"` (as axis label или in phrasing context).
- `"наедине с собой"`.
- `"подводить итоги внутреннего цикла"`.
- `"завершение этапа"` (Natalya-specific).
- `"переход в новый цикл"` (Natalya-specific).

Positive assertions (text MUST contain semantically equivalent — see clarification 5 for strict-string vs semantic):
- **ЛИЧНОСТЬ block:** reference to `1 → 5` link («ребёнок / творчество / хобби / самовыражение»).
- **Выводы / final synthesis:** Asc в Весах (партнёрство / договорённости), MC в Раке (дом / семья / почва под ногами), ось `5-11` (дети, хобби, планы, коллектив), прогрессивная Луна в 11 доме.

**Calibrated case regression (per § Ready clarification 4):**
- Either: existing Natalya / 05 / 07 / 10 PDFs maintain current synthesis text bit-identical OR sensible-divergence-allowed.

### Stage 5 — Documentation

Inline comments updating Phase 0.10c-c lineage note (line 103-104) to reflect evidence-based architecture instead of «added as in reference».

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` (substantive rewrite — scope per clarification 1).
  - `project-overlays/astro/STATUS_RU.md`.

- new (likely):
  - `services/api-python/tests/test_consultation_summary_evidence.py` (Olga + maybe other cases acceptance — per clarification 3).

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures.
- `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` / `MARINA_OUTER_CARD_BOUNDARIES` — Phase 4/7/8 calibrated data.
- `generic_outer_cards()` / `ANGLE_TARGETS` — Phase 9.2B closure.
- `solar.html.j2` template — no changes (synthesis text rendered via Jinja from `synthesis_themes` returns).
- `builder.py` — likely no changes (consumer of `themed_synthesis` / `summary_table`; verify Worker).
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`) — transit-section only, untouched.
- Phase 9.4 `test_summary_themes.py` primary_axis pins — NOT modified.
- Phase 9.0 memo — unaffected (this is не Phase 9 work).
- 12 future-work items audit § A.2.1.D.
- **DO NOT touch engine output / facts_json structure.** Worker uses existing facts evidence; не requests new facts fields from engine.
- **DO NOT add LLM / GPT call.** Deterministic templates only per user direction.
- **DO NOT copy Marina's narrative from other clients' PDFs as defaults** — evidence-driven only.

## Acceptance

### Primary (Olga consultation 11)

- [ ] Olga PDF «Итоги консультации» section НЕ contains: `"1-12"`, `"наедине с собой"`, `"подводить итоги внутреннего цикла"`, `"завершение этапа"`, `"переход в новый цикл"`.
- [ ] Olga PDF «Итоги консультации» ЛИЧНОСТЬ block references `1 → 5` axis (creativity / kids / hobbies / self-expression keywords).
- [ ] Olga PDF «Итоги консультации» Выводы block references: Asc в Весах (партнёрство), MC в Раке (дом / семья), primary axis `5-11` (дети / хобби / коллектив), progressed Moon в 11 доме.
- [ ] Acceptance tests в `test_consultation_summary_evidence.py` cover both negative и positive assertions для Olga.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: pytest passes `>= 382 + N` где N — count новых acceptance tests; **0 failed AND 0 xfailed**.
- [ ] Calibrated cases (per clarification 4) — either bit-identical OR sensible-divergence-documented.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (synthesis rewrite + new tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.

### Discipline

- [ ] NO LLM calls, NO GPT API, NO LangChain — deterministic templates only.
- [ ] NO Marina-narrative copying from other-client PDFs as defaults.
- [ ] NO engine modifications.
- [ ] NO schema modifications.
- [ ] Evidence sources used ⊆ existing facts.
- [ ] Worker decides scope per § Ready clarifications 1-2.

## STOP triggers

- Worker tempted to add LLM call → STOP, deterministic templates only.
- Worker tempted to modify engine output для new facts field → STOP, use existing evidence.
- Worker tempted to keep ЛИЧНОСТЬ `houses = {1, 12}` as default fallback → STOP, this IS the bug being fixed.
- Worker tempted to copy Marina-narrative from другого case PDF as «better default» → STOP, evidence-driven only.
- Worker finds calibrated case (Natalya / 05 / 07 / 10) PDF text changes substantively → STOP, escalate; decide bit-identical vs sensible-divergence per clarification 4.
- Worker finds existing Phase 9.4 test breaks → STOP, investigate (Phase 9.4 pins primary_axis only, не narrative text, so should NOT break — if it does, regression).

## Reviewer subagent — per § Ready clarification 6

Tier B normally Reviewer-required (substantive rewrite + tests). Per recent precedent (9.2B): user may opt Reviewer optional + TL inline-verify.

## Context

**Mode normal + Tier B (Reviewer disposition per § Ready).** Worker mode: normal.

**Baseline:**
- Product main @ `7751d46` (Phase 9.2B angle-filter landed; Phase 9.3A validation-only).
- Overlay master @ `99adf67` (Phase 9.3A closure).
- Pytest baseline: `382 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Buggy code locations: `services/api-python/app/pdf/synthesis_themes.py:103-122` (`LIFE_THEMES["ЛИЧНОСТЬ"]`) + `:367-378` (`_THEME_PROSE["ЛИЧНОСТЬ"]`).
- Phase 0.10c-c lineage (Natalya reference): mentioned в line 103-104 comment.
- Phase 9.4 summary axis tests (read-only baseline): `services/api-python/tests/test_summary_themes.py`.
- Phase 9.3A closure (PARTIAL verdict): `project-overlays/astro/ARCHITECTURE/phase-9-3-a-outer-card-horizon-window-validation-2026-05-19.md`.
- Marina-Olga reference PDF: `/Users/ilya/Downloads/Соляр 2026-2027.pdf`.
- Olga DB consultations: `/Users/ilya/Projects/astro/data/astro.db` rows id=10 + id=11.

**Not in scope (explicit):**
- Phase 9.x sub-problems (all 4 already closed).
- Outer-card filter / window / horizon — Phase 9.2B + 9.3A territories.
- Engine output / schema modifications.
- LLM / GPT integration.
- Marina-style synthesis emulation (deterministic templates only).
- Other client PDFs regeneration (unless calibrated regression detected per clarification 4).

**Ready: no** — pending 6 clarifications below.

## Ready clarifications (pending user direction 2026-05-19)

1. **Scope of rewrite — incremental vs full sweep:**
   - (a) Incremental: fix `ЛИЧНОСТЬ` block only (smallest change to address Olga's immediate factual error); other 9 blocks unchanged.
   - (b) Full sweep: audit all 10 themed blocks для Natalya-specific phrasings; refactor all to evidence-driven.

2. **Architecture choice:**
   - (α) Conditional template builder (collect evidence per block, render only confirmed phrasings).
   - (β) Per-house topical lookup catalog (catalog phrasings per house; synthesis picks based on active evidence).
   - (γ) Hybrid (keep current `LIFE_THEMES` houses structure, drive narrative from evidence presence).
   - (δ) Worker proposes alternative architecture в HANDOFF before implementing.

3. **Test file location:**
   - (a) New file `test_consultation_summary_evidence.py`.
   - (b) Extend existing `test_summary_themes.py` (Phase 9.4 file).
   - (c) Worker discretion.

4. **Calibrated case regression policy:**
   - (a) Strict bit-identical — Natalya / 05 / 07 / 10 PDFs must produce identical synthesis text pre/post rewrite (high constraint; may block clean refactor).
   - (b) Sensible-divergence-allowed — calibrated cases may produce different synthesis text IF evidence supports; Worker documents diff in HANDOFF.
   - (c) Per-case override via Phase 4b structured-overrides pattern (analogous to `STRUCTURED_OVERRIDES` for transit section).

5. **Acceptance assertion strictness:**
   - (a) Strict-string: tests pin exact phrases (e.g. `"5-11"` substring).
   - (b) Semantic: tests check evidence-presence via structural assertions (e.g. ЛИЧНОСТЬ block references house 5; final synthesis mentions Asc sign).
   - (c) Hybrid: negative assertions strict-string (no Natalya phrasings); positive assertions semantic.

6. **Reviewer subagent:**
   - (a) Optional like 9.2B — TL inline-verify.
   - (b) Required Tier B external Reviewer.
