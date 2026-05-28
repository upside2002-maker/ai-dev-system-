# HANDOFF: worker → tl — inventory-parser-fork-task-c-amazon-timeout

- Status: closed
- Date: 2026-05-28 12:39
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-28-inventory-parser-fork-task-c-amazon-timeout.md

## Summary

P0-2 fix landed in single commit on `feat/inventory-parser-fork-task-c-amazon-timeout`. Hardcoded `_RUN_STORE_TIMEOUT_SECONDS = 35.0` literal in `runtime/service.py` replaced with `_store_run_timeout(adapter)` helper that honours each adapter's declared `search_timeout_seconds` + 10 s buffer, with a 35 s floor. Amazon (180 s declared → 190 s cap) now has enough budget for Apify junglee. All acceptance criteria met; full services suite green.

## Done

- `sitka-services/app/inventory/adapters/base.py` — added class attribute `search_timeout_seconds: float = 35.0` on `BaseStoreAdapter` with comment explaining the scheduler contract.
- `sitka-services/app/inventory/runtime/service.py`:
  - Renamed `_RUN_STORE_TIMEOUT_SECONDS` → `_RUN_STORE_TIMEOUT_SECONDS_DEFAULT` (grepped: no external imports anywhere in `sitka-services/`).
  - Added `_STORE_TIMEOUT_NETWORK_BUFFER = 10.0` constant.
  - Added `_store_run_timeout(adapter)` helper returning `max(adapter.search_timeout_seconds + buffer, default)`.
  - `run_one` inner function now computes `cap_seconds = _store_run_timeout(self.registry[store])` and passes it to `asyncio.wait_for(..., timeout=cap_seconds)`.
- `sitka-services/tests/test_inventory_runtime_timeout.py` — new file, 7 tests, all green, mock-based (no network):
  - `test_default_adapter_gets_floor_cap` — 35 s + 10 s = 45 s.
  - `test_amazon_style_subclass_gets_declared_budget` — 180 s + 10 s = 190 s, asserts `>= 180`.
  - `test_low_override_is_clamped_to_floor` — adapter with `search_timeout_seconds = 10` still gets 35 s (floor protection).
  - `test_helper_handles_adapter_without_attribute` — `getattr` fallback path covered.
  - `test_run_many_completes_under_cap` — adapter sleeps 0.05 s under 35 s cap → `status="empty"` (its own SearchExecution), not failed.
  - `test_run_many_times_out_when_search_exceeds_cap` — adapter sleeps 2 s, cap monkey-patched to 0.2 s → `status="failed", reason="store_timeout"`.
  - `test_constants_have_expected_values` — pin on `_RUN_STORE_TIMEOUT_SECONDS_DEFAULT == 35.0` and `_STORE_TIMEOUT_NETWORK_BUFFER == 10.0`.
- Audit of all `adapters/stores/*.py` for `search_timeout_seconds` overrides — see "Conflicts / risks" below.

### Buffer value chosen

**+10 s**, exactly as suggested in TASK direction. Apify cold-start window for the junglee actor is ~5–10 s above the declared actor timeout (the TASK file notes this in the rationale). +10 s gives realistic headroom without making the upper bound absurd (200 s would have been). Adapter writers who need more can declare a larger `search_timeout_seconds` — buffer is on top.

## Remaining

Nothing in scope. Prod smoke (acceptance bullet 7) requires the change to be deployed first — handled by TL after PR merge.

## Artifacts

- branch:               feat/inventory-parser-fork-task-c-amazon-timeout
- commit(s):            c8f039f
- PR:                   (none yet — Worker does not push per TASK)
- tests:                7 new tests in `tests/test_inventory_runtime_timeout.py` all green; full `make services-test` 283 passed, 1 skipped (the 1 skip is pre-existing, not introduced).
- Product repo status:  committed

### Smoke result (TASK-defined check)

```
default:      45.0    (35 floor + 10 buffer)
amazon-style: 190.0   (180 declared + 10 buffer)
```

Also verified the real `AmazonAdapter` (via `SITKA_APIFY_TOKEN=test-placeholder`):
```
amazon.search_timeout_seconds: 180
amazon cap:                    190.0
```

## Conflicts / risks

### Audit of other adapters — only Amazon has the override today

Grep over `sitka-services/app/inventory/adapters/stores/*.py` for `search_timeout_seconds`:
```
amazon.py:34:    search_timeout_seconds = 180
amazon.py:61:    ..., timeout_seconds=self.search_timeout_seconds
```

That's it. The other 19 adapters in the registry (`als`, `ebay`, `eurooptic`, `franks`, `gohunt`, `gritr`, `jamesriver`, `jootti`, `kevins`, `lancaster`, `lennyshoe`, `linton`, `1shot`, `outdoor_insiders`, `phantom`, `rogers`, `scheels`, `vandam`, `badass`) all rely on the base default. No P1 followup is required for "other slow adapters with declared overrides".

I also looked at general `timeout` usage in `ebay.py` / `eurooptic.py` to spot any other slow-by-design pattern: eurooptic has Playwright `page.goto(timeout=45_000)` (45 s) in its DOM-rendering path. Worth noting because the 35 s default cap would in principle truncate it — but that path is gated behind a Playwright fallback that's not always taken, and it would belong to a separate TASK (different fix shape: declare `search_timeout_seconds = 50` on `EuroopticAdapter` so the helper picks it up). Outside this TASK; flagging it here so TL can decide whether to spin a P1.

### Naming nit (worth noticing, not changing here)

The TASK direction summary in the prompt uses `name = 't'` in the smoke snippet for an ad-hoc subclass, but the actual `BaseStoreAdapter` attribute is `store` (validated in `__init__`). I used `store` in the test file — works as written. Just a typo to be aware of when re-running the smoke from the prompt verbatim.

### Сценарий test_run_many_times_out_when_search_exceeds_cap

Этот тест monkey-patches `_store_run_timeout` чтобы вернуть 0.2 s — иначе ждать 45 s в каждом запуске unit-тестов жирно. Поведение clamp'а к 35 s floor отдельно покрыто `test_low_override_is_clamped_to_floor` (unit), а здесь интересен именно path "asyncio.wait_for → TimeoutError → failed_store_run". Возможно тебе захочется в долгую переехать на отдельный helper типа `_store_run_timeout_override` (parameter injection) — но это уже мелкая чистка не из scope этого TASK.

## Next step

TL accepts HANDOFF + opens PR off `feat/inventory-parser-fork-task-c-amazon-timeout`. After merge — prod smoke: `POST /api/sourcing/search` с `desiredItem="sitka jetstream"` и `stores=["amazon"]` → ожидаемый status НЕ `failed:store_timeout` (допустимые: `ok` / `empty` / `blocked`).
