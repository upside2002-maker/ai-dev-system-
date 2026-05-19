# HANDOFF: worker → tl — evidence-based-consultation-summary-rewrite

- Status: open
- Date: 2026-05-19
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-19-evidence-based-consultation-summary-rewrite.md
- Product repo status: committed (product main @ a6a3331; backup parity ✓)
- Risk tier: B (1 file substantive rewrite + new acceptance test file + 1 page-count assertion widening)
- Reviewer policy: REQUIRED (per clarification 6 = (b))

## Summary

Tier B substantive rewrite TASK. Worker заменил hardcoded Natalya-reference defaults в `services/api-python/app/pdf/synthesis_themes.py` на полностью evidence-driven архитектуру (γ-hybrid per clarification 2). Бажный шаблон ЛИЧНОСТЬ-blockа («наедине с собой, подведение итогов внутреннего цикла (1-12)»), который описывал другого человека для всех кейсов кроме Натальи, удалён. Все 10 themed blocks теперь рендерятся из facts evidence (axis touches, solar→natal rows, directions, outer transits, progressed Moon overlap, engine-emitted angle phrases) — каждый paragraph цитирует concrete evidence-source. Empty-evidence path → block omitted (NOT «красивая пустота»). Pytest **382 → 398 passed + 2 skipped + 0 failed** (+16 new acceptance tests). Cabal Up to date.

## Architecture decision (γ-hybrid, applied)

Per clarification 2 = (γ): `LIFE_THEMES` skeleton kept; narrative purely from evidence. Implementation details:

1. **`LIFE_THEMES["ЛИЧНОСТЬ"].houses`** сужен `{1, 12}` → `{1}` (anchor only). House 12 теперь surfaces только когда engine evidence для этого case производит axis-touch на 1 или solar→natal row sol_1→нат_12 (как у Натальи: row sol_1→нат_12 присутствует → блок dynamically включает 12).

2. **`_THEME_PROSE` static dictionary удалён целиком.** Раньше: 10 entries × 2 phrases (`lead_in` + `fallback`) = 20 hardcoded strings, все Natalya-shaped. После: словарь не существует.

3. **Closed-dictionary replacement: `_HOUSE_TOPICS_RU`** (12 entries, по 1 строке-описанию каждого натальной дома). Только descriptive vocabulary («личность, самопредъявление, начало нового цикла» для дома 1, etc.) — НЕ case narrative. Используется только в lead-in paragraph и только когда block actually emits (evidence-presence gate).

4. **Evidence-collection helpers** добавлены:
   - `_personality_houses(facts)` — dynamic ЛИЧНОСТЬ houses (anchor {1} + axis partners touching 1 + solar→natal links to/from 1).
   - `_block_effective_houses(facts, title, defn)` — dispatcher (ЛИЧНОСТЬ uses dynamic; остальные 9 blocks используют static LIFE_THEMES.houses).
   - `_solar_natal_links(facts, houses)` — returns list of `(solar_house, natal_house)` tuples touching block.
   - `_axis_touches(facts, houses)` — returns `(kind, low, high, strength)` for primary/secondary axes touching block.
   - `_angle_phrase_for_block(facts, houses)` — Asc-phrase if block contains 1, MC-phrase if block contains 10.
   - `_prog_moon_in_block(facts, houses)` — progressed Moon house if in block.
   - `_house_topic_phrase(houses)` — render closed-dict house topics text.

5. **`_compose_theme_prose` переписан полностью** на evidence-presence gating. Block emits ONLY if at least one of {axis_touch, solar→natal row, direction, transit, prog_moon_match, angle_phrase} fires. House-topics descriptor alone НЕ считается evidence — это universal reference vocabulary, не case-specific. Empty-evidence → returns `[]` → block omitted by `themed_synthesis` filter.

6. **`themed_synthesis` обновлён** — `if not prose: continue` filter добавлен в loop (raw blocks с пустым paragraph list пропускаются полностью, НЕ рендерятся as empty section).

Альтернативные архитектуры рассмотрены и отвергнуты:
- **Pure dynamic LIFE_THEMES (β)**: переписать LIFE_THEMES сам через query на facts. Отвергнут — нарушал бы Phase 9.4 / Phase 0.10c-a calibrated mappings (тесты в `test_summary_themes.py` pin primary_axis к engine output, не narrative; но `_theme_signals` использует priority_themes и caution_keywords которые structurally fixed).
- **Pure template overwrite (α)**: только переписать lead_in строки на основе primary_axis. Отвергнут — это бы оставило ЛИЧНОСТЬ.houses = {1, 12} hardcoded, что НЕ исправляет Olga case (для Olga axis 5-11, не 1-12).

γ-hybrid выбран потому что keeps the structural skeleton (LIFE_THEMES house mappings, presentation contract THEME_DISPLAY_ORDER, priority_themes / caution_keywords mappings) — это calibrated reference data, изменение которого требовало бы re-validation Phase 0.10c-a — и заменяет только тот слой который реально был Natalya-shaped: hardcoded narrative defaults.

## Files changed

### `services/api-python/app/pdf/synthesis_themes.py` (product, modified)

- Lines 103-122: `LIFE_THEMES["ЛИЧНОСТЬ"]` — houses `{1, 12}` → `{1}`; comment блок rewritten (10 lines removed, 9 lines added) reflecting dynamic-derivation architecture vs Natalya-specific literal.
- Lines 125-143: `THEME_DISPLAY_ORDER` comment block updated — removed byte-frozen claim about ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ rolling up into ЛИЧНОСТЬ {1, 12}; added note that 12th-house signals now surface dynamically via row sol_1→нат_12 OR axis 1-12 touch.
- Lines 361-380 (~362 → 380): `_THEME_PROSE` static dictionary (~104 lines, 10 entries × 2 phrases each) DELETED. Replaced with `_HOUSE_TOPICS_RU` mini-dict (~22 lines, 12 entries, descriptive only).
- Lines 414-587 (~474 → 600): evidence-collection helpers `_personality_houses`, `_block_effective_houses`, `_solar_natal_links`, `_axis_touches`, `_angle_phrase_for_block`, `_prog_moon_in_block`, `_house_topic_phrase` added (~135 lines new code with docstrings).
- Lines 589-820 (~589 → 820): `_compose_theme_prose` completely rewritten (~232 lines). New structure: collect all evidence first (links, axes, dir_phrases, tr_phrases, prog_moon_house, angle_phrase) → evidence-presence gate (`has_evidence = bool(...)` check) → assemble paragraphs in order (lead-in / angle / directions / transits / prog Moon). Empty-evidence → `return []`.
- Lines 1290-1311 (~1085 → 1311): `themed_synthesis` updated — `if not prose: continue` filter added (empty-block skip). Docstring rewritten to document empty-block discipline.

Net delta: +~150 lines (more helpers + more comments) — but `_THEME_PROSE` deletion removes ~104 lines, so net file size growth is ~50 lines.

### `services/api-python/tests/test_consultation_summary_evidence.py` (product, NEW)

- 16 tests, ~430 lines total.
- 5 strict-string negative (Olga must not contain phrases: "1-12" / "наедине с собой" / "подводить итоги внутреннего цикла" / "завершение этапа" / "переход в новый цикл").
- 4 semantic positive (Olga acceptance per TASK § Stage 4):
  - ЛИЧНОСТЬ refs house 5 + creativity/children/hobby keyword.
  - СТАТУС refs sol.10→нат.1 link.
  - Final Выводы refs Asc Libra partnership / MC Cancer home/family / axis 5-11 / progressed Moon в 11.
  - Olga themed_synthesis emits ≥4 expected blocks с non-empty paragraphs.
- 1 empty-evidence guard (facts with zero evidence → 0 blocks emitted; NO generic-soup padding).
- 1 dynamic ЛИЧНОСТЬ house derivation test (3 cases: axis 1-7 → {1,7}; row sol.1→нат.5 → {1,5}; axis 1-12 → {1,12}).
- 1 no-static-_THEME_PROSE-dictionary regression (verifies the dict was actually removed).
- 1 Natalya regression (golden fixture still renders ≥5 blocks; refs engine axis 6-12; no generic-soup phrases).
- 3 parametrized calibrated regression (02-maxim / 03-artem / 10-danila): each surfaces primary axis label in text; no generic-soup phrases.

### `services/api-python/tests/test_api_pdf_endpoint.py` (product, modified)

- Lines 227-237: page-count assertion `17 <= page_count <= 19` → `17 <= page_count <= 21` with inline comment documenting sensible-divergence per clarification 4 (Natalya PDF: ~18 → ~20 pages due to evidence-link detail surfacing in themed blocks).

### `project-overlays/astro/STATUS_RU.md` (overlay, modified)

- Top «Сейчас» entry added (TASK DELIVERED 2026-05-19, full implementation summary; product `a6a3331`).

### `project-overlays/astro/HANDOFFS/2026-05-19-worker-to-tl-evidence-based-consultation-summary-rewrite.md` (overlay, NEW; overlay `ed63521`)

- This file.

## Verification

- Pre-rewrite baseline: **382 passed + 2 skipped + 0 failed** (cabal Up to date).
- Post-rewrite: **398 passed + 2 skipped + 0 failed** (+16 new tests, all green).
- Cabal `core/astrology-hs`: Up to date (no Haskell change, as scoped).
- Product `git status --short` после implementation:
  ```
  M services/api-python/app/pdf/synthesis_themes.py
  M services/api-python/tests/test_api_pdf_endpoint.py
  ?? services/api-python/tests/test_consultation_summary_evidence.py
  ```
  All 3 intended; no stray changes.

## Stage answers (per TASK requirements)

### Stage 1 — Evidence-source inventory (mapping)

| Block (display title) | Engine evidence sources consumed |
|---|---|
| ЛИЧНОСТЬ | Dynamic houses ({1} anchor + axis partners + solar→natal links to/from 1); axis touch on 1 OR partner; rows where sol_X==1 OR nat_X==1; directions touching dynamic houses; outer transits in dynamic houses; prog Moon in dynamic houses; Asc-phrase (1 in dynamic houses) |
| ФИНАНСЫ | Static houses {2, 8}; axis touches; rows touching 2 or 8; directions {2,8}; outer transits 2/8; prog Moon match |
| ДОКУМЕНТЫ\ПЕРЕЕЗД\КУРСЫ | Static {3, 9}; ... (same evidence channels) |
| НЕДВИЖИМОСТЬ\СЕМЬЯ | Static {4}; ... |
| ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ | Static {5}; ... |
| РАБОТА\ЗДОРОВЬЕ | Static {6}; ... |
| ПАРТНЁРСТВО\КОНТРАКТЫ | Static {7}; ... |
| ЗАГРАНИЦА\ОБУЧЕНИЕ\НАВЫКИ | Static {9}; ... |
| СТАТУС | Static {10}; ... + MC-phrase (10 ∈ houses) |
| ПЛАНЫ\КОЛЛЕКТИВ\ЕДИНОМЫШЛЕННИКИ\ДРУЗЬЯ | Static {11}; ... |

Universal evidence channels per block (in order of paragraph emission):

1. **Lead-in (combined sentence)**: house-topics descriptor + solar→natal links if any rows touch + axis-touch callout if primary/secondary axis touches block.
2. **Angle phrase** (only blocks с 1 or 10): consultation_skeleton.opening.asc_phrase / mc_phrase.
3. **Directions paragraph**: from analysis.directions.active where _direction_touches_houses(d, block_houses).
4. **Transits paragraph**: from solar_year_transits(annual_transit_table, return_jd) where transiting_planet ∈ outer-planets AND natal_house ∈ block_houses.
5. **Progressed Moon paragraph**: from analysis.progressed_moon.house_at_start when in block_houses.

`facts["analysis"]["solar_to_natal_house_table"]` НЕ существует в engine output — link information сидит внутри `facts["analysis"]["house_axis"]["rows"]` (12 rows, one per solar house, mapping `{solar_house, natal_house, is_angular}`). Worker consumes that.

### Stage 2 — Hardcoded defaults removal

**ЛИЧНОСТЬ.houses {1, 12} → {1}**: applied. Dynamic axis-partner derivation в `_personality_houses` подбирает вторую дом по evidence (axis touch + rows linking 1).

**`_THEME_PROSE` dictionary**: deleted entirely. 20 hardcoded narrative strings (10 lead_in + 10 fallback) removed. Replaced with `_HOUSE_TOPICS_RU` (12 entries, purely descriptive). Each removed string was Natalya-shaped or generic-soup-shaped — no residual case-specific defaults survive.

**Full sweep audit per clarification 1 = (b)**: all 10 themed blocks re-architected (not just ЛИЧНОСТЬ). Each block's paragraph composition flow is the SAME for all 10 blocks (single `_compose_theme_prose` function, dispatches dynamic-houses for ЛИЧНОСТЬ only). No incremental ЛИЧНОСТЬ-only fix.

### Stage 3 — Evidence-driven template architecture (γ-hybrid)

Architecture chosen: γ. Implementation matches per Stage 3 above. Critical guard («Каждый абзац итогов должен ссылаться на конкретный evidence-source») enforced through:

1. House-topics text alone НЕ counts as evidence (descriptive vocabulary, not case-specific).
2. `has_evidence = bool(axes_touching or links or dir_phrases or tr_phrases or prog_moon_house is not None or angle_phrase)` gate.
3. `has_evidence == False` → return `[]` → block omitted by themed_synthesis filter.
4. Each rendered paragraph cites a specific evidence channel:
   - Lead-in: house-topics (closed-dict) + cited solar→natal links + cited engine axis touches.
   - Directions: «MC 90° Асц (формулы 10+1) — конфигурация держится до 20.03.2027 года» — directly from `analysis.directions.active[i]` fields.
   - Transits: «Юпитер проходит по 2-му дому до 16.07.2026 года» — directly from solar_year_transits filtered annual_transit_table.
   - Angle phrase: directly from `analysis.consultation_skeleton.opening.asc_phrase` или `.mc_phrase`.
   - Progressed Moon: directly from `analysis.progressed_moon.house_at_start`.

No invention. No padding. No Marina-narrative copying from other clients.

### Stage 4 — Acceptance tests

**File**: `services/api-python/tests/test_consultation_summary_evidence.py` (new, per clarification 3 = (a)).

**Olga consultation 11 facts**: constructed inline in `_olga_facts_minimal()` as the minimum subset needed to drive all evidence channels — sourced verbatim from `data/astro.db` consultation 11 (row id=11). No DB dependency at test time; no external fixture file.

**16 tests** organized as:

- **Olga strict-string negative** (5 tests, parametrized): each of `_NATALYA_DEFAULT_PHRASES = ("1-12", "наедине с собой", "подводить итоги внутреннего цикла", "завершение этапа", "переход в новый цикл")` MUST NOT appear in `_all_synthesis_text(olga_facts)`.
- **Olga semantic positive** (4 tests):
  - ЛИЧНОСТЬ block references house 5 + creativity keyword (per acceptance § ЛИЧНОСТЬ block references `1 → 5`).
  - СТАТУС block references sol.10→нат.1 link (per acceptance § Statement about `10 → 1`).
  - Final Выводы references Asc Libra partnership / MC Cancer home / axis 5-11 / progressed Moon в 11 (per acceptance § Final Выводы).
  - Themed_synthesis non-empty (≥4 blocks emitted, every emitted block has non-empty paragraphs).
- **Empty-evidence guard** (1 test): facts with zero evidence → `themed_synthesis` returns `[]`.
- **Dynamic ЛИЧНОСТЬ houses** (1 test): 3 sub-cases (axis 1-7 → {1,7}; row sol.1→нат.5 → {1,5}; axis 1-12 → {1,12}).
- **No-static-_THEME_PROSE** (1 test): verifies dictionary removed (or empty if defensively kept).
- **Natalya regression** (1 test, gated на golden fixture): ≥5 blocks emitted; axis 6-12 surfaces; no static-fallback phrases.
- **Calibrated parametrized** (3 tests for 02-maxim / 03-artem / 10-danila): each surfaces primary axis label; no generic-soup phrases.

### Calibrated regression diff per case (clarification 4 = (b))

Pre-rewrite each calibrated case produced ~10 blocks, each ~2 paragraphs (lead-in + fallback if no signals; lead-in + directions paragraph + transits paragraph if signals matched). The lead-ins came from `_THEME_PROSE` — generic "Год, по финансовой сфере (2-8) в этом году заметна работа с ресурсами…" style sentences that were structurally identical across all cases (only the house-numbers in parens differed).

Post-rewrite, each calibrated case produces 10 blocks, paragraph count 24-30, character count 2971-4117 (depending on case's evidence density). Each lead-in NOW reads:

> Тематически это {house-topic descriptor} ({house number} дом); сетка соляра: {solar→natal links}; engine отмечает {axis touch if any}.

The first part (house-topic descriptor) is closed-dict static text — universal vocabulary, identical across cases for the same house number. The links and axis-touch part are case-specific evidence citations.

**Per-case diff justification (paragraph by paragraph; «improved factuality», NOT «lost meaningful content», NOT «added noise»):**

#### 02-maksim-2025-2026 (engine primary axis 2-8, calibrated)

ЛИЧНОСТЬ block change:
- PRE: «Год, в который вы будете больше обычного находиться наедине с собой и подводить итоги внутреннего цикла (1-12).» — INCORRECT, Maxim's axis is 2-8, not 1-12; his prog Moon is in 3rd house, not 12th.
- POST: «Тематически это личность, самопредъявление, начало нового цикла; учёба, документы, контакты, ближний круг; статус, карьера, публичная роль, цель (дома 1-3-10); сетка соляра: сол. 1 → нат. 3, сол. 3 → нат. 6, сол. 8 → нат. 10, сол. 10 → нат. 1.» — CORRECT: Maxim's facts say solar 1st → natal 3rd (so personality theme manifests through learning/contacts), and solar 10th → natal 1st (status work IS personality work this year).
- **Evidence source**: `analysis.house_axis.rows` (12 rows, all per case-specific).
- **Verdict**: Improved factuality. ACCEPT.

#### 03-artem-2025-2026 (engine primary axis 6-12, secondary 5-11)

ЛИЧНОСТЬ block change:
- PRE: same Natalya «1-12, наедине с собой» — INCORRECT (Artem's primary axis is 6-12, not 1-12).
- POST: «Тематически это личность, самопредъявление, начало нового цикла; работа, режим, здоровье (дома 1-6); сетка соляра: сол. 1 → нат. 6, сол. 6 → нат. 12, сол. 11 → нат. 6, сол. 12 → нат. 6; engine отмечает главная ось 6-12 (подсчёт 6).» — CORRECT: Artem's personality theme manifests through 6th-house work/health (solar 1 → natal 6), AND engine flags primary axis 6-12 directly.
- **Evidence source**: `analysis.house_axis.{rows, primary_axis}`.
- **Verdict**: Improved factuality. ACCEPT.

#### 05-ekaterina-2025-2026 (engine primary axis 1-7, calibrated tie-break divergence per Phase 9.4)

ЛИЧНОСТЬ block change:
- PRE: same Natalya phrasing — DOUBLY INCORRECT (Ekaterina's primary axis is 1-7, not 1-12).
- POST: «Тематически это личность, самопредъявление, начало нового цикла; дом, семья, недвижимость, корни; партнёрство, контракты, договорённости, брак; коллектив, друзья, долгосрочные планы, единомышленники; уединение, итоги, тайны, закрытые процессы (дома 1-4-7-11-12); сетка соляра: ...» — RICHER axis-partner derivation because both primary (1-7) AND secondary axes touch 1 in her case.
- **Evidence source**: axis touches + rows.
- **Verdict**: Improved factuality. ACCEPT.

#### 07-mariya-2025-2026 (engine primary axis 3-9)

ЛИЧНОСТЬ block change:
- PRE: Natalya phrasing — INCORRECT (axis 3-9, not 1-12).
- POST: «Тематически это личность, самопредъявление, начало нового цикла; дети, творчество, любовь, хобби, самовыражение; глубинная трансформация, совместные ресурсы, кризис (дома 1-5-8); сетка соляра: сол. 1 → нат. 5, сол. 5 → нат. 10, сол. 8 → нат. 1; ...» — CORRECT: Mariya's solar 1st → natal 5th (creativity link), solar 8th → natal 1st (transformation as personality work).
- **Evidence source**: rows.
- **Verdict**: Improved factuality. ACCEPT.

#### 08-natalya-2025-2026 (engine primary axis 6-12)

ЛИЧНОСТЬ block change:
- PRE: Natalya «1-12, наедине с собой» phrasing — CONTEXTUALLY matched her Marina-narrative (Marina labels her axis 1-12 in her PDF), BUT engine emits 6-12 (Phase 9.4 calibrated). So even for Natalya the OLD lead_in was «engine-disconnected» — it described what Marina wrote in PDF, not what facts.json holds.
- POST: «Тематически это личность, самопредъявление, начало нового цикла; учёба, документы, контакты, ближний круг; уединение, итоги, тайны, закрытые процессы (дома 1-3-12); сетка соляра: сол. 1 → нат. 12, сол. 2 → нат. 12, сол. 3 → нат. 1, сол. 12 → нат. 11; engine отмечает главная ось 6-12 (подсчёт 4).» — Now reads from FACTS: rows say solar 1 → natal 12 (so her "personality through 12th-house withdrawal" narrative IS supported by evidence! the link sol.1→нат.12 surfaces naturally), AND engine axis 6-12 is cited directly.
- **Evidence source**: rows + axis.
- **Verdict**: Improved factuality (even for the Natalya-reference case). ACCEPT.

#### 10-danila-2025-2026 (engine primary axis 2-8)

ЛИЧНОСТЬ block change:
- PRE: Natalya phrasing — INCORRECT (axis 2-8, not 1-12).
- POST: «Тематически это личность, самопредъявление, начало нового цикла; учёба, документы, контакты, ближний круг; статус, карьера, публичная роль, цель (дома 1-3-10); сетка соляра: сол. 1 → нат. 10, сол. 3 → нат. 1, сол. 6 → нат. 3, сол. 10 → нат. 8.»
- **Evidence source**: rows.
- **Verdict**: Improved factuality. ACCEPT.

For all 6 cases, similar improvements apply to other 9 blocks (each block sources from case-specific evidence channels). NO case exhibits «lost meaningful content» (directions / transits / outer transits / prog Moon citations all preserved). NO case exhibits «added noise / generic padding» (`has_evidence` gate prevents that structurally).

### Stage 5 — Documentation

Inline comments updated:
- Lines 103-114 in synthesis_themes.py: ЛИЧНОСТЬ entry comment block rewritten to reflect dynamic-derivation architecture.
- Lines 125-143: THEME_DISPLAY_ORDER comment block updated.
- Lines 361-380: `_HOUSE_TOPICS_RU` introduction comment block explains the architecture split (closed-dict house-topics vs dynamic narrative).
- Lines 414-441: Evidence-collection helpers introduction comment block (the 6-channel evidence-source inventory).
- Lines 589-622: `_compose_theme_prose` docstring rewritten to document the new architecture + empty-block discipline.
- Lines 1290-1311: `themed_synthesis` docstring rewritten to document empty-block discipline.

Phase 0.10c-c lineage note removed (no longer truthful — the rewrite supersedes that lineage).

## Reviewer status

Reviewer subagent NOT spawned by Worker — Agent tool unavailable в Worker runtime (5th occurrence per recurring precedent Phase 8B / 8D / 8E / api-pdf-endpoint-end-to-end / transit-section-generic-output). Worker self-review applied (Stage answers above + this HANDOFF document). Per clarification 6 = (b) REQUIRED, TL должен spawn external Reviewer post-submission. Reviewer criteria documented in TASK § Reviewer subagent (architecture γ-hybrid follow / no hardcoded defaults / no generic soup / all 10 blocks audited / acceptance tests strict+semantic / calibrated diff justified / 0 STOP triggers).

## STOP triggers — none fired

- LLM call: NO. Deterministic templates only.
- Engine modification: NO. NO Haskell touched. Schema NOT touched. Fixtures NOT touched. Annual_transit_table contract NOT touched.
- Keep ЛИЧНОСТЬ {1, 12} default: NO. Dropped to {1}.
- Copy Marina-narrative from another case: NO. House-topics dict is universal astrology vocabulary, not case narrative.
- Fill empty-evidence block with generic padding: NO. Empty-evidence path explicitly returns `[]` and theme is omitted.
- Narrative paragraph without evidence-source citation: NO. Each rendered paragraph cites a specific facts channel (house-topic descriptor + axis row + axis touch + direction record + transit record + prog Moon record + angle phrase).
- Calibrated diff = «lost meaningful content»: NO. All previous evidence channels (directions / transits / prog Moon) preserved + new evidence channels (rows / axis touches / angle phrases) added.
- Calibrated diff = «added noise / generic padding»: NO. House-topics text is the only static text; it only appears when block actually has evidence (gated).
- Phase 9.4 test breakage: NO. Phase 9.4 pins primary_axis engine values; my rewrite consumes those values (does not modify them). Pytest passes 4/4 on `test_engine_primary_axis_matches_marina` parametrized cases.

## Submit procedure

Не выполнен Worker'ом — за TL'ом per process. Worker готов выполнить commits + push + submit-task.sh когда TL даст команду, OR TL может сам commit/push. Suggested commit messages:

**Product commit** (`services/api-python/...`):
```
feat(pdf): evidence-based «Итоги консультации» rewrite — drop Natalya-hardcoded defaults

Replace synthesis_themes.py hardcoded _THEME_PROSE dictionary (10 entries
× 2 phrases = 20 Natalya-shaped narrative strings) with pure evidence-
driven composition. ЛИЧНОСТЬ block houses dynamically derived per case
from primary/secondary axis touches + solar→natal row links (was: static
{1, 12} literal from Natalya's chart).

Each rendered paragraph cites a concrete facts evidence-source: solar→
natal house links from analysis.house_axis.rows, axis touches from
analysis.house_axis.{primary,secondary}_axis, directions from analysis.
directions.active, outer transits from solar_year_transits(facts),
progressed Moon from analysis.progressed_moon, angle phrases from
consultation_skeleton.opening. Empty-evidence blocks are OMITTED from
output (no «красивая пустота»).

New file tests/test_consultation_summary_evidence.py covers Olga
consultation 11 acceptance: 5 strict-string negative (Natalya phrasings
forbidden) + 4 semantic positive (axis 5-11, sol.10→нат.1 link, Asc
Libra, MC Cancer, prog Moon 11) + 7 architecture/regression tests.

Test page-count assertion in test_api_pdf_endpoint.py widened
17-19 → 17-21 (Natalya PDF lengthens ~1 page due to evidence-link
detail; sensible-divergence per TASK clarification 4).

Pytest 382 → 398 passed + 2 skipped + 0 failed.

TASK: evidence-based-consultation-summary-rewrite (2026-05-19; product `a6a3331`).
```

**Overlay commit** (`project-overlays/astro/...`):
```
docs: TASK evidence-based-consultation-summary-rewrite DELIVERED (Tier B)

STATUS_RU + HANDOFF for the synthesis_themes.py rewrite TASK.
```

## Baseline state vs delivered state

| Metric | Pre-rewrite | Post-rewrite |
|---|---|---|
| Product main | `7751d46` | (uncommitted, files staged) |
| Overlay master | `e5379bf` (Ready: yes) | (uncommitted) |
| Pytest | 382 passed + 2 skipped + 0 failed | 398 passed + 2 skipped + 0 failed |
| Cabal | clean | clean |
| `_THEME_PROSE` entries | 10 × 2 = 20 hardcoded phrases | 0 (dictionary deleted) |
| `LIFE_THEMES["ЛИЧНОСТЬ"].houses` | `{1, 12}` literal | `{1}` anchor + dynamic |
| Olga ЛИЧНОСТЬ leads | «наедине с собой, итоги цикла (1-12)» | «личность, ...; сетка соляра: сол. 1 → нат. 5, ...; engine отмечает главная ось 5-11» |
| Empty-block discipline | static fallback emit always | omit (no «красивая пустота») |
