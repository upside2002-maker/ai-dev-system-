# HANDOFF: reviewer → tl — inventory-parser-fork-task-b-title-matches

- Status: closed
- Date: 2026-05-27 18:46
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-b-title-matches.md

## ARTIFACT

- TASK: `project-overlays/sitka-office/TASKS/2026-05-27-inventory-parser-fork-task-b-title-matches.md`
- Branch: `feat/inventory-parser-fork-task-b-title-matches` (local, not pushed)
- Commit: `7d627b2` (single commit from master `8f1d5c4`)
- Files (4): `sitka-services/app/inventory/adapters/base.py`, `sitka-services/requirements.txt`, `sitka-services/tests/test_inventory_title_matches.py`, `sitka-services/tests/test_inventory_title_matches_property.py` (+437 / −48)
- Worker HANDOFF: `project-overlays/sitka-office/HANDOFFS/2026-05-27-worker-to-tl-inventory-parser-fork-task-b-title-matches.md`

## SUMMARY

**ACCEPT.** Change matches TASK acceptance: `title_matches` simplified to a pure token-presence check (substring + GTX special-case both removed), backed by 22 example tests + 2 hypothesis property tests (200 examples each), all green; full `make services-test` 276/276 + 1 skipped (TASK A baseline 265+1, delta +11 as claimed); diff scope clean (exactly the 4 expected files, none of the forbidden zones touched); smoke `parse_query('blizzard aerolite parka')` vs title `"Sitka Men's Blizzard AeroLite Bib Parka"` returns `True` (was `False` before fix); GTX equivalence re-verified through `_TOKEN_EQUIVALENTS` at `_sitka_catalog.py:331-334` so the special-case drop is safe. No blockers.

## FINDINGS

(No critical / high. Two low-severity observations + one nit, none of them block ACCEPT.)

**low-1 — HANDOFF claim "~45% draws hit True branch" in soundness property is overstated.**

Worker HANDOFF (line 73) states for the soundness property "~45% draws попадают в True-ветку". When I re-ran the same generators with `max_examples=500`, the actual ratio is ~13.4% (67 True / 433 False). The property is **still non-vacuous** — 13% of 200 examples is ~26 True-branch assertions per run, well above zero — but the documented figure is wrong and could mislead a future reader who relies on it without re-checking. File: `tests/test_inventory_title_matches_property.py` lines 210-238. Not a code defect; a HANDOFF-documentation accuracy item. Falls under Correction 010 spirit (numbers should come from a measurement, not memory).

**low-2 — `_arbitrary_title` strategy uses the same `_filler_strategy` which itself filters via `_is_clean_token`.**

Because fillers pass through the same reserved-token / color filter, "arbitrary" titles will rarely contain query tokens by chance with 5-10 char tokens. This is what gives the modest True-ratio above. The property still passes because hypothesis biases generation through shrinking / coverage, but if someone later swaps `_filler_strategy` for an even more constrained generator, the True branch could become genuinely vacuous without test failure. Adding a hypothesis statistics or coverage assertion (`event()`) would lock the non-vacuity contract explicitly. Not blocking — current 13% is comfortably above zero and the completeness property is unaffected.

## MISSING

- Nothing TASK-critical. Acceptance bullets 1-7 all satisfied:
  - [✓] `title_matches` simplified to 2 lines + invariant-preserving comment block (base.py:452-470 → simplified body at base.py:468-472).
  - [✓] Example tests extended 13 → 22, broad / target observationally identical pinned, GTX block added.
  - [✓] Property test file created, 2 functions, `@settings(max_examples=200)` explicit on both.
  - [✓] Target file pytest: 24 passed in 34.21s (22 example + 2 property).
  - [✓] `make services-test`: 276 passed + 1 skipped in 34.07s (skip is pre-existing `test_core_client.py` flake, see Backlog #12).
  - [✓] Smoke (concrete-subclass form): `SMOKE: True`. Literal TASK form fails on Python 3.12 ABC — see SCOPE CREEP below.
  - [⏳] CI yet to run — branch is unpushed per WORKER protocol. Will exercise when TL pushes.

## SCOPE CREEP

**None from Worker.** Diff includes exactly the 4 expected files. Forbidden zones all clean:

- `sitka-services/app/inventory/query.py` — untouched
- `sitka-services/app/inventory/runtime/service.py` — untouched
- `sitka-services/app/inventory/adapters/stores/*.py` — untouched
- `sitka-services/app/inventory/_sitka_catalog.py` — untouched
- `sitka-core/`, migrations, `third_party/`, avito vendor — untouched
- `.github/workflows/ci.yml` — untouched (hypothesis flows in via requirements.txt as planned; pytest-asyncio<0.27 pin from TASK A still at line 248)

**TASK-side artifact (not Worker's fault, but TL should address before next similar TASK):** the literal smoke command in TASK acceptance bullet 6 cannot run as-written on Python 3.12 — `BaseStoreAdapter.__new__(BaseStoreAdapter)` raises `TypeError: Can't instantiate abstract class BaseStoreAdapter without an implementation for abstract methods 'check_product', 'search'`. Worker handled this correctly by running the smoke through a minimal concrete subclass (same shape as the `_TestAdapter` in both test files), recording the deviation in HANDOFF §Conflicts/risks p.1, and the test files themselves already pin the same call. Recommend TL edit the TASK bullet 6 (post-accept) or note the form-deviation as accepted, per Worker's offer in HANDOFF.

## NITS

- `requirements.txt` line 22 pin `hypothesis>=6,<7` — good loose pin, generous range. If `hypothesis-6.153.6` is what `pip install -r` resolves today and we want install reproducibility, consider locking exact in a follow-up; not blocking.
- Property test docstrings (lines 38-40) say "Each property runs the hypothesis default of 100 examples" but the actual code overrides this to 200 via `@settings(max_examples=200, …)` on both functions. The text in the docstring should say 200, not 100. Cosmetic only.
- `test_inventory_title_matches_property.py:91` `_ADAPTER = _TestAdapter()` is a module-level instantiation while the other file uses a `@pytest.fixture(scope="module")` for the same thing. Different style but functionally equivalent here. Not worth a churn.
- HANDOFF `Conflicts/risks` p.3 explains the drive-by `normalize_text` import removal. Verified: only `BaseStoreAdapter` (and `FetchResult`) are imported from `adapters/base` across the codebase (`grep "from app.inventory.adapters.base import"` shows 11 consumers, none take `normalize_text`). Removal is safe.

## RECOMMEND

**ACCEPT** the HANDOFF. TL can proceed to push branch + open PR + run CI + Reviewer-of-PR-side smoke after deploy (per usual lifecycle).

Findings classification:
- **low-1** (HANDOFF "~45%" inaccuracy) — fix on the way out if TL is editing the HANDOFF anyway during accept; otherwise OK to leave as a one-off note. Not worth a follow-up TASK.
- **low-2** (filler strategy overlap making True-ratio modest) — DEFER. Property still passes 200 examples and exercises both branches at ~13%. If a future TASK touches the property tests, consider adding an `event("title_matches_true")` to lock the non-vacuity invariant explicitly.
- **NITS** — docstring "100 examples" → "200 examples" can be fixed during a future drive-by on this file; not worth holding ACCEPT.
- **TASK-side smoke literal** — TL discretion. Suggest fixing the TASK bullet 6 to use a concrete subclass form OR accept the deviation as documented in Worker HANDOFF.

Architectural / correctness re-verification:

- **Correction 001 (no domain decisions in integration layer):** new `title_matches` is purer than before — just a count comparison. No business logic added. PASS.
- **Correction 010 (no PR numbers from memory):** commit message refers to "PR #89 (master `ccac24b`)" — verified against `git log --oneline master | head -8`: `ccac24b fix(parser): two-word queries enter broad mode (no substring drop) (#89)`. Also "TASK A (master `8f1d5c4`)" — verified `8f1d5c4 refactor(inventory): форк vendor/inventory_parser в app/inventory/ + тесты + CI cleanup (#90)`. Both correct. PASS.
- **CLAUDE.md "Drive-by фиксы" rule:** Worker noted the `normalize_text` unused-import removal in HANDOFF §Conflicts/risks p.3 with explicit reasoning. Could argue this should have been a pre-flight callout per the rule's strict reading, but in this case the import drop is a *direct mechanical consequence* of the requested simplification (any linter would catch it), and Worker explicitly flagged it. Acceptable.
- **GTX equivalence safety claim (Worker §Conflicts/risks p.2):** verified by reading `_sitka_catalog.py:331-334` (`_TOKEN_EQUIVALENTS["gtx"] = ("gtx", "goretex", "gore-tex", "gore", "tex")`) AND `_sitka_catalog.py:498-500` (`canonical_product_tokens` rewrites title-side `gore-tex` / `gore tex` / `goretex` → `gtx`) AND `query.py:73-81` (`match_query_tokens` checks each variant via `variant in normalized_text` OR `variant in text_tokens`). Live smoke `parse_query('sitka blizzard gtx')` vs `"Sitka Blizzard Gore-Tex Glove"` → `True`. PASS.

## Artifacts

- branch:               `feat/inventory-parser-fork-task-b-title-matches` (local, awaiting TL push)
- commit(s):            `7d627b2`
- PR:                   none yet (created post-ACCEPT by TL)
- tests:                target files 24/24 green (22 example + 2 property × 200 examples); full `make services-test` 276 passed + 1 skipped (delta +11 vs TASK A baseline as claimed)
- Product repo status:  committed

## Conflicts / risks

None blocking ACCEPT. Two low-severity observations + nits documented in FINDINGS / NITS above. TASK-side smoke literal (Python 3.12 ABC) is a docs-side issue, not a code defect — Worker handled correctly.

## Next step

TL: read this report, classify the two low findings (suggest both can be left as-is or fixed on the way out), then proceed with the standard accept-handoff → push branch → open PR → Reviewer-of-PR (if Mode demands a second pass — Mode is `normal` so PR-side review is optional) → merge → deploy → smoke-on-prod (recommended: re-run the 3-token smoke against a real Sitka catalog item that was previously failing).
