# TASK: transit-section-generic-output

- Status: done
- Ready: yes
- Date: 2026-05-16
- Project: astro
- Layer: services (Python presentation: transit_themes + outer_cards + template) + tests
- Risk tier: C (presentation logic shift + new generic path for non-calibrated cases); **Reviewer subagent REQUIRED** per user direction 2026-05-16
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Two independent gaps в Transit Section для non-calibrated horoscope (e.g. Ольга consultation 10, `case_label=None`), discovered 2026-05-16:

### Gap 1 — Bottom house interpretations diverge from monthly table

В PDF `/Users/ilya/Downloads/solar-10.pdf`:
- Table «Транзиты планет по домам» (`transit_matrix_by_month`) shows для Венеры houses: `4, 5, 5, 5, 5, 5, 6, 7, 9, 10, 11, 12, 1` (not 8).
- Bottom interpretation block lists «Венера в 8 доме» — house 8 в table отсутствует.
- Аналогично «Марс в 1 доме» появляется, но в table Mars never reaches 1.

Root cause: template uses **two different functions** with different semantics:
- Table: `transit_matrix_by_month(facts.annual_transit_table, sr_jd)` (line 544) — mid-15 snapshot per calendar month.
- Bottom interpretations: `houses_visited(facts.annual_transit_table, p_key, horizon=solar_year)` (line 591) — houses where planet was at any point in solar year (включая short transits).

Это два разных contract'а. Bottom interpretation surfaces houses planet briefly visited; table shows only mid-15 snapshots. Marina'in эталон bottom interpretations matches table snapshots, not extended «visited» list.

### Gap 2 — Outer-planet cards absent for non-calibrated case

Для Ольги (`case_label=None`) секция «Транзиты высших планет» полностью **отсутствует** в PDF, хотя engine'ом рассчитаны Uranus/Neptune/Pluto transits.

Root cause: `app/pdf/outer_cards.py:outer_cards_for_case(case_id, ...)` returns empty list when `case_id not in OUTER_CARD_ALLOWLIST`. Для откалиброванных кейсов (05/08/10 Marina-reference subset + 01/02/03/04/09 Phase 8D extension) allowlist + facts populated; для новых case_id'ов — no allowlist entry → no cards rendered.

Per Phase 4 design decision (Path 3 chosen 2026-05-13): allowlist + manually-curated card-facts с Marina reference visually transcribed. Это работает для известных кейсов; для новых клиентов нужен **generic fallback**.

## Scope (Tier C; Reviewer REQUIRED)

### Stage 1 — Bottom house interpretations parity with monthly table

#### Stage 1.1 — Add helper

`services/api-python/app/pdf/transit_themes.py`:

```python
def houses_from_transit_matrix(tmatrix: list[dict], planet_key: str) -> list[int]:
    """Return sorted unique house numbers for `planet_key` from monthly-table snapshots.

    Mirrors the contract of `transit_matrix_by_month`: every house listed
    here MUST appear in some month-row of `tmatrix`. Used for bottom house-
    interpretation block so it stays consistent with the rendered table.
    """
```

#### Stage 1.2 — Template switch

In `solar.html.j2:591`, replace:

```jinja
{% set visited = houses_visited(
     facts.annual_transit_table, p_key, horizon=solar_year) %}
```

with:

```jinja
{% set visited = houses_from_transit_matrix(tmatrix, p_key) %}
```

(`tmatrix` already computed on line 544 — reuse.)

#### Stage 1.3 — `houses_visited` callers audit

Check that `houses_visited` callers besides this template usage stay correct:
- `synthesis_themes.py` (Phase 3 horizon split) — может или должно остаться?
- Test files — какие?

Worker reports audit results в HANDOFF. **`houses_visited` саму функцию не удалять и не менять** — это Phase 3 contract; только template usage переключается на new helper.

### Stage 2 — Generic outer-cards fallback

#### Stage 2.1 — Detection rule

In `services/api-python/app/pdf/outer_cards.py`, add function:

```python
def generic_outer_cards(
    facts: dict,
    *,
    tz_id: str | None = None,
) -> list[dict]:
    """Build outer-card list deterministically from facts when no allowlist exists.

    Includes any Uranus/Neptune/Pluto transit to a natal planet/MC/Asc that
    forms a major aspect (existing aspect filter in outer_cards.py).
    Returns card dicts in the same shape as build_outer_card() output.
    """
```

#### Stage 2.2 — Wiring

In `outer_cards_for_case(case_id, annual_transit_table, tz_id)`:
- If `case_id in OUTER_CARD_ALLOWLIST` AND allowlist entry non-empty → existing allowlist behavior (UNCHANGED).
- If `case_id is None` OR `case_id not in OUTER_CARD_ALLOWLIST` → invoke `generic_outer_cards(facts, tz_id=tz_id)`.

Existing calibrated cases (05/08/10 Marina-reference + 01/02/03/04/09 Phase 8D extension) **MUST stay bit-identical pre/post** — regression check.

#### Stage 2.3 — Generic card content (per user direction 2026-05-16)

**Структура карточки полная**, БУТ texts **только из controlled source**:
- **Title:** existing `_card_title()` helper в outer_cards.py — already deterministic.
- **Intervals:** existing `aggregate_display_windows` — already deterministic from engine output.
- **Golden-rule table (5 cells):**
  - `transit_natal_house` — from `natal_chart` planet position house.
  - `target_natal_house` — same for target.
  - `transit_ruled_houses` — reuse `rulership_houses.py:rulership_houses()` (Phase 5).
  - `target_ruled_houses` — same.
  - `transit_walks_house` — reuse Phase 5 helper.
- **`psychology` + `event_level`:**
  - Per user direction: «если есть существующий словарь/шаблон — использовать его; если нет — короткий нейтральный deterministic fallback из фактов таблицы: планета, аспект, дома, управители. Никакой свободной красивой прозы 'под Марину'.»
  - Worker checks `outer_cards.py` для existing dict mapping `(transit, aspect, target) → texts`. Если есть — use.
  - Если нет existing dict OR specific (transit, aspect, target) tuple отсутствует → deterministic template like: `«Транзит {transit_ru} в {aspect_ru} с натальным {target_ru} затрагивает темы домов {target_natal_house} и {target_ruled_houses}. Транзитная планета проходит {transit_walks_house} дом, активируя {transit_natal_house} дом радикса.»`
  - **Никакой свободной красивой прозы под Marina-style.** Detected fallback usage MUST be listed in HANDOFF.
- **`provenance:` field в card dict:** `"calibrated"` для allowlist cases; `"generic-fallback"` для new path. Это нужно чтобы template или tests могли отличить.

### Stage 3 — Tests + verification

#### Stage 3.1 — Stage 1 parity tests

- For each of 9 calibrated cases (01/02/03/04/05/07/08/09/10): bottom house list for Mars/Saturn/Jupiter/Venus MUST equal monthly-table snapshot column union. Assert via `houses_from_transit_matrix(tmatrix, planet_key) == set of houses in tmatrix planet column`.
- Specific case for Ольга (consultation 10):
  - `Венера в 8 доме` absent.
  - `Марс в 1 доме` absent.
  - Bottom interpretation set = table column union per planet.

#### Stage 3.2 — Stage 2 generic-fallback tests

- Test 1: Calibrated case 10 (Данила, `case_label='10-danila-2025-2026'`) — `outer_cards_for_case` returns allowlist cards (3 cards, existing facts). Bit-identical pre/post (regression).
- Test 2: Non-calibrated case (Ольга consultation 10, `case_label=None`) — `outer_cards_for_case` returns generic cards. Expected count > 0 (engine emits Uranus/Neptune/Pluto major aspects for Ольга's natal chart and current SR). Worker MUST first inspect actual aspect candidates and report expected count in HANDOFF before writing test.
- Test 3: Generic card structure assertions — every generic card has title + intervals + 5 golden-rule cells + psychology + event_level (non-empty strings or deterministic templates); `provenance=="generic-fallback"`.

#### Stage 3.3 — Manual UI smoke (in acceptance)

After Worker commits:
- Render PDF для Ольги consultation 10 через API.
- Extracted text contains:
  - «Венера в 8 доме» absent (Stage 1).
  - «Марс в 1 доме» absent (Stage 1).
  - «Транзиты высших планет» section present (Stage 2).
  - «Интервалы реализации» present (Stage 2).
  - «Золотое правило транзита» present (Stage 2).
  - «Психологический уровень» present (Stage 2).
  - «Событийный уровень» present (Stage 2).

## Files

- modify:
  - `services/api-python/app/pdf/transit_themes.py` — new helper `houses_from_transit_matrix`.
  - `services/api-python/app/pdf/outer_cards.py` — new function `generic_outer_cards` + wiring in `outer_cards_for_case`.
  - `services/api-python/app/pdf/builder.py` — register `houses_from_transit_matrix` в Jinja env (line ~404 analog to `houses_visited`).
  - `services/api-python/app/pdf/templates/solar.html.j2` — line 591 switch helper invocation.
  - Tests in `services/api-python/tests/test_transit_themes.py` (или new `test_transit_section_generic.py` — Worker decides).
  - `project-overlays/astro/STATUS_RU.md`.

- new: maybe new test file (Worker decides).

- delete: —

## Do not touch

- Engine: Haskell core, schema, fixtures.
- `houses_visited()` function itself — Phase 3 contract preserved.
- Existing allowlist behavior for calibrated cases (05/08/10 + 01/02/03/04/09).
- `OUTER_CARD_ALLOWLIST` data + `_OUTER_CARD_FACTS` data — не менять existing entries.
- `render_case.py` — canonical script path stays as-is.
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs.
- Marina framing memo.
- TASK A scope (directions section — отдельный TASK).
- 12 future-work items audit § A.2.1.D (Pluto display rule, single-window alignment, case 03 P-Mars typo, Анастасия TYPE-D).
- **Formulas из directions (e.g. `1+5`, `1+7`, etc.) — OUT OF SCOPE для generic outer-card facts** (per user direction 2026-05-16). Formulas — отдельная presentation feature (existing для directions section); не смешивать с transit-card facts. Generic card golden-rule использует ONLY: transit planet / aspect / target / transit_natal_house / target_natal_house / transit_ruled_houses / target_ruled_houses / transit_walks_house.

## Reviewer subagent (REQUIRED per user direction 2026-05-16)

After Stage 1-3 work, spawn Reviewer subagent (`general-purpose`). Reviewer scope:

1. **Stage 1 helper correctness:** `houses_from_transit_matrix(tmatrix, planet_key)` returns exact column union from `tmatrix`. Spot-check 2-3 calibrated cases.
2. **Stage 1 parity:** for calibrated cases (05/08/10), bottom interpretation set == monthly table column union (no «расхождения» as in pre-fix `solar-10.pdf`).
3. **Stage 2 calibrated regression:** `outer_cards_for_case` для cases 05/08/10 returns bit-identical card list pre/post (no allowlist behavior change).
4. **Stage 2 generic correctness:** для Ольги (case_label=None), generic cards generated with expected count + structure + provenance="generic-fallback". Texts deterministic, no Marina-style invention.
5. **Pytest independent run:** `(301 baseline) + N new tests passed + 0 xfailed + 0 failed`.
6. **Manual UI smoke replication:** render Ольгу consultation 10 PDF, extract text, verify Stage 3.3 assertions.

Reviewer reports APPROVE / REQUEST CHANGES / ESCALATE.

## Acceptance summary

### Stage 1 — House interpretations parity

- [ ] `houses_from_transit_matrix(tmatrix, planet_key)` helper added.
- [ ] Template `solar.html.j2:591` switched to new helper.
- [ ] For Ольга solar-10: `Венера в 8 доме` absent, `Марс в 1 доме` absent.
- [ ] For all 9 calibrated cases: bottom interpretation set == monthly table column union.

### Stage 2 — Generic outer cards fallback

- [ ] `generic_outer_cards(facts, tz_id)` function added.
- [ ] `outer_cards_for_case` wires to generic fallback for non-allowlisted cases.
- [ ] Existing allowlist behavior for 05/08/10/01/02/03/04/09 bit-identical pre/post.
- [ ] Generic card structure complete: title + intervals + 5-cell golden-rule + psychology + event_level + provenance.
- [ ] Card texts from controlled source only: existing dict if present, else deterministic template (no Marina-style invention).
- [ ] Worker HANDOFF lists every (transit, aspect, target) tuple where fallback fired.

### Stage 3 — Tests

- [ ] Stage 1 parity tests added (9 calibrated cases pass).
- [ ] Stage 2 calibrated regression test (cases 05/08/10 bit-identical pre/post).
- [ ] Stage 2 generic test для Ольги (expected count > 0, structure correct).
- [ ] Manual UI smoke: text assertions per Stage 3.3.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: `(301 baseline) + N new passed + 0 xfailed + 0 failed`.
- [ ] `git status --short` clean.
- [ ] Product commit(s) ≤ 2 (Stage 1 + Stage 2, ИЛИ combined). Justify split в HANDOFF.
- [ ] Overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.

## STOP triggers

- Calibrated cases 05/08/10/01/02/03/04/09 outer cards diverge bit-identical pre/post → STOP, regression в allowlist path.
- Generic card texts include free Marina-style prose (any text not in existing dict and not deterministic from facts) → STOP, scope mismatch.
- `houses_visited()` semantics change → STOP, Phase 3 contract violation.
- Template touches outside line 591 helper switch → STOP, scope creep.
- Worker tempted to add new entries to `OUTER_CARD_ALLOWLIST` для Ольги → STOP, allowlist is curated calibration set; generic fallback is the right path.
- Generic card count for Ольга = 0 (no outer aspects detected) → STOP, escalation memo с diagnostic (либо engine не emitted, либо filter слишком узкий).
- Reviewer escalates.

## Context

**Mode normal + Tier C.** Reviewer **REQUIRED** per user direction 2026-05-16 (new code path для клиентских PDF; integration risk).

**Baseline:**
- Product main @ `1536612` (post api-pdf-endpoint TASK closure).
- Overlay master @ `fdfec88` (TASK A drafted; TASK B будет на top после TASK A closure OR в parallel — Worker launch waits TASK A completion per user order direction).
- Pytest baseline: `301 passed + 0 xfailed + 0 failed`.
- Cabal: clean.

**Order per user direction 2026-05-16:** TASK A (directions filter) executes first; TASK B (this) starts ПОСЛЕ TASK A closure.

**Not in scope (explicit):**
- Engine changes.
- TASK A scope (directions section filter).
- 12 future-work items audit § A.2.1.D.
- UI/API changes (presentation only).
- New allowlist entries для Ольги или других non-calibrated persons.
- Free Marina-style prose generation.

**Ready: yes** — flipped 2026-05-16 after user ack + 4 clarifications:

1. **Spec clean** — нет новых требований; scope ровно по файлу (Stage 1 helper + Stage 2 generic fallback + Stage 3 tests).
2. **Reviewer REQUIRED** confirmed. Runtime limitation path: если Agent tool недоступен у Worker'а — Worker self-review + **explicit note в HANDOFF**, потом TL spawns external Reviewer post-submission (same pattern как TASK api-pdf-endpoint-end-to-end + TASK 8B/8D/8E).
3. **Formulas из directions — OUT OF SCOPE.** Generic outer-card facts use ONLY: transit planet, aspect, target, transit_natal_house, target_natal_house, transit_ruled_houses, target_ruled_houses, transit_walks_house. **NOT добавлять «формулы» из directions** (например `1+5`, `1+7`) в generic card facts. Это отдельная presentation feature (existing для directions section); не смешивать с transit-card facts.
4. **Runtime limitation path:** Worker self-review + HANDOFF explicit note; TL spawns Reviewer afterwards.

Worker order: TASK A closed (commit `ff7af69`); TASK B (this) executes сейчас.

## Closure (2026-05-16)

**Worker delivered + TL inline-verify + external Reviewer APPROVE + user explicit closure ack.**

- **Product commits:** `2670f4e` (Stage 1: `houses_from_transit_matrix` helper + Jinja env registration + template switch) + `aca694b` (Stage 2-3: `generic_outer_cards` + dispatch + `provenance` field + `"07-mariya-2025-2026": []` allowlist entry + 63 new tests).
- **Overlay commits:** `43f44b5` (Worker submission + STATUS_RU initial) + this closure commit.
- **Pytest:** 305 baseline → **368 passed + 2 skipped (vacuous case 07) + 0 failed.**

### Stage results

- **Stage 1 — bottom interpretations parity:** Helper `houses_from_transit_matrix(tmatrix, planet_key)` projects already-computed `tmatrix` (line 532 шаблона) в sorted unique houses. Template `solar.html.j2:579` switched от `houses_visited(...)` к новому helper. **`houses_visited()` функция не тронута** (Phase 3 contract preserved). Для Ольги: «Венера в 8 доме» / «Марс в 1 доме» больше не появляются.
- **Stage 2 — generic outer-cards fallback:** `generic_outer_cards(facts, tz_id=...)` строит карточки из engine output: 5 Ptolemaic aspects only (Quincunx filtered per Correction 009), 5-cell golden-rule через `rulership_houses.py` (Phase 5), psychology + event_level — deterministic templates. `provenance` field: `"calibrated"` / `"generic-fallback"`. `outer_cards_for_case` extended kwarg `facts=None` (Option A — backward-compatible). Calibrated cases (05/08/10 + 01/02/03/04/09) **bit-identical pre/post** (verified Reviewer Item 3 — 9/9 cases). **Mariya case 07:** explicit empty allowlist `"07-mariya-2025-2026": []` (Marina editorial zero; pinned by `test_case_07_allowlist_explicit_zero`).
- **Stage 3 — tests:** 63 new в `tests/test_transit_section_generic.py` (parity для 9 calibrated cases × planets, bit-identity calibrated regression, generic для Ольги, deterministic re-run, no Marina-style prose contract). 2 skipped = case 07 vacuous parametrize.

### External Reviewer APPROVE (2026-05-16, 6 points)

All 6 items PASS via independent empirical reproduction:
1. Helper correctness — 12 spot-checks across 3 cases × 4 planets.
2. Bottom interpretation parity — 36 parity checks calibrated + Ольга PDF zero occurrences both bug strings.
3. Calibrated bit-identity — 9/9 cases; case 10 spot-check (3 cards inc. Нептун кв Юпитеру 4 windows).
4. Generic Ольга — 7 cards `provenance="generic-fallback"`; texts deterministic from facts; **0 formulas**; engine emit 10 → 7 (3 quincunx filtered).
5. Pytest 368/2/0 independent.
6. Manual UI smoke replication — 24 pages / 154 KB; 5/5 outer-card markers; 7 outer card titles (Уран×3 + Нептун×3 + Плутон×1); Phase 3 guard ✓.

### Reviewer beyond-scope notes — recorded as non-blocking future polish

1. **`Asc/MC` nominative dict gap в golden-rule natural radix cell:** card 4 «Нептун кв Асц» title shows Cyrillic «Асц» but `golden_rule.row_natural.radix` shows Latin `'Asc'` fallback (т.к. `_PLANET_NOM_RU` не содержит `'Asc'`/`'MC'` keys). **Calibrated path имеет такой же gap** — out of TASK B scope; deferred as future cosmetic polish.
2. **Test name `test_calibrated_cards_bit_identical_except_provenance`** немного misleading (test asserts full equality including provenance — both sides emit `"calibrated"`, equality holds). Contract correct; deferred as future cleanup.
3. **Runtime limitation 5-я occurrence** (Agent tool недоступен в Worker subagent runtime) — infrastructure pattern, не product code. Worker correctly self-reviewed + escalated к TL для external Reviewer post-submission per established discipline (TASK 8B/8D/8E/api-pdf-endpoint precedent).

### User explicit closure ack — received 2026-05-16

User confirmed all 5 closure items:
1. Status review → done.
2. HANDOFF open → closed.
3. Archive TASK + HANDOFF.
4. STATUS_RU update: post-recovery follow-ups closed; API/render/PDF pipeline works for calibrated AND non-calibrated clients.
5. Single overlay commit + push backup.
3 Reviewer informational notes recorded as non-blocking future polish.

### Production state at closure

- Product main = backup/main = `aca694b`.
- Overlay master = backup/master = (this closure commit).
- Pytest **368 passed + 2 skipped + 0 failed**.
- Cabal Up to date.
- uvicorn serving Ольга consultation 10 PDF: 24 pages, 7 generic outer cards, deterministic content.

### Pipeline state at closure (post 3 follow-ups)

API → render → PDF pipeline теперь **полностью работает для любого клиента**:
- **Calibrated cases** (Наталья / 01/02/03/04/05/07/08/09/10): existing allowlist + curated card-facts (Phase 4+5+7b+8D).
- **Non-calibrated cases** (любой новый клиент): generic-fallback с deterministic templates; no Marina-style invention; no formulas; engine-driven 5-Ptolemaic aspects filter.

### Status: done

Archive to `project-overlays/astro/TASKS/archive/`. HANDOFF archive to `HANDOFFS/archive/`. 3 post-recovery follow-up TASKs all closed (api-pdf-endpoint-end-to-end + directions-show-all-active + transit-section-generic-output).
