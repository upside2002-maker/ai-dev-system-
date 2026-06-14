# TASK: t5-merge-into-master

- Status: open
- Ready: yes
- Date: 2026-06-13
- Project: crypto
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus)
- Mode: normal
- Critical approved by: (нет)
- Reviewer: (обязателен — независимая сессия)

## Problem

Слить принятую ветку feat/t-5-backtest (бэктест-движок) в master,
разрешив текстовые конфликты с уже влитым Т-6 (отчёты). Обе работы
ОТРЕВЬЮЕНЫ и ПРИНЯТЫ по отдельности — это чисто механическое слияние,
НЕ новая логика. Конфликты только текстовые: обе ветки добавляли свои
подкоманды/секции рядом. master уже содержит Т-6 (eb319ae); ff-слияния
не выйдет, нужен merge с разрешением.

## Что сделать

1. На master (уже = eb319ae, Т-6 влит): `git merge feat/t-5-backtest`.
2. Разрешить конфликты, СОХРАНИВ ОБЕ СТОРОНЫ (это не выбор, а объединение):
   - `platform/cpds_platform/cli.py`: восстановить ЦЕЛИКОМ функции Т-6
     (`_build_run_for_reports`, `cmd_status`, `cmd_report`) И функцию Т-5
     (`cmd_backtest`); в парсере argparse — ВСЕ подкоманды обеих веток
     (status, report — Т-6; backtest — Т-5). git склеил общие начала тел
     функций (обе грузят снимки) — раздели аккуратно, каждая функция
     цельная и рабочая.
   - `Makefile`, `README.md`, `docs/CONTRACTS.md`: обе добавленные секции
     рядом (отчёты Т-6 + бэктест Т-5), ничего не потерять.
3. `make check` зелёный (это объективное доказательство корректного
   слияния — все тесты Т-1..Т-6 вместе).
4. Закоммитить merge.

## Do not touch

- Никакой НОВОЙ логики — только восстановить обе уже принятые стороны.
  Если конфликт требует выбора/изменения логики (не просто объединения) —
  СТОП и доклад (этого быть не должно: работы независимы по файлам, кроме
  cli/доков, где обе лишь ДОБАВЛЯЛИ).
- core/ (Haskell), schemas/, paper/, collectors/, reports/, backtest/ —
  их содержимое не менять; конфликты только в общих cli.py и доках.
- В ai-dev-system — только этот TASK и HANDOFF.

## Acceptance

- [ ] master содержит ОБЕ работы: `git log` показывает Т-5 и Т-6; функции
  cmd_status/cmd_report (Т-6) И cmd_backtest (Т-5) на месте в cli.py.
- [ ] Все подкоманды работают: `cli status`, `cli report`, `cli backtest`,
  `cli run-paper`, `cli snapshot` — парсер принимает каждую (тест/прогон).
- [ ] `make check` зелёный (полный набор Т-1..Т-6 вместе, кросс-хэш цел).
- [ ] Никакой логики не потеряно и не добавлено (diff обзор: только
  объединение блоков).

## Context

- Принятые: Т-5 (`archive/2026-06-13-t5-backtest-engine.md`, ветка
  feat/t-5-backtest @605f11e), Т-6 (`archive/2026-06-13-t6-reports-voice.md`,
  влит в master @eb319ae).
- Конфликтные файлы при `git merge feat/t-5-backtest`: Makefile, README.md,
  docs/CONTRACTS.md, platform/cpds_platform/cli.py (предупреждено воркерами).
- После приёмки этого слияния: feat/t-5-backtest, feat/t-6-reports —
  удалить (влиты); этап «данные и стенд» собран целиком.
- Чужие ветки feat/contour2-analytics, feat/t-2-onchain-valuation — НЕ
  трогать (другие колеи).
