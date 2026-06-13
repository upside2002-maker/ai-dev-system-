# HANDOFF: reviewer → tl — t3a-signal-families

- Status: closed
- Date: 2026-06-13 13:42
- Project: crypto
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus (5 независимых линз-сессий + верификация, рабочий контур)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/crypto/TASKS/2026-06-13-t3a-signal-families.md

## Summary

Независимое адверсариальное ревью классификации сигнала ядра (tier A):
5 линз по зонам + верификация каждой находки руками. **Вердикт: ACCEPT.**
0 критических, 0 средних, 1 мелочь (перепутанная подпись граничного теста,
логика верна). Все 5 линз собрали `make check` зелёным; Admin перепроверил
вручную для протокола tier A.

## Done

- Инвариант 1 (critical_ok=false → всегда Unconfirmed) — воспроизведён на
  экзотике (все семьи extreme + critical_ok=false → Unconfirmed). Держится.
- Инвариант 6 (строгий порог) — логика корректна (ошибочна только подпись).
- Целочисленная арифметика ×10^8, без Double/Float, без переполнения
  (Integer); парсер фикс. точности переиспользован из принятого ядра.
- Монотонность (инв.4) и маппинг зон по таблице ТЗ; warm/hot в боевом коде
  не перепутаны.
- Взаимоисключение (инв.5): конфликт перегрев∧капитуляция → Neutral.
- Источник параметров (инв.3): порог/веса только из профиля, зашитых нет.
- Периметр чист: тронуты Signal.hs, cabal, SignalSpec.hs; Gate/CpdsStub/
  Canonical/Json/Sha256/schemas/platform не изменены; CLI прежний (Observe).

## Remaining

- MINOR: подпись граничного теста `core/test/SignalSpec.hs:302` перепутана
  («порог + ε» ↔ «порог − ε»), логика теста верна. Правка вынесена попутным
  пунктом в ТЗ Т-3b — отдельный цикл ради комментария не гоняем.

## Artifacts

- branch:               master
- commit(s):            3c5ef30 (Signal.hs + cabal), c6f0361 (SignalSpec.hs)
- PR:                   нет (локальная разработка, CI заморожен)
- tests:                27 core + 44 Signal Haskell + Python + кросс-хэш(8) + злой корпус(24/17) — зелёные
- Product repo status:  committed (репозиторий crypto-platform, дерево чистое)

## Conflicts / risks

Нарушений инвариантов не найдено. buildOk у всех 5 линз (ложных тревог
сборки, как было на Т-1, нет). Свод ревью с разбором по линзам:
`HANDOFFS/2026-06-13-t3a-signal-families-review.md`.

## Next step

Admin принимает Т-3a и ставит следующий кусок ядра Т-3b (денежная
арифметика чистой прибыли), включив попутную правку подписи теста.
