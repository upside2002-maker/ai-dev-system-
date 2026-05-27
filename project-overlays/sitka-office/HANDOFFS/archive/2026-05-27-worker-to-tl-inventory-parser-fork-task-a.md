# HANDOFF: worker → tl — inventory-parser-fork-task-a

- Status: closed
- Date: 2026-05-27 17:34
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-a.md

## Summary

Форк выполнен в два коммита на ветке `feat/inventory-parser-fork-task-a` (от
master `ccac24b`): commit 1 — чистый `git mv` 47 живых файлов из
`vendor/inventory_parser/inventory/v2/` → `app/inventory/`; commit 2 —
переписаны импорты, создан минимальный `_sitka_catalog.py`, обрезан
`_governor.py` до Protocol, удалён весь `vendor/inventory_parser/` (166
мёртвых файлов), обновлены Dockerfile/CI/gitleaks-allowlist, добавлены 4
теста. `make services-test` зелёный, все 5 acceptance smoke-команд
проходят. Главный flag: `_sitka_catalog.py` действительно содержит только
10 публичных символов из TASK Files.new, но **другие живые адаптеры
(`eurooptic.py`, `franks.py`, `als.py`, `outdoor_insiders.py`,
`shopify_stores.py`, `families/shopify_support.py`,
`bigcommerce_support.py`, `catalog/sitka_canon.py`) продолжают
импортировать ещё 15 символов** из `shared.product.sitka_catalog` —
эти импорты резолвятся в avito vendor, который TASK A не трогает. См.
"Конфликты / открытые вопросы" п.1.

## Done

**Commits на ветке `feat/inventory-parser-fork-task-a`:**

1. **`c7114ea`** — `refactor(inventory): git mv vendor/inventory_parser → app/inventory/ (no import changes)`.
   47 файлов перемещены через `git mv`, git регистрирует все 47 как 100%
   renames. Снимки `snapshot/types.py` → `_governor.py` и
   `snapshot/proxy_pool.py` → `proxy_pool.py` подняты в корень.
   `basspro.py` оставлен на старом месте — удаляется во второй коммит
   через `git rm`.

2. **`4420fee`** — `refactor(inventory): rewrite imports + drop vendor + tests + CI cleanup`.
   - 116 импортов `from inventory.v2.*` → `from app.inventory.*` (включая
     перенаправления на `_governor` / `proxy_pool`).
   - `app/inventory/_sitka_catalog.py` создан — 10 публичных символов из
     `query.py` + минимально необходимая private machinery (helpers и
     catalog facts: `COLOR_ALIASES`, `SIZE_SYNONYMS` build-up,
     `PRODUCT_TOKEN_ALIASES`/`VARIANTS`, `MODEL_FAMILY_HINTS`/`ALIASES`,
     `QUERY_TYPO_ALIASES`). `query.py` теперь импортирует только из этого
     slice, не из `shared.product.sitka_catalog`.
   - `app/inventory/_governor.py` обрезан до одного `class Governor(Protocol)`.
   - `app/inventory/__init__.py` экспортирует ровно 5 публичных
     символов: `ParserService`, `parse_query`, `DEFAULT_STORE_NAMES`,
     `ItemResult`, `StoreRunResult` (убраны `InventoryV2Module*`,
     `ParsedQuery`, `run_store_query{,ies}` — внутренние или мёртвые).
   - `app/inventory/registry.py` — basspro уже отсутствовал в upstream'е
     (он не был в `build_registry()`), так что физически менять было
     нечего; импорта тоже не было.
   - `app/parsers/inventory_v2.py` — два импорта переключены на
     `from app.inventory.core import ParserService` и
     `from app.inventory.types import StoreRunResult`. Файл оставлен как
     backwards-compat alias.
   - `sitka-services/Dockerfile` — строка `RUN pip install --no-cache-dir
     -e ./vendor/inventory_parser` удалена, заменена комментарием.
   - `.github/workflows/ci.yml` — строка `pip install -e
     ./vendor/inventory_parser` из Python-test job удалена.
   - `.gitleaks.toml` — путь allowlist Rogers Klevu key переехал из
     `vendor/inventory_parser/.../rogers.py` в
     `app/inventory/.../rogers.py`. Старый второй entry
     `klevu_rogers.py` (был в мёртвом `catalog_sync/`) удалён.
   - `git rm -rf sitka-services/vendor/inventory_parser/` — 166 мёртвых
     файлов снесены.
   - **Тесты:**
     - `tests/test_inventory_v2_query.py` → `tests/test_inventory_query.py`
       через `git mv`, импорт переведён на `app.inventory.query`, все
       **7 кейсов** PR #89 (`ccac24b`, 2026-05-21) остались зелёными.
     - `tests/test_inventory_title_matches.py` — **13 кейсов**: broad
       positives/negatives + target substring (текущее F-PARSE-1
       поведение pinned, чтобы TASK B мог явно его поменять).
     - `tests/test_inventory_registry.py` — **6 кейсов**: build_registry()
       возвращает **20** адаптеров (см. п.2 ниже), basspro absent,
       DEFAULT_STORE_NAMES содержит rogers/1shot/als/lancaster.
     - `tests/test_inventory_smoke.py` — **5 кейсов**: rogers/1shot/badass/gritr
       smoke с fixture-HTML и monkeypatch BaseStoreAdapter.{fetch_text,
       fetch_json, post_json}. Без реальной сети.
     - Fixtures: `tests/fixtures/inventory/{rogers,1shot,badass,gritr}/empty.html`
       — минимальный HTML "0 results" для каждого магазина.

**Тесты (acceptance):**
- Новые 4 файла: **31 passed** (7 + 13 + 6 + 5).
- `make services-test`: **265 passed, 1 skipped** (на master было 235
  passed + 7 в `test_inventory_v2_query.py` = 242 collected; на ветке
  226 + 31 + 1 skip = 266 collected, 265 passed + 1 skipped). Прирост
  +24 тестов (новые 24 = 31 - 7 переименованных).
- Pre-commit hooks: все Passed (включая gitleaks с обновлённым
  allowlist путём).

**Acceptance smoke-команды из prompt'а, все ОК:**

- `python -c "from app.inventory.core import ParserService; print(ParserService)"`
  → `<class 'app.inventory.runtime.service.ParserService'>`.
- `python -c "import asyncio; from app.parsers.inventory_v2 import
  run_parser_search; r = asyncio.run(run_parser_search('blizzard',
  ['rogers'])); print(len(r[0].items))"` → `6` (живой network запрос на
  rogers, прошёл, 6 товаров).
- `grep -rE "^from inventory\.v2" sitka-services/ --include="*.py"` →
  пусто (exit 1).

## Remaining

Ничего, что нужно делать в рамках TASK A. Спорные точки в "Конфликты"
ниже — это знание для следующих TASK B/C/D и для Reviewer, не TODO
внутри A.

## Artifacts

- branch:               `feat/inventory-parser-fork-task-a` (не запушена; ждёт review + push от TL)
- commit(s):            `c7114ea` (move), `4420fee` (rewrite+cleanup+tests)
- PR:                   нет (push делает TL после Reviewer ACCEPT)
- tests:                4 новых файла = 31/31 passed; `make services-test` 265 passed + 1 skipped (+24 vs master)
- Product repo status:  committed
- LOC delta (git diff --stat master..HEAD): 230 files changed, +1267, -32749 (net **-31 482 LOC**)

## Conflicts / risks

1. **`_sitka_catalog.py` содержит только 10 символов, но другие живые
   адаптеры импортируют ещё 15 из `shared.product.sitka_catalog`.**

   TASK Files.new говорит: «`app/inventory/_sitka_catalog.py` — копия
   нужных функций из `vendor/avito_parser/.../__init__.py`. Использовать
   `inventory/v2/query.py` как референс — копировать **только** функции/константы
   которые там импортируются: <10 имён>.» Я выполнил буквально — файл
   содержит ровно эти 10 публичных символов (+ их private machinery,
   потому что без неё они не работают).

   Однако при инвентаризации `grep -rA 30 "^from shared\.product\.sitka_catalog import"`
   по живому коду нашёл **ещё 9 live import sites** в файлах, которые
   TASK A тоже трогает (через rename), но не упоминает в этом
   контексте:

   - `app/inventory/adapters/stores/eurooptic.py` →
     `infer_color_label_from_text, infer_size_label_from_text,
     is_color_axis_label, is_size_axis_label`
   - `app/inventory/adapters/stores/franks.py` →
     `contains_label_candidate, label_match_candidates,
     match_segment_label, normalize_text, repair_color_label,
     significant_product_tokens`
   - `app/inventory/adapters/stores/outdoor_insiders.py` → `normalize_text`
   - `app/inventory/adapters/stores/als.py` →
     `compact_size_length_label, is_color_axis_label,
     is_size_aux_axis_label, is_size_axis_label`
   - `app/inventory/adapters/stores/shopify_stores.py` → `canonical_color_key`
   - `app/inventory/adapters/families/shopify_support.py` →
     `is_color_axis_label, is_size_axis_label, move_tall_marker_from_color`
   - `app/inventory/adapters/families/bigcommerce_support.py` →
     `combine_size_label, is_color_axis_label, is_size_aux_axis_label,
     is_size_axis_label`
   - `app/inventory/catalog/sitka_canon.py` → `canonical_product_title`

   Уникально 15 дополнительных символов. Эти импорты сейчас работают
   потому что `vendor/avito_parser` ещё установлен editable (это TASK A
   намеренно не трогает) — `shared.*` namespace по-прежнему импортится.
   Это **не сломанный код** на сегодня. Но это **скрытая зависимость**,
   которую TL spike note (MAILBOX/to-admin.md, запись «Spike inventory
   fork») и audit §5 F-DEAD-1 не оценили количественно — там
   говорилось: «1 live import в `query.py`».

   **Что я выбрал:** держу `_sitka_catalog.py` минимальным per TASK
   текст и явно его ограничиваю комментарием в docstring; остальные
   адаптеры оставляю на старый импорт. Альтернатива — затащить все
   25 символов в `_sitka_catalog.py` (значительно больше кода, плюс
   transitive нужны ещё другие helpers из `canonical.py` — это
   расширение скоупа).

   **Что нужно от TL/Reviewer:** подтвердить выбор. Если правильнее
   была альтернатива, переделываем по новому TASK (или внутри B/C/D).
   Если оставляем как сейчас — следующий шаг (TASK D? avito-аудит?) в
   какой-то момент должен закрыть последний `shared.*` импорт, либо
   решить, что он остаётся легитимной shared библиотекой между двумя
   проектами.

2. **"23 alive store" vs "20 в build_registry()" — расхождение чисел в
   TASK acceptance.**

   TASK Acceptance говорит: «`tests/test_inventory_registry.py` —
   `build_registry()` × 23 store без basspro». Фактически
   `build_registry()` возвращает **20** уникальных адаптеров. 23 — это
   количество `.py` файлов в `adapters/stores/` (без basspro, включая
   `__init__.py` и две aggregator-файла `shopify_stores.py` /
   `bigcommerce_stores.py`, экспортирующих по несколько thin classes).
   Расхождение классического вида из Correction 016 (число элементов в
   перечислении ≠ число в acceptance).

   Я написал тест на **фактический** счёт (20) — иначе он сразу красный.
   В файле `test_inventory_registry.py` есть DOCSTRING комментарий,
   который явно объясняет это расхождение, чтобы Reviewer не
   спрашивал.

   **Что нужно от TL:** обновить TASK acceptance с 23 на 20 при
   accept-task, или попросить переписать тест на 23 (тогда нужно либо
   разбивать shopify_stores/bigcommerce_stores на отдельные файлы —
   это TASK A2, либо считать `__init__.py` как "файл-адаптер", что не
   соответствует семантике `build_registry()`).

3. **Compat shims `adapters/shopify.py`, `adapters/bigcommerce.py`,
   `adapters/families/shopify.py`, `adapters/families/bigcommerce.py`
   перенесены, хотя в TASK Files.new их нет.**

   TASK Files.new перечисляет только `families/__init__.py`,
   `families/shopify_support.py`, `families/bigcommerce_support.py` для
   families/. Но в upstream между store-файлами и support-модулями
   стоят два уровня re-export shim'ов (`adapters/shopify.py` →
   `families/shopify.py` → `families/shopify_support.py`). Store-файлы
   импортируют через эти shim'ы (`from app.inventory.adapters.shopify
   import ShopifyStoreAdapter`).

   **Что я выбрал:** перенёс все 4 shim'а как есть. Альтернатива —
   убрать shim'ы и переписать импорты во всех 22 store-файлах на
   прямой `from app.inventory.adapters.families.shopify_support import
   ShopifyStoreAdapter`. Это +22 файла в diff, чистая косметика,
   архитектурно лучше но больше scope. Решил, что Files.new это
   «обязательные новые файлы», не «исчерпывающий список того, что
   должно быть» — поэтому shim'ы остались.

   **Что нужно от TL/Reviewer:** OK или TASK A2 на их элиминацию.

4. **2-commit split удался.** Commit 1 — чистый `git mv` без edit'ов
   (git показывает все 47 файлов как 100% rename). Commit 2 — все
   import rewrite + cleanup. Reviewer может смотреть commit 1
   отдельно («правильно ли я переместил?») и commit 2 отдельно
   («правильно ли я переписал?»). Никаких трудностей не было.

5. **gitleaks-allowlist path обновлён.** Это drive-by fix, прямо
   следующий из rename: иначе следующий commit поймал бы Klevu key.
   Per Communication discipline #2 — отмечаю явно. Также убрана
   запись для `klevu_rogers.py` (был в мёртвом `catalog_sync/`,
   ушёл в `git rm -rf`).

6. **Test count в commit 2 message содержит ошибку.** В commit 4420fee
   я написал «296 passed» — на самом деле **265 passed + 1 skipped**
   (см. Done выше). Не amend'ю, фиксирую расхождение здесь для
   audit trail.

## Next step

TL делает code-review (рекомендую сначала commit `c7114ea` посмотреть
как diff renamed-only, потом `4420fee` — собственно изменения). Если
ACCEPT — запускает Reviewer subagent (Tier B + размер change'а
оправдывают второй pair of eyes). После Reviewer ACCEPT — push ветки,
PR, auto-deploy + smoke на проде, merge. Затем по плану TASK B (P0-1:
substring drop в `title_matches`).
