# HANDOFF: worker → tl — transit-contact-window-semantics

- Status: open
- Date: 2026-05-13 13:50
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-transit-contact-window-semantics.md

## Summary

TASK 4a (analysis-only, Tier C, docs) **COMPLETED**. Memo создан с 7 sections per
TASK spec: контекст, taxonomy 5 concepts, engine semantic analysis с line
references на `Domain.TransitCalendar`, hypothesis testing Marina display rule
на 3 примерах Натальи (U-V, N-J, N-N), path analysis (3 + 1 новый), recommendation,
next TASK templates. Worker рекомендует **Path 4** (новый — hybrid relaxation
test contract с structured per-window tolerance overrides) как оптимум между
honest engineering (engine semantically correct, не трогаем) и acceptance
discipline (Cat 4 xfails закрываются через structured pass). Главный technical
finding: на 3 примерах **deterministic Marina display rule не выводится** — H1
(tight orb), H2 (anchored half-width), H3 (drift skip) fit максимум 2 из 3
примеров; только H4 (editorial / non-deterministic) консистентна, что отменяет
Path 2 (engine fix) как viable option.

## Done

- Memo создан: `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`
  (757 строк, 7 sections + 2 appendices).
- Boundary data collected from `08-natalya-2025-2026.expected.json`:
  - **Uranus-Venus Square** (3 raw hits, 3 orb windows): все 3 boundaries
    совпадают с Marina ±0.5 d.
  - **Neptune-Jupiter Square** (5 raw hits, 3 orb windows): W1+W2 совпадают
    с Marina ±0.5 d; **W3 end engine 30.01.2028 vs Marina 16.02.2028 = +17d**.
  - **Neptune-Neptune Square** (4 raw hits, 3 orb windows): W2+W3 совпадают
    с Marina ±0.5 d; **W1 start engine 02.04.2024 vs Marina 27.09.2024 = +178d**.
- Engine code analysed: `Domain.TransitCalendar.findOrbWindows` (lines 333-404)
  + orb thresholds (lines 232-242). Per-planet orb for Neptune = 1.0° (mirror в
  `daragan-orbs-v1.json:transit_per_planet_class.Neptune`).
- 4 hypotheses tested on 3 examples; **H4 (editorial / non-deterministic) best
  fit** — единственная консистентная.
- Commit: `5a90416` в `ai-dev-system` repo, message с executive summary
  recommendation.
- Push: `backup master` parity verified (`3c42f04..5a90416`).

## Top-3 findings из § 4 hypothesis analysis

1. **Marina rule не deterministic**: N-J W1 и N-N W1 имеют идентичную morphology
   (D+R в одном orb window, similar exact timing offsets ~30d after orb_enter
   / ~37d before orb_exit), но Marina рисует одно как **full 160-day window**,
   другое как **15-day tail**. Никакая algorithm rule не объясняет эту
   асимметрию.
2. **Marina расширяет boundary за engine 1° threshold** (N-J W3 +17d), что
   несовместимо с tight-orb hypothesis. Любая uniform tighter/wider orb rule
   сломает другие windows того же случая.
3. **Engine emits 1.0° orb threshold for Uranus AND Neptune** — разница в
   per-card hit count (U-V 3 hits → 3 windows; N-J 5 hits → 3 windows; N-N 4
   hits → 3 windows) объясняется **только speed** транзитной планеты (Uranus
   быстрее, его orb window короткий + 1 phase; Neptune медленнее, его orb
   window длинный + 2 phases). Это семантически корректное поведение engine,
   Marina aggregates differently editorially.

## Path к memo

`/Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`

## Path к product repo commit

Product repo (`/Users/ilya/Projects/astro`) — **NOT TOUCHED**. Working tree
clean throughout, не было ни одного `git add` в product repo. TASK 4a per spec
analysis-only.

## Artifacts

- branch:               master (ai-dev-system); main untouched (astro)
- commit(s):            5a90416 (ai-dev-system)
- PR:                   нет
- tests:                **113 passed + 10 xfailed** unchanged (analysis-only TASK
                        не трогает test suite). Pre-baseline = post-baseline.
- Product repo status:  **not applicable** — astro repo untouched, working tree
                        clean.

## Pre-existing untracked files

Нет. Ни в `ai-dev-system` (только новый committed memo file), ни в `astro`
(working tree clean).

## Conflicts / risks

- **Path 2 не работает на 3 of 3 examples** — § 4 hypothesis findings конкретны.
  Если TL/user хочет Path 2 anyway (например, потому что Marina divergence
  продуктово неприемлема), Worker рекомендует первоначально опять перепроверить
  § 4 на 3-х примерах прежде чем запускать Tier A cascade — иначе высока
  вероятность landing partial fix + регрессии в других 8 cases.
- **Product call** на «приемлема ли Marina-vs-PDF разница на 2 boundaries
  (~22%)» — продуктовый вопрос, который Worker НЕ решает. Memo рекомендует
  технический Path 4 (closure 2 Cat 4 xfails через structured tolerance
  override), но **product implication** «PDF может показать N-N W1 = 02.04.2024
  вместо Marina 27.09.2024» остаётся как есть и в Path 4, и в Path 3, и
  возможно в Path 2 partial.
- **Editorial Marina rule** означает что любой future outer-planet case (TASK 7
  multi-case calibration) может выявить новые divergences. Path 4 предусматривает
  ad hoc additions to per-window override list — но scale concern: если > 10
  overrides — пересматривать подход.

## Next step

1. **TL читает memo** (757 строк, 7 sections + 2 appendices). Особое внимание:
   - § 4 hypothesis testing (best-fit H4, Path 2 disqualified).
   - § 6 Recommendation (Path 4 + 8-предложение rationale).
   - § 7 Next TASK templates per path.
2. **TL эскалирует на user** для продуктового decision:
   - «Marina-vs-PDF разница на 2 boundaries (N-J W3 end +17d, N-N W1 start
     +178d) — приемлема для клиентского показа?»
   - «Path 4 (test relaxation through structured exceptions) предпочтителен
     над Path 3 (permanent xfail) — согласны?»
3. **После user ack** — TL открывает один из:
   - **Path 4 (recommended):** TASK X «Phase 2 reopen: Neptune slow-loop window
     contract with structured exceptions». Tier C, Worker subagent, ~1 файл,
     ~50 LoC. Expected delta: 113/10 → 115/8.
   - **Path 3 (fallback):** NO TASK — только обновить STATUS_RU + program
     document § 6 ERRATUM cross-ref + (optionally) xfail reason text.
   - **Path 1:** TASK X с relaxation без exception structure (worse than Path 4
     for same effort).
   - **Path 2 (NOT recommended):** Tier A cascade с risk landing partial fix.
4. Phase 5/6/7 продолжают по программе после closure 4a.
