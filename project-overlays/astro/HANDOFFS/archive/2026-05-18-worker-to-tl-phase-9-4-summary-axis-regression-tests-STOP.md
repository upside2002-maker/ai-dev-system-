# HANDOFF: Worker → TL — Phase 9.4 Summary Axis Regression Tests — **STOP** (escalation)

- Status: OPEN — Worker STOP at Stage 9.4.1/9.4.2 boundary (empirical engine validation).
- Дата: 2026-05-18.
- TASK: `project-overlays/astro/TASKS/2026-05-17-phase-9-4-summary-axis-regression-tests.md` (Ready: yes; Status: open).
- Tier: C (tests-only; Reviewer NOT required per user direction).
- Worker mode: normal.
- Outcome: **STOP at Stage 9.4.2** — empirical validation of engine output для 9 fixture cases показал, что memo § 5.4 finding «engine matches Marina deterministically 8/8 cases» **falsified для cases 05-ekaterina and 09-anastasiya** при strict primary-axis-order interpretation. Worker honors STOP discipline per TASK spec critical warning: «if engine output ≠ memo § 5.4 finding → NOT fix code, NOT adjust test; STOP + escalation memo. Memo § 5.4 may be wrong OR engine drifted.»
- Baseline: product main @ `aca694b`; overlay master @ `b1d1a5e`; pytest **368 passed + 2 skipped + 0 failed** (preserved — no test files written; no product code touched); cabal Up to date; `git status --short` clean.

---

## § 0. Worker scope discipline preserved

- ✓ NO product code modified.
- ✓ NO test files written (no `tests/test_summary_themes.py` created).
- ✓ NO Haskell engine / schema / fixtures / `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` touched.
- ✓ NO template / Jinja filter / allowlist data modified.
- ✓ NO «improved» memo § 5.4 finding silently — Worker honoured STOP-trigger per TASK critical discipline.
- ✓ NO scope creep (Marina-reference PDFs not re-read; memo § 1.1 used as Marina-primary SoT per user direction).

Pytest baseline preserved. Cabal clean. Product `git status --short` clean.

---

## § 1. Stage 9.4.1 — Marina-primary themes extracted from memo § 1.1

Worker first read memo § 1.1 + § 5.4 + § 3.4 H1 hypothesis test для compile-time per-case Marina-primary inventory:

| Case | Memo § 1.1 Marina-primary | Memo § 3.4 H1 explicit text (where present) |
|---|---|---|
| 01-kseniya | distributed (4-10 + 2-8 + 3-9; acentual; «не явно "первое место"») | — |
| 02-maksim | «ось 2-8 (финансы) — Главная тема» | «Главная тема – Финансы. Ось денег II-VIII» |
| 03-artem | «оси 6-12 (работа) + 5-11 (дети/планы) — два направления» | «Первое место: Работа\здоровье\питомцы (Ось 6-12). Второе место: Дети\планы\друзья\хобби (Ось 5-11)» |
| 04-valeriya | not extracted | — |
| 05-ekaterina | «оси 6-12 + 1-7 — 1-е место / 2-е место» | «Первое место: ось 6-12 — работа, здоровье, питомцы» |
| 07-mariya | not extracted | — |
| 08-natalya | «ось 6-12 (работа) — 1-е место» | «Первое место: Ось 6-12. Работа» |
| 09-anastasiya | «ось 1-7 (партнерство) — 1-е место»; «год супер-соляра» | «Партнерство (ось 1-7) (1st-place per her main label). H1 needs verification — possibly «super solar» means engine emits «balanced; partnership 1-7 by chart-anchor logic». **Untested but plausible.**» |
| 10-danila | «ось 2-8 (финансы) — 1-е место» | «Первое место: Финансы, ось 2-8» |
| 11-olga | «ось 5-11 (дети/хобби/планы) — акцент на одном направлении» | Memo § 1.3 engine emit: «Дети/хобби и коллектив (ось 5-11), подсчёт 4 из 12 куспидов соляра» — engine ≡ Marina exact. |

**Worker note** (per TASK spec clarification 5): cases 01/04/07 — Marina-primary not extracted в memo § 1.1; per TASK direction Worker НЕ extract'ит from Marina-reference PDFs в этой TASK. Cases 01/04/07 excluded from analysis.

**Worker minimum cases per TASK spec:** 02, 05, 08, 10, Ольга 11. **Additional eligible per memo § 1.1:** 03, 09.

---

## § 2. Stage 9.4.2 — Engine primary-axis emission located

### 2.1 Field path

Engine emits `house_axis.primary_axis` (и `secondary_axis`) в JSON DTO under `analysis.house_axis`:

```python
facts["analysis"]["house_axis"]["primary_axis"]
# → {"low": int (1..6), "high": int (7..12, == low + 6), "strength": int (count among 12 solar cusp projections)}
# or None (super-solar — no axis ≥ minAxisStrength=3)

facts["analysis"]["house_axis"]["secondary_axis"]
# → same shape or None
```

### 2.2 Computation location

**Layer: Haskell core**, NOT Python.

- File: `core/astrology-hs/src/Domain/HouseAxisAnalysis.hs`.
- Function: `analyzeAxes :: HouseCusps -> [Longitude360] -> HouseAxisAnalysis` (line 159-205).
- Method: project each of 12 solar cusps onto natal Placidus chart → count `axisOf(natalHouse)` frequencies → sort by `(Down strength, ascending low-pole)` → take top axis if `strength ≥ minAxisStrength = 3`.
- Tie-break: **deterministic numeric ascending low-pole** (e.g. при strength tie 1-7 wins over 6-12 because `1 < 6`).

Бridge in Solar.hs line 411 (`baHouseAxis :: HouseAxisAnalysis`), JSON key `house_axis` (line 425).

### 2.3 Template consumption

`services/api-python/app/pdf/templates/solar.html.j2:271-298` reads `facts.analysis.house_axis.primary_axis` directly. Synthesis builder `synthesis_themes.py:792` also reads same field для narrative sentence.

**Engine primary-axis emission is fully deterministic** (Haskell pure function). No editorial residual в emission layer. Test target: assert `facts["analysis"]["house_axis"]["primary_axis"]` equals `{"low": L, "high": L+6, "strength": N}` per Marina expected.

---

## § 3. Empirical validation — engine output for 9 fixture cases

Worker ran `astrology-core-cli` (built `aca694b`) on each `*.input.json` в `packages/test-fixtures/golden-cases/` (excluding 06 stub) and recorded `analysis.house_axis.{primary_axis, secondary_axis}`. Cross-referenced с Marina-primary from memo § 1.1.

| Case | Engine primary | Engine secondary | Marina-primary (memo § 1.1) | Match (primary order)? |
|---|---|---|---|---|
| 01-kseniya | `1-7 @ 6` | `2-8 @ 4` | distributed (no clear primary) | n/a |
| 02-maksim | `2-8 @ 4` | None | 2-8 | ✓ |
| 03-artem | `6-12 @ 6` | `5-11 @ 4` | 6-12 (1st) + 5-11 (2nd) | ✓ |
| 04-valeriya | `5-11 @ 4` | `6-12 @ 4` | not extracted | n/a |
| 05-ekaterina | **`1-7 @ 4`** | `6-12 @ 4` | **6-12 (1st)** | **✗ ORDER MISMATCH** |
| 07-mariya | `3-9 @ 4` | `4-10 @ 4` | not extracted | n/a |
| 08-natalya | `6-12 @ 4` | None | 6-12 | ✓ |
| 09-anastasiya | **None** | None | **1-7 (super-solar, editorial)** | **✗ EMIT-NONE vs MARINA-LABEL** |
| 10-danila | `2-8 @ 4` | None | 2-8 | ✓ |

Engine output matches Marina-primary order **exactly for 4 of 6 analyzable cases** (02, 03, 08, 10). **Case 05 + 09 mismatch.**

Pytest `test_golden_cases.py` confirms `expected.json` ≡ engine output for all 9 fixture cases (11/11 passed), so `expected.json` is a faithful reflection of current engine — Worker ran engine subprocess for redundant verification; results identical.

---

## § 4. Critical finding — STOP trigger evidence

### 4.1 Case 05 Екатерина — tie-break order mismatch

Engine ties strength 4 between axes 1-7 and 6-12. Per `analyzeAxes` deterministic tie-break (`sortOn (\(low, n) -> (Down n, low))` — descending strength, **ascending low-pole**) — engine picks 1-7 as primary, 6-12 as secondary.

Marina's PDF says verbatim (memo § 3.4):
> «Первое место: ось 6-12 — работа, здоровье, питомцы».

Marina chose 6-12 first by **editorial criterion** («работа, здоровье, питомцы» — alignment с client's stated focus), not by numeric axis-pole ordering.

**Both axes ARE in engine's tied-for-top set** — axis-density rule itself is consistent. The disagreement is purely on **tie-break direction** (engine numeric ascending vs Marina semantic-editorial).

Memo § 5.4 verdict claim:
> «Engine post-`transit-section-generic-output` summary uses axis-density (cusp count × angular weight) to determine primary theme. ... 8/8 analyzable cases match. No editorial residual at primary-theme level.»

is **empirically falsified для case 05 at strict primary-equality test**: engine.primary_axis = 1-7, Marina.primary = 6-12 — these are different axes, not formatting variations.

### 4.2 Case 09 Анастасия — super-solar None vs Marina label 1-7

Engine emit для case 09 has **NO axis with strength ≥ 3** (super-solar: planet/house distribution is spread evenly). Result: `primary_axis = None`.

Marina's PDF says verbatim (memo § 3.4):
> «Партнерство (ось 1-7) (1st-place per her main label).»

Marina LABELS 1-7 first despite super-solar pattern — by **editorial chart-anchor logic** (memo § 3.4 acknowledged: «Untested but plausible — possibly «super solar» means engine emits «balanced; partnership 1-7 by chart-anchor logic».»).

Memo § 3.4 itself qualifies case 09 as **«Untested but plausible»** — not «verified match». But memo § 5.4 verdict counts case 09 в the «8/8 deterministic match» claim without resolving the qualifier.

**Internal memo inconsistency:** § 3.4 «untested» qualifier on case 09 ↔ § 5.4 «8/8 match» summary claim.

### 4.3 Pattern recurrence with Phase 9.1 erratum

Same family pattern as Phase 9.1 closure (TASK `2026-05-17-phase-9-1-directions-filter` STOP HANDOFF):

- Memo § 5.1 claimed «hybrid (deterministic-leaning) — combined rule predicts 4/9 EXACT Marina match для Ольги».
- Phase 9.1 Worker empirical validation: **no formulation of A1+A2+A3 reproduces Marina selection in all 8 calibrated + Ольга simultaneously**.
- Verdict downgraded `hybrid / deterministic-leaning` → `editorial / curation-required`. Memo § 5.1 erratum issued.

Same pattern recurring для § 5.4:

- Memo § 5.4 claim: «deterministic — engine already correctly implements this rule for 8/8 cases».
- Phase 9.4 Worker empirical validation: engine matches Marina **only 4 of 6 analyzable cases** at strict primary-axis order (cases 05 + 09 differ).
- **Worker hypothesis:** verdict may need downgrade to `hybrid / partial-deterministic` или `deterministic with editorial tie-break residual`.

### 4.4 STOP discipline triggered per TASK critical clause

TASK spec § «STOP triggers» line 119-120:
> «Engine primary-axis output для test case differs from Marina expected per memo § 5.4 → **STOP, escalation memo, NOT silent test adjustment**. Memo § 5.4 finding was 8/8 deterministic; if reality differs — same pattern as Phase 9.1 editorial reality.»

TASK spec Worker framing (verbatim user direction):
> «**STOP discipline (CRITICAL):** Если engine output ≠ memo § 5.4 finding — NOT fix code, NOT adjust test. STOP + escalation memo. Memo § 5.4 may be wrong OR engine drifted. Same discipline pattern that exposed Phase 9.1 editorial reality.»

**Worker honors STOP-gate.** Does not write tests for case 05 (would fail на assertion `primary_axis.low == 6, high == 12` because engine emits `low=1, high=7`). Does not silently weaken assertion (e.g. assert axis ∈ engine's top-2 set) — that would be «adjusting test to match engine» which is the forbidden path. Does not write tests for case 09 (would assert `primary_axis is not None and axis == 1-7` — engine emits None).

---

## § 5. Subset that would match (informational, NOT executed)

For TL decision support: if user/TL chooses Option (β) below — pin only matching cases — these 4 cases pass strict engine.primary == Marina.primary:

| Case | Test assertion (proposed) | Engine actual |
|---|---|---|
| 02-maksim | `primary_axis == {"low": 2, "high": 8, "strength": 4}` AND `secondary_axis is None` | `{low:2, high:8, strength:4}` + None |
| 03-artem | `primary_axis == {"low": 6, "high": 12, "strength": 6}` AND `secondary_axis == {"low": 5, "high": 11, "strength": 4}` | same |
| 08-natalya | `primary_axis == {"low": 6, "high": 12, "strength": 4}` AND `secondary_axis is None` | same |
| 10-danila | `primary_axis == {"low": 2, "high": 8, "strength": 4}` AND `secondary_axis is None` | same |

Note: Ольга (case 11) — memo § 1.3 says engine ≡ Marina (5-11), но **fixture absent** в `packages/test-fixtures/golden-cases/`. Test для Ольги требует либо:
- Создание `11-olga-*.input.json` fixture (бOOK out of scope — requires natal data ingestion).
- DB-backed test (но `data/astro.db` пуст в текущем working tree).

**Worker НЕ создаёт fixture для Ольги** — это product-data change за пределами tests-only scope.

---

## § 6. STOP rationale per user direction

User direction 2026-05-18 verbatim в TASK spec § «Worker framing»:
> «**STOP discipline (CRITICAL):** Если engine output ≠ memo § 5.4 finding — NOT fix code, NOT adjust test. STOP + escalation memo. Memo § 5.4 may be wrong OR engine drifted. Same discipline pattern that exposed Phase 9.1 editorial reality.»

STOP triggers per TASK spec § «STOP triggers»:
- ✓ «Engine primary-axis output для test case differs from Marina expected per memo § 5.4 → STOP, escalation memo, NOT silent test adjustment.» **TRIGGERED** для cases 05 + 09.
- ✓ «Memo § 1.1 doesn't have Marina-primary для targeted case → expand или skip (Worker discretion; не extract from Marina PDFs).» **HONORED** для cases 01/04/07 (skipped).
- ✓ «Worker tempted to modify `synthesis_themes.py` или any product code → STOP, tests-only scope.» **AVOIDED** — Worker did NOT touch product code.

Worker did NOT silently:
- Adjust test assertions to engine output (would create «test pins current engine output as ground truth» — but ground truth is Marina-primary per TASK spec, not engine).
- Refine `analyzeAxes` tie-break (would be product code change за scope).
- Skip case 05 quietly (case 05 is в TASK minimum — silent omission would breach acceptance bar).

---

## § 7. Stage 9.4 decision branch (per TASK spec STOP discipline)

**Worker presents 4 options for TL decision:**

### Option α — Issue memo § 5.4 erratum (recommended)

Same path as Phase 9.1: memo § 5.4 verdict «deterministic 8/8» **empirically falsified** для cases 05 + 09. Issue erratum analogous to Phase 9.1's `§ 5.1 → editorial / curation-required` downgrade:

- Memo § 5.4 verdict downgrade: `deterministic` → `partial-deterministic with editorial tie-break residual` или `hybrid`.
- Erratum text describes:
  - Engine axis-density rule itself is consistent with Marina (axes Marina names ARE в engine's top-density set).
  - Strict primary-order ≠ Marina primary-order for 2 of 6 analyzable cases.
  - Root cause: engine numeric tie-break (ascending low-pole) ≠ Marina editorial tie-break (theme-significance).
  - Case 09 super-solar represents secondary edge: engine emits None when no axis ≥ strength 3; Marina labels primary axis from chart-anchor logic.
- Close Phase 9.4 honestly без code change (Option β analog of Phase 9.1 closure).
- No regression tests added (Worker scope discipline) — defer to follow-up TASK after erratum lands.

### Option β — Pin partial set (4 of 5+ minimum)

Worker writes regression tests for **4 cases that match exactly** (02, 03, 08, 10). Skip cases 05 + 09 + Ольга. Document skip rationale в test file docstring.

- Pros: locks in 4 deterministic wins; consistent with «pin existing correct behavior».
- Cons: **below TASK minimum** (5 cases required including 05). Requires user/TL re-scope ack.
- Pytest delta: 368 + 4 new tests = 372 passed.

### Option γ — Pin engine output (not Marina) as «engine behavior contract»

Worker writes regression tests asserting `engine.primary_axis == <engine actual>` for all eligible cases (including 05 + 09). This pins engine behavior, NOT Marina alignment.

- Pros: tests cover all 6 analyzable cases.
- Cons: **subverts TASK intent** («pin Marina-matching primary-axis output»). Test for case 05 would assert `primary_axis.low == 1, high == 7` — which contradicts Marina. Pinning engine ≠ pinning Marina. Worker considers this **forbidden** per spec STOP discipline: «NOT adjust test if engine output ≠ Marina expected.» **NOT recommended.**

### Option δ — Wait for TL/user direction

Worker STOPs entirely без any test writing. TL reads HANDOFF, decides α / β / γ / other. Worker submits this HANDOFF, no commits beyond HANDOFF + STATUS_RU.

**Worker default recommendation: Option α** (erratum + closure без tests), analogous to Phase 9.1 precedent.

Если TL chooses Option β и formally re-scopes TASK (e.g. «minimum revised to 4: 02/03/08/10»), Worker может proceed во второй цикл — текущий цикл STOPped to honor explicit STOP discipline.

---

## § 8. Acceptance status

| Item | Status | Note |
|---|---|---|
| Tests added для 4-5 cases | **NOT MET** | 0 tests written (STOP) |
| Tests pass at HEAD `aca694b` | **N/A** (no tests written) | Baseline preserved 368/2/0 |
| No product code modified | ✓ MET | Zero edits |
| `git diff aca694b -- services/api-python/app/` empty | ✓ MET | confirmed clean |
| Cabal clean | ✓ MET | Up to date |
| Pytest 368 + N new passed | **PARTIAL** | 368/2/0 preserved; N=0 |
| `git status --short` clean | ✓ MET | confirmed clean |
| One product commit (test file only) | **NOT MET** | No product commit — STOP escalation |
| Overlay commit (STATUS_RU + HANDOFF) | ✓ This handoff + STATUS_RU update | Pending commit |
| Push backup, parity verified | Pending after commit | — |
| Tests-only scope | ✓ MET | Zero product code touched |
| STOP discipline honored | ✓ MET | STOP triggered correctly per spec |

---

## § 9. Files inspected (read-only)

- `/Users/ilya/Projects/astro/CLAUDE.md`
- `/Users/ilya/Projects/astro/.claude/architecture-invariants.md`
- `/Users/ilya/Projects/astro/.claude/corrections.md`
- `/Users/ilya/Projects/ai-dev-system/CLAUDE_GLOBAL.md`
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/TASKS/2026-05-17-phase-9-4-summary-axis-regression-tests.md`
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` (§ 1.1, § 1.3, § 2.4, § 3.4, § 5.4, § 6 TASK 4, § 7, erratum)
- `/Users/ilya/Projects/astro/services/api-python/app/pdf/synthesis_themes.py` (primary-axis read at lines 502, 792)
- `/Users/ilya/Projects/astro/services/api-python/app/pdf/templates/solar.html.j2` (lines 271-298, 334-337)
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Domain/HouseAxisAnalysis.hs` (`analyzeAxes` function)
- `/Users/ilya/Projects/astro/core/astrology-hs/src/Bridge/Solar.hs` (`baHouseAxis` field, line 411 + 425 + 840)
- `/Users/ilya/Projects/astro/packages/test-fixtures/golden-cases/*.input.json` + `*.expected.json` (9 cases)
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/HANDOFFS/archive/2026-05-17-worker-to-tl-phase-9-1-directions-filter-STOP.md` (precedent format)

---

## § 10. Programme implication (Phase 9.x meta-pattern)

Phase 9.0 memo делал claim across 4 sub-problems с verdicts:
- A — directions: «hybrid (deterministic-leaning)» → **Phase 9.1 erratum**: «editorial / curation-required» (verdict downgrade).
- B — outer cards: «hybrid» (TASK 9.2 deferred).
- C — intervals: «hybrid (strong editorial residual)» (TASK 9.3 deferred).
- D — summary themes: «deterministic» → **Phase 9.4 candidate erratum**: «hybrid / partial-deterministic with editorial tie-break residual» (если TL принимает Option α).

**Pattern:** Memo § 5 verdicts derived от Marina text + sample of 8-10 cases without exhaustive engine-output-cross-validation across all primary-equality assertions. Empirical Phase 9.x validation exposes cases where engine ≠ Marina at strict primary-equality test:
- Phase 9.1: A1+A2+A3 combined rule reproduces Ольгу but breaks 4 calibrated.
- Phase 9.4: axis-density rule consistent с Marina at SET level but engine tie-break breaks Marina's editorial primary-order для case 05; super-solar None vs Marina label for case 09.

**Programme lesson:** Future analytical memos должны cross-validate verdicts с empirical engine output на ALL primary-equality assertions, не just rule-pattern coherence. Memo § 5.4 falls в same misclassification trap memo § 5.1 fell в. Phase 9.0 erratum (§ 5.1) prompts review of § 5.2 / § 5.3 / § 5.4 verdicts using same empirical-validation discipline.

---

## § 11. Diagnostic dump для TL

### 11.1 Reproduction commands

```bash
# Build core CLI (already up-to-date at aca694b):
cd /Users/ilya/Projects/astro/core/astrology-hs && PATH="/Users/ilya/.ghcup/bin:$PATH" cabal build

# Get binary path:
CLI=$(PATH="/Users/ilya/.ghcup/bin:$PATH" cabal --project-dir core/astrology-hs list-bin astrology-core-cli)

# Run engine on each input fixture, extract house_axis:
for case in 01-kseniya-2024-2025 02-maksim-2025-2026 03-artem-2025-2026 04-valeriya-2025-2026 05-ekaterina-2025-2026 07-mariya-2025-2026 08-natalya-2025-2026 09-anastasiya-2025-2026 10-danila-2025-2026; do
  python3 -c "
import json
d = json.load(open('/Users/ilya/Projects/astro/packages/test-fixtures/golden-cases/${case}.input.json'))
d.pop('_meta_source', None)
print(json.dumps(d))" | "$CLI" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ax = d['analysis']['house_axis']
p = ax.get('primary_axis'); s = ax.get('secondary_axis')
def fmt(a): return f\"{a['low']}-{a['high']}@{a['strength']}\" if a else 'None'
print(f'${case}: primary={fmt(p)} secondary={fmt(s)}')
"
done
```

### 11.2 Output (Worker observed)

```
01-kseniya-2024-2025: primary=1-7@6 secondary=2-8@4
02-maksim-2025-2026: primary=2-8@4 secondary=None
03-artem-2025-2026: primary=6-12@6 secondary=5-11@4
04-valeriya-2025-2026: primary=5-11@4 secondary=6-12@4
05-ekaterina-2025-2026: primary=1-7@4 secondary=6-12@4    ← Marina says 6-12 first
07-mariya-2025-2026: primary=3-9@4 secondary=4-10@4
08-natalya-2025-2026: primary=6-12@4 secondary=None
09-anastasiya-2025-2026: primary=None secondary=None      ← Marina says 1-7 (super-solar editorial)
10-danila-2025-2026: primary=2-8@4 secondary=None
```

### 11.3 Engine tie-break logic (verbatim from `HouseAxisAnalysis.hs` lines 182-184)

```haskell
-- Sort axes: primary by descending strength, then by ascending
-- low-pole number for deterministic tie-breaking.
ranked =
  sortOn (\(low, n) -> (Down n, low))
         (Map.toList tally)
```

При strength tie между low=1 (axis 1-7) и low=6 (axis 6-12), engine picks low=1 first. Marina чаще picks по semantic-content. Difference is **deterministic tie-break direction**, not algorithm flaw — но diverges от Marina's editorial primary в case 05.

---

## § 12. Submission

- **HANDOFF**: this file.
- **STATUS_RU**: update обновляет Phase 9.4 status from «planned» to «STOP + escalation».
- **TASK file**: spec stays Status: open (TL decides α/β/γ; bumps status only on resolution).
- **NO product commit** (zero code change).
- **One overlay commit**: STATUS_RU update + this HANDOFF.

Backup parity to be verified after commit.

End of HANDOFF.
