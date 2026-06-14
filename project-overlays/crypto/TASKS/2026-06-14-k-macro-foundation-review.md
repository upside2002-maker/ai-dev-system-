# TASK: k-macro-foundation-review

- Status: review
- Ready: yes
- Date: 2026-06-14
- Project: crypto
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus) — параллельная сессия Owner'а
- Worker branch: влито в master (7258f36)
- Mode: normal
- Critical approved by: (нет)
- Reviewer: (обязателен — независимая сессия)

## Problem

Макро-фундамент (свежие ряды ФРС с учётом ревизий + модуль рыночного режима)
сделан в ПАРАЛЛЕЛЬНОЙ сессии Owner'а и УЖЕ влит в master, минуя общий
конвейер. По решению Owner'а 14.06 — независимое ревью ретроактивно.
Это advisory-исследовательский модуль (макро-режим), денег и права ядра
на деньги НЕ касается.

## Состав (7258f36, в master)

- modify: platform/cpds_platform/collectors/fred.py (vintage-ревизии ALFRED)
- new: platform/cpds_platform/research/{macro_regime,macro_config,intmath}.py
- new: config/macro.yaml, fixtures/fred_alfred_revisions.json,
  test_macro_regime.py (414 тестов), test_collectors.py (+).

## Acceptance (ревью на master @HEAD, изолированно по файлам research/macro/fred)

- [ ] make check зелёный с чистого клона master.
- [ ] ГРАНИЦА (главное): макро-режим НЕ влияет на critical_ok/право ядра на
  деньги; НЕ касается core/ (Haskell), снимка дня (market_snapshot), полигона.
  git diff подтверждает (только fred.py + research/).
- [ ] POINT-IN-TIME макро: vintage-ревизии ФРС берутся «как было известно на
  дату» (ALFRED), без заглядывания в будущее (макро-ревизии публикуются
  задним числом — это классическая ловушка; проверить, что режим на дату T
  не видит позже-опубликованных ревизий).
- [ ] intmath: проценты/перцентили/доли целые ×10^8, без float (1 float-
  вхождение в macro_regime.py — проверить, что это коммент/тест, не расчёт).
- [ ] Детерминизм (тот же вход → тот же режим); секретов/ключей нет
  (FRED-ключ из окружения); сети в тестах нет.

## Context

- Архитектура §3.1 (декларации поставщиков), исследование §6 (макро-факторы),
  дыра Д-1 (история). Макро — генератор гипотез, не источник денежных решений.
- Прецедент Т-2: параллельная работа → ретроактивное независимое ревью.
- Код УЖЕ в master; доработка при находке — отдельной задачей поверх.
