# HANDOFF: worker → tl — transit-presentation-rebuild-marina-format

- Status: closed
- Date: 2026-05-12 14:42
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-12-transit-presentation-rebuild-marina-format.md

## Summary

Раздел «Транзиты» PDF переписан в Marina-формат: убраны iter-1 raw таблицы и блок «Какие транзиты особенно важны»; monthly table cells = простой int; календарь аспектов = bullet-list коротких строк по месяцам в формате `{planet} {deg}° {target} ({tone}) — DD.MM.YYYY–DD.MM.YYYY → Дома цели: N — name`. Math engine не тронут (2e4c394 TUNE-2 сохранён). Все 6 секций Acceptance — структурно совпадают с Marina pp. 7-22.

## Done

- **`services/api-python/app/pdf/transit_themes.py`** (rewrite, net -240 lines):
  - `transit_matrix_by_month` cells теперь `int|None` вместо arrow-joined strings (доминирующий дом по overlap-days за месяц, det'ое tie-break).
  - `transit_aspects_by_month` принимает `natal_positions` + `tz_id`, отдаёт Marina-shape entries: `aspect_deg` (int), `tone_label` (благоприятный/напряжённый/сильный), `target_house` + `target_house_label`, `period_start_str`/`period_end_str` (DD.MM.YYYY).
  - Фильтр engine super-set: окна < 7 дней дропаются, окна полностью вне solar-year дропаются, dedup hits-with-same-window-from-different-parent-entries.
  - Добавлены `_ASPECT_TONE_RU`, `_HOUSE_LABEL_RU`, `GOLDEN_RULE_PARAGRAPHS`.
  - Удалены `transit_aspects_table`, `transit_aspects_outer`, `transit_aspects_social`, `_aggregate_touches_by_combo`, `_OUTER_PLANETS`, `_SOCIAL_PLANETS`, `_ORB_BY_CLASS` (iter-1 helpers, supersede'нуты единым monthly calendar).

- **`services/api-python/app/pdf/builder.py`** (minimal patch, ~10 lines):
  - Снята регистрация `transit_aspects_outer`/`transit_aspects_social` из Jinja globals.
  - Добавлена регистрация `golden_rule_paragraphs`.

- **`services/api-python/app/pdf/templates/solar.html.j2`** (structural rewrite of Транзиты section, ~150 lines diff):
  - Удалён h3 «Какие транзиты особенно важны для этой натальной карты» + `<ul>` block.
  - Удалены h4 «Транзиты высших планет» / h4 «Транзиты социальных планет» + большие per-row таблицы (Период/Касания/Петля).
  - Добавлен h3 «Золотое правило транзита» (2 paragraph).
  - Добавлен h3 «Календарь транзитных аспектов» — bullet list по месяцам в Marina-shape.
  - Wiring `transit_aspects_by_month(att, sr_jd, natal_positions, tz_id)` с person.birth_timezone.

- **`services/api-python/tests/test_transit_aspects_tables.py`** (rewrite):
  - Удалены 9 тестов на iter-1 helpers (`test_outer_table_only_outer_planets`, `test_social_table_only_social_planets` и др.).
  - Добавлены 13 Marina-format тестов: matrix cells = int|None, calendar Marina-shape (aspect_deg, tone_label, period strings, target_house), tone labels, short-window filter, Quincunx preservation, natal_positions=None fallback, chronological sort.

## Remaining

- Visual parity не 100%-byte-match с Marina, но структурно полное совпадение — engine эмитит шире чем Marina печатает (Marina редакторская выборка, у нас filtered engine super-set с >=7d filter). Если TL захочет дальнейшее сужение календаря — это presentation knob `_MIN_WINDOW_DAYS` в `transit_themes.py:_MIN_WINDOW_DAYS`, не engine.
- 4 month-cell boundary mismatches с Marina monthly table (Венера окт/фев/июл/авг, Марс мар/май) — методологический выбор: мы берём «дом по большему overlap-days», Marina видимо берёт «дом на начало месяца». Разница в пределах одного дома; если критично — переключить fallback с overlap-time на month-start-snapshot.

## Artifacts

- branch:               `claude/dreamy-moore-46f5eb` (worktree `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`)
- commit(s):            `9f47f45` (push backup OK, baseline `2e4c394`)
- PR:                   нет (Tier C, backup-mirror flow)
- tests:                85/85 green (было 82 → -9 iter-1 +12 Marina = +3 net)
- New PDF:              `/tmp/astro-natalya-presentation-rebuild-iter1.pdf` (141 KB, 20 страниц)
- Marina reference:     `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 7-22
- Product repo status:  **committed**

### Visual parity check vs Marina (6-секционная структура)

| Секция | Verdict |
|---|---|
| 1. Короткий вводный блок | OK — без «Какие транзиты особенно важны» |
| 2. Monthly table «Транзиты планет по домам» | OK structural — cells = int, 48/52 cell-matches с Marina (92%); 4 boundary cells выбраны иначе (см. Remaining) |
| 3. Трактовки по домам — flat list | OK — Saturn 6/7/8, Jupiter 9-12+1, Mars 5-12+1-4, Venus 5-12+1-4, Uranus 9/10, Neptune 7/8, Pluto 5 |
| 4. Aspect taxonomy (5 видов) | OK — Соединение/Трин/Секстиль/Оппозиция/Квадрат |
| 5. Золотое правило транзита | OK — добавлен (2 paragraph) |
| 6. Календарь аспектов по месяцам | OK — Marina-format bullet rows, Quincunx 150° присутствует и помечен «напряжённый» |

## Conflicts / risks

- **Scope discipline.** `git show --stat 9f47f45` → 4 файла: `services/api-python/app/pdf/{builder.py, templates/solar.html.j2, transit_themes.py}` + `services/api-python/tests/test_transit_aspects_tables.py`. Никаких изменений в `core/`, `packages/contracts/`, `packages/rulesets/`, `packages/test-fixtures/`. Haskell engine — 0 lines. Bright lines #1-7 — preserved.
- **«Дома цели» — упрощение.** Marina pp. 20-22 показывает «расширенный» набор домов (target's natal house + houses target rules by sign rulership). У нас в строке — только натальный дом, в котором стоит target planet. Это narrowed-down vs Marina, но (а) выводимо однозначно из engine, (б) клиенту понятно, (в) Marina'ин «расширенный» набор требует справочной таблицы rulerships которой нет в engine output. Если TL хочет полный Marina-набор — это отдельный TASK с явным contract на «target houses by rulership».
- **Iter-1 helpers удалены, не deprecated.** `transit_aspects_table` / `transit_aspects_outer` / `transit_aspects_social` физически удалены из `transit_themes.py` и `builder.py`. Связанный параллельный open TASK `2026-05-11-transits-aspects-tables-outer-social` теперь semantically supersede'нут — TL handles его lifecycle отдельно (formal-reject в archive).
- **Render harness.** Использовал temp script `/tmp/render_natalya_marina_rebuild.py` для smoke-render — это не закоммичено, удалено по завершении. TL может пересобрать PDF через тот же harness или через `services/api-python/app/main.py` POST `/pdf` endpoint.

## Next step

TL inline-проверяет `/tmp/astro-natalya-presentation-rebuild-iter1.pdf` против Marina reference (особенно pp. 7-22) и принимает Tier C (Reviewer optional per Tier C матрице).

---

## TUNE-2 follow-up — 2026-05-12 (после `dec0f5d` quincunx-tune)

Узкий cell-choice swap в `transit_matrix_by_month` ради Marina-parity на monthly таблице. Math engine не тронут.

### Что сделано

- **Заменена логика выбора ячейки** в `transit_matrix_by_month` с "доминирующий дом по overlap-time" на "дом на 15-е число календарного месяца" (UTC). Fallback на dominant-overlap сохраняется для редкого случая, когда mid-month JD не покрыт ни одним entry.
- Обновлены docstring функции и стейл-комментарий в `tests/test_transit_aspects_tables.py` module docstring.
- TL'ова hypothesis ("дом на начало месяца") empirically falsified: дала 10/52 mismatches (хуже baseline 6/52). Probed 4 strategies против Marina:
  - month-start = 10/52
  - month-end = 18/52
  - calendar 1-st = 14/52
  - **calendar mid-month (15th) = 2/52** ← выбрано
  - dominant-overlap (baseline HEAD `dec0f5d`) = 6/52

### Final cell match

**50/52 (96.2%)** vs Marina эталонной таблицы (Соляр 2025-2026_5.pdf стр. 8).

Остаются 2 пограничные ячейки (быстрые планеты прямо вокруг 15-го числа):
- Авг 2025 Юпитер: наш=10, Marina=11
- Авг 2026 Венера: наш=2, Marina=1

Эти 2 ячейки — Marina'ин manual judgement, недостижимый детерминистическим sample-rule (любая JD-точка mid-month даст наш ответ).

### Artifacts (TUNE-2)

- commit: `6894743` (на `claude/dreamy-moore-46f5eb`, push backup OK; baseline TUNE-2 was `dec0f5d`)
- new PDF: `/tmp/astro-natalya-monthstart-iter1.pdf` (133 KB)
- tests: 85/85 green
- product repo status: **committed**
- changed files (1 + 1 docstring):
  - `services/api-python/app/pdf/transit_themes.py` — функция `transit_matrix_by_month` (sample point swap + docstring update + добавлен helper `house_at`)
  - `services/api-python/tests/test_transit_aspects_tables.py` — обновлён module docstring (invariant description); тесты неизменны.

### Notes for TL

- Patch остаётся в рамках presentation layer; math engine не пересчитывался; fixtures не регенерировались.
- 2/52 остаточных mismatches классифицируются как «Marina manual editorial choice»; дальнейшее sharpen'ing без access to her editorial rationale бесполезно.
- Если TL предпочтёт rollback to baseline (6/52) ради simpler rule «overlap dominance» — `git revert 6894743` чистый.
