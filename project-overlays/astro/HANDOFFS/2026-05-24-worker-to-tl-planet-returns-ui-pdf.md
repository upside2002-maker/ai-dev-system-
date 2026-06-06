# HANDOFF: worker → tl — planet-returns-ui-pdf (Phase E, FINAL)

- Status: open (Phase E complete; epic A-E done — final visible layer landed)
- Date: 2026-06-05 (executed; reference rendered = render date)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-24-planet-returns-ui-pdf.md
- Memo: project-overlays/astro/ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md (§ 3.2/3.3, § 0.1/0.2)
- **Product repo status: committed (`51f1e575f6af19cf91000a84a06ca0625a8e0250` on main — `feat(pdf+ui): planet-returns visible layer — PDF section + UI panel (Phase E)`)**

## Summary

Phase E (FINAL) of the planet-returns epic: the **visible layer**. Two
client-facing surfaces for the standalone «ближайшие возвраты планет»
calculator — a **PDF section** in the solar report (reference = render
date) and a **live UI panel** (reference = server now). Presentation-only
(Tier B): math/schema/Haskell (Phase B-D) untouched. **MVP = dates only**
— a factual table (planet → nearest return → action window → note), NO
deep interpretation prose / NO Daragan verbatim (wave 4). PDF reuses the
Phase D orchestration verbatim (ONE snapshot, ONE subprocess call — NOT
the HTTP endpoint). JD→date is presentation on each side (Python reuses
the builder's `_jd_to_utc`; TS reuses i18n `jdToUtc`); the contract stays
JD (no ISO fields). **0 STOP triggers fired.**

## Files changed (one product commit `51f1e57`, 9 files, +1063/-1)

PDF (services):
- **NEW** `services/api-python/app/pdf/returns_section.py` — `build_returns_section(person, render_jd)`: reuses Phase D `build_returns_snapshot` + `run_core_analysis` (ONE call), groups/formats the `returns-output` into a table. JD→long-Russian-date («22 марта 2027») via the shared `_jd_to_utc` primitive (no JD math duplicated). 6-key group (Moon/Sun/Venus/Mars/Jupiter/Saturn) → Mercury secondary → outer (Uranus/Neptune/Pluto) with notes. Slow planets render a multi-pass series. Graceful degradation (missing tz / core error → placeholder line, never crashes the PDF).
- **MOD** `services/api-python/app/pdf/templates/solar.html.j2` — new «Ближайшие возвраты планет» section placed **before «Справочные данные»** (near the reference/calendar sections per memo § 3.2). Intro states the render-date reference; grouped tables; «проходы:» series line for slow planets.
- **MOD** `services/api-python/app/pdf/builder.py` — `_render_jd_now()` (render-date reference) + register `returns_section` / `render_jd_now` Jinja globals. The `build_returns_section` import is placed after `_jd_to_utc` is defined to avoid a circular dependency (returns_section imports `_jd_to_utc`).

UI (frontend):
- **MOD** `apps/web-react/src/api.ts` — `getPersonReturns(id, asOf?)` → `GET /persons/{id}/returns` (mirrors `geocodePlace`; live default = server now).
- **NEW** `apps/web-react/src/components/ReturnsPanel.tsx` — grouped table mirroring the PDF (same grouping/notes/series logic); JD→date in TS via new `formatJdDate`.
- **MOD** `apps/web-react/src/lib/i18n.ts` — `formatJdDate(jd)` (long Russian date, reuses `jdToUtc`; kept in lock-step with the PDF's month names).
- **MOD** `apps/web-react/src/pages/PersonDetails.tsx` — mounts `ReturnsPanel` as a card between «Натальные данные» and «Консультации» (gated on `birth_timezone`).

Tests:
- **NEW** `services/api-python/tests/test_returns_section.py` — 13 tests: date/window formatting (incl. same-day collapse + null boundaries), fast single-row vs slow multi-pass series, 3-group ordering, outer notes + beyond flags, unknown-body drop, e2e for Marina, missing-tz degradation.
- **MOD** `services/api-python/tests/test_api_pdf_endpoint.py` — page-count upper bound 23→25 (the appended returns page adds one page to the case-label deck; no existing section changed — all content assertions in that test still pass).

## Rendered returns section — Marina, consultation 15, LIVE render (reference = render date 5 июня 2026)

Extracted from the actual rendered solar HTML (`render_solar_html` for
person 4 / consultation 15, the same path the `/pdf` endpoint uses):

```
Ключевые планеты
  Луна    | 21 июня 2026   | 21 июня 2026                            | повторяется примерно раз в месяц
  Солнце  | 22 марта 2027  | с 21 марта 2027 по 23 марта 2027        | повторяется раз в год (≈ день рождения)
  Венера  | 18 апреля 2027 | с 17 апреля 2027 по 19 апреля 2027      | повторяется примерно раз в год
  Марс    | 8 июля 2026    | с 6 июля 2026 по 9 июля 2026            | повторяется примерно раз в два года
  Юпитер  | 16 мая 2036    | с 12 мая 2036 по 21 мая 2036            | повторяется примерно раз в 12 лет
  Сатурн  | 23 февраля 2048 [проходы: 23 февраля 2048, 28 июня 2048, 21 ноября 2048] | с 12 февраля 2048 по 1 декабря 2048 | повторяется примерно раз в 29–30 лет
Меркурий
  Меркурий| 1 апреля 2027  | с 1 апреля 2027 по 2 апреля 2027        | повторяется примерно раз в год
Внешние планеты (справочно)
  Уран    | 14 февраля 2073 [проходы: 14 февраля 2073, 7 июня 2073, 3 декабря 2073] | с 24 января 2073 по 20 декабря 2073 | раз в жизнь (~84 года)
  Нептун  | 24 февраля 2153 [проходы: 24 февраля 2153, 4 июня 2153, 24 декабря 2153] | с 22 января 2153 по 19 января 2154 | вне продолжительности жизни (справочно)
  Плутон  | 13 декабря 2235 [проходы: 13 декабря 2235, 30 апреля 2236, 8 октября 2236] | с 16 ноября 2235 по 3 ноября 2236 | вне продолжительности жизни (справочно)
```

Highlights TL asked to quote: **Sun = 22 марта 2027** (≈ Marina's
birthday, matches Phase A). **Saturn = 23 февраля 2048** as the headline
of a 3-pass series (Direct / Retrograde / DirectReturn → 23.02 / 28.06 /
21.11.2048), window spans the whole loop. **Neptune / Pluto** carry the
beyond-lifespan note (справочно). Jupiter shows a single pass (its loop
crossed the natal degree once in-window) so it renders as a non-series
row — correct.

### Existing sections intact (same live render)

All 8 `.section-title` headings render in order — the 6 pre-existing
sections plus the new one before «Справочные данные»:

```
Распределение планет по домам соляра · Темы года · Прогрессии · Дирекции ·
Транзиты · Итоги консультации · Ближайшие возвраты планет · Справочные данные
```

(Note: pypdf `extract_text` mangles multi-word Cyrillic headings, so the
authoritative proof is the rendered HTML that feeds WeasyPrint, quoted
above — not a pypdf substring scan.)

## Presentation choices (for TL eyeball)

- **Date format:** «22 марта 2027» (long Russian, month in genitive) —
  reads warmly in a sparse 10-row client table and matches Marina's
  reference-report style. (The dense transit *calendar* uses DD.MM.YYYY;
  a factual returns table reads better with month names.) Same format
  UI + PDF.
- **Action window:** «с 21 марта 2027 по 23 марта 2027», collapsing to a
  single date when both ends fall on the same calendar day (fast planets
  like the Moon), with graceful one-sided / «—» fallbacks for null
  boundaries.
- **Slow-planet series form:** one **headline row** per planet (nearest
  pass = the date), the window spanning the **whole loop** (first pass's
  orb-enter → last pass's orb-exit), and the individual pass dates on a
  compact «проходы: …» sub-line. This gives both the "ближайший возврат"
  headline and the readable series in one row (avoids 3 separate rows per
  slow planet).
- **Grouping / emphasis:** group 1 «Ключевые планеты» (the 6 Marina
  emphasises, in her order Moon/Sun/Venus/Mars/Jupiter/Saturn); group 2
  «Меркурий» (secondary); group 3 «Внешние планеты (справочно)» with the
  once-in-life / beyond-lifespan notes.
- **Section title / placement (PDF):** «Ближайшие возвраты планет», own
  `section-page` immediately **before «Справочные данные»** (reference
  cluster). Reference = render date, stated in the intro.
- **Panel placement (UI):** a card in `PersonDetails` between «Натальные
  данные» and «Консультации», gated on `birth_timezone` (the endpoint's
  hard requirement); live (default as_of = server now).

## Verification

- **pytest** (`PATH=ghcup .venv/bin/pytest --tb=short -q`): **728 passed,
  3 skipped, 0 failed** (715 baseline + 13 new returns-section tests; the
  3 skips are pre-existing core-CLI-gated e2e fixtures). The single
  initial failure (`test_api_pdf_endpoint` page-count 24 > 23) was the
  expected one-page growth from the new section → bound widened 23→25
  with a documented comment; all content assertions in that test pass.
- **tsc** (`npx tsc --noEmit` in `apps/web-react`): **clean (exit 0)**.
- **cabal test** (spot-check, Haskell untouched): **279 examples, 0
  failures** (matches baseline — returns golden + roundtrip intact).
- **Live render** Marina consultation 15: returns section present +
  correct (rows quoted above) + all existing sections intact.
- `git status --short`: clean for intended (only pre-existing unrelated
  artifacts `.claude/launch.json`, `_marina-deliverables/`,
  `marketing-site/` remain — left OUT per Correction 008).

## STOP triggers

**0 fired.** No ISO fields added to any contract (JD→date is
presentation on each side). No return/JD math duplicated (PDF reuses
Phase D + the shared `_jd_to_utc`; UI reuses `jdToUtc`). No
Haskell/contract/Phase-D logic changed. No deep interpretation /
Daragan verbatim — factual table only (per-planet notes are frequency /
once-in-life / beyond-lifespan facts). Existing solar sections intact.
PDF calls the Phase D **function** directly (`build_returns_snapshot` +
`run_core_analysis`), NOT the HTTP endpoint.

## Self-review checklist

- [x] PDF returns section renders (reference = render date); JD→date correct; 6-key emphasis; outer notes; slow series readable.
- [x] UI panel renders the 10 planets live; JD→date in TS.
- [x] PDF reuses Phase D functions directly (ONE call, not HTTP).
- [x] No ISO in contract; no math dup; no Haskell/Phase-D logic change.
- [x] No deep interpretation / Daragan verbatim — factual table only.
- [x] Existing solar sections intact (live render proof).
- [x] pytest green (728/3/0); tsc clean; cabal spot-check green (279/0).
- [x] Product committed (`51f1e57`); overlay HANDOFF + STATUS_RU; backups pushed (see § below).

## Open notes for TL (non-blockers)

- **Daragan deep interpretation prose** remains wave 4 (deliberately out;
  the section is factual to avoid the brevity / no-Daragan-verbatim
  conflict).
- **Lilith** still pending (mean/true) — out of returns-MVP.
- Jupiter rendering as a single pass (vs a 3-pass series like the other
  slow planets) is data-driven: in Marina's window its loop crossed the
  natal degree once. The code handles both forms; if TL wants slow
  planets *always* shown as a labelled series even when single-pass, that
  is a one-line tweak.
