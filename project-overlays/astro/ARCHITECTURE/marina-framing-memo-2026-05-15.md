# Marina framing memo — Transit Section delivery

**Date:** 2026-05-15
**Author:** Project Tech Lead
**Product HEAD:** astro main @ `59ec177` (post-Recovery-program-closure)
**Status:** Lightweight post-closure artifact — separate from closure commit per user discipline 2026-05-15 («framing memo не смешивать с closure commit»).

---

## Что это

Памятка для Марины при показе результатов Transit Section. Не маркетинговый текст, а **честная справка по 4 категориям**: что готово, что с caveat'ами, что специально вне поставки. Цель — избежать ошибки «вся папка ready», которая была сделана 2026-05-13 (TASK 7b закрытие).

---

## Производственная категория (4 кейса)

Эти PDF можно показывать Марине напрямую. Все границы окон совпадают с её эталонами в пределах ±2 дня; все таблицы «Золотое правило транзита» прочитаны прямо с её страниц.

### 1. Наталья (08-natalya-2025-2026)

- **Соляр:** 07.08.2025 02:13 UTC, Москва.
- **PDF render:** `services/api-python/scripts/render_case.py --case-id 08-natalya-2025-2026 --output <path>`.
- **Структура:** monthly transit table + per-house interpretations + 3 outer-cards (Уран кв Венера, Нептун кв Юпитер, Нептун кв Нептун) + календарь.

**Одно editorial divergence для Марины:**
- **Нептун кв Нептун W1 start:** наш `02.04.2024` vs её `27.09.2024` (Δ +178 дней раньше).
- **Это не bug, это разница в visualization choice.** Engine видит, что орбис начинает закрываться на нашу дату; Марина в показе сужает окно — её narrative выбор.
- Подтверждено эмпирически (TASK 8E Path 1' Scenario 1, 2026-05-15): even расширение `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540 → 730` не двигает нашу дату (SR-491d внутри даже старого buffer). True editorial.

**Что сказать Марине:** «На карточке Нептун кв Нептун первое касание показано с 02.04.2024 — это техническое начало орбиса. Вы в эталоне сужаете до 27.09.2024 как практически значимое. Engine оставлен как есть, мы это знаем; если хотите узкое окно — это presentation выбор, можем сделать.»

### 2. Екатерина (05-ekaterina-2025-2026)

- **Соляр:** 11.03.2025 06:34 UTC, Москва.
- **Структура:** monthly + per-house + 3 outer-cards (Уран кв Луна, Уран секст Юпитер, Нептун тригон Юпитер) + календарь.

**1 anchor convention divergence (TYPE-A item 3 в § 4 калибровочного отчёта):**
- **Венера Jul 2025 monthly cell:** наш h4 vs её h3 (Δ ±1 дом).
- Причина: мы snapshot'им 15-го числа календарного месяца; Марина — 11-го (день её соляра). Венера движется ~1°/день, 4-дневный gap straddles границу h3/h4.

**Что сказать Марине:** «Венера в июле 2025 — у нас 4 дом, у вас 3 дом. Мы берём середину календарного месяца как срез; вы берёте день соляра. Венера в эти 4 дня переходит через куспид — отсюда разница. Если хотите, можем переключить snapshot на ваш anchor.»

### 3. Мария (07-mariya-2025-2026)

- **Соляр:** 01.07.2025 19:11 UTC, Москва.
- **Структура:** monthly + per-house + календарь. **Без outer-cards** — Марина в эталоне специально указывает: «В текущем году у вас не будет транзитных аспектов от высших планет.» Мы это уважаем (пустой allowlist).

**2 anchor convention divergences (TYPE-A items 4-5 в § 4):**
- **Июнь 2026:** Mars h9 vs Marina h8; Venus h11 vs Marina h10.
- **Июль 2026:** Saturn h8 vs Marina h7; Venus h12 vs Marina h11.
- Та же причина что у Екатерины: 15-е vs 1-е.

**Что сказать:** «Те же 2 строки monthly table расходятся на ±1 дом по той же причине — anchor convention. Стратегический fix — отдельная программа.»

### 4. Данила (10-danila-2025-2026)

- **Соляр:** 05.08.2025 07:44 UTC, Москва.
- **Структура:** monthly + per-house + 3 outer-cards (Уран кв Луна, Нептун кв Венера, Нептун кв Юпитер). **Карточка Нептун кв Юпитер показывает 4 окна (не 3)** — Марина в эталоне пишет «четвёртое касание». Engine native-emits 4 окна; никаких overrides.

**Без divergences после Phase 8B Path 1 horizon fix.** Все 4 outer-card windows совпадают с её эталоном ±2 дня. Раньше были off на 38-50 дней (engine sample horizon truncation), исправлено 2026-05-14.

---

## Категория «показывать с per-case caveat» (4 кейса)

Эти cases имеют allowlist + facts (12 + 2 + 9 + 2 = 25 outer cards across them), но **некоторые границы окон не покрыты тестами** — 12 documented future-work items в audit § A.2.1.D. Можно показывать **per-case с явным framing**, не как часть «папки готова».

### 5. Ксения (01-kseniya-2024-2025)

- **5 outer cards** (Уран кв Солнце, Уран кв Уран, Нептун тригон Солнце, Нептун кв Марс, Плутон тригон Юпитер).
- **После Phase 8E (BEFORE buffer 540→730):** Нептун окна стартов W1 теперь совпадают с Мариной ±2 дня. Раньше были off на 17-42 дня.
- **Caveat:** Плутон тригон Юпитер — Марина показывает окна ~100 дней, наш engine ~261 день. Marina narrows Pluto боксы вручную как presentation choice. **Future work:** add Pluto display rule (отдельная программа, не Phase 8).

### 6. Максим (02-maksim-2025-2026)

- **2 outer cards** (Уран оппозиция Плутон, Уран тригон Уран).
- **Caveat:** Марина показывает по 1 окну на каждой карточке (single Marina window). Engine emits 3-4 окна loop'а. Positional alignment: Marina[0] = engine[2] или [3] (не первое touch). **Future work:** single-window alignment helper в test infrastructure (Marina W1 → engine W_N mapping).
- **Что показывать:** карточки рендерятся правильно с 3-4 окнами; Марина может комментировать только то которое она выделила, остальные — engine context.

### 7. Артём (03-artem-2025-2026)

- **9 outer cards** (Уран тригон Солнце/Меркурий/Марс, Нептун оппозиция Солнце/Меркурий/Марс/Уран, Плутон тригон Солнце/Марс).
- **Caveats:**
  - Single-window alignment для Нептун оп Меркурий + Нептун оп Марс (Marina W1 = engine W3/W4).
  - Уран тригон Меркурий W1 start: Δ -4 дня (граничный, чуть вне ±2 дня tolerance; принято per consistency policy).
  - **Плутон тригон Марс:** Marina p. 29 показывает идентичные даты с Плутон тригон Солнце — **likely Marina editorial typo**. Engine output для P-Mars отличается. **Future work:** ask Marina если P-Mars дублирует P-Sun намеренно или это опечатка.
- **Что показывать:** карточки правильные; если Марина увидит «странные» даты на P-Mars, объяснить.

### 8. Валерия (04-valeriya-2025-2026)

- **2 outer cards** (Уран кв Сатурн, Уран оппозиция Плутон).
- **Caveat:** Та же single-Marina-window alignment что у Максима (Marina W1 = engine W2/W3).

---

## Категория «вне поставки» (1 кейс)

### 9. Анастасия (09-anastasiya-2025-2026)

**NOT в production supply.**

- **TYPE-D fixture/reference SR-time mismatch (~60 минут).** Наш fixture показывает соляр на одно время, Марина в эталоне — на другое. Расхождение в timezone resolution или birth time entry.
- **Не code regression, а data quality issue.** Требует отдельной data-revision sub-task: re-resolve birth_time + timezone через `timezonefinder`, сверить с Marina'ыным эталоном.
- **Не показывать Марине пока fixture не выровнен с её эталоном.** Иначе будут расхождения на каждой границе окон — не из-за engine, а из-за разных входных данных.

---

## Категория «future work, неотделимая часть Phase 8 carry-over»

12 documented items в audit `phase-8-audit-report-2026-05-14.md` § A.2.1.D, **вне Phase 8 implementation programme**:

1. **Pluto display rule** (3 cards: 01 P-J, 03 P-Sun, 03 P-Mars) — engine выдаёт широкие окна, Марина сужает; нужен presentation-layer Pluto narrowing helper.
2. **Single-window alignment helper** (6 cards) — расширить `MARINA_OUTER_CARD_BOUNDARIES` схему чтобы поддерживать per-card `engine_window_index` mapping.
3. **Case 03 P-Mars Marina typo** — спросить Marina'у, дублируют ли даты P-Mars и P-Sun намеренно.
4. **Анастасия TYPE-D** — пересобрать fixture.

Если будет следующий цикл работ по Transit Section — это четыре отдельных под-программы (не одна).

---

## Operational discipline для показа

- **Render:** `services/api-python/scripts/render_case.py --case-id <case-id> --output <path>`. Provenance sidecar (`<path>.provenance.json`) должен показывать `git_sha = 59ec1773ccbd...` или новее. Если git_sha старый — PDF stale.
- **Debug footer:** sidecar должен иметь `debug == false` или `None`. На клиентских PDF debug footer не виден (text-extract verified, Phase 1).
- **Один кейс — одно общение с Мариной.** Не давать «папку из 9 PDFs» одним архивом — это retraction'ит весь честный framing.
- **На случай вопросов:** ссылаться на этот memo по конкретной категории.

---

## Cross-references

- Recovery program SoT: `ARCHITECTURE/transit-section-program-2026-05-13.md`.
- Final calibration report verdict: `ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` § 6 «post-cascade-closure 2026-05-15».
- Phase 8 audit + 12 future-work items: `ARCHITECTURE/phase-8-audit-report-2026-05-14.md` § A.2.1.D.
- Phase 4a memo + Phase 8B Path 1 erratum: `ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`.

---

**Memo не подписан как «production-ready без caveats» — каждый кейс имеет свой framing context.** Это и есть честная поставка вместо «папка готова».
