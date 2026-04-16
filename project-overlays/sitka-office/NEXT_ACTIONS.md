# Sitka Office — Next Actions

Дата: 2026-04-15

## Приоритет 0: Оставшийся техдолг

1. **Smart constructors** — mkPercent (0-100), mkUSD (≥0), mkRUB (≥0), mkExchangeRate (>0). Core agent, 2-3ч.
2. **ADT для eventType/actor** — sealed types вместо Text. Core agent, 1-2ч.
3. **Больше тестов** — SM edge cases, pricing boundaries, risk engine. Core agent, 4-6ч.

## Приоритет 1: Production deployment

4. **Первый деплой на VPS** — docker-compose.prod.yml + nginx + SSL. Уже подготовлено (scripts/, deploy/).
5. **Manual DB migrations** — перейти с auto-migration на versioned SQL files перед production.
6. **Staging environment** — dev → staging → prod pipeline.

## Приоритет 2: Бизнес-ценность

7. **Telegram bot доработка** — бот уже работает, но может потребовать доработок по UX.
8. **Outbound actions** — отправка КП клиенту из workspace.
9. **Мобильная адаптация** — responsive CSS для операторов в полях.

## Приоритет 3: Масштабирование

10. **Redis** — подключить для кеша/очередей когда будет нагрузка.
11. **riskFlags нормализация** — JSONB или junction table.
12. **Event sourcing wiring** — handlers начинают использовать DealEvent полноценно.

## Не делать

- Не переписывать архитектуру
- Не добавлять Kubernetes
- Не добавлять email/SMS
- Не тащить business logic в Python
