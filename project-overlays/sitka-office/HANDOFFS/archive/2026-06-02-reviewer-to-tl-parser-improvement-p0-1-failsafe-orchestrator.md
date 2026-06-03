# HANDOFF: reviewer → tl — parser-improvement-p0-1-failsafe-orchestrator

- Status: closed
- Date: 2026-06-02 18:45
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-1-failsafe-orchestrator.md

## Summary

**ACCEPT.** P0-1 TASK закрыт корректно: `run_one` теперь полностью failsafe, любая
exception (`unregistered_store`, `_store_run_timeout` крах, adapter.search() crash,
postprocess crash) конвертируется в `failed_store_run`, не bubble в `asyncio.gather`.
Все Acceptance criteria выполнены, тесты red→green подтверждены независимо
(stash-swap), смоук-сценарий из ТЗ воспроизводится `[rogers/ok/20, unknown_store/failed/unregistered_store, 1shot/ok/10]`. Scope creep — ноль. Найдено 2 nit-уровня без блокировки.

## ARTIFACT

- TASK: `project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-1-failsafe-orchestrator.md` (Status: review)
- HANDOFF worker→tl: `project-overlays/sitka-office/HANDOFFS/2026-06-02-worker-to-tl-parser-improvement-p0-1-failsafe-orchestrator.md`
- Branch: `feat/parser-improvement-p0-1-failsafe-orchestrator` от master `301e7e3`
- Commit: `769b18c` — fix(parser): orchestrator-level failsafe in run_one (TASK P0-1)
- Diff (2 файла, exactly as TASK promised):
  - `sitka-services/app/inventory/runtime/service.py` +54/-7
  - `sitka-services/tests/test_inventory_runtime_failsafe.py` +302 (new)

## FINDINGS

Severity legend: critical / high / medium / low.

### Verified — green / acceptable

1. **[verified] Diff scope tight.** `git diff master..feat/parser-improvement-p0-1-failsafe-orchestrator --stat` показывает ровно 2 файла. Никаких касаний `query.py`, `adapters/base.py`, `_sitka_catalog.py`, store-файлов, `_store_run_timeout` body, `_RUN_MANY_CONCURRENCY`, `sitka-core/`, миграций, `.github/workflows/ci.yml`. Confirmed by `git diff master..<branch> -- .github/ sitka-core/` → empty.

2. **[verified] Failsafe logic structurally correct.** `service.py:196-260`:
   - Pre-check `if store not in self.registry` стоит **до** `async with semaphore:` (line 213-219) — никакого `self.registry[store]` доступа в throw-path до этой ветки.
   - `cap_seconds = _store_run_timeout(self.registry[store])` теперь внутри `try:` (line 233).
   - Сохранён dedicated `except asyncio.TimeoutError:` ДО `except Exception` (line 238-244) — `store_timeout` reason не теряется.
   - `except Exception as exc:` логирует через `logger.exception(...)` (line 252-254) ДО возврата `failed_store_run`.
   - Префикс `adapter_error:<type>` соответствует Acceptance criteria.
   - `_store_run_timeout` helper body не тронут (только call-site сдвинут на одну строку).

3. **[verified] Тесты независимо запущены.** Target file 6/6 green за 1.46 s. Full suite `make services-test` — **298 passed, 1 skipped** за 39.62 s (точно как HANDOFF claim'ил +6 кейсов vs A2 baseline 292+1).

4. **[verified] Red→green TDD sequence.** Подменил `sitka-services/app/inventory/runtime/service.py` на master-версию (`git show master:...`), оставил тестовый файл от ветки, прогнал pytest:
   ```
   4 failed, 2 passed:
     FAILED test_unregistered_store_returns_failed_not_raises  (KeyError bubble)
     FAILED test_search_raises_key_error_is_caught            (reason='store_error:...')
     FAILED test_search_raises_runtime_error_is_caught        (reason='store_error:...')
     FAILED test_adapter_exception_is_logged_with_stacktrace  (no logger.exception)
   ```
   Восстановил fixed-версию → 6 passed. Это полностью совпадает с HANDOFF («Pre-fix: 4 failed, 2 passed. Post-fix: 6 passed»). TDD red-first честный.

5. **[verified] Smoke сценарий из ТЗ воспроизведён.**
   ```
   SITKA_APIFY_TOKENS=dummy .venv/bin/python -c "..."
   → [('rogers', 'ok', '', 20),
      ('unknown_store', 'failed', 'unregistered_store', 0),
      ('1shot', 'ok', '', 10)]
   ```
   No `KeyError` escape, 3 результата вернулись, healthy sibling-ы preserved.

6. **[verified] pytest-asyncio CI pin не тронут.** `.github/workflows/ci.yml:248` всё ещё содержит `"pytest-asyncio>=0.26,<0.27"` с комментарием от TASK A. Forbidden zone honoured.

7. **[verified] Local-only no-PR posture.** `gh pr list --search "head:feat/parser-improvement-p0-1"` возвращает пусто. Ветка запушена в origin как backup (Worker подтвердил), но PR не открыт — соответствует Owner-директиве 2026-06-02.

8. **[verified] Correction 001 / Tier B плумбинг scope.** Изменение — чисто integration-layer (orchestrator wraps adapter calls). Бизнес-решений в orchestrator не приехало; reason-таксономия (`unregistered_store`, `store_timeout`, `adapter_error:<type>`) — operational, не domain.

## MISSING

Ничего блокирующего. Минимально достаточный набор тестов (6 кейсов) покрывает все три ветки Acceptance (unregistered / search()-crash / dedicated TimeoutError). Tier B normal mode — example-based тестов хватает; property-test не нужен.

Один опциональный кейс который мог бы быть, но не блокирует: **postprocess crash** (адаптер вернул валидный `SearchExecution`, но `from_search_execution` / agent enrichment бросил исключение). Текущие тесты прокрывают только crash в `adapter.search()`. Это same code-path (вход в тот же `except Exception`), так что покрытие фактически достигнуто транзитивно — но прямой кейс был бы пожирнее. Не блокирует accept, можно добавить при следующем касании файла.

## SCOPE CREEP

Ничего. Worker остался в scope. Drive-by фиксов нет. Из HANDOFF "Conflicts / risks" видно что Worker правильно идентифицировал adapter-construction crash в `build_registry()` (Apify token) как ОТДЕЛЬНЫЙ failure mode не P0-1 scope, ВНЕС его в HANDOFF как открытый вопрос для TL — и не стал чинить. Это образцово-показательная дисциплина scope (см. также Correction 008/011 — Worker правильно не вышел за рамки).

TL уже зафиксировал этот случай как backlog #19 (`adapter-construction failsafe в build_registry() — Apify token crash`) per задание Reviewer'у. Не релитигирую.

## NITS

Без блокировки. Опциональные мелочи.

1. **nit (low)** — `tests/test_inventory_runtime_failsafe.py:241,244`: `ok_two.store = "fake_ok_two"` и `raising.store = "fake_broken"` мутируют class-level атрибут на инстансе. Это работает (instance attr заслоняет class attr), но если кто-то заведёт subclass и положится на class-level `store` — будет сюрприз. Альтернатива чище — фабрика-функция или две распаянные subclass'ы. Не блокирует.

2. **nit (low)** — комментарий в коде упоминает «hypothetical crash in the helper (e.g. an exotic adapter whose `search_timeout_seconds` is something weird like `NaN`)» (`service.py:228-232`). Хороший контекст для будущего читателя, но в текущем `_store_run_timeout` (TASK C) NaN-входа фактически не бывает — все адаптерные значения проверены TASK C аудитом. Если хочется быть строгим — переформулировать на «defence-in-depth» без выдуманного примера. Не блокирует.

## RECOMMEND

**ACCEPT TASK без условий.**

Все Acceptance criteria выполнены, TDD честный, диф ровно в scope, тесты прогоняются независимо, смоук работает, forbidden zones не тронуты, TL backlog item #19 уже отражает остаточный риск (build_registry() Apify crash) который **физически не закрывается** orchestrator-level фиксом и правильно вынесен отдельно.

Worker'ское поведение тоже образцовое: scope-дисциплина, явное вынесение adapter-construction crash как ОТКРЫТОГО ВОПРОСА в HANDOFF (не молча подложил вариант 1/2/3), пушнул ветку в origin как backup без открытия PR (Owner-директиву соблюл).

Дальше — TL: `make accept-handoff` на этом файле, затем `make accept-task` на TASK файле, и можно запускать P0-2 от ЭТОЙ ветки (как и предписывает TASK Context). Backlog #19 остаётся в очереди как P1/P0-4.

## Done

(Reviewer report выше; ARTIFACT / FINDINGS / MISSING / SCOPE CREEP / NITS / RECOMMEND.)

## Remaining

Ничего по reviewer-стороне. TL принимает решения.

## Artifacts

- branch:               `feat/parser-improvement-p0-1-failsafe-orchestrator` (от master `301e7e3`)
- commit(s):            `769b18c` (fix(parser): orchestrator-level failsafe in run_one (TASK P0-1))
- PR:                   нет (Owner directive 2026-06-02 — CI заморожен, локально-only)
- tests:                target file `test_inventory_runtime_failsafe.py` 6/6 green (1.46 s); full `make services-test` 298 passed + 1 skipped (39.62 s); red-first verified независимо через stash-swap (4 failed + 2 passed на master service.py с новым тестовым файлом)
- Product repo status:  committed

## Conflicts / risks

Нет. Single open question уже filed TL'ом как backlog #19 (`adapter-construction failsafe в build_registry()` — Apify token crash). Reviewer не релитигирует.

## Next step

TL: `make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/2026-06-02-reviewer-to-tl-parser-improvement-p0-1-failsafe-orchestrator.md`, затем `make accept-task FILE=project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-1-failsafe-orchestrator.md`. После этого — start P0-2 Worker от ветки `feat/parser-improvement-p0-1-failsafe-orchestrator` (не от master, per TASK Context).
