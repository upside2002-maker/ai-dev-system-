# HANDOFF: worker → tl — debug-artifact-removal-from-synthesis

- Status: closed
- Date: 2026-05-08 15:34
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code (TL session, inline Worker)
- Model: Claude Opus
- Role mode: TL inline-Worker
- TASK: project-overlays/astro/TASKS/2026-05-08-debug-artifact-removal-from-synthesis.md

## Summary

**Execution isolation: same-session TL inline accepted (Tier C mechanical).** Reason: один файл template + точечная f-string правка, no logic / schema / migration, pytest 70/70 acceptance. Per `policies/MODES.md` § light.

Commit `astro:08bdda8` (parent `ea71e4c`), 2 files changed, +7/-72. pytest 70/70 → 70/70. Re-rendered Naташа PDF: 0 forbidden patterns (`интенсивность N` / `Окно N:` / `score N` / `+score` / `Показаны топ-10`). Pages 23 → 14 (drop = «Ключевые окна года» section removal, themed_synthesis блоки нетронуты).

## Done

- `services/api-python/app/pdf/synthesis_themes.py`: `windows_block` builder теперь генерирует «Чувствительный период с {start} по {end}; затрагивает темы: {tags}.» без `(интенсивность {score})` суффикса. Dead `score = w.get("score", 0)` удалён. Selection logic (theme-set overlap) intact.
- `services/api-python/app/pdf/templates/solar.html.j2`: вся секция «КЛЮЧЕВЫЕ ОКНА ГОДА» (комментарий + `<section>` block, 64 строки) удалена. «ИТОГИ КОНСУЛЬТАЦИИ» секция теперь напрямую следует за транзитным календарём.
- pytest verify: `70 passed in 25.58s` ✅
- PDF re-render: `/tmp/astro-natasha-after-cleanup.pdf` (117827 bytes, 14 pages).
- Forbidden-pattern grep на новом PDF: `pdftotext ... | grep -cE 'интенсивность [0-9]|Окно [0-9]+:|score [0-9]|\+score|Показаны топ-10 окон'` → **0 matches**.
- Cautions still rendered, но без числа: «Чувствительный период с 07.08.2025 по 05.08.2026; затрагивает темы: ...» (verified pdftotext sample).

## Artifacts

- branch: `main`
- commit: `astro:08bdda8` (`08bdda827d91260b250a2e13c445f415d7ae39dc`), parent `astro:ea71e4c`
- diff stat: 2 files, +7 / -72 (synthesis_themes.py, solar.html.j2)
- tests: pytest 70/70 green
- Product repo status: **committed (commit:08bdda8)** + backup pushed (`/Users/ilya/Backups/astro.git` HEAD `08bdda8`)
- Visual evidence: `/tmp/astra-natasha-current.pdf` (BEFORE, на `ea71e4c`) vs `/tmp/astro-natasha-after-cleanup.pdf` (AFTER)

## Conflicts / risks

Conflicts not found. Note for next TASK (`synthesis-themes-rewrite-toward-reference`): cautions list ещё содержит **дубликаты** — Python `windows_block` производит «Чувствительный период с X по Y; затрагивает темы: ...», а Haskell `Domain.SolarReportSkeleton.buildCautions` отдельно производит «Чувствительный период X – Y: вовлечена слабая натальная планета. Темы: ...». Оба попадают в render. Это **out of scope** этого debug-removal TASK — будет решено rewrite'ом.

## Next step

TL accepts через `make accept-handoff` + `make accept-task`. Reviewer не нужен (Mode light per policies/MODES.md). После этого: render-preview обновлённого PDF (вариант (b) пользователя) — у нас уже `/tmp/astro-natasha-after-cleanup.pdf`, можно показывать пользователю как product preview №2.
