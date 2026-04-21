# AI Dev System — Refresh 2026-04-21

Область изменений: только `ai-dev-system`.

Цель: безопасно подтянуть `sitka-office` overlay к реальному состоянию
проекта и добавить минимальную механику самопроверки, не трогая сам
`sitka-office`.

## Было

1. `project-overlays/sitka-office/` не имел `README.md`, хотя
   `AGENT_ONBOARDING.md` отправляет агента именно в
   `project-overlays/[slug]/README.md`.
2. `CURRENT_STATE.md`, `NEXT_ACTIONS.md`, `PROJECT_MAP.md`,
   `KNOWN_ISSUES.md` были зафиксированы вокруг `2026-04-16` и описывали
   проект как "после Phase 0 / в начале Phase 1".
3. Root `README.md` показывал сильно урезанную и уже неактуальную
   структуру системы.
4. Не было даже минимальной механической проверки, что overlay не отстал
   от реального repo.
5. `.gitignore` не игнорировал `.claude/worktrees/` и мусорные
   `.DS_Store`, из-за чего служебные артефакты легко начинали выглядеть
   частью системы.

## Стало

1. Добавлен `project-overlays/sitka-office/README.md` как нормальная
   точка входа в overlay.
2. `CURRENT_STATE.md` переписан под актуальную форму проекта:
   post-Phase-DM, lead-first flow, message inbox, treasury,
   conversations.
3. `NEXT_ACTIONS.md` больше не ведёт в старый "Phase 1 — Marketing
   Analytics MVP" как будто это ближайший шаг. Теперь там текущий
   practical focus.
4. `PROJECT_MAP.md` обновлён под реальную кодовую карту:
   `Person/Lead/Treasury/Messages` вместо старой client-first схемы.
5. `KNOWN_ISSUES.md` очищен от phase-0 исторического шума и теперь
   фиксирует живые проблемы текущей формы проекта.
6. Root `README.md` обновлён: отражает overlay README, scripts и текущую
   роль репозитория.
7. Добавлен `scripts/check-overlay-consistency.sh`:
   - проверяет обязательные файлы overlay
   - требует `Snapshot commit:` в `CURRENT_STATE.md`
   - сверяет snapshot с HEAD целевого repo
8. `.gitignore` расширен служебными исключениями.
9. Добавлен `scripts/check-system-structure.sh`:
   - проверяет обязательные root docs
   - проверяет базовый sitka overlay entrypoint
   - страхует onboarding/readme от молчаливого расползания
10. Добавлен `Makefile` с `make check` как единым входом в self-checks.
11. Добавлен `.claude/README.md`, чтобы `worktrees/` больше не выглядели
    частью основного knowledge surface.

## Изменённые файлы

- `README.md`
- `AGENT_ONBOARDING.md`
- `.gitignore`
- `.claude/README.md`
- `project-overlays/sitka-office/README.md`
- `project-overlays/sitka-office/CURRENT_STATE.md`
- `project-overlays/sitka-office/NEXT_ACTIONS.md`
- `project-overlays/sitka-office/PROJECT_MAP.md`
- `project-overlays/sitka-office/KNOWN_ISSUES.md`
- `scripts/check-overlay-consistency.sh`
- `scripts/check-system-structure.sh`
- `Makefile`
- `SYSTEM_REFRESH_2026-04-21.md`

## Не менялось специально

- код `sitka-office`
- доменная модель `sitka-office`
- тесты / CI целевого продукта
- `.claude/worktrees/` содержательно — только добавлен ignore, без ломки
  текущего рабочего процесса

## Как проверять дальше

```bash
/Users/ilya/Projects/ai-dev-system/make check
# или точечно
/Users/ilya/Projects/ai-dev-system/scripts/check-system-structure.sh
/Users/ilya/Projects/ai-dev-system/scripts/check-overlay-consistency.sh sitka-office
```

Если `sitka-office` меняет HEAD, а overlay не обновлён, скрипт будет
падать с ошибкой и явно покажет рассинхрон snapshot'а.
