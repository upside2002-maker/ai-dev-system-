# TASK: status-ru-split-live-journal

- Status: done
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: TL (docs-правка, class C light — без Worker/Reviewer)
- Mode: light
- Critical approved by: (нет — class C не требует)

## Problem

Задача №2 из MAILBOX 2026-06-06. `STATUS_RU.md` раздулся до 953 строк с обилием англо-жаргона — нарушение `policies/OPERATOR_LANGUAGE.md` (файл должен читаться за 30 секунд) и свежего замка `check-status-hygiene.sh` (лимит 150 строк). Плюс задвоенные записи и устаревшая дата в шапке. Нужно развести «живой статус» (≤1 экран, человеческим языком, замещается) и «журнал» (append, технический).

## Что сделано (TL, выполнено в этой задаче)

1. Вся история (953 строки) перенесена в `OPERATING/journal/2026-05.md` (по образцу sitka-office; охватывает апрель–июнь 2026), с пометкой-шапкой что это архив.
2. `STATUS_RU.md` переписан с нуля: **32 строки**, человеческий язык, без англо-жаргона. Разделы: что работает / сейчас / в очереди / известные долги / как посмотреть вживую.
3. Замок `check-status-hygiene.sh astro` проходит: «32 строк (лимит 150) — читаемо», предупреждения о жаргоне нет.

## Files

- new: `project-overlays/astro/OPERATING/journal/2026-05.md` (перенесённый архив истории).
- modify: `project-overlays/astro/STATUS_RU.md` (переписан, 953 → 32 строки).
- delete: —

## Do not touch

- Продуктовый код, контракты, движок — это чисто docs.
- Содержание истории — переносится дословно, не редактируется (только шапка-пометка).

## Acceptance

- [x] `STATUS_RU.md` ≤ 150 строк (факт: 32).
- [x] `check-status-hygiene.sh astro` → OK, без жаргон-предупреждения.
- [x] История сохранена дословно в `OPERATING/journal/`.
- [x] Живой статус — человеческим языком, читается за 30 секунд.

## Context

- MAILBOX `to-tl-astro.md` 2026-06-06, задача №2 (ADS-BLOAT-1).
- Замок: `scripts/check-status-hygiene.sh` (Correction-замок #3, методология).
- `policies/OPERATOR_LANGUAGE.md`.
- Образец журнала: `project-overlays/sitka-office/OPERATING/journal/`.

**Ready: yes** — выполнено в одном проходе TL (class C light). Закрытие сразу.
