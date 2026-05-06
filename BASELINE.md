# BASELINE — AI Dev System v0.1 smoke baseline

Дата: 2026-05-06
Tag:  `ai-dev-system-v0.1-smoke`

Этот файл фиксирует точку, в которой AI Dev System (этот репозиторий)
**доказал жизнеспособность как механизм**, но ещё **не доказал
воспроизводимость**. Baseline нужен, чтобы следующий PR (system-fix)
не размылся и можно было `git diff` против этого тега.

## Что зафиксировано как v0.1

- **Phase A "cement"**: 3 системных drift'а закрыты — date sync (
  CURRENT_STATE / NEXT_ACTIONS / KNOWN_ISSUES в overlay'е), header
  canonicalization (templates/ + scripts/new-task.sh + scripts/new-handoff.sh
  выровнены, активный TASK мигрирован), accept-task lifecycle gate
  (`scripts/accept-task.sh` требует `Status=review` AND `Ready=yes`).
- **Phase B smoke**: end-to-end прогон агентной цепочки на реальном
  docs-only TASK `2026-05-06-dm7-cashbox-doc-status-sync` (Sitka
  product repo, Tier C). TL → Worker → HANDOFF → TL accept прошёл,
  Worker self-flagнул scope-creep ("Prod deploy" row), даты
  скорректированы перед accept, оба helper'а (`accept-handoff` +
  `accept-task`) отработали с честным lifecycle-check.

## Что найдено как реальные слабости (не теория, а факты smoke'а)

1. **Worker не двигает Status TASK** — закончил работу, записал
   HANDOFF, TASK остался `open`. TL ручным edit'ом перевёл в `review`
   перед `accept-task`. См. `corrections/global-corrections.md` →
   Correction 008.

2. **Reviewer возвращает отчёт через stdout, не через файл** — нет
   `HANDOFFS/<date>-reviewer-to-tl-*.md`, audit trail review-pass'а
   исчезает с концом сессии. См. Correction 009.

3. **Worker сконфабулировал даты PR'ов** в design doc — написал из
   памяти `2026-04-29 → 2026-05-04` вместо реальных
   `2026-05-01 → 2026-05-02` (verified `git log --grep`). TL поправил
   до accept; иначе drift попал бы в source-of-truth design doc. См.
   Correction 010.

4. **Cross-repo state machine не закрыта policy** — TASK был принят в
   AI Dev System (`Status: done`, файл в `archive/`), а product repo
   (`/Users/ilya/Projects/sitka-office`) остался dirty с
   незакоммиченным `M docs/DM-7-cashbox.md`. AI Dev System говорил
   "закрыто", git product repo — "не сохранено". Закрыто отдельным
   коммитом в sitka-office (branch `docs/dm7-cashbox-status-sync`),
   перед этим baseline'ом.

## Что НЕ входит в этот baseline

- `submit-task.sh` ещё не написан.
- Reviewer agent instructions ещё не требуют файлового HANDOFF'а.
- Шаблоны не требуют evidence (git short hash) рядом с PR-датами.
- Product repo status — не зафиксированное поле в HANDOFF.

Эти 4 пункта — scope **следующего** PR (system-fix), не v0.1.

## Следующий шаг

System-fix PR: чинит механику (submit / reviewer file-handoff /
evidence rule / product-repo-status field), потом retry на маленькой
AI-Dev-System-internal docs-задаче с явными acceptance criteria что
новая механика отработала **без manual edits** между Worker submit
и TL accept.

После успешного retry — можно открывать новый Sitka product TASK.
До retry — нет.

## Зачем этот файл

Без явного checkpoint'а "v0.1" любой следующий PR висел бы в воздухе:
непонятно, какие gap'ы он чинит, что считалось работающим до него,
что считается фиксацией прогресса. Tag `ai-dev-system-v0.1-smoke`
плюс этот файл закрывают вопрос — против чего сравнивать diff
system-fix'а.
