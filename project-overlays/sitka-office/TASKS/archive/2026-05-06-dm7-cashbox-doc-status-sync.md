# TASK: dm7-cashbox-doc-status-sync

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: sitka-office
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code (sitka-worker subagent)

## Problem

`docs/DM-7-cashbox.md` отстал от текущего состояния sitka-office на 7 дней. Header помечен `Last updated: 2026-04-29` и говорит "Phase A/B/C Core в репе (PR #63-72), Phase C Frontend и Phase D — впереди". Реально:
- Phase C Frontend закрыт целиком (PR #74-78)
- Production live на `94.72.112.106:8088` после deploy fixes #79/#80
- Phase D scope **ещё не зафиксирован** в этом документе
- Существует active TASK `2026-04-29-dm7-c-backend-widget-prereq` (Status: open, Ready: no — заблокирован) как prereq будущего Phase D widget breakdown

Документ — **source of truth по дизайну cashbox**, его читают новые сессии. Stale статус приводит к запутыванию и потере контекста.

## Scope

В скоупе:
- Header (lines ~1-7): обновить "Last updated" + блок про Phase status под актуальную реальность.
- Таблица "Фазы внедрения" (line ~53): добавить недостающие строки — Phase C Core (#72/#73), Phase C Frontend (#74/#75/#76/#77/#78), Phase D (TBD/scoped). Существующие строки (Phase A, B-1/B-2/B-3) не трогать — они корректны.
- Параграф про active backend-widget-prereq как Phase D prereq: где-то после таблицы фаз или в Phase D section добавить упоминание что есть TASK `2026-04-29-dm7-c-backend-widget-prereq` (Status: open, Ready: no) — он расширяет `Api.TransactionResp` полем `trExpenseCategoryId :: Maybe Int64` для будущего widget breakdown по `expense_category.kind`. Сейчас blocked, ждёт TL go.

Вне скоупа:
- Любые архитектурные изменения content'а (формула `csExpectedMargin`, lifecycle reservation, инварианты — НЕ трогать)
- Phase A / Phase B-1 / Phase B-2 / Phase B-3 секции (они корректны)
- Phase C section line ~274 (если уже есть — оставить как есть, не переписывать)
- Любой код вне `docs/`

## Files

- new:    (none)
- modify: `/Users/ilya/Projects/sitka-office/docs/DM-7-cashbox.md`
- delete: (none)

## Do not touch

- `/Users/ilya/Projects/sitka-office/sitka-core/**`
- `/Users/ilya/Projects/sitka-office/sitka-services/**`
- `/Users/ilya/Projects/sitka-office/sitka-web/**`
- Любой файл вне `Files` секции выше
- Архитектурные decisions описанные в DM-7-cashbox.md (формула snapshot, lifecycle reservation, инварианты)
- Phase A / B-1 / B-2 / B-3 строки таблицы
- Resolved invariants secция (line ~185+) — это history, не переписываем

## Acceptance criteria

- [ ] `Last updated:` строка показывает `2026-05-06` (или текущую дату)
- [ ] Header status block отражает реальность: Phase C закрыт целиком (Core + Frontend), production live на `94.72.112.106:8088`, Phase D scope не зафиксирован
- [ ] Таблица "Фазы внедрения" имеет строки для Phase C Core (PR #72) и Phase C Frontend (PR #74-78); статус ✅ закрыты
- [ ] Таблица имеет строку для Phase D с пометкой "scope не зафиксирован" или "TBD"
- [ ] В документе явно упомянут active TASK `2026-04-29-dm7-c-backend-widget-prereq` как Phase D prereq (где-то после таблицы фаз; короткий параграф 2-3 предложения)
- [ ] Никаких изменений в Phase A / B-1 / B-2 / B-3 строках таблицы
- [ ] Никаких изменений вне `docs/DM-7-cashbox.md`
- [ ] Markdown синтаксис валидный (заголовки, table cells, ссылки)

## Test commands

```bash
# В repo /Users/ilya/Projects/sitka-office:
git diff docs/DM-7-cashbox.md   # проверить scope diff
git status --short              # должен показать только M docs/DM-7-cashbox.md
```

Никаких cabal test / pytest / npm — это docs-only TASK.

## Handoff requirements

В HANDOFF Worker фиксирует:
- **Done**: какие конкретно секции/строки обновлены (header, фазы table, параграф про backend-widget-prereq); diff stat
- **Artifacts**: branch (если делал отдельную; для docs Tier C можно работать в working tree без отдельной ветки), commit SHA если коммитил
- **Conflicts/risks**: None expected; если потребовалось трогать что-то вне scope — flag это явно и **не делай** без возврата в TL
- **Next step**: TL читает HANDOFF, optional Reviewer pass, потом `make accept-handoff` + `make accept-task`
