# Статус — Astro

Дата последнего обновления: 2026-05-13.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **Программа Transit Section Recovery в работе. Phase 0/1/2 закрыты. Phase 3 spec готов (ack pending). Worktree merged в main.**

**Phase 1 (Single source of truth + render provenance) — ACCEPTED.** TASK 1 закрыт коммитом `9793d5d`, теперь на `main` (после fast-forward merge `claude/dreamy-moore-46f5eb` → `main`):
- Canonical render entry point: `services/api-python/scripts/render_natalya.py` с CLI флагами (`--mode {fixture-render,recompute}`, `--output`, `--debug`, `--facts`, `--input`).
- Render provenance module: `services/api-python/app/pdf/provenance.py`. Sidecar JSON `<output>.pdf.provenance.json` рядом с PDF; 13 keys (git SHA, repo root, render script, facts path+hash, input fixture path+hash, mode, core CLI path+hash, timestamp UTC, worktree branch) + bonus debug_mode + extra.
- Opt-in debug footer в `solar.html.j2`: guarded by `provenance_meta.debug_mode`; на клиентских PDF не виден (text-extract verified).
- Tests: 94/94 green (85 baseline + 9 новых в `test_provenance.py`).
- Workspace cleanup: forensic listing `/tmp/render_*.py` в HANDOFF (5 files), не удалены per policy. Внутри repo нет alternative render entry points.

**Phase 2 (Hard acceptance assertions) — ACCEPTED.** TASK 2 закрыт коммитом `fb47aca` на main:
- `services/api-python/tests/test_natalya_transits_acceptance.py` — 29 assertions в 7 категориях по § 6 архитектурного документа.
- `services/api-python/tests/conftest.py` — session-scoped fixtures (canonical render once per test session, pypdf text extraction).
- Стратегия `@pytest.mark.xfail(strict=True, reason="Phase N — ...")` — assertions фиксируют контракт **сейчас**, закрытие Phase 3/4/5/6 переведёт xfailed → xpassed → strict flip заставит Worker unmark.
- Distribution: **8 passed** (Category 1 Render provenance + 4 regression guards already-satisfied) + **21 xfailed** (Phase 3 = 5, Phase 4 = 11, Phase 5 = 4, Phase 6 = 4).
- Tests: **102 passed + 21 xfailed = 123 total, 0 failed.**

**Worktree merged.** `claude/dreamy-moore-46f5eb` → `main` fast-forward сделан перед TASK 2 (commit `9793d5d` теперь HEAD `main`, backup parity ✓). Worktree directory orphaned (same SHA как main); pruning — отдельное user decision, не блокер.

**Lesson from Phase 2 verification — cabal build hygiene.** Worker Phase 2 первоначально обнаружил 9 «pre-existing» failures в `test_golden_cases.py` на baseline `9793d5d`. Расследование: stale cabal cache (source `TransitCalendar.hs` менялся в Tier A, но binary cache на main был stale после merge). После `cabal build` все 9 проходят. **Дисциплина для следующих Phase Worker'ов:** при работе с engine или после смены ветки — обязательный `cabal build` перед pytest. Worker может рассчитывать что cabal cache stale пока не доказано иначе.

**Phase 3 (Transit horizon split) — ACCEPTED.** TASK 3 закрыт коммитом `70185b0` на main:
- Path B выбран (presentation-level, Tier C). Engine + schema не тронуты.
- `transit_themes.py`: `solar_year_transits(att, sr_jd)` + `loop_transit_windows(att)` view filters; `houses_visited()` accepts `horizon=` param с default `solar_year`.
- `synthesis_themes.py`: routed на solar-year view, suppress out-of-year `exit_jd` tails в «Выводы:» / themed prose / «Итоги консультации».
- `solar.html.j2`: per-house section passes explicit `solar_return_jd` from `facts.solar_chart.return_jd`.
- Verify: PDF Натальи (`/tmp/natalya-phase3.pdf`) — Saturn houses `[7, 8]`, no `Сатурн в 6 доме`, no `2024/2027/2028` в per-house section и synthesis.
- xfail flips: 4 tests (saturn houses, saturn-6-pdf, horizon-param, regression ban). Phase 5/6 xfails остаются untouched.
- Tests: 106 passed + 17 xfailed = 123 total, 0 failed.

**Phase 4 (Outer-planet cards generator) — Path 3 decision applied, Worker reopen pending.** TASK `2026-05-13-outer-planet-cards-generator.md`, Ready: yes. Tier C / Mode normal / Layer services.

После первого Worker preflight 2026-05-13 (BLOCKED — Neptune interval contract mismatch) — пользователь принял **Path 3 decision**: Phase 4 строит карточки с консолидацией raw hits в 3 display windows best-effort (для PDF parity с Мариной), но **НЕ закрывает Category 4 Neptune interval xfails**. Acceptance retroactively суживается с 9 → **7 xfail flips** (6 Cat 3 структура + 1 Cat 7 regression ban).

**Phase 2 erratum:** прежняя формулировка «строго 3 касания» в архитектурном документе оказалась неточной. Marina-style «касание» = **display/orb window**, не **raw engine hit per motion phase**. Erratum записан в § 6 architecture document; решение по correct contract semantics — отдельный TASK 4a после Phase 4 close.

Жёсткие запреты Path 3 для Phase 4 Worker'а: НЕ модифицировать `_assert_three_phase_intervals` (Path 1 маскирует root cause), НЕ хардкодить Marina-date overrides, НЕ перезаписывать `expected.json`, НЕ unmark Cat 4 xfails (только обновить их `reason` строку на `"TASK 4a — Neptune slow-loop contact window semantics"`).



**Tier A engine cascade (2026-05-11/12) принят и удержан.** Math engine стабилен:
- Quincunx revoke (scope = transit calendar only) — работает.
- Per-loop-pass orb-window scanner (orb_enter_jd / orb_exit_jd) — работает.
- Cross-year sample window (540d до/после соляра) — работает.
- Per-planet orb calibration (J/S/U/N = 1.0°, P = 1.25°) — эмпирически выведена по Натальину PDF.
- Schema cascade выполнен одним atomic коммитом (bright-line #8) — `5f4fbc9`.
- Tests: `cabal test` 242/242, `pytest` 85/85 — зелёный.

**Tier C presentation rebuild (2026-05-12) — преждевременный accept.** Проверка ограничилась календарём, monthly table и заголовками. Полная постраничная сверка раздела с эталоном не выполнялась. После сверки пользователем 2026-05-13:
- В трактовках по домам появился `Сатурн в 6 доме` (из расширенного horizon-а engine'а, 2024 год).
- Отсутствуют outer-planet карточки эталона (Уран-Венера, Нептун-Юпитер, Нептун-Нептун) с таблицами «Золотое правило транзита».
- «Дома цели» считаются placement-only без rulerships (теряются темы 2/3/7 у разных аспектов).
- Не разделены горизонты данных: один `annual_transit_table` используется и для солярного года (трактовки) и для full-loop scan (карточки).
- Конфликт артефактов: PDF собирался из worktree, основной repo содержит другой шаблон, render не несёт provenance.

**Программа recovery зафиксирована** в `ARCHITECTURE/transit-section-program-2026-05-13.md` — 8 секций (статус/gate, дефекты, root causes, архитектурное решение, фазы 0-7, hard acceptance assertions, запреты, порядок TASK'ов). Это новый SoT для всех presentation-работ по транзитам до закрытия программы.

Артефакты:
- Программа: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- Последний (нерабочий по презентации) PDF: `/tmp/astro-natalya-monthstart-iter1.pdf` — debug/QA only, не показывать.
- Продуктовый repo: ветка `claude/dreamy-moore-46f5eb`, последний commit `6894743`. Главная ветка `main` не тронута.
- Тесты зелёные, но не являются acceptance contract против Марины — это будет покрыто в Phase 2.

## Ждёт твоего решения

- **Ack на TASK 4 spec.** Прочитать `project-overlays/astro/TASKS/2026-05-13-outer-planet-cards-generator.md`. Особое внимание — scope discipline («строго 3 карточки», Уран 150° Юпитер не становится карточкой), identification rule, closed-dictionary тексты для психологии/событийного уровня. Без ack Worker не стартует — Ready: no.
- **Когда показывать Марине** — после закрытия всей программы (Phase 0-7) и финального ack пользователя. До этого PDF — внутренний debug/QA артефакт.

Локальная ветка `claude/dreamy-moore-46f5eb` остаётся (deferred cleanup) — не блокер.

## Срочные риски

**Программа Transit Section Recovery открыта.** Все работы по транзитному presentation проходят через `ARCHITECTURE/transit-section-program-2026-05-13.md`. До закрытия программы:

- запрещено перезаписывать `expected.json` golden fixtures результатом текущего engine без diff review и hard acceptance tests;
- запрещено считать зелёные snapshot tests доказательством близости к Марине;
- запрещено использовать full-loop horizon для текстов про текущий соляр;
- запрещено держать main и worktree как равноправные источники PDF;
- запрещены Worker subagents на Phase 3-7 пока Phase 1 + Phase 2 не закрыты;
- запрещён показ PDF Марине до закрытия программы.

Дрейф между prescribed architecture (phases 0.1/0.2) и фактическим кодом (0.5+) — без изменений с 2026-05-06. Не пожар.

## На очереди

Программа Transit Section Recovery, фазы 0-7:

- **Phase 0** (freeze + audit trail) — **CLOSED** 2026-05-13 (architecture document + STATUS_RU freeze).
- **Phase 1** (single source of truth + render provenance) — **CLOSED** 2026-05-13 (TASK 1 accepted, commit `9793d5d`, worktree merged в main).
- **Phase 2** (hard acceptance assertions) — **CLOSED** 2026-05-13 (TASK 2 accepted, commit `fb47aca`, 29 hard assertions с xfail-strict).
- **Phase 3** (transit horizon split) — **CLOSED** 2026-05-13 (TASK 3 accepted, commit `70185b0`, Path B presentation-level, 4 xfail flips).
- **Phase 4** (outer-planet cards generator) — **Path 3 applied, Worker reopen in progress.** Tier C, Marina-reference oracle pp. 17-22. После landing: **7 xfail tests** flip → passed (Cat 3 структура + 1 Cat 7 regression). 2 Cat 4 Neptune interval xfails остаются — открывается TASK 4a после close.
- **Phase 4a** (Transit contact window semantics for slow outer loops) — **открывается после Phase 4 close.** Формализует `raw hit` / `motion phase hit` / `orb window` / `display contact` / `tight Marina window`; решает scope (Tier C test-contract или Tier A engine semantic). Это backlog item на момент 2026-05-13.
- **Phase 4** (outer-planet cards generator) — только для тех outer-aspects, что представлены в эталоне как карточки.
- **Phase 5** (rulership-expanded target houses) — Tier C с эскалацией до Tier A при shared core helper.
- **Phase 6** (per-context cutoff policy) — explicit clipping rules.
- **Phase 7** (multi-case calibration) — default cases 05/07/10, либо обоснованный выбор 3 из 8.

Backlog вне программы (на паузе до её закрытия):
- `solar-nodes-lilith-retro-display` — Tier A, без явного запроса Марины не запускать.
- `consultation-summary-matrix-rewrite` — пауза.
- `section-order-recon` — пауза.

## Не делаем сейчас

- **«Solar nodes / Lilith / retro display» без её явного запроса.** Tier A.
- **Публичный хостинг репозитория** (GitHub / GitLab / Gitea). Без отдельного «ок» не добавляем.
- **SaaS-направление и B2C-сайт.** Сняты, проект — внутренний инструмент.
- **Полная сверка архитектурного документа с фактическим кодом.** Откладывается.
- **Презентационные правки раздела Транзиты вне программы Transit Section Recovery.** Все правки идут через её phases в указанном порядке.
- **Дальнейшая калибровка орбисов транзитного движка на одном Натальином case.** Per-planet значения выведены эмпирически; расширение калибровки требует ≥3-5 cases (Phase 7 программы).
