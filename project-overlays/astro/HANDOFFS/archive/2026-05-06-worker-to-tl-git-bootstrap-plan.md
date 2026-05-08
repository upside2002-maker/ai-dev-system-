# HANDOFF: worker → tl — git-bootstrap-plan

- Status: closed
- Date: 2026-05-06 16:53
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-06-git-bootstrap-plan.md

## Summary

Создан `project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md` (385 строк, 11 разделов в требуемом порядке): filesystem inventory через `du -sh` + `find` + `sqlite3`, sensitive content review с фиксацией PII в `data/astro.db` (2 person'а — реальные клиенты), полный готовый `.gitignore`, 3 варианта remote с trade-offs, pre-init и post-init checklists, init procedure с пошаговой command sequence. **Worker не запускал ни одной `git`-команды в `/Users/ilya/Projects/astro/`** — только `ls -la /Users/ilya/Projects/astro/.git` (filesystem evidence отсутствия repo). Plan-only результат, ничего не инициализировано.

## Done

- Создан `project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md` (385 строк), 11 жёстких разделов из acceptance criteria.
- Filesystem inventory собран командами:
  - `du -sh /Users/ilya/Projects/astro/* /Users/ilya/Projects/astro/.[a-zA-Z]*` — top-level sizes
  - `find -maxdepth 4 -type d -name {node_modules,.venv,dist-newstyle,.pytest_cache}` — heavy dirs locations
  - `find -maxdepth 4 -name '*.se1'` — ephemeris check
  - `ls -la /Users/ilya/Projects/astro/data/` — data dir contents
  - `sqlite3 data/astro.db "SELECT count(*) FROM persons; SELECT count(*) FROM consultations"` — PII confirmation (2 persons, 9 consultations)
  - `sqlite3 data/astro.db "SELECT id, full_name, birth_date, birth_place FROM persons LIMIT 5"` — names cited literally в plan'e
  - `find -name '.env*' -o -name '*secret*'` — пусто (хорошо)
- `.gitignore` рекомендация (§ 5 plan'а) включает все 13 обязательных позиций: `data/astro.db` (через `/data/`), `data/pdf/` (через `/data/`), `data/ephemeris/` (через `/data/` + `*.se1` defensive), `node_modules/`, `.venv/`, `dist-newstyle/`, `dist/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `.DS_Store`, `*.swp`, и существующие `*.se1`. Каждое строкой с обоснованием.
- 3 варианта remote (R1 GitHub private / R2 self-hosted Gitea на VPS / R3 локально-только) с trade-offs по deployability/backup/cost, **без выбора** (выбор за пользователем).
- 6 open questions явно перечислены в § 10 — каждое требует решения пользователя.

## Remaining

Pending у пользователя (не Worker):
1. Решение R1 / R2 / R3 для remote.
2. Решение A / B / C для `data/astro.db` (Worker рекомендует A — exclude через `/data/`).
3. Подтверждение что нет старого remote, который надо подключить (filesystem evidence — нет `.git/config`, но Worker не может знать историю).
4. `git config user.name` / `user.email` для commit attribution.
5. Подтверждение «пользователь сам делает push первым», не AI.
6. Опциональный update `starts/TECH_LEAD.md` + README после успешного init (отдельный мини-TASK).

## Artifacts

- branch:               n/a (AI Dev System repo: working-tree edit; продуктовый repo всё ещё не существует)
- commit(s):            ещё не закоммичено (TL accept'нет → отдельный коммит в ai-dev-system)
- PR:                   n/a (внутренний docs-only TASK, без PR-flow)
- tests:                `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки (overlay astro = `pre-phase0`-валидный)
- Product repo status:  **not a git repo at /Users/ilya/Projects/astro root / decision pending**

Filesystem evidence (re-checked at HANDOFF time):
```
$ ls -la /Users/ilya/Projects/astro/.git
ls: /Users/ilya/Projects/astro/.git: No such file or directory

$ wc -l project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md
     385

$ make check 2>&1 | tail -2
OK: overlay 'astro' is at maturity=pre-phase0 (README only; CURRENT_STATE/etc. expected after Phase 0 — bump to 'active' then).
```

**Worker не выполнял `git init` / `git add` / `git status` в `/Users/ilya/Projects/astro/`.** Единственная git-related команда — `ls -la .git` (filesystem evidence что repo нет). `git rev-parse --show-toplevel` запускался один раз на recon-stage предыдущего TASK для фиксации того же факта, в этом TASK не повторялся.

(Evidence rule для git-hash к датам PR не применим — по той же причине что в предыдущем TASK: ai-dev-system правки сами не закоммичены до accept-task, продуктовый repo как git-repo не существует вообще.)

## Conflicts / risks

- **Существующий `.gitignore` уже содержит 5 правильных строк** (`dist-newstyle/`, `**/__pycache__/`, `*.pyc`, `node_modules/`, `/data/`, `*.se1`). План **расширяет** его на 22 строки (см. § 5). Перед `git init` пользователь должен заменить `.gitignore` на расширенную версию из плана **до** первого `git add`. План это явно отмечает в § 8 step 1 / sanity check в step 2.
- **`.venv/` отсутствует в существующем `.gitignore`** — это критический gap. При `git add -A` без plan'овского .gitignore попадёт ~210 MB Python deps. План это отмечает в § 5 с пометкой `# new — services/api-python/.venv (CRITICAL: ~210 MB)`.
- **`data/ephemeris/` сейчас пуст** (`find ... '*.se1' | wc -l → 0`). Существующий `/data/` уже исключает каталог; превентивный `*.se1` остаётся для случая, если эфемериды попадут в нестандартное место.
- **PII в `data/astro.db`**: реальные имена клиентов («Евгения», «наташа») и даты рождения. Если пользователь в будущем когда-либо нарушит план и сделает `git add data/astro.db` — PII попадёт в historical log даже после `git rm`. План этому посвящает § 3.1 + § 7 (pre-init checklist обязывает backup БД до init, чтобы accidental drop не убил данные).

## Next step

TL принимает HANDOFF через `make accept-handoff FILE=…`, затем TASK через `make accept-task FILE=…`. После accept TASK уезжает в `TASKS/archive/`, HANDOFF — в `HANDOFFS/archive/`.

После accept мяч у пользователя:
1. Прочитать план (`project-overlays/astro/ARCHITECTURE/git-bootstrap-plan.md`).
2. Пройти Pre-init checklist (§ 7).
3. Принять решения по 6 open questions (§ 10).
4. Выполнить Init procedure (§ 8) — **сам**, не AI.
5. Пройти Post-init smoke checklist (§ 9).
6. Дать TL go на отдельный мини-TASK обновления `starts/TECH_LEAD.md` + README после успешного init (где «нет git» меняется на «есть git, evidence rule в силе»).

Reviewer не запрашивался (Tier C docs-only). Если TL по результатам HANDOFF решит запросить ревью — это будет отдельный шаг с собственным `make new-handoff FROM=reviewer TO=tl`.
