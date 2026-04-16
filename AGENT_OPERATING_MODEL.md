# Agent Operating Model

## Роли

| Роль | Владеет | Не владеет |
|------|---------|-----------|
| **Core Agent** | Domain types, state machine, pricing, API контракты, DB schema | Парсеры, UI, browser automation |
| **Services Agent** | FastAPI, парсеры, Telegram bot, notifications, external APIs | Бизнес-решения по деньгам и статусам |
| **Frontend Agent** | Операторские сценарии, UX, API client | Расчёт цен, бизнес-логика статусов |

## Цикл работы

1. Прочитать CLAUDE_GLOBAL.md → corrections → overlay
2. Определить слой
3. Выполнить задачу в рамках одного слоя
4. Build/test/lint
5. Обновить corrections если ошибка повторяемая

## Формат задачи

```
Слой: [core | services | web]
Файлы: [конкретные пути]
Задача: [что сделать]
Не трогать: [что не менять]
Проверка: [stack build | pytest | tsc]
```

## Координация

- Один файл = один агент в момент времени
- API контракты фиксируются до параллельной работы
- Core мержится первым (определяет контракт)
