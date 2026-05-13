# TASK: neptune-window-structured-exceptions

- Status: open
- Ready: no
- Date: 2026-05-13
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Implementation TASK для Path 4 решения (per TL/user decision 2026-05-13 после TASK 4a memo). Phase 4a memo (`ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`) показал что Marina display boundaries для slow outer transits **не имеют deterministic rule** — H4 (editorial / non-deterministic) единственная консистентная гипотеза по 4 тестированным гипотезам.

Решение: **structured editorial exceptions в test contract**, без trogания engine, schema, fixtures, PDF.

Цель — закрыть 2 Cat 4 Neptune interval xfails через structured override mechanism: каждая editorial divergence явно задокументирована в коде test'а с reason-строкой и cross-reference на memo. Test contract остаётся regression guard для **остальных 7 boundaries** (≤ ±2d).

**Важная формулировка для документации:** Path 4 закрывает **тестовую дисциплину**, не превращает 2 даты в «совпавшие». PDF продолжает рендерить engine-derived dates через Phase 4 aggregation; Marina при показе видит engine boundaries, не свои эталонные. Это **known editorial divergence**, явно accepted TL/user 2026-05-13, не regression.

После landing — Cat 4 xfails → passing, тестовый статус: `113 passed + 10 xfailed → 115 passed + 8 xfailed`.

## Files

- modify:
  - **`services/api-python/tests/test_natalya_transits_acceptance.py`** — **единственный затрагиваемый файл**:
    - Refactor `_assert_three_phase_intervals` helper:
      - вместо `assert len(hits) == 3` — `assert len(aggregate_display_windows(hits)) == 3`. Reuse `outer_cards.aggregate_display_windows` (Phase 4 helper), не дублировать логику.
      - phase order проверяется как **set of phases per window**, не strict ordered list. Window может содержать `{Direct, Retrograde}`, `{DirectReturn}`, etc.
      - per-window boundary tolerance: по умолчанию `±2d`. Параметр `tolerance_overrides: dict[int, dict[str, tuple[int, str]]]` позволяет per-window-index указать override `{window_index: {"start": (days, reason), "end": (days, reason)}}`.
    - Add 2 structured exceptions с reason-строками + cross-reference на memo:
      - Neptune-Jupiter Square W3 end: tolerance `±20d`, reason: `"Marina extends past engine 1° orb threshold by 17d; editorial choice per memo § 4.4 + Path 4 decision 2026-05-13 — not a regression"`.
      - Neptune-Neptune Square W1 start: tolerance `±200d`, reason: `"Marina shows tail only of long first-orb-window (15-day approach before exit) vs engine wide-orb 1° threshold (193-day window); editorial choice per memo § 4.4 + Path 4 decision 2026-05-13 — not a regression"`.
    - Unmark `@pytest.mark.xfail` для 2 Cat 4 tests:
      - `test_neptune_square_jupiter_three_touches_tolerance_2d`
      - `test_neptune_square_neptune_three_touches_tolerance_2d`
    - Module docstring обновить с ссылкой на memo + Path 4 decision.

- new: —
- delete: —

## Do not touch

- **Engine** (`core/astrology-hs/**`) — out of scope. Path 4 decision: engine semantically correct, не трогаем. § 4 memo показал что deterministic rule не существует — Tier A engine adjustment не сработает.
- **Schema, rulesets, fixtures** — engine output остаётся unchanged.
- **PDF presentation** — `outer_cards.py`, `solar.html.j2`, `synthesis_themes.py`, `transit_themes.py`, `provenance.py`, `builder.py` — НЕ трогать. Path 4 — test-side acceptance, не презентация.
- **`scripts/render_natalya.py`** — Phase 1 canonical, не трогать.
- **Другие tests** (`test_contracts.py`, `test_transit_aspects_tables.py`, `test_draft.py`, `test_provenance.py`, `test_golden_cases.py`, `conftest.py`) — out of scope. Изменения только в `test_natalya_transits_acceptance.py`.
- **Phase 5/6 xfails** — НЕ трогать. Только 2 Cat 4 Neptune xfails flip.
- **Phase 4 outer_cards.py aggregation** — НЕ менять. Test reuse'ит `aggregate_display_windows` через import; реализация helper'а не правится.

## Acceptance

### Test contract refactor

- [ ] `_assert_three_phase_intervals` (или его replacement) переключён с `len(hits) == 3` на `len(aggregate_display_windows(hits)) == 3` через import `outer_cards.aggregate_display_windows`.
- [ ] Phase order assertion переключён с `[Direct, Retrograde, DirectReturn]` (strict list) на set-of-phases per window (per § 4.4 memo, set может быть `{Direct, Retrograde}`, `{DirectReturn}`, `{Retrograde, DirectReturn}` и т.д.).
- [ ] `tolerance_overrides` parameter присутствует с типом `dict[int, dict[str, tuple[int, str]]]` где int = window index (1-based or 0-based, Worker выбирает; документирует).

### Structured exceptions

- [ ] Neptune-Jupiter Square test (`test_neptune_square_jupiter_three_touches_tolerance_2d`) вызывает `_assert_three_phase_intervals(...)` с `tolerance_overrides={3: {"end": (20, "Marina extends past engine 1° orb threshold by 17d; ...")}}` (window index 3 = W3).
- [ ] Neptune-Neptune Square test (`test_neptune_square_neptune_three_touches_tolerance_2d`) вызывает с `tolerance_overrides={1: {"start": (200, "Marina shows tail only of long first-orb-window; ...")}}` (W1).
- [ ] **Reason-строки полные**: содержат «editorial choice per memo § 4.4 + Path 4 decision 2026-05-13 — not a regression».
- [ ] Each override location в коде имеет inline-комментарий со ссылкой на memo path: `# See: project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md § 4.4`.

### xfail unmark

- [ ] `@pytest.mark.xfail` декоратор удалён с `test_neptune_square_jupiter_three_touches_tolerance_2d`.
- [ ] `@pytest.mark.xfail` декоратор удалён с `test_neptune_square_neptune_three_touches_tolerance_2d`.
- [ ] Phase 5/6 xfail декораторы **не тронуты**.

### Test runs

- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — **115 passed + 8 xfailed** (было 113/10; 2 Cat 4 flipped + 2 reason-update не меняют count). 0 failed.
- [ ] `pytest tests/test_natalya_transits_acceptance.py --runxfail -v` — debug mode показывает 2 Neptune tests passing (с tolerance overrides), не падают на boundary divergence.
- [ ] Регрессии не на остальных 7 boundaries: U-V × 3 + N-J × 2 (W1+W2 ≤2d) + N-N × 2 (W2+W3 ≤2d) — все продолжают проходить с `±2d` без override.

### Scope discipline

- [ ] `git show --stat` финального commit'а — затронут **только** `services/api-python/tests/test_natalya_transits_acceptance.py`. Ничего другого.
- [ ] Engine, schema, fixtures, PDF code, presentation helpers — 0 lines changed.

### Process

- [ ] Worker subagent — отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-verifies (тест diff + один pytest run).
- [ ] HANDOFF содержит: diff scope, тест diff snippet, pytest output до/после, link на memo § 4.4.

### Tests + clean state

- [ ] `cabal build` сделан (Phase 2 lesson — даже если core не трогается, хорошая дисциплина).
- [ ] `git status --short` чисто для intended product changes.
- [ ] Один commit. Conventional message. Body цитирует Path 4 decision + ссылка на memo.
- [ ] Push на backup, parity verified.

## Context

**Mode normal + Tier C** (test-only refactor + structured exceptions). Worker subagent. Reviewer subagent необязателен.

**Baseline:** main @ `8c9588d` (Phase 4 Path 3 closed). Tests 113 passed + 10 xfailed.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` + `transit-contact-window-semantics-2026-05-13.md` (memo).

**Path 4 decision rationale (от TL/user 2026-05-13):**
1. § 4 memo показал что deterministic rule для Marina display boundaries не существует — Path 2 (engine adjustment) дисквалифицирован.
2. Path 4 структурно отделяет «common boundary parity ≤ 2d» от «known Marina editorial divergences» — каждый override в коде с reason явно объясняет почему именно этот boundary разрешено отклоняться.
3. Engine semantically корректен; PDF продолжает рендерить engine dates через Phase 4 aggregation; Marina-vs-PDF разрыв на 2 boundaries (N-J W3 +17d end, N-N W1 +178d start) — **known editorial divergence, accepted TL/user 2026-05-13**, не regression.
4. Path 4 восстанавливает Phase 2 acceptance contract integrity (Cat 4 не «forever xfail»).

**Phase 7 gate clause:** если TASK 7 multi-case calibration (после Phase 5/6) покажет что **похожие Neptune (или другие slow-mover) overrides начинают накапливаться** (>5 за case или >10 across all cases), это сигнал что Path 4 структура не масштабируется и нужно пересмотреть продуктовый подход — возможно отдельный presentation-layer "editorial override" механизм, но это не TASK 4b и не engine. Phase 7 Worker фиксирует override count в HANDOFF; если threshold превышен — TL эскалирует пользователю до closing Phase 7.

**Critical wording для документации** (на момент landing TASK 4b обновить STATUS_RU + architecture erratum):
- Path 4 закрывает **тестовую дисциплину**, не превращает 2 даты в «совпавшие».
- PDF продолжает рендерить engine-derived dates через Phase 4 aggregation.
- Marina при показе видит **engine boundaries, не свои эталонные** для 2 Neptune windows.
- Это **known editorial divergence**, accepted TL/user 2026-05-13.
- Не regression. Не engine bug.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 4b spec.
