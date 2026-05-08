# Git Bootstrap Plan — `/Users/ilya/Projects/astro`

**Дата:** 2026-05-06.
**Контекст:** см. README → секция «Bootstrap risks» и `starts/TECH_LEAD.md` → секция «Bootstrap status». Решение пользователя зафиксировано: вариант B — `git init` локально + private remote.
**Назначение:** аккуратный include/exclude план перед `git init`, чтобы не закоммитить случайно тяжёлые/генерируемые файлы и реальные клиентские PII.

---

## 1. Цель и scope

**Что план делает:**
- Описывает `.gitignore`, который должен лежать в `/Users/ilya/Projects/astro/.gitignore` к моменту первого `git add -A`.
- Описывает что войдёт в initial commit, что — нет.
- Перечисляет 2-3 варианта remote с trade-offs (выбор за пользователем).
- Даёт пошаговую процедуру init и smoke-чеклист после.

**Что план НЕ делает:**
- **Worker этот план не исполняет.** Ни одной `git`-команды в `/Users/ilya/Projects/astro/` не запущено. План — это документ для пользователя; init-шаги выполняет пользователь после явного go.
- Не выбирает remote.
- Не принимает решение про `data/astro.db` (PII): фиксирует факт + варианты, выбор за пользователем.

---

## 2. Filesystem inventory

Собрано через команды (`du -sh`, `find`, `ls`, `sqlite3`) на 2026-05-06, не из памяти. Все цитаты — реальный output.

### 2.1 Top-level директории (отсортировано по размеру)

```
$ du -sh /Users/ilya/Projects/astro/* /Users/ilya/Projects/astro/.[a-zA-Z]*
4.0K   .gitignore
4.0K   CLAUDE.md
4.0K   docker-compose.yml
8.0K   .DS_Store
8.0K   run-local.sh
 12K   infra
 28K   docs
 32K   .claude
800K   data
4.4M   packages
113M   apps
193M   core
214M   services
```

| Path | Размер | Класс | В commit? |
|---|---|---|---|
| `services/` | 214 M | mixed | partial — только src, без `.venv` |
| `core/` | 193 M | mixed | partial — только src, без `dist-newstyle` |
| `apps/` | 113 M | mixed | partial — только src, без `node_modules` и `dist` |
| `packages/` | 4.4 M | source (contracts + fixtures) | YES |
| `data/` | 800 K | sensitive (PII + generated) | NO целиком |
| `.claude/` | 32 K | config (agent instructions) | YES |
| `docs/` | 28 K | source (Markdown documentation) | YES |
| `infra/` | 12 K | config | YES |
| `run-local.sh` | 8 K | source (bootstrap script) | YES |
| `.DS_Store` | 8 K | macOS cruft | NO |
| `docker-compose.yml` | 4 K | config | YES |
| `CLAUDE.md` | 4 K | config (project rules) | YES |
| `.gitignore` | 4 K | config | YES (расширим, см. § 5) |

### 2.2 Source-only размеры (фактическое содержимое, без build-артефактов)

```
$ du -sh apps/web-react/src services/api-python/app services/api-python/tests \
         core/astrology-hs/src core/astrology-hs/test packages docs .claude
180K   apps/web-react/src
596K   services/api-python/app
288K   services/api-python/tests
260K   core/astrology-hs/src
144K   core/astrology-hs/test
4.4M   packages
 28K   docs
 32K   .claude
```

**Итог: реальный source ≈ 6 MB.** Все остальные ~520 MB — `.venv` / `dist-newstyle` / `node_modules` / `dist` / cache / data.

### 2.3 Тяжёлые директории к exclude (подтверждено find'ом)

```
$ find /Users/ilya/Projects/astro -maxdepth 4 -type d -name node_modules
/Users/ilya/Projects/astro/apps/web-react/node_modules

$ find /Users/ilya/Projects/astro -maxdepth 4 -type d -name .venv
/Users/ilya/Projects/astro/services/api-python/.venv

$ find /Users/ilya/Projects/astro -maxdepth 4 -type d -name dist-newstyle
/Users/ilya/Projects/astro/core/astrology-hs/dist-newstyle

$ ls -d /Users/ilya/Projects/astro/apps/web-react/dist
/Users/ilya/Projects/astro/apps/web-react/dist

$ find /Users/ilya/Projects/astro -maxdepth 4 -type d -name '.pytest_cache'
/Users/ilya/Projects/astro/services/api-python/.pytest_cache

$ find /Users/ilya/Projects/astro -name '.DS_Store'
/Users/ilya/Projects/astro/.DS_Store
   total: 1
```

### 2.4 Ephemeris files

```
$ find /Users/ilya/Projects/astro -maxdepth 4 -name '*.se1' | wc -l
0
```

`.se1` файлов сейчас **нет** на диске (директория `data/ephemeris/` пустая). При первом запуске `run-local.sh` они скачиваются через `app/ephemeris/cache.py:ensure_ephemeris_files`. Однако `*.se1` всё равно идёт в `.gitignore` превентивно — иначе при первом запуске после клона разработчик случайно закоммитит ~80 MB бинарей.

---

## 3. Sensitive content review

### 3.1 `data/astro.db` — реальные клиенты Марины

```
$ sqlite3 /Users/ilya/Projects/astro/data/astro.db \
    "SELECT count(*) FROM persons; SELECT count(*) FROM consultations"
2
9

$ sqlite3 /Users/ilya/Projects/astro/data/astro.db \
    "SELECT id, full_name, birth_date, birth_place FROM persons LIMIT 5"
1|Евгения|1979-11-28|Москва
2|наташа|1984-08-07|Москва
```

**В БД**: 2 реальных person'а (Евгения, наташа) с реальными дата+место рождения, плюс 9 консультаций с натальными вычислениями и черновиками. Это **PII** в смысле 152-ФЗ. **НЕ коммитим.**

Варианты для пользователя:
- **A. Просто исключить через `/data/`** (как сейчас в существующем `.gitignore`): продолжаем работать локально, БД не покидает машину. Минимум усилий. Backup БД — вручную через `cp data/astro.db ~/backup/`.
- **B. Исключить + создать `data/sample.db`** с фиктивными person'ами для воспроизводимых тестов / новых разработчиков. Sample DB можно коммитить.
- **C. Исключить + cron-экспорт** в encrypted blob (например через `age` / `sops`) на отдельный private remote. Overkill для MVP-стадии.

**Рекомендация Worker'а:** A на старт. Когда (и если) Astro будет иметь второго разработчика или CI — переход на B.

### 3.2 `data/pdf/` — сгенерированные PDF с PII

```
$ ls -la /Users/ilya/Projects/astro/data/pdf/
total 448
-rw-r--r--@ 1 ilya  staff  226289  consultation-5.pdf
```

`consultation-5.pdf` — последний rendered solar для Натальи, содержит её натальные данные + расшифровки. **PII. НЕ коммитим.** Существующий `.gitignore` уже excludes через `/data/`, но укажем `data/pdf/` явно для defensive depth.

### 3.3 `data/ephemeris/` — Swiss Ephemeris binary

```
$ ls /Users/ilya/Projects/astro/data/ephemeris/
(пусто)
```

Сейчас пусто, но при первом запуске `run-local.sh` загружается ~80 MB `.se1` файлов с публичного источника (Swiss Ephemeris). Это **не source** — это эталонные эфемериды, которые любой пользователь может скачать тем же `cache.py`. Excluded и через `/data/`, и через `*.se1` defensive.

### 3.4 .env / secrets / credentials

```
$ find /Users/ilya/Projects/astro -maxdepth 4 -name '.env*' -o -name '*secret*' -o -name '*credentials*'
(пусто)
```

Сейчас секретов нет (Phase 0 не имеет remote endpoints, OAuth, API ключей). При появлении (например на Phase 1+ для VPS deploy) — обязательно `.env` в `.gitignore` + `.env.example` для шаблона. Превентивно добавлю в plan'овый `.gitignore`.

---

## 4. Include в initial commit

Включаем (по top-level + точечно):

| Path | Почему |
|---|---|
| `apps/web-react/{src,public,index.html,package.json,package-lock.json,tsconfig*.json,vite.config.ts,.claude/}` | React frontend source + manifest для воспроизводимой `npm install` |
| `core/astrology-hs/{src,test,app,*.cabal,cabal.project,LICENSE,README*}` | Haskell core |
| `services/api-python/{app,tests,scripts,pyproject.toml,uv.lock или poetry.lock,README*}` | Python services |
| `packages/{contracts,test-fixtures,rulesets}/` | Cross-layer schemas + golden fixtures + ruleset configs |
| `docs/` | Markdown documentation (включая ADR'ы, design notes) |
| `infra/` | Docker / deploy scripts (если есть) |
| `.claude/` | Agent instructions (architecture-invariants.md, corrections.md, agents/, settings, skills) |
| `CLAUDE.md` | Project rules для агентов |
| `docker-compose.yml` | Compose manifest |
| `run-local.sh` | One-command bootstrap |
| `.gitignore` | (расширенная версия — см. § 5) |
| `README.md` (если появится) | Top-level entry |

**Не включаем точечно:**
- `apps/web-react/node_modules/` — генерируется npm install
- `apps/web-react/dist/` — генерируется vite build
- `services/api-python/.venv/` — генерируется python -m venv
- `services/api-python/.pytest_cache/` — генерируется pytest
- `services/api-python/**/__pycache__/`, `*.pyc` — Python bytecode
- `core/astrology-hs/dist-newstyle/` — генерируется cabal build
- `data/` целиком — PII + генерируемое + binary эфемерид
- `.DS_Store` — macOS cruft

---

## 5. Полный `.gitignore` (готовый к копированию)

Существующий `.gitignore` (5 строк) расширяется до следующего. Добавления отмечены `# new`:

```gitignore
# ── Build artifacts ─────────────────────────────────────────────
dist-newstyle/
node_modules/
dist/                          # new — Vite output (apps/web-react/dist/)

# ── Language caches / bytecode ──────────────────────────────────
**/__pycache__/
*.pyc
.pytest_cache/                 # new — pytest cache directory
.mypy_cache/                   # new — mypy cache (preventive)
.ruff_cache/                   # new — ruff cache (preventive)

# ── Python virtual environments ─────────────────────────────────
.venv/                         # new — services/api-python/.venv (CRITICAL: ~210 MB)
venv/                          # new — common alternative name
env/                           # new — common alternative name

# ── Operational data (PII + generated + binary) ─────────────────
/data/                         # excludes data/astro.db (PII), data/pdf/ (rendered), data/ephemeris/ (binary)
*.se1                          # defensive: Swiss Ephemeris binary outside /data/

# ── OS / editor noise ───────────────────────────────────────────
.DS_Store                      # new — macOS Finder metadata
Thumbs.db                      # new — Windows
*.swp                          # new — vim
*.swo                          # new
.idea/                         # new — JetBrains
.vscode/                       # new — но selectively: .vscode/settings.json иногда хочется хранить; решит пользователь
*~                             # new — emacs backup

# ── Secrets ─────────────────────────────────────────────────────
.env                           # new
.env.local                     # new
.env.*.local                   # new

# ── Coverage / profiling ────────────────────────────────────────
.coverage                      # new
htmlcov/                       # new
*.cover                        # new
.hypothesis/                   # new — property-based tests
```

**Подтверждение что existing 5 строк осталось:** `dist-newstyle/`, `**/__pycache__/`, `*.pyc`, `node_modules/`, `/data/`, `*.se1` — все внутри.

**Не добавлено** (но можно если пользователь захочет):
- `*.log` — Astro currently не пишет .log файлы (uvicorn в /tmp/uvicorn.log, vite в /tmp/vite.log — оба вне репо)
- `.tox/`, `.eggs/`, `*.egg-info/` — Python packaging cruft, добавить если когда-то будет packaged

---

## 6. Remote strategy (3 варианта, выбор за пользователем)

| Вариант | Где | Плюсы | Минусы | Cost |
|---|---|---|---|---|
| **R1. GitHub private** | github.com/<user>/astro (private) | Привычный flow, GitHub Actions для CI «бесплатно», PR-review UI, easy 2FA | US-юрисдикция (для PII клиентов из РФ это **не подходит** для commits с реальной БД — но мы её и не коммитим, source code не PII) | Free для private до 2000 actions-minutes/мес |
| **R2. Self-hosted Gitea/Forgejo** | На VPS (Yandex Cloud / Selectel / VPS, что выберет оператор) | Полный контроль, российская юрисдикция, можно подключить webhooks к будущему deploy | Сам админишь, обновления, backup | ~₽300-500/мес minimum VPS |
| **R3. Локально-только, без remote** | `git init` без `git remote add` | Минимум зависимостей, ничего на стороне | **Нет backup** — если умирает диск, проект потерян. Не подходит для serious project. | 0 |

**Рекомендация Worker'а:** R1 для скорости (source code без PII; БД и PDFs локально), с возможностью миграции на R2 когда Astro перейдёт на VPS deploy в Phase 1+. R3 категорически не рекомендуется — целая работа над PDF/themes/архитектурой висит без backup'а.

**Не рекомендуется** GitHub public — даже если source code «не секретный», `.claude/` директория содержит agent instructions с упоминаниями имён клиентов в corrections (например `corrections.md / Correction 006` упоминает «Наташа» / «Евгения»). Public exposure нежелателен.

---

## 7. Pre-init checklist (пользователь подтверждает ДО `git init`)

- [ ] **Backup `data/astro.db`** в безопасное место **вне** проекта: `cp /Users/ilya/Projects/astro/data/astro.db ~/Backups/astro-pre-git-2026-05-06.db`. Это страховка на случай accidental drop.
- [ ] **Прочитан полный `.gitignore` из § 5**, пользователь согласен.
- [ ] **Решено по `data/astro.db`**: вариант A (просто exclude, рекомендуемый) или B (sample DB) или C (encrypted backup). При A — никаких дополнительных действий.
- [ ] **Выбран remote**: R1 / R2 / R3.
- [ ] **Если R1 (GitHub private)**: создан empty private repo (через web UI / `gh repo create astro --private`). URL зафиксирован. SSH key или PAT настроен.
- [ ] **Если R2 (self-hosted)**: VPS поднят, Gitea/Forgejo установлен, empty repo создан, SSH key настроен.
- [ ] **Confirm нет open uncommitted работы** в продуктовом пути, которую планируется делать прямо сейчас (это будет первый коммит — пусть он зафиксирует stable снимок).
- [ ] **Confirm read README.md → Bootstrap risks** в overlay (там зафиксирована политика «нет git → evidence rule не применяется»). После init политика меняется автоматически: HANDOFF'ы для Astro начнут заполнять `Product repo status:` нормальным `committed` / `intentionally uncommitted (Tier C docs)` и т.п.

---

## 8. Init procedure (готовая последовательность; **Worker не выполняет, выполняет пользователь**)

```bash
# 0. Pre-flight: убедиться что .git ещё нет (защита от случайного re-init)
cd /Users/ilya/Projects/astro
test -d .git && echo "ERROR: .git already exists, aborting" && exit 1

# 1. Расширить .gitignore (заменить содержимое на текст из § 5)
#    — пользователь делает это ВРУЧНУЮ через редактор, до git init
#    — это критично: git init подхватит .gitignore с первого `git add`
#    — если init случится до расширения .gitignore — попадут .venv, .DS_Store, etc.

# 2. Sanity check: проверить что .gitignore содержит .venv
grep -q '^\.venv/' .gitignore || echo "WARN: .gitignore missing .venv/"

# 3. Init
git init -b main

# 4. Configure user (если global config уже стоит — пропустить)
git config user.name  "Ilya …"     # placeholder — пользователь заполнит
git config user.email "…"

# 5. First add — посмотреть ЧТО будет включено перед commit'ом
git add -A
git status --short | head -50      # быстрая верификация
git ls-files | wc -l               # ожидаемо: ~500-2000 файлов (source + tests + fixtures)
git ls-files | grep -E '\.venv|node_modules|dist-newstyle|astro\.db' && \
  echo "ERROR: forbidden files staged — abort, fix .gitignore, git rm --cached, retry" && exit 1

# 6. Initial commit
git commit -m "Initial import: post-Phase 0.10b state

Snapshot of Astro project at the time of git bootstrap.
Project history before this commit lived without VCS;
this is the first version-controlled state.

Phase nomenclature in commit history will follow the
phases introduced in product sessions (0.5 — 0.10b for
PDF / synthesis work) until the overlay's
ARCHITECTURE/PHASE_0_TASKS.md and post-MVP work are
reconciled (see ai-dev-system overlay 'Architecture drift
reconciliation' candidate TASK).
"

# 7. Add remote (зависит от выбора R1/R2)
#    R1 пример (GitHub private):
git remote add origin git@github.com:<user>/astro.git
git push -u origin main

#    R2 пример (Gitea на VPS):
git remote add origin git@gitea.<host>:<user>/astro.git
git push -u origin main

#    R3: пропустить шаг 7
```

---

## 9. Post-init smoke checklist

Сразу после `git init` + `git commit` (до push'а — в случае R1/R2 — после tоже):

- [ ] `du -sh .git/` — ожидаемо < 50 MB (если больше — что-то heavy попало в commit, нужен `git filter-repo` или повторный init с правильным .gitignore).
- [ ] `git ls-files | grep '\.venv'` → empty.
- [ ] `git ls-files | grep 'node_modules'` → empty.
- [ ] `git ls-files | grep 'dist-newstyle'` → empty.
- [ ] `git ls-files | grep 'astro\.db'` → empty.
- [ ] `git ls-files | grep '\.se1'` → empty (не должно быть; превентивно).
- [ ] `git ls-files | grep '\.DS_Store'` → empty.
- [ ] `./run-local.sh` поднимается без ошибок (init ничего runtime не сломал).
- [ ] `cd services/api-python && pytest -x -q` — зелёный (если был зелёный до).
- [ ] `cd core/astrology-hs && cabal test` — зелёный.
- [ ] `cd apps/web-react && npx tsc --noEmit` — exit 0.
- [ ] `git log -1 --stat` — initial commit виден, file count разумный.

Если любой пункт упал — НЕ делать второй commit «исправляя на ходу». Лучше:
- если попал в `.git` heavy file (>10 MB): `rm -rf .git && go to step 1`, скорректировав `.gitignore`. Это безопасно потому что только-что init'нулись, истории нет.
- если runtime сломан: `git status` должен показать что ничего не изменилось в working tree (init это не делает); тогда баг не от git. Investigate отдельно.

---

## 10. Open questions

Пользователь решает (план не выбирает):

1. **Remote: R1 / R2 / R3?** Worker'овы рекомендации в § 6, но это product-level decision (хостинг, юрисдикция, monthly cost).
2. **`data/astro.db` стратегия: A / B / C?** Worker рекомендует A (см. § 3.1).
3. **Подключение к существующему remote**, если у оператора есть архив старого Astro repo откуда-нибудь? Filesystem evidence не показывает следов прошлого remote (нет `.git/config`, нет `.git/HEAD`), но если оператор знает что был старый push куда-то — это меняет процедуру (`git clone <old> + force-update master` вместо `git init`).
4. **Кто `git config user.name` / `user.email`?** Personal или dedicated bot identity для AI-driven commits? Влияет на commit attribution: если позже захочется `git log --author=…` для распознавания «AI-сделанные» commits, лучше отдельный identity.
5. **Кто пушит первым** — пользователь или AI agent? Рекомендация: пользователь, после прохождения post-init checklist. Иначе риск race condition с `.gitignore` adjustments.
6. **Когда переход на TL workflow с git-evidence?** Сразу после успешного push'а: при следующей TL-сессии `starts/TECH_LEAD.md` и README → секцию «Bootstrap risks» можно обновить — git появился, evidence rule снова в силе. Это отдельный маленький TASK (probably ≤30 строк правок, TL может сделать сам под small-patch rule).

---

## 11. Что произойдёт ПОСЛЕ успешного init

(Не часть scope этого TASK, но контекст для пользователя)

- HANDOFF любого Astro Worker'а начнёт заполнять `Product repo status:` нормальным `committed` (или `intentionally uncommitted (Tier C docs)` если задача docs-only без правок source).
- Evidence rule (Correction 010) в силе: каждая ссылка на дату коммита сопровождается short hash через `git log --pretty='%h %ad'`.
- README → секция «Bootstrap risks» → подсекция #1 «Продуктовый repo не под git» **снимается** или переписывается как историческая заметка.
- `starts/TECH_LEAD.md` → «Bootstrap status» подсекция аналогично обновляется.
- Drift check для Astro переключается с filesystem-only на нормальный `git log` сравнение с overlay snapshot.
- Architecture drift по `target-architecture.md § 6` (candidate drift из § 11 plan'а / README) можно начать reconcile-ить отдельным TASK — теперь будут commits, к которым можно ссылаться.
