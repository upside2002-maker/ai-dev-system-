# Sitka Office — Next Actions

Дата: 2026-04-16 (после закрытия Phase 0)

## Phase 1 — Marketing Analytics MVP (приоритет 0)

Самая бизнес-значимая задача. Foundation в Phase 0 уже заложен.

**Цель:** менеджер открывает Marketing dashboard → видит spend / leads / deals / revenue / margin per channel за выбранный период.

**Длительность:** 2 недели.

### Подзадачи

1. **Engine.Marketing** (Haskell, pure):
   - `aggregateSpend :: Period -> [SpendEntry] -> SpendByChannel`
   - `funnelByChannel :: Period -> [Deal] -> [SourceTouch] -> FunnelByChannel`
   - `calculateCPL`, `calculateCPD`, `calculateROI` per channel/listing/campaign
   - Loss reasons aggregation (DisqualifyReason / RejectReason / CancelReason breakdown)

2. **API endpoints** (расширение Api.Marketing):
   - `GET /api/marketing/dashboard?from=&to=&channel=`
   - `GET /api/marketing/funnel?from=&to=&groupBy=channel|listing|campaign`
   - `GET /api/marketing/listings?from=&to=` (performance per listing)
   - `GET /api/marketing/losses?from=&to=` (breakdown by reason)

3. **Web — Marketing Dashboard**:
   - KPI cards (spend, leads, deals, revenue, margin, ROI/ROMI)
   - Funnel chart per channel
   - Listings performance table
   - Loss reasons pie chart
   - Period selector (today / week / month / custom)

4. **Тесты:** unit для aggregations + property tests для edge cases (нет spend, нет deals, all losses)

## Phase 2 — Avito Inbox + Conversations (приоритет 1)

Решает проблему "WhatsApp leak" + автоматизирует ввод диалогов в CRM.

**Длительность:** 3 недели.

### Подзадачи

1. **Services**: `sitka-services/app/conversations/` — ConversationProvider abstraction + AvitoProvider
2. **Background sync**: каждые 15 минут (per ARCHITECTURE_V2 решение)
3. **conversation_messages таблица в Postgres** (тело сообщений в services БД)
4. **Inbox UI** в web (Layout 5.2 из ARCHITECTURE_V2)
5. **SLA индикаторы**: Avito 30 минут (жёсткий красный алерт), Telegram/WA 4 часа (мягкий)
6. **Cursor pagination** для Conversations API (закрывает технический долг #2 Phase 0)

## Phase 3 — Telegram + WhatsApp adapters (приоритет 2)

**Длительность:** 2-3 недели.

- Расширение Telegram bot для роли ConversationProvider
- TelegramProvider implementation
- WhatsAppProvider (зависит от выбора: WA Business API / Wati / Twilio)

## Phase 4 — Knowledge / Decisions Hub (приоритет 2)

**Длительность:** 1-2 недели.

- Note + Decision entities в Core
- Telegram bot команды: `/note`, `/save`, `/decide`, `/notes`, `/decisions`
- Реакция на 📌 emoji в общем чате (опционально)
- Web UI с поиском и тегами

## Phase 5 — Avito Spend Auto-Sync (приоритет 3)

**Длительность:** 1 неделя.

- AvitoSpendSync background job (раз в день pull spend report)
- Reconciliation manual vs API spend
- Alerts при расхождениях

## Технический долг (накопленный)

| # | Долг | Когда чинить |
|---|------|--------------|
| 1 | ApiSpec test harness использует `runMigration` (не dbmate) | При рефакторинге test infra |
| 2 | Conversations API: limit 200 без cursor pagination | Phase 2 (нужно для inbox) |
| 3 | Marketing event stream отсутствует — spend/listing events не аудируются | Phase 1/2 если нужна аналитика по событиям |
| 4 | ~~Auth middleware на Marketing/Conversations endpoints~~ | ✅ Проверено: `authMiddleware` в `Api/Server.hs` оборачивает `serve apiProxy` целиком — все роутеры защищены автоматически; `isPublic` открывает только `/health` |

## Параллельная операционная работа (НЕ код)

Из аудита `MY_AVITO_AUDIT.md` — то что владелец делает руками:

| # | Действие | Статус |
|---|----------|--------|
| 1 | Пополнить CPA-аванс (минимум 1 000 ₽) | 🚨 БЛОКЕР |
| 2 | Установить дневной лимит трат 300-500 ₽ | TODO |
| 3 | Поставить ставку 7-10 ₽ на активные | TODO |
| 4 | Заменить условные цены в названиях ("5 000 ₽") на реальные | TODO |
| 5 | Опубликовать 2-3 готовых из 15 неопубликованных | TODO |
| 6 | Добавить SLA "5-15 минут" в описания | TODO |
| 7 | Переименовать профиль: "Илья — эксперт по Sitka & Kuiu" | TODO |
| 8 | Подключить максимальный тариф Avito (для Phase 2 API) | TODO |

## Не делать

- Не переписывать архитектуру
- Не добавлять Kubernetes
- Не добавлять email/SMS — только Telegram
- Не тащить business logic в Python
- Не строить Growth Lab / A/B testing infrastructure (нет статпов на 30 сделках/месяц)
- Не делать multi-touch attribution (single-touch достаточно)
- Не хранить тело сообщений в Haskell core (только метаданные ConversationThread)
