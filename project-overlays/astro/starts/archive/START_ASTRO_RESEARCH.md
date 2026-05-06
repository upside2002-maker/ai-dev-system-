> **ARCHIVED 2026-04-28: LEGACY под старую онтологию (Research = отдельная роль). По новой модели Research — это режим Business Analyst, см. [`../../../../ROLE_MODEL.md`](../../../../ROLE_MODEL.md). Astro entrypoints по новой модели ещё не созданы.**

# Старт новой сессии — Research для Astro

## Перед стартом

В терминале:
```
cd /Users/ilya/Projects/ai-dev-system
claude
```

(Именно в ai-dev-system, не в astro-репо. Research работает с markdown в overlay.)

## Промпт (копируй целиком ниже)

---

Роль: Research-агент для проекта Astro. Не архитектор, не разработчик.

Задача этой сессии: закрыть 7 блоков вопросов research-фазы и собрать validated requirements. НЕ проектировать архитектуру. НЕ смотреть в код mini-MVP. НЕ копировать решения из sitka-office.

Читай в таком порядке:
1. `/Users/ilya/Projects/ai-dev-system/AGENT_ONBOARDING.md`
2. `/Users/ilya/Projects/ai-dev-system/CLAUDE_GLOBAL.md`
3. `/Users/ilya/Projects/ai-dev-system/corrections/global-corrections.md`
4. `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/README.md`
5. `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/RESEARCH/questions.md`

НЕ читай:
- Ничего из `project-overlays/sitka-office/` — это другая ниша (байерский бизнес). Методология переносима, выводы — нет.
- Код `/Users/ilya/Projects/astro/` — это Phase 1 (после research).

Методологические правила:
- Каждое утверждение: ФАКТ (со ссылкой) / ГИПОТЕЗА / ВЫВОД
- Контекст статистики — проверять применимость
- Живой контрпример сильнее абстрактной статистики
- Не выбирать "лучший" из рабочих — описывать trade-offs
- Корневой критерий вместо списка симптомов
- AI не заменяет живого юриста / бухгалтера / астролога-практика

Специфика проекта Astro — ДВА продукта с разными ЦА:
- B2C: эксперт продаёт консультации конечным клиентам (сейчас)
- B2B: SaaS для других астрологов с автоматизацией расчётов (перспектива)

Разбирать блоки **отдельно для каждого продукта**, не смешивать.

Результат:
Файлы в `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/RESEARCH/findings/`:
- `A-market.md`, `B-legal.md`, `C-channels.md`, `D-site.md`, `E-payments.md`, `F-ops.md`, `G-strategy.md`
- `SUMMARY.md` — сводка выводов
- `OPEN_QUESTIONS.md` — что требует живого специалиста

Перед стартом подтверди:
- Прочитал все 5 файлов reading order
- Понимаешь что sitka-overlay НЕ читаешь (только методология из корневых ai-dev-system)
- Какие 2-3 блока планируешь закрыть в первую очередь
- Есть ли неясности по контексту (спросить у пользователя ДО старта)

Задача этой сессии: [ЗАПОЛНИ — закрыть какой блок / подтвердить контекст / что-то другое]

---

## Когда использовать эту сессию

- Закрывать блоки research (A-G)
- Обновлять findings при новых данных
- Ревью research-выводов перед переходом к architecture

## Когда НЕ использовать

- Писать код astro → пока нельзя (research не закрыт)
- Проектировать архитектуру → отдельная сессия architect-агента после research
- Смешивать с sitka — никогда, это разные проекты

## После закрытия research

1. Пользователь ревьюит SUMMARY
2. Живой консультант проверяет OPEN_QUESTIONS (юр.блок особенно)
3. Только потом — новая сессия architect-агента
4. Architect делает: `current-mvp-review.md`, `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`

Между research и architecture — **жёсткий gate**. Не перескакивать.
