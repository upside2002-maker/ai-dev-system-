# HANDOFF: worker → tl — inventory-parser-fork-task-b-title-matches

- Status: closed
- Date: 2026-05-27 18:38
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-b-title-matches.md

## Summary

P0-1 closed одним коммитом на ветке `feat/inventory-parser-fork-task-b-title-matches`
от master `8f1d5c4`: `title_matches` упрощён до чистого token-presence
check (substring-check и GTX special-case удалены — оба избыточны),
example-тесты расширены 13→22 кейса, property-тесты добавлены отдельным
файлом (2 функции через hypothesis, 200 examples каждая). `make
services-test` 276/276 + 1 skip, smoke на 3-словном запросе зелёный.

## Done

**Commit `7d627b2`** — `fix(parser): drop contiguous-phrase substring check in title_matches (TASK B / P0-1)`. 4 файла, +437 / −48.

**Изменения:**

1. **`sitka-services/app/inventory/adapters/base.py`** — `title_matches`
   упрощён до 2 содержательных строк (плюс блок комментариев с
   обоснованием для следующего читателя):
   ```python
   def title_matches(self, title, parsed_query) -> bool:
       matched_tokens = self.matched_tokens(title, parsed_query)
       return len(matched_tokens) == len(parsed_query.search_tokens)
   ```
   Substring-check (старые строки 458–461) и GTX special-case (старые
   строки 462–469) удалены. Связанный unused-import `normalize_text`
   тоже снят.

2. **`sitka-services/tests/test_inventory_title_matches.py`** —
   расширен с 13 до 22 кейсов:
   - **Broad mode (preserved unchanged):** 9 кейсов из TASK A (5
     positives + 3 negatives + 1 single-token).
   - **Target mode (flipped + extended):** 8 новых/обновлённых
     кейсов. `test_target_mode_no_substring_required_after_task_b`
     заменяет старый `test_target_mode_substring_required_today` —
     утверждение перевёрнуто с `False` на `True` для того же
     `"Sitka Men's Blizzard Bib AeroLite Parka"` против `"blizzard
     aerolite parka"`. `test_target_mode_three_tokens_with_gaps_match`
     parametrize 3-х titles (включая прямой smoke-кейс «Bib» между
     AeroLite и Parka, реверс порядка, prefix/suffix junk).
     `test_target_mode_all_tokens_must_be_present` расширен с 1 до 3
     negative подкейсов. `test_target_mode_size_forces_target` —
     второе утверждение в нём (с «Bib» между «Blizzard» и «Parka»)
     перевёрнуто с `False` на `True` после fix. Добавлен
     `test_target_mode_color_forces_target_and_matches_with_gap` (на
     color-hint forcing + token-gap).
   - **GTX equivalence (new block):** 5 кейсов:
     `test_gtx_matches_via_token_equivalence` parametrize 4 titles
     (`Gore-Tex`, `Gore Tex`, `GoreTex`, `GTX`) +
     `test_gtx_three_token_query_matches_gore_tex_with_gap` (combined:
     3-token target query "blizzard gtx glove" против title
     "Sitka Men's Blizzard Bib Gore-Tex Glove" — failed before
     TASK B по двум причинам сразу, passes now).

3. **`sitka-services/tests/test_inventory_title_matches_property.py`**
   (новый файл, 2 property функции через `hypothesis` 6.153.6):
   - **`test_title_matches_implies_all_tokens_in_normalised_title`
     (soundness):** для случайных `(tokens, arbitrary_title)`
     пар — если `title_matches==True`, тогда каждый токен из
     `parsed.search_tokens` должен быть substring в
     `normalize_text(title)`. ~45% draws попадают в `True`-ветку
     (проверено вручную через 200 deterministic draws), property
     нетривиально упражняется. 200 examples.
   - **`test_all_tokens_in_normalised_title_implies_title_matches`
     (completeness):** для случайных tokens, конструируем title из
     этих токенов + filler-слов между/до/после/в random
     UPPER/Title-case → `title_matches` MUST be `True`. Это и есть
     fix F-PARSE-1: до TASK B failed бы для target mode когда tokens
     не contiguous. 200 examples.
   - **Token strategy:** lowercase ASCII, длина 5–10. Фильтр против
     `_STOPWORDS` (sitka, mens, ...), `PRODUCT_TOKEN_ALIASES`
     (jackets→jacket трансформируется), `PRODUCT_TOKEN_VARIANTS`
     (всё семейство jacket/pant/...), `MODEL_FAMILY_HINTS`
     (blizzard, stratus, ...), `_TOKEN_EQUIVALENTS` (gtx, gore, tex,
     goretex) и `COLOR_PARSE_TERMS` (через `extract_color_from_text`).
     Это нужно, чтобы `parse_query(" ".join(tokens)).search_tokens
     == tuple(tokens)` (round-trip stability). При несовпадении —
     `hypothesis.assume(...)` пропускает draw.
   - **`HealthCheck.filter_too_much` + `HealthCheck.too_slow` suppressed:**
     `_is_clean_token` отбрасывает достаточно много генерируемых
     строк, hypothesis иначе ругается на filter ratio. Это
     ожидаемо при text() со специфичным constraint.

4. **`sitka-services/requirements.txt`** — добавлен `hypothesis>=6,<7`
   с комментарием. Этого достаточно для CI: workflow
   `.github/workflows/ci.yml` (job "Python: test") выполняет
   `pip install -r requirements.txt` (строка 239), hypothesis
   подхватится автоматически. CI-workflow НЕ трогал.

**Тесты:**

- `cd sitka-services && .venv/bin/python -m pytest
  tests/test_inventory_title_matches.py
  tests/test_inventory_title_matches_property.py -v`:
  **24 passed** (22 example + 2 property) в 19.21s.
- `make -C .. services-test`: **276 passed, 1 skipped** в 20.90s.
  Baseline after TASK A был 265 passed + 1 skip → прирост +11 тестов
  (= 22 − 13 в example file + 2 новые property). Skip — известный
  pre-existing flake `test_core_client.py` (см. note в prompt'е).
- Pre-commit hooks: все Passed (gitleaks / detect-private-key / EOF
  fixer / trailing-ws / etc.) — никаких автофиксов, чистый коммит.

**Smoke** (concrete subclass, см. Conflicts/risks п.1 про литеральный
smoke из TASK):

```python
ad = _ConcreteAdapter()
q = parse_query("blizzard aerolite parka")
assert ad.title_matches("Sitka Men's Blizzard AeroLite Bib Parka", q) is True
```
→ **`SMOKE: True`** (до fix — `False`).

GTX дополнительный smoke:
```python
q = parse_query("sitka blizzard gtx")
assert ad.title_matches("Sitka Blizzard Gore-Tex Glove", q) is True
```
→ **`GTX SMOKE: True`**.

## Remaining

В рамках TASK B — ничего. Открытые/спорные точки — в Conflicts/risks.

## Artifacts

- branch:               `feat/inventory-parser-fork-task-b-title-matches` (не запушена; ждёт review + push от TL)
- commit(s):            `7d627b2`
- PR:                   нет (push делает TL после Reviewer ACCEPT)
- tests:                новые/обновлённые: `test_inventory_title_matches.py` 22 passed (было 13), `test_inventory_title_matches_property.py` 2 passed (новый); `make services-test` 276 passed + 1 skipped (baseline 265+1 skip → +11 tests)
- Product repo status:  committed

## Conflicts / risks

1. **Литеральный smoke из TASK acceptance падает в Python 3.12 на
   ABC enforcement** — pre-existing issue в формулировке TASK, не в
   моих изменениях.

   TASK acceptance bullet:
   > `.venv/bin/python -c "from app.inventory.adapters.base import
   > BaseStoreAdapter; ...; q = parse_query('blizzard aerolite
   > parka'); print('matches:', BaseStoreAdapter.title_matches(
   > BaseStoreAdapter.__new__(BaseStoreAdapter), '...', q))"` →
   > `matches: True`

   В Python 3.12 `BaseStoreAdapter.__new__(BaseStoreAdapter)` сам
   по себе бросает `TypeError: Can't instantiate abstract class
   BaseStoreAdapter without an implementation for abstract methods
   'check_product', 'search'`. Это поведение PEP-3119 / `abc.ABC`,
   усилено в 3.12 (раньше `__new__` пропускал, метакласс ловил при
   `__init__`). Sitka services работают на Python 3.12 (`.venv` +
   CI `actions/setup-python@v6 python-version: 3.12`).

   **Что я сделал:** запустил smoke через минимальный concrete
   subclass — это ровно то же что делает
   `_TestAdapter`/`_C` в обоих test-файлах. Логика
   `title_matches` отрабатывает идентично (метод определён на
   `BaseStoreAdapter`, наследник не переопределяет), результат
   `SMOKE: True`. Записал это и в commit message, и в Done выше.

   **Что нужно от TL:** либо при accept-task поправить bullet в
   TASK на concrete-subclass формулировку (1 строка edit), либо
   принять то что smoke factually passes но не в той форме, что
   написана буквально. Я выбрал второе — поменять TASK я как
   Worker не могу.

2. **GTX special-case — удалил, не оставил «just in case».**

   TASK "Do not touch" п.5: «Special-case GTX substitution (line
   462-469) — можно **оставить** как есть ... **или удалить** ...
   На усмотрение Worker'а — если удаляешь, добавь explicit test
   что «sitka blizzard gtx» матчит «Sitka Blizzard Gore-Tex
   Glove». Если оставляешь — отметь в HANDOFF почему "just in
   case".»

   **Выбор: удалил.** Обоснование:
   - GTX special-case был substitution внутри substring-check.
     После удаления substring-check сам special-case становится
     dead code (выполняется только когда matched_tokens-check
     прошёл, broad-fastpath не сработал, substring-check прошёл
     — но мы только что удалили substring-check вместе с этим
     блоком).
   - Token-level equivalence уже работает: `_TOKEN_EQUIVALENTS`
     в `_sitka_catalog.py` (строка 332) маппит `"gtx" →
     ("gtx", "goretex", "gore-tex", "gore", "tex")`. Проверено
     вручную и тестами: запрос `"sitka blizzard gtx"` против
     title `"Sitka Blizzard Gore-Tex Glove"` уже возвращает
     `True` без special-case'а — `match_query_tokens` принимает
     "gore-tex" как вариант "gtx" на уровне token-matching.
   - Тесты подтверждают: `test_gtx_matches_via_token_equivalence`
     (4 title variants: Gore-Tex / Gore Tex / GoreTex / GTX) +
     `test_gtx_three_token_query_matches_gore_tex_with_gap`
     (3-token query с gap).
   - Code-hygiene: «just in case» / «на всякий случай» — точно
     тот тип формулировки, который CLAUDE.md «Tech-lead posture»
     метит красным флагом. Если код избыточен, его убирают;
     если боимся убирать — фиксируем причину. Конкретной причины
     не нашёл (специально проверил equivalence map), поэтому
     удалил.

3. **Минимальный (но всё же) drive-by фикс:** убрал импорт
   `normalize_text` из `base.py` (после удаления substring-check
   он стал unused). 1 строка. Не сообщал заранее как drive-by по
   Communication discipline #2, потому что это прямое следствие
   изменения функции — иначе любой линтер (ruff/pyflakes) поймал
   бы. Если хотите делать в отдельном коммите — могу выделить;
   мне кажется overkill для 1 unused-import.

4. **Hypothesis: 200 examples max явно зафиксированы в `@settings`.**

   TASK acceptance говорит «Минимум 200 examples каждая (default)».
   Hypothesis default — 100 examples, не 200. Чтобы не зависеть от
   глобальных hypothesis profile настроек, поставил
   `max_examples=200` явно в `@settings(...)` обоих property-функций.
   Это buys нам:
   - Соответствие TASK буквой и духом (200 examples гарантированно).
   - Тест время: ~17–19 секунд для обеих, приемлемо для CI.
   Если в CI время становится bottleneck — можно ввести hypothesis
   profile (ci=50 examples / dev=200) через `conftest.py`. Сегодня
   не нужно.

5. **`_STOPWORDS` — module-private импорт.**

   Property-тест импортирует `_STOPWORDS` из `app.inventory.query`
   (underscore-prefix = module-private). Альтернатива — захардкодить
   копию в тест-файле, но тогда добавление stopword в `query.py`
   беззвучно сделало бы property несоответствующим реальности.
   Импорт private symbol в test-only consumer — приемлемая практика
   (тест уже coupled к internal'ам того модуля, который тестирует).
   Если есть concern — могу перевернуть на skip-list поверх
   `parse_query` result'а (медленнее, но без private import). Считаю
   текущий вариант чище.

6. **CI yet to run.** Эта ветка не запушена (per WORKER.md). После
   ACCEPT TL пушит → запускается полный CI (haskell, python,
   frontend lanes). Hypothesis в `requirements.txt` подхватится
   pip'ом в Python-test job без дополнительных правок workflow. Если
   pip cache key не инвалидируется (он берётся от хэша
   `requirements.txt` — строка 233 workflow), то всё ок (мы как раз
   изменили requirements.txt → кэш-ключ другой → fresh install).
   Если по какой-то причине hypothesis не подтянется на CI — TASK
   acceptance fallback'ом предлагает «добавить `pip install
   "hypothesis>=6,<7"` в Python-test step»; такой PR будет занимать
   3 строки. Но я ожидаю, что requirements.txt пути достаточно.

## Next step

TL делает code-review (diff небольшой — `base.py` 20 строк, 2
test-файла, requirements.txt). Если ACCEPT — запускает Reviewer
subagent (Tier B + замена контракта пользовательской функции
оправдывают второй pair of eyes). После Reviewer ACCEPT — push
ветки, PR, auto-deploy + smoke на проде, merge. Затем TASK C
(Amazon timeout) по плану.
