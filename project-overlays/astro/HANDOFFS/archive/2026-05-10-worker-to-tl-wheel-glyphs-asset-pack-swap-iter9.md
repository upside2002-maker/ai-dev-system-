# Worker -> TL: Saturn glyph fix (iter 9, bitmap-trace method)

- Status: closed

## Date
2026-05-10

## Status
DONE — silhouette matches Owner's reference, embedded, tested, rendered, committed.

## Summary
Iter 8 was rejected by Owner (8th hand-crafted/described Saturn still wrong "5/squiggle").
Owner provided exact reference PNG and directed: bitmap-to-vector trace of THAT image,
not generation from description. This iteration follows that directive end-to-end.

Reference: `/Users/ilya/Projects/astro/Снимок экрана 2026-05-10 в 12.27.48.png`
(172x216 px, white Saturn glyph on black background).

Method:
1. PIL preprocessing: invert (white-on-black -> black-on-white), threshold, crop, pad.
   Output: `/tmp/saturn-trace-input.pbm` + `/tmp/saturn-trace-input.png`.
2. Potrace: `--tight -s -O 0.5 -t 2 -z white` -> closed outline SVG.
   Output viewBox 92.29 x 162.06pt with `<g transform="translate(-49,195.96) scale(0.1,-0.1)">`.
3. Custom Python walker tokenises the path, bakes the Potrace `<g>` transform
   into coordinates (handles M, l, c, z; converts to absolute), computes baked
   bbox, then scales+translates to fit a 20-unit content area centred in
   `-12 -12 24 24` viewBox. Z (close path) was appended manually after the
   walker dropped it (subtle bug: trailing `z` consumed but not emitted; the
   path renders correctly as a closed fill once Z is added).
4. Architecture switch: Saturn moves from stroke to fill geometry. The
   `STROKE_BASED_GLYPHS` frozenset in `app/pdf/wheel.py` is now empty (kept
   for future use). Saturn is now a closed filled outline like every other
   Astronomicon-derived glyph.
5. Embedded transformed path string in `HAND_CRAFTED_OVERRIDES["Saturn"]`
   in `services/api-python/scripts/build_wheel_glyphs.py`.
6. Regenerated `wheel_glyphs.py` (25 glyphs).

## Trace iterations
1 (silhouette matched on first Potrace pass).

## Y-flip
Yes, needed — Potrace emits `scale(0.1, -0.1)` in its `<g>`. I baked the
flip into the path coordinates by applying the `<g>` transform before
the final scale+translate. No additional flip needed downstream.

## Architecture change (one line)
`STROKE_BASED_GLYPHS` -> empty. Saturn is now `fill="currentColor"`,
not `fill="none" stroke="currentColor"`.

## Final path (length: 793 chars)
Single closed subpath, M + 22 cubic Béziers + 6 lines + Z. Excerpt:
`M-3.15 -9.70C-3.21 -9.56 ... -3.00 -9.95 -3.15 -9.70Z`

Full path lives in `HAND_CRAFTED_OVERRIDES["Saturn"]`
(`services/api-python/scripts/build_wheel_glyphs.py:130`).

## 3 mandatory verification artifacts (Owner directive)
1. **Original crop (cropped + inverted)**: `/tmp/saturn-trace-input.png`
2. **Traced vector on white background**: `/tmp/saturn-iter9-trace.png`
3. **Side-by-side overlay**:               `/tmp/saturn-iter9-overlay.png`

Plus full-context renders:
- Full PDF (Natalya case): `/tmp/astro-natalya-after-glyph-swap-iter9.pdf`
- PDF page 1 PNG:          `/tmp/astro-iter9-p1.png`

## Self-decision: silhouettes match
Trace replicates the original silhouette faithfully:
- Vertical descender (full-height bar)
- Horizontal crossbar near the top
- Curved tail sweeping right and down with a small inward hook curling
  back to the lower-left (the canonical Saturn "sickle" / stylised
  lowercase h-descender)

This is **not** the "5/squiggle" of prior iterations. The hook direction
is correct (down-and-left), the proportions match, the crossbar height
matches.

## Files changed
- `services/api-python/scripts/build_wheel_glyphs.py` — Saturn override
  rewritten with traced path, docstring updated to explain Potrace pipeline.
- `services/api-python/app/pdf/wheel.py` — `STROKE_BASED_GLYPHS` set
  emptied; comment updated.
- `services/api-python/app/pdf/wheel_glyphs.py` — auto-regenerated.

## Verification
- pytest: 70/70 passing.
- Full PDF (Natalya golden case) renders cleanly at 121.9 KB.
- Saturn visible in IX-house cluster of natal wheel as a properly-formed
  Saturn glyph with vertical bar, crossbar, and hook tail.

## Commit
HEAD: `309468a` — `fix(pdf): bitmap-trace Saturn from Owner reference image (iter 9)`

## Untracked
The Owner-provided reference PNG remains untracked at the repo root:
`Снимок экрана 2026-05-10 в 12.27.48.png`. Not committed — it's an
input artefact, not source. TL may want to relocate to a documented
references folder or `.gitignore` it.

## Out of scope (not touched)
- All other glyphs (font extraction unchanged).
- Cardinal labels, axes, viewBox, aspect-removal — already accepted.
- Wheel layout math, sizing, colours.
- Anything outside `HAND_CRAFTED_OVERRIDES["Saturn"]` and the
  `STROKE_BASED_GLYPHS` set.
