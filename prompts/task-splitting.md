# Task Splitting Prompt Patterns

## Шаблон для core-задачи

Проект: `<repo>/<core-dir>`

Слой: typed core

Задача:
- Измени только `<files>`
- Не трогай services/frontend
- Сначала определи типы и инварианты
- Затем добавь минимальный handler/repo wiring
- Если появляется повторяемый паттерн, выдели helper

Проверка:
- build
- tests
- краткий список реальных инвариантов, которые теперь защищены

## Шаблон для services-задачи

Проект: `<repo>/<services-dir>`

Слой: FastAPI/integrations

Задача:
- Измени только `<files>`
- Не меняй business rules core
- Нормализуй вход
- Явно обработай parser/core failures
- Не смешивай реальные и mock данные без маркировки

Проверка:
- import/app startup
- endpoint smoke test
- что произойдет при external failure

## Шаблон для frontend-задачи

Проект: `<repo>/<web-dir>`

Слой: operator UI

Задача:
- Измени только `<files>`
- Упрости workflow, а не добавь еще одну панель
- Покажи один главный next action
- Технические детали спрячь или переведи в operator language

Проверка:
- build/lint
- что менеджер должен нажать первым
- стало ли меньше когнитивной нагрузки
