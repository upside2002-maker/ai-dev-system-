# HANDOFF: reviewer → tl — returns-belated-independent-review

- Status: closed
- Date: 2026-06-06
- From: Reviewer (независимая сессия, не участвовал в реализации)
- To: Tech Lead (astro)
- Role mode: Reviewer
- TASK: `project-overlays/astro/TASKS/2026-06-06-returns-belated-independent-review.md`
- Product repo status: not applicable (read-only ревью, кода не менял)

## Вердикт

**APPROVE-WITH-FINDINGS.** Money/math движка возвратов независимо подтверждён корректным для основного (live-reference) сценария. **Процессный долг X-1 (critical) погашен.** Один реальный low-баг (RET-1) — заведён отдельной fix-задачей, не блокер.

## Воспроизведено самостоятельно (не доверяя прежним вердиктам)

- `cabal test` → **279 examples, 0 failures**; golden solar проходит → вынос `TransitMath` бит-в-бит.
- `pytest` → **728 passed, 3 skipped, 0 failed**.

## Что проверено (B/C приоритет)

- **Ядро (B):** детекция пересечений (retro оба направления, 0/360 wrap корректно отбит `abs d<90`), орб-окна (enter/exact/exit на 1°), нумерация/фазы, `beyond_lifespan` (только Нептун/Плутон), граница «строго после reference». Bug-hunt — см. RET-1.
- **Вынос без регрессии:** хелперы только в `TransitMath`, `TransitCalendar` импортирует; `numberContactsFor`↦`numberPasses` доказуемо идентичен; golden solar бит-в-бит; нет wildcard над `Planet`; `data Planet` не расширен; `findSolarReturnJd` не переиспользован.
- **Контракт (C):** schema↔Bridge↔TS — 9 полей совпадают; JD-числа (не ISO); `motion` enum verbatim; DTO reused (Correction 001); solar схема/golden не тронуты (пустой diff); Python-фикстура == Haskell golden (байт-в-байт).
- **AST-WIRE-1 СНЯТ:** трассировка `Domain.Returns.findNearestReturns` → `Bridge.Returns.runReturns` → `Main.hs` dispatch → один `run_core_analysis` subprocess в `api/returns.py` и `pdf/returns_section.py`. Один вызов (#6), нет math в Python (#7), не кэшируется. PDF — факт-таблица, без Дараган-verbatim, solar-секции целы.
- **Live (Марина, person 4):** Sun-return 2027-03-22 = ДР; Saturn 3-pass 2048; Нептун/Плутон beyond_lifespan, Уран False.

## Находка

**RET-1 (low)** — `Domain/Returns.hs:211-223` + `Domain/TransitMath.hs:239-243`.
Когда `reference_jd` попадает **строго внутрь** незавершённой ретро-петли медленной планеты, `findNearestReturns` нумерует только выжившие (post-reference) пересечения → `phaseFromSpeedAndPass` (требует pass≥3 для DirectReturn) метит settling-проход как `Direct` вместо `DirectReturn`, затем поглощает первый проход *следующего* цикла как «pass 3 / DirectReturn» — сливая два разных возврата в одну плоскую серию.
Репро: `as_of=2048-04-01` для Марины → Saturn `[Retrograde 2048-06-28, Direct 2048-11-21, DirectReturn 2077-12-30]`.
**Направление движения и даты всегда верны** (speed-driven); деградирует только метка `DirectReturn` + группировка. Не влияет на даты, орб-окна, быстрые планеты, `beyond_lifespan`. **Безвреден для shipped live/PDF пути** (reference=сегодня → следующая петля целиком в будущем → чистая 1/2/3).
Fix-направление: группировать пересечения в петли ДО нумерации, либо определять полное число проходов петли из sample'ов до reference. → fix-TASK `2026-06-06-returns-retro-loop-midref-numbering`.

## Снято/дисмиссено (architect low-items)

- «лишний `signed_diff(lo)` в бисекции» — N/A для returns (уточнение = Haskell linear `interpolateZero`, без лишнего вызова). Дисмисс.
- `pyswisseph>=2.10` не запинен, прогрессии 365.25 vs тропик — вне scope этого diff'а, не введены здесь.

## Рекомендация TL

**X-1 пометить settled.** Завести одну low fix-задачу RET-1. Прочих fix-задач не требуется.
