# Sitka Office — Next Actions

Дата: 2026-05-02
Основано на snapshot `b58e5fb`

Ниже не исторический Phase 1 план, а ближайшие практические шаги после
закрытия DM-7 Phase B и включения cashbox.

## Приоритет 0 — держать overlay в синхроне с repo

Это не продуктовая фича, но сейчас это обязательный шаг:

- после каждого заметного milestone обновлять `CURRENT_STATE`,
  `NEXT_ACTIONS`, `PROJECT_MAP`
- не использовать старые `PHASE_0/1` документы как текущую картину мира
- фиксировать snapshot commit в overlay

Иначе `ai-dev-system` перестаёт быть системой разработки и снова
становится набором отставших markdown-файлов.

## Приоритет 1 — DM-7 Phase C/D + post-Phase-B стабилизация

DM-6.2.5 message loop теперь в operationally-stable состоянии (буквы
m/n/o/r закрыли inbox bugs; PR #69 закрыл cold-cache parser UX).
DM-7 Phase A и Phase B закрыты целиком (PR #63–#66 + live-smoke
фиксы #68–#70).

Практический фокус:

1. **Phase C/D DM-7** — содержание в `/Users/ilya/Projects/sitka-office/docs/DM-7-cashbox.md`. Первая итерация требует приоритизации у TL; в overlay пока не зафиксировано.
2. **Post-Phase-B стабилизация** — собрать operator feedback на полный cashbox flow (foundation + ConfirmPurchase + shipping-expense + ReservationOverrun + FulfillmentStep) перед стартом Phase C.
3. **Realistic fixture coverage** — три бага PR #68–#70 поймались только на live local smoke, не unit-тестами. При новых engine/risk модулях добавлять golden tests с realistic non-round numbers и slow-network timing, а не только happy-path round-numbers.

## Приоритет 2 — убрать очевидный legacy debt

После DM-6.4 часть legacy surface уже мертва в runtime, но ещё видна в
типах и helper-ах.

Ближайший cleanup-кандидат:

- dead `DealStatus` / `Transition` constructors, которые остались только
  ради старых stage-mapping helper-ов
- устаревшие комментарии и docs, где процесс всё ещё описан как
  `Client -> Deal -> Sourcing -> QuoteReady`

Это делать только после того, как не пострадает текущий analytics/read-side.

## Приоритет 3 — production-safety backlog

В `architecture-invariants.md` уже перечислен реальный safety backlog.
Самые практичные вещи оттуда:

1. более явный audit trail вне `deal_event`
2. contract / golden tests для DTO
3. backup + restore drill
4. единый audit env / secrets

Это даёт больший ROI, чем новые большие сущности "на будущее".

## Приоритет 4 — знания и операторские ассистенты

После стабилизации message loop уже можно безопасно двигать:

- базу знаний по моделям
- внутреннего помощника для оператора
- структурированную product knowledge
- аккуратные инструменты поиска по CRM + knowledge base

Но это следующий слой, а не то, на чём стоит снова переписывать core.

## Не делать

- не возвращать Client-first flow
- не плодить новые большие подсистемы до стабилизации message loop
- не тащить knowledge / assistant прямо в runtime core без ясной границы
- не считать старые Phase 0 / Phase 1 документы текущим roadmap'ом
