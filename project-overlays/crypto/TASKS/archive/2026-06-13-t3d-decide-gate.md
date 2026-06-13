# TASK: t3d-decide-gate

- Status: done
- Ready: yes
- Date: 2026-06-13
- Project: crypto
- Layer: core
- Risk tier: A
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus)
- Mode: strict
- Critical approved by: (нет)
- Reviewer: многолинзовое (5 линз+верификация) — ACCEPT, 0 крит/1 средн(документация)/1 отклонена; Reviewer-HANDOFF closed

## Problem

Последний кусок ядра CPDS (4/4): сборка решения. Заменить заглушку модуля
настоящим `decideModule`, связав принятые Signal (классификация), Profit
(деньги), Reentry (блокировки), и усилить риск-ворота. Модуль предлагает
действия по сигналу; ворота фильтруют по правам данных, порогу прибыли,
лимитам профиля и блокировкам. Впервые денежные атомы могут появиться в
выходе — но строго в рамках ворот. Архитектура §9.1 (поток, actions[]),
§9.3 (порог прибыли), §9.4 (профили, ManualReview), §9.5 (все инварианты).
Попутно: документировать предусловие «цена > 0» в Reentry.hs (наблюдение
ревью Т-3c).

## Логика (зафиксировать точно)

**decideModule (предлагает, по SignalState):**
- `OverheatStrong`/`OverheatMild` → транш фиксации = `strong_overheat_pct` /
  `normal_pct` профиля; `computeNetProfit` на лотах+цене снимка+комиссиях;
  если `estimated_net_profit ≥ min_net_profit` → атомы по порядку
  `TakeProfit → DistributeProfit (allocateProfit по distribution_map) →
  CreateSaleLock`; если `< min_net_profit` → `Observe` (фиксировать
  невыгодно, причина в reason).
- `Capitulation` → `BuyDipFromBuffer` долей `buyback_per_event_pct`, ТОЛЬКО
  если `canReenter` разрешает по цене снимка (не дороже активной блокировки);
  иначе `Observe` (перезаход заблокирован).
- `Neutral`/`Unconfirmed` → `Observe`.

**riskGate (фильтрует предложение модуля):**
- `critical_ok=false` или невалидный вход → `observe_only`, денежные атомы
  невыразимы, предупреждение «нет права на денежные решения» (РЕГРЕСС Т-0,
  не сломать).
- Действие с долей > `max_unconfirmed_action_pct` профиля →
  `human_review_required=true` и атом `ManualReview` (НЕ молча исполнить).
  Доля транша > 5% (0.05000000) → ManualReview ВСЕГДА, любой профиль
  (красная линия §9.4). **v1-приближение:** доля меряется как доля позиции
  актива (`position_pct`), не как доля денежного капитала портфеля (полного
  портфеля стоимости ядро пока не имеет) — зафиксировать в HANDOFF и KNOWN.
- Σ распределения = net (через Profit — интеграционно перепроверить).
- Хэши входа/конфига, core_version — как в каркасе.

## Files

Репозиторий /Users/ilya/Projects/crypto-platform (master):

- new: core/src/Cpds.hs — настоящий `decideModule :: <вход> -> [Action]`
  (использует Signal/Profit/Reentry). Заменяет заглушку.
- delete: core/src/CpdsStub.hs — заглушка Т-0 (её роль переходит к Cpds.hs).
- modify: core/src/Gate.hs — усилить ворота (порог прибыли, ManualReview,
  лимиты профиля, проброс блокировок); импорт Cpds вместо CpdsStub.
  Сохранить регресс: critical_ok=false → observe_only.
- modify: core/src/Types.hs — если нужны поля в Action (напр. position_pct,
  distribution_plan, estimated_net_profit) согласно schemas/decision_output —
  минимально и строго по схеме.
- modify: core/src/Render.hs — сериализация новых полей Action в выход
  строго по schemas/decision_output.schema.json (actions[] с денежными
  полями, data_rights). НЕ менять схему.
- modify: core/src/Reentry.hs — ТОЛЬКО haddock-комментарий предусловия
  «цена > 0» (наблюдение ревью Т-3c); логику не трогать.
- new: core/test/DecideSpec.hs — интеграционные + property тесты.
- modify: core/cpds-core.cabal — модули/тесты.
- modify: project-overlays/crypto/KNOWN_LIMITATIONS.md — строка про
  v1-приближение «доля позиции вместо доли капитала» (разрешённый файл).
- modify: (в ai-dev-system — этот TASK + свой HANDOFF)

## Do not touch

- Signal.hs, Profit.hs — логику не менять (только импорт/использование).
- Canonical.hs, Json.hs, Sha256.hs — канонизация/хэши приняты.
- schemas/ — контракт, менять ЗАПРЕЩЕНО. Выход обязан валидироваться по
  существующей decision_output.schema.json.
- platform/ — не трогать.
- Никаких Double/Float (grep). Никакой сети/ключей. Журналы не писать
  (ядро только читает; CreateSaleLock — это ПРЕДЛОЖЕНИЕ атома, не запись).

## Acceptance

- [x] `make check` зелёный с чистого клона; DecideSpec добавлен; прежние
  сьюты (signal/profit/reentry/core) целы; кросс-хэш и злой корпус целы.
- [x] РЕГРЕСС (главный, §9.5 инв.3): `critical_ok=false` → выход
  `observe_only`, только Observe, денежных атомов НЕТ, предупреждение на
  месте (тест на снимке без valuation — как сейчас в каркасе).
- [x] Перегрев при `critical_ok=true` и `net ≥ min_net_profit` → actions
  `[TakeProfit, DistributeProfit, CreateSaleLock]` в этом порядке; Σ
  distribution_plan = estimated_net_profit (интеграционный тест).
- [x] Перегрев, но `net < min_net_profit` → Observe (фиксировать невыгодно),
  денежных атомов нет (тест).
- [x] Капитуляция + canReenter разрешает → `BuyDipFromBuffer`; капитуляция +
  активная блокировка дороже → Observe (перезаход заблокирован) (тест).
- [x] Доля действия > `max_unconfirmed_action_pct` → `human_review_required`
  + ManualReview; транш > 5% → ManualReview в любом профиле (тест на трёх
  профилях).
- [x] Выход cpds-core валиден по decision_output.schema.json на наборе
  входов (перегрев/капитуляция/нейтрально/плохие данные); `echo '{}'` и
  `critical_ok=false` по-прежнему observe_only (CLI-приёмка цела).
- [x] В новом коде нет Double/Float (grep); детерминизм; предусловие price>0
  задокументировано в Reentry.hs.

## Context

- Архитектура: `ai-dev-system/docs/CRYPTOBOT_ARCHITECTURE_2026-06-12.md`
  §9.1 (decideModule/riskGate, actions[]), §9.3 (порог прибыли, estimated),
  §9.4 (профили, ManualReview >5%), §9.5 (6 инвариантов — все обязаны
  держаться в собранном ядре).
- Схемы-истина: `crypto-platform/schemas/decision_output.schema.json`
  (actions[], атомы, data_rights, estimated_net_profit у денежных),
  `profile_config.schema.json` (tranche, min_net_profit, distribution_map,
  buckets, max_unconfirmed_action_pct), все журналы.
- Принятые Т-3a/b/c: `archive/` + Signal.hs/Profit.hs/Reentry.hs
  (использовать как есть, не дублировать; Fixed8 переиспользовать).
- Текущие Gate.hs/CpdsStub.hs (каркас Т-0) — заменяемая основа; РЕГРЕСС
  observe_only обязан сохраниться.
- Это ЗАВЕРШЕНИЕ ядра решений. После приёмки CPDS-модуль собран целиком;
  дальше — бумажный полигон (Т-4) и бэктест (Т-5).
- Mode strict: денежное сердце, впервые денежные атомы в выходе (MODES: A→strict).
