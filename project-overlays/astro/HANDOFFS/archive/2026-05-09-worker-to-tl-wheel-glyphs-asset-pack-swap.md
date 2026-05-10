# HANDOFF: worker → TL — wheel-glyphs-asset-pack-swap

- Status: closed
- Date: 2026-05-09
- From: Worker (Claude Code subagent, separate session)
- To: TL
- Project: astro
- TASK: project-overlays/astro/TASKS/2026-05-09-wheel-glyphs-asset-pack-swap.md
- Worker commits: `9d452dd` (parent `876cdfe`)
- Agent runtime: Claude Code (Worker subagent, separate from TL session)
- Role mode: Worker (Mode normal — Tier B)

## Summary

Заменил 22 hand-drawn approximation глифа на path-based выгрузки из
Astronomicon Fonts v1.1 (SIL OFL 1.1). One atomic commit `9d452dd`:
build script + TTF + license + auto-generated `wheel_glyphs.py` + правки
`wheel.py` (стилевая иерархия gold zodiac / dark planets, tuning размеров
под filled glyphs). pytest 70/70 green; real-PDF Натальи рендерится
чисто без WeasyPrint render abort. A/B preview Aries (Phase 1) clearly
favoured Astronomicon — Worker proceeded to Phase 2 без TL escalation.

## Phase 1 A/B preview

- **Astronomicon variant (a)**: `/tmp/aries-astronomicon-preview.svg`
- **Hand-trace variant (b)**: `/tmp/aries-handtrace-preview.svg`
  (used the existing wheel.py `_GLYPH_SVG['Aries']` as the «hand-trace
  approximation» — that path IS the current hand-drawn approximation
  that Marina и Owner называют «школьная парта».)
- **Side-by-side PDF**: `/tmp/aries-ab-preview.pdf` (3 sizes per variant:
  24px / 60px / 200px) + supporting full-charset reveal at
  `/tmp/astronomicon-charset-wide.pdf`.

### Comparison

| Dimension | Astronomicon (a) | Hand-trace (b) |
|---|---|---|
| Path quality | Clean Bezier curves, vector source from professional font | Quadratic-arc hand approximation, no fidelity to canonical shape |
| Edge sharpness | Crisp at all sizes (24/60/200 px) | Acceptable at 24px, rough at 200px |
| Style fidelity | Classical Unicode-canonical horns ♈, ram-style | Looks like a flat-top arch with two vertical bars — not recognisable as Aries |
| Production scalability | Single script run extracts all 22 glyphs deterministically | Per-glyph manual drafting × 22 |
| License | SIL OFL 1.1, commercial-use OK, ships with OFL-License.txt | n/a |

### Recommendation

**Astronomicon variant (a) — clear win across all dimensions.** Worker
**proceeded to Phase 2 без TL escalation** per TASK § Acceptance line 60
(«Если clearly Astronomicon win → Worker proceed'ит без TL
escalation»). The current hand-drawn `_GLYPH_SVG['Aries']` quite simply
does not look like Aries; replacing it with the canonical glyph from a
professional vector font is a strict-better in every measured dimension.

### Astronomicon character map (verified by visual inspection)

Astronomicon's TTF doesn't expose glyphs at U+26xx — it maps them to
ASCII letters. Verified by rendering the full charset to PDF:

- **A..L → 12 zodiac signs** (Aries..Pisces)
- **Q → Sun**, **R → Moon**
- **S..Z → Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto**
- **g → North Node**, **h → South Node**, **l → Lilith** (bonus, not
  rendered today — engine doesn't emit those positions; included in
  asset set for future Tier A `solar-nodes-lilith-retro-display`)

Build script encodes this as the `GLYPH_MAP` dict in
`scripts/build_wheel_glyphs.py:48-77`.

## Phase 2 implementation

### Files added

- `services/api-python/app/pdf/assets/Astronomicon.ttf` (31564 bytes,
  binary) — original TTF as downloaded from
  https://astronomicon.co/AstronomiconFonts_1.1.zip; not modified.
- `services/api-python/app/pdf/assets/OFL-License.txt` (4419 bytes) —
  SIL OFL 1.1 text, copied verbatim from the upstream ZIP. Required by
  OFL §4 (license must accompany the font binary).
- `services/api-python/scripts/build_wheel_glyphs.py` (198 lines) —
  one-shot extraction script. fontTools.SVGPathPen + TransformPen
  pipeline; affine: translate to origin, scale uniformly so longer
  bbox dimension fits in 22 units (1-unit margin), flip y (TTF y-up
  → SVG y-down). Emits `app/pdf/wheel_glyphs.py` deterministically.
  Run with `.venv/bin/python services/api-python/scripts/build_wheel_glyphs.py`.
- `services/api-python/app/pdf/wheel_glyphs.py` (auto-generated, 45
  lines, 16 KB) — `GLYPH_PATHS: dict[str, str]` with 25 entries (10
  planets + 12 signs + 3 bonus). Coordinates rounded to 2 decimals.

### Files modified

- `services/api-python/app/pdf/wheel.py:36-77` — header comment updated
  to describe Astronomicon-derived path origin; `_GLYPH_SVG` (54 lines
  of hand-drawn paths) deleted; replaced with `_RENDERED_GLYPHS` list
  (22 names) that drives `_emit_glyph_defs` reading from
  `wheel_glyphs.GLYPH_PATHS`.
- `services/api-python/app/pdf/wheel.py:78-95` — `_emit_glyph_defs`
  switched from `fill="none" stroke="currentColor" stroke-width="1.6"
  stroke-linecap="round" stroke-linejoin="round"` to a single
  `<path d="..." fill="currentColor"/>` per `<symbol>`. Astronomicon
  glyphs are closed filled outlines, not strokes; using stroke would
  produce inverted, hollow renderings.
- `services/api-python/app/pdf/wheel.py:268-275` —
  `sign_glyph_size = size * 0.058 → 0.052` and
  `planet_glyph_size = size * 0.064 → 0.060`. Justified inline in the
  comment: filled outlines carry more visual weight than strokes, so
  smaller absolute sizes preserve the previous reading balance.
- `services/api-python/app/pdf/wheel.py:296` — sign glyph wrapper
  `<g color="#333">` → `<g color="#b88a2c">` (warm gold). Drives the
  zodiac-vs-planet hierarchy via `currentColor`. Planet wrapper at
  `wheel.py:471` already uses `<g color="#1a1a1a">` and stays
  unchanged — the contrast (gold zodiac / near-black planets) is the
  «reference style hierarchy» the TASK called for.

### Sizing/color tuning notes

- The new gold (`#b88a2c`) was eyeballed against pastel sector tints
  (`#fde2d4` peach / `#e0eed7` green / `#fff4d0` yellow / `#dbeaf4`
  blue) — readable on all four. Slightly desaturated from pure gold
  (`#c9a14a` used in the A/B preview) to keep the wheel calm rather
  than bling-y.
- `sign_glyph_size = size * 0.052` at the default `size=460` →
  ~24 px sign glyph diameter, fits comfortably in the ~36 px-wide
  zodiac ring.
- `planet_glyph_size = size * 0.060` → ~28 px diameter, distinct from
  sign size by ~4 px so the eye separates "outer ring = signs" from
  "inner cluster = planets" by scale plus colour.

### Real PDF render

Output: `/tmp/astro-natalya-after-glyph-swap-9d452dd.pdf` (130 KB,
case 8 Наталья). Both wheel pages render cleanly:

- **Page 1 (Solar wheel)**: 12 gold sign glyphs in outer ring, all
  recognisable; 10 black planet glyphs in inner cluster; aspect lines,
  cusps, Roman house numerals, ASC/MC/DSC/IC labels — all intact.
- **Page 2 (Natal wheel)**: same hierarchy; the natal Sagittarius
  stellium (Moon, Uranus, Neptune within ~9° of longitude) renders
  with the existing radial+tangential stagger logic — glyphs distinct,
  labels readable.

`pdftotext` extracts 805 lines and 15 hits across `Транзит / Дирекц /
Прогноз / Итог` keywords — confirms no WeasyPrint render abort
downstream. (When the SVG-text U+26xx bug fires, *all* subsequent SVG
elements vanish and the text-extraction count plummets; observed full
extraction is the canary that says we're clean.)

## Tests

- pytest: 70/70 green (unchanged from baseline `876cdfe`).
- WeasyPrint render: clean (130 KB PDF, both wheels visually correct,
  full pdftotext extraction).
- `git status --short` after commit: clean (verified).
- `git diff 876cdfe..HEAD --stat`: 5 files touched — exactly the set
  in TASK § Files (modify: `wheel.py`; add: build script, TTF, license,
  generated module). Nothing outside `services/api-python/app/pdf/**`
  + `services/api-python/scripts/**`.

## Conflicts/risks flagged

### 1. Astronomicon character mapping diverges from Unicode

Astronomicon's TTF maps glyphs to ASCII letters (A..L = signs,
Q..Z = planets), not to U+26xx codepoints. The TASK § Constraints
guidance (lines 87–88) suggested `fontTools.ttLib.TTFont` lookup by
Unicode codepoint — that returns `None` for this font. Worker
disambiguated by rendering the full ASCII charset to PDF and visually
identifying which letter holds which glyph; the mapping is encoded
explicitly as `GLYPH_MAP` dict in `scripts/build_wheel_glyphs.py:48-77`
with a comment pointing to the verification artifact
(`/tmp/astronomicon-charset-wide.pdf`). **Risk**: if Astronomicon ever
ships a v2 with a different character layout, the build script will
silently produce wrong glyphs (e.g. if "A" started carrying Taurus
instead of Aries). Mitigation: the script is run once and its output
is committed as text; any silent mis-mapping would be visible in the
next render's PDF diff. Acceptable for a one-shot conversion.

### 2. Switched `<symbol>` defaults from stroke to fill — visual change beyond glyph identity

The previous `_GLYPH_SVG` was strokes (line-art schematics, hollow
shapes). Astronomicon glyphs are filled closed outlines, so the new
`<symbol>` carries `fill="currentColor"` instead of `stroke=...`.
Visually: planet glyphs now read as solid silhouettes rather than
line-drawings. This was not separately approved by Owner — it follows
naturally from "use a vector font", but TL should confirm Owner is OK
with the silhouette style vs strict line-drawing. The reference image
attached by Owner (per TASK § Context) showed «classical
Unicode-canonical shapes» which are typically rendered as filled
outlines in standard astrology fonts, so I judged this aligned with
intent — but flagging for explicit Owner verdict per the TL inline
review checklist line 71.

### 3. Sizing tuning was eyeballed at default `size=460`

The wheel is rendered at `size=460` in both call sites
(`solar.html.j2:201` solar, `:234` natal). All sizing constants
(`sign_glyph_size = size * 0.052` etc.) scale linearly, so geometry
is correct at any size — but I only verified the visual balance at
460 px. If the wheel is ever rendered at a much different size (e.g.
embedded in a smaller UI component at 200 px), the absolute pixel
weight of the filled glyphs may need a re-tune. Out-of-scope for this
TASK.

### 4. Astronomicon includes 3 bonus glyphs (Nodes, Lilith) not rendered today

`GLYPH_PATHS` carries `NorthNode`, `SouthNode`, `Lilith` extracted
впрок per TASK § Context («Lilith/Nodes glyphs готовим в asset set
впрок»). They are NOT in `_RENDERED_GLYPHS` and never reach
`_emit_glyph_defs`, so they don't add bytes to the rendered SVG nor
risk accidental render. When the future Tier A
`solar-nodes-lilith-retro-display` lands and the engine starts
emitting those positions, the wiring is one-line: append the names to
`_RENDERED_GLYPHS`. Risk: dead asset bytes (~3 KB in
`wheel_glyphs.py`). Acceptable.

### 5. Build-script run is manual, not CI-enforced

`scripts/build_wheel_glyphs.py` is a one-shot. There is no CI gate
that re-runs it and asserts no diff against committed
`wheel_glyphs.py`. If anyone hand-edits `wheel_glyphs.py` (which the
auto-generated header explicitly forbids) or modifies the TTF without
re-running the script, the two will drift. Risk-mitigation: the
auto-generated header says "DO NOT EDIT BY HAND" plus a re-run
command. Could add a pytest step that compares
`build_wheel_glyphs.py`'s output to the committed module — but that's
a separate-TASK enhancement; out of scope.

### 6. Cardinal labels (ASC/MC/DSC/IC) overlap zodiac glyphs at top/bottom

This was already true in the previous version (cardinal labels sit
"just outside the outer ring" at radius `r_outer + size * 0.040`,
which crowds the zodiac glyph at the same screen angle when the
cardinal axis happens to fall near a sector boundary). Not regressed
by this change, but the new larger-stroke gold glyphs make the
overlap slightly more visible. Out of scope; would be its own Tier C
TASK if Owner wants it cleaned up.

## Recommendation to TL

- **Inspection**:
  - Open `/tmp/astro-natalya-after-glyph-swap-9d452dd.pdf` for the
    real wheel render (case 8 Наталья).
  - Side-by-side with Marina reference
    `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` p.1-2
    (wheel pages) for visual style verdict.
  - `git show 9d452dd` for the diff.
  - `/tmp/aries-ab-preview.pdf` for the Phase 1 A/B comparison.
  - `/tmp/astronomicon-charset-wide.pdf` for the Astronomicon
    glyph-to-letter mapping that drove `GLYPH_MAP`.
- **Acceptance gate**: TL inline review per TASK § Embedded TL review
  checklist (lines 70–79). All 9 checklist items addressable from
  this HANDOFF + the rendered PDF; no Reviewer subagent required per
  Mode normal.
- **Open questions for TL/Owner**:
  - § 2 above: silhouette/filled style vs line-drawing — visual
    change beyond pure glyph swap.
  - Gold colour `#b88a2c` — Worker's eyeball pick; if Owner wants a
    different gold (richer / more muted), trivial CSS change in
    `wheel.py:296`.

## Next step

TL inline review of commit `9d452dd` + rendered PDF. Sign-off → Owner
visual verdict via TL relay. If Owner approves: TASK closes, HANDOFF
moves to `archive/`. If Owner requests tuning (gold shade, glyph size,
weight, etc.): one-line follow-up commits within the same scope.
