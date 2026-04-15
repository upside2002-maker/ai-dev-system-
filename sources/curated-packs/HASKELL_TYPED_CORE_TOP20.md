# Haskell Typed Core Top 20

Этот файл не про "скопируй отсюда код".
Он про 20 паттернов, которые стоит показывать агенту перед задачами в typed core.

Базовые источники для отбора:

- `tibbe/haskell-style-guide`
- `haskell-servant/servant`
- `PostgREST/postgrest`
- `jgm/pandoc`

## 1. Newtype для денег и единиц измерения

Когда использовать:

- валюты;
- проценты;
- курсы;
- любые значения, которые нельзя случайно смешать.

Хорошая форма:

- `newtype USD = USD Scientific`
- `newtype RUB = RUB Scientific`
- `newtype Percent = Percent Scientific`

Избегать:

- raw `Double`;
- `type USD = Double`;
- хранить смысл только в имени поля.

## 2. Smart constructor вместо открытого конструктора

Когда использовать:

- значение имеет диапазон;
- отрицательные числа недопустимы;
- есть доменная валидация.

Хорошая форма:

- `mkPercent :: Scientific -> Either Text Percent`
- `mkExchangeRate :: Scientific -> Either Text ExchangeRate`

Избегать:

- создавать `Percent` в любом месте без проверки;
- засовывать валидацию только в handler.

## 3. ADT для статусов жизненного цикла

Когда использовать:

- этапы сделки;
- типы событий;
- роли актеров;
- стадии доставки и оплаты.

Хорошая форма:

- sum type с явными конструкторами;
- exhaustive pattern matching;
- transitions через отдельную функцию/модуль.

Избегать:

- `Text`-статусы на уровне domain;
- `Maybe Text` вместо реального sum type.

## 4. Отдельный модуль state machine

Когда использовать:

- когда сущность движется по этапам;
- когда есть запрещенные переходы.

Хорошая форма:

- `Domain/Deal/StateMachine.hs`
- чистая функция `applyTransition`.

Избегать:

- разбрасывать правила переходов по handler'ам;
- condition spaghetti в трех разных модулях.

## 5. Pure first

Когда использовать:

- pricing;
- risk flags;
- validation;
- transition rules.

Хорошая форма:

- сначала чистая функция;
- потом thin handler, который только грузит и сохраняет.

Избегать:

- смешивать DB + validation + pricing в одной длинной функции.

## 6. Thin handler

Когда использовать:

- Servant endpoint;
- любой API handler.

Хорошая форма:

- parse input;
- вызвать чистую доменную функцию;
- сделать persistence;
- вернуть response.

Избегать:

- 150 строк handler'а с половиной бизнес-логики.

## 7. Type-level API как источник истины

Когда использовать:

- любые HTTP контракты.

Хорошая форма:

- сначала изменить API type;
- потом server implementation;
- потом transport types.

Избегать:

- менять JSON форматы "по месту";
- незаметно менять endpoint только в коде handler'а.

## 8. Отдельные transport types

Когда использовать:

- JSON request/response.

Хорошая форма:

- `Api.Types` отдельно от `Domain.*`;
- явное преобразование между transport и domain.

Избегать:

- использовать DB entity как API response напрямую;
- использовать domain type как storage shape без надобности.

## 9. Fetch helper вместо копипасты

Когда использовать:

- повторяется `get -> case Nothing/Just`.

Хорошая форма:

- `fetchOr404` или аналогичный helper.

Избегать:

- 6 копий одного и того же паттерна во всех handlers.

## 10. PersistField для доменных новых типов

Когда использовать:

- DB boundary для newtype и ADT.

Хорошая форма:

- instance `PersistField USD`
- instance `PersistField DealStatus`

Избегать:

- manually `statusToText` / `textToStatus` с wildcard;
- strip newtype at DB boundary.

## 11. Маленькие модули по смыслу

Когда использовать:

- растущий core.

Хорошая форма:

- `Domain/Quote.hs`
- `Domain/Offer.hs`
- `Engine/Pricing.hs`
- `Api/Quotes.hs`

Избегать:

- один огромный `Types.hs` на весь мир;
- `Api.hs` с кучей не связанных вещей.

## 12. Deriving discipline

Когда использовать:

- почти всегда на top-level types.

Хорошая форма:

- `deriving stock`
- `deriving anyclass`
- явный список deriving.

Избегать:

- неявных derive-подходов, которые хуже читаются;
- магии, которую следующий агент не поймет.

## 13. Эксплицитные type signatures

Когда использовать:

- на всех top-level functions.

Хорошая форма:

- сигнатура на всё публичное;
- сигнатура на все важные внутренние функции.

Избегать:

- полагаться на inference там, где важен intent.

## 14. Separate policy from mechanism

Когда использовать:

- transitions;
- quote eligibility;
- risk assignment.

Хорошая форма:

- policy: чистые правила;
- mechanism: DB/HTTP wiring вокруг них.

Избегать:

- "если такое, то сохраняем это, и заодно считаем цену".

## 15. Domain events как отдельная сущность

Когда использовать:

- нужна история действий;
- аудит критичен;
- важна отладка процесса.

Хорошая форма:

- событие с типом, actor, payload, timestamp;
- запись события рядом с transition/important action.

Избегать:

- терять историю переходов;
- делать "audit" только текстовыми логами.

## 16. Validation result как тип, а не как строка

Когда использовать:

- when domain validation can fail.

Хорошая форма:

- `Either DomainError a`
- custom error ADT.

Избегать:

- `"invalid"` строками;
- `Bool` без объяснения причины.

## 17. Запрет wildcards на важных ADT

Когда использовать:

- статусах;
- transitions;
- event types.

Хорошая форма:

- явный разбор каждого конструктора.

Избегать:

- `_ -> ...` в критичных ветках.

## 18. Reader-like boundary или явный env

Когда использовать:

- когда хендлеры системно зависят от pool/config.

Хорошая форма:

- единый env или последовательная передача зависимостей.

Избегать:

- случайных глобальных переменных;
- mutable shared state.

## 19. Тесты на allowed и forbidden paths

Когда использовать:

- state machine;
- pricing;
- quote generation.

Хорошая форма:

- happy path;
- invalid transition;
- edge case.

Избегать:

- только smoke test "компилируется".

## 20. Core должен владеть смыслом

Когда использовать:

- всегда при споре "куда положить логику".

Хорошая форма:

- meaning of status, quote, risk, pricing lives in core.

Избегать:

- переносить смысловую логику в Python или UI ради скорости.

## Как использовать этот top-20

Перед задачей на core агенту стоит давать:

1. `CLAUDE_GLOBAL.md`
2. project overlay
3. этот `Top 20`
4. 1-2 локальных reference-snippet

Так агент будет писать не "любой Haskell", а Haskell под нужную архитектуру.
