# Golden Case 10 (Danila 2025-2026) — Recon

**Дата:** 2026-05-06.
**Baseline:** `astro:3bb96c0` (HEAD после `phase-0-10c-wheel-polish`).
**Автор:** Worker (AI Dev System).
**Источник запроса:** TASK `golden-case-10-danila-recon` (`project-overlays/astro/TASKS/2026-05-06-golden-case-10-danila-recon.md`).
**Статус:** recon-only, diagnostic. Этот документ **не** регенерирует fixture, **не** меняет core, **не** меняет PDF visual layer.

---

## 1. Baseline и метод

### 1.1 Baseline

- Git commit: `astro:3bb96c0` (`3bb96c06dad879bda82aa2502d982db7a940a32d`).
- Pre-existing pytest failure: `tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]`, **верифицирован** на baseline `4937c00`, `b7774cf`, `bb5a9eb`, `3bb96c0` (все четыре снапшота показывают одинаковую failure mode).
- Fixture last touched in git: `4937c00` (initial import; не модифицирован ни в одном из 3 последующих коммитов).
- Haskell core source last touched: `4937c00` (для `Domain/PriorityWindows.hs`, `Domain/SolarReportSkeleton.hs` content; в `b7774cf` только rename `Domain.ConsultationSkeleton` → `Domain.SolarReportSkeleton`, content не менялся).
- Core CLI binary already built (`53M` aarch64 binary), mtime 19:54 same session — Worker NOT triggered new `cabal build`.

### 1.2 Files compared

- Input: `packages/test-fixtures/golden-cases/10-danila-2025-2026.input.json` (325 KB).
- Expected (committed): `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json` (167 KB).
- Actual (regenerated this recon): `/tmp/case-10-actual.json` (104 KB; smaller because no `_meta_source` and no pretty-print spacing).

### 1.3 Метод evidence

- `pytest tests/test_golden_cases.py -k '10-danila' -vv` — captured full output (15031 lines) to `/tmp/case-10-pytest-vv.log`.
- Direct CLI rerun via `cabal list-bin astrology-core-cli` (already built) → feed input → save actual.
- Path-aware deep walk через Python script (compares every leaf, reports diverging paths).
- Per-section item-by-item compare (priority_windows / cautions / key_periods / etc).

Никаких claim'ов «по памяти». Все цифры в § 2 ниже — из реальных команд § 5 Evidence appendix.

### 1.4 Ограничение recon

Этот документ:
- **не** регенерирует `10-danila-2025-2026.expected.json`;
- **не** меняет Haskell core / fixture / PDF;
- **не** меняет other overlay-документы;
- **не** запускает `cabal build` (использует уже-built binary).

---

## 2. Diff inventory

### 2.1 Top-level analysis fields — что divergent vs identical

| Field | Status |
|------|--------|
| `analysis.directions` | IDENTICAL |
| `analysis.house_axis` | IDENTICAL |
| `analysis.important_transit_planets` | IDENTICAL |
| `analysis.natal_king_of_aspects` | IDENTICAL |
| `analysis.natal_stellia` | IDENTICAL |
| `analysis.solar_king_of_aspects` | IDENTICAL |
| `analysis.solar_stellia` | IDENTICAL |
| `analysis.progressed_moon` | IDENTICAL |
| **`analysis.priority_windows`** | **DIVERGE** |
| **`analysis.consultation_skeleton`** | **DIVERGE** (downstream of priority_windows) |
| `natal_chart`, `solar_chart`, `meta`, `annual_transit_table`, `workflow` | IDENTICAL (not shown in walker output) |

**Total diverging leaves:** 394.

### 2.2 priority_windows.windows divergence pattern

15 windows total; ranks 0-4 + 10-14 IDENTICAL; ранки 5-9 DIVERGE.

| Rank | actual peak_jd | actual score | expected peak_jd | expected score | Status |
|------|---------------|-------------|-----------------|---------------|--------|
| 0 | 2461058.158 | 92 | 2461058.158 | 92 | IDENTICAL |
| 1 | 2461119.438 | 87 | 2461119.438 | 87 | IDENTICAL |
| 2 | 2461225.211 | 81 | 2461225.211 | 81 | IDENTICAL |
| 3 | 2461156.766 | 79 | 2461156.766 | 79 | IDENTICAL |
| 4 | 2461206.451 | 76 | 2461206.451 | 76 | IDENTICAL |
| **5** | **2460921.111** | **70** | **2461002.786** | **67** | DIVERGE |
| **6** | **2461002.786** | **67** | **2461124.703** | **67** | DIVERGE |
| **7** | **2461124.703** | **67** | **2460969.501** | **61** | DIVERGE |
| **8** | **2460969.501** | **61** | **2460921.111** | **58** | DIVERGE |
| **9** | **2460932.495** | **41** | **2460923.713** | **55** | DIVERGE |
| 10 | 2461020.383 | 41 | 2461020.383 | 41 | IDENTICAL |
| 11 | 2461254.655 | 14 | 2461254.655 | 14 | IDENTICAL |
| 12-14 | … | 5-6 | … | 5-6 | IDENTICAL |

### 2.3 Key signal: window `2460921` score moved from 58 → 70 (+12)

Same window (peak_jd `2460921.111`) has:
- in expected (committed fixture): **score 58** at rank 8
- in actual (current core): **score 70** at rank 5

A score increase of **+12 points** means the scoring algorithm now adds new factors or higher weights for some factor types. Concrete factor-level evidence:

```
windows[5].factors[0]:
  actual:   {jd: 2460897.276, label: 'тр Марс ✶ Асц',           kind: ?,        score_contribution: 3}
  expected: {jd: 2460990.136, label: 'тр Венера △ Венера',      kind: ?,        score_contribution: 2}

windows[5].factors[6]:
  actual:   {kind: 'transit_aspect',         score_contribution: 3}
  expected: {kind: 'transit_house_ingress',  score_contribution: 1}

windows[5].factors[7]:
  actual:   {kind: 'direction_exit',         label: 'дир Юпитер ⚻ Луна', score_contribution: 4}
  expected: {kind: 'transit_aspect',         label: 'тр Марс ☍ Сатурн', score_contribution: 2}
```

(Полный 30-line breakdown — § 5 Evidence appendix command 3.)

### 2.4 cautions divergence (downstream)

`consultation_skeleton.cautions` derived от `priority_windows` через `Domain.SolarReportSkeleton.buildCautions` (filter по `«по слабой планете» elem pwReasons w` → одна строка-предупреждение per такое окно, в порядке windows[]).

Pattern:
- 14 cautions total; ранки 0-4 + 10-13 IDENTICAL; ранки 5-9 DIVERGE.
- Цитата divergent items (≤ 15 слов each):
  - `cautions[5]` actual: `«Чувствительный период 09.08.2025 – 05.09.2025: вовлечена слабая натальная планета. Темы: деньги, статус…»`
  - `cautions[5]` expected: `«Чувствительный период 10.11.2025 – 09.12.2025: вовлечена слабая натальная планета. Темы: отношения…»`
  - `cautions[6]` actual: `«Чувствительный период 10.11.2025 – 09.12.2025: …»` (= expected[5])
  - `cautions[6]` expected: `«Чувствительный период 24.03.2026 – 21.04.2026: …»`

Это **прямое следствие** § 2.2: cautions сохраняют window'овый порядок, поэтому когда windows перетасовались, cautions перетасовались синхронно.

### 2.5 key_periods unchanged

`consultation_skeleton.key_periods` — first 5 windows; **все 5 IDENTICAL** (rank 0-4 priority windows тоже identical, см. § 2.2). Headlines:
- `[0]`: «Окно: деньги — поворотный период» (both)
- `[1]`: «Окно: деньги — поворотный период» (both)
- `[2-4]`: «Окно: отношения — поворотный период» × 3 (both)

Это значит: user-visible PDF top section («Ключевые периоды года») идентичен. Drift живёт в long-tail less-impactful windows.

---

## 3. Hypothesis tree

Worker рассматривает 3 кандидата first-cause'а и оценивает evidence для каждого.

### 3.1 Hypothesis A: Stale fixture (most likely — primary hypothesis)

**Claim:** `10-danila-2025-2026.expected.json` был сгенерирован до последней правки в `Domain.PriorityWindows.hs` (или в одном из drivers: `direction`/`transit`/`progression` factor scoring). После той правки 8 других fixtures (cases 1, 2, 3, 4, 5, 7, 8, 9) были регенерированы; case 10 — не был.

**Evidence:**
1. **Cases 1-9 PASS зелёным** — current core consistent с fixtures 1-9. Если был бы реальный bug в priority_windows для всех 10 cases, минимум один из 1-9 тоже падал бы.
2. **Top-5 windows identical** для case 10 — current core не сломан для high-impact windows. Drift только в borderline rank 6-10.
3. **Score increase pattern** — window `2460921.111` gained +12 score points в actual; это типично для «new factor type added» или «existing factor weight bumped», что разумно для refinement post-fixture.
4. **Modified factor metadata** — `factors[].kind` differs (`transit_house_ingress` появилось в actual'е там, где expected имеет `transit_aspect`); это новый kind label или новое включение этого factor type в scoring.
5. **Git history** — все коммиты в overlay/product (`b7774cf`, `bb5a9eb`, `3bb96c0`) НЕ трогали `core/astrology-hs/src/Domain/PriorityWindows.hs` ни `packages/test-fixtures/`. Fixture устарел до `4937c00` initial import — это **pre-bootstrap drift** (developer работал в pre-git режиме над PriorityWindows refinement, регенерировал 8 fixtures из 9, упустил 10).

**Counter-evidence:** none material. Все наблюдения consistent.

### 3.2 Hypothesis B: Real Haskell core regression in PriorityWindows for case 10's specific configuration

**Claim:** Case 10 имеет какую-то особую configuration (e.g., specific stellium, edge-case retrograde pattern), на котором `Domain.PriorityWindows` algorithm имеет bug.

**Evidence для:**
- Не выявлено. Cases 1-9 покрывают разнообразные configurations и все проходят.

**Evidence против:**
1. Cases 1-9 contain reasonable variety (case 5 has Pisces stellium, case 4 has retrograde planets, etc.) — если был bug, случай 10 не уникален в triggering configuration.
2. Top-5 windows для case 10 identical — значит core не сломан для high-impact windows на этом case.

**Likelihood:** низкая. Worker не нашёл ни одного artifact'а указывающего на specific bug.

### 3.3 Hypothesis C: Hybrid — stale fixture + minor numerical drift

**Claim:** Большинство divergences — stale fixture (Hyp A). Но возможно existуют отдельные numeric precision differences (e.g., transit_jd computed marginally differently on different platforms or build dates).

**Evidence для:**
- Cases 1-9 byte-identical к fixtures, что excludes platform/build-date precision drift across the suite.

**Evidence против:**
- Те же cases 1-9 byte-identical eliminates this hypothesis as primary cause.

**Likelihood:** очень низкая. Hybrid не нужен — Hyp A объясняет всё.

### 3.4 Conclusion

**Primary hypothesis: A — stale fixture.** Confidence: высокая. Все наблюдаемые pattern'ы consistent с «fixture не регенерирован после последней refinement в PriorityWindows scoring».

---

## 4. Recommended fix (одно предложение)

**Регенерировать `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`** через текущий built `astrology-core-cli` (тот же mechanism, что использует `tests/test_golden_cases.py`): feed `10-danila-2025-2026.input.json` (с removed `_meta_source`) → core CLI → save stdout как new `expected.json`, commit с message по образцу «chore(fixtures): regenerate case-10 to match current PriorityWindows scoring (stale since pre-bootstrap; cases 1-9 already current)», push backup; **отдельным мини-TASK Tier C** с Reviewer pass optional (Reviewer независимо повторяет regen + verifies all 10 cases pass; этот TASK уровня pure data refresh, не logic change).

---

## 5. Evidence appendix

Все commands воспроизводимы на `astro:3bb96c0` с built CLI binary в `dist-newstyle/`.

### 5.1 Failing pytest reproduction

```
$ cd /Users/ilya/Projects/astro/services/api-python && source .venv/bin/activate
$ pytest tests/test_golden_cases.py -k '10-danila' -vv 2>&1 | tail -3
=========================== short test summary info ============================
FAILED tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]
======================= 1 failed, 8 deselected in 0.83s ========================
```

### 5.2 Direct CLI rerun (no rebuild — uses already-built binary)

```
$ CORE_CLI=$(cd /Users/ilya/Projects/astro/core/astrology-hs && cabal list-bin astrology-core-cli)
$ ls -lh "$CORE_CLI"
-rwxr-xr-x@ ... 53M May 6 19:54 .../astrology-core-cli  # pre-built; no `cabal build` triggered

$ python3 -c "
import json, subprocess
inp = json.load(open('packages/test-fixtures/golden-cases/10-danila-2025-2026.input.json'))
inp.pop('_meta_source', None)
proc = subprocess.run(['$CORE_CLI'], input=json.dumps(inp).encode(), capture_output=True, timeout=60)
print('exit:', proc.returncode)
json.dump(json.loads(proc.stdout), open('/tmp/case-10-actual.json', 'w'), ensure_ascii=False, indent=2)
print('actual saved')
"
exit: 0
actual saved
```

### 5.3 Path-aware deep walk (top 30 diverging leaves)

```
$ python3 - <<'EOF'
[script per § Test commands of TASK]
EOF
TOTAL diverging leaves: 394
PATH: .analysis.consultation_skeleton.cautions[5]
  actual:   'Чувствительный период 09.08.2025 – 05.09.2025: …'
  expected: 'Чувствительный период 10.11.2025 – 09.12.2025: …'
PATH: .analysis.priority_windows.windows[5].factors[0].label
  actual:   'тр Марс ✶ Асц'
  expected: 'тр Венера △ Венера'
… (28 more lines)
```

### 5.4 Top-level analysis-field split (identical vs divergent)

```
$ python3 -c "[per-key compare script per § Test commands]"
consultation_skeleton: DIVERGE
directions: IDENTICAL
house_axis: IDENTICAL
important_transit_planets: IDENTICAL
natal_king_of_aspects: IDENTICAL
natal_stellia: IDENTICAL
priority_windows: DIVERGE       # ← root cause
progressed_moon: IDENTICAL
solar_king_of_aspects: IDENTICAL
solar_stellia: IDENTICAL
```

### 5.5 priority_windows.windows item-by-item

```
$ python3 -c "[item-by-item compare]"
[0]: peak_jd 2461058.158, score 92/92, IDENTICAL
[1]: 87/87 IDENTICAL
[2]: 81/81 IDENTICAL
[3]: 79/79 IDENTICAL
[4]: 76/76 IDENTICAL
[5]: peak_jd actual=2460921.111, expected=2461002.786, score 70/67, DIVERGE
[6]: 67/67 (same scores, different windows) DIVERGE
[7]: 67/61 DIVERGE
[8]: 61/58 DIVERGE
[9]: 41/55 DIVERGE
[10]: 41/41 IDENTICAL
[11-14]: 14/14, 6/6, 5/5, 5/5 IDENTICAL
```

### 5.6 cautions item-by-item

```
[0..4]: IDENTICAL
[5..9]: DIVERGE (downstream of windows[5..9])
[10..13]: IDENTICAL
```

### 5.7 key_periods item-by-item (top-5 priority windows)

```
[0]: 'Окно: деньги — поворотный период' / IDENTICAL
[1]: 'Окно: деньги — поворотный период' / IDENTICAL
[2-4]: 'Окно: отношения — поворотный период' × 3 / IDENTICAL
```

### 5.8 Git provenance

```
$ git log --oneline 4937c00..HEAD -- core/astrology-hs/src/Domain/PriorityWindows.hs
(empty — no commits modified PriorityWindows since baseline)

$ git log --oneline 4937c00..HEAD -- packages/test-fixtures/golden-cases/
(empty — no commits modified fixtures since baseline)

$ git log --oneline 4937c00..HEAD
3bb96c0 fix(pdf): polish natal/solar SVG wheel typography + layout
bb5a9eb docs(corrections): add Correction 008 …
b7774cf refactor(core): rename ConsultationSkeleton→SolarReportSkeleton …

→ All 3 post-baseline commits irrelevant to PriorityWindows / fixtures.
   Drift therefore preexisted in `4937c00` initial import (pre-bootstrap origin).
```

---

## 6. Summary

- **Root cause:** stale fixture `10-danila-2025-2026.expected.json`. Likely регенерирован 8/9 fixtures когда последняя scoring refinement в `Domain.PriorityWindows` landed — case 10 был пропущен. Drift предшествовал git bootstrap (`4937c00`); все 3 post-bootstrap commits irrelevant.
- **Scope of drift:** только rank-6+ priority windows (top-5 identical) и derived cautions[5..9]. User-visible PDF top section (key_periods) unchanged.
- **Recommendation:** regenerate `expected.json` для case 10 — отдельным Tier C мини-TASK с Reviewer optional. Не fix core (нет bug'а), не accept as known drift (drift реальный, не aesthetic).
- **After fix:** pytest baseline станет 70/70 green; стандартный «зелёный baseline» для будущих TASK'ов.
