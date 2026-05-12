# HANDOFF: worker → tl — transit-presentation-rebuild-marina-format (iter-2: quincunx filter)

- Status: closed
- Date: 2026-05-12 15:30
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-12-transit-presentation-rebuild-marina-format.md
- Parent HANDOFF: HANDOFFS/2026-05-12-worker-to-tl-transit-presentation-rebuild-marina-format.md

## Summary

Tochechный follow-up к presentation rebuild (commit `9f47f45`). Owner directive: после rebuild раздел «Транзиты» структурно совпадает с Marina, но в календаре было >15 квинконсов (150°) — у Marina pp. 19-23 показан **ровно один** «Уран 150° Юпитер». Patch: presentation-фильтр для 150° (не engine math) — 1 файл `transit_themes.py`, +105 строк (50 кода + 55 комментариев), engine не тронут.

## Done

- **`services/api-python/app/pdf/transit_themes.py`** (`+105` lines, all additive):
  - Добавлена константа `_QUINCUNX_MAX_DISPLAY_ORB = 0.7°` — per-aspect display-orb threshold для quincunx, применяемый ТОЛЬКО к 150° (остальные аспекты идут как раньше).
  - Добавлена `_OUTER_TRANSIT_PLANETS = {Uranus, Neptune, Pluto}` — class-фильтр.
  - Добавлен `_PLANET_MEAN_SPEED` table (deg/day, Sun=0.985 ... Pluto=0.004) — используется для peak-orb estimate.
  - Добавлен `_TRANSIT_CLASS_ORB` table (mirror Haskell `Domain.TransitCalendar.transitOrbForPlanet`) — Pluto=1.25°, остальные=1.0°. Помечен SOT-mirror в комментарии.
  - Добавлена функция `_quincunx_passes_display_filter(tp, target, window_days)` с recipe:
    1. transit planet ∈ outer (Uranus/Neptune/Pluto)
    2. target ∉ outer (отсекает «Уран 150° Плутон», «Уран 150° Нептун» — outer→outer)
    3. estimated peak orb ≥ `_QUINCUNX_MAX_DISPLAY_ORB` (0.7°), где peak_orb_est = max(0, class_orb − window_days × speed / 2)
  - Вшит фильтр в `transit_aspects_by_month` сразу после `_MIN_WINDOW_DAYS` check (`if asp == "Quincunx" and not _quincunx_passes_display_filter(...): continue`). Остальные аспекты bypass.

- **Calibration rationale** (для записи threshold = 0.7°):
  - Marina-shown quincunx: Uranus 150° Jupiter, 16.06–29.07.2026, width 43.4d → peak_est = 1.0 − (43.35 × 0.012) / 2 = **0.74°** → проходит порог 0.7.
  - Worst noise сосед: Neptune 150° Venus, drift-only, width 114d → peak_est = 1.0 − (114.22 × 0.006) / 2 = **0.66°** → не проходит.
  - Окно [0.66, 0.74] — есть ~0.04° запас с обеих сторон, threshold 0.7° даёт стабильное разделение.
  - Низшие thresholds (0.5°, 0.6°) пропускают Neptune 150° Venus drift-only — нежелательно. Высшие (0.75°+) рискуют отсечь Marina-shown.

- **Test suite**: `cd services/api-python && pytest` → **85/85 green** (включая `tests/test_transit_aspects_tables.py::test_calendar_includes_quincunx_when_present` — тест проверяет shape ЕСЛИ quincunx есть, а не количество, поэтому совместим с фильтром).

## Verification (case-8 Натальи fixture, in-solar-year)

Все 19 quincunx-кандидатов (после `_MIN_WINDOW_DAYS=7` filter):

| Hit | Result | Why |
|---|---|---|
| Uranus 150° **Jupiter** 16.06-29.07.2026 | **KEEP** | outer→non-outer, peak_est 0.74° ≥ 0.7 |
| Uranus 150° Pluto 24.10.25-13.12.25 | SKIP | target Pluto is outer |
| Uranus 150° Pluto 26.03-05.05.2026 | SKIP | target Pluto is outer |
| Uranus 150° Neptune 09.11.25-01.01.26 | SKIP | target Neptune is outer |
| Uranus 150° Neptune 09.03-25.04.2026 | SKIP | target Neptune is outer |
| Neptune 150° Pluto 01.10.25-14.02.26 | SKIP | target Pluto is outer |
| Neptune 150° Venus 13.10.25-04.02.26 | SKIP | peak_est 0.66° < 0.7 (drift-only) |
| Saturn 150° Pluto (×2) | SKIP | tp Saturn not outer |
| Saturn 150° Venus (×2) | SKIP | tp Saturn not outer |
| Saturn 150° Saturn | SKIP | tp Saturn not outer |
| Saturn 150° Mercury | SKIP | tp Saturn not outer |
| Saturn 150° Asc | SKIP | tp Saturn not outer |
| Jupiter 150° Moon (×3) | SKIP | tp Jupiter not outer |
| Jupiter 150° Neptune | SKIP | tp Jupiter not outer |
| Jupiter 150° Jupiter | SKIP | tp Jupiter not outer |

→ **1 / 19** survives. PDF проверен `pdftotext` — в «Календарь транзитных аспектов» 150° встречается ровно в двух bucket'ах (Июнь 2026, Июль 2026 — окно спанит оба месяца), оба «Уран 150° Юпитер». Остальные аспекты (60°/90°/120°/0°) — count 8/20/20/56 в календарной секции, **не затронуты**.

## Artifacts

- branch:               `claude/dreamy-moore-46f5eb` (worktree `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`)
- commit(s):            `dec0f5d` (поверх `9f47f45`) → push backup OK
- PR:                   нет (Tier C, backup-mirror flow)
- tests:                85/85 green
- New PDF:              `/tmp/astro-natalya-quincunx-filter-iter1.pdf` (140 KB)
- Render harness:       `/tmp/render_natalya_quincunx_filter.py` (10 строк wrap вокруг `app.pdf.builder.write_solar_pdf` + Natalya input/expected fixtures)
- Marina reference:     `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 19-23
- Product repo status:  **committed**

## Conflicts / risks

- **Threshold sensitivity.** 0.7° даёт ~0.04° запас с обеих сторон от Marina-keeper. Если на другой fixture Marina покажет quincunx с peak_est ниже 0.7°, threshold потребует пересмотра (повысить запас или комбинировать с дополнительным класс-фильтром). На данный момент валидировано только на case-8 Натальи (это единственная fixture с Marina ground-truth для quincunx).
- **`_TRANSIT_CLASS_ORB` дублирует Haskell SOT.** В `transit_themes.py` есть mirror Pluto=1.25°, остальные=1.0° — синхронизирован с `core/astrology-hs/src/Domain/TransitCalendar.hs::transitOrbForPlanet`. Если TL поменяет engine orb, нужно обновить и здесь (отметил в docstring).
- **Engine не тронут.** Bright lines #1-7 preserved: `core/`, `packages/contracts/`, `packages/rulesets/`, `packages/test-fixtures/` — 0 changes. Только presentation в Python services.

## Next step

TL inline-сравнивает `/tmp/astro-natalya-quincunx-filter-iter1.pdf` с Marina reference pp. 19-23 (раздел «Календарь транзитных аспектов»). Ожидаемое: один quincunx «Уран 150° Юпитер» — присутствует в Июнь + Июль 2026 (окно 16.06–29.07.2026 спанит оба). Остальные аспекты в календаре не изменились.
