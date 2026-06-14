# TASK: k2-contour2-analytics-review

- Status: review
- Ready: yes
- Date: 2026-06-14
- Project: crypto
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus) — параллельная сессия Owner'а
- Worker branch: влито в master (a8865c2 → merge 7b25258)
- Mode: normal
- Critical approved by: (нет)
- Reviewer: (обязателен — независимая сессия)

## Problem

Контур-2 «Аналитика 24/7» (advisory-разведка, К1..К7) сделан в ПАРАЛЛЕЛЬНОЙ
сессии Owner'а и УЖЕ влит в master, минуя общий конвейер ревью. По решению
Owner'а 14.06 «провести через независимое ревью» — оформляем ретроактивно.
Архитектура §4-бис контур 2 (аналитика 24/7: LLM классифицирует/сводит, но
НЕ принимает торговых решений; граница И-8).

## Состав (a8865c2, в master)

- new: platform/cpds_platform/analytics/{classify,digest,feeds,normalize,store,cli}.py
- new: schemas/{event_digest,intel_item}.schema.json (НОВЫЕ, не правка ядра-схем)
- new: golden/{intel_item,event_digest,regime_note}/*, тесты test_intel_*
  (включая test_intel_i8_firewall.py — авторский тест границы И-8).
- bin/cpds-intel, config/{analytics,feeds}.yaml.

## Acceptance (ревью на master @HEAD, изолированно по файлам analytics/intel)

- [ ] make check зелёный с чистого клона master.
- [ ] ГРАНИЦА И-8 (главное): analytics-контур НЕ касается денежного ядра
  (core/ Haskell, Gate/decide/Cpds/Signal/Profit/Reentry) — git diff
  подтверждает; intel-данные НЕ несут денежных полей (golden invalid.3
  money_field отвергается); LLM/классификация НЕ порождает торговых действий.
- [ ] Периметр: тронуты только analytics/, intel-схемы (новые), golden, тесты,
  cli-intel, config — НЕ существующие схемы ядра/снимка/полигона.
- [ ] Деградация источников (анти-бот/битый фид) — честно (как farside/Т-1),
  без молчаливого проглатывания (урок Т-1/Т-2).
- [ ] Секретов/ключей в репо нет; сети в тестах нет (фикстуры).
- [ ] Детерминизм; без float в числовых путях, где это важно.

## Context

- Архитектура §4-бис (контур 2), §3 (контракт), И-8 (модель не в деньгах).
- Прецедент: Т-2 он-чейн (параллельная сессия → ретроактивное ревью).
- Чужие ветки не трогать; это код УЖЕ в master — ревью на месте, доработка
  (если найдётся дыра) отдельной задачей поверх master.
