# TASK: wheel-glyphs-asset-pack-swap

- Status: done
- Ready: yes
- Date: 2026-05-09
- Project: astro
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: normal

## Problem

В клиентском PDF верхняя графика (натальное и солярное колёса, `services/api-python/app/pdf/wheel.py`) использует **22 hand-drawn approximation глифа** (планеты + знаки), эмиттящихся через `<defs>+<symbol>+<use>` SVG pattern. Owner и Marina воспринимают эти глифы как «kustarny / school-notebook approximations». Reference image (предоставлен Owner'ом, провенанс свой/clean) показывает целевую эстетику: **gold zodiac (bold) + white planets (thin) + classical Unicode-canonical shapes**. 

Цель: заменить hand-drawn `_GLYPH_SVG` на профессиональный path-based glyph set, визуально близкий к reference.

## Approach (decided pre-spawn)

**Primary path: Astronomicon Fonts v1.1 (OFL) → SVG paths via build script.** Картинка остаётся style anchor для размеров/spacing/color, не как pixel source. Reasoning: vector source = crisp, OFL = clean license, single TTF = full coverage including Lilith/Nodes/retrograde впрок. Fallback path: hand-trace from reference if A/B preview шоит, что Astronomicon стилистически не дотягивает.

**A/B mandate в первой итерации**: Worker до full implementation делает side-by-side preview одного представительного glyph'а (Aries) — Astronomicon-converted vs hand-traced — embed'ит оба в HANDOFF вместе с recommendation. Если direction clearly favors one — Worker proceed'ит. Если ambiguous — flag в HANDOFF и ждёт TL/Owner verdict перед full 22-glyph commit'ом.

## Files

- modify:
  - `services/api-python/app/pdf/wheel.py:58-111` — заменить hand-drawn `_GLYPH_SVG` dict на 22+ path-based записи из Astronomicon (или hand-trace, если A/B повернёт). **Сохранить current architecture**: `<defs>+<symbol>+<use>` pattern, `viewBox="-12 -12 24 24"`, `currentColor` для CSS-driven coloring.
  - `services/api-python/app/pdf/wheel.py:255-340` (region of `render_chart_wheel_svg` где emit'ятся zodiac sectors / planet glyphs) — добавить дифференциацию `stroke-width` zodiac vs planet (для воспроизведения reference style hierarchy: bold zodiac, thin planets) и color-токены (gold для zodiac sector glyphs, white/dark для planet glyphs).
  - `services/api-python/app/pdf/wheel.py:308-309` — параметры `sign_glyph_size = size * 0.058` / `planet_glyph_size = size * 0.064` могут потребовать tuning после нового glyph stroke-weight'а.

- add (если выбран Astronomicon path):
  - `services/api-python/scripts/build_wheel_glyphs.py` — build script: загружает `Astronomicon.ttf`, конвертит каждый нужный glyph в SVG path через `fontTools.pens.svgPathPen.SVGPathPen`, дампит в Python module / JSON, импортируемый из `wheel.py`. ≤100 строк. Запускается one-shot, output committed в репо (не runtime dependency).
  - `services/api-python/app/pdf/assets/Astronomicon.ttf` — original font file (~31KB)
  - `services/api-python/app/pdf/assets/OFL-License.txt` — license text from font ZIP

- add (если выбран hand-trace path):
  - `services/api-python/scripts/trace_reference_glyphs.py` — automation script (Potrace или similar), output committed
  - Reference image: где Owner сохранит PNG (Worker уточнит у TL при спавне)

## Do not touch

- `core/astrology-hs/**`, `packages/**`, любые fixtures, JSON-схемы — pure presentation TASK
- `apps/web-react/**` — React wheel renderer не входит в scope этой итерации
- Wheel layout math: `_polar`, `_lon_to_screen_deg`, `_annular_sector_path`, stellium stagger logic (lines 431-513) — корректны, не трогать
- `_ASPECT_COLOUR`, `_ASPECT_DASH`, `_SIGN_TINT` — комментарии говорят «matches reference idiom», не трогать
- Cardinal labels ASC/MC/DSC/IC, Roman numerals (lines 515-526) — работают через ASCII `<text>`, не трогать
- Lilith / NorthNode / SouthNode data emission — engine пока не эмиттит эти planets, **glyphs можно подготовить впрок в asset set**, но не рендерить в wheel'е до отдельного Tier A `solar-nodes-lilith-retro-display`
- `apps/web-react/`, `services/api-python/app/pdf/synthesis_themes.py`, `transit_themes.py`, `direction_themes.py`, `house_pair_themes.py` — out of scope

## Constraints

- **WeasyPrint 68.1 SVG-text U+26xx bug** (см. comment в `wheel.py:45-52`): нельзя использовать Unicode astrology glyphs через `<text>♈</text>` — поломает render всех subsequent SVG elements. Все glyphs должны остаться **path-based** в `<defs>+<symbol>+<use>` форме.
- **Не использовать кириллицу/text-суррогаты** для глифов
- **Сохранить `currentColor`** в SVG paths — позволяет CSS-driven recoloring (gold zodiac vs white planets)
- License compliance: OFL-License.txt **must** ship в репо рядом с TTF при выборе Astronomicon path

## Acceptance

- [ ] **Phase 1 (A/B preview)**: Worker submit'ит HANDOFF с рендером **одного** glyph'а (Aries) в обоих вариантах: (a) Astronomicon-converted, (b) hand-traced from reference image. Embed'ит оба SVG в HANDOFF + краткий recommendation. Если clearly Astronomicon win → Worker proceed'ит без TL escalation. Если ambiguous → HANDOFF в Status: open с явным "awaiting Owner choice" — TL escalation.
- [ ] **Phase 2 (full implementation)**: после A/B verdict — full 22+glyph swap в `_GLYPH_SVG`. Tuning sizing/spacing/color hierarchy под reference. Real-PDF render Натальи (case 8) на новом HEAD'е → `/tmp/astro-natalya-after-glyph-swap-<HEAD>.pdf`. PDF embed'ится в HANDOFF (либо path) для TL visual review.
- [ ] `pytest` 70 passed / 0 failed (template-level + wheel.py-level edits, no Python logic touched).
- [ ] `git status --short` после commit'а: clean. Коммиты атомарные: build script + assets + `_GLYPH_SVG` swap + sizing tuning — отдельными коммитами или одним atomic'ом по choice Worker'а, **но** все commit'ы должны быть в scope ровно `services/api-python/app/pdf/**` + `services/api-python/scripts/**`.
- [ ] `git diff <baseline>..HEAD` показывает touched файлы только из § Files.
- [ ] OFL-License.txt присутствует в репо если выбран Astronomicon path.
- [ ] Real-PDF render Натальи рендерится без поломок (no WeasyPrint render abort, no missing glyphs, no fallback boxes).

## Embedded TL review checklist (TL inline review, no separate Reviewer subagent per Mode normal)

- [ ] Architecture preserved: `<defs>+<symbol>+<use>` pattern, viewBox 24×24, `currentColor` для recoloring
- [ ] No Unicode `<text>` для astro glyphs (WeasyPrint constraint)
- [ ] Stroke-width hierarchy: zodiac visibly bolder than planets (matches reference)
- [ ] Color hierarchy: zodiac gold-tinted, planets white/dark (CSS-driven через `currentColor`)
- [ ] License file present и пара "asset + license" coherent
- [ ] Все 22 minimum glyphs (10 planets + 12 signs) переведены, no regressions
- [ ] Real PDF render side-by-side с Marina reference (`/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` p. 1-2 wheel pages) — TL verdict «выглядит профессионально / близко к образцу»
- [ ] No spillover: directions/transits/итоги/PDF-prose untouched
- [ ] Phase 1 A/B preview добросовестно представлен (не cherry-picked one direction)

## Context

- **Mode normal** (Tier B); Worker subagent **mandatory** (separate session, fresh memory). TL inline review OK без формального Reviewer subagent. HANDOFF Worker→TL обязателен.
- Baseline: `astro:876cdfe` (Tier C #2 prose fix), pytest 70/70, working tree clean, 0 active TASKs.
- Reference image: предоставлен Owner'ом в чате, провенанс свой/clean. **Style anchor**: gold zodiac (bold) + white planets (thin), classical Unicode-canonical shapes, professional non-handcrafted look. Worker может запросить у TL прямой PNG на диске если нужен для tracing/comparison.
- Asset pack recon (предыдущая сессия TL): top pick **Astronomicon Fonts v1.1**, OFL, https://astronomicon.co/AstronomiconFonts_1.1.zip, single TTF ~31KB, full coverage (22 glyphs + Lilith/Nodes/Chiron/retrograde впрок), minimalist single-weight strokes.
- WeasyPrint constraint: см. `wheel.py:45-52` comment — TTF font через `@font-face` + `<text>` НЕ работает (silent render abort на U+26xx codepoint). Path-based via `<defs>+<symbol>+<use>` — единственный stable путь.
- Conversion approach (рекомендуемый): `fontTools.pens.svgPathPen.SVGPathPen`. Standard Python tool, ~50 строк скрипта на TTF→SVG path extraction.
- Lilith/Nodes glyphs **готовим в asset set впрок** (Astronomicon уже coverс'ит), но **не подключаем в wheel render** до отдельного Tier A `solar-nodes-lilith-retro-display` (data-side extension Planet ADT).

## References

- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` p. 1-2 (wheel pages — visual style ground-truth)
- Owner reference image (chat-attached): style anchor — gold zodiac + white planets
- Current implementation: `services/api-python/app/pdf/wheel.py:58-111` (`_GLYPH_SVG` dict)
- Render entry points: `services/api-python/app/pdf/templates/solar.html.j2:201` (solar) + `:234` (natal)
- Standalone render harness (для real-PDF gate): `/tmp/render_natalya_2ffa002.py` (модифицируется под current HEAD)
- Asset pack source: https://astronomicon.co/AstronomiconFonts_1.1.zip + https://scripts.sil.org/cms/scripts/page.php?item_id=OFL_web
- Fontools docs: https://fonttools.readthedocs.io/en/latest/pens/svgPathPen.html

**Execution isolation**: Worker subagent (separate session, fresh memory) per Mode normal Tier B. Worker submit'ит HANDOFF после Phase 1 A/B preview (если ambiguous) или после полной Phase 2 implementation (если direction clear). TL inline review per embedded checklist выше; sign-off — Owner via TL relay, side-by-side с Marina reference.
