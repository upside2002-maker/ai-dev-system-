# HANDOFF: worker → tl — proforientation-phase-b1-rules-orchestration

- Status: closed
- Date: 2026-06-08
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-06-06-proforientation-phase-b1-rules-orchestration.md
- Memo: project-overlays/astro/ARCHITECTURE/proforientation-module-architecture-2026-06-06.md
- Method extract: project-overlays/astro/RESEARCH/daragan-proforientation-method-extract.md (§ 1, § 5)
- Phase 0 HANDOFF (significator mappings): HANDOFFS/archive/2026-06-06-worker-to-tl-proforientation-phase0-method-proof.md (§ 2)
- **Product repo status: committed (`6c24c11` feat(services+rules): proforientation stage-5 — vocation rules + orchestration + endpoint (Phase B1)) on `main`**

## Summary

Phase B1 of the proforientation epic: Daragan **stage 5 (interpretation)** delivered as
**editable rules-data** (`packages/rulesets/vocation/`, Marina edits, no programmer) +
thin Python orchestration + a standalone endpoint. The math/selection (stages 1–4) was
already done in the Haskell core (A1 `7dc313e` / A2 `b7cf858`); Python here only assembles
the natal input, makes **ONE** `run_core_analysis` subprocess call (`workflow:"vocation"`),
and **substitutes** draft prose from the rulesets onto the engine's output keys. **No math /
no significator-selection in Python** (bright line #7). **No PDF / no UI** (those are Phase B2).

`GET /persons/4/vocation` → HTTP 200; Marina's top-3 reproduce A1 (Jupiter ruler-of-X = the
optimum, then Venus, then Sun), each with composed draft text honestly flagged
«черновое толкование». `pytest`: **741 passed, 3 skipped (pre-existing), 0 failed**.

## Done (B1.1–B1.5)

- **B1.1 rules-data** — `packages/rulesets/vocation/` (3 JSON, each with the draft `_note`
  «Черновой набор, правится Мариной; парафраз метода Дарагана, не финальный голос»):
  - `planet_activity.json` — 10 planets → activity sphere (Sun…Pluto).
  - `house_income_mode.json` — 4 money houses (X/II/VI/VIII) → income mode.
  - `sign_narrowing.json` — 12 signs → narrowing (element layer + per-sign nuance).
  Paraphrase of the § 5 + Phase-0 significator tables — NOT Daragan verbatim.
- **B1.2 orchestration** — `app/ephemeris/vocation_sampler.py`:
  `build_vocation_snapshot(person)` → natal positions (reuse `compute_planet_positions`) +
  Placidus cusps via `swe.houses_ex` (an ephemeris query, like `find_solar_return_jd`) →
  `vocation-input` (validates against `vocation-input.schema.json`; static natal — **no
  `samples`, no `reference_jd`**). No math.
- **B1.3 composer** — `app/vocation_composer.py`: `compose_vocation_draft(output, natal_positions)`.
  Per top-2–3 combo: planet_activity + income-mode of the **priority** connected house
  (`connected_houses[0]` — the engine already orders X>II>VI>VIII) + the natal-sign narrowing
  (sign read back from the input positions) → 2–3 short draft sentences. `is_draft=True` +
  `DRAFT_NOTICE`. Pure substitution by the engine's keys — recomputes nothing.
- **B1.4 endpoint** — `app/api/vocation.py` + router in `app/main.py` (mirrors `api/returns.py`):
  `GET /persons/{id}/vocation` → `{workflow, person_id, draft_notice, top_combinations,
  composed, factor_table, meta}`. No DB write.
- **B1.5 tests** — `services/api-python/tests/test_vocation_endpoint.py` (10 tests): input
  validates; `GET person-4` → 200 with top-3 (Jupiter ruler-of-X / Venus / Sun); composer
  draft spheres (Jupiter→expertise/law/teaching) + draft markers; **no-Daragan-verbatim
  guard**; full key vocabulary; **exactly ONE subprocess call** (spy); composer substitutes
  engine keys without recompute; 404 / 422 edges.

## The ONE-subprocess code path (proof)

`app/api/vocation.py` → `get_person_vocation`: load person → `build_vocation_snapshot` (pure
ephemeris, no core) → **one** `run_core_analysis(snapshot)` → `compose_vocation_draft(result,
snapshot["natal_positions"])` (pure substitution, no core). The composer and snapshot builder
never shell out — only the single `run_core_analysis` line does.
`test_vocation_endpoint_exactly_one_subprocess_call` monkeypatches the
`vocation.run_core_analysis` symbol with a counting spy and asserts the call count is exactly
**1** per request (and that the payload is the static-natal `workflow:"vocation"` snapshot,
no `samples`).

## no-Daragan-verbatim — how paraphrase was ensured

The significator meanings were **reworded** from the § 5 / Phase-0 tables, not copied. The
guard test `test_rules_data_is_paraphrase_not_verbatim` asserts (a) every file carries the
draft `_note` marker + honest method attribution, and (b) none of the book's distinctive
verbatim strings appears in the rule text: the chapter-title pun «долги отдают только трусы»,
the quoted house nicknames «работа на себя» / «слава и почести» / «не работаешь сам» /
«работают вложенные деньги», and the p. 282 opener «недостаточно знать». (One incidental
3-word echo «работа на себя» was reworded to «самозанятость» during the build so even the
quoted nickname is absent.) Draft framing is explicit and machine-readable (`is_draft`,
`DRAFT_NOTICE`, in-text «черновая формулировка») so the draft is never passed off as the
finished Marina-voice interpretation (a separate later track per TZ).

## Composed draft text — Marina (person 4) top-3

> **[ранг 1] Юпитер · дом X · знак Близнецы · Σ7** *(черновик)*
> Юпитер как сигнификатор — авторитет и экспертиза — то, что даёт уважение и вес:
> преподавание и наука, право (адвокат, нотариус), управление и представительство,
> консультирование, идеология и культура; способ дохода (дом X) — признание и руководство:
> стать заметным именем в профессии или возглавить дело — доход приходит вслед за репутацией
> и масштабом, потолка по сути нет. Натальный знак Близнецы уточняет: слово, информация и
> посредничество, несколько дел сразу. Черновая формулировка — направление, не финальный текст.

> **[ранг 2] Венера · дом X · знак Рыбы · Σ6** *(черновик)*
> Венера как сигнификатор — красота и искусство — создание привлекательного и приятного:
> дизайн и стиль, музыка и живопись, сцена, индустрия красоты, гостеприимство и эстетика
> комфорта; способ дохода (дом X) — признание и руководство: стать заметным именем в
> профессии или возглавить дело — доход приходит вслед за репутацией и масштабом, потолка по
> сути нет. Натальный знак Рыбы уточняет: образы, тонкое восприятие и темы моря или закулисья.
> Черновая формулировка — направление, не финальный текст.

> **[ранг 3] Солнце · дом X · знак Овен · Σ5** *(черновик)*
> Солнце как сигнификатор — творчество и публичность — всё, где важно проявить себя и быть на
> виду: креатив, сцена, реклама и PR, ведение и наставничество, эксклюзивная авторская работа;
> способ дохода (дом X) — признание и руководство: стать заметным именем в профессии или
> возглавить дело — доход приходит вслед за репутацией и масштабом, потолка по сути нет.
> Натальный знак Овен уточняет: напор и старт нового, инициатива в одиночку. Черновая
> формулировка — направление, не финальный текст.

**Note for TL/Marina:** the priority connected house is X for all three (the income-mode
anchor). A1 framed Jupiter as «упр.X в II» — the II is *where Jupiter sits* (its
`placed_in_house_2` factor); the composer uses the priority connected house (X) for the
income mode, which is method-faithful (Daragan: a planet connected to X → the X optimum). If
Marina prefers the draft to mention the *placement* house (II) as well as the priority house,
that is a one-line rule-text edit, no code change.

## Verify

- `cd services/api-python && PATH="…ghcup/bin:$PATH" .venv/bin/pytest --tb=short -q` →
  **741 passed, 3 skipped, 0 failed** (existing suite + 10 new vocation tests). The 3 skips
  are pre-existing (core-CLI-gated cases skip only when the binary is absent; here it was
  present, so they are the unrelated pre-existing skips).
- Core untouched → `cabal test` not affected (spot: no edits under `core/`).
- `git status --short` clean for intended: only the 8 B1 files were staged/committed;
  pre-existing `.claude/launch.json` (M) / `_marina-deliverables` / `marketing-site/` /
  `services/api-python/data/` were left out per the TASK directive (Correction 008 hygiene).

## Self-review checklist

- [x] Rules-data in `packages/rulesets/vocation/`, Marina-editable, `_note` draft marker,
      paraphrased (no verbatim) — guard test enforces it.
- [x] Orchestration: `vocation-input` validates against schema; **ONE** subprocess; no math
      in Python.
- [x] Composer: top-2–3 → draft text from rules (no recompute — test asserts row keys ==
      engine keys); honest draft framing (`is_draft`, `DRAFT_NOTICE`).
- [x] Endpoint `GET /persons/{id}/vocation` → 200; Marina top-3 + draft text.
- [x] no-Daragan-verbatim verified; no DB cache; no core/contract/B2 scope touched.
- [x] pytest green; product committed (`6c24c11`); overlay committed + pushed (this HANDOFF +
      journal).

## Artifacts (product, `6c24c11`)

- new: `packages/rulesets/vocation/{planet_activity,house_income_mode,sign_narrowing}.json`
- new: `services/api-python/app/ephemeris/vocation_sampler.py`
- new: `services/api-python/app/vocation_composer.py`
- new: `services/api-python/app/api/vocation.py`
- new: `services/api-python/tests/test_vocation_endpoint.py`
- modify: `services/api-python/app/main.py` (router registration)

## Conflicts / risks

- None with the core/contract (untouched; solar/returns/vocation schemas not edited).
- The composer anchors the income mode on `connected_houses[0]`; if a future engine change
  reorders that list, the draft's house would follow it (correct by design — Python does not
  re-rank). Flagged above for the optional «mention the placement house too» tweak.

## Next step

TL inline-verify of the client draft text + paraphrase check (Tier B). On accept → Phase B2
(PDF section + UI panel consuming this endpoint). Move TASK Status → review (done here).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
