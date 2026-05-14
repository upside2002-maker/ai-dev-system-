# Статус — Astro

Дата последнего обновления: 2026-05-14.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **Программа Transit Section Recovery — REOPENED 2026-05-14, Phase 8 в работе.**

**Verdict update (post-Phase-8-audit, 2026-05-14):** «**Partial pass — только 08 Наталья production-ready**». Закрытие TASK 7b 2026-05-13 было **преждевременным** — manual audit (Codex + TL 2026-05-14) на clean checkout обнаружил, что multi-case тесты Stage B проверяли количество outer-card окон, но **не их boundary даты** vs Marina. Worker'овский pytest baseline 183/0/0 правда зелёный, но контрактная дыра в TASK 7b § B.4 пропустила реальные расхождения. **Дисциплинарная ответственность — на PTL за spec, не на Worker'е.**

**5 находок Phase 8.0 audit:**
1. **Test contract gap:** `test_multi_case_calibration.py` не assert'ит outer-card interval boundaries; spec gap в TASK 7b § B.4.
2. **Данила Neptune boundary regression** (TYPE-B-equivalent, не accepted divergence): Нептун кв Венере W3 end `28.01.2028` vs Marina `07.03.2028` (+38d); Нептун кв Юпитеру W4 end `28.01.2028` vs Marina `18.03.2028` (+49d). Оба заканчиваются на identical `orb_exit_jd = 2461798.822368622` — finite-horizon engine sample window truncation, не Marina editorial. **Это новый class дефекта, отличный от Phase 4b Натальи accepted divergences.**
3. **Allowlist gap:** Cases 01/02/03/04/09 — у нас 0 outer cards, у Marina 2-9 cards per case. TYPE-A (closed-config gap, аналог решения TASK 7b Stage B для 05/10).
4. **Lexical divergence case 05:** card title «Нептун в **трине** с нат Юпитером», Marina «Нептун в **тригоне**». One-word fix.
5. **Data-quality blockers (TYPE-D, отдельный класс):** `Соляр 2025-2026_3.pdf` — fixture missing natal metadata; Анастасия — fixture/reference SR-time/timezone mismatch. Не code regressions; требуют отдельной data revision.

**Recovery program closure summary (2026-05-13, преждевременный — теперь historical record):**
- Production HEAD: `c936dd1` (astro main = backup/main).
- Pytest: 183 passed, 0 xfailed, 0 failed (тесты зелёные, но contract incomplete).
- Override count: 2 / 10 (Phase 4b Натальи Neptune; threshold preserved).
- Phase 4b structured editorial exceptions на Натальи (2 Neptune boundaries) — accepted divergence; будет видно Марине при показе, framing подготовит TL.
- 5 TYPE-A items в § 4 калибровочного отчёта (anchor-day monthly boundaries): items 1, 2 [RESOLVED via Stage B]; items 3, 4, 5 — anchor-day boundary divergence, documented note-only.
- Канонический render path: `services/api-python/scripts/render_case.py --case-id <case-id> --output <path>`.
- Полная история: `ARCHITECTURE/transit-section-program-2026-05-13.md` + `transit-multi-case-calibration-report-2026-05-13.md` + archived TASKs.

**Phase 8 sub-phases:**
- **Phase 8.0** (audit trail reopen, TL inline overlay-only): **в работе сейчас** — STATUS_RU downgrade + calibration report § 6 verdict update.
- **Phase 8A** (read-only full-folder audit): следующий TASK после 8.0 closes. Inventory всех Marina etalon PDFs из `/Users/ilya/Downloads/Gmail (3)/`, per-case diff (outer-card count/titles/interval boundaries/golden-rule/calendar/monthly/per-house smoke), classification TYPE-A/B/C/D, prioritized fix plan.
- **Phase 8C** (test contract first): boundary assertions в `test_multi_case_calibration.py` (start/end ±2 дня, structured overrides только где явно решено). **Must первым поймать Данилу красным.** Без этого «зелёные тесты, дырка в факте» снова повторится.
- **Phase 8B** (fixes, отдельный TASK после 8A+8C closes): lexical «трине → тригоне»; Данила — **не accepted divergence**, либо расширить loop horizon, либо явно маркировать truncated windows; allowlist/facts 01/02/03/04/09 (отдельный подэтап после 8A inventory).

**Phase 8A+8C — один комбинированный Worker TASK** (audit + test contract — должны идти вместе, потому что 8C boundary assertions используют 8A Marina-listed dates как single source of truth).

**Phase 8B — отдельный TASK** после 8A+8C closes (фиксы поверх audit findings).

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

**TASK 7b (Phase 7 Stage A re-validation + Stage B closed-config calibration) — Worker hit STOP gate, ждёт TL/user decision.** TASK `2026-05-13-phase-7-stage-b-closed-config-calibration.md`, overlay commit `b8188e1` (Ready: yes). Worker subagent отработал Stage A.2 + создал `render_case.py` (Stage B.3, untracked) и STOP'нул на gate `case 07 < 13/13`.

**Stage A.2 outcome:**
- **Case 07 Мария monthly table = 11/13 rows match Marina** (не 13/13). 13 labels post-TASK 7a fix correct. 2 residual mismatches:
  - Июнь 2026: ours M=9/S=7/J=10/V=11 vs Marina 8/7/10/10 (Mars и Venus boundary).
  - Июль 2026: ours M=9/S=8/J=11/V=12 vs Marina 9/7/11/11 (Saturn и Venus boundary).
- **Cases 05, 10 — no regression.** Case 05 = 51/52, case 10 = 52/52 (sustained).
- **Stage B (B.1, B.2, B.4, B.5, B.6) — НЕ начат.** Только B.3 `render_case.py` создан (Stage A.2 prerequisite, authorized в spec).

**Diagnosis (Worker analysis, TL-verified):** 2 mismatched rows = **TYPE-A boundary anchor diffs**, не TYPE-B regression. Marina anchors monthly cells at **01 числа** (day-of-solar-return = 1st of solar month); наша конвенция = **mid-15** (`datetime(y, m, 15, UTC)`). Cusp transitions в 15-day gap:
- Mars 2026-06-05 (h=8→9), Venus 2026-06-11 (h=10→11) — Marina samples 01.06 (still h=8/10), ours samples 15.06 (already h=9/11).
- Saturn 2026-07-08 (h=7→8), Venus 2026-07-08 (h=11→12) — same family.

Это **same family как case 05 Venus Jul 2025 boundary** (calibration report § 4 item 3 TYPE-A note). TASK 7a fix targeted label arithmetic (`sr + i*30.4375` → integer calendar advance); cell values rows 12/13 идентичны pre/post TASK 7a — это не regression от 7a, это pre-existing convention gap.

**HANDOFF Worker→TL:** `project-overlays/astro/HANDOFFS/archive/2026-05-13-worker-to-tl-phase-7-stage-b-closed-config-calibration.md`. Override count unchanged: 2 (Натальи Phase 4b) — within threshold. Pytest baseline preserved 150/0/0.

**Решение пользователя 2026-05-13: Path D.** Открыт **TASK 7c** (`2026-05-13-phase-7c-gate-amendment-typea-monthly-boundary.md`, Tier C overlay-only, no Worker, TL inline). 5 fixations по user direction:
1. Case 07 labels — PASS (13/13 unique consecutive Июль 2025 → Июль 2026, TASK 7a сработал).
2. Case 07 monthly cells — 11/13 exact, 2 TYPE-A divergences (rows 12-13 Mars/Venus и Saturn/Venus).
3. Cause — deterministic anchor convention difference (Marina 01st vs наш mid-15), не Phase 7a regression, не label arithmetic bug.
4. Stage B gate amendment — 4 conditions (a)-(d): no dup/missing labels, no TYPE-B regressions, mismatches только в documented TYPE-A boundary rows, report verdict honest.
5. No product-code change в 7c — только TASK 7b spec + calibration report + STATUS_RU.

Path B (anchor convention convergence) deferred — strategically возможен, но scope wide (full Phase 1-7 re-validation Натальи + 05/07/10). Path C (STOP program) отклонён — теряем multi-case sense. Path D предпочтительнее Path A процедурно (отдельный TASK = явный ack-trail).

**TASK 7c — ACCEPTED + archived 2026-05-13.** Overlay commit `6b768ae`. Inline-применение: TASK 7b Stage A.2 gate amended (literal `13/13` → conditions (a)-(d)); calibration report § 3.2 (post-TASK-7a snapshot), § 4 (TYPE-A items 4-5 для case 07 rows 12-13 с cross-ref на item 3), § 6 (verdict update + follow-up reorg); STATUS_RU narrative обновлён. User ack на closure received → TASK 7b Worker resumes на Stage B per amended gate.

**TASK 7b — Stage B Worker resume — ACCEPTED.** Commit `c936dd1` на main:
- Stage B closed-config calibration landed: B.1 (case 05 outer cards 3 triples + facts из Marina pp. 34-37), B.2 (case 10 outer cards 3 triples + facts из pp. 16-19; case 10 card 3 = 4 windows engine output natively), B.3 (`render_case.py` committed), B.4 (`test_multi_case_calibration.py` — 33 parameterized tests), B.5 (case 05 Venus Jul 2025 = TYPE-A note only), B.6 (calibration report final update).
- Test helper `_assert_three_phase_intervals` generalized: optional `expected_window_count: int = 3`. Phase 4b Натальи структурные overrides — без изменений.
- Doc/comment generalization («3 intervals / три касания» → «3+ per Marina card») в `outer_cards.py` + `solar.html.j2`. **0 semantic code change** вне ALLOWLIST + FACTS extends.
- 0 новых tolerance overrides; всего 2 (Phase 4b Натальи). Threshold preserved (≤ 10 total; ≤ 5 per case).
- Engine / Haskell core / schema / fixtures / `transit_themes.py` / Phase 4b structured overrides — **0 lines changed**.
- Tests: **183 passed + 0 xfailed + 0 failed** (150 baseline + 33 new). cabal build up-to-date. backup parity ✓.
- **Production-readiness verdict (calibration report § 6): «Ready for Marina show — pending user ack».**

**Production-readiness gate — PASSED 2026-05-13.** (1) TASK 7b closed с verdict «Ready for Marina show — pending user ack» ✓; (2) **explicit user ack на updated calibration report received 2026-05-13** ✓. Программа Transit Section Recovery **CLOSED**. PDFs cases 05/07/08/10 — production-ready (показывать Марине разрешено).

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

- **Ack на TASK 8.0 closure** (audit-trail downgrade, overlay-only, TL inline). Все правки в одном commit: TASK 8.0 file + STATUS_RU downgrade + calibration report § 6 «Verdict update (post-Phase-8-audit, 2026-05-14)». Product код 0 строк; pytest baseline preserved; backup parity ✓. После ack → draft TASK Phase 8A+8C для review.
- **Ack на TASK Phase 8A+8C spec.** TL draft'ит spec для audit + boundary test contract (combined Worker TASK). Презентация на review (Ready: no) перед Worker launch.
- **Показ Марине — parallel artifact track, доступно сейчас:**
  - **Можно (independent of Phase 8):** Только Наталю. Fresh PDF `/tmp/08-natalya-2025-2026-c936dd1.pdf` + sidecar `git_sha = c936dd15169c...` (rendered 2026-05-14 post-closure). TL подготовит framing memo для Marina про 2 Phase 4b Neptune accepted divergences (N-J W3 +17d, N-N W1 +178d) по запросу.
  - **Нельзя:** Показывать «пакет» (05/07/08/10) или говорить «вся папка закрыта». Phase 8 ещё open; case 10 Данила имеет confirmed boundary regression (+38d, +49d); cases 01/02/03/04/09 — allowlist gap; case 05 — lexical «трине» divergence.

Локальная ветка `claude/dreamy-moore-46f5eb` остаётся (deferred cleanup) — не блокер.

## Срочные риски

**Программа Transit Section Recovery — REOPENED 2026-05-14, Phase 8 в работе.** TASK 7b closure 2026-05-13 был премат-clos'нут — contract gap в тестах Stage B (boundary assertions missing). **Дисциплинарная ответственность — на PTL** за неполный spec TASK 7b § B.4.

**Текущая Phase 8 discipline:**
- **Показывать Марине разрешено только Наталю** (с Phase 4b framing про 2 Neptune accepted divergences); НЕ показывать «пакет» PDFs до закрытия Phase 8.
- Финальные client PDFs (Наталя) рендерить только через `services/api-python/scripts/render_case.py --case-id 08-natalya-2025-2026` на HEAD `c936dd1` или новее. Provenance sidecar должен показывать актуальный `git_sha`.
- Case 10 Данила, cases 01/02/03/04/09, case 05 lexical — **не показывать** до Phase 8B fix landed.
- `_3.pdf` и Анастасия — TYPE-D data quality blockers, держать отдельно от code regressions.
- Phase 8C boundary assertions: должны **сначала** поймать Данилу красным, до любого fix attempt. Worker'ы Phase 8B не trogают product code пока 8C contract не landed + RED.

**Historical дисциплина (на время программы 2026-05-11 → 2026-05-13) — задокументирована в `ARCHITECTURE/transit-section-program-2026-05-13.md`; во время программы запрещалось:**
- перезаписывать `expected.json` golden fixtures результатом текущего engine без diff review;
- считать зелёные snapshot tests доказательством близости к Марине;
- использовать full-loop horizon для текстов про текущий соляр;
- держать main и worktree как равноправные источники PDF;
- Worker subagents на Phase 3-7 пока Phase 1 + Phase 2 не закрыты;
- показ PDF Марине до закрытия программы.

**Phase 4b 2 Neptune editorial divergences (N-J W3 end +17d, N-N W1 start +178d) на Натальи — accepted divergence per Path 4 / TASK 4b**; TL framing для Марины перед показом Наталю обязателен.

**Anchor convention (mid-15 vs Marina 01st) — 5 TYPE-A boundary rows документированы в калибровочном отчёте § 4. Path B convergence — отдельная будущая программа если потребуется.

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
- **TASK 7b** (Phase 7 Stage A re-validation + Stage B closed-config calibration) — **CLOSED** 2026-05-13 (commit `c936dd1`, 150 → 183 passed, calibration report verdict «Ready for Marina show — pending user ack»). Финальная implementation TASK программы. **NEXT — user explicit ack** на updated calibration report → recovery program closes; PDF можно показывать Марине.
- **TASK 7c** (overlay-only gate amendment, TYPE-A monthly boundary) — **CLOSED** 2026-05-13 (overlay commit `6b768ae`, amended gate (a)-(d) для Stage A.2 → Stage B continuation).
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
