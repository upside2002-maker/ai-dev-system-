# TASK: parser-improvement-p0-1-failsafe-orchestrator

- Status: open
- Ready: yes
- Date: 2026-06-02
- Project: sitka-office
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Закрывает **P0-1** из `docs/PARSER_IMPROVEMENT_TZ.md` — «Адаптеры падают глобально, не failsafe».

Симптом из ТЗ:
```python
await run_parser_search('q', stores=['rogers','scheels','basspro','franks',...])
# → ERROR: 'basspro'
```
Один сломанный адаптер валит весь run, теряются результаты остальных 14 магазинов.

**Точный root cause (TL grounding pass 2026-06-02):**

`app/inventory/runtime/service.py:run_one` (внутри `run_many`) **уже имеет** `try/except Exception` обёртку вокруг `asyncio.wait_for(...)`. Но **выше** этого try-блока стоит:
```python
async def run_one(store: str) -> StoreRunResult:
    started = time.perf_counter()
    cap_seconds = _store_run_timeout(self.registry[store])   # ← KeyError здесь
    async with semaphore:
        try:
            return await asyncio.wait_for(...)
```
Если `store` не в `self.registry` (например, оператор передал `basspro` — он удалён в TASK A), `self.registry['basspro']` бросает `KeyError('basspro')` **до** входа в try-блок. Эта exception bubble'ает в `asyncio.gather` (или эквивалент) в `run_many` и валит весь run.

Дополнительно ТЗ сообщает: после удаления basspro → падает one_shot. После удаления one_shot — продолжает. То есть есть **второй** unhandled failure mode для one_shot — нужно найти при работе над фиксом.

**Цель TASK:** сделать `run_one` полностью failsafe — любая exception в pipeline (registry miss / `_store_run_timeout` / `governor.acquire_live` / `adapter.search` / postprocess) → `failed_store_run(reason='adapter_error:<type>')`, **никогда** не bubble. Залогировать stacktrace падающего адаптера с уровнем ERROR.

## Решение

1. Переместить `cap_seconds = _store_run_timeout(self.registry[store])` **внутрь** try-блока. Перед этим — pre-check `if store not in self.registry: return failed_store_run(reason='unregistered_store')`.
2. Расширить `except Exception as exc:` — добавить `logger.exception("adapter %s failed in run_one", store)` (logger из `logging.getLogger(__name__)`).
3. Воспроизвести one_shot failure (через unit-test с моком, либо через probe в dev — посмотреть какая именно exception падает в `OneShotAdapter.__init__()` или `OneShotAdapter.search()`). Если это adapter-construction crash в `build_registry()` — registry неполный, и `self.registry['one_shot']` тоже → KeyError, который покрывается шагом 1. Если это что-то иначе — задокументировать в HANDOFF и убедиться что failsafe ловит.
4. Тесты:
   - Unit-test с моком: `run_many(query, stores=['rogers', 'unknown_store', 'one_shot'])` — все три должны вернуть `StoreRunResult` (валидные результаты `rogers` + два `failed`), не exception bubble.
   - Unit-test: моковый adapter бросает `KeyError` в `search()` — тоже `failed_store_run`, не bubble.
   - Unit-test: моковый adapter бросает `RuntimeError` в `__init__()` через `build_registry()` — тоже failsafe.

## Files

- modify: `sitka-services/app/inventory/runtime/service.py` (расширить `run_one`, ~30-50 LOC). Сохранить TASK C изменения (per-adapter `_store_run_timeout`) intact.
- new: `sitka-services/tests/test_inventory_runtime_failsafe.py` — unit-тесты на failsafe-сценарии.
- modify (optional): `sitka-services/app/inventory/runtime/service.py` — добавить `logger` в module imports.

## Do not touch

- **TASK B substring drop** (`adapters/base.py` `title_matches`) — закрыт PR #91, не трогаем.
- **TASK C per-adapter timeout cap** (`_store_run_timeout` helper в том же файле) — сохраняем, только перемещаем вызов внутрь try.
- **TASK A _sitka_catalog** — TASK A2 закрыл, не трогаем.
- **`_RUN_MANY_CONCURRENCY = 2`** — P1, не P0.
- **Adapter store files** — fix в shared runtime, не в адаптерах.
- **P0-2 (variant-level stock)** — отдельный TASK (`2026-06-02-parser-improvement-p0-2-variant-level-stock.md`).
- **P0-3 (hardcoded paths)** — отдельный TASK (`2026-06-02-parser-improvement-p0-3-env-paths.md`).
- **`sitka-core/`, миграции, avito vendor, prod.yml, auto-deploy.sh** — не трогать.

## Acceptance

- [ ] `run_one` в `runtime/service.py` имеет pre-check `if store not in self.registry: return failed_store_run(reason='unregistered_store', ...)`.
- [ ] `cap_seconds = _store_run_timeout(...)` перемещён внутрь try-блока.
- [ ] `except Exception as exc:` логирует stacktrace через `logger.exception(...)`.
- [ ] `tests/test_inventory_runtime_failsafe.py` — минимум 3 кейса (unregistered store / search() бросает / __init__() crash) + ровно одно failed_store_run с reason `'adapter_error:<type>'`.
- [ ] `make services-test` зелёный.
- [ ] Smoke (failing-test-first per DoD ТЗ): unit-test воспроизводит баг с unregistered store — red до фикса, green после.
- [ ] Один из ТЗ-Smoke-кейсов на dev: `await run_parser_search('Sitka Jetstream', stores=['rogers', 'unknown', '1shot'])` возвращает 3 результата (1 ok + 2 failed), не exception. Транскрипт в HANDOFF.
- [ ] One_shot failure mode задокументирован в HANDOFF: воспроизведён, root cause найден, покрыт failsafe.

## Context

- ТЗ от Owner'а: `/Users/ilya/Projects/sitka-office/docs/PARSER_IMPROVEMENT_TZ.md` § «P0-1. Адаптеры падают глобально, не failsafe».
- Грунтовка TL 2026-06-02: текущий `run_one` уже имеет try/except Exception, но `cap_seconds = _store_run_timeout(self.registry[store])` стоит ПЕРЕД try → KeyError при registry miss валит run.
- TASK C (master `4aa26ec`) — добавил `_store_run_timeout` helper. Этот TASK не отменяет TASK C, только перемещает вызов внутрь try.
- DoD из ТЗ §«Definition of Done»: failing test → green test → live smoke → make test → pre-commit → запись в UPSTREAM.md / CHANGELOG. Заметка про UPSTREAM.md / CHANGELOG: в форкнутом `app/inventory/` UPSTREAM.md не имеет смысла; CHANGELOG.md в корне репо не существует. Пропускаем эти два пункта (или TL поправит DoD после первого закрытого TASK'а).
- **Branching context:** GitHub Actions заморожены (неоплаченный счёт на free tier, решение Owner'а 2026-06-02 «делать локально»). Worker создаёт ветку `feat/parser-improvement-p0-1-failsafe-orchestrator` от master `301e7e3` или эквивалент. TL не пушит в origin для PR до разморозки CI; локально tested + accepted. P0-2 берётся от ЭТОЙ branch (не от master), чтобы избежать конфликтов в `runtime/service.py`.

После закрытия — TL отчитывается короткой запиской в `to-admin.md`. P0-2 на старт.
