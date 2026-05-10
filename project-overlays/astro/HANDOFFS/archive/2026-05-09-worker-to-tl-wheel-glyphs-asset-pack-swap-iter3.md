# HANDOFF: worker → TL — wheel-glyphs-asset-pack-swap (iteration 3)

- Status: closed
- Date: 2026-05-09
- From: Worker (Claude Code subagent, separate session, iteration 3)
- To: TL
- Project: astro
- TASK: 2026-05-09-wheel-glyphs-asset-pack-swap
- Worker commit (iter 3): b49707c (parent 666c995)
- Agent runtime: Claude Code (Worker subagent, iteration 3)
- Role mode: Worker (Mode normal — Tier B)

## Summary
Saturn rebuilt as stroke-based line-art (vertical bar + crossbar + sickle hook), with a per-glyph stroke/fill split in `_emit_glyph_defs`. Cardinal labels (ASC/DSC/MC/IC) made readable: bigger, heavier, black with white halo, repositioned inside `r_outer` so the SVG viewBox no longer clips them.

## Fix 1 — Saturn (stroke-based)
- Architecture change: introduced `STROKE_BASED_GLYPHS = frozenset({"Saturn"})` in `services/api-python/app/pdf/wheel.py`. `_emit_glyph_defs` now branches on membership: stroke glyphs emit `<symbol><path fill="none" stroke="currentColor" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/></symbol>`; all other (Astronomicon-derived filled) glyphs keep `fill="currentColor"`.
- New Saturn path (in `services/api-python/scripts/build_wheel_glyphs.py` HAND_CRAFTED_OVERRIDES, baked into `wheel_glyphs.py` by the build script):
  `M0 -10L0 7M-5 -10L5 -10M0 7Q6 7 6 11Q6 13 4 12`
  — vertical bar (top -10 → lower 7), horizontal crossbar at -10, quadratic sickle hook curving down-and-right then back inward.
- Verification: `/tmp/astro-natalya-after-glyph-swap-iter3.pdf` p1 (solar wheel — Saturn at 0°04' Sagittarius cluster, left-centre area) and p2 (natal — Saturn at 23°08' Sagittarius cluster, bottom-right). Both render canonical ♄: vertical bar + crossbar + curl, instantly recognisable.

## Fix 2 — Cardinal labels
- Changes (block at `services/api-python/app/pdf/wheel.py:528-562`):
  - **Position**: moved INSIDE the outer ring (`label_r = r_outer - size*0.030`) instead of outside (was `r_outer + size*0.040`), so labels stay within the SVG viewBox. Outside-ring placement was getting clipped — the primary readability problem.
  - **Size**: `size*0.026 → size*0.038` (~46% larger).
  - **Weight**: `bold → 900` (heaviest).
  - **Letter-spacing**: added `1.5` so 3-letter labels feel substantial.
  - **Contrast**: fill switched from `#c0392b` (muted red) to `#000000` (pure black).
  - **Halo**: emitted as TWO `<text>` elements per label — first a white-stroked-and-filled copy (`fill=#fff`, `stroke=#fff`, `stroke-width=5`), then the black foreground on top. Avoids relying on `paint-order="stroke"` which WeasyPrint 68.x honours inconsistently for SVG `<text>` (an earlier attempt with `paint-order=stroke` rendered as white rectangles with NO visible black text).
- Verification: real-PDF p1 + p2 — ASC (9 o'clock), MC (12 o'clock), DSC (3 o'clock), IC (6 o'clock) all read instantly against the gold zodiac ring; the white halo cleanly cuts through any sector tint or zodiac glyph at the cardinal angle.

## Out-of-scope (not touched)
- Axis lines (`wheel.py:386-395`) — kept as-is from iter-2 per Owner directive.
- All other glyphs (Sun, Moon, Mercury, Venus, Mars, Jupiter, Uranus, Neptune, Pluto, all 12 zodiac signs).
- Sizing constants for sign/planet glyphs, gold tone, sector tints, aspect colours/dashes, Roman numerals, stellium stagger, cusps loop.

## Tests
- pytest 70/70 (services/api-python, 71.5 s)
- Real PDF: `/tmp/astro-natalya-after-glyph-swap-iter3.pdf` (132.5 KB, 2 pages, clean)

## Recommendation to TL
Open `/tmp/astro-natalya-after-glyph-swap-iter3.pdf` pp.1-2; for hi-res visual review there are PNG renders at `/tmp/astro-iter3-v3-01.png` (page 1, solar wheel) and `/tmp/astro-iter3-v3-02.png` (page 2, natal wheel) at 250 DPI. ASC/MC/DSC/IC are now clearly readable at the four cardinal points; Saturn shows the canonical line-art form on both pages.
