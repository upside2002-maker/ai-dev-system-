# HANDOFF: worker → tl — proforientation-phase-b2-pdf-ui

- Status: ready-for-review
- Date: 2026-06-08
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-06-06-proforientation-phase-b2-pdf-ui.md
- Memo: project-overlays/astro/ARCHITECTURE/proforientation-module-architecture-2026-06-06.md (§ 4.3–4.4)
- B1 HANDOFF (backend reused here): HANDOFFS/archive/2026-06-06-worker-to-tl-proforientation-phase-b1-rules-orchestration.md
- Returns Phase E precedent (mirrored): HANDOFFS/archive/2026-05-24-worker-to-tl-planet-returns-ui-pdf-phaseE.md (if archived)
- **Product repo status: committed (`c3fb97b` feat(pdf+ui): proforientation visible layer — PDF section + UI panel (Phase B2)) on `main`**

## Summary

Phase B2 (FINAL) of the proforientation epic: the **visible layer** over the B1 backend —
a PDF section «Профориентация» in the solar report + a UI panel «Профориентация» in
`PersonDetails`. **Presentation-only, Tier B.** Reuses the B1 orchestration verbatim
(`build_vocation_snapshot` + `run_core_analysis` + `compose_vocation_draft` — the SAME
functions the `GET /persons/{id}/vocation` endpoint uses, called **DIRECTLY**, **ONE** core
call, **NOT** the HTTP endpoint). Authors **no** interpretation text (it comes from the
Marina-editable rulesets via the B1 composer) and recomputes **no** factors/selection
(bright lines #6/#7). The draft is honestly framed «черновое» in both surfaces.

Live render of Marina's solar PDF (consultation 15) shows the new section with her top-3
(Юпитер · дом X · Близнецы / Венера · дом X · Рыбы / Солнце · дом X · Овен), each with the
B1 draft text + a «черновое» marker; the existing solar sections and the returns section
are intact. `pytest`: **748 passed, 3 skipped (pre-existing), 0 failed** (+7 new section
tests over the B1 baseline 741). `tsc --noEmit` clean. `cabal` untouched.

## Done (B2.1–B2.3)

- **B2.1 PDF** — `services/api-python/app/pdf/vocation_section.py` (mirrors
  `returns_section.py`): `build_vocation_section(person)` → reuse B1 (`build_vocation_snapshot`
  + `run_core_analysis` + `compose_vocation_draft`, **ONE** subprocess call) → format the
  engine's top-2–3 into rows `{rank, combination "планета · дом · знак", draft_text,
  is_draft}` + the `DRAFT_NOTICE` banner. Graceful degradation on any error (returns
  `{rows: [], error}` — never crashes the PDF, like the returns section). Authors no text;
  the «combination» string is just a join of the composer's `planet_label`/`house_roman`/
  `natal_sign_label`.
  - Jinja block «Профориентация» in `app/pdf/templates/solar.html.j2` (calls
    `vocation_section(person)`), placed **after** «Ближайшие возвраты планет» and **before**
    «Справочные данные» — grouping the two natal-derived reference sections together. Draft
    banner + a per-row «черновое» tag. Standard table markup (no SVG glyphs — no Correction
    007 risk).
  - Builder wire-up: `from .vocation_section import build_vocation_section` (after the
    helpers, acyclic) + `vocation_section=build_vocation_section` global, next to
    `returns_section`.
- **B2.2 UI** — `getPersonVocation(id)` in `apps/web-react/src/api.ts` (mirrors
  `getPersonReturns`) + endpoint-envelope types `VocationDraftResponse` / `VocationDraftRow`
  in `types.ts` (the endpoint wraps the raw `vocation-output` with `person_id`,
  `draft_notice`, and the `composed` DRAFT rows). `VocationPanel.tsx` (mirrors
  `ReturnsPanel.tsx`): draft banner + table of top combos «планета · дом · знак» + draft
  text + per-row «черновое»; live fetch on mount. Mounted in `PersonDetails.tsx` right after
  `ReturnsPanel`, gated on `birth_timezone`. `tsc --noEmit` clean.
- **B2.3 regression + live render** — `tests/test_vocation_section.py` (pure-presentation
  row formatting + e2e `build_vocation_section` for Marina + a **ONE-subprocess-call** spy
  guard + graceful-degrade). `pytest` **748/3/0**. Live render of consultation 15 (in-process,
  `DB_PATH=/Users/ilya/Projects/astro/data/astro.db`, `CORE_CLI_PATH` → cabal list-bin) →
  full WeasyPrint PDF 179 823 bytes; section present + correct; returns + other solar
  sections intact.

## The ONE-call reuse path (proof it's B1, not HTTP)

`build_vocation_section(person)` imports and calls **the B1 functions directly**:
`build_vocation_snapshot` (from `app.ephemeris.vocation_sampler`), `run_core_analysis`
(from `app.core_client`), `compose_vocation_draft` (from `app.vocation_composer`) — the
exact trio the endpoint `app/api/vocation.py` orchestrates. No `httpx`/`requests`/TestClient,
no router call. The spy test `test_build_vocation_section_exactly_one_subprocess_call`
monkeypatches `app.core_client.run_core_analysis` and asserts it fires **exactly once** per
render with the static-natal vocation snapshot (`workflow:"vocation"`, no `samples`, 10
positions, Placidus cusps).

## Rendered «Профориентация» section (Marina, live consultation 15)

Banner: «**Черновое толкование.** Черновое толкование (парафраз метода Дарагана), правится
Мариной — не финальный голос.»

| Сочетание (планета · дом · знак) | Черновое толкование (excerpt) |
|---|---|
| **Юпитер · дом X · Близнецы** · черновое | «Юпитер как сигнификатор — авторитет и экспертиза … преподавание и наука, право (адвокат, нотариус), управление … способ дохода (дом X) — признание и руководство … Натальный знак Близнецы уточняет: слово, информация и посредничество … Черновая формулировка — направление, не финальный текст.» |
| **Венера · дом X · Рыбы** · черновое | «Венера как сигнификатор — красота и искусство … дизайн и стиль, музыка и живопись … Натальный знак Рыбы уточняет: образы, тонкое восприятие и темы моря или закулисья. Черновая формулировка — направление, не финальный текст.» |
| **Солнце · дом X · Овен** · черновое | «Солнце как сигнификатор — творчество и публичность … креатив, сцена, реклама и PR … Натальный знак Овен уточняет: напор и старт нового … Черновая формулировка — направление, не финальный текст.» |

Section ordering in the rendered HTML (offsets): «Ближайшие возвраты планет» (162931) →
«Профориентация» (168161) → «Справочные данные» (171108). Returns section verified intact
(Ключевые планеты group; Луна 21 июня 2026; reference date 9 июня 2026).

## Placement choices

- **PDF section position:** «Профориентация» as a `section-page`, immediately after the
  returns section and before «Справочные данные». Rationale: both are natal-derived
  reference/calculator sections (not the year-specific solar narrative), so they read well
  as a pair near the end. **TL to eyeball on the live PDF** — easy to move if you prefer it
  elsewhere (e.g. right after the natal-chart reference).
- **UI panel position:** a `cardStyle` section in `PersonDetails`, right after the
  «Ближайшие возвраты планет» card, gated on `birth_timezone` (same guard as returns).
- **Title:** «Профориентация» in both surfaces (matches the TASK wording).

## Self-review checklist

- [x] PDF vocation section renders (top-2–3 планета/дом/знак + draft text + «черновое»);
      reuses B1 functions directly (ONE call, not HTTP — spy-proven).
- [x] UI panel renders top combos + interpretation + «черновое»; `getPersonVocation`.
- [x] No interpretation authored in code (text from B1 rules/composer verbatim); no
      recompute; no core/contract/B1/rules change.
- [x] Existing solar + returns sections intact (live render proof — section offsets +
      returns content quoted).
- [x] pytest green (748/3/0); tsc clean; cabal untouched.
- [x] Product committed (`c3fb97b`); overlay committed; backups pushed.

## Verify (committed-state)

- `cd services/api-python && PATH="…/.ghcup/bin:$PATH" .venv/bin/pytest --tb=short -q` →
  **748 passed, 3 skipped (pre-existing), 0 failed** (existing + 7 new section tests).
- `cd apps/web-react && npx tsc --noEmit` → clean (exit 0).
- `cabal` not touched (no core/contract change).
- `git status --short` clean for intended (8 files committed; pre-existing
  `.claude/launch.json` / `_marina-deliverables` / `marketing-site` / `api-python/data`
  intentionally left out per Correction 008 + TASK).
- **0 STOP triggers.**

## Files

- new: `services/api-python/app/pdf/vocation_section.py`;
  `apps/web-react/src/components/VocationPanel.tsx`;
  `services/api-python/tests/test_vocation_section.py`.
- modify: `services/api-python/app/pdf/builder.py`;
  `services/api-python/app/pdf/templates/solar.html.j2`;
  `apps/web-react/src/api.ts`; `apps/web-react/src/types.ts`;
  `apps/web-react/src/pages/PersonDetails.tsx`.

## Not in scope (unchanged)

- Core / contract / `Bridge.*` / `Main.hs` (A1/A2 closed).
- `vocation_sampler.py` / `vocation_composer.py` / `app/api/vocation.py` / rulesets (B1 —
  reused, logic untouched; rules are Marina's data).
- Returns / other solar sections, synthesis, outer_cards (only the new section added).
- DB schema. **No interpretation authored. No math/recompute in presentation. No HTTP from
  the PDF. No draft passed off as final.**
- Full Marina voice (separate track); the B1 cross-house income-mode refinement flag
  (composer takes income-mode by priority house X, not placement II — a B1/rules follow-up,
  not a B2 blocker).
