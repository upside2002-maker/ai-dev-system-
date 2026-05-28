# HANDOFF: reviewer → tl — inventory-parser-fork-task-c-amazon-timeout

- Status: closed
- Date: 2026-05-28 12:44
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-28-inventory-parser-fork-task-c-amazon-timeout.md

## Summary

ACCEPT. Per-adapter timeout cap helper is correctly wired, all 7 new tests + full 283-passed services suite green, smoke values match HANDOFF (`default: 45.0`, `amazon-style: 190.0`). Diff is exactly the 3 expected files (+340/-2 LoC), no forbidden surfaces touched, no external imports of the renamed constant. No blocking findings.

## ARTIFACT

- Branch: `feat/inventory-parser-fork-task-c-amazon-timeout`
- Base: master `53a738e` (override.example.yml — close CORE_AUTH drift, PR #92)
- Single commit under review: `c8f039f` "fix(parser): per-adapter runtime timeout cap (TASK C / P0-2)"
- TASK file: `project-overlays/sitka-office/TASKS/2026-05-28-inventory-parser-fork-task-c-amazon-timeout.md`
- Worker HANDOFF: `project-overlays/sitka-office/HANDOFFS/2026-05-28-worker-to-tl-inventory-parser-fork-task-c-amazon-timeout.md`
- Tier B, Mode: normal

## FINDINGS

(no critical / high / medium / low findings — see RECOMMEND)

## MISSING

(nothing material; all acceptance criteria met or queued explicitly)

- Acceptance bullet 7 (prod smoke `POST /api/sourcing/search` `stores=["amazon"]` → not `failed:store_timeout`) **requires deploy first** — Worker correctly left it to TL. Not a Reviewer block.

## SCOPE CREEP

None. Diff is exactly the 3 files declared in TASK `## Files`:

```
sitka-services/app/inventory/adapters/base.py      |   9 +
sitka-services/app/inventory/runtime/service.py    |  32 +-
sitka-services/tests/test_inventory_runtime_timeout.py | 301 +++++++++
3 files changed, 340 insertions(+), 2 deletions(-)
```

Forbidden surfaces I explicitly checked, all clean:
- `sitka-services/app/inventory/query.py` — untouched.
- `title_matches` body in `adapters/base.py` — untouched (only the new class attribute was added; TASK B PR #91 territory preserved).
- `_PRODUCT_CHECK_TIMEOUT_SECONDS` — untouched.
- `_RUN_MANY_CONCURRENCY` — untouched.
- `amazon.py` body — untouched; `search_timeout_seconds = 180` at line 34 preserved.
- `sitka-core/`, migrations, `sitka-services/avito/`, `docker-compose.prod.yml`, `deploy/`, `scripts/`, `.github/` — all empty in diff.
- `.github/workflows/ci.yml` `pytest-asyncio>=0.26,<0.27` pin (TASK A flake-guard) — intact at line 248.

## NITS

1. **Floor-test note in `test_run_many_times_out_when_search_exceeds_cap` docstring contains a subtle inaccuracy.** The docstring says "`_store_run_timeout` will clamp the 0.2 s back up to the 35 s floor — so this test actually exercises the floor + the timeout path". But the test then monkey-patches `svc._store_run_timeout = lambda _adapter: 0.2` — so the clamping path is **bypassed**, not exercised, by this specific test. The HANDOFF "Conflicts / risks" section already calls this out honestly ("monkey-patches `_store_run_timeout` чтобы вернуть 0.2 s"); the docstring just lags the actual code by one sentence. Cosmetic; the floor clamping is independently covered by `test_low_override_is_clamped_to_floor`. Worth fixing on next pass but does NOT block ACCEPT.

2. **`getattr` fallback duplicates the class default.** `_store_run_timeout` does `getattr(adapter, "search_timeout_seconds", _RUN_STORE_TIMEOUT_SECONDS_DEFAULT)` — but `BaseStoreAdapter` now declares the attribute as a class default (35.0). The `getattr` default is therefore only reachable for non-`BaseStoreAdapter` objects (covered by `test_helper_handles_adapter_without_attribute`). Belt-and-braces, intentional per the test's docstring. Acceptable.

3. **`AmazonAdapter` typed `search_timeout_seconds = 180` (int) vs base annotated `float`.** No runtime issue — Python's `+` and `max` work fine across `int`/`float`, and `float(declared)` is forced in the helper. Type annotations would flag this if `mypy` were enabled, but it isn't here. Cosmetic.

## RECOMMEND

**Verdict: ACCEPT.**

- TL: open PR off `feat/inventory-parser-fork-task-c-amazon-timeout` against master, merge after CI green (8 lanes — pre-existing structure).
- After merge: deploy + run the TASK acceptance prod smoke (`POST /api/sourcing/search desiredItem="sitka jetstream" stores=["amazon"]`) — expected NOT `failed:store_timeout`.
- The single NIT (#1, lagging docstring) does not block; if TL wants it tightened, it's a one-line edit, not a returned-for-rework class of change.

Out-of-scope item I observed and confirmed already queued — eurooptic's Playwright `page.goto(timeout=45_000)` vs default cap 45s collision (backlog #14, "Adapter writers should declare `search_timeout_seconds = 50`"). Worker's HANDOFF flagged it; TL already accepted as backlog. No re-litigation here.

## Verification record

| Check | Result |
|-------|--------|
| `git diff master..feat/... --stat` | 3 files, +340/-2 — matches TASK `## Files` exactly |
| `pytest tests/test_inventory_runtime_timeout.py -v` | 7 passed in 0.73s |
| `make services-test` | 283 passed, 1 skipped in 21.65s (pre-existing skip) |
| Smoke `_store_run_timeout(_Default())` | 45.0 |
| Smoke `_store_run_timeout(_Slow())` | 190.0 |
| `grep -rn "_RUN_STORE_TIMEOUT_SECONDS" sitka-services/ --include="*.py"` | Only intra-module + tests + 1 comment in `base.py`; no external imports of old name |
| `grep "search_timeout_seconds" adapters/stores/*.py` | Only `amazon.py` — confirms Worker audit claim |
| TASK A commit (`8f1d5c4`), TASK B/PR #91 (`89a6c25`) | Both present in `git log --oneline master` |
| `.github/workflows/ci.yml` `pytest-asyncio>=0.26,<0.27` pin | Intact at line 248 |
| Forbidden surfaces (sitka-core, avito, prod compose, deploy, scripts, .github) | Empty diff |
| Amazon `search_timeout_seconds = 180` at line 34 | Preserved |
| `title_matches` body in `base.py` | Untouched |
| `_PRODUCT_CHECK_TIMEOUT_SECONDS`, `_RUN_MANY_CONCURRENCY` | Untouched |

## Artifacts

- branch:               feat/inventory-parser-fork-task-c-amazon-timeout
- commit(s):            c8f039f
- PR:                   not yet opened (Worker does not push per TASK)
- tests:                target file 7/7 green; full services suite 283 passed + 1 skipped (skip is pre-existing, not introduced)
- Product repo status:  not applicable (Reviewer made no code changes — Read/Grep/Bash only)

## Conflicts / risks

None blocking. Two non-blocking observations already covered in NITS (#1 docstring lag, #2 getattr-default duplicates class default — both acceptable belt-and-braces).

Worker's own HANDOFF flagged the eurooptic Playwright collision as a separate P1 — TL has already queued it (backlog #14). Confirmed out-of-scope; not re-litigated here per Reviewer prompt.

## Next step

TL: `make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/2026-05-28-reviewer-to-tl-inventory-parser-fork-task-c-amazon-timeout.md` to close this review HANDOFF, then `make accept-task` (TASK status is already `review` per Worker), then open PR against master and merge after CI green. Post-merge prod smoke per TASK acceptance bullet 7.
