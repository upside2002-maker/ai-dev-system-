# HANDOFF: worker → tl — phase-9-2-a-outer-cards-filter-validation

- Status: closed (TL inline-verify + user explicit closure ack 2026-05-18; Stage 0 PASS)
- Date: 2026-05-18 20:37
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-18-phase-9-2-a-outer-cards-filter-validation.md

## Summary

Tier C validation-only memo (Phase 9.2A Stage 0 mandatory gate). Worker empirically validated hypothetical filter `target ∉ {Asc, MC, IC, DC}` against engine outer-card emit sets для всех 10 cases (01 / 02 / 03 / 04 / 05 / 07 / 08 / 09 / 10 / 11-olga) using memo § 1.1 / § 1.2 / § 1.3 inventory + codebase reads of `services/api-python/app/pdf/outer_cards.py` + `core/astrology-hs/src/Domain/TransitCalendar.hs`. **Stage 0 verdict: PASS** — 0 false negatives across 35 Marina-selected cards; angle-exclusion filter does not drop any Marina-selected card. Worker also ran significator-supplement diagnostic (§ 3) which is informational only per user direction; combined rule would drop 3 of 6 Marina cards для Olga (Phase 9.1 family pattern, NOT gate-relevant).

## Done

- New file: `project-overlays/astro/ARCHITECTURE/phase-9-2-a-outer-cards-validation-2026-05-18.md` — validation memo с § 0 framing, § 1 per-case empirical table (10 cases), § 2 aggregate score, § 3 significator-diagnostic (informational), § 4 verdict PASS, § 5 Phase 9.2B implementation TASK draft outline + erratum status (not drafted, per FAIL-only discipline).
- Read-only inspection: `services/api-python/app/pdf/outer_cards.py` (lines 160-254, 271-284, 1388-1390, 1656-1828); `core/astrology-hs/src/Domain/TransitCalendar.hs` (lines 79-94, 624-660).
- Pytest baseline preserved: `372 passed + 2 skipped + 0 failed` (verified post-analysis; no test files written).
- Cabal: Up to date (no Haskell change).
- Product `git status --short`: empty before + after analysis (no product code touched).
- TASK status bumped open → in-progress (pre-work), and updated `STATUS_RU.md` narrative (overlay only).

## Remaining

- TL/user inline-verify validation memo + verdict (Tier C, Reviewer optional per user direction 4).
- If PASS verdict accepted: spawn Phase 9.2B implementation TASK using § 5.1 draft outline (angle-only scope, significator deferred).
- After accept: standard `submit-task.sh` + `accept-task.sh` cascade for этой 9.2A; one overlay commit lands memo + STATUS_RU + HANDOFF; backup push parity verified.

## Artifacts

- branch:               main (product) — untouched; master (overlay) — memo + HANDOFF staged but not yet committed
- commit(s):            none yet — Worker hands off before commit per workflow; commit lands after submit-task gate
- PR:                   not applicable (overlay-only memo)
- tests:                `372 passed + 2 skipped + 0 failed` baseline preserved (no test files written)
- Product repo status:  not applicable — TASK ничего не трогал в product repo (validation-only memo)

## Conflicts / risks

### Stage 0 gate empirical result: PASS

- 0 false negatives across 10 cases / 35 Marina-selected cards. All Marina-selected card targets are non-angle planets (verified by reading `OUTER_CARD_ALLOWLIST` content + memo § 1.1 / § 1.3 inventory).
- Memo § 5.2 verdict «hybrid» not downgraded by Worker. Erratum drafting is FAIL-only per user direction 5; PASS means memo stands.

### Inventory partial-extract note (memo § 1.3 для 11-olga)

- Memo § 1.3 explicitly says «~13 unique aspect triples — partial extract from PDF» with 9 named + ~3-4 unnamed Marina-rejected. Worker validated на 9 named; cannot enumerate unnamed без ad-hoc PDF re-extraction (forbidden per STOP discipline). The unnamed-rejected are by definition Marina-rejected; они add to FP if planet-target or TN if angle-target, but cannot add to FN.
- Effect on gate: **none** (gate is no-FN; unnamed are Marina-rejected by spec).
- Effect on FP count: Olga FP is bounded `1–5` (1 named + 0–4 unnamed depending on target types).

### Significator-supplement diagnostic (§ 3): informational FAIL signal

- Memo § 6 TASK 2 step 2 significator-set definition (Asc-ruler / MC-ruler / 1st-house / Sun-sign / stellium-ruler), combined с outer-outer extension, **drops 3 of 6 Marina-selected cards для Olga** (Уран кв Венера; Уран опп Юпитер; Нептун триг Юпитер).
- This replicates Phase 9.1 over-pruning pattern. **Not gate-relevant** per user direction 2026-05-18 + TASK clarification 3 («Significator-гипотеза пусть будет диагностикой false positives, не основанием молча усложнять фильтр»).
- Worker recommendation per § 5.1: Phase 9.2B implementation TASK ships **angle-only filter**; significator-supplement deferred OR documented as editorial residual in `outer_cards.py` comment. Re-validation gate analogous этой 9.2A required if a future TASK proposes значимый significator rule.

### Scope discipline preserved

- ✓ NO product code modifications.
- ✓ NO test files written or modified.
- ✓ NO `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` entries added.
- ✓ NO `generic_outer_cards` filter logic touched.
- ✓ NO engine / schema / fixtures / PDFs / Jinja templates touched.
- ✓ NO ad-hoc Marina PDF re-extraction.
- ✓ NO «improve» filter proposal to make 10/10 (filter is empirically 10/10 без modification).
- ✓ NO silent significator-set definition adjustment (Phase 9.1 lesson honoured).
- ✓ NO erratum drafted to memo § 5.2 (PASS verdict; erratum only on FAIL per user direction 5).

### Erratum draft text (NOT applicable, PASS verdict)

Per user direction 5 + TASK Stage 0 stop discipline: «if Stage 0 PASS → Worker writes validation memo + Phase 9.2B implementation TASK draft outline; NO erratum draft. If Stage 0 FAIL → Worker drafts erratum в HANDOFF (not lands в memo himself)». Stage 0 = PASS ⇒ this section intentionally left empty. No erratum text required.

## Next step

1. **TL inline-verify** validation memo (Tier C, Reviewer not required per user direction 4 + TASK section «Reviewer subagent — OPTIONAL»).
2. **TL/user ack** verdict PASS + § 5.1 Phase 9.2B implementation TASK draft outline.
3. **If accepted:** Worker runs `submit-task.sh` (open→review) → TL runs `accept-task.sh` (review→done) → archive TASK + commit overlay (memo + STATUS_RU + HANDOFF in one commit) + push backup, verify parity.
4. **Then:** TL spawns Phase 9.2B implementation TASK using § 5.1 draft outline (Tier B; 1 file modification + 1-2 tests; angle-only scope; significator deferred).

If verdict OR scope contested at inline-verify — Worker available для clarifications via this HANDOFF.
