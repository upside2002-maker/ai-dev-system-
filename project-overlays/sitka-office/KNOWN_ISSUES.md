# Sitka Office — Known Issues

Дата: 2026-05-19
Snapshot commit: `7b069a7`

Постоянные риски и неснятые долги, актуальные после переезда на
production (`94.72.112.106:8088`, 2026-05-02), perimeter close
(2026-05-11) и инцидентов с deploy/security 2026-05-13/14.

Текущие mini-tasks и drive-by — в `OPERATING/backlog.md`. Полные
TASK с lifecycle — в `TASKS/`.

## 1. HTTPS + домен ещё не настроены

Прод сейчас живёт на голом IP+нестандартный порт (`94.72.112.106:8088`).
Из этого следует:

- Авторизация по периметру — только Basic Auth, без TLS (трафик
  открыт в публичной сети). Internal use без чувствительных
  данных в URL это терпит, но лимит низкий.
- Любой запрет ингреса от соседнего tenant'а на shared VPS может
  снова закрыть наш порт (так уже было 2026-05-13/14, см. журнал).
  Защита через bind на `127.0.0.1` в override уже включена
  (postgres) и в шаблоне репо для нового deploy (PR #88).
- Frontend bearer auth flow не реализован — оператор работает на
  internal-only поверхности, дальше расширять без auth-flow нельзя.

Ближайший шаг — settle на стратегии (внешний домен через FounderOS
nginx 80/443, либо отдельный subdomain с Let's Encrypt). В backlog,
не блокер пока сайт нужен только Илье и Виталию.

## 2. Production-safety backlog по-прежнему отложен

В `.claude/architecture-invariants.md` описан отдельный слой защит,
из которого закрыто частично:

- `daily backup pg_dump` — **запущен 2026-05-19** (контейнер
  `sitka-office-backup-1`, retention 7 дней, первый дамп лёг).
- swap-файл 2 ГБ — **добавлен 2026-05-19** (раньше swap отсутствовал,
  при OOM сервер ложил всё).
- restore drill — **не сделан**. Бэкап есть, но восстановление
  на чистую базу не отрабатывали — гипотеза «бэкап рабочий»,
  не проверено.
- audit trail вне `deal_event` — не реализован.
- дополнительные DB / contract guards — частично (golden tests на
  wire formats есть для PR #76, не для всех endpoints).
- единый secrets/config audit — **первый прогон 2026-05-19** (этот).

## 3. Legacy compile-surface ещё не вычищена до конца

Runtime legacy Client-first path мёртв, но в типах и helper-ах:

- старые `DealStatus` constructors
- старые `Transition` constructors
- куски mapping/комментарии под старую воронку

Цена — лишний когнитивный шум и риск принять мёртвую поверхность
за живую. Не блокер, чистить когда руки дойдут (Tier C cleanup-PR).

## 4. Message flow есть, но операторский UX не финален

`Api.Messages`, Avito poller/sender, `message-inbox/` во фронте —
всё работает. Не хватает:

- сценариев retry / failed / pending
- удобного встраивания сообщений в повседневный workflow
- ясных правил, где оператор работает с Lead Inbox, а где с
  Message Inbox

## 5. Avito-интеграция зависит от реальных credentials и сторонних API

- наличие кода не означает что фича включена (всё credentials-gated,
  no-op без `SITKA_AVITO_CLIENT_ID` / `SITKA_AVITO_CHANNEL_ACCOUNT_ID`).
- Avito API регулярно даёт 500/503 (внешняя проблема, наши retry'и
  работают). Зафиксировано в логах 2026-05-19, не нашё.
- Cold-start cursor race в `avito_poller.py:192-200` — Codex audit
  2026-05-06 принят, в backlog (Tier A backend, ~10-15 LOC).

## 6. Shared VPS — соседний tenant может вмешиваться

2026-05-13/14: соседний tenant FounderOS в рамках своего security
audit добавил DROP-правило в `DOCKER-USER` на портах 5432 и 8088.
8088 (наш sitka-web) закрылся снаружи, прод полежал до моего
вмешательства. Я снял правило для 8088, оставил для 5432, и
параллельно перенастроил postgres на bind `127.0.0.1` — теперь
правило соседа избыточно (защита на уровне docker).

Класс риска остаётся: на shared VPS любой tenant с root может
менять iptables хоста. Mitigation — bind всех внутренних портов
на loopback (что уже сделано) + долгосрочно переезд на HTTPS+домен
через единый nginx FounderOS как «один общий вход».

## 7. Overlay нужно поддерживать как живую документацию

Был основной сбой когда overlay sitka застрял на Phase 0 пока
продукт ушёл в DM-6.x. После refresh 2026-05-02 разрыв закрыт,
но дисциплина обновления — отдельный риск.

После каждого milestone (или раз в неделю) — пройтись по
`CURRENT_STATE.md`, `KNOWN_ISSUES.md`, `NEXT_ACTIONS.md`,
`PROJECT_MAP.md` и убрать stale.

## Закрытые старые долги

- Phase 0 baseline (нет CI / нет auth / только foundation) — закрыт
  в DM-6.x.
- Perimeter close (раньше core/services торчали на 0.0.0.0) — закрыт
  PR #81 + deploy 2026-05-11.
- Daily backup — закрыт 2026-05-19 (точка 2 выше).
- Postgres exposed на 0.0.0.0 — закрыт 2026-05-19 (точка 6 выше).
- No swap — закрыт 2026-05-19.
- Auto-deploy через GitHub Actions — закрыт PR #87 (2026-05-14).
- Корневая причина deploy-каскада (wget в core image) — закрыта
  PR #86 + Correction 017.
