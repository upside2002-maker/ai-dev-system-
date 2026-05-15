# TASK: phase-8d-allowlist-extension-01-02-03-04-09

- Status: done
- Ready: yes
- Date: 2026-05-14
- HANDOFF: project-overlays/astro/HANDOFFS/2026-05-14-worker-to-tl-phase-8d-allowlist-extension-01-02-03-04-09.md
- Product commit: ce35be1 (astro main)
- Project: astro
- Layer: services (Python presentation only — closed-config additions)
- Risk tier: C (allowlist data + facts + tests; analogous to TASK 7b Stage B closed-config calibration pattern) — **Reviewer subagent REQUIRED (narrow-scope), per user direction 2026-05-14: main risk is human error in golden-rule fact transfer across 5 cases × ~20 outer cards × 5 fact cells, not code.**
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 8A audit (audit report § A.3 TYPE-A item 6) confirmed: cases 01/02/03/04/09 render **0 outer cards** в нашем PDF, тогда как Marina эталоны показывают 2-9 outer cards per case. Это TYPE-A **closed-config gap** — точный аналог решения TASK 7b Stage B для cases 05/10:
- `OUTER_CARD_ALLOWLIST` нет entries для этих case_ids → `outer_cards_for_case` возвращает пустой список → PDF не рендерит outer-card блок.
- `_OUTER_CARD_FACTS` нет facts dicts → даже если allowlist расширить, render не нашёл бы данных для Golden-rule таблиц.

После TASK 8B (Path 1 horizon extension) sample window достаточен для outer-card loops до SR + 1096d (~3 solar years), что покрывает все Marina-эталонные boundaries новых cases. Это последний implementation TASK Phase 8 — фактически finishing up multi-case calibration started в TASK 7b Stage B.

**TASK 8D — финальный Phase 8 implementation TASK.** После closing + final calibration report verdict update + явный user ack → Phase 8 closes → Recovery program closes finally.

## Stages

### Stage D.1 — Per-case allowlist + facts (5 cases, 20 cards total per audit)

Pre-mapped card counts per case (per user direction 2026-05-14, sourced from Phase 8A audit § A.2 + audit § A.4 item 4):

| Case | Etalon PDF | Expected outer card count |
|------|------------|---------------------------|
| 01-kseniya-2024-2025 | `Соляр 2025-2026.pdf` (case 01 variant) | **5** |
| 02-maksim-2025-2026 | `Соляр 2025-2026 для Максима.pdf` (or analog) | **2** |
| 03-artem-2025-2026 | `Соляр 2025-2026 для Артёма.pdf` (or analog) | **9** |
| 04-valeriya-2025-2026 | `Соляр 2025-2026 для Валерии.pdf` (or analog) | **2** |
| 09-anastasiya-2025-2026 | `Соляр 2025-2026 для Анастасии.pdf` | **2** |
| **Total** | — | **20 outer cards** |

Worker MUST:
- Visually verify exact PDF filename per case (audit report § A.1 inventory has match table; consult).
- Read «Золотое правило транзита» tables from Marina pages directly. **No silent guessing on house numbers.**
- Cite exact Marina page range per card in code comment (e.g. `# Marina <PDF> pp. X-Y — тр Уран в квадрате с нат Луной`).
- In HANDOFF, provide an exact **PDF page → card** mapping table:

  | case | card # | Marina PDF | pages | triple (transit, aspect, target) | golden-rule cells (5) verified |
  |------|--------|------------|-------|----------------------------------|--------------------------------|

For each card:
- Extend `OUTER_CARD_ALLOWLIST["<case-id>"]` с triple.
- Populate `_OUTER_CARD_FACTS[(case, transit, aspect, target)]`: `transit_natal_house`, `target_natal_house`, `transit_ruled_houses`, `target_ruled_houses`, `transit_walks_house` (5 cells from Marina table) + `psychology` + `event_level` (Marina-style paraphrase, не verbatim).

**STOP triggers within Stage D.1:**
- Engine `outer_cards_for_case` returns ≠ expected card count for any case (i.e. fewer triples produce hits than allowlist contains, or unexpected extras) → audit page numbers wrong or fixture mismatch; STOP, escalation.
- Marina page numbers ambiguous (Worker cannot confidently read house numbers from etalon PDF) → STOP, escalation memo, request user clarification per card.

### Stage D.2 — Render verification per case

For each of 01/02/03/04/09:
- Render PDF via `services/api-python/scripts/render_case.py --case-id <case-id> --output /tmp/<case-id>-stage-d.pdf`.
- PDFs stay в `/tmp/` (debug artifacts; **NOT committed** anywhere persistent).
- **Provenance sidecar verification (MANDATORY):**
  - `git_sha == HEAD` (one of the Stage D commits or later; not stale).
  - `extra.case_label == <case-id>` (correct case wiring).
  - `debug == false` (no debug footer in client PDFs).
  - Report verification status per case в HANDOFF.
- Confirm rendered outer cards present per allowlist (count matches Stage D.1 table).
- Visual smoke (PyPDF text extract) for card titles + dates within ±2d of Marina audit § A.2.1 entries.

**STOP triggers within Stage D.2:**
- Sidecar `git_sha` does NOT match HEAD → stale render; re-render after commit.
- Sidecar `case_label` mismatched → wiring bug; STOP, escalation.
- `debug == true` in any sidecar → debug leak risk; STOP, fix render mode.

### Stage D.3 — Test contract extension

Extend `services/api-python/tests/test_multi_case_calibration.py`:
- **D.3.1 — Boundary assertions** (per Phase 8C C.1 helper pattern):
  - Add Marina-listed boundary dates per new card per new case to `MARINA_OUTER_CARD_BOUNDARIES` dict (single SoT, with `# SoT: ... § A.2.1` cross-ref).
  - Per-window start_str + end_str assertions (±2 days date-only).
  - 0 new `tolerance_overrides`. If any window OUT-of-tolerance — STOP, escalation. Phase 8B horizon extension should make all new cases pass cleanly; if not, that's a finding.
- **D.3.2 — Exact title lexical assertions (per user direction 2026-05-14):**
  - Per card, assert rendered card title contains **exact lexical form** of aspect locative, NOT regex `трин\w*` или similar fuzzy match.
  - Specifically: «тригоне» (not «трине»), «секстиле», «квадрате», «соединении», «оппозиции» — exact strings.
  - Rationale: TASK 8B B1 just fixed lexical «трине → тригоне»; pin via exact-string test so future regressions are caught immediately. Generic regex masks lexical regressions.
  - Implementation: per case, parametrized test asserting `assert "в тригоне с" in title` (for Trine cards), `assert "в квадрате с" in title` (for Square cards), etc. Use `in` not `re.match`/`re.search` with wildcard.

Tests should run green at HEAD (no new xfail markers).

### Stage D.4 — Calibration report § 4 update (FULL subsections per user direction 2026-05-14)

Update `transit-multi-case-calibration-report-2026-05-13.md`:
- § 4 TYPE-A item 6 (allowlist gap 01/02/03/04/09) marked `[RESOLVED via TASK 8D]`.
- **§ 3.4-3.8 full subsections per case** (NOT compact additive). Rationale per user direction: compact wording previously hid the Phase 8B boundary gap (TASK 7b closure was premature in part because compact reporting); for 5 new cases pinning explicit § 3.4 case 01, § 3.5 case 02, § 3.6 case 03, § 3.7 case 04, § 3.8 case 09 with structure analogous to existing § 3.1/3.2/3.3:
  - Per case: SR + Marina PDF reference; monthly transit table summary (smoke check, не cell-by-cell — those covered by existing tests); per-house interpretation summary; outer-planet cards table (count + titles + boundaries + golden-rule cells); calendar smoke; verdict per case (matches Marina; partial; documented divergences).
- § 6 verdict update: «Ready for Marina show — pending user ack» (target verdict — все TYPE-A closed-config gaps resolved; TYPE-B no new findings; overrides count unchanged; TYPE-C documented; TYPE-D остаётся data-revision backlog вне Phase 8).

## Files

- modify:
  - `services/api-python/app/pdf/outer_cards.py` — `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` data extends only. **NO def/class changes**, no semantic logic touches.
  - `services/api-python/tests/test_multi_case_calibration.py` — `MARINA_OUTER_CARD_BOUNDARIES` extension + boundary assertions per new case.
  - `project-overlays/astro/STATUS_RU.md` — narrative.
  - `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — § A.4 item 4 [RESOLVED]; § A.2.1 post-fix table extended with new cases (optional — Worker decides).
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 3 / § 4 / § 6 updates.

- new: —

- delete: —

## Do not touch (STRICT scope per user direction 2026-05-14)

- **Haskell core, schema, fixtures, rulesets** — engine output stable; Phase 8B already extended sample horizon, no further engine changes.
- **`services/api-python/app/ephemeris/bridge.py`** — sample horizon parameter at 730 post Phase 8B; no further changes.
- **All product semantic code** (`transit_themes.py`, `rulership_houses.py`, `synthesis_themes.py`, `builder.py`, `provenance.py`, `outer_cards.py` core functions).
- **`outer_cards.py` core functions** `aggregate_display_windows`, `build_outer_card`, `identify_cards_for_case`, `outer_cards_for_case` — data extends only to `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS`.
- **`solar.html.j2`** — template iterates `card.intervals` generically, no semantic change needed.
- **`test_natalya_transits_acceptance.py`** — Phase 4b N-N W1 ±200d override stays; no other test_natalya changes.
- **Existing allowlist entries для 05/08/10** — не менять.
- **Existing facts entries для 05/08/10** — не менять.
- **TYPE-D blockers** (`_3.pdf`, Анастасия) — **NOT in this TASK scope** per user direction 2026-05-14. Separate data-revision backlog.
- **Phase 8B horizon parameter** — already landed at 730; don't tune.
- **TASK 7b/7c/8.0/8A+8C/8B archived files** — historical records.
- **expected.json / input.json fixtures** — already regen'd in TASK 8B; no further regen needed (allowlist + facts are presentation-only, не trigger fixture regeneration).

## Acceptance

### Stage D.1 — Per-case allowlist + facts

- [ ] Cases 01/02/03/04/09 entries in `OUTER_CARD_ALLOWLIST`: **5 + 2 + 9 + 2 + 2 = 20 triples total** (per audit + user pre-mapping).
- [ ] `_OUTER_CARD_FACTS` populated per card with 5 cells + psychology + event_level texts.
- [ ] Marina reference pages cited в code comments (e.g. «pp. X-Y per Соляр 2025-2026_N.pdf»).
- [ ] HANDOFF includes exact **PDF page → card** mapping table per Stage D.1 spec (case / card # / Marina PDF / pages / triple / golden-rule cells verified).
- [ ] **No silent guessing on house numbers** — Worker visually audited Marina «Золотое правило транзита» tables per card.

### Stage D.2 — Render verification

- [ ] Per-case PDFs at `/tmp/<case-id>-stage-d.pdf` exist with correct allowlist outer cards (count matches Stage D.1 table).
- [ ] **Provenance sidecar verification per case (MANDATORY):**
  - `git_sha == HEAD` (one of Stage D commits or later).
  - `extra.case_label == <case-id>`.
  - `debug == false`.
- [ ] Visual smoke (PyPDF text extract) per case: card titles + dates within ±2d of Marina audit § A.2.1.

### Stage D.3 — Test contract extension

- [ ] **D.3.1:** `MARINA_OUTER_CARD_BOUNDARIES` extended per new card per new case (with `# SoT:` cross-ref).
- [ ] **D.3.1:** Boundary assertions added per Phase 8C C.1 helper.
- [ ] **D.3.1:** 0 new `tolerance_overrides`; no new xfail markers.
- [ ] **D.3.1:** All new boundary tests green (per Phase 8B horizon extension covering all Marina dates).
- [ ] **D.3.2:** Exact lexical title assertions added per card (e.g. `assert "в тригоне с" in title` for Trine cards; `assert "в квадрате с" in title` for Square cards). **NOT regex / fuzzy match.**
- [ ] **D.3.2:** Tests for all 20 new cards + sanity for 05/08/10 existing cards (re-asserting lexical on existing cards optional but recommended — Worker decides).

### Stage D.4 — Calibration report update (full subsections)

- [ ] § 4 TYPE-A item 6 marked `[RESOLVED via TASK 8D]`.
- [ ] **§ 3.4-3.8 full subsections per case** (NOT compact additive): one subsection each for case 01, 02, 03, 04, 09 with structure analogous to existing § 3.1/3.2/3.3 (SR + Marina PDF ref + monthly smoke + per-house summary + outer-cards table + calendar smoke + verdict).
- [ ] § 6 verdict: «Ready for Marina show — pending user ack» (with reasoning: all TYPE-A resolved; no TYPE-B; override count = 1 only N-N W1 stays).

### Common

- [ ] `cabal --project-dir core/astrology-hs build`: Up to date (no engine changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: `(221 baseline) + N new boundary tests passed + 0 xfailed + 0 failed`.
- [ ] `git status --short` clean for intended product changes; pre-existing `.claude/scheduled_tasks.lock` allowed.
- [ ] One product commit ideal (data extends + tests in one); justify split if needed.
- [ ] One overlay commit (STATUS_RU + audit + calibration + HANDOFF).
- [ ] Push backup, parity verified.

### Scope discipline (per user direction 2026-05-14)

- [ ] Затронуты: только `outer_cards.py` (ALLOWLIST + FACTS data extend) + `test_multi_case_calibration.py` (boundary tests extend) + overlay docs.
- [ ] **NOT затронуты:**
  - Engine, schema, fixtures, Haskell core — 0 lines.
  - `bridge.py` — 0 lines (no further horizon tuning).
  - All product semantic code outside ALLOWLIST/FACTS data — 0 lines.
  - `test_natalya_transits_acceptance.py` — 0 lines.
  - TYPE-D items (`_3.pdf`, Анастасия) — NOT touched.
  - `solar.html.j2` — 0 lines.
- [ ] No new override mechanisms; no new accepted-divergence classifications.
- [ ] No new helper functions in `outer_cards.py` core.

### STOP triggers

- Any new boundary test fails after Phase 8B horizon extension — means horizon margin insufficient for one of new cases → escalation memo, possibly wider `outer_card_lookahead_days` (but that's NOT this TASK's scope; TASK 8D STOP would be the trigger).
- Marina audit page numbers ambiguous (Worker can't confidently read house numbers from etalon PDF) → STOP, escalation memo, request user clarification per case.
- Worker tempted to fix anything beyond ALLOWLIST/FACTS scope.
- Worker tempted to touch TYPE-D items.
- Worker tempted to extend Phase 4b structured override pattern to any new boundary.

## Context

**Mode normal + Tier C** (closed-config calibration; analogous to TASK 7b Stage B). **Reviewer subagent REQUIRED (narrow-scope) per user direction 2026-05-14** — main risk vector is human error in golden-rule fact transfer across 5 cases × 20 cards × 5 fact cells = 100 manual data points. TL inline-verify on top of Reviewer pass.

**Reviewer narrow scope:**
- Verify each card's 5 golden-rule cells (transit_h, target_h, transit_ruled, target_ruled, walks) match Marina table on cited page (independent visual read).
- Verify card title lexical exactness (assert «тригоне» not «трине» etc.).
- Verify allowlist entry count per case matches Stage D.1 table (5+2+9+2+2 = 20).
- Verify sidecar provenance per case (git_sha + case_label + debug=false).
- Confirm 0 new tolerance_overrides; 0 new xfail markers.
- Pytest independent run.

**Baseline:**
- Product main @ `f667a10` (TASK 8B Path 1 accepted; horizon extended to SR + 1096d).
- Overlay @ TBD post-TASK-8B-closure commit.
- Pytest baseline: `221 passed, 0 xfailed, 0 failed`.
- Cabal build: Up to date.

**Architecture SoT:**
- `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` — recovery program SoT.
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — § A.1 inventory + § A.2.1 boundary SoT + § A.3 classification + § A.4 sub-task proposals.
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — verdict will move to «Ready for Marina show — pending user ack».

**Phase 8 sequence post-TASK-8D:**
- TASK 8.0 — CLOSED (audit trail reopen).
- TASK 8A+8C — CLOSED (audit + test contract).
- TASK 8B — CLOSED (lexical + horizon + unmark + Path 1 reclassification).
- **TASK 8D (this)** — final implementation TASK.
- Recovery program closes after TASK 8D + final user ack on calibration report + Marina framing memo (1 editorial divergence: N-N W1 start).

**Production-readiness gate post-TASK-8D:** «Ready for Marina show — pending user ack» verdict requires:
- All Phase 7 + Phase 8 deliverables landed.
- No TYPE-B.
- Override count ≤ threshold (post-Path-1: 1 override only — N-N W1 start ±200d).
- All TYPE-A closed-config gaps resolved.
- TYPE-C documented.
- TYPE-D остаётся отдельным data-revision backlog (НЕ блокирует Marina show — кейсы `_3.pdf` и Анастасия не в production scope этой программы).
- User explicit ack required for verdict promotion.

**Ready: yes** — flipped 2026-05-14 после user ack + 5 refinements applied:

1. **Reviewer:** REQUIRED (narrow-scope) per user direction; main risk = human error в golden-rule fact transfer across 5 cases × 20 cards × 5 cells.
2. **Pages pre-mapped:** card counts per case (01=5, 02=2, 03=9, 04=2, 09=2 = 20 total); Worker fills exact PDF page → card table в HANDOFF.
3. **PDF artifacts:** `/tmp/` only (not committed); sidecar verification mandatory (`git_sha == HEAD`, `case_label` correct, `debug=false`).
4. **Calibration report:** full § 3.4-3.8 subsections (NOT compact additive); compact previously hid Phase 8B boundary gap.
5. **Acceptance:** exact lexical title assertions added (e.g. `"в тригоне с"`, `"в квадрате с"`) — NOT regex/fuzzy; pin lexical post-TASK-8B fix.

## Closure (2026-05-15, cascade with TASK 8E)

**TASK 8D + TASK 8E closed in cascade per user explicit ack 2026-05-15.** TASK 8D was held in `review` status post-Worker delivery while pre-buffer truncation finding (audit § A.2.1.D, confirmed by external Reviewer 2026-05-15) was resolved via TASK 8E. After TASK 8E Reviewer APPROVE → both closed in single overlay commit.

- **Product commit:** `ce35be1` (TASK 8D Stage D.1-D.4 implementation).
- **Reviewer subagent APPROVE** (2026-05-15, narrow 5-point scope per user direction):
  - 20/20 cards rendered + golden-rule facts not mis-transferred (Reviewer spot-checked 15/20 Marina pages directly).
  - 14 excluded cards: all categories empirically reproduced; no missed-assertion bug.
  - Pre-buffer finding case 01 N-Sun + N-Mars confirmed (SR-540d exactly = engine cutoff; symmetric to TASK 8B Path 1 AFTER-buffer).
  - Product scope clean (2 files: `outer_cards.py` + `test_multi_case_calibration.py`).
  - Pytest 286/0/0 independent run.
- **Pre-buffer finding follow-up:** Resolved via TASK 8E BEFORE buffer extension `540 → 730` (2026-05-15). Case 01 N-Sun W1 16.04.2023 (Δ-1d Marina), N-Mars W1 11.05.2023 (Δ-1d Marina) — both within ±2d.
- **14 excluded cards documented in audit § A.2.1.D — 2 resolved via 8E (case 01 N-Sun + N-Mars), 12 remain as documented future work items** (Pluto display rule, single-window alignment, case 03 P-Mars typo, Анастасия TYPE-D). NOT touched in Phase 8 implementation per user scope discipline.
- **Status: done.** Archive to `project-overlays/astro/TASKS/archive/`.
