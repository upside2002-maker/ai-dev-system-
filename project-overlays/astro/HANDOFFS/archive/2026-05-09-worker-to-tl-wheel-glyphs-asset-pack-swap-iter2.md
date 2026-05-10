# HANDOFF: worker → TL — wheel-glyphs-asset-pack-swap (iteration 2)

- Status: closed
- Date: 2026-05-09
- From: Worker (Claude Code subagent, separate session, iteration 2)
- To: TL
- Project: astro
- TASK: 2026-05-09-wheel-glyphs-asset-pack-swap
- Worker commit (iter 2): `666c995` (parent `9d452dd`)
- Agent runtime: Claude Code (Worker subagent, iteration 2 — fresh session after iter-1 stream timeout)
- Role mode: Worker (Mode normal — Tier B)

## Summary

Iter-1 (9d452dd) shipped wheel-glyphs-asset-pack-swap; Owner reviewed and flagged 2 defects. Iter-2 fixes both with a single atomic commit, scope-locked to wheel.py + wheel_glyphs.py + build_wheel_glyphs.py. Pytest 70/70, real-PDF render clean.

## Fix 1 — Saturn

- Diagnosis: Astronomicon's `W` glyph (extracted by build script for `Saturn` per `GLYPH_MAP`) renders as a stylized "5" / "ち" — top horizontal crossbar plus an S-curve below, with NO descending vertical bar and NO bottom-right sickle hook. This is non-canonical; the canonical Saturn ♄ has three distinct components (vertical bar through the symbol, horizontal crossbar near the top, sickle/hook curving down-and-right at the bottom of the vertical bar). Verified by: (a) reading `/tmp/astronomicon-charset-wide.pdf` (multimodal Read), (b) rendering letters V/W/X/Y individually via WeasyPrint to `/tmp/letter-check.pdf` to confirm shapes, (c) confirming no other Astronomicon letter holds canonical Saturn. Therefore fallback Option 3 (hand-crafted path) was the correct choice.
- Fix: Added a `HAND_CRAFTED_OVERRIDES: dict[str, str]` in `build_wheel_glyphs.py` with a canonical Saturn path authored directly in the `-12..+12` viewBox: vertical bar `M-0.7 -9 → 0.7 4`, horizontal crossbar `-4.5..4.5 at y≈-7`, sickle hook from the bottom of the vertical bar curving down-right and back up. Applied AFTER font extraction in `main()` so the override fully replaces the auto-extracted W path. Build script re-run regenerates `wheel_glyphs.py` with the override baked in. The other 24 glyphs (Sun, Moon, Mercury, Venus, Mars, Jupiter, Uranus, Neptune, Pluto, 12 zodiac signs, NorthNode, SouthNode, Lilith) continue to come from Astronomicon unchanged. The override mechanism is documented with a long docstring explaining when and why to use it, so future glyph corrections have a clear paved path.
- Verification: real-PDF render (`/tmp/astro-natalya-after-glyph-swap-iter2.pdf`) — Saturn now reads as canonical ♄ on **page 1** (solar wheel, bottom-right cluster next to Mars ♂ at `0°04'`) and **page 2** (natal wheel, bottom cluster at `23°08'`). Both pages confirmed visually.

## Fix 2 — Main axes

- Implementation: Replaced the short angular-cusp highlight in the cusps loop (was `#c0392b` red, width `1.4`, drawn from `r_inner_circle` to `r_house_outer` only at houses 1/4/7/10) with a dedicated full-diameter through-center axis pass after the inner reference circle and before aspect lines. For each of `(asc, mc)` we draw a single line from `r_outer` through the centre to `r_outer + 180°`, stroke `#000000`, width `2.4`, `stroke-linecap="round"`. The cusps loop now uses the standard non-angular treatment for all 12 houses (`#a0a4a8`, width `0.6`).
- Z-order rationale (preserved as a comment in the code): main axes drawn after cusp gridlines (axes sit above cusps) and before aspect lines (aspects sit above axes in the centre cluster). This keeps the dense aspect web readable while making ASC/DSC/MC/IC the chart's primary structural feature on first glance.
- Verification: real-PDF — both pages show full-diameter black axes that visually dominate the chart structure. ASC/MC labels at the outer edge stay as-is (out of scope for this fix).

## Tests

- pytest: **70/70 passed** in 11.51s.
- Real PDF: `/tmp/astro-natalya-after-glyph-swap-iter2.pdf` (129.7 KB).
- WeasyPrint render: clean (no abort, no warnings).
- `git status` after commit: clean.

## Files touched (3)

- `services/api-python/app/pdf/wheel.py` — cusps loop (drop angular-highlight branch); insert main-axes pass.
- `services/api-python/app/pdf/wheel_glyphs.py` — auto-regenerated; `Saturn` entry now hand-crafted.
- `services/api-python/scripts/build_wheel_glyphs.py` — added `HAND_CRAFTED_OVERRIDES` mechanism + Saturn entry; comment on `Saturn: "W"` in `GLYPH_MAP` pointing to the override.

## Recommendation to TL

Open `/tmp/astro-natalya-after-glyph-swap-iter2.pdf` pp. 1-2; side-by-side with Marina reference + Owner's reference image. Both fixes are visible at first glance — Saturn ♄ now shows the three canonical components, and the ASC-DSC / MC-IC axes are the dominant structural feature. If Owner accepts, this closes iter-2; if Saturn proportions need tuning (hook size, crossbar position), the override is one path string in `build_wheel_glyphs.py:HAND_CRAFTED_OVERRIDES["Saturn"]` — trivial to iterate.
