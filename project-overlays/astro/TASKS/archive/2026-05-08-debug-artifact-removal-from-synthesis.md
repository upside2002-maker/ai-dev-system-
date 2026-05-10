# TASK: debug-artifact-removal-from-synthesis

- Status: done
- Ready: yes
- Date: 2026-05-08
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: light

## Problem

В клиентском PDF Наташи (`/tmp/astra-natasha-current.pdf` rendered на `ea71e4c`) утекают engine-internal метрики из `priority_windows`: «Окно N: ... score 709», «+score» столбец таблицы, «Чувствительный период с X по Y (интенсивность 709); затрагивает темы: ...», footer «Показаны топ-10 окон по score из N обнаруженных». Reference Marina (`Соляр 2025-2026_5.pdf`) **не имеет** ни секции «Ключевые окна года», ни любых score-чисел в тексте. Это пункт #7 feedback'а Марины — самый раздражающий артефакт. Mechanical fix: удалить всю debug-секцию template + убрать `(интенсивность {score})` из synthesis-cautions.

## Files

- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2` — удалить секцию «КЛЮЧЕВЫЕ ОКНА ГОДА» целиком (комментарий + `<section>` блок, строки ~674-737)
  - `services/api-python/app/pdf/synthesis_themes.py` — строка 433: убрать `(интенсивность {score})` из f-string в `windows_block` builder. Селектор `score = w.get("score", 0)` (строка 420) удалить как dead code.

## Do not touch

- `core/astrology-hs/**`, `packages/**`, `data/**`, `apps/**`, остальные `pdf/*.py` (особенно `transit_themes.py` с легитимным «интенсивных психологических курсов» — это narrative, не debug).
- Selection logic: `set(w.get("themes")) & priority_themes` фильтр оставляем — окна продолжают участвовать в выборке для cautions, просто без числа.
- `consultation_skeleton` JSON wire-format — не трогаем.

## Acceptance

- [ ] `pytest` 70 passed / 0 failed (Python projector edit, golden cases не затронуты).
- [ ] Re-render Naташа case (consultation 9) → `/tmp/astro-natasha-after-cleanup.pdf`. `pdftotext ... | grep -E 'интенсивность [0-9]|Окно [0-9]+:|score [0-9]|\+score|Показаны топ-10 окон'` → 0 matches.
- [ ] Diff scope: ровно 2 файла в HEAD (`solar.html.j2`, `synthesis_themes.py`). `git show --stat HEAD` подтверждает.
- [ ] 1 atomic commit поверх `ea71e4c`. `git log --oneline ea71e4c..HEAD` = 1 строка.
- [ ] Backup parity: `git ls-remote backup main` == local HEAD.
- [ ] Cautions всё ещё рендерятся в client PDF — но без `(интенсивность N)` суффикса. Verify через `pdftotext ... | grep 'Чувствительный период'` показывает entries без числа.

## Context

- Mode `light` (default для Tier C); same-session TL inline execution accepted per `policies/MODES.md` § light с body-marker в HANDOFF: `Execution isolation: same-session TL inline accepted (Tier C mechanical)`.
- Reviewer **не нужен** (Tier C light, mechanical removal).
- Baseline: `astro:ea71e4c` (Phase 0.10c-b literary synthesis), pytest 70/70.
- Reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` (Marina's actual report, 29 страниц) — в нём ни «Ключевые окна года» секции, ни score-чисел.
- Next TASK по плану: `synthesis-themes-rewrite-toward-reference` (Tier B, переписать `themed_synthesis` под reference shape с ЛИЧНОСТЬ темой и concrete narrative). Этот TASK — узкий точечный фикс mess'а перед structural rewrite.
