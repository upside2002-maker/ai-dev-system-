# Sitka Office — Known Rules

Выжимка из CLAUDE.md и накопленного опыта. Для быстрого входа нового агента.

## Haskell Core — жёсткие правила

1. **Нет raw Double для денег.** Только USD, RUB, Percent, ExchangeRate из Domain/Types.hs. Если Persistent требует Double — PersistField instance на newtype.
2. **Нет Text для ADT в DB.** DealStatus, Transition, RiskFlag, EventType — через PersistField с exhaustive pattern matching.
3. **Нет raw Int64 для ID.** Только Key Client, Key Deal или domain newtypes.
4. **Smart constructors.** Percent: 0-100. ExchangeRate: > 0. USD/RUB: >= 0. Export mkPercent, не Percent constructor.
5. **Нет mutable state.** IORef, MVar, STRef запрещены. HLint это ловит.
6. **Business logic — pure.** IO только на границах (handlers, DB).
7. **DRY.** Повторяющиеся паттерны → helpers. fetchOr404, не copy-paste.
8. **-Wall -Werror -Wincomplete-patterns.** Все pattern matches exhaustive. Нет wildcards на sum types.
9. **DerivingStrategies.** deriving stock / deriving anyclass — явно.
10. **Type signatures.** На всех top-level функциях.
11. **Servant API.** Изменения идут от type-level API definition.
12. **where > let.** Предпочитать where-clause, do-блоки держать shallow.

## Python Services — границы

- FastAPI — только transport и orchestration.
- **Services не принимают бизнес-решений.** Финальные статусы, pricing, валидация — core.
- Core вызывается по HTTP через core_client.
- Pydantic для request/response.
- Type hints на всех функциях.
- Graceful degradation на внешние зависимости.
- Mock всегда помечен как mock.

## Frontend — принципы

- Это CRM для менеджера, не демо внутренней архитектуры.
- **UI показывает next action**, не все возможности сразу.
- Технические термины спрятаны или переведены в операторский язык.
- Frontend не хранит бизнес-truth — берёт всё из API.

## Что отложено явно (НЕ ДЕЛАТЬ)

- Authentication/authorization.
- CI/CD.
- Email/SMS — только Telegram.
- Переписывание Haskell на другой язык.

## Мета-правило

Любой повторяющийся агентный косяк → `.claude/corrections.md` в формате BAD → GOOD → WHY.
