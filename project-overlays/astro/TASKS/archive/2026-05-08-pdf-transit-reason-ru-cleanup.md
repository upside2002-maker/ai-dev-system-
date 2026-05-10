# TASK: pdf-transit-reason-ru-cleanup

- Status: done
- Ready: yes
- Date: 2026-05-08
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: light

## Problem

После Tier A `important-transit-planets-rule-fix` (commit `7b86cf9`) `ImportantTransitReason` ADT расширился c 3 до 5 значений: добавились `RulerOfSunSign` и `RulerOfStelliumSign`. Но presentation-слой (`services/api-python/app/pdf/builder.py:194-199`) не обновлён — словарь `_TRANSIT_REASON_RU` ещё содержит:

- 3 актуальных entry (`RulerOfAsc`, `RulerOfMc`, `KingOfAspects`) — OK
- 1 stale entry `"InTenthHouse": "планета 10 дома"` — больше не входит в schema enum
- 0 entries для двух новых reason types → fallback через `dict.get(value, value)` рендерит сырой ASCII identifier (`RulerOfSunSign`, `RulerOfStelliumSign`) в PDF

Reviewer Tier A advisory (HANDOFF Reviewer→TL `7b86cf9`): закрыть после accept-cascade Tier A.

## Files

- modify:
  - `services/api-python/app/pdf/builder.py:193-199` — обновить comment header («4 selection criteria» → «5 selection criteria»), удалить stale `"InTenthHouse"` ключ, добавить `"RulerOfSunSign"` + `"RulerOfStelliumSign"` с RU-метками. Финальный dict: 5 entries, синхронизирован со schema enum.

## Do not touch

- `core/astrology-hs/**`, `packages/**`, `apps/**`, любые fixtures, любые JSON-схемы, любые другие `pdf/*.py` файлы.
- `_TRANSIT_REASON_RU.get(value, value)` fallback pattern — оставляем как defensive (если в будущем reason добавится в enum раньше чем в этот dict, не упадёт).

## Acceptance

- [ ] `pytest` 70 passed / 0 failed (Python builder edit, golden cases и contract test не затронуты).
- [ ] `git show --stat HEAD` показывает ровно 1 файл (`services/api-python/app/pdf/builder.py`).
- [ ] 1 atomic commit поверх `7b86cf9`.
- [ ] `_TRANSIT_REASON_RU` keys ровно совпадают с 5 значениями enum в `packages/contracts/solar-computed-facts.schema.json` (cross-check визуально).
- [ ] RU-метки терминологически совпадают с Marina's rule-naming (см. attribution в TASK `important-transit-planets-rule-fix.md` § Context).

## Context

- Mode `light` (default для Tier C); **same-session TL inline execution accepted** per `policies/MODES.md` § light. No Worker subagent, no Reviewer subagent — mechanical dict update.
- Baseline: `astro:7b86cf9` (Tier A `important-transit-planets-rule-fix`), pytest 70/70.
- Trigger: Reviewer minor-advisory в HANDOFF `2026-05-08-reviewer-to-tl-important-transit-planets-rule-fix.md` § Findings.
- RU-выбор labels:
  - `RulerOfSunSign` → `«управитель знака Солнца»` (Marina rule wording: «знак Солнца → его управитель»)
  - `RulerOfStelliumSign` → `«управитель знака стеллиума»` (Marina rule wording: «знак с ≥3 planets → его управитель»)
- Stale `"InTenthHouse"` was a remnant of an earlier 4-criterion engine prototype (pre-Архипова's 5 rules); never matched current schema enum. Безопасно удалить.

**Execution isolation**: same-session TL inline accepted (Tier C mechanical, ≤10 lines code change, no Worker subagent needed).
