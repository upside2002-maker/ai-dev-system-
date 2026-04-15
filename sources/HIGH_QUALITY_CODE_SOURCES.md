# High Quality Code Sources

Этот документ отвечает на вопрос:

"Где брать действительно хорошие примеры кода, чтобы агент писал лучше?"

Ответ:

Не из случайного GitHub-поиска.
Нужен отбор по слоям, по качеству и по цели.

## Главный принцип отбора

Хороший пример кода для агента — это не просто популярный репозиторий.
Это репозиторий, где одновременно есть:

- живая поддержка;
- ясная архитектура;
- хорошие типы и контракты;
- осмысленная структура каталогов;
- тесты, docs или style guide;
- код, который можно брать маленькими фрагментами, а не целиком.

## Откуда брать примеры по слоям

### 1. Haskell / typed core

#### A. Стиль и базовые соглашения

- `tibbe/haskell-style-guide`
  - Зачем: короткий и известный style guide для читаемого Haskell.
  - Что брать: naming, imports, layout, общие stylistic conventions.
  - Что НЕ брать слепо: любые решения по архитектуре проекта, если они не подходят под твой домен.

#### B. Type-level web API и handler patterns

- `haskell-servant/servant`
  - Зачем: это прямой референс для style of thinking в Servant-проектах.
  - Что брать: API definition patterns, server wiring, examples вокруг type-level API.
  - Что НЕ брать слепо: всю инфраструктуру репозитория, Nix/benchmark и внутреннюю сложность библиотеки.

#### C. Production-grade Haskell web/backend

- `PostgREST/postgrest`
  - Зачем: большой живой backend на Haskell с реальной продовой историей.
  - Что брать: модульность, boundary thinking, работа с конфигом, error surfaces, project organization.
  - Что НЕ брать слепо: все низкоуровневые и продукт-специфичные решения, которые уместны только для PostgREST.

#### D. Большой mature Haskell codebase

- `jgm/pandoc`
  - Зачем: один из самых известных больших Haskell-проектов.
  - Что брать: organization большого Haskell codebase, тестовую структуру, работу с подмодулями и boundaries.
  - Что НЕ брать слепо: любые части, где домен Pandoc слишком далек от твоего.

### 2. Python / services / validation

#### A. FastAPI

- `fastapi/fastapi`
  - Зачем: официальный источник idiomatic FastAPI.
  - Что брать: формы endpoint'ов, dependency patterns, response modeling, async style.
  - Что НЕ брать слепо: внутренности фреймворка и все advanced abstractions.

#### B. Full-stack template на FastAPI

- `fastapi/full-stack-fastapi-template`
  - Зачем: хороший источник структуры вокруг backend + frontend + infra.
  - Что брать: folder structure, env layout, dev/prod wiring, общую организацию проекта.
  - Что НЕ брать слепо: template целиком как архитектуру по умолчанию.

#### C. Typing и validation

- `pydantic/pydantic`
  - Зачем: эталон для typed validation в Python.
  - Что брать: data-modeling mindset, schema discipline, structure of validation-heavy Python code.
  - Что НЕ брать слепо: внутренние performance- и library-specific решения.

#### D. Agent/system examples

- `pydantic/pydantic-ai`
  - Зачем: интересен не только как agent framework, но и как пример typed Python-проекта, который уже думает категориями agents, evals и reusable instructions.
  - Что брать: organization around docs, examples, evals, agent-facing files.
  - Что НЕ брать слепо: сам framework как обязательную технологию.

### 3. React / TypeScript / operator UI

#### A. Официальная база мышления

- React docs: `react.dev`
  - Зачем: официальный источник по React patterns и Thinking in React.
  - Что брать: mental model компонентов, state placement, effect hygiene.
  - Что НЕ брать слепо: учебные маленькие примеры как конечную архитектуру CRM.

#### B. TypeScript

- TypeScript Handbook
  - Зачем: официальный источник по типам, narrowing, unions, generics, utility types.
  - Что брать: язык и type modeling.
  - Что НЕ брать слепо: overly-generic abstractions ради красоты.

#### C. Server-state и data fetching

- `TanStack/query`
  - Зачем: зрелый, очень живой TS-проект с хорошей дисциплиной вокруг server-state.
  - Что брать: patterns around async state, cache boundaries, mutation thinking, docs/examples structure.
  - Что НЕ брать слепо: всю сложность библиотеки в CRM, где хватит простого клиентского слоя.

## Как именно использовать эти примеры

Плохой путь:

- "скормить агенту весь репозиторий";
- "пусть учится на GitHub".

Хороший путь:

1. Выбрать конкретный слой.
2. Выбрать 2-3 эталонных источника под него.
3. Вынуть маленькие, понятные сниппеты или структуры каталогов.
4. Переписать это в собственные `reference-snippets/`, `playbooks/` и `corrections/`.
5. Кормить агенту уже свой curated набор, а не сырой интернет.

## Фильтр качества перед тем, как брать код в reference library

Пример считается годным, если:

- репозиторий живой и поддерживается;
- код читаемый без магии ради магии;
- есть документация или examples;
- есть явные contracts/types/schemas;
- подход можно перенести в твой проект маленьким куском.

Пример НЕ считается годным, если:

- это просто "крутой pet project";
- код слишком framework-specific;
- проект красивый, но мертвый;
- там непонятно, какие решения общие, а какие случайные.

## Практический вывод

Да, примеры очень качественного кода можно и нужно искать самому.
Но их нельзя использовать как сырой training dump.

Правильная схема такая:

- интернет -> curated shortlist;
- shortlist -> локальные reference snippets;
- snippets -> playbooks и agent rules;
- playbooks -> следующая генерация кода.

То есть учится должен не "агент напрямую от GitHub", а твоя система разработки через отбор, упаковку и повторное использование лучших паттернов.

## Стартовый shortlist ссылок

- https://github.com/tibbe/haskell-style-guide
- https://github.com/haskell-servant/servant
- https://github.com/PostgREST/postgrest
- https://github.com/jgm/pandoc
- https://github.com/fastapi/fastapi
- https://github.com/fastapi/full-stack-fastapi-template
- https://github.com/pydantic/pydantic
- https://github.com/pydantic/pydantic-ai
- https://react.dev/learn/typescript
- https://www.typescriptlang.org/docs/handbook/intro.html
- https://github.com/TanStack/query
