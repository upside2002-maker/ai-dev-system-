# HANDOFF: reviewer → tl — t3c-reentry-locks

- Status: closed
- Date: 2026-06-13 15:20
- Project: crypto
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus (5 независимых линз-сессий + верификация, рабочий контур)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/crypto/TASKS/2026-06-13-t3c-reentry-locks.md

## Summary

Независимое адверсариальное ревью блокировок перезахода (tier A): 5 линз +
верификация руками. **Вердикт: ACCEPT.** 0 подтверждённых находок
(0 крит / 0 средних / 0 мелких). 1 находка отклонена верификатором
(отрицательная цена) — не реальна. Все 5 линз собрали `make check` зелёным;
Admin перепроверил вручную.

## Done

Проверено руками, дыр не найдено:
- Инвариант 4 (главный): canReenter запрещает перезаход дороже цены продажи
  при активной блокировке; ≤ цены, сброшенные и чужие блокировки не
  ограничивают. Проверено на множестве блокировок и границе ±1e-8.
- Дизъюнкция сброса: каждое из 4 условий по отдельности сбрасывает; «ни
  одно» → active; границы drawdown/timeout нестрогие; идемпотентно.
- Критичность: critical_ok=false → capitulation и valuation-сброс не
  срабатывают; drawdown и timeout срабатывают.
- Множество блокировок / разделение активов: «достаточно одной активной
  дешёвой»; чужой актив не влияет.
- timeout календарный (год×12+месяц), без float и «30 дней»; переход через
  год и границы покрыты.
- Float нет (grep); Fixed8/classifySignal переиспользованы; периметр чист
  (Reentry.hs, ReentrySpec.hs, cabal); CLI прежний (Observe).

## Remaining

- Наблюдение (НЕ блокер): drawdown-сброс предполагает цену > 0. Схема журнала
  отрицательную цену не допускает (в шаблоне sale_price нет минуса), так что
  невыразима в валидном входе. Документирование предусловия «price > 0» в
  Reentry.hs вынесено попутным пунктом в Т-3d.

## Artifacts

- branch:               master
- commit(s):            807be09, 74826c2 (Reentry.hs + ReentrySpec + cabal)
- PR:                   нет (локальная разработка, CI заморожен)
- tests:                reentry 50 + signal 44 + profit 36 + core 27 Haskell + Python + кросс-хэш(8) + злой корпус(24/17) — зелёные
- Product repo status:  committed (репозиторий crypto-platform, дерево чистое)

## Conflicts / risks

Нарушений инвариантов нет. buildOk у всех 5 линз. v1-упрощение drawdown
(от цены продажи, не от пика) — осознанное, зафиксировано в KNOWN (Я-1).

## Next step

Admin принимает Т-3c и ставит Т-3d — последний кусок ядра: сборка
decideModule + riskGate (actions[], профили, min_net_profit-gate,
ManualReview >5%), подключение к выходу CLI в рамках data_rights;
попутно документировать предусловие price>0 в Reentry.hs.
