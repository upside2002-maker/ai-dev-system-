# HANDOFF: reviewer → tl — inventory-parser-fork-task-a

- Status: closed
- Date: 2026-05-27 17:45
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-a.md

## ARTIFACT

Branch `feat/inventory-parser-fork-task-a` (от master `ccac24b`), два
коммита:

- `c7114ea` — `refactor(inventory): git mv vendor/inventory_parser → app/inventory/`. 47 файлов, 0 insertions, 0 deletions, все R100.
- `4420fee` — `refactor(inventory): rewrite imports + drop vendor + tests + CI cleanup`. 220 файлов (8 A / 166 D / 45 M / 1 R), +1195 / -32677.
- Total master→branch: 230 файлов, +1267 / -32749 (net **-31 482 LOC**).

Сопутствующий HANDOFF Worker→TL: `project-overlays/sitka-office/HANDOFFS/2026-05-27-worker-to-tl-inventory-parser-fork-task-a.md` (Status: open).

## SUMMARY

**ACCEPT.** Tier-B бар выдержан: что работало до форка — продолжает
работать (smoke `rogers/blizzard` → 6 items, status=ok); ничего из
запрещённого (Tier A `sitka-core/`, avito vendor, миграции,
substring-drop в `title_matches`, Amazon timeout 35.0) не тронуто;
4 новых файла тестов (31 кейс) покрывают пере-маршрутизированные
импорты, registry-инвариант (20 адаптеров, basspro absent),
F-PARSE-1 текущее поведение для TASK B, и fixture-smoke на 4
семействах адаптеров. Все 6 Conflicts/risks из HANDOFF Worker'а
сверены с кодом — каждый совпадает с тем, что обещано. Главное
открытое окно — TASK A2 (15 символов `shared.product.sitka_catalog`
ещё импортятся из avito vendor) — оно зафиксировано в TL correction
post-handoff внутри TASK и уже занесено в task-list как pending.

## FINDINGS

Findings нулевые — критических, high, medium, low не обнаружено.
Подтверждённые проверки ниже:

### F1 [info]. Commit split — чистый и проверяемый отдельно

- `git show c7114ea --stat | tail -1`: `47 files changed, 0 insertions(+), 0 deletions(-)`.
- `git show c7114ea --name-status | grep -c '^R100'` → 47 (все 47 файлов 100% renames).
- Reviewer/blame работает: история по файлу прослеживается за rename.

### F2 [info]. Tests — посчитаны заново

- `pytest tests/test_inventory_query.py tests/test_inventory_title_matches.py tests/test_inventory_registry.py tests/test_inventory_smoke.py -v` → **31 passed in 1.27s** (7 + 13 + 6 + 5; ровно по HANDOFF).
- `pytest tests/` → **265 passed, 1 skipped in 2.22s** (ровно по HANDOFF, +24 vs master).

### F3 [info]. Smoke — реальный network на rogers подтверждён

Команда из prompt'а:
```
.venv/bin/python -c "import asyncio; from app.parsers.inventory_v2 import run_parser_search; r = asyncio.run(run_parser_search('blizzard', ['rogers'])); print(len(r[0].items), r[0].status, r[0].reason)"
```
→ `6 ok None` (env: `SITKA_APIFY_TOKENS` загружены из `sitka-services/.env`; без них падает на `ApifyError` при `AmazonAdapter()` init во время `build_registry()` — это известная backlog-проблема, не TASK A; смысл smoke'а — что rogers сам работает, и работает).

### F4 [info]. Vendor really gone (git-level)

- `git ls-files sitka-services/vendor/inventory_parser/` → 0 файлов.
- `git diff master..HEAD --stat | grep -c '^ .*vendor/inventory_parser'` → 166 удалённых файлов в коммите 2.
- Filesystem-residue в `sitka-services/vendor/inventory_parser/inventory/.../__pycache__/*.pyc` — это untracked orphan bytecode, gitignored по правилу `.gitignore:13 __pycache__/`. Не попадёт в Docker image (исключён через `__pycache__` в `.dockerignore` стандартно либо очистится при `COPY . .` без stale bytecode). Безвредно.

### F5 [info]. Public API — ровно 5 символов

`app/inventory/__init__.py` экспортирует `__all__ = [DEFAULT_STORE_NAMES, ItemResult, ParserService, StoreRunResult, parse_query]` — без `InventoryV2Module*`, `ParsedQuery`, `run_store_query{,ies}`. Поверхность чище чем у upstream.

### F6 [info]. `_sitka_catalog.py` — ровно 10 публичных + private machinery

`__all__` (строки 525-535) содержит ровно: `COLOR_PARSE_TERMS`, `SIZE_PARSE_TERMS`, `canonical_color_key`, `canonical_product_tokens`, `canonical_size_key`, `canonical_token_variants`, `color_matches`, `normalize_match_text`, `phrase_pattern`, `size_matches` — 10 штук, как в TASK Files.new. Private machinery (под `_`) — helpers и catalog facts из `canonical.py`/`matching.py`/`facts.py` avito vendor'а, без которых публичные 10 не работают. Docstring явно фиксирует scope и почему 8 других alive адаптеров продолжают импортировать из `shared.product.sitka_catalog` (TASK A2).

### F7 [info]. `_governor.py` — только Protocol

Файл 41 строка, единственная top-level декларация `class Governor(Protocol)` с двумя async-методами (`acquire_live`, `record_request`). Остальные dataclass'ы из исходного `snapshot/types.py` (CooldownState, PriceObservation и т.д.) ушли в `git rm`. Docstring объясняет почему Protocol сохранён (Phase 2 seam).

### F8 [info]. Registry — 20 vs 23 reconciled через docstring + test

`registry.py:47-69` строит ровно 20 уникальных адаптеров (basspro отсутствует и в импортах, и в `build_registry()`, и в `DEFAULT_STORE_NAMES`). `test_inventory_registry.py:62-95` пинит 20 через `_EXPECTED_REGISTRY_SIZE = 20` + `_EXPECTED_STORE_NAMES = frozenset({...20 имён...})`. Docstring файла (строки 9-19) объясняет расхождение «23 файлов в `adapters/stores/` ≠ 20 классов в `build_registry()`» — Worker не оставил это для Reviewer-а угадывать. TL correction post-handoff в TASK acceptance (строка 106) уже признаёт цифру 20.

### F9 [info]. Forbidden zones — не тронуты

- `sitka-core/`: 0 файлов в `git diff master..HEAD --name-only | grep sitka-core/` (нет).
- `sitka-core/migrations/`: 0 файлов.
- `sitka-services/vendor/avito_parser/`: 0 файлов.
- `BaseStoreAdapter.title_matches`: тело по `git show 4420fee -- adapters/base.py` показывает только import-rewrite, body identical → substring drop сохранён для TASK B (визуально в `base.py:452-470`).
- `_RUN_STORE_TIMEOUT_SECONDS = 35.0` в `runtime/service.py:29` — без изменений → Amazon timeout collision сохранена для TASK C.

### F10 [info]. Dockerfile + CI clean

- `Dockerfile`: `RUN pip install --no-cache-dir -e ./vendor/inventory_parser` удалён, заменён комментарием (строки 27-32); avito install остаётся (строка 25).
- `.github/workflows/ci.yml`: `pip install -e ./vendor/inventory_parser` удалён из Python-test job; `pip install -e ./vendor/avito_parser` (строка 247) остаётся.

### F11 [info]. gitleaks-allowlist — drive-by чистый

`.gitleaks.toml` diff показывает: путь rogers Klevu key обновлён с `vendor/inventory_parser/.../rogers.py` на `app/inventory/.../rogers.py`; запись `klevu_rogers.py` (была в мёртвом `catalog_sync/`) корректно удалена; описание `description` обновлено на «forked parser» вместо «vendored». HANDOFF #5 явно отмечает это как drive-by, дисциплина Communication discipline #2 соблюдена.

### F12 [info]. Correction 001 — не нарушена

- `grep -rn "USD|RUB|margin|exchange_rate" sitka-services/app/inventory/` показывает только строковые литералы `"USD"` как currency-code в parser output (types.py, base.py, amazon.py, ebay.py). Никакой pricing/FX/margin-логики в integration layer — domain decisions остаются в Haskell core.
- `core.py` / `runtime/service.py`: 0 матчей по USD/RUB/margin/exchange.

## MISSING

Ничего. Acceptance contract пройден полностью:

- [x] `app/inventory/` создан со сглаженной v2 структурой (47 файлов rename + 4 теста + 4 fixture HTML).
- [x] Все 22 alive store без basspro (20 классов через 22 файла) — переехали в `app/inventory/adapters/stores/`.
- [x] `vendor/inventory_parser/` удалён (git-level; orphan pyc — untracked).
- [x] Все `from inventory.v2.*` импорты переписаны — `grep` пустой.
- [x] `_sitka_catalog.py` создан, только 10 публичных в `__all__`.
- [x] Dockerfile + CI без inventory_parser, avito install сохранён.
- [x] 4 теста, 31/31 passed; full suite 265 + 1 skip; smoke на rogers возвращает 6 items.

Тесты `test_inventory_title_matches.py` явно пинят F-PARSE-1 для TASK B, `test_inventory_registry.py` пинит inventory без basspro для будущих регрессий — это **полезное расширение покрытия**, не gap.

## SCOPE CREEP

Нет. Worker не вышел за TASK A. 4 шима (`adapters/shopify.py`, `bigcommerce.py`, `families/shopify.py`, `families/bigcommerce.py`) перенесены как часть pure-rename (commit 1, R100); Worker явно отметил это в Conflicts #3 HANDOFF'а и предложил TASK A2 для их элиминации — TL accept ответом. Это не creep, это документированное residual.

15 символов `shared.product.sitka_catalog` всё ещё импортятся из avito vendor (Conflicts #1) — TL уже добавил пост-handoff correction в TASK + создал pending TASK A2. Также не creep, это известный artefact decomposed.

## NITS

Не блокирующие, информация для TL/будущих сессий:

### N1. Commit message commit 2 содержит ошибку счёта

В body коммита `4420fee` фраза «296 passed» — реальный счёт 265 passed + 1 skipped (HANDOFF Conflicts #6 сам флагнул это, не amend'ит, audit trail). Если TL хочет почистить — это `git rebase -i` против коммита 2 с правкой body, но это amend-history и стоимость > пользы. Рекомендую **оставить как есть**, HANDOFF #6 уже фиксирует расхождение в audit trail.

### N2. `test_inventory_registry.py` ставит `SITKA_APIFY_TOKEN` placeholder при импорте

`test_inventory_registry.py:29` и `test_inventory_smoke.py:37` оба делают `os.environ.setdefault("SITKA_APIFY_TOKEN", "test-placeholder-token")` до импорта `build_registry`. Это уместно — `AmazonAdapter()` падает в `ApifyError` без токена. Но это уже **2 копии одной и той же грязи** в тестах. Тривиальный рефактор — поднять в `conftest.py` (autouse session-scoped fixture), но out of TASK A scope. Drive-by для TASK A2 или отдельной мелкой задачи.

### N3. Smoke без `.env` — падает на Amazon

Smoke из prompt'а **не работает** без `SITKA_APIFY_TOKENS=...` в окружении, потому что `AmazonAdapter` строится при `build_registry()` лениво, а не «lazy». На локалке с `.env` всё ок (6 items, status=ok). На CI это покрывается — там стоит `SITKA_APIFY_TOKEN=test-placeholder-token` (см. N2). Документировать в TL'овском HANDOFF к user'у: **до deploy smoke на prod нужно проверить, что `SITKA_APIFY_TOKENS` есть в env**. На самом деле это уже есть на prod (Amazon parser работает), но если deploy идёт со свежего env-bootstrap, smoke может пройти ложно зелёным («ApifyError» = адаптер не построился, не «нет товаров»).

### N4. Pyc residue в `sitka-services/vendor/inventory_parser/`

После `git rm -rf` остаются orphan `__pycache__/*.pyc` файлы — это нормальное поведение `git rm` (только git-tracked files). На локалке Worker'а stale bytecode безвреден (gitignored, `.dockerignore` исключает, runtime не загрузит без `.py`). Но чисто эстетически — можно `rm -rf sitka-services/vendor/inventory_parser/` после деплоя для гигиены файловой системы. Не блокирующий.

## RECOMMEND

**ACCEPT без замечаний.**

Я бы рекомендовал TL:

1. **Принять HANDOFF и TASK A**: всё что обещано — реализовано; всё что forbidden — не тронуто; тесты зелёные; smoke зелёный; CI-конфиги корректны.
2. **Push + open PR + auto-deploy + prod smoke** — стандартный pipeline для Tier B.
3. **Перед prod smoke** — проверить, что `SITKA_APIFY_TOKENS` есть в env на сервере (N3). Если есть — `python -c "import asyncio; from app.parsers.inventory_v2 import run_parser_search; print(asyncio.run(run_parser_search('blizzard', ['rogers']))[0].items)"` должен дать > 0 items.
4. **После accept** — стартовать TASK B (P0-1 substring drop) как и планировалось. `test_inventory_title_matches.py:135-147` (`test_target_mode_substring_required_today`) пинит текущее F-PARSE-1 поведение — TASK B обязан явно перевернуть этот assert.
5. **TASK A2** (15 символов в `_sitka_catalog.py`) — уже в task list как pending; запускать перед avito-аудитом (иначе форк avito сломает inventory adapters).
6. **N1, N2, N4** — игнорировать или собрать в backlog. N3 — упомянуть в DEPLOY guidance или checklist перед prod-merge.

---

## Done

См. ARTIFACT + FINDINGS выше. Review pass самостоятельно выполнен:
- diff scope + split sanity (F1)
- tests run locally (F2)
- smoke on rogers (F3)
- vendor really gone (F4)
- public API contract (F5)
- `_sitka_catalog` boundary (F6)
- `_governor` trim (F7)
- registry 20 vs 23 (F8)
- forbidden zones unchanged (F9)
- Dockerfile + CI (F10)
- gitleaks-allowlist (F11)
- correction 001 (F12)

## Remaining

ничего — TL получает verdict и идёт дальше по pipeline (push → PR → smoke → merge → TASK B).

## Artifacts

- branch:               `feat/inventory-parser-fork-task-a` (local, не запушена; ждёт push от TL после accept)
- commit(s):            `c7114ea` (git mv 47 файлов R100, 0 insertions/0 deletions), `4420fee` (220 файлов: 8 A + 166 D + 45 M + 1 R, +1195/-32677)
- PR:                   нет — push делает TL после Reviewer ACCEPT
- tests:                Reviewer-side rerun: 31/31 passed (новые 4 файла); 265 passed + 1 skipped (full suite); smoke `rogers/blizzard` → 6 items, status=ok
- Product repo status:  committed (на local branch, не запушена)

## Conflicts / risks

Ноль. Все 6 conflicts из Worker HANDOFF'а свериены, каждое заявление совпадает с реальностью кода. Sanity-residual (N1-N4) выше — не блокирующие.

## Next step

TL → `make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/2026-05-27-reviewer-to-tl-inventory-parser-fork-task-a.md` → `make accept-task FILE=project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-a.md` → `git push origin feat/inventory-parser-fork-task-a` → `gh pr create` → wait CI → deploy → prod smoke (с проверкой `SITKA_APIFY_TOKENS` per N3) → merge.

После merge: TL отчёт в `MAILBOX/to-admin.md` (PR # + SHA master + LOC было/стало -31 482) и старт TASK B.
