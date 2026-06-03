# HANDOFF: reviewer → tl — parser-improvement-p0-2-variant-level-stock

- Status: closed
- Date: 2026-06-02 19:12
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-2-variant-level-stock.md

## Summary

**ACCEPT.** Mode strict bar met: explicit acceptance contract reproduced 1:1
(9 new fields with exact types/defaults from TASK, `in_stock` behavioural
flip from product-level to variant-level), 4 files exactly per modify-list,
no forbidden-zone drift, no regressions (309 passed / 1 skipped — matches
P0-1 baseline + 11 net new green tests). Live smoke against Equinox Guard
Pant Lead 36R @ eurooptic reproduces the bug end-to-end: parsed
`size='36' color='lead'`, adapter returns `available_sizes=('42R','44R')`
for the Lead variant, matcher returns
`(matched_cell=None, variant_status='out_of_stock')` — exactly the F-WIRE-1
fix intended. No critical or high-severity findings.

## Done

<!-- Reviewer didn't "do" work in the implementation sense; below is what was
     verified during this review pass. -->

- **Diff scope verified** (`git diff feat/parser-improvement-p0-1-failsafe-orchestrator..feat/parser-improvement-p0-2-variant-level-stock --stat`):
  exactly 4 files, +575/-2.
  - `sitka-services/app/inventory/variant_match.py` (new, +147)
  - `sitka-services/app/routes/parsing.py` (+88/-2)
  - `sitka-services/tests/test_inventory_smoke.py` (+96)
  - `sitka-services/tests/test_inventory_variant_match.py` (new, +246)
- **No forbidden-zone drift.** Read the file list end-to-end against the TASK
  "Do not touch" list — clean on every forbidden path:
  no `runtime/service.py`, no `query.py` body change (only imported),
  no `adapters/base.py`, no store files, no `_sitka_catalog.py`,
  no `vendor/avito_parser/`, no `sitka-core/`, no `sitka-web/`,
  no `migrations/`, no `prod.yml` / `auto-deploy.sh`,
  no CI workflow change (`.github/workflows/ci.yml:248` still has
  `pytest-asyncio>=0.26,<0.27` pin).
- **Tests run locally — matches HANDOFF numbers exactly.**
  - Target: `.venv/bin/python -m pytest tests/test_inventory_variant_match.py
    tests/test_inventory_smoke.py -v` → 16 passed in 2.16s
    (10 variant_match + 6 smoke = 5 baseline + 1 new TDD case).
  - Full suite: `make services-test` → **309 passed / 1 skipped in 80.34s**.
    P0-1 baseline was 298+1, so +11 net new green tests (10 in
    test_inventory_variant_match.py + 1 in test_inventory_smoke.py).
    Zero regressions.
- **`OfferCandidate` acceptance contract verified** at
  `sitka-services/app/routes/parsing.py:52–99`. All 9 new fields present
  with exact types/defaults from TASK header:
  - `actual_color: str | None = None` (L85) ✓
  - `actual_size: str | None = None` (L86) ✓
  - `variant_status: Literal["in_stock","out_of_stock","backorder","preorder","unknown"] = "unknown"` (L87–89) ✓
  - `variant_sku: str | None = None` (L90) ✓
  - `variant_url: str | None = None` (L91) ✓
  - `available_sizes: list[str] = []` (L96) ✓
  - `unavailable_sizes: list[str] = []` (L97) ✓
  - `available_colors: list[str] = []` (L98) ✓
  - `unavailable_colors: list[str] = []` (L99) ✓
  Old shape preserved (L72–80): `store / title / url / status / price_text /
  price_usd / in_stock / added_to_core / skip_reason`. Backwards-compat check
  ran live: a payload with only the legacy fields (no `variant_status`, etc.)
  validates and the new fields take their defaults.
- **`in_stock` behavioural flip wired correctly** at `parsing.py:282`:
  `in_stock=(variant_status == "in_stock")`. Comment block on L278–281
  explicitly flags the user-visible P0-2 change. Acceptance row matches.
- **`match_variant` is pure.** `app/inventory/variant_match.py` imports only
  `Literal` from `typing`, `match_color`/`match_size` from `app.inventory.query`,
  and `ParsedQuery`/`VariantCell` from `app.inventory.types`. No DB call, no
  HTTP, no `_sitka_catalog` body access, no pricing/business logic.
  Correction 001 (domain leak) not violated. Decision tree is reasonable:
  empty matrix → `unknown` (L113); no constraints → first available cell
  with `_cell_status` (L118–123); constrained → filter then prefer
  in-stock > backorder/preorder > out-of-stock (L130–147). `_cell_status`
  (L44–80) layers `cell.available` → `cell.availability` canonical code →
  `cell.note` text patterns, in that order. The note patterns
  (`"bo "`, `"backorder"`, `"preorder"`, `"pre-order"`) align with the
  Shopify family annotation conventions actually used by `shopify_support`.
- **Tests are real, not tautological.** Read `test_inventory_variant_match.py`
  in full (246 LOC):
  - `test_failing_first_ventlite_size_11_out_of_stock` (L66–81) — the TDD
    red→green case. Fixture has `size="13"`, query is `"...11 Olive Green"`,
    expected `(cell=None, status="out_of_stock")`. Pre-matcher mapper would
    have surfaced `in_stock=True` (the bug shape). Pins it deterministically.
  - `test_color_mismatch_returns_out_of_stock` (L234–246) — explicitly checks
    matcher doesn't confuse colours (Subalpine cell available, but query
    asks for "Optifade Elevated II") — exactly the Drifter Duffle EV2 case
    from ТЗ. Asserts `(None, "out_of_stock")`.
  - All 10 unit cases cover TASK Acceptance minimum 6: exact match (1),
    size-only (3), colour-only (4), no-constraints (5), empty matrix (6),
    backorder via note (7), backorder via BO format (8), preorder (9),
    colour mismatch (10). Plus the failing-test-first (2).
  Smoke `test_p0_2_route_mapper_variant_out_of_stock_for_requested_size`
  (test_inventory_smoke.py:237–309) is end-to-end: synthesises an `ItemResult`
  with product-level `status="in_stock"` (the pre-fix data shape), runs the
  matcher, builds an `OfferCandidate`, asserts `candidate.in_stock is False`
  and `candidate.variant_status == "out_of_stock"`. That nails the wire
  contract, not just the matcher in isolation.
- **Live smoke reproduced — one ТЗ case picked.** Worker chose Equinox Lead
  36R @ eurooptic. Reviewer reproduced same case live (dev,
  `SITKA_APIFY_TOKENS=dummy SITKA_APIFY_TOKEN=dummy`):
  - Query: `Sitka Equinox Guard Pant Lead 36R`
  - `parse_query` → `size='36' color='lead'`
  - eurooptic adapter returned 4 items, all `status="variant_not_found"`,
    each with non-empty `variant_cells` (4–5 cells per product)
  - First item (Lead 50247-PB): `available_sizes=('42R','44R')`,
    `available_colors=('Lead',)`, no 36R in matrix
  - Matcher: `(matched_cell=None, variant_status="out_of_stock")` ✓
  This is the F-WIRE-1 fix in action — pre-P0-2, the mapper would have used
  product-level `status` and the frontend would have seen "available"; post-P0-2
  the operator gets the variant-level truth.
- **Adapter `variant_cells` fill claim sanity-checked.** Did NOT re-audit all
  22 adapters but spot-checked 3 different families:
  - `app/inventory/adapters/families/shopify_support.py:601` —
    `variant_cells=availability.variant_cells` (covers lancaster, badass,
    gohunt, jamesriver, etc.)
  - `app/inventory/adapters/families/bigcommerce_support.py:636` —
    `variant_cells=variant_availability.variant_cells` (covers gritr,
    linton, vandam)
  - `app/inventory/adapters/stores/eurooptic.py:1004,1208` —
    direct `variant_cells=availability.variant_cells` on both code paths
  Live eurooptic call above confirms 4–5 non-empty cells per product on
  Lead variant pages, so the wiring is real, not stubbed. Worker's
  conclusion ("no backlog item needed for adapter fill-rate") holds for
  the spot-checked families.
- **No PR opened.** `gh pr list --search "head:feat/parser-improvement-p0-2"`
  returns empty (per Owner directive: Actions frozen).

## Remaining

- Nothing the Reviewer is holding open. Worker's known follow-ups
  (frontend variant-fields consumer, `variant_url` deep-link via adapters,
  adapter quality audit if/when discrepancies are spotted on stores
  Reviewer did not live-test) are correctly tracked as separate-TASK items
  per HANDOFF — none of them block accept-handoff for P0-2.

## Artifacts

- branch:               `feat/parser-improvement-p0-2-variant-level-stock`
                         (off `feat/parser-improvement-p0-1-failsafe-orchestrator`, NOT off master — cascading branch strategy)
- commit(s):            `a5364ec` (single commit on top of P0-1 base; verified
                         via `git log feat/parser-improvement-p0-1-failsafe-orchestrator..HEAD`)
- PR:                   none — Actions frozen per Owner 2026-06-02;
                         branch pushed to origin as backup, no PR opened
                         (`gh pr list` empty for this head)
- tests:                309 passed / 1 skipped (full `make services-test`,
                         reproduced locally on Reviewer machine in 80.34s);
                         16 passed on target subset
                         (`test_inventory_variant_match.py` + smoke);
                         +11 net new green vs P0-1 baseline (298+1);
                         0 regressions in `test_routes_http.py` or any other module
- Product repo status:  committed

## Conflicts / risks

No critical or high-severity findings. The risks below are **medium / low**
and all acknowledged in the Worker HANDOFF or in the TASK Mode strict header —
Reviewer flags them so TL has them on the record, not to block accept.

### MEDIUM (already approved by TL in TASK header — Mode strict acknowledgment)

- **API contract change to `OfferCandidate.in_stock` semantics is shipping
  blind to downstream consumers.** Pre-P0-2, `in_stock = (status ==
  "in_stock")` where `status` was product-level; post-P0-2 it's variant-level.
  Downstream frontend (`sitka-web/`) is **explicitly out of scope** by TASK
  directive — Reviewer did **not** audit it (per TL instruction in the
  Reviewer prompt: "do NOT relitigate; do NOT mark as blocker"). The change
  is in the safe direction (frontend will see *fewer* false positives, not
  more), and TASK header has `Critical approved by: TL Sitka` + Acceptance
  bullet "in_stock теперь = `(variant_status == "in_stock")` (поведенческое
  изменение в нужную сторону)". Frontend consumer audit if needed → separate
  future TASK.

### LOW (acknowledged risks, design-level decisions, not blockers)

- **`variant_url` is always `None`** (parsing.py L269). Worker notes
  `VariantCell` does not carry its own URL — adapters surface product URL only.
  Shopify variants in particular have a deep-link shape (`?variant=<id>`) but
  the matcher has no place to construct it without adapter-side changes,
  which TASK explicitly forbids. Field is wire-ready for a future
  adapter-level fix. Not a blocker — field is nullable per TASK contract.

- **`getattr(item, "variant_cells", ()) or ()`** at `parsing.py:255,289–292`
  is a test-fixture compatibility shim — masks `AttributeError` on stub items
  that don't carry variant axes. Worker explicitly justifies this in the
  HANDOFF: `test_routes_http.py` mocks `run.items` as bare `SimpleNamespace`
  without variant fields, and without the `getattr` fallback those tests
  would 500. In production every `ItemResult` is a frozen dataclass that
  ALWAYS has these fields (their dataclass default is `()`), so the fallback
  branch is unreachable on real data. Reviewer-verified the dataclass
  defaults at `app/inventory/types.py:80–86` (all four `available_*` /
  `unavailable_*` and `variant_cells` default to `()`). Risk of masking a
  real missing-field bug in production: nil. Accept as test-shim.

- **First-available fallback on no-constraint queries** at
  `variant_match.py:118–123`: if the query has no size and no colour,
  matcher returns the first in-stock cell (or first overall) plus its
  derived status. This is opinionated — the alternative would be to return
  `(None, "unknown")` to force the operator to specify. TASK is lenient on
  this case ("query has neither size nor color → 'unknown' or first
  available is acceptable"), and Worker chose the more helpful behaviour.
  Acceptable for current scope; if Owner later wants a stricter contract
  (no opportunistic match), that's a one-line change.

- **`variant_sku` value may be operator-useless** on some adapters that
  populate `cell.sku` with an internal variant key, not a real human SKU.
  Worker flags this in HANDOFF Conflicts. Not a blocker — field is
  nullable, and surfacing it as `None` instead of a useless internal key
  would just be a quality-of-life adapter-level cleanup, again out of scope
  here.

### Not blockers, observed for completeness

- **Worker references no PR # in commit message** (the commit message is
  free-text, no `(#NN)` suffix). Correction 010 not violated.
- **HANDOFF references one PR via short hash** in body but uses none in
  Done/Artifacts — Evidence rule (Correction 010) holds.
- **CLAUDE.md anti-confabulation check:** Worker's HANDOFF claims
  "All 5 adapter families... variant_cells fill correctly" with
  specific file paths and line numbers (eurooptic L989/L1193,
  shopify_support, bigcommerce_support). Spot-checked the citations
  via `grep variant_cells=` — line numbers are off by tens to hundreds
  (actual: eurooptic.py:1004, 1208; shopify_support.py:601;
  bigcommerce_support.py:636), but the *content* of the citations is
  correct — every cited adapter does in fact wire `variant_cells`.
  Worker likely cited from memory of an earlier read; the substantive
  claim holds, only the line numbers drift. Low severity — would have
  been a finding under stricter Evidence rule, but the conclusion is
  right. Worth noting for global-corrections (line-number freshness)
  rather than blocking this TASK.

## Next step

TL runs `make accept-handoff` on this file once read, then `make
accept-task` on the TASK. Per TL plan from the prompt:
P0-3 (env paths) is the next TASK on deck. No new TASK needs to be
created from this Review — every flagged risk is either already in
TASK header approval, already in Worker HANDOFF Conflicts, or a
known-acceptable design choice. Frontend consumer audit
(`sitka-web/`) is the only follow-up worth tracking as a candidate
future TASK; whether it actually needs one depends on TL/Owner
deciding to surface variant info to the UI.
