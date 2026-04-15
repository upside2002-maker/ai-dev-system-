# Sitka Office — Next Actions

Дата: 2026-04-14

## Приоритет 0: Техдолг type safety (блокирует рост)

Без этого каждый новый модуль будет наследовать дыры.

1. **PersistField instances для USD, RUB** — `Db/Schema.hs` + `Domain/Types.hs`.
2. **PersistField instance для DealStatus** — exhaustive, `-Wincomplete-patterns`.
3. **PersistField instance для RiskFlag, EventType** — аналогично.
4. **fetchOr404 helper** — `Api/Helpers.hs`, заменить дублирование в Clients и Deals.
5. **Заменить Double на domain types в Api/Types.hs** — transport types тоже должны быть типизированы.

Все 5 пунктов — задачи для Core Agent, один слой, одна сессия.

## Приоритет 1: Операторский workflow (ценность для бизнеса)

6. **Доступ к PricingSettingsPanel** — сейчас панель существует, но неочевидно как до неё добраться. Иконка gear или пункт меню.
7. **Создание клиента из "Новый запрос"** — сейчас flow: inbox → создать клиента → создать deal. Упростить.
8. **Re-search из карточки сделки** — повторный sourcing без пересоздания deal.
9. **Явный next action в DealWorkspace** — UI должен показывать что делать, а не всё что можно.

Пункты 6-8 — Frontend Agent. Пункт 9 — архитектурный, затрагивает и frontend и возможно core.

## Приоритет 2: Коммуникационный слой

10. **Telegram бот** — уведомления о новых лидах + калькулятор цен.
11. **Outbound из UI** — отправка КП клиенту прямо из workspace.

Telegram: Services Agent (bot wiring) + Core Agent (notification events). Outbound: все три слоя.

## Приоритет 3: Качество кода

12. **Тесты для Pricing.hs** — чистая функция, тестировать тривиально.
13. **Тесты для StateMachine.hs** — allowed и forbidden transitions.
14. **Подключить event sourcing** — handlers начинают писать DealEvents.
15. **Удалить мёртвый CSS** — ~300 строк.
16. **Мобильная адаптация** — базовый responsive.

## Что НЕ делать сейчас

- Не переписывать архитектуру.
- Не тащить core-логику в Python.
- Не добавлять auth/CI/CD (явно отложено в CLAUDE.md).
- Не расширять UI вниз бесконечными блоками.
- Не подключать Redis пока нет реальной потребности в очередях.
