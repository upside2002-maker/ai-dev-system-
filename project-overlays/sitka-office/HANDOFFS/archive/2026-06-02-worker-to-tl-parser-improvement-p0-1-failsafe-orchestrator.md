# HANDOFF: worker → tl — parser-improvement-p0-1-failsafe-orchestrator

- Status: closed
- Date: 2026-06-02 18:40
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-1-failsafe-orchestrator.md

## Summary

P0-1 закрыт: `run_one` теперь полностью failsafe — неизвестный
store, помеха в `_store_run_timeout`, исключение в `adapter.search()`
или `postprocess` конвертируются в типизированный
`failed_store_run`, никогда не bubble в `asyncio.gather`. Все 6
новых тестов зелёные, TASK C тесты сохранены, полный
`make services-test` 298 passed + 1 skipped (без регрессий).
Главный риск: one_shot **на этой машине** действительно не работает,
но **по другой причине** — `build_registry()` крашится на
`AmazonAdapter.__init__()` (нет Apify token локально). Это
adapter-construction crash до `run_one`, P0-1 его не закрывает,
вынесено в Conflicts ниже.

## Done

- `sitka-services/app/inventory/runtime/service.py` (+34 LOC, refactor `run_one`):
  - Добавлен module-level `logger = logging.getLogger(__name__)`.
  - Pre-check: `if store not in self.registry: return failed_store_run(reason='unregistered_store', ...)`.
  - `cap_seconds = _store_run_timeout(self.registry[store])` перемещён **внутрь** `try:` блока.
  - `except Exception as exc:` теперь логирует `logger.exception("adapter %s failed in run_one", store)` ДО возврата `failed_store_run`.
  - Префикс reason переименован: `store_error:<type>` → `adapter_error:<type>` (соответствует Acceptance criteria TASK).
  - TASK C сохранён: `_store_run_timeout` helper не тронут, только перенесён вызов.
- `sitka-services/tests/test_inventory_runtime_failsafe.py` (новый файл, 6 кейсов):
  1. `test_unregistered_store_returns_failed_not_raises` — каноничный P0-1 баг (red→green sequence записан).
  2. `test_search_raises_key_error_is_caught` — `KeyError` в `adapter.search()` → `adapter_error:KeyError`.
  3. `test_search_raises_runtime_error_is_caught` — `RuntimeError` → `adapter_error:RuntimeError`.
  4. `test_search_raises_timeout_error_uses_dedicated_reason` — `asyncio.TimeoutError` → `store_timeout` (не `adapter_error:`).
  5. `test_run_many_isolates_failures_across_stores` — mixed batch (healthy + broken + healthy), порядок сохраняется.
  6. `test_adapter_exception_is_logged_with_stacktrace` — `logger.exception` пишет с exc_info.
- Red→Green TDD sequence (документировано):
  - До фикса: `tests/test_inventory_runtime_failsafe.py` — 4 failed, 2 passed.
    - Case 1 падал с реальным `KeyError: 'unknown_store'` на строке `cap_seconds = _store_run_timeout(self.registry[store])` (service.py:200) — точно как ground'нул TL.
    - Cases 2, 3, 6 падали потому что префикс был `store_error:` (старый) и не было `logger.exception`.
  - После фикса: 6 passed, 0 failed.

## Remaining

- TASK закрыт по scope. Опциональный backlog item (см. Conflicts ниже):
  Amazon adapter-construction crash в `build_registry()` — не P0-1
  scope, но проявляется как user-visible bug на dev-машинах без
  Apify token. TL может решить, открывать ли отдельный TASK
  (P0-4? lazy Apify runner?) или оставить в KNOWN_ISSUES.

## Artifacts

- branch:               `feat/parser-improvement-p0-1-failsafe-orchestrator` (от master `301e7e3`)
- commit(s):            `769b18c` — fix(parser): orchestrator-level failsafe in run_one (TASK P0-1)
- PR:                   нет (по решению Owner'а 2026-06-02 GitHub Actions заморожены, ветка запушена в origin как backup без открытия PR)
- tests:                целевой файл 6/6 green; полный `make services-test` 298 passed + 1 skipped (без регрессий относительно базовой линии); TASK C timeout тесты 7/7 green (регрессия проверена)
- Product repo status:  committed

Smoke transcript (с hand-built registry — обход AmazonAdapter
construction crash, см. Conflicts):

```
$ .venv/bin/python -c "
import asyncio
from app.inventory.adapters.stores import OneShotAdapter, RogersAdapter
from app.inventory.runtime.service import ParserService

async def main():
    registry = {'1shot': OneShotAdapter(), 'rogers': RogersAdapter()}
    svc = ParserService(registry=registry)
    r = await svc.run_many('Sitka Jetstream',
                           stores=['rogers', 'unknown_store', '1shot'])
    print([(s.store, s.status, s.reason, len(s.items)) for s in r])

asyncio.run(main())"
[('rogers', 'ok', '', 20),
 ('unknown_store', 'failed', 'unregistered_store', 0),
 ('1shot', 'ok', '', 10)]
```

Pre-fix эта же команда падала с `KeyError: 'unknown_store'`, 0
результатов вернулось. Post-fix все три есть, статусы `ok` / `failed`
/ `ok`, healthy sibling-результаты сохранились. `1shot` сам по себе
**работает** на этом запросе и вернул 10 items.

## Conflicts / risks

**One_shot root cause — другой класс, не registry miss.**

ТЗ сообщает: «После удаления basspro → падает one_shot. После
удаления one_shot — продолжает». TL обоснованно предположил
второй failure mode. Воспроизвёл локально через
`from app.inventory.registry import build_registry; r = build_registry()`:

```
shared.apify_runner.ApifyError: no Apify tokens configured
(apify_tokens / apify_token)
```

Цепочка краша: `ParserService.__init__()` (lazy в
`get_parser_service()`) → `build_registry()` (registry.py:67) →
`AmazonAdapter()` (amazon.py:41) → `ApifyRunner()`
(vendor/avito_parser/shared/apify_runner.py:94) → `ApifyError`
если ни `apify_token`, ни `apify_tokens` не сконфигурированы в
config (читается через `get_secret_value(...)`).

Комментарий в `amazon.py:38-40` прямо говорит: «Fail fast at
registry-build time if no tokens are configured, instead of on
first user query.» — это намеренное поведение, не баг адаптера.

**Что это значит для one_shot:** `OneShotAdapter` сам по себе
**не сломан** (init OK, search в смоке вернул 10 items). Но если
`AmazonAdapter` крашится при construction, `build_registry()`
бросает `ApifyError` **до** того как `OneShotAdapter` добавляется
в dict. Lazy-init `ParserService` через
`get_parser_service()` пропускает эту ошибку наружу, в
`run_parser_search` → пользователь видит `'1shot'` неработающим
вместе со всеми остальными, потому что _весь сервис_ не
конструируется.

**Покрывает ли P0-1 фикс этот случай?** Частично. Pre-check
`if store not in self.registry` сработает если кто-то даст
неполный registry в `ParserService(registry=...)` (как наш smoke
обход). НО construction crash из `build_registry()` происходит
**до** `ParserService.__init__` завершается, до `run_one`, до
`asyncio.gather`. Failsafe-граница `run_one` его физически не
видит.

**Класс: adapter-construction crash в build_registry().**
Это **отдельный** failure mode от того, что P0-1 закрывает.
Релевантные опции (НЕ делаю в этом TASK, scope P0-1 — orchestrator
level):

1. Lazy Apify runner: `AmazonAdapter._runner` инициализируется на
   первом `search()`, не в `__init__`. Тогда construction всегда
   проходит, search вернёт `failed:adapter_error:ApifyError` через
   наш новый failsafe — round trip закрыт.
2. `build_registry()` catches per-adapter construction errors и
   возвращает partial registry: записывает неудачные адаптеры в
   warning log, продолжает. Тогда `1shot in registry` остаётся
   True даже если `amazon` упал.
3. `ApifyRunner()` принимает опциональный режим «no-token = skip»
   вместо raise — тогда `AmazonAdapter` сконструируется и при
   первом `search()` вернёт `failed`.

Любой из трёх вариантов решает класс «один адаптер сломан в
construction — весь сервис недоступен». Все три — отдельный TASK
P0-4 (или amendment к P0-1 если TL хочет включить сейчас).
Воздержался от выбора варианта, потому что:
- TASK explicit «If you find a NEW adapter-construction bug — flag
  it as a future backlog item, do NOT fix it in this TASK».
- Выбор между 1-2-3 — architectural decision, не worker scope.

Воспроизводимая команда:
```
cd sitka-services
.venv/bin/python -c "
from app.inventory.registry import build_registry
r = build_registry()
print('1shot' in r)
"
# Pre-this-TASK: bombs with ApifyError, never prints.
# Post-this-TASK: same — orchestrator failsafe doesn't see it.
```

**DoD pruning — подтверждено намеренно:**
- TASK Context explicitly accepts: «UPSTREAM.md … forked
  `app/inventory/` … не имеет смысла. CHANGELOG.md в корне репо
  не существует. Пропускаем эти два пункта». Не трогал ни одного.

**Pre-commit / hygiene:**
- `git commit` прошёл все pre-commit хуки (gitleaks, large-files,
  yaml/json/toml validators, eof-fixer, trailing-whitespace,
  case-conflict, merge-conflict). Полный лог в `git commit` output.
- `actionlint` и `check-imports` skipped (no relevant files
  changed — Python-only TASK).

**Branch state:**
- `git push origin feat/parser-improvement-p0-1-failsafe-orchestrator` прошёл (`* [new branch]` в output).
- PR **не** открывал (TASK Direction + Owner decision 2026-06-02 «делать локально», CI заморожен).
- Master не тронут, ветка отделена от `301e7e3`.

## Next step

TL: принять TASK через `make accept-task` после ревью HANDOFF +
diff (`git diff master...feat/parser-improvement-p0-1-failsafe-orchestrator`).

Открытый вопрос для TL/Owner:
- Открывать ли отдельный TASK на adapter-construction failsafe
  (вариант 1/2/3 в Conflicts)? Без этого `run_parser_search` на
  dev-машинах без Apify token останется неработоспособным, хотя
  orchestrator-level failsafe (P0-1) уже на месте.
- P0-2 (variant-level stock) per TASK Context берётся от ЭТОЙ
  ветки, не от master, чтобы избежать конфликтов в `service.py`.
  Wait for TL signal.
