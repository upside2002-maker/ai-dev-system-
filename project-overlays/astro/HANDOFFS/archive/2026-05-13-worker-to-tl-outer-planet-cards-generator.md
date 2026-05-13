# HANDOFF: worker → tl — outer-planet-cards-generator

- Status: closed
- Date: 2026-05-13 12:55
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-outer-planet-cards-generator.md

## Summary

**BLOCKED — Phase 4 contract mismatch (Neptune intervals).** Preflight check выявил, что engine эмитит для Нептуновых триплетов **больше hits, чем мандатирует Marina reference + test contract** (5 hits для Neptune-Jupiter и 4 hits для Neptune-Neptune вместо 3). Phase 4 является pure presentation, и Worker per § Preflight rule в TASK останавливается до решения TL о scope для engine/test layer. Никаких изменений не коммичено, working tree clean.

## Done

- Прочитан полный reading order: TASK файл, architecture-invariants.md, corrections.md, transit-section-program-2026-05-13.md (§ 4-8), Marina эталон pp. 15-22, render_natalya.py, transit_themes.py, builder.py, solar.html.j2, test_natalya_transits_acceptance.py, conftest.py, 08-natalya-2025-2026.expected.json.
- **Preflight check выполнен** для двух xfail тестов Category 4:
  - `pytest tests/test_natalya_transits_acceptance.py::test_neptune_square_jupiter_three_touches_tolerance_2d --runxfail -v` → AssertionError: 5 hits emitted, expected 3.
  - `pytest tests/test_natalya_transits_acceptance.py::test_neptune_square_neptune_three_touches_tolerance_2d --runxfail -v` → AssertionError: 4 hits emitted, expected 3.
- Verified для baseline (passing) теста `test_uranus_square_venus_three_touches_tolerance_2d`: engine эмитит ровно 3 hits (Direct, Retrograde, DirectReturn) — это работает потому, что Уран — более быстрый planet, и каждое orb-окно содержит ровно одну motion phase.

## Remaining

- **Полная реализация Phase 4 outer cards (`outer_cards.py` + builder/template wiring + 9 xfail unmark)** — не сделана. Будет восстановлена после решения TL о Category 4 contract.

## Artifacts

- branch:               main (no new commits)
- commit(s):            нет
- PR:                   нет
- tests:                **PREFLIGHT FAIL** (см. § Conflicts). Baseline до Worker: 106 passed + 17 xfailed.
- Product repo status:  **not applicable** — Worker остановился перед любыми code changes; `git status --short` clean.

## Conflicts / risks

### Contract-mismatch memo: Neptune interval xfails

**Engine output (facts) from `08-natalya-2025-2026.expected.json`, annual_transit_table:**

**Neptune ⬜ Jupiter (5 hits, ожидалось 3):**
```
loop_pass=1 phase=Direct         orb_enter=21.04.2026 00:42 exact=25.05.2026 15:59 orb_exit=28.09.2026 13:22 natal_h=8
loop_pass=2 phase=Retrograde     orb_enter=21.04.2026 00:42 exact=20.08.2026 09:44 orb_exit=28.09.2026 13:22 natal_h=8
loop_pass=3 phase=DirectReturn   orb_enter=21.02.2027 07:16 exact=20.03.2027 21:03 orb_exit=16.04.2027 16:20 natal_h=8
loop_pass=4 phase=Retrograde     orb_enter=09.10.2027 19:43 exact=28.11.2027 23:22 orb_exit=30.01.2028 02:13 natal_h=8
loop_pass=5 phase=DirectReturn   orb_enter=09.10.2027 19:43 exact=31.12.2027 17:10 orb_exit=30.01.2028 02:13 natal_h=8
```

**Neptune ⬜ Neptune (4 hits, ожидалось 3):**
```
loop_pass=1 phase=Direct         orb_enter=02.04.2024 02:37 exact=01.05.2024 14:37 orb_exit=12.10.2024 02:51 natal_h=7
loop_pass=2 phase=Retrograde     orb_enter=02.04.2024 02:37 exact=05.09.2024 02:58 orb_exit=12.10.2024 02:51 natal_h=7
loop_pass=3 phase=DirectReturn   orb_enter=31.01.2025 06:40 exact=02.03.2025 12:17 orb_exit=29.03.2025 02:25 natal_h=7
loop_pass=4 phase=DirectReturn   orb_enter=24.10.2025 16:44 exact=09.12.2025 15:53 orb_exit=24.01.2026 15:03 natal_h=7
```

**Marina reference (architecture doc § 6 Outer-planet intervals):**

Neptune ⬜ Jupiter — 3 окна:
- 21.04.2026 12:00 - 28.09.2026 12:00 — 1-е касание
- 21.02.2027 12:00 - 16.04.2027 12:00 — 2-е касание
- 10.10.2027 00:00 - 16.02.2028 12:00 — 3-е касание

Neptune ⬜ Neptune — 3 окна:
- 27.09.2024 00:00 - 12.10.2024 00:00 — 1-е касание
- 31.01.2025 12:00 - 29.03.2025 00:00 — 2-е касание
- 25.10.2025 00:00 - 24.01.2026 12:00 — 3-е касание

### Анализ структуры mismatch

**Consolidation by `(orb_enter, orb_exit)` показывает истинное строение engine output:**

Neptune ⬜ Jupiter — **3 уникальных orb-window**, но каждое split'нуто по motion phases:
- 21.04.2026 - 28.09.2026 → phases=[Direct, Retrograde] (2 hits на одно окно)
- 21.02.2027 - 16.04.2027 → phases=[DirectReturn] (1 hit)
- 09.10.2027 - 30.01.2028 → phases=[Retrograde, DirectReturn] (2 hits)

Neptune ⬜ Neptune — **3 уникальных orb-window**:
- 02.04.2024 - 12.10.2024 → phases=[Direct, Retrograde] (2 hits)
- 31.01.2025 - 29.03.2025 → phases=[DirectReturn]
- 24.10.2025 - 24.01.2026 → phases=[DirectReturn]

**Структурное наблюдение:** Engine эмитит **по одному hit per motion phase** внутри orb-окна. Для Урана (быстрее) каждое orb-окно содержит ровно одну фазу → 3 окна = 3 hits (тест Uranus-Venus passes). Для Нептуна (медленнее) одно orb-окно может содержать несколько exact moments в разных motion phases (D + R, или R + DR) → 3 окна = 4-5 hits.

### Гипотеза о root cause

**Это test contract design gap из Phase 2, не engine bug.** Test `_assert_three_phase_intervals` имеет unstated assumption «engine эмитит ровно 3 hits per outer triplet», что не выдерживается для slow movers (Neptune). Engine **семантически правильно** эмитит per-phase exact moments. Marina рассматривает 3 «касания» как 3 **petli** = 3 уникальных orb-window, что соответствует engine output после consolidation.

**Дополнительный edge case Neptune-Neptune окно 1:**
- Engine: 02.04.2024 - 12.10.2024 (orb_enter 178 дней раньше Marina 27.09.2024).
- Это указывает, что Marina **визуально пропустила** длинный orb-период (~6 месяцев Direct→Retrograde drift), считая его background drift, и записала «1-е касание» только как период **последнего захода в orb** перед началом DirectReturn петли. Engine считает orb-окно от первого пересечения 1.0° orb threshold.

**Дополнительный edge case Neptune-Jupiter окно 3:**
- Engine orb_exit 30.01.2028 vs Marina 16.02.2028 (Δ=17d вне ±2d tolerance).
- Здесь engine более «жёстко» закрывает orb, Marina — на ~2 недели позже.

### Recommendation

Three возможных next-step paths (выбор TL):

1. **Test-level fix (Phase 2 reopen, low cost):** Изменить `_assert_three_phase_intervals` логику: вместо `assert len(hits) == 3` — `assert len(unique_windows) == 3`, где `unique_windows = set((orb_enter, orb_exit))`. Phase order assertion остаётся через `phases_emitted_in_window`. Это сохраняет facts-level контракт «3 окна реализации», но adapts to engine emission pattern. Tolerance ±2d остаётся для окна 1 Neptune-Neptune — здесь ОНА не пройдёт (Δ=178d), потребуется либо bumping tolerance до ~6 months для slow-mover first-touch (нелогично), либо принять расхождение как documented exception (engine считает orb-окно с первого захода, Marina — с последнего перед direct-return петли).

2. **Engine-level fix (Tier A cascade, high cost):** Изменить `Domain.TransitCalendar`, чтобы первое orb-окно начиналось не с первого пересечения orb threshold, а с входа в "tight orb" (e.g., 0.5°) или с первой точки exact-Direct. Это семантическое изменение в engine, требует schema cascade per bright-line #8.

3. **Hybrid: Marina-orchestrated truth (выбор Path B, Tier C):** Phase 4 Worker строит cards с **consolidated 3 windows** (хорошо для PDF presentation, parity с Marina), но **НЕ unmark** Category 4 xfails (это Tier A/Phase 2 territory). Acceptance contract Phase 4 retroactively suжается до 7 xfail flips (6 Category 3 + 1 Category 7 regression ban). Category 4 пишется как отдельный TASK (Phase 2 test contract fix или engine semantic adjustment).

**Worker предлагает Path 3** как минимально-invasive с разъяснением:
- Phase 4 deliverable (visual cards с 3 окнами) полностью выполнима в presentation layer.
- Phase 2 test contract имел design gap для Neptune (5/4 hits expected as 3), который Phase 4 НЕ может починить из presentation.
- Path 1 vs Path 2 разделение требует архитектурного решения TL — это явная границы Tier C.

**Constraint:** Path 3 уменьшает количество xfail flips с 9 до 7. TASK § Test contract явно мандатирует 9 — Worker не может выполнить без эскалации.

### Что не нарушено

- `expected.json` НЕ переписан.
- transit_themes.py, synthesis_themes.py, provenance.py, render_natalya.py НЕ затронуты.
- Haskell core, schema, fixtures НЕ затронуты.
- Working tree clean (`git status --short` пуст).

## Next step

**TL принимает решение по сценарию** (Path 1 / Path 2 / Path 3) и эскалирует:

- Если **Path 3** → переоткрыть TASK 4 с обновлённой acceptance criteria (7 xfail flips, Category 4 staying xfail), Worker возобновит presentation работу немедленно. Параллельно открыть Phase 2 reopen TASK для test contract или engine semantic TASK.
- Если **Path 1** → открыть Phase 2 reopen TASK сначала (worker level), затем re-enable Phase 4.
- Если **Path 2** → открыть Tier A engine TASK с schema cascade, затем Phase 2/4 re-evaluation.

Worker готов взять любой из этих TASK'ов при следующем activation. Marina pp. 17-22 уже прочитаны, structure outer cards (5 секций × 3 карточек) сформулирована и готова к implementation как только path выбран.
