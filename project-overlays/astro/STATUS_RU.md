# Статус — Astro

Дата последнего обновления: 2026-05-13.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **2026-05-13 раздел «Транзиты» переоткрыт как программа работ** — после визуальной построчной сверки пользователем с эталоном Марины обнаружены 5 системных недоделок presentation, которые не были выловлены при предыдущем accept'е Tier C от 2026-05-12.

**Tier A engine cascade (2026-05-11/12) принят и удержан.** Math engine стабилен:
- Quincunx revoke (scope = transit calendar only) — работает.
- Per-loop-pass orb-window scanner (orb_enter_jd / orb_exit_jd) — работает.
- Cross-year sample window (540d до/после соляра) — работает.
- Per-planet orb calibration (J/S/U/N = 1.0°, P = 1.25°) — эмпирически выведена по Натальину PDF.
- Schema cascade выполнен одним atomic коммитом (bright-line #8) — `5f4fbc9`.
- Tests: `cabal test` 242/242, `pytest` 85/85 — зелёный.

**Tier C presentation rebuild (2026-05-12) — преждевременный accept.** Проверка ограничилась календарём, monthly table и заголовками. Полная постраничная сверка раздела с эталоном не выполнялась. После сверки пользователем 2026-05-13:
- В трактовках по домам появился `Сатурн в 6 доме` (из расширенного horizon-а engine'а, 2024 год).
- Отсутствуют outer-planet карточки эталона (Уран-Венера, Нептун-Юпитер, Нептун-Нептун) с таблицами «Золотое правило транзита».
- «Дома цели» считаются placement-only без rulerships (теряются темы 2/3/7 у разных аспектов).
- Не разделены горизонты данных: один `annual_transit_table` используется и для солярного года (трактовки) и для full-loop scan (карточки).
- Конфликт артефактов: PDF собирался из worktree, основной repo содержит другой шаблон, render не несёт provenance.

**Программа recovery зафиксирована** в `ARCHITECTURE/transit-section-program-2026-05-13.md` — 8 секций (статус/gate, дефекты, root causes, архитектурное решение, фазы 0-7, hard acceptance assertions, запреты, порядок TASK'ов). Это новый SoT для всех presentation-работ по транзитам до закрытия программы.

Артефакты:
- Программа: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- Последний (нерабочий по презентации) PDF: `/tmp/astro-natalya-monthstart-iter1.pdf` — debug/QA only, не показывать.
- Продуктовый repo: ветка `claude/dreamy-moore-46f5eb`, последний commit `6894743`. Главная ветка `main` не тронута.
- Тесты зелёные, но не являются acceptance contract против Марины — это будет покрыто в Phase 2.

## Ждёт твоего решения

- **TASK 1 («Single source of truth + render provenance») — стартовать сейчас?** Это Phase 1 программы. Tier C, Layer infra + services. Worker subagent делает: canonical render path, provenance в metadata/sidecar/log, решение по worktree merge/discard (mechanics — Worker, decision — пользователь).
- **Merge ветки `claude/dreamy-moore-46f5eb` в main** — отложено до закрытия Phase 1 (где это решение и фиксируется). Без TL'ого инициативного действия.
- **Когда показывать Марине** — после закрытия всей программы (Phase 0-7 включительно) и финального ack пользователя. До этого PDF — внутренний debug/QA артефакт.

## Срочные риски

**Программа Transit Section Recovery открыта.** Все работы по транзитному presentation проходят через `ARCHITECTURE/transit-section-program-2026-05-13.md`. До закрытия программы:

- запрещено перезаписывать `expected.json` golden fixtures результатом текущего engine без diff review и hard acceptance tests;
- запрещено считать зелёные snapshot tests доказательством близости к Марине;
- запрещено использовать full-loop horizon для текстов про текущий соляр;
- запрещено держать main и worktree как равноправные источники PDF;
- запрещены Worker subagents на Phase 3-7 пока Phase 1 + Phase 2 не закрыты;
- запрещён показ PDF Марине до закрытия программы.

Дрейф между prescribed architecture (phases 0.1/0.2) и фактическим кодом (0.5+) — без изменений с 2026-05-06. Не пожар.

## На очереди

Программа Transit Section Recovery, фазы 0-7:

- **Phase 0** (freeze + audit trail) — закрыт настоящим обновлением STATUS_RU + фиксацией architecture document.
- **Phase 1** (single source of truth + render provenance) — следующий TASK.
- **Phase 2** (hard acceptance assertions) — после Phase 1.
- **Phase 3** (transit horizon split) — Tier C с эскалацией до Tier A при изменении schema/core.
- **Phase 4** (outer-planet cards generator) — только для тех outer-aspects, что представлены в эталоне как карточки.
- **Phase 5** (rulership-expanded target houses) — Tier C с эскалацией до Tier A при shared core helper.
- **Phase 6** (per-context cutoff policy) — explicit clipping rules.
- **Phase 7** (multi-case calibration) — default cases 05/07/10, либо обоснованный выбор 3 из 8.

Backlog вне программы (на паузе до её закрытия):
- `solar-nodes-lilith-retro-display` — Tier A, без явного запроса Марины не запускать.
- `consultation-summary-matrix-rewrite` — пауза.
- `section-order-recon` — пауза.

## Не делаем сейчас

- **«Solar nodes / Lilith / retro display» без её явного запроса.** Tier A.
- **Публичный хостинг репозитория** (GitHub / GitLab / Gitea). Без отдельного «ок» не добавляем.
- **SaaS-направление и B2C-сайт.** Сняты, проект — внутренний инструмент.
- **Полная сверка архитектурного документа с фактическим кодом.** Откладывается.
- **Презентационные правки раздела Транзиты вне программы Transit Section Recovery.** Все правки идут через её phases в указанном порядке.
- **Дальнейшая калибровка орбисов транзитного движка на одном Натальином case.** Per-planet значения выведены эмпирически; расширение калибровки требует ≥3-5 cases (Phase 7 программы).
