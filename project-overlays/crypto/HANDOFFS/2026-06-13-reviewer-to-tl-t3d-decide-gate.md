# HANDOFF: reviewer → tl — t3d-decide-gate

- Status: closed
- Date: 2026-06-13 16:30
- Project: crypto
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus (5 независимых линз-сессий + верификация, рабочий контур)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/crypto/TASKS/2026-06-13-t3d-decide-gate.md

## Summary

Независимое адверсариальное ревью сборки ядра (tier A, впервые денежные
атомы): 5 линз по денежным углам + верификация руками с пересчётом до 1e-8.
**Вердикт: ACCEPT.** 0 критических, 1 средняя (неточность ОПИСАНИЯ в
HANDOFF, не дефект кода), 1 отклонена. Все 5 линз собрали `make check`
зелёным; Admin перепроверил вручную.

## Done

Проверено руками, дыр в коде не найдено:
- РЕГРЕСС (главный, §9.5 инв.3): critical_ok=false при всех раскалённых
  семьях → observe_only, [Observe], денег НЕТ, предупреждение. Цел.
- Перегрев + net≥min → [TakeProfit, DistributeProfit, CreateSaleLock] в
  порядке; net<min → Observe без денег.
- Капитуляция + canReenter → BuyDipFromBuffer; блокировка дороже → Observe.
- Красная линия: транш >0.05 → ManualReview на всех трёх профилях; обойти
  через max_unconfirmed_action_pct профиля нельзя (5% — жёсткий потолок).
- Выход валиден по decision_output.schema.json; float нет; периметр чист
  (Signal/Profit логика не тронута, schemas/Canonical/Json/Sha256 целы).
- 3 диверсии Worker'а перепроверены — тесты ловят.

## Remaining

- MEDIUM (документация, НЕ код): HANDOFF Worker'а п.3 неточно описал
  использование allocateProfit. **Точный контракт (для Т-4):** ядро кладёт
  в выход ДОЛИ карты распределения (dmK1/dmK2/dmK3), а НЕ суммы;
  allocateProfit вызывается лишь для проверки, что доли сходятся (Σ=1.0 /
  Σ=net на целых). Фактические суммы по корзинам = доля×net вычисляет
  ВНЕШНЯЯ обвязка (бумажный полигон Т-4). Это логически верно и достаточно;
  правка — в описание, код корректен. Зафиксировано здесь как источник
  истины для Т-4.
- MINOR (отклонено): комментарий в Types.hs о денежности CreateSaleLock —
  читаемость, не логика.

## Artifacts

- branch:               master
- commit(s):            117c1e9, adbb6dc, e2eda6a, c6f1750, 6836f9b
- PR:                   нет (локальная разработка, CI заморожен)
- tests:                core 27 + profit 36 + signal 44 + reentry 50 + decide 43 (200 кейсов) + Python + кросс-хэш(8) + злой корпус(24/17) — зелёные
- Product repo status:  committed (репозиторий crypto-platform, дерево чистое)

## Conflicts / risks

Нарушений инвариантов §9.5 нет. buildOk у всех 5 линз. v1-приближения
(Я-1 drawdown от цены продажи, Я-2 доля позиции, Я-3 комиссии=0) —
осознанные, в KNOWN_LIMITATIONS.

## Next step

Admin принимает Т-3d → ядро решений СОБРАНО ЦЕЛИКОМ (сигнал+деньги+
блокировки+сборка). Дальше — Т-4 бумажный полигон (умножает доли карты на
net по контракту выше) и Т-5 бэктест.
