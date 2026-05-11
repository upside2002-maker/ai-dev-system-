# HANDOFF: worker → tl — sitka-perimeter-close

- Status: closed
- Date: 2026-05-10 19:35
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-10-sitka-perimeter-close.md

## Summary

P1 perimeter gap закрыт в репо: core/services забиндены к loopback в
`docker-compose.prod.yml` через `ports: !override`, nginx в
`deploy/nginx-prod.conf` требует Basic Auth на `/`, `/api/`, `/services/`,
DEPLOY.md получил новую секцию «6. Защита периметра» с инструкциями
оператора. Все 7 acceptance criteria — green. Изменения **не закоммичены**
в продуктовый repo per TASK guidance (TL делает PR/коммит как часть
accept lifecycle). Один важный нюанс с `!override` тегом — см. Conflicts.

## Done

- `docker-compose.prod.yml` (+18 строк): добавлены `ports: !override
  - "127.0.0.1:8080:8080"` к сервису `core` и `ports: !override
  - "127.0.0.1:8081:8081"` к сервису `services`. Комментарии объясняют
  почему loopback и почему `!override` обязателен (без него compose
  list-merge оставлял `0.0.0.0:8080` от dev).
- `deploy/nginx-prod.conf` (+19/-1 строк): `auth_basic "SITKA"` +
  `auth_basic_user_file /etc/nginx/htpasswd;` добавлены к трём
  location'ам — `location /` (SPA fallback), `location /api/`,
  `location /services/`. Existing `proxy_pass`, `limit_req`,
  `proxy_set_header` директивы НЕ изменены. `location /health`
  оставлен без auth с явным комментарием — нужен docker
  healthcheck'у и операторским smoke-tests, данных не отдаёт.
- `deploy/htpasswd.example` (новый, 975 байт): bcrypt-стиль строка
  `sitka-ops:$2y$05$DUMMY.EXAMPLE.HASH.NEVER.USE.THIS.IN.PRODUCTION...`
  с шапкой комментариев — что это пример, как сгенерировать
  настоящий, куда положить.
- `DEPLOY.md` (+96 строк): новая секция «6. Защита периметра» между
  «5. SSL / TLS» и «Ongoing operations». Содержит a) объяснение
  почему perimeter — единственная линия защиты (web client не
  инжектит Authorization), b) команды генерации htpasswd на сервере
  через `apt-get install apache2-utils` + `htpasswd -B -c`,
  c) snippet `docker-compose.override.yml` для монтирования htpasswd
  как `/etc/nginx/htpasswd:ro` и публикации web на 8088,
  d) curl-команды для проверки 401 без креденшелов и 200 с ними,
  e) одна ремарка про `CORE_AUTH=disabled` (допустим внутри
  закрытого perimeter, не публично).
- TASK Status поднят `open → in-progress` локально (через Edit),
  следующий шаг — `make submit-task` в → `review`.

### Acceptance criteria — поштучно

- [✓] AC1: `docker-compose.prod.yml` core ports — loopback. Подтверждено
  `sed -n '/^  core:/,/^  services:/p' | grep ports` → `ports: !override
  - "127.0.0.1:8080:8080"`.
- [✓] AC2: services ports — loopback. Аналогично: `ports: !override
  - "127.0.0.1:8081:8081"`.
- [✓] AC3: auth_basic на 3 location'ах. Подтверждено `grep auth_basic
  deploy/nginx-prod.conf` → 3 пары `auth_basic "SITKA"` +
  `auth_basic_user_file`. Existing директивы не тронуты (диф +19/-1,
  единственная удалённая строка — пустая комментарий-разделитель,
  заменена расширенным коммент-блоком).
- [✓] AC4: htpasswd.example существует, hash явно dummy
  (`$2y$05$DUMMY.EXAMPLE.HASH.NEVER.USE.THIS.IN.PRODUCTION.PLACEHOLDERaaaaa`),
  два маркера в шапке: «THIS IS A DUMMY EXAMPLE — DO NOT USE IN PRODUCTION»
  и в конце строки сам hash содержит слово DUMMY.
- [✓] AC5: DEPLOY.md секция «6. Защита периметра» — `grep -n` строка 112,
  до «Ongoing operations» (строка 208 после правки).
- [✓] AC6: `make -C /Users/ilya/Projects/ai-dev-system check` — exit 0,
  только WARN про working-tree dirty (per TASK мой write-set 4 файла,
  это ожидаемо).
- [✓] AC7: `POSTGRES_PASSWORD=dummy CORE_API_TOKEN=dummy docker compose
  -f docker-compose.yml -f docker-compose.prod.yml --profile app config`
  — exit 0. Слитый ports у core: один маппинг `host_ip: 127.0.0.1,
  target: 8080, published: "8080"`. У services: `host_ip: 127.0.0.1,
  target: 8081`. У web: `80, 443` без host_ip (публичный фронт,
  ожидаемо). У postgres: `5432:5432` без host_ip (dev compose, не наш
  scope).

## Remaining

Ничего по этой задаче. Дальше — ход TL:

1. Reviewer (cold-start, sitka-reviewer) — review HANDOFF + diff в
   working tree продуктового repo (4 файла).
2. После ACCEPT — TL делает PR/коммит в `sitka-office` (поскольку я
   ничего не коммитил).
3. После merge — отдельный шаг деплоя на сервере (TL): обновить
   `docker-compose.override.yml` server-only (mount
   `/etc/sitka-htpasswd → /etc/nginx/htpasswd`, добавить `8088:80`
   маппинг web), сгенерировать настоящий htpasswd, `docker compose
   ... up -d --force-recreate web core services`, проверить acceptance
   curl'ом снаружи (401 без auth, 200 с auth, `:8080` / `:8081`
   публично — connection refused).

## Artifacts

- branch:               не создавал — TASK strict mode + явная
                        инструкция «не коммить без go от TL» →
                        изменения остаются в working tree
                        `/Users/ilya/Projects/sitka-office/` (worktree
                        `claude/funny-agnesi-9eb4a0` для агентского
                        окружения, но git status относится к main
                        check-out).
- commit(s):            нет (working tree only, см. ниже Product repo
                        status).
- PR:                   нет, TBD после accept.
- tests:                test suite по этой задаче не запускал — write-set
                        чисто infra/docs (compose YAML, nginx conf,
                        htpasswd-пример, DEPLOY.md), Haskell core / Python
                        services / web SPA не тронуты, существующие
                        cabal/pytest/playwright тесты не релевантны.
                        Smoke-валидации запустил две: (a) `docker compose
                        ... config` exit 0 + ports-структура подтверждена,
                        (b) `make check` exit 0. Реальный smoke на работу
                        Basic Auth + loopback — после деплоя на сервер
                        (вне scope).
- Product repo status:  intentionally uncommitted (Tier C docs+infra)
                        — TASK явно: «НЕ коммить в git в продуктовом
                        repo без explicit go от TL». 4 файла в working
                        tree готовы к ревью / коммиту.

Evidence:
- AI-Dev-System ветка для HANDOFF: `claude/funny-agnesi-9eb4a0`
  (worktree, не репозиторий продукта).
- Product repo working-tree diff:
  `cd /Users/ilya/Projects/sitka-office && git diff --stat
   docker-compose.prod.yml deploy/nginx-prod.conf DEPLOY.md`
  → `3 files changed, 132 insertions(+), 1 deletion(-)`.
  + untracked `deploy/htpasswd.example` (975 байт).

## Conflicts / risks

1. **`!override` YAML tag — требует Compose ≥ 2.20.** Без него
   `docker compose config` показал что merge `ports` от dev и prod
   даёт **дубликат**: `0.0.0.0:8080` (из dev) **+** `127.0.0.1:8080`
   (из prod). То есть public binding оставался жив. Решено через
   `ports: !override - ...` — синтаксис официально поддерживается
   Compose ≥ 2.20 (мой локальный `Docker Compose v5.1.1` принимает,
   prod compose должен быть ≥ 2.20). На проде до деплоя нужно убедиться
   `docker compose version` — если < 2.20, единственная safe-альтернатива
   — отдельный production-only compose без `extends` от dev (но это
   уже расширение scope, требует решения TL). Альтернатива «удалить
   ports из dev» запрещена TASK §Do not touch.

2. **TASK Problem statement vs реальный repo: `CORE_AUTH=disabled`.**
   TASK говорит «`CORE_AUTH=disabled` на сервере, prod API без auth».
   Однако `docker-compose.prod.yml` уже содержит `CORE_AUTH: "required"`
   + `CORE_API_TOKEN` обязателен через `:?`. То есть **в репо** prod
   override уже secure — несоответствие либо в текущем server-only
   `docker-compose.override.yml` (он перезаписывает env), либо
   TASK Problem statement отражает фактическое состояние сервера, а
   не репо. Я ничего не менял в env (вне scope per Do not touch).
   В DEPLOY.md секции (d) явно написал что `CORE_AUTH=disabled`
   допустим только внутри perimeter, и что bearer-middleware ядра
   активен внутри compose-сети при `required`. **TL стоит проверить
   server-side override и явно решить — оставлять `CORE_AUTH=required`
   или возвращать к `disabled` с perimeter защитой**.

3. **`location /health` без auth — сознательное решение, не в TASK.**
   TASK говорит «auth_basic на /, /api/, /services/». Я оставил
   `/health` без auth с комментарием в conf — этот endpoint используется
   docker healthcheck (контейнер сам себя проверяет, не имеет
   креденшелов) и операторскими smoke-curl'ами. Возвращает только
   `{"status":"ok"}`, чувствительных данных нет. Если TL хочет
   полностью закрыть — добавить `auth_basic` к `/health` тоже, но
   тогда healthcheck в `docker-compose.yml` core/services имеет
   собственный path (`http://localhost:8080/health` внутри контейнера),
   nginx с auth не помешает. Web nginx healthcheck сейчас просто
   `wget -qO- http://localhost/` — упадёт 401, healthy не вернётся.
   Решение оставить без auth — наиболее наименее-рискованное по
   сравнению с поломкой healthcheck. Жду подтверждение или
   корректирующий TASK.

4. **Drive-by observation в `deploy/nginx-prod.conf`:** на строке 60
   `listen 443 ssl http2;` — deprecated синтаксис (warning в
   `nginx -t` контейнерной проверке). Не моя работа, не в scope этой
   задачи. Стоит отдельный TASK типа Tier C: заменить на
   `listen 443 ssl;` + `http2 on;` (одна строка). Не правлю молча
   per CLAUDE.md §2.

5. **Nginx config syntax check вне compose-сети не пройден полностью:**
   `nginx -t` без resolver падает на `host not found in upstream "core"`.
   Это false-positive — nginx ходит к core через docker-сеть. Tokeniser
   дошёл до строки 102 без syntax errors, мой блок auth_basic (строки
   ~80-100) принят. Полный live-тест возможен только в compose окружении
   (после деплоя).

6. **Worktree `claude/funny-agnesi-9eb4a0` — агентский worktree, не
   ветка проекта.** Изменения в working tree main check-out
   `/Users/ilya/Projects/sitka-office/` (current branch `master` per
   git status начала сессии). Когда TL будет коммитить — либо
   создать feature branch локально, либо коммит в master через PR
   workflow.

## Next step

1. **TL запускает Reviewer (sitka-reviewer cold-start):** ревью HANDOFF
   + diff working tree в `/Users/ilya/Projects/sitka-office/` (4 файла,
   3 modified + 1 new). Особое внимание — пункты 1 и 2 из Conflicts
   (`!override` совместимость + CORE_AUTH несоответствие).
2. **На ACCEPT:** TL делает PR/коммит в `sitka-office`, мерджит, потом
   отдельным шагом деплой на сервер (вне этой задачи). Если Reviewer
   просит правки — новый TASK от TL, не правлю напрямую.
3. **Submit-task:** сразу после этого HANDOFF делаю
   `make -C /Users/ilya/Projects/ai-dev-system submit-task FILE=...` —
   гейт переводит TASK Status `in-progress → review`.

---

## Iteration 2 (post-Reviewer feedback)

Reviewer вернул REQUEST CHANGES (см.
`HANDOFFS/2026-05-10-reviewer-to-tl-sitka-perimeter-close.md`). TL
классифицировал: фиксим FINDING #1 (high — web healthcheck сломается
на проде из-за auth_basic) и MISSING #1 (must-fix — Compose version
pre-deploy check в DEPLOY.md). FINDING #2/#3 и NITS — отложены TL'ом.

### (a) Что поменял

1. **`docker-compose.prod.yml`** (web service): добавлен override
   `healthcheck` с пробой `wget -qO- http://localhost/health` вместо
   дефолтного `wget -qO- http://localhost/`. `/health` уже исключён
   из `auth_basic` в `nginx-prod.conf`, поэтому wget без креденшелов
   получит 200 → web становится `healthy` → `depends_on` race не
   возникает. Перенёс **все 4 timing-поля** dev healthcheck'а
   (`interval: 15s`, `timeout: 3s`, `retries: 3`, `start_period: 10s`)
   потому что compose merge для `healthcheck` — dict-style (полная
   замена), а не list-merge: без переноса prod бы потерял timings и
   взял compose-defaults. Комментарий в файле объясняет почему
   override и почему дублируем поля.

   Реализация — Reviewer'ский вариант (a) из FINDING #1, явно
   указанный TL как approved. Варианты (b)/(c)/(d) не использованы
   (TL approved (a)).

   Скрытое уточнение к моему iter1 комментарию: nginx **проксирует**
   `/health` в `core:8080` (это `proxy_pass http://core:8080;` на
   строке 125 `nginx-prod.conf`), а не отдаёт static 200. Это не
   создаёт нового race — `web depends_on core: service_healthy`
   уже было до этого фикса, поэтому к моменту когда web start
   проверяет `/health`, core уже healthy.

2. **`DEPLOY.md`** секция «6. Защита периметра»: добавлен **первым**
   подпунктом `#### 6.0) Pre-deploy check — версия Docker Compose`
   перед `#### a) Сгенерировать htpasswd на сервере`. Шаг указывает
   `docker compose version` ≥ v2.20.0 (требование `!override`
   directive), даёт команды апгрейда `apt-get install --only-upgrade
   docker-compose-plugin` / `apt-get upgrade docker-ce ...`, и
   объясняет failure mode (silent — порты остаются открытыми,
   perimeter не закроется). Это закрывает риск из Conflict #1
   моего iter1 (был выявлен и Worker'ом, и Reviewer'ом).

### (b) Acceptance ре-verified

- **AC compose merge** — `POSTGRES_PASSWORD=dummy CORE_API_TOKEN=dummy
  docker compose -f docker-compose.yml -f docker-compose.prod.yml
  --profile app config | sed -n '/^  web:/,/^  [a-z]/p'` — exit 0,
  показывает `healthcheck.test = wget -qO- http://localhost/health
  >/dev/null 2>&1 || exit 1`, **все 4 timing-поля сохранены**
  (interval 15s, timeout 3s, retries 3, start_period 10s).
  Никаких compose-defaults не подменилось.
- **AC make check** — `make -C /Users/ilya/Projects/ai-dev-system
  check` exit 0, только ожидаемый WARN про dirty working tree
  (write-set TASK'а, per «не коммить без go от TL»).
- **AC1-AC8 первичной верификации** (loopback ports, auth_basic на
  3 location'ах, htpasswd.example dummy, DEPLOY.md секция 6,
  HANDOFF заполнен) — не регрессировали, иter2 их не трогал. См.
  Iter1 Done выше для full check'а.

### (c) Ответ на Reviewer callouts

- **FINDING #1 (high — web healthcheck) — addressed.** Использован
  Reviewer'ский предложенный вариант (a) — `wget` бьёт `/health`,
  который остался без auth. После деплоя `docker compose ps`
  должен показать web `healthy` в течение `start_period: 10s` +
  один `interval: 15s` цикл.
- **MISSING #1 (Compose version pre-check) — addressed.** Новый
  подпункт `#### 6.0)` в DEPLOY.md, **первым** в секции 6, до
  всех инструкций по htpasswd / монтированию. Failure mode описан
  явно (silent — perimeter не закроется).
- **FINDING #2 (risk-tier mismatch) — отложено TL'ом.** Не трогал.
- **FINDING #3 (DEPLOY.md (b) override fragility) — отложено TL'ом.** Не трогал.
- **NITS** — отложено TL'ом. Не трогал.

### (d) Product repo status (iter2)

`intentionally uncommitted (Tier C docs+infra)` — то же что в iter1.
Working tree теперь содержит:
- modified: `docker-compose.prod.yml` (iter1 +18, iter2 +13 = +31 line region добавлен)
- modified: `deploy/nginx-prod.conf` (без изменений в iter2, +19/-1 от iter1)
- modified: `DEPLOY.md` (iter1 +96, iter2 +24 = +120 lines в новой секции 6)
- new untracked: `deploy/htpasswd.example` (без изменений в iter2)

TL коммитит как часть accept lifecycle.

### (e) Iter2 evidence

- TASK Status bumped review → in-progress (perl/sed-style Edit на
  строке `- Status: review`) до начала фикса. После submit-task в
  конце iter2 — снова → `review`.
- Reviewer HANDOFF Iter1 — прочитан полностью, FINDING #1 и
  MISSING #1 классифицированы TL'ом как must-fix, остальные —
  defer.

