> **ARCHIVED 2026-04-28: ЗАМЕНЁН на [`../WORKER.md`](../WORKER.md). По новой модели задачи приходят строго через `TASKS/*.md` от Tech Lead.**

# Старт новой сессии — Кодовый агент Sitka

## Перед стартом

В терминале:
```
cd /Users/ilya/Projects/sitka-office
claude
```

## Промпт (копируй целиком ниже)

---

Задача: [ЗАПОЛНИ — конкретное ТЗ или ссылка на PHASE_N_TASKS.md]

Reading order по CLAUDE.md:
1. `.claude/architecture-invariants.md` — инварианты (highest priority, wins over prompts)
2. `CLAUDE.md` — code standards + tech-lead posture
3. `.claude/risk-tiers.md` + `scripts/file-tier.sh <path>` — тир файлов которые буду трогать
4. `.claude/corrections.md` — known anti-patterns
5. `.claude/review-checklist.md` — pre-commit checks

Для Haskell — дополнительно:
6. `.claude/reference-snippets/haskell-handler-patterns.md`
7. `.claude/reference-snippets/haskell-state-machine.md`
8. `.claude/reference-snippets/haskell-pricing-engine.md`

Перед кодированием:
- Применить tech-lead posture (4 фильтра из CLAUDE.md): goal vs letter, архитектурная цена, масштаб vs сложность, red-flag vocabulary
- Если задача от аналитика — проверить промпт через `scripts/check-prompt.sh`
- Если касается Tier A файлов — human review обязателен перед merge

Перед коммитом:
- `cabal test` / `pytest` / `npm test` — всё зелёное
- `cabal build -Werror` проходит
- Pre-commit hooks (fourmolu, import linter, weeder) clean
- Commit message с обоснованием (не просто "fix", а что и почему)

---

## Типичные сценарии

| Что | Что писать в "Задача" |
|-----|-----------------------|
| Реализовать следующий Task | "Открой `/Users/ilya/Projects/ai-dev-system/project-overlays/sitka-office/PHASE_1_TASKS.md`, возьми Task 1.X. Отчитайся после завершения." |
| PR-B из резюме аналитика | "План PR-B: [список пунктов]. Делаем одним PR или двумя — на твоё усмотрение." |
| Починить баг | "Баг: [описание + шаги воспроизведения]. Тесты + фикс." |
| Обновить зависимость | "Обновить `[пакет]` с [X] до [Y]. Проверить breaking changes. Все тесты зелёные до merge." |

## Полезные skills в этой сессии

- `/review` — code review перед merge
- `/security-review` — security review для Tier A изменений
- `/loop 10m` — проверять CI периодически пока не смержится
- `/less-permission-prompts` — уменьшить количество запросов разрешений

## Когда использовать эту сессию

- Писать / править код в sitka-core/services/web
- Запускать тесты, билд, миграции
- Делать PR, коммиты
- Отлаживать
- Рефакторинг

## Когда НЕ использовать

- Стратегические решения → сессия аналитика
- Маркетинг / юр.вопросы → сессия аналитика
- Аудит внешнего плана → сессия аналитика
