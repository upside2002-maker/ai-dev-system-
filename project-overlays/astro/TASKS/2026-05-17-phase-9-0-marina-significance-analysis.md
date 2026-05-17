# TASK: phase-9-0-marina-significance-analysis

- Status: review
- Ready: yes
- Date: 2026-05-17
- Project: astro
- Layer: overlay (analytical memo deliverable only — NO code, NO data, NO PDF changes)
- Risk tier: C (memo-only, analytical; Reviewer optional)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Post-recovery follow-up cycle (api-pdf-endpoint + directions-show-all-active + transit-section-generic-output) исправил «hidden important» баги. Но pendulum инвертировался: теперь PDF для non-calibrated клиентов (e.g. Ольга consultation 11) показывает **всё активное вместо Marina-significant subset**.

Reference data for Ольга consultation 11 (`/Users/ilya/Downloads/solar-11.pdf`, 28 pages, our output):
- **Directions:** 9 эмиттировано, Marina выбрала 4 (MC 90 Asc, MC 120 Уран, Солнце 60 Asc, Сатурн 150 Марс).
- **Outer cards:** 13 эмиттировано, Marina выбрала 6 (Уран кв Венера / Уран опп Уран / Уран опп Юпитер / Нептун триг Юпитер / Нептун триг Уран / Плутон секст Уран).
- **Touch intervals:** Marina показывает 1 specific touch per card (e.g. Уран кв Венера: 02.12.2026–15.04.2027), мы показываем все 3 loop touches.
- **Summary themes:** Marina centers around партнерство / 5-11 ось / дом+семья / 9 дом; наш summary generic.

### Phase 4a precedent (critical context)

Phase 4a memo (2026-05-13, archived) tested 4 hypotheses on Marina window BOUNDARIES across 3 examples — H1 tight orb, H2 anchored half-width, H3 drift skip, H4 editorial/non-deterministic. Killer evidence: N-J W1 и N-N W1 morphologically identical но Marina draws differently. Conclusion: H4 (editorial). Path 4 chosen: structured exceptions per case (allowlist + curated facts), NOT generic rule. Same family question now arises для significance selection: deterministic-rule OR editorial?

### 4 sub-problems (may have different rule structures)

1. **Active directions selection.** Why Marina picks 4 of N engine-emitted active directions?
2. **Outer-card selection.** Why Marina picks M of generic-detected outer-aspect candidates?
3. **Touch-interval selection.** Why Marina shows 1 of K loop touches per card?
4. **Summary thematic selection.** Why Marina centers summary on specific themes (e.g. 5-11 axis for Ольга)?

Different sub-problems may follow different rules — some deterministic, some editorial, some hybrid.

## Worker framing (verbatim from user direction 2026-05-17)

> **Не чинить в этом TASK ничего. Никаких allowlist для Ольги, никаких heuristic filters, никаких изменений PDF. Только memo и рекомендации.**

> **Прогноз:** directions могут оказаться hybrid/deterministic, outer cards и intervals — hybrid/editorial, summary почти точно editorial. **Но это надо доказать на данных, а не ощущением.**

## Reference data

**10 cases для empirical analysis:**

| Case | Calibrated? | Marina-reference PDF | Engine output |
|---|---|---|---|
| 01-kseniya | ✓ | `/Users/ilya/Downloads/Gmail (3)/...` | fixture |
| 02-maksim | ✓ | `/Users/ilya/Downloads/Gmail (3)/...` | fixture |
| 03-artem | ✓ | `/Users/ilya/Downloads/Gmail (3)/...` | fixture |
| 04-valeriya | ✓ | `/Users/ilya/Downloads/Gmail (3)/...` | fixture |
| 05-ekaterina | ✓ | `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_2.pdf` | fixture |
| 07-mariya | ✓ | `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_4.pdf` | fixture |
| 08-natalya | ✓ | `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` | fixture |
| 09-anastasiya | ✓ | `/Users/ilya/Downloads/Gmail (3)/...` | fixture (TYPE-D mismatch noted) |
| 10-danila | ✓ | `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026 для Данилы.pdf` | fixture |
| **11-olga (consultation 11)** | **NO** | **`/Users/ilya/Downloads/Соляр 2026-2027 (1).pdf`** (per user direction 2026-05-17) | DB consultation_id=11; current script output для compare: `/Users/ilya/Downloads/solar-11.pdf` |

Worker first reads Phase 8A audit § A.1 inventory table for confirmed Marina-PDF → fixture mapping. For Ольга consultation 11 — Marina-reference path is **out-of-scope-default**; Worker requests path from TL via STOP+escalation if not pre-provided.

## Stages

### Stage 9.0.1 — Reference inventory + Marina-selected extractions

Per case, Worker extracts Marina's selected items via Marina-reference PDF read:

- **Directions:** list 4-N Marina-shown directions per «Дирекции» section.
- **Outer cards:** list 3-N Marina-shown cards per «Транзиты высших планет» section.
- **Touch intervals:** per outer card, list Marina's specific window(s).
- **Summary themes:** extract key themes from Marina's «Итоги консультации» section.

Output: structured table в memo § 1 (one row per Marina selection per case).

Engine-emitted side (для сравнения):
- Allowlist + facts data для 9 calibrated cases ↔ Marina-shown (these MATCH by definition — allowlist уже представляет Marina-curated set).
- Generic-fallback output для Ольга consultation 11 (28 pages, 9 dirs + 13 cards + multi-touch intervals).

### Stage 9.0.2 — Per-sub-problem diff tables (4 tables × 10 cases = 40)

Per case × per sub-problem:

| Engine emitted | Marina selected | In-Marina? | Why? (hypothesis-fitting) |
|---|---|---|---|
| ... | ... | ✓ / ✗ | ... |

Output: memo § 2.1 (directions), § 2.2 (outer cards), § 2.3 (intervals), § 2.4 (summary).

### Stage 9.0.3 — Hypothesis testing per sub-problem

Per sub-problem, test 4-6 hypotheses against the 10-case dataset:

**Directions hypotheses (test set):**
- H1: «involvement of Asc/MC/1st-house elements» (engine breadth criterion).
- H2: «luminary or angle priority» (target = Sun/Moon/Asc/MC).
- H3: «aspect type priority» (hard vs soft; or major-only).
- H4: «overlap with solar year» (enter_jd ∈ [sr_jd, sr_jd + 365.25]).
- H5: «target house / ruled houses relevance to consultation goals».
- H6: «duplicated theme confirmation» (direction reinforces signal from transits/progressions).
- Worker may propose additional hypotheses based on observed pattern.

**Outer cards hypotheses (test set):**
- H1: «orb tightness» (smaller orb → more likely selected).
- H2: «target = significator» (Sun, Moon, ruler of Asc/1st/4th/7th/10th).
- H3: «SR chart angles/luminaries involvement».
- H4: «aspect type priority» (Marina prefers hard aspects?).
- H5: «multi-stream theme confirmation» (parallel direction signal на ту же тему).
- H6: «editorial choice based on client goals» (default-non-deterministic H4 от Phase 4a).

**Touch intervals hypotheses (test set):**
- H1: «touch overlapping SR year» (touch start или end в [sr_jd, sr_jd + 365.25]).
- H2: «touch overlapping SR year midpoint ±60d».
- H3: «strongest/tightest touch» (smallest orb across all touches).
- H4: «first touch in petal» (chronologically first).
- H5: «touch closest to natal aspect partile» (target planet exact aspect).
- H6: «editorial choice» (H4 default).

**Summary themes hypotheses (test set):**
- H1: «highest signal count» (theme with most input signals across all streams).
- H2: «5-11 axis» (relationships+social) — **case-specific hypothesis** (per user direction 2026-05-17: «оставь, но пометь как case-specific, не как универсальную аксиому. Worker должен проверять, повторяется ли это в других кейсах»). NOT axiom; if H2 fits только Ольга и 0-2 calibrated cases → не general rule.
- H3: «consultation goal alignment» (client's stated questions in request_note).
- H4: «5/7/10 dom-stack priority» (creative/partnership/career as central solar themes).
- H5: «cross-stream confirmation» (direction + transit + progression all touch same house).
- H6: «editorial» (H4 default).

### Stage 9.0.4 — Hypothesis scoring per sub-problem

Per hypothesis × per sub-problem:

```
Hypothesis H_i:
  Fits N/10 cases (with full Marina-match prediction)
  False positives count (predicted ∈ Marina-selected but excluded by Marina)
  False negatives count (Marina-selected but predicted excluded)
  Breaker examples: 1-2 cases where hypothesis fails clearly + why
```

Score table в memo § 3.

### Stage 9.0.5 — Per-sub-problem verdict + recommendation

Per sub-problem (directions / cards / intervals / summary):

**Verdict classification:**
- **`deterministic`** — single hypothesis fits 9+/10 cases с ≤ 1 FP/FN. Recommended: implement filter as TASK.
- **`editorial`** — best hypothesis fits ≤ 5/10. Killer evidence (morphologically identical cases где Marina differs). Recommended: structured exceptions per case (allowlist extension Phase 8D-style).
- **`hybrid`** — deterministic pre-filter (e.g. «include all touching Asc/MC + filter the rest editorially») fits N/10 with explicit editorial overrides. Recommended: filter + override mechanism.
- **`insufficient data`** — Marina-reference incomplete OR fewer than 7/10 analyzable cases. Recommended: gather more data; defer.

### Stage 9.0.6 — Recommended next TASKs

Per sub-problem (4 sub-problems = up to 4 next-TASK proposals):
- Deterministic-verdict → propose: Phase 9.X-filter-implementation TASK (target file: where filter lives — `transit_themes.py` / `outer_cards.py` / новый).
- Editorial-verdict → propose: Phase 9.X-allowlist-extension TASK (per-case curation).
- Hybrid-verdict → propose: Phase 9.X-hybrid TASK (filter + override).
- Insufficient-data → propose: data-gathering preceding TASK.

Output: memo § 5 «Recommended Next Steps» как numbered TASK proposals для TL/user review.

## Stage 0 — Marina-reference path resolution

**Before Stage 9.0.1:** Worker checks Marina-reference path для Ольга consultation 11. Likely candidates:
- `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026 для Ольги.pdf` (or similar Russian-language filename).
- User-provided path в HANDOFF / TASK description.

If accessible — proceed. If not — **STOP**, escalation memo, request path from TL.

## Files

- new:
  - `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` (memo, ~500-1000 lines depending on case detail).

- modify:
  - `project-overlays/astro/STATUS_RU.md` — narrative update.

- delete: —

- **DO NOT modify any product code, allowlist data, fixtures, tests, schema, PDFs.**

## Do not touch

- **All product code** (`services/api-python/app/*`, `core/astrology-hs/*`, `apps/web-react/*`).
- **`OUTER_CARD_ALLOWLIST` data** — DO NOT add entries for Ольги or any non-calibrated person.
- **`_OUTER_CARD_FACTS`** — no new entries.
- **`solar.html.j2` template** — no changes.
- **Engine code, schema, fixtures.**
- **Tests** — no new или modified test files.
- **PDF files** — no rendering, no PDF artifacts beyond reading Marina-reference for analysis.
- **Phase 8 archived TASKs** — historical record.
- **Marina framing memo** — separate artifact.
- **Previous TASK closures** (api-pdf-endpoint, directions-show-all-active, transit-section-generic-output) — already closed.

## Acceptance

### Primary

- [ ] Memo file `marina-significance-selection-analysis-2026-05-17.md` created.
- [ ] § 1 reference inventory: Marina-selected items per 10 cases listed (4 streams × 10 cases = 40 lists; Ольга dependent on Stage 0 success).
- [ ] § 2 diff tables: 4 sub-problems × 10 cases.
- [ ] § 3 hypothesis testing: 4-6 hypotheses per sub-problem × scoring on 10 cases.
- [ ] § 4 verdict per sub-problem: `deterministic` / `editorial` / `hybrid` / `insufficient data`.
- [ ] § 5 recommended next TASKs: 4 numbered proposals.
- [ ] One overlay commit; push backup; parity verified.
- [ ] **NO product code changes; NO allowlist additions; NO PDF artifacts.**

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: **368 passed + 2 skipped + 0 failed baseline preserved (no test changes)**.
- [ ] Product `git status --short` clean (no product code touched).

### STOP triggers

- Worker tempted to write code, add allowlist entries, modify PDFs → STOP, reread «memo-only».
- Marina-reference для Ольги недоступен → STOP at Stage 0, escalation memo с request.
- Fewer than 7 cases analyzable (e.g. Marina-reference PDFs missing) → STOP, partial memo + flag для user; Worker reports which cases incomplete.
- Hypothesis scoring incomplete (e.g. only 2 hypotheses tested vs spec'd 4-6) → STOP, finish before submission.

## Reviewer subagent — OPTIONAL

Tier C memo-only. Reviewer not required; TL inline-verify acceptable (TL reads memo, checks methodology + verdicts).

If Worker prefers Reviewer pass — может spawn'нуть post-completion. Не блокер.

## Context

**Mode normal + Tier C memo-only.** Worker mode: analytical-thinking-heavy. Tools used: Read (Marina PDFs), Bash (engine output via fixture inspection / API queries), Edit/Write (memo authoring only).

**Baseline:**
- Product main @ `aca694b` (post 3-follow-up TASKs closed).
- Overlay master @ `0e90b7d` (TASK B closure).
- Pytest baseline: `368 passed + 2 skipped + 0 failed` — must be preserved (no test changes in this TASK).
- Cabal: clean.

**Risk class:**
- Same family as Phase 4a memo (analytical, hypothesis testing).
- Cost: 1 Worker session, ~3-6 hours analytical work depending on data accessibility.
- Output is **decision input для next TASKs**, не implementation.

**Cross-references for Worker:**
- Phase 4a precedent: `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` (analytical-memo template; H1-H4 hypothesis pattern).
- Phase 8 audit memo: `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` (multi-case audit pattern).
- Calibration report: `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (per-case structure).
- Allowlist entries (Marina's curated set proof for 9 calibrated cases): `services/api-python/app/pdf/outer_cards.py:OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS`.

**Not in scope (explicit):**
- Any product code modification.
- New allowlist entries OR fact populations.
- New tests.
- PDF rendering или artifacts.
- Implementation work — that's next-TASK-after.
- Specific case rendering / fixture changes.

**Ready: yes** — flipped 2026-05-17 after user ack + 3 substantive clarifications:

1. **Marina-reference для Ольги:** `/Users/ilya/Downloads/Соляр 2026-2027 (1).pdf` (per user direction). Script result для compare: `/Users/ilya/Downloads/solar-11.pdf`. Stage 0 path resolution: путь pre-provided; no STOP required.

2. **H2 «5-11 axis»** в Summary hypotheses помечен **case-specific**, не universal axiom. Worker должен testить, повторяется ли pattern в других calibrated cases. Если H2 fits only Ольга + 0-2 others → не general rule.

3. **Reviewer optional:** TL inline-verify acceptable. Если вывод спорный — отдельный Reviewer можно поднять после.

**Scope discipline confirmed:** «Никаких code changes, allowlist entries, PDF fixes, даже obvious quick wins. Только memo, scoring, verdict, next TASK proposals.»
