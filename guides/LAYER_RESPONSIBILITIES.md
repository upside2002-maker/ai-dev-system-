# Layer Responsibilities

> **Область:** этот файл описывает **слои Worker-задачи** (Core / Services / Frontend). Это **не роли** — слои и роли две ортогональные оси. Канонический источник по ролям (Project Tech Lead / Business Analyst / Reviewer / Worker / AI Dev System Admin) — [`../ROLE_MODEL.md`](../ROLE_MODEL.md).

## Слои

В TASK поле `Layer:` принимает одно из шести значений ниже. Канонические имена строчные (для match с `scripts/new-task.sh` whitelist).

| Слой | Владеет | Не владеет |
|------|---------|-----------|
| **`core`** | Domain types, state machine, pricing, API контракты, DB schema | Парсеры, UI, browser automation |
| **`services`** | FastAPI, парсеры, Telegram bot, notifications, external APIs | Бизнес-решения по деньгам и статусам |
| **`web`** | Operator UI (React / TS / CSS), API client, e2e тесты. Историческое имя — *frontend*; в новых TASKs используем `web`. | Расчёт цен, бизнес-логика статусов |
| **`docs`** | Markdown в overlay, дизайн-доки, README, корректировки | Любой исполняемый код |
| **`infra`** | `Makefile`, CI workflows, `Dockerfile`, deploy scripts, helper-скрипты | Domain logic |
| **`mixed`** | Задачи неразделимо затрагивающие несколько слоёв (редко; почти всегда правильный ответ — разбить на отдельные TASKs) | — |

## Цикл работы

1. Прочитать CLAUDE_GLOBAL.md → corrections → overlay (CURRENT_STATE / KNOWN_ISSUES)
2. Определить слой
3. Выполнить задачу в рамках одного слоя
4. Build / test / lint
5. Обновить corrections если ошибка повторяемая

## Формат задачи

```
Слой:    [docs | core | services | web | infra | mixed]
Файлы:   [конкретные пути]
Задача:  [что сделать]
Не трогать: [что не менять]
Проверка: [конкретные команды: cabal test | pytest | npm test | tsc -b | make check]
```

## Координация

- Один файл = один агент в момент времени
- API контракты фиксируются до параллельной работы
- Core мержится первым (определяет контракт)
