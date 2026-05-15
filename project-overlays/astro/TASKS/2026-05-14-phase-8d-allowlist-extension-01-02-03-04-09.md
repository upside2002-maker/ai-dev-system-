# TASK: phase-8d-allowlist-extension-01-02-03-04-09

- Status: open
- Ready: no
- Date: 2026-05-14
- Project: astro
- Layer: services (Python presentation only — closed-config additions)
- Risk tier: C (allowlist data + facts + tests; analogous to TASK 7b Stage B closed-config calibration pattern)
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

### Stage D.1 — Per-case allowlist + facts (5 cases)

For each of cases 01/02/03/04/09:
- Extend `OUTER_CARD_ALLOWLIST["<case-id>"]` с N triples (per Marina audit § A.2 inventory).
- Populate `_OUTER_CARD_FACTS` per card: `transit_natal_house`, `target_natal_house`, `transit_ruled_houses`, `target_ruled_houses`, `transit_walks_house`, `psychology`, `event_level` (Marina-style paraphrase, не verbatim).
- Marina reference pages — TBD from audit § A.2.1 / § A.4 per-case page numbers. Worker reads etalon PDFs visually + audit table.

Worker MUST audit-read each etalon PDF before adding facts. **No silent guessing on house numbers** — Worker reads «Золотое правило транзита» tables from Marina pages directly.

### Stage D.2 — Render verification per case

For each of 01/02/03/04/09:
- Render PDF via `services/api-python/scripts/render_case.py --case-id <case-id> --output /tmp/<case-id>-stage-d.pdf`.
- Verify provenance sidecar `git_sha` matches HEAD (one of the Stage D commits).
- Confirm rendered outer cards present per allowlist.
- Visual smoke (PyPDF text extract) for card titles + dates within ±2d of Marina audit § A.2.1 entries.

### Stage D.3 — Test contract extension

Extend `services/api-python/tests/test_multi_case_calibration.py` boundary assertions:
- Per Phase 8C pattern: add Marina-listed boundary dates per new card per new case to `MARINA_OUTER_CARD_BOUNDARIES` dict (single SoT, with `# SoT: ... § A.2.1` cross-ref).
- Per-window start_str + end_str assertions (±2 days date-only, per Phase 8C C.1 helper).
- 0 new `tolerance_overrides`. If any window OUT-of-tolerance — STOP, escalation. Phase 8B horizon extension should make all new cases pass cleanly; if not, that's a finding.

Tests should run green at HEAD (no new xfail markers).

### Stage D.4 — Calibration report § 4 update

Update `transit-multi-case-calibration-report-2026-05-13.md`:
- § 4 TYPE-A item 6 (allowlist gap 01/02/03/04/09) marked `[RESOLVED via TASK 8D]`.
- New § 3.X subsections per new case if Worker decides (analogous to existing § 3.1, 3.2, 3.3 for 05/07/10) — or single appended § 3.4-3.8 block, Worker chooses minimal-additive approach.
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

- [ ] Cases 01/02/03/04/09 entries in `OUTER_CARD_ALLOWLIST` (N triples each per audit).
- [ ] `_OUTER_CARD_FACTS` populated per card with 5 cells + psychology + event_level texts.
- [ ] Marina reference pages cited в code comments (e.g. «pp. X-Y per Соляр 2025-2026_N.pdf»).

### Stage D.2 — Render verification

- [ ] Per-case PDFs at `/tmp/<case-id>-stage-d.pdf` exist with correct allowlist outer cards.
- [ ] Provenance sidecar `git_sha` matches Stage D commit HEAD.

### Stage D.3 — Test contract extension

- [ ] `MARINA_OUTER_CARD_BOUNDARIES` extended per new card per new case (with SoT cross-ref).
- [ ] Boundary assertions added per Phase 8C C.1 helper.
- [ ] 0 new `tolerance_overrides`; no new xfail markers.
- [ ] All new boundary tests green (per Phase 8B horizon extension covering all Marina dates).

### Stage D.4 — Calibration report update

- [ ] § 4 TYPE-A item 6 marked `[RESOLVED via TASK 8D]`.
- [ ] § 3 extended with new cases (or compact additive block).
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

**Mode normal + Tier C** (closed-config calibration; analogous to TASK 7b Stage B). Reviewer subagent optional (Tier C). TL inline-verify acceptable.

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

**Ready: no** — TL flips after user ack on TASK 8D spec + any refinements.
