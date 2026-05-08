# Git Bootstrap — Execution Checklist (local-only + local bare backup)

**Дата:** 2026-05-06.
**Контекст:** см. [`git-bootstrap-plan.md`](git-bootstrap-plan.md) (полный inventory, sensitive review, обоснование `.gitignore`). Этот файл — финальный execution checklist после того, как пользователь выбрал стратегию.

**Решение пользователя:** local-only git, **без** GitHub / GitLab / Gitea / VPS-remote. Цель init — локальная история, evidence для AI Dev System, возможность rollback. Backup — локальный bare repo `/Users/ilya/Backups/astro.git`, плюс рекомендации по retention.

**ВАЖНО:** Worker этот checklist **не исполняет**. Каждая команда префиксована «👤 пользователь копирует». Worker фиксирует только filesystem evidence через read-only `ls` / `cat` / `find`.

---

## Step 1 — `.gitignore` patch

### 1.1 Текущий `.gitignore` (5 значимых строк, верифицировано `cat`)

```gitignore
dist-newstyle/
**/__pycache__/
*.pyc
node_modules/
/data/
*.se1
```

### 1.2 Target `.gitignore` (полный финальный текст)

```gitignore
# ── Build artifacts ─────────────────────────────────────────────
dist-newstyle/
node_modules/
dist/

# ── Language caches / bytecode ──────────────────────────────────
**/__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/
.ruff_cache/

# ── Python virtual environments ─────────────────────────────────
.venv/
venv/
env/

# ── Operational data (PII + generated + binary) ─────────────────
/data/
*.se1

# ── OS / editor noise ───────────────────────────────────────────
.DS_Store
Thumbs.db
*.swp
*.swo
.idea/
.vscode/
*~

# ── Secrets ─────────────────────────────────────────────────────
.env
.env.local
.env.*.local

# ── Coverage / profiling ────────────────────────────────────────
.coverage
htmlcov/
*.cover
.hypothesis/
```

Обоснование каждой строки — см. `git-bootstrap-plan.md § 5`. Здесь — финал, готовый к копированию.

### 1.3 Самый критичный gap

`.venv/` **отсутствует** в текущем `.gitignore`. Без него `git add -A` затащит `services/api-python/.venv/` (≈ 210 MB). Фиксится этим патчем.

### 1.4 Команды (👤 пользователь копирует)

```bash
# Worker НЕ выполняет; пользователь копирует.
# Заменить .gitignore целиком на target из § 1.2.
cd /Users/ilya/Projects/astro

cat > .gitignore <<'EOF'
# ── Build artifacts ─────────────────────────────────────────────
dist-newstyle/
node_modules/
dist/

# ── Language caches / bytecode ──────────────────────────────────
**/__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/
.ruff_cache/

# ── Python virtual environments ─────────────────────────────────
.venv/
venv/
env/

# ── Operational data (PII + generated + binary) ─────────────────
/data/
*.se1

# ── OS / editor noise ───────────────────────────────────────────
.DS_Store
Thumbs.db
*.swp
*.swo
.idea/
.vscode/
*~

# ── Secrets ─────────────────────────────────────────────────────
.env
.env.local
.env.*.local

# ── Coverage / profiling ────────────────────────────────────────
.coverage
htmlcov/
*.cover
.hypothesis/
EOF

# Sanity check — критические строки на месте.
grep -qE '^\.venv/$'     .gitignore || echo "FAIL: .venv missing"
grep -qE '^/data/$'      .gitignore || echo "FAIL: /data/ missing"
grep -qE '^\.DS_Store$'  .gitignore || echo "FAIL: .DS_Store missing"
grep -qE '^node_modules/$' .gitignore || echo "FAIL: node_modules missing"
grep -qE '^dist-newstyle/$' .gitignore || echo "FAIL: dist-newstyle missing"
echo "OK: .gitignore patched"
```

---

## Step 2 — Backup `data/astro.db` перед init

PII в БД (см. `git-bootstrap-plan.md § 3.1` — 2 person'а, 9 consultations, реальные имена и даты). Перед любым git-операциями — снимок в безопасное место **вне** проекта.

```bash
# Worker НЕ выполняет; пользователь копирует.
mkdir -p ~/Backups
cp /Users/ilya/Projects/astro/data/astro.db \
   ~/Backups/astro-pre-git-$(date +%F).db

# Verify backup читаем + содержит persons.
sqlite3 ~/Backups/astro-pre-git-$(date +%F).db \
  "SELECT count(*) AS persons FROM persons; \
   SELECT count(*) AS consultations FROM consultations"
# Ожидаемо: persons=2, consultations=9 (или больше если были новые консультации после 2026-05-06).
```

`~/Backups/` сейчас **не существует** (filesystem evidence: `ls /Users/ilya/Backups → No such file or directory`). `mkdir -p` создаёт directory.

---

## Step 3 — `git init` + initial commit

```bash
# Worker НЕ выполняет; пользователь копирует.
cd /Users/ilya/Projects/astro

# Защита от случайного re-init (если этот checklist гоняется второй раз).
test -d .git && { echo "ERROR: .git already exists, aborting"; exit 1; }

# Sanity: .gitignore содержит .venv (защита от 210 MB случайного include).
grep -q '^\.venv/$' .gitignore || { echo "ERROR: .venv missing from .gitignore"; exit 1; }

# Init с branch=main (modern default; -b main поддерживается с git 2.28).
git init -b main

# Configure local user identity (per-repo, не global).
git config user.name  "Ilya"        # 👤 заполнить точное имя
git config user.email "upside2002@gmail.com"

# Stage everything per .gitignore.
git add -A

# Sanity preview перед commit'ом.
echo "Files to commit: $(git ls-files | wc -l)"   # ожидаемо ~500-2000
git status --short | head -20

# Commit.
git commit -m "Initial import: post-Phase 0.10b state

Snapshot of Astro project at the time of git bootstrap.
Project history before this commit lived without VCS;
this is the first version-controlled state.

Stack at this point: Haskell core (cabal) + Python services
(FastAPI + pyswisseph + WeasyPrint) + React frontend.
Phase nomenclature in earlier work followed phases introduced
in product sessions (Phase 0.5 — 0.10b for PDF / themed
synthesis / Solar Arc migration). Reconciliation of these
phases against ARCHITECTURE/PHASE_0_TASKS.md is a candidate
follow-up TASK in the AI Dev System overlay (see README →
Bootstrap risks → 'Architecture drift').
"
```

---

## Step 4 — Проверка что forbidden files не попали

Запускается **сразу** после step 3, до push'а в backup. Если что-то forbidden затащилось — лучше переинит'ить чем потом чистить историю.

```bash
# Worker НЕ выполняет; пользователь копирует.

# 4.1 Проверка по списку forbidden.
echo "=== forbidden files in commit (must be empty) ==="
git ls-files | grep -E '\.venv|node_modules|dist-newstyle|\bdist/|astro\.db|\.DS_Store|\.se1|\.pytest_cache|__pycache__|\.pyc$|\.env$' \
  && { echo "ABORT: forbidden files staged. See troubleshooting."; exit 1; } \
  || echo "OK: no forbidden files"

# 4.2 .git size sanity.
echo ""
echo "=== .git size (expected < 50 MB) ==="
du -sh .git/

# 4.3 File count sanity.
echo ""
echo "=== file counts ==="
echo "  source files:        $(git ls-files | wc -l)"
echo "  Haskell (.hs):       $(git ls-files | grep -c '\.hs$')"
echo "  Python  (.py):       $(git ls-files | grep -c '\.py$')"
echo "  TS/TSX:              $(git ls-files | grep -cE '\.(ts|tsx)$')"
echo "  JSON contracts:      $(git ls-files | grep -c '^packages/contracts/.*\.json$')"
echo "  fixtures:            $(git ls-files | grep -c '^packages/test-fixtures/')"
```

### 4.4 Что делать если что-то forbidden попало

```bash
# Worker НЕ выполняет; troubleshooting для пользователя.
# БЕЗОПАСНО потому что только что init'нулись, backup repo ещё не создан.

cd /Users/ilya/Projects/astro
rm -rf .git

# Открыть .gitignore, дописать недостающее правило, пересохранить.
# Затем повторить Step 3.
```

---

## Step 5 — Создать локальный bare backup repo

Bare repo — это git-репозиторий без working tree (нет checkout'а файлов, только objects + refs). Используется как destination для push'а: компактнее, проще, и явно сигнализирует «это backup, не working copy».

```bash
# Worker НЕ выполняет; пользователь копирует.

# Создать bare repo. Path-name по аналогии с `<project>.git` — git convention для bare.
git init --bare /Users/ilya/Backups/astro.git

# Verify.
ls -la /Users/ilya/Backups/astro.git/
# Ожидаемо: HEAD, config, description, hooks/, info/, objects/, refs/
# (без папки working tree — это и есть bare)

du -sh /Users/ilya/Backups/astro.git/
# Сразу после init: ~ 100 KB (пустой). После первого push'а — ≈ размер .git/ working repo.
```

**Не SSH, не URL — обычный filesystem path.** Git нормально работает с local paths как remotes (это не hack — официально supported).

---

## Step 6 — Push в bare backup: Pattern A vs Pattern B

Два паттерна с одинаковым результатом, разные ergonomics. **Рекомендация Worker'а: Pattern A** (registered remote с привычными `git push` командами).

### Pattern A (рекомендуемый): registered remote с именем `backup`

Имя `backup` (а не `origin`) — намеренный выбор: `origin` подразумевает collaboration upstream; `backup` явно говорит «это backup, не upstream».

```bash
# Worker НЕ выполняет; пользователь копирует.
cd /Users/ilya/Projects/astro

git remote add backup /Users/ilya/Backups/astro.git
git push backup main

# Verify.
git remote -v
# Ожидаемо:
#   backup  /Users/ilya/Backups/astro.git (fetch)
#   backup  /Users/ilya/Backups/astro.git (push)

git ls-remote backup main
# Ожидаемо: <commit-sha>  refs/heads/main
# (тот же commit-sha что и `git rev-parse HEAD` в working repo)
```

**Дальнейшая работа:**
- После каждой сессии (или daily): `git push backup main`.
- Если появятся branches: `git push backup --all` или per-branch.
- Tags: `git push backup --tags`.

### Pattern B: ad-hoc `git push --mirror`

Без registered remote. Один command. Минус — каждый раз пишется полный path; нет audit trail в `git remote -v`.

```bash
# Worker НЕ выполняет; пользователь копирует — альтернатива Pattern A.
cd /Users/ilya/Projects/astro
git push --mirror /Users/ilya/Backups/astro.git
# --mirror толкает ВСЕ refs (branches, tags, notes); destructive если на той стороне есть лишнее.
# На свежем bare repo это эквивалентно Pattern A first push.
```

### Когда какой использовать

- **Pattern A** — daily / per-session backup. Push через привычный `git push backup main`. Можно завернуть в alias.
- **Pattern B** — periodic «mirror everything» snapshot, например еженедельный.

### Опционально: shell wrapper для one-button backup

```bash
# Worker НЕ выполняет; suggestion для пользователя — после Pattern A setup.
# ~/bin/astro-backup (создать после init):
cat > ~/bin/astro-backup <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /Users/ilya/Projects/astro
git push backup --all
git push backup --tags
echo "OK: pushed all branches + tags to /Users/ilya/Backups/astro.git"
EOF
chmod +x ~/bin/astro-backup

# Использование: $ astro-backup
```

---

## Step 7 — Post-init smoke

Все проверки read-only. Запускаются после Step 6.

```bash
# Worker НЕ выполняет; пользователь копирует.
cd /Users/ilya/Projects/astro

echo "=== 1. .git/ size sanity ==="
du -sh .git/
# < 50 MB ожидаемо. Если больше — что-то heavy попало (см. Step 4.4).

echo ""
echo "=== 2. forbidden files in committed tree (must all be empty) ==="
git ls-files | grep '\.venv'        || echo "  OK: no .venv"
git ls-files | grep 'node_modules'  || echo "  OK: no node_modules"
git ls-files | grep 'dist-newstyle' || echo "  OK: no dist-newstyle"
git ls-files | grep '/dist/'        || echo "  OK: no dist/"
git ls-files | grep 'astro\.db'     || echo "  OK: no astro.db"
git ls-files | grep '\.se1'         || echo "  OK: no .se1"
git ls-files | grep '\.DS_Store'    || echo "  OK: no .DS_Store"
git ls-files | grep '\.env'         || echo "  OK: no .env"

echo ""
echo "=== 3. Backup remote configured + reachable ==="
git remote -v
git ls-remote backup main
# Должно показать тот же commit-sha что HEAD.

echo ""
echo "=== 4. HEAD сравнение working ↔ backup ==="
echo "  working HEAD: $(git rev-parse HEAD)"
echo "  backup main:  $(git ls-remote backup main | awk '{print $1}')"
# Две строки ↑ должны совпасть.

echo ""
echo "=== 5. runtime smokes ==="
./run-local.sh &
sleep 8
curl -s -o /dev/null -w "API health: %{http_code}\n" http://127.0.0.1:8000/api/v1/health
curl -s -o /dev/null -w "Vite root:  %{http_code}\n" http://127.0.0.1:3000/
pkill -f uvicorn || true
pkill -f vite    || true
# Ожидаемо: API 200, Vite 200.

echo ""
echo "=== 6. test suites ==="
( cd core/astrology-hs && cabal test 2>&1 | tail -3 )
( cd services/api-python && . .venv/bin/activate && pytest -x -q 2>&1 | tail -3 )
( cd apps/web-react && ./node_modules/.bin/tsc --noEmit && echo "tsc OK" )

echo ""
echo "=== 7. backup file count consistency ==="
git ls-files | wc -l                                | xargs echo "  working files:"
GIT_DIR=/Users/ilya/Backups/astro.git git ls-tree -r main | wc -l | xargs echo "  backup files: "
# Должны совпасть.
```

Если любой пункт падает — НЕ commit'ить «исправление на ходу». Investigate, понять root cause, при необходимости — `rm -rf .git && rm -rf /Users/ilya/Backups/astro.git`, начать с Step 1. Безопасно потому что backup'ов истории нет (только-что init'нулись).

---

## Backup retention рекомендация

Минимум:
- **После каждой осмысленной серии коммитов** (≈ конец session): `git push backup main` (Pattern A).
- **Раз в неделю**: `cd /Users/ilya/Projects/astro && tar czf ~/Backups/astro-git-$(date +%F).tgz .git` — time-stamped tarball всего `.git/` на тот же или отдельный физический носитель. Это catastrophic-recovery snapshot: если оба `.git/` working и `astro.git/` bare умрут в один день (диск), tarball вытаскивает.

Опционально:
- **launchd / cron**: ежедневный `astro-backup` script. Пример launchd plist для macOS:
  ```xml
  <!-- ~/Library/LaunchAgents/com.local.astro-backup.plist -->
  <plist version="1.0">
    <dict>
      <key>Label</key><string>com.local.astro-backup</string>
      <key>ProgramArguments</key>
      <array>
        <string>/Users/ilya/bin/astro-backup</string>
      </array>
      <key>StartCalendarInterval</key>
      <dict><key>Hour</key><integer>23</integer><key>Minute</key><integer>00</integer></dict>
    </dict>
  </plist>
  ```
  Активация: `launchctl load ~/Library/LaunchAgents/com.local.astro-backup.plist`.
- **External drive**: периодически `rsync ~/Backups/astro.git /Volumes/<external>/astro-backup/`.
- **macOS Time Machine** автоматически бэкапит `~/Backups/` если включён. Это **дополнение**, не замена: Time Machine может пропустить point-in-time recovery, и если домашняя директория повреждена логически (не физически), Time Machine отдаст повреждённое.

---

## What changes after success

После успешного init + первого push в backup, в overlay'е появится несколько микро-обновлений (отдельный TL мини-TASK, не часть этого checklist'а):

- `Product repo status:` в Astro HANDOFF переключается с фиксированной «not a git repo at … / decision pending» на нормальные значения из `templates/HANDOFFS_TEMPLATE.md`: `committed` / `intentionally uncommitted (Tier C docs)` / `not applicable` / `dirty (см. Conflicts)`.
- Evidence rule (Correction 010 в `BASELINE.md`) — в силе для Astro: каждая ссылка на дату commit'а через `git log --pretty='%h %ad'`. Формат: `commit abc1234 (2026-05-06)`.
- README → секция «Bootstrap risks» → подсекция #1 «Продуктовый repo не под git» **снимается** или переписывается как историческая заметка.
- `starts/TECH_LEAD.md` → «Bootstrap status» подсекция аналогично обновляется.
- Drift check для Astro переключается с filesystem-only на нормальный `git log` сравнение с overlay snapshot.
- TL может начать работу над «Architecture drift reconciliation» (`target-architecture.md § 6` vs реальный код post-Phase-0.10b) — теперь будут commits, к которым можно делать ссылки в HANDOFF.

Этот мини-TASK подождёт явного go от пользователя после прохождения Steps 1-7.
