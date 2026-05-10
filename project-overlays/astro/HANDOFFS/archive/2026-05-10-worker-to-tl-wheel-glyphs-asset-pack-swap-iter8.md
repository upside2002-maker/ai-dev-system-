# Handoff: Worker → TL — Saturn glyph fix (iter 8)

- Status: closed

**Date:** 2026-05-10
**Scope:** Saturn-only manual SVG override (no other changes)
**HEAD before:** bbc7a82 (clean)
**HEAD after:** 6b63df8

## Summary

Owner rejected iter 6 (closed-loop sickle). Iter 8 reauthored Saturn as
ONE rounded arc + small inward terminal hook, per Owner's 5 acceptance
criteria. Converged in 3 standalone-render iterations.

## Iterations

### Attempt 1 — `M 0 -11 L 0 5 M -2 -9 L 2 -9 M 0 5 Q 8 5 7 11 Q 5 13 3 10`
- PNG: `/tmp/saturn-iter8-attempt-1.png`
- Verdict: Almost right but cramped — arc width too narrow (x_max=8) and
  hook end (3, 10) too close to stem, visually reading like a near-closed
  curl rather than a delicate flick.

### Attempt 2 — `M 0 -11 L 0 5 M -2 -9 L 2 -9 M 0 5 Q 9 5 8 11 Q 6 12 4 10`
- PNG: `/tmp/saturn-iter8-attempt-2.png`
- Verdict: Wider arc, hook moved outward to (4, 10) — much better. But
  the chained-Q junction at (8, 11) showed a faint "elbow" — the arc and
  hook met with a visible bend rather than continuous flow.

### Attempt 3 — `M 0 -11 L 0 5 M -2 -9 L 2 -9 M 0 5 C 9 5 9 11 4 10` ✓ FINAL
- PNG: `/tmp/saturn-iter8-attempt-3.png`
- Replaced the chained quadratics with a single cubic Bezier for the
  whole arc-and-hook. Result is a smooth continuous curve from stem-end
  (0, 5) sweeping out to the right and down, ending in a small inward
  flick at (4, 10).
- Matches all 5 acceptance criteria:
  1. Short crossbar (4 units, x=-2..2 at y=-9) ✓
  2. Vertical extends above crossbar (y=-11..-9 finial) ✓
  3. Long vertical stem (y=-9..5, ~58% of glyph height) ✓
  4. ONE rounded arc on the right (single C cubic, no visible elbow) ✓
  5. Small inward terminal hook (cubic ends at (4,10), well outside stem) ✓

## Final path

```
M 0 -11 L 0 5 M -2 -9 L 2 -9 M 0 5 C 9 5 9 11 4 10
```

Authored as STROKE geometry (not fill). Saturn remains in
`STROKE_BASED_GLYPHS` set in `wheel.py` — no logic change.

## Verification

- **Standalone preview:** `/tmp/saturn-iter8-attempt-3.png` (400×400 from
  WeasyPrint SVG render at viewBox=-12..12, stroke-width=2.4).
- **Real-PDF render:** `/tmp/astro-natalya-after-glyph-swap-iter8.pdf`
  (case 8 Натальи, 121.4 KB).
- **Page-1 PNG (3000-pixel high-res):** `/tmp/astro-iter8-p1-big.png`.
  Saturn visible at IX house cluster next to "1°25' R" — silhouette
  matches the standalone preview.
- **pytest:** 70/70 passed (15.89s).

## Files changed

- `services/api-python/scripts/build_wheel_glyphs.py` —
  `HAND_CRAFTED_OVERRIDES["Saturn"]` rewritten as single-cubic arc+hook.
- `services/api-python/app/pdf/wheel_glyphs.py` — autoregenerated.

## Out of scope (untouched)

Any other glyph, wheel.py logic, cardinal labels, axes, viewBox,
aspect-removal — all per iter-8 directive constraints.

## Commit

```
6b63df8 fix(pdf): manual Saturn override matching Owner reference (iter 8)
```

## Tool budget

Used ≈14 tool calls (precondition 2 + iter1 4 + iter2 2 + iter3 4 +
pytest 1 + real-PDF 2 + commit/log 2 + handoff 1).
Well under 20-call cap.
