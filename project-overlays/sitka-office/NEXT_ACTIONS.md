# Sitka Office — Next Actions

Дата: 2026-04-21
Основано на snapshot `679b188`

Ниже не исторический Phase 1 план, а ближайшие практические шаги после
закрытия Phase DM и включения lead-first flow.

## Приоритет 0 — держать overlay в синхроне с repo

Это не продуктовая фича, но сейчас это обязательный шаг:

- после каждого заметного milestone обновлять `CURRENT_STATE`,
  `NEXT_ACTIONS`, `PROJECT_MAP`
- не использовать старые `PHASE_0/1` документы как текущую картину мира
- фиксировать snapshot commit в overlay

Иначе `ai-dev-system` перестаёт быть системой разработки и снова
становится набором отставших markdown-файлов.

## Приоритет 1 — стабилизация DM-6.2.5 message loop

Новая зона проекта уже не `marketing setup`, а операторский цикл
`message -> lead -> deal`.

Практический фокус:

1. Довести Avito message path до спокойного операционного состояния:
   - poller
   - ingest
   - outbound sender
   - retry / failed / pending сценарии
2. Проверить, как message inbox входит в ежедневный workflow оператора
3. Не размывать это новыми крупными сущностями, пока message loop не
   обкатан руками

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
