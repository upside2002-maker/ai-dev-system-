# HANDOFF: worker → tl — transit-engine-orb-tune2-per-planet

- Status: closed
- Date: 2026-05-11 23:30
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-11-transit-engine-orb-window-quincunx-cross-year.md (TUNE-2 round)

## Summary

**Status: TUNE-2 COMPLETED.** Per-planet эмпирическая калибровка transit orb по Marina case-8 row diff. Result: **17/17 combos present**, **16/17 ALL Marina passes have overlap with engine pass** (только #1 Jupiter Sextile Asc формально NO overlap из-за Marina single-day window — Marina-точка 07.08 лежит ВНУТРИ engine окна 30.07—09.08; drift 8/2d). **TUNE-2 avg drift 7.3 дней** vs TUNE-1 28.0 vs pre-TUNE 19.9 (4× улучшение vs TUNE-1, 3× улучшение vs pre-TUNE). #12 Neptune Sextile MC ВОССТАНОВЛЕН (с 312/283d в TUNE-1 → 21/22d с overlap). #7 Pluto Trine MC восстановлен до perfect (27/32d в TUNE-1 → 2/1d). Тесты зелёные (cabal 242/242, pytest 82/82). Single followup commit `2e4c394`, push'нут на backup.

## Done

- **Commit:** `2e4c394` на ветке `claude/dreamy-moore-46f5eb` (worktree `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`).
- **Baseline (TUNE-1):** `3a12ed3`.
- **Pre-TUNE baseline:** `5f4fbc9` (Tier A cascade).
- **Backup parity:** push'нут на `backup` (`3a12ed3..2e4c394 claude/dreamy-moore-46f5eb`).

### Файлы изменены (11 файлов)

- `packages/rulesets/daragan-orbs-v1.json` — `transit_per_planet_class` block:
  - Uranus: 0.5 → 1.0
  - Neptune: 0.5 → 1.0
  - Pluto: 0.5 → 1.25
  - Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn: 1.0 (без изменений)
  - `__source__` doc string обновлён с TUNE-2 reasoning (per-planet empirical from Marina case-8 row diff).
- `core/astrology-hs/src/Domain/TransitCalendar.hs` — `transitOrbForPlanet` зеркало ruleset'а. Header comment обновлён с TUNE-2 reasoning (Marina-implied per-planet empirical).
- 9 × `packages/test-fixtures/golden-cases/*.expected.json` — регенерированы через `_generate.py` + cabal CLI.

### Файлы НЕ изменены

- `*.input.json` — sample window 540d before/after сохранён. `git diff --stat HEAD~1 HEAD -- packages/test-fixtures/golden-cases/*.input.json` пусто.
- `core/astrology-hs/test/Test/Domain/TransitCalendarSpec.hs` — Jupiter remains 1.0° (test expectations не менялись).
- Никаких presentation/Domain.Aspects/Directions/synthesis правок.

### Tests

- `cabal test` — **242 examples, 0 failures** (как и до TUNE-2).
- `pytest` — **82 passed in 16.30s** (как и до TUNE-2).

## Remaining

Открытых пунктов нет — TUNE-2 patch применён. TL принимает решение (см. Next step).

## Artifacts

- branch: `claude/dreamy-moore-46f5eb` (worktree `.claude/worktrees/dreamy-moore-46f5eb`)
- commit (TUNE-2): `2e4c394`
- commit (TUNE-1 baseline): `3a12ed3`
- commit (pre-TUNE baseline): `5f4fbc9`
- tests: cabal 242/242 green; pytest 82/82 green
- **Product repo status: committed.**
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` (pp. 19-23)
- TUNE-2 diff script: `/tmp/marina_diff_post_tune2.py` (self-contained Python helper, reuses overlap matching)

## Conflicts / risks

### Pre-TUNE vs TUNE-1 vs TUNE-2 drift comparison — 17 Marina combos

Per-pass max drift_start / drift_end (worst Marina pass для combos with 2 пасс'ами). TUNE-2 column из текущего fixture'а (`08-natalya-2025-2026.expected.json` после regen).

```
 #  Combo                             preΔst  preΔen  t1Δst  t1Δen  t2Δst  t2Δen   ov                         verdict
============================================================================================================================================
 1  Jupiter Sextile Asc                   14      10      8      2      8      2   NO                       == TUNE-1
 2  Saturn Square Neptune                 26      22      0      1      0      1  yes                       == TUNE-1
 3  Jupiter Trine Mars                    14      15      1      1      1      1  yes                       == TUNE-1
 4  Neptune Square Neptune               184      11     30     28      0      1  yes              IMPROVED vs TUNE-1
 5  Uranus Square Venus                    8       5     12     13      1      1  yes              IMPROVED vs TUNE-1
 6  Saturn Trine Mars                     26      25      0      0      0      0  yes                       == TUNE-1
 7  Pluto Trine MC                         1       2     27     32      2      1  yes              IMPROVED vs TUNE-1
 8  Saturn Square Jupiter                 12      14      0      1      0      1  yes                       == TUNE-1
 9  Saturn Sextile MC                     10      16      2      3      2      3  yes                       == TUNE-1
10  Neptune Square Jupiter                 7      10     16     34      0     53  yes              WORSENED vs TUNE-1
11  Saturn Trine Uranus                   12      17      0      0      0      0  yes                       == TUNE-1
12  Neptune Sextile MC                     2       2    312    283     21     22  yes              IMPROVED vs TUNE-1
13  Jupiter Square Pluto                   7       8      1      1      1      1  yes                       == TUNE-1
14  Saturn Trine Sun                      22      45      1     22      1     22  yes                       == TUNE-1
15  Uranus Quincunx Jupiter                5       9      9     12      1      1  yes              IMPROVED vs TUNE-1
16  Uranus Conjunction MC                  0     100     18     80      5     93  yes                       == TUNE-1
17  Jupiter Sextile MC                     6       9      0      1      0      1  yes                       == TUNE-1
============================================================================================================================================
Pre-TUNE avg (Δst+Δen)/2 across all 17: 19.9 days
TUNE-1   avg (Δst+Δen)/2 across all 17: 28.0 days
TUNE-2   avg (Δst+Δen)/2 across all 17: 7.3 days   ←  4× улучшение vs TUNE-1
vs TUNE-1: IMPROVED 5 ; WORSENED 1 ; == 11
Combos with overlap (TUNE-2): 16/17
Combos missing overlap (TUNE-2): 1 (= #1 Jupiter Sextile Asc, pedantic near-miss)
```

### Combos с overlap всех passes

**16/17 combos** имеют `has_overlap=yes` (engine pass пересекается с Marina period для ВСЕХ Marina passes этого combo).

**1/17 без overlap (#1):**

- **#1 Jupiter Sextile Asc** — Marina single-day window `(07.08.2025, 07.08.2025)`. Engine pass `(30.07.2025, 09.08.2025)`. Marina-точка (07.08) лежит ВНУТРИ engine-окна, но overlap-метрика трактует Marina'ино «нулевой длительности» окно как точку и возвращает `intersection_days = 0`. Это **не реальный miss** — drift 8/2 дней, Marina date inside engine window. **То же что в TUNE-1**, Jupiter остался 1.0° (не менялся).

**Все остальные combos — overlap есть**, включая #12 Neptune Sextile MC которое было real miss в TUNE-1.

### Особое внимание (per TL спецификации TUNE-2)

- **#7 Pluto Trine MC**: ожидание drift 1-2d (как pre-TUNE при 1.25°). **Получено 2/1d** ✓ — IMPROVED vs TUNE-1 (был 27/32d).
- **#12 Neptune Sextile MC**: ожидание overlap. **Получено overlap=yes, drift 21/22d**. Engine pass 2026-06-29—2026-07-16 пересекается с Marina 2026-06-08—2026-08-07 ✓ — IMPROVED vs TUNE-1 (был 312/283d, no overlap).
- **#5 Uranus Square Venus**: ожидание drift 5-9d. **Получено 1/1d** (лучше ожидаемого, потому что U=1.0° даёт более широкое окно которое перекрывает Marina window полностью) ✓ — IMPROVED vs TUNE-1.
- **#15 Uranus Quincunx Jupiter**: ожидание drift 5-9d. **Получено 1/1d** (тоже лучше ожидаемого, тот же эффект) ✓ — IMPROVED vs TUNE-1.

### Один WORSENED (#10 Neptune Square Jupiter)

- Marina period: 2026-04-21—2026-08-07.
- Engine TUNE-1: 2026-05-07—2026-09-10 (drift 16/34d).
- Engine TUNE-2: 2026-04-21—2026-09-29 (drift 0/53d).

TUNE-2 расширил Neptune окно (orb 0.5°→1.0°), что улучшило start (0d!) но tail engine'а вылез на ~2 мес. за Marina cutoff 07.08. Total sum: TUNE-1=50d, TUNE-2=53d. Net effect ~== с пограничным WORSENED. Это side-effect более широкого Neptune orb'а — **acceptable trade-off** для восстановления #12.

### Финальный вердикт

- TUNE-2 даёт **17/17 формальное присутствие combos** (axis 1 сохранена) ✓
- TUNE-2 даёт **16/17 содержательное совпадение** (axis «период overlap with Marina») — на 1 больше чем TUNE-1, на 1 меньше чем pre-TUNE
- TUNE-2 даёт **средний drift 7.3 дня** — **4× улучшение vs TUNE-1**, **3× улучшение vs pre-TUNE**
- TUNE-2 решает **2 ключевые TUNE-1 деградации**: #7 Pluto (восстановлен с 27/32 → 2/1d) и #12 Neptune Sextile MC (восстановлен с no overlap → overlap)
- Только #1 Jupiter Sextile Asc остаётся pedantic near-miss (Marina-точка inside engine окна, но zero-length overlap)
- Owner-directive «per-planet empirical» **успешно применён** — single case-8 estimate валидно

### Финальные эмпирические orb-значения per planet (TUNE-2)

```
Sun, Moon, Mercury, Venus, Mars : 1.0°  (transiting class minimal)
Jupiter                          : 1.0°  (TUNE-1 working, kept)
Saturn                           : 1.0°  (TUNE-1 working, kept)
Uranus                           : 1.0°  (Marina-implied empirical)
Neptune                          : 1.0°  (Marina #12: |signedArc|=0.98°)
Pluto                            : 1.25° (Marina #7 perfect match)
```

## Next step

TL запускает **второй Reviewer cold-start** для верификации TUNE-2 результата. Reviewer должен:

1. Независимо открыть Marina PDF (`Соляр 2025-2026_5.pdf` pp. 19-23) и извлечь 17 unique aspect combos.
2. Независимо прогенерить engine output из коммита `2e4c394` (через cabal CLI + `_generate.py` либо прямое чтение `08-natalya-2025-2026.expected.json`).
3. Сравнить row-by-row для каждого из 17 combos: проверить наличие, число касаний, даты, период overlap.
4. Зафиксировать средний drift независимо.
5. Verdict: ACCEPT (если ~17/17 overlap, drift <10d) / TUNE-3 (если нужны мелкие корректировки) / REJECT (если структурный issue).

Reviewer cold-start — fresh memory, чтобы независимо подтвердить acceptance.
