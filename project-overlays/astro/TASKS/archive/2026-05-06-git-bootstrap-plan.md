# TASK: git-bootstrap-plan

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`/Users/ilya/Projects/astro/` содержит реальный продуктовый код (PDF logic, Haskell core, Python services, React frontend), но не находится под git. Это блокирует evidence-rule из `templates/HANDOFFS_TEMPLATE.md`, делает невозможным diff/rollback/cross-session reference и оставляет работу без backup. Пользователь принял решение: план B — `git init` локально + private remote. Однако перед инициализацией нужен **аккуратный include/exclude план**: в репо есть тяжёлые / генерируемые / содержащие персональные данные клиентов файлы, которые в initial commit попадать не должны. Один раз правильно разложить — лучше, чем потом чистить историю через `git filter-repo`.

## Scope

Входит:
- Filesystem-инвентаризация `/Users/ilya/Projects/astro/` через `du -sh`, `find`, `ls -la` — без `git`, без модификаций.
- Классификация по top-level содержимому: что в initial commit, что в `.gitignore`, что требует решения пользователя.
- Особое внимание к чувствительным данным: `data/astro.db` (SQLite с реальными клиентами Марины), `data/pdf/` (сгенерированные PDF с PII клиентов), `data/ephemeris/` (тяжёлые .se1 binary, downloaded artifacts, не source).
- Рекомендация по `.gitignore` (полный текст, готовый к копированию).
- Рекомендация по initial commit — message + предлагаемый порядок шагов.
- Remote strategy: 2-3 варианта с trade-offs, без выбора (выбирает пользователь).
- Pre-init checklist: что пользователь должен явно подтвердить ДО `git init`.
- Post-init smoke checklist: как проверить что `git init` не сломал runtime (`run-local.sh`, тесты, `data/` доступы).
- Артефакт: один новый файл `project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md`.

Не входит:
- любая git-команда: ни `git init`, ни `git add`, ни `git status` в `/Users/ilya/Projects/astro/` (Worker НЕ запускает git в продуктовом пути).
- любая модификация `/Users/ilya/Projects/astro/` файлов (включая `.gitignore` — Worker предлагает текст плана, не пишет файл).
- bump `.overlay-maturity`, создание `CURRENT_STATE.md` и пр.
- правка `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`.
- решение по выбору remote hosting — только перечислить варианты.
- решение про сохранение/несохранение существующего `data/astro.db` — Worker фиксирует факт «PII внутри», предлагает options, выбор за пользователем.

## Files

- new:    `project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md`
- modify: —
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких модификаций, включая `.gitignore` (он там уже есть размером 64 байта; план может его дополнить, но не правит сейчас).
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, `current-mvp-review.md` — только цитировать.
- `project-overlays/astro/RESEARCH/**` — только ссылаться при необходимости.
- `project-overlays/astro/starts/**` — не трогать TECH_LEAD.md / archive.
- любые другие TASK / HANDOFF.

## Acceptance criteria

- [ ] Создан `project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md` со следующими разделами (порядок жёсткий):
  1. Цель плана + scope (что план делает, что не делает; явно: «Worker этот план не исполняет»).
  2. Filesystem inventory — таблица top-level директорий с `du -sh` и кратким классификатором (source / generated / cache / data / config / ephemeris-binary / sensitive). Числа — реальные, через команду, не из памяти.
  3. Sensitive content review — отдельный подраздел про PII в `data/astro.db`, `data/pdf/`, любые .env/secrets если найдены.
  4. Include в initial commit — список путей с обоснованием.
  5. Exclude через `.gitignore` — полный готовый текст файла, аннотированный.
  6. Remote strategy — 2-3 варианта (минимум: GitHub private, self-hosted Gitea/Forgejo на VPS, локально-только без remote) с trade-offs по deployability/backup/sharing/cost.
  7. Pre-init checklist — что пользователь подтверждает ДО `git init` (например: текущий `data/astro.db` забэкаплен / решение про PII принято / выбран remote / etc.).
  8. Init procedure — пошаговая последовательность команд, готовая к копированию (но НЕ исполняемая Worker'ом).
  9. Post-init smoke checklist — что проверить после init (du -sh .git, `run-local.sh` поднимается, pytest зелёный, `data/astro.db` НЕ в git, .ephemeris files НЕ в git).
  10. Open questions — что осталось pending и ждёт пользователя.
- [ ] Filesystem inventory собран **commands, не из памяти**: `du -sh /Users/ilya/Projects/astro/*` + `find /Users/ilya/Projects/astro -type d -name node_modules` + `find -type d -name .venv` + `ls -la /Users/ilya/Projects/astro/data/`. Цитаты команд в плане.
- [ ] `data/astro.db` явно отмечен как PII (содержит реальных клиентов Марины — `Наталья`, `Евгения` и др.). План фиксирует: НЕ коммитим. Альтернативы (seed sample DB / отдельный private storage / etc.) перечислены, выбор за пользователем.
- [ ] `.gitignore` рекомендация включает (минимум): `data/astro.db`, `data/pdf/`, `data/ephemeris/`, `node_modules/`, `.venv/`, `dist-newstyle/`, `dist/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `.DS_Store`, `*.swp`, `/tmp/*`. Каждое — с одно-строчным обоснованием.
- [ ] Worker не запускает `git init` / `git add` / `git status` в `/Users/ilya/Projects/astro/`. `git rev-parse` для evidence (что repo всё ещё нет) — допускается.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает TASK прошедшим лайфцикл (open → review → done после accept).

## Test commands

```
# Filesystem inventory commands (Worker запускает чтобы написать план):
du -sh /Users/ilya/Projects/astro/*
find /Users/ilya/Projects/astro -maxdepth 3 -type d -name node_modules
find /Users/ilya/Projects/astro -maxdepth 3 -type d -name .venv
find /Users/ilya/Projects/astro -maxdepth 3 -type d -name dist-newstyle
find /Users/ilya/Projects/astro -maxdepth 3 -name '*.se1' | head
ls -la /Users/ilya/Projects/astro/data/
ls -la /Users/ilya/Projects/astro/.gitignore
sqlite3 /Users/ilya/Projects/astro/data/astro.db "SELECT count(*) FROM persons; SELECT count(*) FROM consultations" 2>/dev/null

# Verify nothing changed in product path:
ls -la /Users/ilya/Projects/astro/.git 2>&1 | head -1   # должно остаться "No such file"

# Workflow checks:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff` (без manual touch файла), затем заполняет body. В шапке обязательно:
- `Agent runtime: Claude Code`
- `Model: Claude Opus`
- `Role mode: Worker`
- `TASK:` ссылка на `TASKS/2026-05-06-git-bootstrap-plan.md`

В теле обязательно:
- список созданных файлов (один: новый markdown);
- результат filesystem-инвентаризации в кратком виде (top-3 размеров директорий + наличие/отсутствие node_modules / .venv / dist-newstyle);
- подтверждение что `data/astro.db` существует и содержит persons (число);
- подтверждение что `.git` всё ещё отсутствует (filesystem evidence);
- результат `make check` и `make status SLUG=astro`;
- **`Product repo status:` `not a git repo at /Users/ilya/Projects/astro root / decision pending`**;
- явная фраза: «Worker не выполнял git init / git add / git status в продуктовом пути»;
- ссылка на open questions из плана.

После HANDOFF — `make submit-task FILE=…`. TL не делает manual edit `Status:`.

Reviewer не запрашивается (Tier C docs-only). Если TL по результатам HANDOFF решит — отдельный шаг.
