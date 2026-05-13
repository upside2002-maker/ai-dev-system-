# HANDOFF: worker → tl — transit-render-provenance-sot

- Status: closed
- Date: 2026-05-13 10:49
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-transit-render-provenance-sot.md

## Summary

TASK 1 (Phase 1 of Transit Section Recovery) **COMPLETED**. Closed root cause #1 from `transit-section-program-2026-05-13.md` § 3: each PDF render now produces a sibling `<output>.pdf.provenance.json` sidecar with 13 metadata keys (git SHA, repo/worktree root, render-script path, source-facts path+hash, input-fixture path+hash, mode, core-CLI path+hash, timestamp). Canonical render entry point for Наталья is `services/api-python/scripts/render_natalya.py`. Tests 94/94 green (85 baseline + 9 new). Single commit, pushed to backup, parity verified.

## Done

Per-file overview of single commit `9793d5d`:

* **`services/api-python/app/pdf/provenance.py`** (new, 326 lines) — `@dataclass(frozen=True) RenderProvenance` + `collect_provenance(...)` + `write_sidecar(...)`. Exposes `REQUIRED_SIDECAR_KEYS = frozenset({13 keys})` for test consumption. Git SHA / branch detected via `git -C <repo> rev-parse`. Best-effort: no git → keys are `None`, no crash. SHA-256 on facts file, input fixture, and core CLI binary (recompute mode only). Module-level docstring cites architecture § 4.5 + bright lines #2/#6.
* **`services/api-python/app/pdf/builder.py`** (modify, +34 / -4 lines) — new optional `provenance: RenderProvenance | None = None` arg on both `render_solar_html` and `write_solar_pdf`. When supplied: builder passes `provenance_meta = provenance.to_dict()` into Jinja and calls `write_sidecar(provenance, output_path)` after PDF write. Existing callers (main.py `/pdf`, `test_draft.py`) pass nothing — zero behaviour change for client-facing renders.
* **`services/api-python/app/pdf/templates/solar.html.j2`** (modify, +15 lines) — opt-in debug footer inside `.last-page` section, guarded by `{% if provenance_meta and provenance_meta.debug_mode %}`. Renders 4 lines of monospace metadata at 8pt + dashed top border. **Default render is unchanged** — block skipped entirely when `debug_mode=False`. ≤ 20 lines per TASK constraint.
* **`services/api-python/scripts/render_natalya.py`** (new, 263 lines, executable) — canonical entry point with module-level README docstring. Argparse: `--output PATH` (required), `--mode {fixture-render,recompute}` (default fixture-render), `--facts PATH` (default `08-natalya-2025-2026.expected.json`), `--input PATH` (default `08-natalya-2025-2026.input.json`), `--debug` (default off). Recompute path goes through existing `app.core_client.run_core_analysis` (one snapshot, bright line #6). Person/consultation stub synthesised from `input.json`'s `birth` block — minimal shape matching what template reads.
* **`services/api-python/tests/test_provenance.py`** (new, 9 tests, 271 lines):
  * `test_collect_provenance_fixture_render_mode_has_all_required_keys` — all 13 keys present, `core_cli_*` may be None.
  * `test_collect_provenance_recomputed_mode_hashes_core_cli` — core CLI binary hashed; input fixture path+hash populated.
  * `test_collect_provenance_facts_hash_is_stable` — identical bytes → identical hash (reproducibility primitive).
  * `test_write_sidecar_produces_loadable_json` — sidecar location convention, valid JSON, contains all required keys.
  * `test_write_solar_pdf_without_provenance_skips_sidecar` — guards client-deliverable contract.
  * `test_write_solar_pdf_with_provenance_writes_sidecar` — full integration smoke against case-8 facts.
  * `test_debug_footer_hidden_by_default` — sentinel grep on default HTML.
  * `test_debug_footer_visible_when_flag_set` — sentinel grep on debug HTML.
  * `test_sidecar_alone_can_reconstruct_source_of_truth` — Architecture § 6 verifiability claim.

Smoke render outputs (forensic-verifiable):

* `/tmp/natalya-render-phase1-smoke.pdf` (136 622 bytes, 18 pages) + `/tmp/natalya-render-phase1-smoke.pdf.provenance.json` (1 526 bytes). Default `--mode fixture-render --debug off`. PDF text-extract confirms **no debug-footer leak** ("render: fixture-render" not in extracted text; "claude/dreamy-moore-46f5eb" not in extracted text).
* `/tmp/natalya-render-phase1-smoke-debug.pdf` + sidecar — same with `--debug`. PDF text-extract confirms footer present ("render: fixture-render" found; SHA "68947433" found; branch "claude/dreamy-moore-46f5eb" found).

## Provenance shape (sidecar example)

Reference: `/tmp/natalya-render-phase1-smoke.pdf.provenance.json` (real, just produced).

```json
{
  "core_cli_path": null,
  "core_cli_sha": null,
  "debug_mode": false,
  "extra": {
    "case_label": "08-natalya-2025-2026",
    "cli_args": {
      "debug": false,
      "facts": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json",
      "input": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/packages/test-fixtures/golden-cases/08-natalya-2025-2026.input.json",
      "mode": "fixture-render",
      "output": "/private/tmp/natalya-render-phase1-smoke.pdf"
    }
  },
  "git_sha": "68947433ff7a24177edf1a65e3f0c9f63f773ba6",
  "git_sha_short": "68947433ff7a",
  "input_fixture_hash": "af0be12d079a395592c35e0d3d4e008054d784a181a342a3c45084dbe3ce7e15",
  "input_fixture_path": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/packages/test-fixtures/golden-cases/08-natalya-2025-2026.input.json",
  "mode": "fixture-render",
  "render_script_path": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/services/api-python/scripts/render_natalya.py",
  "repo_root_path": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb",
  "source_facts_hash": "48e6ae12b51ea50954714fafa63d8e4012b85770ec792ba49bc70e5d06eb5993",
  "source_facts_path": "/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json",
  "timestamp_utc": "2026-05-13T15:48:06Z",
  "worktree_branch": "claude/dreamy-moore-46f5eb"
}
```

Note: smoke PDF on this branch reports `git_sha=68947433` (= HEAD before this commit). New PDFs rendered post-commit will show `9793d5d…`. The `git_sha` field is intentionally captured at render-time, not at commit-time.

Decision rationale **single commit** vs `≤ 2`: chose single because the canonical render script imports the provenance module immediately; splitting them would land an unused module in commit-1 (awkward to bisect / review) without product value, and the template footer and builder integration are tightly coupled to the new dataclass shape. All five files are one coherent Phase 1 SoT change.

## Worktree drift report + recommendation

Drift summary: **`claude/dreamy-moore-46f5eb` is +7 commits over `main`** after this TASK (was +6 before). Cumulative diff `main..claude/dreamy-moore-46f5eb --stat`: **31 files changed, +550 298 / -88 503**, dominated by `packages/test-fixtures/golden-cases/*.input.json` and `*.expected.json` regenerations from Tier A cascade (`5f4fbc9`).

Commits on `claude/dreamy-moore-46f5eb` over `main`:

```
9793d5d  feat(pdf): render provenance SoT + canonical Natalya entry point (Phase 1)  ← this TASK
6894743  tune(pdf): monthly transit table = house at calendar mid-month (Marina parity)
dec0f5d  tune(pdf): tighten quincunx (150°) display orb in transit calendar
9f47f45  fix(pdf): rebuild Transits section to Marina format (engine kept)
2e4c394  tune(core+fixtures): per-planet transit orb calibration from Marina case-8 empirical
3a12ed3  tune(core+fixtures): tighten transit orb thresholds to Marina-implied values
5f4fbc9  fix(core+services+contracts): transit engine orb-window + quincunx + cross-year [Tier A cascade]
```

Files diverged (top-level groups):
* `core/astrology-hs/src/Domain/TransitCalendar.hs` (+352 lines) + spec.
* `packages/contracts/solar-computed-facts.schema.json` (+15 lines — schema cascade fields).
* `packages/rulesets/daragan-orbs-v1.json` (+14 lines — per-planet orbs).
* `packages/test-fixtures/golden-cases/*.input.json` + `*.expected.json` — 9 of 10 cases regenerated post-Tier-A.
* `services/api-python/app/pdf/builder.py`, `solar.html.j2`, `transit_themes.py`, `ephemeris/bridge.py`.
* `services/api-python/tests/test_contracts.py`, `test_transit_aspects_tables.py`.
* `apps/web-react/src/types.ts` (+7 lines — TS contract cascade).
* `.claude/corrections.md` (+30 lines — Correction 009 Quincunx scoped revoke).
* **New on this TASK only:** `services/api-python/app/pdf/provenance.py`, `scripts/render_natalya.py`, `tests/test_provenance.py`.

Backup parity:
* `local claude/dreamy-moore-46f5eb` = `9793d5d` = `backup/claude/dreamy-moore-46f5eb` (`SHA verified`).
* `local main` = `7b8fd24` = `backup/main` (origin parity intact, no fast-forward pending was needed for this TASK).

**Recommendation: MERGE `claude/dreamy-moore-46f5eb` → `main` via fast-forward.** Arguments:

1. **No conflicts** — `claude/dreamy-moore-46f5eb` is a strict fast-forward of `main` (`main..claude/dreamy-moore-46f5eb` has 7 commits, `claude/dreamy-moore-46f5eb..main` is empty; verified via `git log claude/dreamy-moore-46f5eb..main --oneline | wc -l → 0`).
2. **Architecture § 5 Phase 1 + § 7 explicitly forbids holding both as equal sources of PDF** ("Не держать одновременно main и worktree как равноправные источники PDF"). Until this is collapsed, the Phase 1 promise of single SoT is structural-only, not operational.
3. **Engine work is complete & accepted** — the 6 prior commits include the Tier A cascade (`5f4fbc9` was accepted 2026-05-11), per-planet orb calibration (`2e4c394`, accepted), and Marina-format transits rebuild (`9f47f45`–`6894743`, accepted as Tier C presentation, even if the broader Phase 1 of this new program reopens transit-section work).
4. **Cost of NOT merging** — every new PDF render on `claude/dreamy-moore-46f5eb` will continue to show `worktree_branch: claude/dreamy-moore-46f5eb` in the sidecar, which is unambiguous but invites another "shadow main" scenario as work expands.

**Cherry-pick alternative discouraged** — the 31-file diff is dense, fixtures and schema regenerations are interdependent, and `5f4fbc9` was already a Tier A cascade with its own schema-gate compliance. Decomposing it later would risk re-introducing exactly the drift this TASK closes.

**Discard discouraged** — would lose Tier A engine work + Tier C presentation rebuild + this Phase 1 chassis.

**Decision is the user's** per TASK § Do not touch (`Decision по merge ... → main — Worker НЕ решает молча`). Worker has **not** executed any merge / push to main / cherry-pick. Mechanics, when authorised:

```
cd /Users/ilya/Projects/astro
git fetch backup
git checkout main
git merge --ff-only claude/dreamy-moore-46f5eb         # ff is clean — verified
git push backup main                                    # backup parity
# (origin push only if/when origin is set; backup is canonical here)
```

After merge, the `.claude/worktrees/dreamy-moore-46f5eb/` directory under `/Users/ilya/Projects/astro/` is orphaned. **Worker does not remove it** in this TASK — that's the user's call. It will appear as `?? .claude/worktrees/` in `git status` of main repo forever until pruned via `git worktree remove`, which is documented as a "known artifact" in this TASK Acceptance.

## `/tmp/render_*.py` — forensic / non-SoT artifacts (NOT cleaned up)

Listed per TASK § Files **"`/tmp` harness scripts policy"** — Worker enumerates, does not delete:

```
/tmp/render_natalya_2ffa002.py
/tmp/render_natalya_glyphswap.py
/tmp/render_natalya_glyphswap_9d452dd.py
/tmp/render_natalya_monthstart.py
/tmp/render_natalya_quincunx_filter.py
```

5 files, all created during prior iterations 2026-05-10..12 (commit-name suffixes correlate to commits `2ffa002`, `9d452dd`, `6894743 monthstart`, `dec0f5d quincunx_filter`). Each was a one-off harness that bound a temporary `expected.json` to a temporary render. None are under version control; none import from the new `scripts/render_natalya.py`. They remain on disk as audit evidence for the iterations they served. Future renders **must** use `services/api-python/scripts/render_natalya.py`.

## `git grep` results — alternative render entry points inside repo

Searched `*.py` `*.sh` `*.j2` for `write_solar_pdf | render_solar_html | HTML(string= | render_natalya | render_solar | Наталь`. Findings:

* `services/api-python/app/pdf/builder.py` — canonical builder. **Kept.**
* `services/api-python/app/pdf/__init__.py` — re-exports `render_solar_html`/`write_solar_pdf`. **Kept.**
* `services/api-python/app/main.py:469` — `/pdf` FastAPI endpoint. **Kept** (production path; uses builder without provenance arg → client deliverable contract preserved).
* `services/api-python/tests/test_draft.py:638` — test of `render_solar_html` for skeleton-override smoke. **Kept** (legitimate test usage).
* `services/api-python/scripts/render_natalya.py` — new canonical script. **Added.**

**No deprecated harness scripts inside the repo to mark or delete.** All historical iteration harnesses lived in `/tmp` only.

## Paths to example PDF + sidecar for TL verification

* PDF (default — no debug footer): `/tmp/natalya-render-phase1-smoke.pdf`
* Sidecar JSON:                     `/tmp/natalya-render-phase1-smoke.pdf.provenance.json`
* PDF with debug footer (opt-in):   `/tmp/natalya-render-phase1-smoke-debug.pdf`
* Sidecar (debug):                  `/tmp/natalya-render-phase1-smoke-debug.pdf.provenance.json`

Quick re-verification command (reproducible from this commit):

```
cd /Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb/services/api-python
/Users/ilya/Projects/astro/services/api-python/.venv/bin/python \
    scripts/render_natalya.py --output /tmp/natalya-verify.pdf
```

## Remaining

Nothing in scope for TASK 1 / Phase 1. Open follow-ups belong to TL:

* **Worktree merge decision** (user / TL) per recommendation above.
* **TASK 2 / Phase 2** (`Hard acceptance assertions for Natalya transit section`) — open after merge decision and inline-verification of this TASK.

## Artifacts

- branch:               claude/dreamy-moore-46f5eb (worktree at `.claude/worktrees/dreamy-moore-46f5eb`)
- commit(s):            `9793d5d` (single commit, conventional message, references TASK + architecture)
- PR:                   not applicable — backup remote only, no origin GitHub PR for this repo
- tests:                94/94 green (85 baseline preserved + 9 new in `test_provenance.py`)
- Product repo status:  committed
- backup parity:        verified — `claude/dreamy-moore-46f5eb` HEAD = `9793d5d` on both local and `backup/claude/dreamy-moore-46f5eb`

## Conflicts / risks

* **Known artefact: `?? .claude/worktrees/` in `/Users/ilya/Projects/astro` `git status`** — pre-existing, untracked by design, explicitly out of scope per TASK § Acceptance "Tests + clean state". Not part of this commit. Worker did not modify the worktree directory or its tracking state.
* **`git_sha` in the smoke-PDF sidecar (`68947433`) is one commit behind HEAD (`9793d5d`)** — expected. The smoke render was produced **before** this commit, to verify the implementation. Any TL re-verification render produced post-commit will show `9793d5d` as the SHA. Provenance is captured at render-time; this is the design contract.
* **`api.core_client._resolve_binary` is a leading-underscore private symbol** that `scripts/render_natalya.py` imports. Acceptable for an in-repo script (it is not a third-party consumer) but flagging it explicitly so TL sees it and can decide whether to promote `_resolve_binary` to public surface in a follow-up Tier C polish. **Not blocking for Phase 1.**
* **No other conflicts** with bright-line invariants, schema gate (TASK touched zero `packages/contracts/*` and zero fixtures), or Phase 0.4/0.5 lock-ins.

## Next step

**TL** inline-verifies (open PDF, eyeball sidecar JSON, confirm 13 required keys), then makes the **merge / cherry-pick / discard decision for `claude/dreamy-moore-46f5eb` → `main`** (Worker recommendation: merge fast-forward). After that decision is acted on, TL opens **TASK 2 (Phase 2 — hard acceptance assertions for Наталья transit section)** per architecture § 5 Phase 2 / § 8 TASK 2.
