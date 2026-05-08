# TASK: git-bootstrap-execution

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`git-bootstrap-plan.md` (предыдущий TASK) дал inventory + 3 варианта remote и оставил выбор пользователю. Пользователь выбрал: **local-only git без GitHub/GitLab/etc.**, с обязательным локальным bare backup repo (например `/Users/ilya/Backups/astro.git`). Цель init — не collaboration, а локальная история / evidence для AI Dev System / возможность rollback. Нужен финальный execution checklist с конкретными командами в правильном порядке, готовый к копированию пользователем; Worker checklist не исполняет.

## Scope

Входит:
- Финальный execution checklist (один новый файл `git-bootstrap-execution.md`) с 7 разделами по списку из ТЗ:
  1. `.gitignore` patch (конкретная diff'ом готовая разница против текущего файла из 5 строк).
  2. Backup `data/astro.db` перед init.
  3. `git init` + initial commit.
  4. Проверка что forbidden files не попали (grep по `git ls-files`, `du -sh .git`).
  5. Создание локального bare backup repo (`/Users/ilya/Backups/astro.git`).
  6. Настройка remote `origin` на bare path **или** отдельная команда `backup-push` — оба варианта с trade-offs, рекомендация одного.
  7. Post-init smoke (`run-local.sh`, тесты, no-PII в repo).
- Cross-reference на `git-bootstrap-plan.md § 3 / § 5 / § 9` — не дублировать обоснования, ссылаться.
- Backup retention рекомендация (как часто пушить в bare, время-stamped tarball снимки `.git/` для catastrophic recovery, упомянуть Time Machine на macOS как «free» backup `.git/`).

Не входит:
- любая git-команда: `git init`, `git add`, `git status`, `git push`, `mkdir /Users/ilya/Backups` — Worker не запускает.
- любая модификация `/Users/ilya/Projects/astro/` файлов (`.gitignore` в продуктовом пути остаётся как есть до пользовательского go).
- любая модификация `/Users/ilya/Backups/` (директория может не существовать; Worker не создаёт).
- bump `.overlay-maturity`, создание `CURRENT_STATE.md` и пр.
- правка `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, существующего `git-bootstrap-plan.md`.

## Files

- new:    `project-overlays/astro/ARCHITECTURE/git-bootstrap-execution.md`
- modify: —
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких модификаций.
- `/Users/ilya/Backups/**` — никаких модификаций / создания.
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/{target-architecture,migration-plan,PHASE_0_TASKS,current-mvp-review,git-bootstrap-plan}.md` — только цитировать.
- `project-overlays/astro/starts/**`, `RESEARCH/**`, `archive/**` — не трогать.

## Acceptance criteria

- [ ] Создан `project-overlays/astro/ARCHITECTURE/git-bootstrap-execution.md` со следующими разделами в указанном порядке:
  1. **Цель и связь с предыдущим планом** — 2-3 предложения, ссылка на `git-bootstrap-plan.md`, явный отказ от R1/R2/R3 в пользу «local-only + local bare backup».
  2. **Step 1 — `.gitignore` patch**: показан текущий 5-строчный файл (буквальной цитатой), показан target-файл (полный текст), показан unified diff между ними. Опционально — готовый `cat > .gitignore <<'EOF' ... EOF` блок.
  3. **Step 2 — backup `data/astro.db` перед init**: команда `mkdir -p ~/Backups && cp /Users/ilya/Projects/astro/data/astro.db ~/Backups/astro-pre-git-$(date +%F).db` + verify (`sqlite3 ... "SELECT count(*) FROM persons"`).
  4. **Step 3 — `git init` + initial commit**: `cd /Users/ilya/Projects/astro && test -d .git && exit 1 && git init -b main && git config user.name … && git config user.email … && git add -A && git commit -m "..."`. Commit message multi-line.
  5. **Step 4 — forbidden files check**: `git ls-files | grep -E '\.venv|node_modules|dist-newstyle|astro\.db|\.DS_Store|\.se1' && echo "ABORT"`. + `du -sh .git/` (ожидаемо < 50 MB). + что делать если что-то не так (rm -rf .git → re-fix .gitignore → start over, безопасно потому что истории нет).
  6. **Step 5 — local bare backup repo**: `git init --bare /Users/ilya/Backups/astro.git`. Объяснение что bare — это repo без working tree, только objects+refs, для приёма push'ей. Размер дискa: ~ объём `.git/` в working repo + минимальная metadata.
  7. **Step 6 — push в bare backup**: ОБА варианта с trade-offs:
     - **Pattern A:** `git remote add backup /Users/ilya/Backups/astro.git && git push backup main` (имя remote `backup`, не `origin`, чтобы не путать с collaboration semantics).
     - **Pattern B:** ad-hoc `git push --mirror /Users/ilya/Backups/astro.git` без registered remote.
     Рекомендация одного варианта с обоснованием (Worker мнение: A — push'ы как привычная команда + конкретные branches; mirror — для catastrophic snapshot).
     + опционально: маленький shell wrapper `~/bin/astro-backup` или `make backup` target в проекте.
  8. **Step 7 — post-init smoke**: 11 пунктов из `git-bootstrap-plan.md § 9` адаптированные под local-only + bare backup проверки (`git remote -v` показывает `backup`, `git ls-remote backup main` соответствует HEAD).
  9. **Backup retention** — рекомендация по cadence:
     - manual `git push backup` после каждой осмысленной серии коммитов (≈ daily / per-session);
     - опционально cron / launchd для automatic daily push;
     - time-stamped `.git/` tarball снимок раз в неделю на отдельный физический носитель / external drive (catastrophic recovery scenario);
     - macOS Time Machine как «free» backup `.git/` если включён — упомянуть, не претендовать что заменяет explicit backup.
  10. **What changes after success** — что произойдёт в overlay после успешного init: `Product repo status:` в HANDOFF переключается с фикса «not a git repo» на нормальные значения (`committed` / `intentionally uncommitted (Tier C docs)`); evidence rule (Correction 010) в силе; `starts/TECH_LEAD.md` + README → секция Bootstrap risks #1 → отдельным мини-TASK обновляется (либо удаляется, либо переписывается как историческая заметка).
- [ ] Каждая команда в Steps 2-6 префиксована комментарием «Worker НЕ выполняет; пользователь копирует».
- [ ] Никаких упоминаний GitHub / GitLab / Gitea / VPS — execution checklist чисто local + local bare. Если пользователь когда-то захочет добавить remote — отдельный TASK.
- [ ] Worker не запускает `git`, `mkdir ~/Backups`, или любую модификацию `/Users/ilya/Projects/astro/` или `/Users/ilya/Backups/` в ходе выполнения этой задачи.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки.

## Test commands

```
# Filesystem evidence (Worker запускает чтобы написать checklist):
ls -la /Users/ilya/Projects/astro/.gitignore       # цитата существующего файла
cat /Users/ilya/Projects/astro/.gitignore          # текст существующего .gitignore
ls -la /Users/ilya/Backups 2>&1 | head -3          # если ~/Backups уже существует — упомянуть
ls -la /Users/ilya/Projects/astro/.git 2>&1 | head -1   # должно остаться "No such file"

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff` (без manual touch файла), затем заполняет body. В шапке обязательно:
- `Agent runtime: Claude Code`
- `Model: Claude Opus`
- `Role mode: Worker`
- `TASK:` ссылка на `TASKS/2026-05-06-git-bootstrap-execution.md`

В теле обязательно:
- список созданных файлов;
- цитата текущего `.gitignore` (5 строк) и подтверждение что `git-bootstrap-execution.md § 2` содержит расширенную версию;
- подтверждение что `.git` отсутствует в `/Users/ilya/Projects/astro/` (filesystem evidence);
- подтверждение что `/Users/ilya/Backups/` директория **не создавалась** Worker'ом (если она уже существует — упомянуть факт, ничего не делать);
- результат `make check` и `make status SLUG=astro`;
- **`Product repo status:` `not a git repo at /Users/ilya/Projects/astro root / decision pending`**;
- явная фраза: «Worker не выполнял git / mkdir / cp в продуктовом пути или в ~/Backups»;
- ссылка на разделы checklist'а где зафиксированы options (Pattern A vs B) и рекомендация Worker'а.

После HANDOFF — `make submit-task FILE=…`. TL не делает manual edit `Status:`.

Reviewer не запрашивается (Tier C docs-only). Если TL по результатам HANDOFF решит — отдельный шаг.
