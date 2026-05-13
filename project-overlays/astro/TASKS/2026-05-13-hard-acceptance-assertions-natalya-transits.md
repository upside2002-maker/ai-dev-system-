# TASK: hard-acceptance-assertions-natalya-transits

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

Phase 2 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 2, § 6 Hard acceptance assertions, § 8 TASK 2). Цель — устранить root cause #5 из § 3 документа («Текущие тесты не являются acceptance contract против эталона Марины»).

Сейчас тесты проверяют форму данных и соответствие текущему `expected.json`. Если `expected.json` перезаписан регрессивными facts (что и произошло на worktree между Tier A и Tier C итерациями), тесты остаются зелёными на регрессии. Нужны **независимые, содержательные assertions** по PDF/structured presentation facts, привязанные к case `08-natalya-2025-2026` и эталону Марины.

Эти assertions фиксируют контракт **до** новых presentation refactors (Phase 3-6). Цель: после landing'а каждой следующей фазы программы тесты должны переходить из failed → passed. Если фаза не закрывает ожидаемый assertion — это блокер, не accept.

Семантика тестов: **expected-failure-until-fix.** Тесты должны падать на текущем состоянии (потому что Phase 3-6 ещё не сделаны). Использовать `@pytest.mark.xfail(strict=True, reason="Phase N — short rationale")` чтобы CI оставалось зелёным (xfail == pass), но при landing'е фиксов из Phase N тест перейдёт в xpass → strict xfail flip → CI красный → Worker следующей фазы обязан unmark xfail при closing.

## Files

- new:
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — основной файл с hard assertions. Все assertions из § 6 архитектурного документа, привязанные к case `08-natalya-2025-2026`. Использует:
    - canonical render path из Phase 1 (`services/api-python/scripts/render_natalya.py`) — генерирует PDF + sidecar в pytest tmp_path;
    - extract PDF text через `pdfplumber` или `pypdf` (Worker выбирает, justifies в HANDOFF);
    - structured-data assertions против `transit_themes.transit_aspects_by_month`, `transit_themes.transit_matrix_by_month` и аналогичных presentation helpers (где возможно, без PDF render — быстрее);
    - mix: где fact-level assertion possible (e.g. «Сатурн в houses_visited даёт `[7, 8]`») — структурный тест; где нужен PDF text — extracted-text assertion.
  - `services/api-python/tests/conftest.py` (если ещё нет — Worker check; иначе modify) — fixtures для:
    - `natalya_input_path` (resolves to canonical `08-natalya-2025-2026.input.json`);
    - `natalya_expected_path` (resolves to canonical `expected.json`);
    - `natalya_pdf_render` (session-scoped fixture, generates one PDF + sidecar per test session, caches).

- modify:
  - `services/api-python/pyproject.toml` (или `requirements.txt` / `setup.py`) — добавить `pdfplumber` или `pypdf` в test deps, если ещё нет. Minimal addition.

- delete: —

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — out of scope. Это test contract задача.
- **`packages/contracts/*.schema.json`**, **`packages/rulesets/`** — не трогать.
- **`packages/test-fixtures/golden-cases/*.expected.json` и `*.input.json`** — категорически не перезаписывать. Запрет § 7 архитектурного документа. Тесты читают как input, не модифицируют.
- **PDF templates / helpers**: `transit_themes.py`, `synthesis_themes.py`, `direction_themes.py`, `house_pair_themes.py`, `wheel.py`, `wheel_glyphs.py`, `solar.html.j2`, `builder.py`, `provenance.py` — НЕ менять. Любые «попутные» правки внутрь логики — blocker, переход в TASK 3+.
- **`apps/web-react/`** — out of scope.
- **`scripts/render_natalya.py`** (Phase 1 canonical) — используется тестами, не модифицируется в этой задаче.
- **Существующие тесты** (`test_contracts.py`, `test_transit_aspects_tables.py`, `test_draft.py`, etc.) — не правим. Новые assertions в новом файле.

## Acceptance

### Test file structure

- [ ] `services/api-python/tests/test_natalya_transits_acceptance.py` создан с явной module-docstring ссылкой на architecture document § 6 и эталон Марины.
- [ ] Все assertions из § 6 архитектурного документа разнесены по тестам с понятными именами (`test_<aspect>_<expected_behavior>`).
- [ ] Каждый xfail-тест имеет `@pytest.mark.xfail(strict=True, reason="Phase N — <short>")` и `id` ссылающийся на конкретную фазу программы, которая его починит.
- [ ] Tests xfail НЕ из-за технических ошибок (import error, fixture missing), а только из-за content assertion mismatch.

### Hard assertions categories (per § 6 architecture doc)

**1. Render provenance** (passes сразу, Phase 1 закрыт):

- [ ] `test_provenance_sidecar_has_all_required_keys` — генерит PDF через canonical render, проверяет sidecar содержит 13 required keys.
- [ ] `test_provenance_distinguishes_main_vs_worktree` — sidecar.repo_root_path содержит «worktree» если рендер из worktree.
- [ ] `test_provenance_records_render_mode` — sidecar.mode ∈ {`fixture-render`, `recomputed`}.

**2. Per-house transit interpretations** (xfail Phase 3 — horizon split):

- [ ] `test_saturn_solar_year_houses_only_seven_and_eight` — `houses_visited(solar_year_horizon, 'Saturn') == [7, 8]`.
- [ ] `test_pdf_text_does_not_contain_saturn_six_house` — extracted PDF text не содержит `Сатурн в 6 доме` после `Транзиты планет по домам`.
- [ ] `test_pdf_per_house_section_no_2024_dates` — no `2024` substring в трактовках per-house.
- [ ] `test_pdf_per_house_section_no_2027_2028_dates` — no `2027` or `2028` в трактовках per-house.
- [ ] `test_houses_visited_accepts_explicit_horizon` — `houses_visited` signature принимает явный `horizon=` parameter.

**3. Outer-planet structure** (xfail Phase 4 — cards generator):

- [ ] `test_pdf_contains_outer_transits_section_heading` — extracted PDF text содержит `Транзиты высших планет`.
- [ ] `test_pdf_contains_uranus_square_venus_card` — extracted text содержит `тр Уран в квадрате c нат Венерой` (или canonical variant).
- [ ] `test_pdf_contains_neptune_square_jupiter_card` — `тр Нептун в квадрате c нат Юпитером`.
- [ ] `test_pdf_contains_neptune_square_neptune_card` — `тр Нептун в квадрате c нат Нептуном`.
- [ ] `test_each_outer_card_has_golden_rule_table` — для трёх карточек проверка наличия таблицы `Золотое правило транзита`.
- [ ] `test_each_outer_card_has_psychology_level` — проверка `Психологический уровень` или эквивалентного заголовка.
- [ ] `test_each_outer_card_has_event_level` — проверка `Событийный уровень`.

**4. Outer-planet intervals** (xfail Phase 4, tolerance per § 6):

- [ ] `test_uranus_square_venus_three_touches_tolerance_2d` — `Уран ⬜ Венера` карточка содержит **строго 3 интервала**; даты совпадают с reference в пределах **±2 дня** на границы; порядок **строго D → R → DR**. Reference:
  - `03.06.2025 12:00 - 12.07.2025 12:00`
  - `02.11.2025 12:00 - 22.12.2025 12:00`
  - `19.03.2026 00:00 - 30.04.2026 00:00`
- [ ] `test_neptune_square_jupiter_three_touches_tolerance_2d` — `Нептун ⬜ Юпитер` карточка с 3 интервалами, ±2d, D→R→DR. Reference:
  - `21.04.2026 12:00 - 28.09.2026 12:00`
  - `21.02.2027 12:00 - 16.04.2027 12:00`
  - `10.10.2027 00:00 - 16.02.2028 12:00`
- [ ] `test_neptune_square_neptune_three_touches_tolerance_2d` — `Нептун ⬜ Нептун` карточка с 3 интервалами, ±2d, D→R→DR. Reference:
  - `27.09.2024 00:00 - 12.10.2024 00:00`
  - `31.01.2025 12:00 - 29.03.2025 00:00`
  - `25.10.2025 00:00 - 24.01.2026 12:00`

**5. Calendar dates and clipping** (xfail Phase 6 — per-context cutoff):

- [ ] `test_calendar_neptune_square_jupiter_clipped_to_solar_year_end` — calendar row для `Нептун 90° Юпитер` имеет `period_end` ≤ `solar_return_jd + 365.25` (или соответствующую date `07.08.2026` ±2d). Формула из § 6: `period_end = min(actual, sr_jd + 365.25)`.
- [ ] `test_calendar_uranus_conjunction_mc_clipped_to_solar_year_end` — `Уран 0° MC` клипнется до `07.08.2026` ±2d; нет хвоста в ноябрь 2026.
- [ ] `test_calendar_no_rows_outside_solar_year_span` — все calendar rows лежат внутри `[sr_jd, sr_jd + 365.25]` ±2d.
- [ ] `test_calendar_period_start_clipped_to_solar_year_start` — `period_start = max(actual, sr_jd)` (loops которые начались до соляра — обрезаны слева).

**6. Target houses** (xfail Phase 5 — rulership-expanded):

- [ ] `test_target_houses_not_placement_only_for_multi_house_targets` — для multi-house target (Юпитер, Нептун, Венера в Натальи) `target_house_set` содержит больше одного элемента, не placement-only.
- [ ] `test_uranus_square_venus_target_houses_match_marina_reference` — для `Уран 90° Венера` target_houses совпадают с Marina golden-rule table из эталона (reference set фиксируется Worker'ом TASK 5 на основе скриншота/visual reference; для TASK 2 — assertion expects не-singleton, конкретный set TBD).
- [ ] `test_target_houses_distinguish_placement_from_rulership` — API target_house_set явно разделяет `placement_house` и `rulership_houses` поля.

**7. Regression bans** (always-on, не xfail — должны быть зелёными после landing Phase 3-6):

- [ ] `test_no_saturn_six_house_regression` — strict: PDF text **никогда** не содержит `Сатурн в 6 доме` в solar-year interpretation block (когда Phase 3+ закрыты).
- [ ] `test_outer_cards_always_present_when_marina_shows_them` — Marina reference cards (Уран-Венера, Нептун-Юпитер, Нептун-Нептун) присутствуют в PDF после Phase 4.
- [ ] `test_target_houses_no_placement_only_regression` — multi-house targets никогда не сжимаются до single placement.
- [ ] `test_provenance_distinguishes_main_vs_worktree_always` — sidecar provenance всегда позволяет отличить main vs worktree.

### Self-consistency

- [ ] Tests группируются по category headers (matching § 6 sections).
- [ ] Каждый test содержит inline-комментарий со ссылкой на конкретную assertion в § 6 architecture document (e.g. `# Architecture doc § 6 "Per-house transit interpretations" item 2`).
- [ ] Failed tests при run без xfail (debug-режим, e.g. `pytest --runxfail`) должны давать **читаемое** сообщение об ошибке: показывают actual vs expected (no opaque `AssertionError`).

### Test execution

- [ ] `cd services/api-python && .venv/bin/pytest tests/test_natalya_transits_acceptance.py -v` — выводит N tests, M xfailed, K passed. **Всего ожидается** ~30+ tests; xfail count ≈ 25 (Phase 3-6 not yet implemented); passed count ≈ 5 (provenance tests, который Phase 1 закрыл).
- [ ] `pytest --runxfail tests/test_natalya_transits_acceptance.py` (debug режим, чтобы видеть actual failures) — даёт читаемые failure messages с actual vs expected.
- [ ] Full `pytest` suite остаётся 94+ green (новые xfail НЕ ломают CI; passed-passes increment).
- [ ] **Critical:** ни один тест не падает из-за технической ошибки (import error, fixture problem). Все падения — content assertion mismatch, отмеченный xfail.

### Process

- [ ] Worker subagent (Mode normal Tier C, отдельная Agent-сессия).
- [ ] HANDOFF содержит:
  - per-category test list с xfail-mapping (какой test → какая Phase его починит);
  - example failure output для каждой category (xfail trace);
  - `pdfplumber` vs `pypdf` choice justification;
  - confirmation что fixture files не перезаписаны;
  - path к canonical render output, который тесты используют как evidence.

### Tests + clean state

- [ ] `git status --short` чисто **для intended product changes** перед commit. Pre-existing untracked `.claude/worktrees/` разрешён.
- [ ] Один commit. Tests + minimal pyproject deps update.
- [ ] Push на backup, parity verified.

## Context

**Mode normal + Tier C** (test contract foundation). Worker subagent. Reviewer subagent **необязателен** per Tier C матрица — TL inline-verifies test list completeness + sample xfail messages после Worker.

**Baseline:** `9793d5d` (Phase 1 closed). Tests baseline 94/94 green.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 5 Phase 2 — formal definition.
- § 6 Hard acceptance assertions — содержание тестов (все assertions переводятся в pytest-тесты).
- § 7 запреты — особенно «Не считать зелёные snapshot/golden tests достаточным доказательством близости к Марине».
- § 8 TASK 2 — formal spec (зеркальная с настоящей).

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 2 spec (Ready-gate сейчас намеренно). Без явного go от пользователя Worker не стартует.

**После закрытия:** TL обновляет STATUS_RU, открывает TASK 3 (Phase 3 — Horizon split, Tier C с эскалацией до Tier A при schema/core contract changes).

**xfail strategy rationale:** мы фиксируем контракт «вот это должно работать после Phase 3-6» **сейчас**, до их implementation. Без xfail тесты ломали бы CI. С xfail-strict они работают как guard rails: пройдут — strict-fail заставит Phase N Worker'а unmark xfail и thus формально close acceptance.

**Worktree decision pending:** Phase 1 рекомендация — merge fast-forward. Пока решение не принято, тесты работают на ветке `claude/dreamy-moore-46f5eb`. После merge (если/когда) тесты автоматически перенесутся на main без правки кода — это features tests, не worktree-specific.
