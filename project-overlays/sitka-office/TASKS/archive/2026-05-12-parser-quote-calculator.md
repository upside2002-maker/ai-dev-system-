# TASK: parser-quote-calculator

- Status: done
- Ready: yes
- Date: 2026-05-12
- Project: sitka-office
- Layer: web
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Калькулятор доставки/цены во фронте парсера (`sitka-web/src/components/parser/QuoteCalculator.tsx`) сейчас заглушка: поля есть, кнопка расчёта отключена, в UI текст «расчёт будет подключён позже». Превратить в рабочий инструмент для оператора. Шесть полей ввода: цена товара (USD), доставка по США (USD), международная доставка (USD), доставка по РФ (RUB), курс RUB/USD, маржа (%). Использовать актуальные `pricing settings` из API как дефолты — если эндпоинт уже отдаёт, взять через существующий клиент в `sitka-web/src/api/client.ts`. Оператор должен иметь возможность быстро менять значения руками. Показать breakdown в семь строк: товар в рублях, доставка по США, международная, по РФ, итоговая себестоимость, цена клиенту с маржой, ожидаемая маржа в рублях. Кнопка копирования итогового короткого расчёта в буфер обмена для отправки клиенту — обязательная часть задачи (не follow-up).

(Поправка от 2026-05-12: исходное ТЗ от Codex написало «семь полей», но явный список содержал шесть; Worker реализовал 6 inputs / 7 breakdown lines строго по явному перечислению, Tech Lead принял эту интерпретацию.)

## Files

- new:    (нет)
- modify: sitka-web/src/components/parser/QuoteCalculator.tsx
- modify: sitka-web/src/components/parser/QuoteCalculator.test.tsx
- delete: (нет)

Если в ходе работы Worker обнаружит, что нужно тронуть что-то ещё (например, `sitka-web/src/api/client.ts` для нового вызова за `pricing settings`) — он возвращается через HANDOFF, не делает молча.

## Do not touch

- `sitka-core/src/Engine/Pricing.hs` и весь `sitka-core/` — Haskell ядро без необходимости.
- `sitka-core/src/Api/PricingSettings.hs` — endpoint остаётся как есть, Worker только потребляет данные.
- Миграции БД (`sitka-core/db/migrations/`).
- Money-flow, касса, резервации, shipping expense backend.
- Если frontend-формулы недостаточно и нужно расширять backend — это follow-up, в этой задаче только frontend.

## Acceptance

- [ ] В `QuoteCalculator.tsx` убран режим «в разработке», кнопка расчёта активна.
- [ ] Все шесть входных полей работают; дефолты подтягиваются из `pricing settings`, если эндпоинт доступен.
- [ ] Breakdown показывает все семь строк: товар RUB, доставка США, международная, РФ, себестоимость, цена клиенту, маржа RUB.
- [ ] Нет `NaN`/`Infinity` ни на каких валидных и невалидных вводах.
- [ ] Пустые/битые поля дают понятное состояние валидации, не падение.
- [ ] Кнопка копирования итогового расчёта в буфер обмена работает.
- [ ] На десктопе компонент компактный, не разъезжается.
- [ ] `npm test -- QuoteCalculator` зелёный, тесты покрывают: расчёт на нормальных числах, пустые/некорректные поля, поведение кнопок расчёта и копирования.
- [ ] `npm run build` без ошибок.
- [ ] `make -C ~/Projects/ai-dev-system check` остаётся зелёным.

## Context

ТЗ от Codex 2026-05-13, согласованное в чате архитектуры. Пять продуктовых решений приняты до создания задачи: режим `normal` (фронтенд, не Tier A, не миграции); проверяющий обязателен отдельной сессией; кнопка копирования — часть задачи, не follow-up; новая инициатива (в `OPERATING/backlog.md` калькулятор не упоминался); Worker model — Claude Code.

После принятия — добавить заметку в `OPERATING.md` Sitka в раздел «Заметки» и обновить `STATUS_RU.md` Sitka в разделе «Сейчас».
