# Dispatcher — живой dashboard трёх постоянных чатов

Это страница которую читают **все три постоянные роли** (Admin, TL
Sitka, TL Astro) при каждом обновлении контекста. Обновляется любой
ролью когда меняется её статус.

Соседние артефакты:
- [`policies/SESSIONS.md`](policies/SESSIONS.md) — модель работы.
- [`MAILBOX/`](MAILBOX/) — почтовые ящики между ролями.

---

## Активные роли

| Роль | Чат | Сейчас занят |
|------|-----|--------------|
| Admin | главный (Owner здесь) | диспетчеризация (поставил задачи TL Sitka + промпт на BA Astro 2026-05-21) |
| TL Sitka | вкладка sitka-office | TASK A2 Worker в работе. **AVITO architecture audit сдан** (ЖЁЛТЫЙ светофор, 0 P0, recommendation = «оставить vendored» с двумя условиями UPSTREAM.md + CI hookup). Записка в `MAILBOX/to-admin.md` 2026-05-28 вечер — Owner решает Option 1/2/3. |
| TL Astro | вкладка astro | **этап 1 контент-движка СДАН 2026-05-24** — 6 deliverables в `research/` (stylebook, контент-план 24 поста, архитектура воронки, мокапы 5 страниц, tech-rec, пилотный пост). Ждёт (1) ревью Марины на 30 минут — узнаёт ли себя в пилотном посту, попадает ли план, (2) правки BA Astro §9 tech-rec под Yandex Cloud (вместо CF Pages). После — финализация v1.0 и запуск этапа 2. |

«Сейчас занят» обновляется ролью на старте задачи и снова на её
закрытии. Если пусто — роль свободна, можно слать новую задачу.

## План Owner'а на сегодня (2026-05-24)

- VPN Reality на сервере для 2 непубличных пользователей (не мы) —
  ТЗ написано: `infrastructure/vpn-server-spec-2026-05-24.md`.
  Передать VPN-агенту, тот разворачивает в `/opt/vpn/` изолированно,
  не трогая Sitka и FounderOS.
- На Owner'е по-прежнему висят два открытых решения:
  форк парсера Sitka + ответы Марины на 6 вопросов по контент-движку.

## План Owner'а — предыдущая (2026-05-21)

- Запустить аналитику блога Марины на дзене (отдельная BA-сессия по
  промпту Admin'а от 2026-05-21). Цель — понять что работает, что
  нет, и собрать конкретный план продвижения.
- Поставить TL Sitka задачу на архитектурный аудит парсера
  inventory_parser (vendored код, нужно понимание перед следующими
  изменениями).
- Параллельно — TL Sitka берёт мелкую задачу про двусловные запросы
  в парсере (из backlog).

## Открытые блоки

- **Astro:** ждёт **ревью Марины на 30 минут** — узнаёт ли себя в пилотном посту «Транзит Сатурна по 4 дому», попадает ли контент-план. Параллельно BA Astro правит §9 tech-rec под Yandex Cloud (было CF Pages).
- **Sitka:** **решение по форку принято 2026-05-25** — TL Sitka декомпозирует на 4 TASK'а и запускает по обычному lifecycle.
- **Будущее (этап 2 Astro):** Owner должен будет создать аккаунт Yandex Cloud + привязать карту + решить домен. Не сейчас.

Сюда попадает всё что ждёт от кого-то за пределами одной роли:
- «TL Sitka ждёт от Owner'а решение по HTTPS+домен»
- «TL Astro ждёт от Марины PDF на повторное сравнение»
- «Admin ждёт от FounderOS Клода ответ по shared VPS»

## Свежие cross-role события

Последние ~5 событий которые касаются больше чем одной роли. Старые
переезжают в `OPERATING/journal/` соответствующего overlay.

- 2026-05-28 (вечер): TL Sitka — AVITO architecture audit сдан subagent'ом (`research/avito-parser-architecture-audit-2026-05-28.md`, 464 строки). ЖЁЛТЫЙ светофор, 0 P0, 4 P1 + 5 P2 + 2 NTH. Recommendation: **оставить vendored** с двумя условиями (UPSTREAM.md + CI tests hookup, ~30 минут работы). Диаметрально от inventory (там был fork & own) — потому что avito vendor 10× меньше, 0 vendor edits 34 дня, узкий контракт integration. Параллельно — TASK A2 Worker в работе (закрывает cross-vendor coupling). Owner решает Option 1/2/3.
- 2026-05-28 (день): **Серия inventory_parser fork (A→B→C→D) ФИНАЛИЗИРОВАНА.** TASK D — PR #94 (CODEOWNERS gate на app/inventory/ shared core + PROJECT_MAP refresh). Итоги серии: -31 482 LOC в репо, +1 working store (Amazon), обе P0 из аудита закрыты, recurring CORE_AUTH drift root-caused, pre-existing flake запинен. Финальный summary с цифрами в `MAILBOX/to-admin.md`.
- 2026-05-28 (день): TL Sitka закрыл TASK C (P0-2 Amazon timeout). PR #93 → master `4aa26ec`. Главный win — **Amazon работает первый раз с момента vendoring**: prod smoke «sitka jetstream» → status=ok, 4 items, 63s elapsed (раньше всегда failed:store_timeout). Дальше TASK D.
- 2026-05-28 (ночь): TL Sitka закрыл TASK B (P0-1 substring drop) — PR #91 → master `89a6c25`. Параллельно root-caused recurring CORE_AUTH drift: `deploy/auto-deploy.sh:33` подмешивал `prod.yml` с hardcoded `CORE_AUTH=required`, побеждал `.env=disabled`. Server-only fix через override.yml; PR #92 зеркалит example. Прод-смок 3-словного запроса находит «Blizzard AeroLite Parka». Доклад в `MAILBOX/to-admin.md`. Дальше TASK C (Amazon timeout).
- 2026-05-27 (вечер): TL Sitka закрыл TASK A inventory fork. PR #90 → master `8f1d5c4`, auto-deploy scope=services, prod smoke 21 hit на blizzard. -31 482 LOC в репо, vendor каталог удалён. Один retry CI (inline pin pytest-asyncio<0.27, drive-by на pre-existing flake test_core_client.py — long-fix в backlog). Дальше TASK B (P0-1 substring drop). Доклад в `MAILBOX/to-admin.md`.
- 2026-05-22 (ночь): TL Sitka закрыл обе задачи из ящика. (б) PR #89 → master `ccac24b`, задеплоен, smoke зелёный (Blizzard parka теперь находит товары). (в) Архитектурный аудит в `research/inventory-parser-architecture-audit-2026-05-21.md`, светофор ЖЁЛТЫЙ, рекомендация — fork parser. Доклад в `MAILBOX/to-admin.md`. Решение по форку — за Owner'ом.
- 2026-05-25 (поздний вечер): **Owner принял рекомендацию форка парсера Sitka**. TL Sitka получил декомпозицию на 4 TASK'а (spike + форк + 2× P0-fix + overlay refresh, ориентир — рабочая неделя). Также BA Astro закрыл этап 1 контент-движка 2026-05-24 — 6 deliverables в `research/`, ждёт ревью Марины и правки §9 tech-rec под Yandex Cloud.
- 2026-05-25 (вечер): стек этапа 2 для контент-воронки Марины — **Yandex Cloud Object Storage + CDN + DNS** (вместо Cloudflare Pages). Admin сделал факт-чек: с июня 2025 года Cloudflare фактически блокирован для русской аудитории через 16-КБ throttling. Yandex Cloud free tier бесплатный, российская инфраструктура без замедлений, SSL автоматический. ТЗ обновлено.
- 2026-05-25 (день): Марина ответила на 6 блокирующих вопросов по контент-движку и сайту-воронке. Этап 1 (BA Astro) разблокирован. Продукт в воронке — индивидуальные консультации (соляр 5к, проф-ориентация 10к), не курсы. Tilda-сайты выкидываются.
- 2026-05-25 (раннее утро): VPN Xray VLESS+Reality развёрнут на сервере (TCP 39847, изолировано от Sitka и FounderOS). Smoke со стороны сервера 5/5 OK, E2E через клиента ждёт пока Owner передаст ключи двум пользователям. Ключи скачаны в `/tmp/vpn-keys-2026-05-25/` на ноут Owner'а, в чат и git не выводились. Запись в журнал Sitka добавлена.
- 2026-05-24: важная поправка контекста — FounderOS не «соседский tenant», это **Виталий, наш совладелец сервера**. Старые записи журнала про «соседний tenant без координации» из 2026-05-17 — устаревшая модель, требуется patch overlay-документов (отдельной задачей). Это разблокировало размещение VPN-агента и других инфраструктурных сервисов на сервере без обхода чужого nginx.
- 2026-05-24: Admin написал ТЗ на Reality VPN (Xray в Docker, нестандартный порт, для 2 непубличных пользователей) — `infrastructure/vpn-server-spec-2026-05-24.md`. Ждёт передачи VPN-агенту.
- 2026-05-22: BA Astro обновил отчёт после поправки Owner'а про ссылку в подвале постов Марины — v3 выдержки готова, поручение на полное обновление отчёта в `MAILBOX/to-tl-astro.md`. Admin написал большое ТЗ на контент-движок + сайт-воронку для Марины (`research/marina-content-funnel-spec-2026-05-22.md`), ждёт ответов Марины на 6 блокирующих вопросов перед стартом.
- 2026-05-21: TL Sitka подтвердил end-to-end протокол MAILBOX (тестовая записка от 2026-05-20 закрыта). Обе майские записки переехали в `MAILBOX/archive/2026-05.md`. Взяты в параллельную работу: (б) парсер двусловных и (в) архитектурный аудит.
- 2026-05-21: Admin поставил TL Sitka задачу на архитектурный аудит
  парсера `sitka-services/vendor/inventory_parser/` (vendored код,
  PR #67). Запись в `MAILBOX/to-tl-sitka.md`.
- 2026-05-21: подготовлен промпт для отдельной BA-сессии Astro —
  анализ блога Марины на dzen.ru + план продвижения. Передан
  Owner'у для запуска нового чата с BA.
- 2026-05-20 (ночь Bishkek): Admin закрыл общий аудит + блок
  production-safety фиксов на Sitka (backup-сервис запущен впервые,
  postgres bind на 127.0.0.1, swap 2 ГБ, PR #88). Astro: stale
  STOP-handoff перенесён в archive. Snapshot sitka overlay → `dbe8c15`.
- 2026-05-20: принята политика `policies/SESSIONS.md` (модель «три
  постоянных чата»). Admin расширен функцией координатора TL'ов.

---

_Обновляется в свободной форме. Не пытаться формализовать — это
human-readable доска, не машинный реестр._
