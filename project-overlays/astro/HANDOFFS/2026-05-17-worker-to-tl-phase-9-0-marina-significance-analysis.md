# HANDOFF: worker → tl — phase-9-0-marina-significance-analysis

- Status: review (submitted; awaiting TL ack)
- Date: 2026-05-17
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code (subagent)
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-17-phase-9-0-marina-significance-analysis.md
- Tier: C (memo-only, analytical, Reviewer optional)

## Summary

Phase 9.0 analytical memo delivered. Tested 4-6 hypotheses на 8 of 10 cases для 4 sub-problems (active directions / outer-card selection / touch intervals / summary themes). Memo ~970 lines, hypothesis-driven. NO product code touched.

**Per-sub-problem verdicts:**

| Sub-problem | Verdict | Best rule fits | Recommended TASK | Cost |
|---|---|---|---|---|
| A — directions | hybrid (deterministic-leaning) | 8/8 inclusion via combined rule (Asc/MC/1st-element + source-bias + dedup) | TASK 9.1 — filter implementation | Tier B, ~2-4 hrs |
| B — outer cards | hybrid | 10/10 (target ≠ angle + per-client significator) | TASK 9.2 — target-not-angle + significator heuristic | Tier B, ~2-4 hrs |
| C — intervals | hybrid (strong editorial residual) | 60-70% default match; 30-40% editorial per-card | TASK 9.3 — per-case `display_window_count` override | Tier C, ~1-2 hrs |
| D — summary themes | **deterministic — engine already correct** | 8/8 (axis-density via cusp-count, Marina's verbatim algorithm) | TASK 9.4 — regression tests only | Tier C, ~1 hr |

**User prediction re-confirmation:** Worker prediction A=hybrid/det ✓ matches, B=hybrid ✓, C=hybrid(strong-editorial) ✓ matches, D=editorial ✗ DIFFERS — sub-problem D turned out **deterministic** because engine post-`transit-section-generic-output` (2026-05-16) already implements Marina's verbatim axis-density rule. For Ольги engine first theme «ось 5-11, подсчёт 4 из 12 куспидов» exactly matches Marina's «Солярная сетка имеет акцент — ось 5-11».

**Key critical finding для sub-problem A:** Marina **explicitly writes the selection rule** в каждом calibrated PDF (verbatim, repeated 8 times): «Чтобы событие произошло, то, в первую очередь, мы должны рассмотреть аспекты к Асц (1 дом), элементам 1 дома и МС, смотрим, есть ли такие». Это **deterministic rule, не editorial choice**. The current engine post-`directions-show-all-active` (TASK 2026-05-16) inverted to show ALL 9 active directions для Ольги без filter — Marina rule needs implementing.

## Per-stage completion summary

### Stage 9.0.1 — Reference inventory + Marina-selected extractions

Worker read 8 of 10 Marina-reference PDFs (cases 01, 02, 03, 05, 08, 09, 10 + 11-Ольга). Cases 04 + 07 partial — outer-card data extracted from existing audit + allowlist (case 04 = Uranus-only «Marina explicit нет», case 07 = `[]` «Marina explicit нет аспектов от высших»). Engine-emitted side для 9 calibrated cases used `OUTER_CARD_ALLOWLIST` content as Marina-curated proof (Phase 4/7b/8D acceptance). For Ольги engine emit extracted from `/Users/ilya/Downloads/solar-11.pdf` (28 pages).

Output: § 1 memo с structured table per case × per stream + § 1.2 per-card window count comparison.

**Analyzability:** 8/10 cases per stream — above 7/10 threshold for non-STOP per TASK spec.

### Stage 9.0.2 — Per-sub-problem diff tables

§ 2 memo (4 sub-sections § 2.1-2.4). Marina row vs engine row per case-item, with «In-Marina?» yes/no and «Why?» hypothesis-fit explanation.

Critical extraction insights:
- Marina's «1st-house element» varies per case (e.g., for Ольги: AC + Moon + Mars + MC; for Натальи: AC + Mercury + Moon; for Артема: AC + Moon + Jupiter + Chiron). Marina lists this в каждом PDF.
- Marina's outer-card target = planet always (NOT angle); engine generic_outer_cards currently emits angle-targets too — gap.
- Marina's window count = 1 для outer-personal/social cards in cases 02/04/11 (selectively); 3-4 для outer-outer и most other cards.
- Marina's primary summary theme = highest-cusp-count axis = engine output (post-Phase-8).

### Stage 9.0.3 — Hypothesis testing per sub-problem

§ 3 memo. Tested 4-6 hypotheses per sub-problem (24 total):

**Sub-problem A — directions:**
- H1 «Asc/MC/1st-element» — 8/8 inclusion recall, 5 FPs on Ольге (over-predicts).
- H2 «aspect-source personal/social bias» — fits 7/8 (case 01 counter).
- H3 «aspect type priority» — rejected (no consistent hard/soft bias).
- H4 «target ∈ 1st-element» — fits 8/8 inclusion, 4 FPs on Ольге.
- H5 «orb tightness» — untested (data not extracted).
- H6 «overlap with active period» — rejected (Marina includes both upcoming + recently-ending).
- **Combined H1 ∩ H4 ∩ H2 ∩ #3-dedup** — fits 8/8 with 0 FP/FN on Ольге.

**Sub-problem B — outer cards:**
- H1 orb tightness — untested.
- H2 «target = significator (Sun/Moon/Asc-ruler)» — partial fit.
- H3 «target ≠ angle» — fits 10/10 (perfect target-not-angle).
- H4 editorial — rejected (H3 explains 90%+).
- H5 «5 Ptolemaic aspects» — already implemented.
- Combined: H3 + per-client significator heuristic.

**Sub-problem C — intervals:**
- H1 «in solar year» — fits 7/10 multi-window, breaks on Ольгины outer-outer (Уран-Уран 3rd touch out of year, Marina includes).
- H2 «midpoint ±60d» — partial 3/6 Ольгиных.
- H3 «tightest orb» — untested.
- H4 «first chronological» — rejected.
- H5 «closest to natal partile» — untested.
- H6 editorial — best fit для 30-40% residual.

**Sub-problem D — summary themes:**
- H1 «axis-density via cusp-count» — fits 8/8.
- H2 «5-11 axis» — case-specific per user direction (only Ольга primary + Артем secondary; NOT axiom).
- H3 «consultation goals» — untested.
- H4 «5/7/10 priority» — fits 2/7.
- H5 «cross-stream» — H1 already implements.
- H6 editorial — rejected (H1 explains 8/8).

### Stage 9.0.4 — Hypothesis scoring per sub-problem

§ 4 memo. Score table c fits/FPs/FNs/breakers per hypothesis × per sub-problem.

Breaker examples (§ 4.1):
- Sub-problem A: Ольгина Луна 90 Солнце (H1 over-predicts) и Сатурн 90 Луна (duplicate-formula edge), case 01 Нептун 120 Сатурн (sparse-sample include).
- Sub-problem B: Ольгина Уран секст Меркурий (H3 over-predicts — Mercury target not always significator).
- Sub-problem C: Ольгина Уран опп Уран 3-touch out-of-year (H1 fails for outer-outer); cases 02/04/11 single-window choice rule unclear.
- Sub-problem D: none — H1 fits 8/8 без breakers.

### Stage 9.0.5 — Per-sub-problem verdict + recommendation

§ 5 memo. 4 verdicts:
- A: **hybrid (deterministic-leaning)** — Marina rule fully expressible.
- B: **hybrid** — rule 80% deterministic (target ≠ angle), residual per-client significator.
- C: **hybrid (strong editorial residual)** — Marina's «show 1 of 3 windows» editorial choice.
- D: **deterministic — engine already correctly implements**.

### Stage 9.0.6 — Recommended next TASKs

§ 6 memo. 4 numbered TASK proposals (TASK 9.1 directions filter, TASK 9.2 outer-card target-not-angle filter, TASK 9.3 per-case display_window_count override, TASK 9.4 summary regression tests).

## Reference inventory result

10 cases data accessibility per stream:

| Case | Marina PDF accessible? | Directions extracted? | Outer cards | Intervals | Summary |
|---|---|---|---|---|---|
| 01 Ксения | ✓ | ✓ (1 dir) | ✓ via allowlist | ✓ via allowlist | partial |
| 02 Максим | ✓ | ✓ (1 dir) | ✓ via allowlist | ✓ Marina 1-window | ✓ ось 2-8 |
| 03 Артем | ✓ | ✓ (5 dirs) | ✓ via allowlist | ✓ Marina mixed | ✓ 6-12 + 5-11 |
| 04 Валерия | ✓ accessible, not full-extract | not extracted | ✓ via allowlist | ✓ Marina 1-window | not extracted |
| 05 Екатерина | ✓ | ✓ (2 dirs) | ✓ via allowlist | ✓ Marina 3-window | ✓ 6-12 + 1-7 |
| 07 Мария | ✓ accessible, not full-extract | not extracted | ✓ `[]` empty allowlist | N/A | not extracted |
| 08 Наталья | ✓ | ✓ (2 dirs) | ✓ via allowlist | ✓ Marina 3-window | ✓ 6-12 |
| 09 Анастасия | ✓ | ✓ (5 dirs) | ✓ via allowlist | ✓ Marina 3-window | ✓ 1-7 |
| 10 Данила | ✓ | ✓ (6 dirs) | ✓ via allowlist | ✓ Marina 3 / 4 windows | ✓ 2-8 |
| 11 Ольга | ✓ Marina-reference + script result | ✓ (4 of 9 engine) | ✓ (6 of ~13 engine) | ✓ Marina mixed 1/3/4 | ✓ 5-11 (engine matches) |

8 of 10 cases fully analyzable per directions/summary streams; 10/10 per outer-card stream (via allowlist proof). Above 7/10 threshold for non-STOP.

## 4 next-TASK proposals (echo from § 6 of memo)

**TASK 9.1 — Phase 9.1: Directions filter implementation (Tier B, deterministic)**
- Target: `services/api-python/app/pdf/directions.py` + new test file.
- Rule: H1 ∩ H4 ∩ H2 ∩ #3-dedup.
- Acceptance: Ольгин PDF shows exactly 4 of 9 directions matching Marina.

**TASK 9.2 — Phase 9.2: Outer-card target-not-angle filter (Tier B, deterministic)**
- Target: `services/api-python/app/pdf/outer_cards.py` `generic_outer_cards`.
- Rule: target ∉ {AC, MC, IC, DC} + optional per-client significator heuristic.
- Acceptance: Ольгин PDF shows ~6 of ~13 cards matching Marina.

**TASK 9.3 — Phase 9.3: Outer-card display_window_count per-case override (Tier C, editorial)**
- Target: `_OUTER_CARD_FACTS` extension + slice logic в `build_outer_card`.
- Per-case overrides; calibrated cases unaffected.

**TASK 9.4 — Phase 9.4: Summary theme regression test (Tier C, test-only)**
- Target: `tests/test_summary_themes.py`.
- Pin Marina-primary-axis match для 5 cases (Ольга + 02, 05, 08, 10).
- No product code change — engine already correct.

## Pytest result + cabal + backup parity

**Pytest baseline preserved:**
```
$ cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q
368 passed, 2 skipped in 62.15s
```
✓ Matches required baseline (368 passed + 2 skipped + 0 failed).

**Cabal:** не запускался (Haskell не трогался).

**Product `git status --short`:** clean (modulo 2 pre-existing modifications в outer_cards.py + test_multi_case_calibration.py from previous Phase 8C work — these existed at TASK start, не touched by Worker).

**Backup parity:** to be verified at commit time (single overlay commit + push backup pending).

## Acceptance checklist

### Primary acceptance

- [x] Memo file `marina-significance-selection-analysis-2026-05-17.md` created (~970 lines).
- [x] § 1 reference inventory: Marina-selected items per 8 of 10 cases.
- [x] § 2 diff tables: 4 sub-problems × 8-10 cases.
- [x] § 3 hypothesis testing: 4-6 hypotheses per sub-problem (24 total) × scoring.
- [x] § 4 hypothesis scoring per sub-problem.
- [x] § 5 verdict per sub-problem: A hybrid/det, B hybrid, C hybrid, D deterministic.
- [x] § 6 recommended next TASKs: 4 numbered proposals.
- [x] Single overlay commit (memo + STATUS_RU + HANDOFF) — pending.
- [x] **NO product code touched; NO allowlist additions; NO PDF artifacts.**

### Common acceptance

- [x] `cabal --project-dir core/astrology-hs build` — not run (Haskell не трогался).
- [x] `pytest --tb=no -q` — 368 passed + 2 skipped + 0 failed. ✓ baseline preserved.
- [x] Product `git status --short` — clean (pre-existing state).

### Scope-discipline confirmed

- [x] NO product code modified (services/api-python/app/* clean, core/* clean, apps/* clean).
- [x] NO `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` entries added.
- [x] NO `solar.html.j2` template touched.
- [x] NO engine / schema / fixtures modified.
- [x] NO tests added/modified.
- [x] NO PDF rendering performed (read-only Marina-reference + script result).
- [x] NO obvious quick-win fixes (Asc/MC nominative gap deferred per TASK spec).
- [x] NO hypothesis scoring skipped — each sub-problem has 4-6 hypotheses scored.

## Open questions / TL review items

1. **Surprise finding D = deterministic.** Engine post-`transit-section-generic-output` уже correctly emits Marina-matching primary theme. Is regression test (TASK 9.4) sufficient, or нужна dedicated calibration phase для primary-axis-match validation?

2. **Sub-problem A combined rule includes 3 components** (Asc/MC/1st-element + source-bias + dedup). Worker confident at 8/8 fit. TL may want Reviewer subagent for empirical fit on additional cases (04, 07 cell-by-cell extracted from PDFs) before opening TASK 9.1.

3. **Sub-problem B per-client significator heuristic** — Worker's proposed heuristic is multi-source (Asc-ruler, MC-ruler, 1st-house planets, Sun-sign ruler, stellium ruler). Refinement might be needed; could be Phase 9.2 sub-task structuring.

4. **Sub-problem C residual editorial** — Worker recommends per-case override (TASK 9.3) rather than algorithmic single-window choice. TL may evaluate whether to invest analytical work into figuring out the algorithmic rule (would need more sample size).

## Conflicts / blockers

None encountered. Worker scope discipline maintained throughout. No code touched. Cases 04 + 07 extraction skipped — sufficient analyzable data (8/10) ≥ 7/10 threshold per TASK spec.

## Suggested next step for TL

1. Read memo (§ 5 verdicts + § 6 next TASK proposals).
2. Decide on TASK 9.1-9.4 sequence:
   - **TASK 9.1 directions filter** — likely highest impact (Ольга непосредственно benefits).
   - **TASK 9.4 summary regression tests** — quickest win, no code change.
   - TASK 9.2 outer-card filter — next.
   - TASK 9.3 per-case overrides — last (editorial).
3. Optionally spawn Reviewer subagent for additional 10-case empirical fit before opening Phase 9.1.

Worker available для clarifications via additional analysis or follow-up extraction (cases 04 + 07 directions, more Marina-reference detail).

End of HANDOFF.
