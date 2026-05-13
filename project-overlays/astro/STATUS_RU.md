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

**Phase 4 (Outer-planet cards generator) — ACCEPTED.** TASK 4 закрыт коммитом `8c9588d` на main:
- Path 3 implemented per user decision: allowlist-based 3 cards для Натальи (Уран ⬜ Венера, Нептун ⬜ Юпитер, Нептун ⬜ Нептун), Уран 150° Юпитер остаётся в календаре.
- Новый модуль `services/api-python/app/pdf/outer_cards.py` (~480 lines): allowlist config per case_id, aggregation raw hits → 3 display windows, build_outer_card → dict с 5 секциями Marina format.
- Closed card-facts per case_id (golden-rule data) считаны визуально из Marina pp. 18/20/21.
- Closed-dictionary psychology/event тексты — Marina-style paraphrase, не verbatim.
- Latin `c` (U+0063) в card title между «в квадрате» и «нат» — соответствует Marina эталону.
- xfail flips: 7 (6 Cat 3 outer structure + 1 Cat 7 regression). 2 Cat 4 Neptune interval xfails остаются с обновлённым reason `"TASK 4a — Neptune slow-loop contact window semantics"`.
- Tests: **113 passed + 10 xfailed = 123 total, 0 failed.**
- PDF `/tmp/natalya-phase4.pdf` — 3 cards присутствуют, Уран 150° Юпитер не карточка.

**Phase 4a (Transit contact window semantics) — ACCEPTED.** TASK 4a memo deliverable принят. Memo `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` (758 lines) с 7 sections: taxonomy 5 concepts, engine semantic analysis, Marina hypothesis testing (4 hypotheses на 3 examples), path analysis, recommendation.

Главный finding: **Marina display boundaries для slow outer loops не имеют deterministic rule.** H1 (tight orb), H2 (anchored half-width), H3 (drift skip) fit максимум 2 из 3 examples; только H4 (editorial / non-deterministic) консистентна. Killer evidence: N-J W1 и N-N W1 морфологически идентичны (D+R в одном orb window, similar timing offsets), но Marina рисует одно как 160-day full window, другое как 15-day tail. Engine `Domain.TransitCalendar` semantically корректен (1° orb threshold per planet class); Marina boundaries — editorial.

**Path 4 chosen (TL/user decision 2026-05-13):** structured editorial exceptions в test contract — engine не трогаем, 2 Cat 4 xfails закрываем через per-window tolerance override mechanism с явными reason-строками в коде. Implementation — TASK 4b (`neptune-window-structured-exceptions`).

**Phase 4b (Path 4 implementation) — ACCEPTED.** TASK 4b закрыт коммитом `d44d7c6` на main:
- Refactor `_assert_three_phase_intervals` с window-count + phase-set semantics + per-window 1-based tolerance overrides; импорт `aggregate_display_windows` из `outer_cards.py`.
- 2 structured editorial exceptions: Neptune-Jupiter Square W3 end ±20d, Neptune-Neptune Square W1 start ±200d. Reason-строки + cross-ref на memo § 4.4.
- User-spec vs engine reality reconciliation: spec listed N-J W2 = {Retrograde} и N-N W2 = {Retrograde} (вероятный typo), engine truth = {DirectReturn} для обоих. Worker применил engine truth, документировал в test comments. 2 typo flagged для пользователя.
- Unmark 2 Cat 4 Neptune xfails.
- Worker truncation post-implementation; TL salvage-commit'нул Worker'ову работу с явной attribution (subagent ID `a0d2e46652775fed8`).
- Tests: **115 passed + 8 xfailed = 123 total, 0 failed.**

**Phase 5 (Rulership-expanded target houses) — ACCEPTED.** TASK 5 закрыт коммитом `1d59431` на main:
- Path B (presentation-level) chosen; Path A не trigger'ил schema cascade.
- Новый модуль `services/api-python/app/pdf/rulership_houses.py` с `PLANET_RULES` dict (modern rulership), `cusp_sign()`, `rulership_houses()`, `target_house_set()`.
- Calendar-only scope соблюдён: `outer_cards.py` НЕ тронут (closed Phase 4 card-facts для golden-rule semantic зафиксированы).
- `transit_aspects_by_month` signature updated для приёма `natal_chart`; `solar.html.j2` обновлен под multi-house render; `builder.py` minimal Jinja context update.
- Calendar oracle Натальи validated против Marina pp. 22-23: Venus=[2,3,12], Mars=[3,8,9], Jupiter=[4,7], Neptune=[4,7]. Все 4 match exactly.
- Cusp validation: cusp 9 = 29.812° = Aries confirmed (НЕ Taurus); repeated cusp signs (Libra 2/3, Aries 8/9) корректно учитываются.
- 26 новых helper unit tests + 4 xfail flips (3 Cat 6 + 1 Cat 7 regression ban).
- Tests: **145 passed + 4 xfailed = 149 total, 0 failed.**

**Phase 6 (Per-context cutoff policy) — ACCEPTED.** TASK 6 закрыт коммитом `a1891cc` на main:
- Two-window-pair architecture в `transit_aspects_by_month`: `actual_*` для dedup / `_MIN_WINDOW_DAYS` / quincunx filter; `calendar_*` для presentation (`period_*_str`, `orb_*_jd` calendar entry output, bucket assignment).
- `calendar_start_jd = max(actual_start_jd, sr_jd)`, `calendar_end_jd = min(actual_end_jd, sr_jd + 365.25)`. Row drop если clipped >= clipped (полностью вне solar year), ПОСЛЕ dedup/filter на actual values.
- **Semantic shift в calendar context**: `orb_enter_jd` / `orb_exit_jd` per calendar entry output = clipped display bounds. Outer cards (Phase 4) НЕ затронуты (используют raw engine через `aggregate_display_windows`).
- Calendar oracle Натальи validated: `Нептун 90° Юпитер` clipped до `07.08.2026`; `Уран 0° MC` clipped до `07.08.2026`. No 2024/2027/2028 in calendar.
- Outer cards regression check passed — full loop dates (02.04.2024, 12.10.2024, 21.02.2027, 30.01.2028) intact в interval lists.
- 4 Phase 6 Cat 5 xfails flipped → passing.
- Один existing test (`test_calendar_short_windows_filtered`) adapted к Phase 6 semantic shift — flagged в Worker HANDOFF для TL ack.
- Tests: **149 passed + 0 xfailed + 0 failed.** Все Phase 4/5/6 acceptance contracts закрыты.

**Программа Transit Section Recovery — implementation work complete.** Phase 0/1/2/3/4/4a/4b/5/6 — все CLOSED. Остаётся Phase 7 multi-case calibration (validation).

**Phase 7 Stage A (Multi-case calibration) — ACCEPTED с verdict «Blockers identified — program NOT production-ready».** TASK 7 закрыт; Stage B не authorized. Calibration report в overlay `ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (423 lines).

Worker validated TL pre-mapped Marina inventory (3/3 cases confirmed, return_jd Δ < 60s). Per-case Stage A diff vs Marina:
- **05-ekaterina:** monthly table 51/52 cells match (1 Venus boundary diff = TYPE-A); per-house OK; outer-cards empty (TYPE-A allowlist gap); calendar OK.
- **07-mariya:** monthly table **6/13 cells match — TYPE-B regression** в `transit_themes.py:transit_matrix_by_month` (label-arithmetic bug); per-house OK; outer-cards correctly empty (matches Marina editorial); calendar OK.
- **10-danila:** monthly table 13/13 match; per-house OK; outer-cards empty (TYPE-A gap); calendar OK; case-10 card 3 has 4 windows not 3 (TYPE-C Marina editorial).

**TYPE-B root cause:** `transit_matrix_by_month` uses `sr + i * 30.4375` fractional iteration. Natalya was «lucky» (sr 07.08 ~02:30 UT → consecutive months). Case 07 Мария (sr=01.07.2025 19:11 UT) → i=2 lands 31.08.2025 = still August → label «Август 2025» duplicates, September never computed. 2 duplicate labels, 2 missing months, 6 wrong cells.

**Override count:** 2 / 10 (within Phase 4b gate threshold).

**Phase 7b (Multi-case calibration — Stage A re-validation + Stage B) — deferred until TASK 7a fix lands.**

**TASK 7a (Transit monthly table label-arithmetic fix) — ACCEPTED.** Commit `8a4865e` на main:
- Fix: integer calendar-month advance в `transit_matrix_by_month` (lines 546-588, 24 ins / 11 del). `datetime(y, m, 15, UTC)` для mid-month anchor; `[1st, next-1st)` для window. No new deps.
- Regression test `test_mariya_transit_matrix.py`: full equality `actual_labels == [Июль 2025, ..., Июль 2026]` (13 unique consecutive).
- Natalya baseline preserved 1:1 (mid-15 UTC anchor identical pre/post fix для Натальи early-UT solar return).
- Tests: **149/0/0 → 150/0/0** (regression test добавлен).

**TASK 7b (Phase 7 Stage A re-validation + Stage B closed-config calibration) — spec готов, Ready: no, ждёт ack пользователя.** TASK `2026-05-13-phase-7-stage-b-closed-config-calibration.md`. Финальная implementation TASK программы. Tier C / Mode normal / Layer services.

Stage A.2 re-validation: case 07 monthly table expected 13/13 cells post-fix; case 05/10 без regression. Stage B closed-config:
- Extend `outer_cards.py:OUTER_CARD_ALLOWLIST` для 05-ekaterina (3 triples per Marina pp. 34-37) и 10-danila (3 triples per Marina pp. 16-19). Closed card-facts populated.
- Case 10 card 3 = 4 windows (не 3) — generalize `_assert_three_phase_intervals` helper для parametrized window count.
- Create `services/api-python/scripts/render_case.py` (parametrized canonical render).
- Single parameterised test файл `test_multi_case_calibration.py`.
- Update calibration report § 3/4/5/6 с post-Stage-B results.
- Final production-readiness verdict.

**Production-readiness gate:** PDF Марине **не показывается до**: (1) TASK 7b closes с verdict «Ready for Marina show — pending user ack»; (2) **явный отдельный user ack** на updated calibration report.

**Известный editorial разрыв (документировать честно):** Path 4 закрывает **тестовую дисциплину**, не превращает 2 даты в «совпавшие». PDF продолжает рендерить engine-derived dates; Marina при показе видит engine boundaries для 2 Neptune windows, не свои эталонные. Это **known editorial divergence, accepted TL/user 2026-05-13**, не regression и не engine bug.

**Phase 7 gate clause:** если multi-case calibration (Phase 7) покажет накопление similar Neptune (или other slow-mover) overrides (>5 за case или >10 across all cases) — это сигнал что Path 4 структура не масштабируется и нужно пересмотреть продуктовый подход (возможно отдельный presentation-layer editorial override механизм). Phase 7 Worker фиксирует override count в HANDOFF; threshold exceeded → TL эскалирует пользователю до closing Phase 7.



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

- **Ack на TASK 7b spec.** Прочитать `project-overlays/astro/TASKS/2026-05-13-phase-7-stage-b-closed-config-calibration.md`. Stage A.2 re-validation + Stage B closed-config calibration (allowlist extensions для 05/10 + render_case.py + multi-case tests + calibration report update + final production-readiness verdict). После closing + явного user ack → recovery program closes; PDF Марине можно показывать.
- **Когда показывать Марине** — после закрытия всей программы (Phase 0-7) и финального ack пользователя. До этого PDF — внутренний debug/QA артефакт. Известный editorial разрыв на 2 Neptune boundaries (N-J W3 +17d, N-N W1 +178d) **будет видно Марине при показе**; это accepted divergence, но Marina об этом не знает заранее — TL подготовит ей framing в момент показа.

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
- **Phase 4** (outer-planet cards generator) — **CLOSED** 2026-05-13 (TASK 4 accepted, commit `8c9588d`, Path 3 7 xfail flips + 2 Cat 4 reason updates).
- **Phase 4a** (Transit contact window semantics — analysis memo) — **CLOSED** 2026-05-13 (TASK 4a accepted, memo deliverable, Path 4 chosen by TL/user).
- **Phase 4b** (Neptune window structured exceptions — Path 4 implementation) — **CLOSED** 2026-05-13 (TASK 4b accepted, commit `d44d7c6`, 2 Cat 4 xfail flips, Worker truncation salvaged).
- **Phase 5** (rulership-expanded target houses) — **CLOSED** 2026-05-13 (TASK 5 accepted, commit `1d59431`, Path B presentation-level, 4 xfail flips, 26 new helper tests).
- **Phase 6** (per-context cutoff policy) — **CLOSED** 2026-05-13 (TASK 6 accepted, commit `a1891cc`, 4 Phase 6 xfail flips, two-window-pair architecture).
- **Phase 7 Stage A** (multi-case calibration validation) — **CLOSED** 2026-05-13 с verdict «Blockers identified» (TYPE-B regression в case 07 monthly table; calibration report committed). Stage B deferred.
- **TASK 7a** (transit monthly table label-arithmetic fix) — **CLOSED** 2026-05-13 (commit `8a4865e`, 149/0/0 → 150/0/0, Natalya baseline preserved, case 07 13 labels validated).
- **TASK 7b** (Phase 7 Stage A re-validation + Stage B closed-config calibration) — **готов, ждёт ack пользователя.** Финальная implementation TASK программы. После closing + user ack → recovery program closes; PDF можно показывать Марине.
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
