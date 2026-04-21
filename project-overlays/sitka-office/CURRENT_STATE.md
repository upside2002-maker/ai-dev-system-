# Sitka Office — Current State

Дата: 2026-04-21
Snapshot commit: `679b188`
Repo: `/Users/ilya/Projects/sitka-office`

## TL;DR

`sitka-office` больше не находится в Phase 0 / раннем Phase 1.
Текущая форма проекта — **post-Phase-DM, mid DM-6.2.5**:

- Lead-first flow уже включён и является единственным живым write-path
- Person / ContactPoint / Lead / Treasury / Conversations уже в ядре
- legacy Client-first создание сделки из runtime вырезано
- UI уже разделён на `Входящие` и `Сделки`
- message inbox и Avito-messenger слой уже в работе

Это важно: старые документы про `NewRequest -> Sourcing -> QuoteReady`
нужно читать только как историю.

## Архитектура

Система по-прежнему трёхслойная:

- `sitka-core` — Haskell (Servant + Persistent + Warp), `:8080`
- `sitka-services` — Python (FastAPI + Telegram + crons + Avito tasks), `:8081`
- `sitka-web` — React 19 + TypeScript + Vite, `:5173`
- PostgreSQL 16 + Redis 7 через docker-compose
- CI: 7 обязательных проверок
- миграции: `dbmate`, без auto-migration

## Текущий бизнес-flow

Источник правды по состоянию домена теперь такой:

```
incoming signal
  -> person resolve
  -> lead create
  -> offers + quote attach to lead
  -> create-deal-from-lead
  -> Deal.AwaitingPayment
  -> ConfirmPrepayment
  -> Deal.Confirmed + Client materialised + Treasury row
  -> Purchased -> logistics chain -> Completed
```

Ключевая граница:

- pre-sale живёт на `Person + Lead`
- post-payment execution живёт на `Deal`
- `Client` создаётся только при первой оплате

## Core (Haskell)

### Доменные сущности

В активной модели уже есть:

- `Person`, `ContactPoint`, `Lead`, `Lead.Event`
- `Deal`, `Quote`, `Offer`, `Reason`
- `Conversation`
- `Marketing` + attribution
- `Transaction` (treasury ledger)

### API surface

В кодовой базе уже есть отдельные модули:

- `Api.Persons`
- `Api.Leads`
- `Api.Deals`
- `Api.Treasury`
- `Api.Marketing`
- `Api.MarketingAnalytics`
- `Api.Conversations`
- `Api.Messages`
- `Api.PricingSettings`
- `Api.ServiceState`

### Важная оговорка

Legacy-конструкторы `DealStatus` и старые `Transition` ещё
компилируются как мёртвая поверхность, но текущий runtime-path их не
создаёт. Они остались ради совместимости внутренних helper-ов и
аналитических mapping-ов.

## Services (Python)

Слой services уже тоже ушёл далеко от описания "Phase 0":

- Telegram bot переведён на lead-first создание
- есть `deal_expiration.py` для TTL / auto-expire
- есть Avito poller / sender tasks
- есть канальный Avito client
- старый create-deal-from-sourcing путь уже вырезан

Важно: часть Avito-функций остаётся credentials-gated и по умолчанию
может no-op'иться, пока не заданы реальные ключи/настройки.

## Web (React)

Фронт уже не является только legacy workspace.

Актуальная форма UI:

- вкладка `Входящие` — Lead Inbox
- вкладка `Сделки` — post-Confirmed deal workspace
- отдельный `Message Inbox` под сообщения / треды
- marketing settings + analytics всё ещё на месте

То есть операторский интерфейс уже реально разделён по фазам процесса,
а не крутится вокруг одной legacy карточки сделки.

## Quality / safety

- в Haskell-ядре — сотни тестов
- в Python — десятки test files
- во фронте — `12` E2E spec files + unit tests
- CI жёстко прогоняет formatter / import rules / migration drift /
  Haskell / Python / frontend

Отдельный источник правды по инвариантам:

- `/Users/ilya/Projects/sitka-office/CLAUDE.md`
- `/Users/ilya/Projects/sitka-office/.claude/architecture-invariants.md`

## Git snapshot

На момент синхронизации overlay:

- HEAD: `679b188`
- в рабочем дереве был замечен локальный backup-файл
  `sitka-services/.env.bak`, то есть состояние repo не абсолютно
  идеально-чистое

## Что читать дальше

1. `README.md` в этом overlay
2. `KNOWN_ISSUES.md`
3. `NEXT_ACTIONS.md`
4. `PROJECT_MAP.md`
5. Для глубины: `DOMAIN_V3.md`, `PHASE_DM_TASKS.md`, `ARCHITECTURE_V2.md`
