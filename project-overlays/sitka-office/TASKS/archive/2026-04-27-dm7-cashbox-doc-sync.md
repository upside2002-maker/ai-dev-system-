# 2026-04-27-dm7-cashbox-doc-sync

- ID: `2026-04-27-dm7-cashbox-doc-sync`
- Created by: Claude Tech Lead session, 2026-04-27
- Worker model: Claude Code
- Worker branch: создаётся Worker при старте (`feat/dm7-cashbox-doc-sync` или аналог)
- Layer: docs-only (вне кодовых слоёв core/services/frontend — markdown в `docs/`)
- Risk tier: C (по правилу `docs/**` в `.claude/risk-tiers.md`; `scripts/file-tier.sh docs/DM-7-cashbox.md` → C)
- Status: done

## Задача

Привести `docs/DM-7-cashbox.md` в синхрон с фактическим состоянием master. Документ — заявленный source of truth по DM-7, но в нём осталось внутреннее противоречие: таблица фаз (строки 55–60) показывает Phase B-3 как `в работе`, а тело документа ниже (строка 66 «Phase B ≈ закрыт по B-3» + Resolved invariants п. 4–7) описывает B-3 как закрытую. По факту master содержит PR #66 (B-3 merge, 2026-04-26) и PR #70 (post-B fix `csExpectedMargin`, 2026-04-27).

Это smoke-test нового процесса TL → TASK → Worker → HANDOFF → TL accept. Нулевой blast radius — markdown в `docs/` не идёт в build artifact, не влияет на runtime, не трогает Tier A/B файлы.

## Файлы

- `modify:` `docs/DM-7-cashbox.md` (единственный файл)
- `new:` —
- `delete:` —

## Не трогать

- Кодовая база: `sitka-core/`, `sitka-services/`, `sitka-web/` — целиком, ни строки.
- Миграции: `sitka-core/migrations/*.sql` — целиком.
- `.claude/*` — целиком.
- Любые другие markdown-файлы (`docs/*.md` кроме целевого, `README.md`, overlay в `ai-dev-system/`).
- Не расширять scope правок за пределы перечисленных в "Критерии приёмки" пунктов. Если по дороге заметишь ещё что-то устаревшее в `DM-7-cashbox.md` — **не править молча**, а упомянуть наблюдение в HANDOFF секцией "Замечено по дороге, не правил". TL решит, ставить ли отдельный TASK.

## Критерии приёмки

Все пять пунктов обязательны (расширено по запросу TL 2026-04-27: добавлен пункт 4 про шапку строки 5–6, лимит diff поднят с ≤10 до ≤15 строк). Diff ≤ 15 строк, 1 файл, **без касания кода и тестов**.

1. **Таблица фаз (строки ~55–60).** Строка `Phase B-3` в колонке «Состояние» меняется с `в работе` на `✅ закрыта PR #66 (2026-04-26)`. Формат строго такой, чтобы матчился со стилем соседних строк (`✅ PR #63`, `✅ PR #64`, `✅ PR #65`).

2. **Resolved invariants пункт 7 (строки ~232–248).** Сейчас пункт начинается `7. **csExpectedMargin plan-based (post-B fix).** ✅ Phase A шиплился с …`. Дополнить упоминанием PR #70 в первой фразе пункта — например: `7. **csExpectedMargin plan-based (post-B fix, PR #70).** ✅ …` (точная формулировка на усмотрение Worker, главное чтобы PR-номер появился рядом с заголовком пункта). Существующий fragment в конце пункта про PR #68 (Risk #2 Scientific → Rational) **не трогать** — он про другой hotfix.

3. **Last updated в шапке.** Сейчас шапка (строки 1–6) не содержит метки даты. Добавить под цитатным блоком (после строки 6) одну новую строку: `Last updated: 2026-04-27.`. Не вставлять перед `## Зачем` пустой строкой больше необходимого.

4. **Шапка `docs/DM-7-cashbox.md`, строки 5–6 — статус фаз (расширено по запросу TL 2026-04-27).** Сейчас: `> Phase A на момент написания этого файла **уже в репе** (PR #63). > Phase B/C/D — впереди.` Актуализировать: Phase A/B закрыты, C/D в работе/впереди. Без переписывания смысла, только статус. Сохранить структуру bullet-цитаты (`> ...`). Если шапка окажется длиннее ожидаемого (текстовый блок, не два bullet-блока цитаты) — Worker возвращает в TL, не правит молча.

5. **Объём.** `git diff docs/DM-7-cashbox.md` показывает ≤ 15 строк изменений (added + removed суммарно по `git diff --shortstat`). Касается ровно одного файла. CI зелёный (фактически — markdown CI gate-а нет, но import-linter / weeder / haskell-test / python-test / frontend-typecheck должны остаться зелёными, так как они не зависят от этого файла).

## Контекст

- HEAD master на момент создания TASK: `39873d2`
- PR #66 (B-3 merge): `5aa85c3` 2026-04-26 — `feat(dm-7-b-3): shipping-expense + reservation lifecycle hooks`
- PR #70 (post-B fix): `39873d2` 2026-04-27 — `fix(cashbox): csExpectedMargin = plan-based, не conservative running diff`
- Источник правды по cashbox: `docs/DM-7-cashbox.md` (этот же файл, который правим)
- Подтверждение что Phase B закрыта: `project-overlays/sitka-office/CURRENT_STATE.md` строки 14–19, `OPERATING.md` строки 8–9, `NEXT_ACTIONS.md` строки 22–32
- Шаблон TASK / lifecycle: `templates/TASKS_TEMPLATE.md`

## Reviewer

Не запрашивается. Tier C, объём <15 строк, factual diff против `git log`. После HANDOFF — TL accept напрямую, без отдельного Reviewer round-а.

## Worker workflow (напоминание из правил)

1. Сменить `Status: open` → `Status: in-progress` в этом файле.
2. Создать ветку, внести правки, локально проверить `git diff --shortstat docs/DM-7-cashbox.md` ≤ 15.
3. Открыть PR в master с заголовком в стиле `docs(dm-7): sync Phase B-3 status with master`.
4. Написать HANDOFF в `project-overlays/sitka-office/HANDOFFS/2026-04-27-claude-worker-to-claude-tl-dm7-cashbox-doc-sync.md` по шаблону `templates/HANDOFFS_TEMPLATE.md` со ссылкой на PR.
5. Сменить `Status: in-progress` → `Status: review` в этом файле.
6. Вернуть управление TL (отсюда — accept или возврат с правками).
