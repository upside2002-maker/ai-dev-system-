# HANDOFF: worker → tl — outer-planet-cards-generator

- Status: closed
- Date: 2026-05-13 13:25
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-outer-planet-cards-generator.md

## Summary

**COMPLETED — Phase 4 Path 3 closed.** Outer-planet cards generator реализован для Натальи как allowlist-based закрытый словарь с aggregation engine raw hits в Marina-style display windows. Все 3 карточки (Уран-Венера, Нептун-Юпитер, Нептун-Нептун) рендерятся в PDF с пятью секциями Marina формата. Уран 150° Юпитер остаётся в календаре, не создаёт карточку. Test contract Path 3 выполнен: **113 passed + 10 xfailed** (7 xfail flips: 6 Cat 3 + 1 Cat 7; 2 Cat 4 Neptune остаются xfail с обновлённым reason `"TASK 4a — Neptune slow-loop contact window semantics"`).

## Done

- **Прочитан полный reading order:** TASK (Path 3 scope), architecture document § 6 erratum, archived preflight HANDOFF (для понимания engine emission pattern), Marina эталон pp. 17-22 (3 карточки + golden-rule таблицы + интервалы), CLAUDE.md, architecture-invariants.md, corrections.md, all Phase 1-3 артефакты (transit_themes.py public helpers, conftest fixtures, builder + template).
- **Verified aggregation logic** на engine facts:
  - Uranus Square Venus: 3 raw hits → 3 unique (orb_enter, orb_exit) windows.
  - Neptune Square Jupiter: 5 raw hits → 3 unique windows (window 1 phases=[Direct, Retrograde], window 3 phases=[Retrograde, DirectReturn]).
  - Neptune Square Neptune: 4 raw hits → 3 unique windows (window 1 phases=[Direct, Retrograde]).
  - Uranus Quincunx Jupiter: 3 raw hits → 3 windows (для diagnostic — но НЕ в allowlist, в карточку не идёт).
- **Создан новый модуль `services/api-python/app/pdf/outer_cards.py`** (~480 строк) с:
  - `OUTER_CARD_ALLOWLIST` per case_id (для `08-natalya-2025-2026` — 3 triples).
  - `aggregate_display_windows()` — группирует raw hits по уникальным rounded `(orb_enter_jd, orb_exit_jd)` tuples в display «касания», с set of phases per window и touch_index = 1..3.
  - `identify_cards_for_case()` — фильтрует engine output по allowlist.
  - `build_outer_card()` — собирает 5-секционный dict per Marina format (title, intervals, golden_rule 4-row table, psychology, event_level).
  - **Closed card-facts** (`_OUTER_CARD_FACTS`) с golden-rule значениями для трёх карточек Натальи, считанными визуально с Marina pp. 18/20/21:
    - Уран-Венера: transit_h=4, target_h=12, transit_ruled=[5,6], target_ruled=[2,9], walks=9.
    - Нептун-Юпитер: transit_h=4, target_h=4, transit_ruled=[4,7], target_ruled=[4,7], walks=8.
    - Нептун-Нептун: transit_h=4, target_h=4, transit_ruled=[4,7], target_ruled=[4,7], walks=8.
  - **Closed-dictionary psychology/event тексты** в Marina-style paraphrase (2-4 предложения per уровень, второе-личная форма, НЕ verbatim).
  - JD→Europe/Moscow datetime formatter в Marina format `DD.MM.YYYY HH:MM (GMT+3)`.
  - Russian declension tables (instrumental для target «с нат Венерой», locative для aspect «в квадрате»).
  - **Latin `c`** в card title между aspect locative и «нат» (U+0063, не Cyrillic U+0441) — соответствует Marina эталону и acceptance test pattern verbatim.
- **`services/api-python/app/pdf/builder.py`** — добавлен import + регистрация `outer_cards_for_case` в Jinja globals (2 строки добавления).
- **`services/api-python/app/pdf/templates/solar.html.j2`** — добавлен blocks §4a (outer cards loop) между § «Аспекты транзитных» и § «Золотое правило транзита». Loop iterates `outer_cards_for_case(case_id, facts.annual_transit_table, person.birth_timezone)`. case_id извлекается из `provenance_meta.extra.case_label` (если provenance отсутствует, блок silently skipped). Каждая карточка: `<h4 class="planet-name">` title, `<ul>` интервалов, `<p><strong>Золотое правило транзита</strong></p>` + `<table>` с 4 строками × 5 колонками, два `<p>` с Психологический/Событийный уровень.
- **`services/api-python/tests/test_natalya_transits_acceptance.py`** — **unmark** 7 xfail decorators (6 Cat 3 outer structure + 1 Cat 7 regression ban). **Обновлён `reason`** на 2 Neptune Cat 4 interval tests на `"TASK 4a — Neptune slow-loop contact window semantics"`, декораторы остались `@pytest.mark.xfail(strict=True)`.
- **`cabal build`** — Up to date, без ошибок.
- **pytest** — `cd services/api-python && .venv/bin/pytest --tb=no -q` → `113 passed, 10 xfailed in 59.24s`.
- **Self-verify PDF** через `scripts/render_natalya.py` → `/tmp/natalya-phase4.pdf`:
  - 18 pages, 28667 chars.
  - «тр Уран в квадрате c нат Венерой» count=1.
  - «тр Нептун в квадрате c нат Юпитером» count=1.
  - «тр Нептун в квадрате c нат Нептуном» count=1.
  - «Транзиты высших планет» count=2 (заголовок секции + 1 occurrence в Marina-formatted intro).
  - «Золотое правило транзита» count=4 (1 общий § golden rule + 3 карточки).
  - «Психологический уровень» count=4.
  - «Событийный уровень» count=3.
  - Uranus quincunx Jupiter as card: False — НЕ создан.
- **git push backup main** — `70185b0..8c9588d  main -> main`, parity verified.

## Remaining

- TL inline visual verification PDF vs Marina pp. 18/20/21 (Tier C — reviewer subagent необязателен).
- После closing TASK 4 — открыть **TASK 4a** (Neptune slow-loop contact window semantics) для Cat 4 xfails:
  - Neptune-Jupiter window 3 boundary Δ~17d (engine end 30.01.2028 vs Marina 16.02.2028).
  - Neptune-Neptune window 1 boundary Δ~178d (engine start 02.04.2024 vs Marina 27.09.2024).
  Решение между Path 1 (test contract semantic) и Path 2 (engine adjustment) — TL'у.
- Phase 5/6/7 — продолжают по программе (rulership-expanded houses, per-context cutoff, multi-case calibration).

## Artifacts

- branch:               main
- commit(s):            8c9588d (Phase 4 Path 3 — outer-planet cards generator)
- PR:                   нет (direct main, per Tier C)
- tests:                **113 passed + 10 xfailed** (было 106/17, +7 passed / −7 xfailed).
- Product repo status:  **committed** — на `main` @ `8c9588d`, push'нут в backup `/Users/ilya/Backups/astro.git`.

## Conflicts / risks

### Aggregation verification — 3/3/3 windows per allowlist triple

Все 3 allowlist triples Натальи сходятся к ровно 3 display windows после aggregation. Tolerance-based fallback (если windows ≠ 3) НЕ потребовался.

Dates per card (engine output, Europe/Moscow):

**Уран ⬜ Венера** (Marina match ±1 day):
- 03.06.2025 06:18 - 12.07.2025 19:04 — первое касание (D).
- 02.11.2025 08:22 - 22.12.2025 20:33 — второе касание (R).
- 18.03.2026 15:55 - 30.04.2026 08:44 — третье касание (DR).

**Нептун ⬜ Юпитер** (Marina match windows 1-2 OK, window 3 Δ~17d на end):
- 21.04.2026 03:42 - 28.09.2026 16:22 — первое касание (D+R).
- 21.02.2027 10:16 - 16.04.2027 19:20 — второе касание (DR).
- 09.10.2027 22:43 - 30.01.2028 05:13 — третье касание (R+DR).

**Нептун ⬜ Нептун** (Marina match windows 2-3 OK, window 1 Δ~178d на start — TASK 4a domain):
- 02.04.2024 05:37 - 12.10.2024 05:51 — первое касание (D+R).
- 31.01.2025 09:40 - 29.03.2025 05:25 — второе касание (DR).
- 24.10.2025 19:44 - 24.01.2026 18:03 — третье касание (DR).

### xfail flip status

| Test | Was | Now |
|---|---|---|
| `test_pdf_contains_uranus_square_venus_card` | xfail Phase 4 | **passed** (unmark) |
| `test_pdf_contains_neptune_square_jupiter_card` | xfail Phase 4 | **passed** (unmark) |
| `test_pdf_contains_neptune_square_neptune_card` | xfail Phase 4 | **passed** (unmark) |
| `test_each_outer_card_has_golden_rule_table` | xfail Phase 4 | **passed** (unmark) |
| `test_each_outer_card_has_psychology_level` | xfail Phase 4 | **passed** (unmark) |
| `test_each_outer_card_has_event_level` | xfail Phase 4 | **passed** (unmark) |
| `test_outer_cards_always_present_when_marina_shows_them` | xfail Phase 4 (Cat 7 ban) | **passed** (unmark) |
| `test_neptune_square_jupiter_three_touches_tolerance_2d` | xfail Phase 4 | **xfail** (reason → TASK 4a) |
| `test_neptune_square_neptune_three_touches_tolerance_2d` | xfail Phase 4 | **xfail** (reason → TASK 4a) |

Phase 5/6 xfails — не трогал (Phase 5 target-house xfails ожидают xfail из-за того что мы используем closed card-facts per case, а Phase 5 generic API surface).

### Path 3 confirmation

TL'овое Path 3 решение (предыдущая preflight blocked сессия + ack) реализовано полностью:
- НЕ модифицировал `_assert_three_phase_intervals` (test helper) — он остаётся в old shape.
- НЕ хардкодил Marina dates — все интервалы из engine output через aggregation.
- НЕ перезаписывал `expected.json`.
- НЕ unmark Cat 4 Neptune xfails — только обновлён `reason` text.
- НЕ модифицировал `transit_themes.py`, `synthesis_themes.py`, `provenance.py`, `render_natalya.py`.
- НЕ создал карточку для Уран 150° Юпитер.
- НЕ verbatim текст из Marina — все psychology/event paraphrase.

### Latin `c` vs Cyrillic `с` в card title

Marina эталон визуально использует Latin `c` (U+0063) между «в квадрате» и «нат» (вероятно artifact от Russian/Latin keyboard mixing). Acceptance test pattern в `test_natalya_transits_acceptance.py` также ожидает Latin `c?`. Mой первый draft использовал Cyrillic `с` (U+0441) — пять Cat 3 тестов упали. После переключения на Latin `c` тесты прошли. Documentation добавлена в `_card_title` docstring.

### Visual verification (PDF vs Marina)

Структурно карточки совпадают:
- Заголовок «тр <Planet> в <Aspect> c нат <Target>». ✓
- Интервалы реализации списком из 3 (DD.MM.YYYY HH:MM (GMT+3) - DD.MM.YYYY HH:MM (GMT+3) — N-е касание). ✓
- Таблица «Золотое правило транзита» 4 строки × 5 колонок (label-left, label-right, transit, aspect, radix). ✓ (Marina формат 4 cols × 5 rows — я ввёл doubled left col для clarity, контент тот же.)
- Психологический уровень paragraph. ✓
- Событийный уровень paragraph. ✓
- Уран 150° Юпитер в календаре, не в cards. ✓

Date parity Marina vs engine — расходится на Neptune-Jupiter window 3 (~17d) и Neptune-Neptune window 1 (~178d) — это **TASK 4a domain**, не Phase 4 задача.

### Что не нарушено

- `expected.json` НЕ переписан.
- `transit_themes.py`, `synthesis_themes.py`, `provenance.py`, `render_natalya.py` НЕ затронуты.
- Haskell core, schema, fixtures НЕ затронуты.
- Phase 5/6 xfail декораторы — без изменений.
- Working tree clean после commit.

## Next step

1. **TL inline visual verification** PDF `/tmp/natalya-phase4.pdf` (с commit 8c9588d) vs Marina pp. 18/20/21. Tier C — Reviewer subagent необязателен.
2. После accept'a TL'ом — закрыть TASK 4 через `make accept-handoff FILE=project-overlays/astro/HANDOFFS/2026-05-13-worker-to-tl-outer-planet-cards-generator.md`, переместить в archive.
3. Открыть **TASK 4a** «Neptune slow-loop contact window semantics» — decision Path 1 vs Path 2 за TL:
   - Path 1 (Phase 2 reopen, low cost): изменить `_assert_three_phase_intervals` на window-count semantics + tolerance extension для Neptune.
   - Path 2 (Tier A engine): изменить `Domain.TransitCalendar` orb-window opening rule для slow-mover first-touch (e.g. starts at exact-Direct, не at orb threshold).
4. Phase 5 (rulership-expanded target houses) и Phase 6 (per-context cutoff) продолжают по программе.
