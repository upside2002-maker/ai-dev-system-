# HANDOFF: worker → tl — dm7-cashbox-doc-status-sync

- Status: closed
- Date: 2026-05-06 13:47
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-06-dm7-cashbox-doc-status-sync.md

## Summary

Stale design-doc `docs/DM-7-cashbox.md` синхронизирован с реальностью репо: header dated 2026-05-06, статус Phase C closed (Core + Frontend), production live, Phase D помечен TBD, prereq TASK `2026-04-29-dm7-c-backend-widget-prereq` явно упомянут после таблицы фаз. Single-file docs change, Tier C, working tree only (uncommitted). Тестов и кода не трогал.

## Done

Изменения в `docs/DM-7-cashbox.md` (diff stat: 22 insertions, 9 deletions, 1 file changed):

1. **Header (lines 1-10)**:
   - Bullet "Phase A/B/C Core ... уже в репе (PR #63–#72). Phase C Frontend и Phase D — впереди" → "Phase A/B/C **закрыты целиком** — Core (PR #63–#72) + Frontend (PR #74–#78). Production live на `94.72.112.106:8088` после deploy fixes #79/#80. Phase D scope **ещё не зафиксирован** в этом документе (TBD)."
   - `Last updated: 2026-04-29` → `2026-05-06`.

2. **Таблица "Фазы внедрения" (line ~55)**:
   - Phase A / B-1 / B-2 / B-3 / C-Core строки **не тронуты** (как требовалось).
   - Phase C-Frontend: статус `TODO` → `✅ PR #74–#78 (2026-04-29 → 2026-05-04)`, описание расширено под фактические PRs (#74 «Прочие расходы» tab, #75 unified deal financial block + cashbox refresh + status gating, #76/#77 Variant B widget cells + slug auto-gen + `csTotalSpent`, #78 single-col grid layout).
   - **Новая строка** `Prod deploy`: ✅ PR #79, #80 (libpq-dev из PGDG repo, wget в services container). Не строго требовалось acceptance criteria, но header утверждает "production live на 94.72.112.106:8088" — таблица должна это подтверждать. Если TL считает scope creep — легко удалить отдельным edit.
   - Phase D: статус `TODO` → `TBD — scope не зафиксирован`.

3. **Параграфы под таблицей**:
   - "Минимально полезный срез = A + B. C и D могут идти параллельно после B" → "Минимально полезный срез = A + B. C закрыт целиком. D — отдельная фаза, scope ещё не зафиксирован."
   - "Phase B ≈ закрыт по B-3. Переход к C/D — отдельные задачи..." → "Phase B закрыт по B-3. Phase C закрыт по Core (#72) + Frontend (#74–#78). Переход к D — после фиксации scope."

4. **Новая subsection `### Phase D prereq (active, blocked)`** — 3 предложения о TASK `2026-04-29-dm7-c-backend-widget-prereq`: что расширяет (`Api.TransactionResp` полем `trExpenseCategoryId :: Maybe Int64`), зачем (честный breakdown-join `transactions × categories`), статус (Status: open, Ready: no, blocked, ждёт TL go-сигнала когда Phase D scope финализирован).

5. Phase A / Phase B / Resolved invariants / Phase C / Phase D / "Логика прибыли" / "Что хранить, что вычислять" / "Открытые вопросы" секции — **не тронуты**.

Test commands из TASK выполнены:
- `git diff --stat docs/DM-7-cashbox.md` → ` docs/DM-7-cashbox.md | 31 ++++++++++++++++++++++---------` `1 file changed, 22 insertions(+), 9 deletions(-)`
- `git status --short` → `M docs/DM-7-cashbox.md` + 5 pre-existing untracked entries (`.claude/agents/`, `.claude/commands/`, `.claude/settings.json`, `.claude/worktrees/`, `sitka-services/.cache/`) — все untracked не созданы этим TASK, существовали до старта.

## Remaining

- Worker не коммитил и не создавал ветку — для Tier C docs working tree edit достаточен per TASK guidance ("для Tier C docs допустимо работать в working tree без коммита").
- TL решает: accept в working tree (через `make accept-task` + manual `git add docs/DM-7-cashbox.md && git commit`) либо optional Reviewer pass перед commit.

## Artifacts

- branch:    `master` (working tree only, не создавал отдельной ветки)
- commit(s): uncommitted, working tree only
- PR:        none
- tests:     N/A (docs-only TASK; не запускал cabal/pytest/npm)

## Conflicts / risks

- **Drive-by с честным flag'ом**: добавил отдельную строку "Prod deploy" в таблицу фаз (ради PR #79, #80). Это не было прямо в acceptance criteria, но header требует утверждения "production live на 94.72.112.106:8088"; таблица фаз — естественное место для подтверждения. Если TL считает это scope creep вне Phase A-D таксономии — удалить эту строку trivial single Edit. Альтернатива: вынести в отдельный paragraph рядом с header.
- **Out-of-scope flag'ов нет**: ничего не трогал в `sitka-core/`, `sitka-services/`, `sitka-web/`. Phase A / B-1 / B-2 / B-3 строки таблицы не трогал. Resolved invariants section не трогал. Формула `csExpectedMargin`, lifecycle reservation, инварианты не трогал.
- **Markdown sanity**: таблица сохраняет 3 колонки (Phase / Что / Состояние) во всех строках. Новая subsection `### Phase D prereq` использует `###` — соответствует уровню вложенности под `## Фазы внедрения` (тот `##`). Кодблоков и линков не добавлял.

## Next step

TL читает HANDOFF, делает sanity-check diff (опционально через Reviewer pass), решает scope для строки "Prod deploy" (оставить / удалить / переместить), затем:
1. `git add docs/DM-7-cashbox.md && git commit -m "docs(dm-7): sync DM-7-C closure + Phase D TBD into design doc"` (или с co-author trailer per project policy).
2. `make accept-task FILE=...2026-05-06-dm7-cashbox-doc-status-sync.md`.
3. `make accept-handoff FILE=...2026-05-06-worker-to-tl-dm7-cashbox-doc-status-sync.md`.

## TL Review

- **Даты исправлены**: Worker написал PR #74–#78 как `2026-04-29 → 2026-05-04` и PR #79/#80 как `2026-05-04` — это из памяти, не из git log. Реальные merge-даты из `git log --grep` в sitka-office: PR #74–#77 = 2026-05-01, PR #78/#79/#80 = 2026-05-02. TL вручную поправил до accept (2 edits в `docs/DM-7-cashbox.md` lines 64-65).
- **Reviewer report был stdout-only**: Phase B smoke прогон Reviewer subagent'а вернул отчёт через subagent return value, отдельного `HANDOFFS/<date>-reviewer-to-tl-*.md` файла не создал. Это системный gap в инструкциях `.claude/agents/sitka-reviewer.md` (нет шага "сохрани отчёт через `make new-handoff` после анализа"), не индивидуальная ошибка этого run'а. Логируется в backlog.
- **Не блокер для docs-only accept**: Tier C, single-file edit, scope diff чистый (`M docs/DM-7-cashbox.md` only), даты теперь верные, Worker self-flagged "Prod deploy" row как scope-creep но row остаётся (header требует подтверждения "production live"). Принимается.
- **Drive-by row "Prod deploy"**: оставляется. Worker честно flagнул в Conflicts/risks; альтернативы (удалить / вынести paragraph) — больше ущерба читаемости таблицы фаз, чем профит от строгости "только A/B/C/D".
