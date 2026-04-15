# Sitka Office — Handoff Note

Дата: 2026-04-14

## Что зрело

- Трёхслойная архитектура: core / services / web — все три запускаются и работают вместе.
- Domain model в Haskell: newtypes для денег, ADT для статусов, чистый state machine, чистый pricing engine.
- Services: FastAPI с real parser + mock fallback, sourcing pipeline с normalization/dedupe.
- Web: workspace layout (inbox → workspace → context), sourcing из UI, transitions, quote creation.
- Self-learning: CLAUDE.md (12 правил) + corrections.md (3 записи) + .hlint.yaml.

## Что НЕ зрело (выглядит готовым, но есть дыры)

- **Type safety теряется на границах DB и API** — domain types правильные, но Db/Schema.hs и Api/Types.hs используют raw Double и Text. PersistField instances не реализованы. Это приоритет #0.
- **Event sourcing** — таблица есть, wiring нет. Не использовать как готовую фичу.
- **Тесты** — минимальные. Pricing и StateMachine легко тестируются, но тестов нет.
- **Pre-deal vs active deal** — в data model разделены, в UI смешиваются.

## Что делает другой агент прямо сейчас

На момент этого handoff другой агент работает с sitka-office. Не трогать файлы в sitka-office без координации.

## Что самое важное для следующего

1. Закрыть type safety gaps (PersistField, fetchOr404) — без этого дальше строить ненадёжно.
2. Только после этого двигать UI и коммуникационный слой.
3. Каждую найденную ошибку записывать в corrections.

## Что заносить в ai-dev-system после итераций

- Новые corrections (если повторяемый anti-pattern).
- Удачные Haskell сниппеты → `templates/reference-snippets/`.
- Обновлённый overlay (CURRENT_STATE, KNOWN_ISSUES, NEXT_ACTIONS).
- Postmortem если задача оказалась сложнее ожидаемого.
