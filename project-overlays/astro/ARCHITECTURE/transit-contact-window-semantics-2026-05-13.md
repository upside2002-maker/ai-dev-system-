# Transit Contact Window Semantics — Analysis Memo

Дата: 2026-05-13
Tier: C (analysis only — no code, no schema, no test changes).
Source TASK: `project-overlays/astro/TASKS/2026-05-13-transit-contact-window-semantics.md`.
Baseline: `main` @ `8c9588d` — `113 passed + 10 xfailed`.

Sibling document (recovery program SoT): `transit-section-program-2026-05-13.md`
(§ 6 «Outer-planet intervals» ERRATUM block).

---

## § 1. Контекст

После Phase 4 Path 3 (TASK 4 closed at commit `8c9588d`) в acceptance contract Натальи остались
два xfail-теста Category 4:

- `test_neptune_square_jupiter_three_touches_tolerance_2d` — engine end `30.01.2028`
  vs Marina `16.02.2028` (Δ ≈ 17 d).
- `test_neptune_square_neptune_three_touches_tolerance_2d` — engine start `02.04.2024`
  vs Marina `27.09.2024` (Δ ≈ 178 d).

Оба отмечены reason'ом `"TASK 4a — Neptune slow-loop contact window semantics"`. Phase 4
закрылась через aggregation engine raw hits → 3 «display windows» per allowlist triple
(`outer_cards.py`), но aggregation НЕ воспроизводит Marina boundaries для медленных
loops. Phase 4 preflight HANDOFF (2026-05-13) зафиксировал mismatch; Phase 4 Path 3
запечатал его как «accepted divergence» без формального обоснования.

TASK 4a — настоящий memo — формализует таксономию transit-contact concepts, тестирует
гипотезы о Marina display rule на 3 примерах Натальи (Uranus-Venus, Neptune-Jupiter,
Neptune-Neptune) и рекомендует TL/user один из трёх path для closure 2 Cat 4 xfails.

Phase 5/6/7 ожидают decision по TASK 4a; до неё recovery program остаётся в Phase 4
plateau со status `113 passed + 10 xfailed`.

---

## § 2. Taxonomy (5 concepts)

Перечисленные ниже concepts — общий язык memo. Definitions воспроизводятся из engine
source code (`core/astrology-hs/src/Domain/TransitCalendar.hs`) и из Marina reference
deck (`Соляр 2025-2026_5.pdf` pp. 17-22). Примеры — из engine output Натальи
(`packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json`).

### 2.1 `raw hit`

**Definition.** Запись `TransitContact` от engine — одно `exact_jd` + одна
`MotionPhase` + одна `(orb_enter_jd, orb_exit_jd)` пара. Эмитится в
`numberContactsFor` (`TransitCalendar.hs:586-606`). Для каждой триплеты
`(transit_planet, target, aspect)` engine эмитит по одному raw hit per
`loop_pass` index, где `loop_pass` = порядковый номер exact пересечения
shifted-target line в стриме samples.

**Example.** Neptune-Neptune Square Натальи — engine эмитит **4 raw hits**:

```
loop_pass=1 phase=Direct        exact=01.05.2024  orb_enter=02.04.2024  orb_exit=12.10.2024
loop_pass=2 phase=Retrograde    exact=05.09.2024  orb_enter=02.04.2024  orb_exit=12.10.2024
loop_pass=3 phase=DirectReturn  exact=02.03.2025  orb_enter=31.01.2025  orb_exit=29.03.2025
loop_pass=4 phase=DirectReturn  exact=09.12.2025  orb_enter=24.10.2025  orb_exit=24.01.2026
```

**Relationship.** Каждый raw hit принадлежит ровно одному `orb window`. Для быстрых
планет (Уран в нашем sample) `raw hit count = orb window count`. Для медленных
(Нептун) один orb window может содержать несколько raw hits (см. ниже `orb window`).

### 2.2 `motion phase hit`

**Definition.** Синоним `raw hit`, используемый в контексте обсуждения порядка
Direct → Retrograde → DirectReturn внутри одного цикла подходов планеты к exact
аспектному углу. Phase классифицирована в `phaseFromSpeedAndPass`
(`TransitCalendar.hs:292-296`): `Direct` если `speed >= 0` и `loop_pass < 3`,
`Retrograde` если `speed < 0`, `DirectReturn` если `loop_pass >= 3 && speed >= 0`.

**Example.** Neptune-Jupiter Square Натальи — phases в порядке emission:
`[Direct, Retrograde, DirectReturn, Retrograde, DirectReturn]` (5 raw hits = 5 motion
phase hits). Phase order **внутри одного orb window** может быть `D+R` или `R+DR`
(для slow movers), реже single phase (например, после retrograde station planet
exits orb до следующего захода).

**Relationship.** `motion phase hit` = `raw hit` через другую оптику: при обсуждении
test contract `_assert_three_phase_intervals` мы говорим «3 phases», подразумевая
3 raw hits с конкретными phases.

### 2.3 `orb window`

**Definition.** Интервал `[orb_enter_jd, orb_exit_jd]` где `|signedArc| ≤ orb_class`
непрерывно (см. `findOrbWindows`, `TransitCalendar.hs:333-404`). Эмитится один
window на каждый «approach + retreat» cycle для конкретного shifted-target longitude.
Orb threshold per planet class — из `daragan-orbs-v1.json:transit_per_planet_class`,
для Нептуна и Урана = **1.0°**.

**Example.** Neptune-Neptune Square Натальи — engine эмитит **3 уникальных orb
windows** (consolidated):

```
W1: orb_enter=02.04.2024  orb_exit=12.10.2024  (193 days, contains lp1+lp2 = D+R)
W2: orb_enter=31.01.2025  orb_exit=29.03.2025  ( 57 days, contains lp3 = DR)
W3: orb_enter=24.10.2025  orb_exit=24.01.2026  ( 92 days, contains lp4 = DR)
```

Aggregation `raw hits → orb windows` сейчас выполняется в Phase 4
`outer_cards.aggregate_display_windows` (`outer_cards.py:245-302`) — group by rounded
`(orb_enter_jd, orb_exit_jd)` tuple. Это deterministic из engine output.

**Relationship.** `orb window` — engine native concept. На каждый orb window
приходится ≥ 1 raw hit (если планета достигает exact ≥ 1 раза в окне) или 0 raw
hits + 1 synthetic «window-only» record (`windowOnlyContacts`, `TransitCalendar.hs:536-549`).

### 2.4 `display contact`

**Definition.** Один из 3 интервалов реализации, который Marina показывает клиенту
в outer-planet card («1-е касание» / «2-е касание» / «3-е касание»). Формат:
`DD.MM.YYYY HH:MM (GMT+3) - DD.MM.YYYY HH:MM (GMT+3) — N-е касание`. Marina всегда
показывает **3 display contacts** per card, даже когда engine эмитит больше или
меньше raw hits.

**Example.** Marina reference для Neptune-Jupiter Square Натальи (Соляр 2025-2026 p. 20):

```
W1: 21.04.2026 12:00 - 28.09.2026 12:00 — первое касание
W2: 21.02.2027 12:00 - 16.04.2027 12:00 — второе касание
W3: 10.10.2027 00:00 - 16.02.2028 12:00 — третье касание
```

**Relationship.** Для **быстрых** outer (Uranus в Натальe) `display contact = orb
window = raw hit` (1:1:1). Для **медленных** (Neptune) `display contact` сейчас
аггрегирована Phase 4 как `display contact = orb window` (3 windows из 4-5 raw hits),
но на границах окон Marina и engine **не совпадают** для двух конкретных случаев
(N-J W3 boundary ~17d, N-N W1 boundary ~178d).

### 2.5 `tight Marina window` (гипотеза)

**Definition.** Гипотетический narrowed subset `orb window`'а, который Marina
визуально рисует как «касание» в карточке. Формула предполагается одной из:
(а) tight orb threshold (например, 0.5° вместо 1°), (б) anchor на конкретный exact
moment, (в) start at re-approach после R station, (г) editorial / non-deterministic.
§ 4 ниже тестирует все четыре варианта.

**Example.** Для Neptune-Neptune Square Натальи Marina W1 = `27.09.2024 - 12.10.2024`
(15 дней), что соответствует tail последних 15 дней engine orb window (которое длится
193 дня от 02.04.2024 до 12.10.2024). Конкретное правило, по которому Marina выбрала
именно `27.09` стартом — TASK 4a domain analysis.

**Relationship.** Если `tight Marina window` deterministic — её можно воспроизвести
формулой в engine или в presentation aggregation, и Cat 4 xfails закроются (Path 2).
Если non-deterministic — закрытие через documented exception (Path 3) или relaxation
test contract (Path 1).

---

## § 3. Engine semantic analysis

### 3.1 Где orb-window-start определяется

`TransitCalendar.hs:338-404` — функция `findOrbWindows samples target orb`. Walks
the sample stream, watching `inOrb s = abs (signedArc (sLong s) target) <= orb`.

- Линия `374-386`: если на текущем sample `in1 == True` и не было открытого окна —
  **открыть окно с anchor на `sJd s1`** (`go rest (Just (sJd s1))`).
- Линия `387-394`: если на следующем sample `in2 == True` но `in1 == False` —
  **интерполировать момент входа в orb** через `interpolateOrbBoundary` и открыть
  окно от него.

То есть `orb_enter_jd` — это **первый момент** когда `|signedArc| <= orb` после
периода out-of-orb. Threshold orb для Neptune = 1.0° (см. `transitOrbForPlanet`,
`TransitCalendar.hs:240`, и mirror в `daragan-orbs-v1.json:transit_per_planet_class.Neptune`).

### 3.2 Где orb-window-end определяется

`TransitCalendar.hs:395-404` — внутри `Just startJd`:
- Если `in2 == True` — продолжаем (`go rest (Just startJd)`).
- Если `in2 == False` — **интерполировать момент выхода из orb** через
  `interpolateOrbBoundary` и закрыть окно (`(startJd, jdExit) : go rest Nothing`).

То есть `orb_exit_jd` — это **последний момент** когда `|signedArc| <= orb` перед
переходом в out-of-orb. Тот же threshold 1.0°.

### 3.3 Где hits эмитятся

`TransitCalendar.hs:303-321` — функция `findCrossings samples target`. Walks
consecutive sample pairs, emits one record при каждом sign change `d1 * d2 < 0` (с
guards против 0/360 phantom flips). Это эмиссия **exact moment** пересечения
shifted target longitude — каждый такой момент = один raw hit.

`numberContactsFor` (`TransitCalendar.hs:586-606`) группирует все hits по aspect,
сортирует по `exact_jd`, нумерует `loop_pass` от 1 и attach'ит phase через
`phaseFromSpeedAndPass`.

`matchTouchesToWindows` (`TransitCalendar.hs:514-531`) для каждого hit находит
enclosing `(orb_enter, orb_exit)` window. Если orb window содержит несколько hits
(slow mover) — **они все получают одинаковую `(orb_enter, orb_exit)` пару**.

Поэтому Neptune-Jupiter window 1 (engine W1) содержит hits lp=1 (D) и lp=2 (R) с
идентичными `orb_enter_jd=2461151.5298` (21.04.2026) и `orb_exit_jd=2461312.0575`
(28.09.2026). Aggregation Phase 4 группирует их в одно display window.

### 3.4 Orb thresholds per planet class

Из `packages/rulesets/daragan-orbs-v1.json:transit_per_planet_class` (mirror в
`transitOrbForPlanet` `TransitCalendar.hs:232-242`):

```
Sun     1.0°
Moon    1.0°
Mercury 1.0°
Venus   1.0°
Mars    1.0°
Jupiter 1.0°
Saturn  1.0°
Uranus  1.0°
Neptune 1.0°
Pluto   1.25°
```

Для Урана и Нептуна — одинаковый 1.0°. То есть **разница в behavior U-V vs N-* НЕ
объясняется orb threshold** — она объясняется только **скоростью** транзитной
планеты (Уран идёт быстрее, его orb window короче и содержит ровно 1 phase;
Нептун идёт медленнее, его orb window длится 100-200+ дней и содержит 1-2 phases).

### 3.5 Raw engine output для трёх выборок Натальи

Все JD конвертированы в Europe/Moscow (Marina timezone), MSK = UTC+3.

**Uranus Square Venus** (engine: 3 raw hits, 3 orb windows, 1 hit per window):

```
W1 (Direct      ): orb_enter=03.06.2025 06:18  exact=21.06.2025 13:54  orb_exit=12.07.2025 19:04
W2 (Retrograde  ): orb_enter=02.11.2025 08:22  exact=26.11.2025 18:37  orb_exit=22.12.2025 20:33
W3 (DirectReturn): orb_enter=18.03.2026 15:55  exact=11.04.2026 07:28  orb_exit=30.04.2026 08:44
```

**Neptune Square Jupiter** (engine: 5 raw hits, 3 orb windows):

```
W1 (D+R): orb_enter=21.04.2026 03:42  orb_exit=28.09.2026 16:22
   lp1 Direct       exact=25.05.2026 18:59
   lp2 Retrograde   exact=20.08.2026 12:44
W2 (DR ): orb_enter=21.02.2027 10:16  orb_exit=16.04.2027 19:20
   lp3 DirectReturn exact=21.03.2027 00:03
W3 (R+DR): orb_enter=09.10.2027 22:43  orb_exit=30.01.2028 05:13
   lp4 Retrograde   exact=29.11.2027 02:22
   lp5 DirectReturn exact=31.12.2027 20:10
```

**Neptune Square Neptune** (engine: 4 raw hits, 3 orb windows):

```
W1 (D+R): orb_enter=02.04.2024 05:37  orb_exit=12.10.2024 05:51
   lp1 Direct       exact=01.05.2024 17:37
   lp2 Retrograde   exact=05.09.2024 05:58
W2 (DR ): orb_enter=31.01.2025 09:40  orb_exit=29.03.2025 05:25
   lp3 DirectReturn exact=02.03.2025 15:17
W3 (DR ): orb_enter=24.10.2025 19:44  orb_exit=24.01.2026 18:03
   lp4 DirectReturn exact=09.12.2025 18:53
```

---

## § 4. Marina semantic hypothesis

### 4.1 Reference dates (Marina display windows)

Из Соляр 2025-2026 pp. 17-22 (визуально извлечено):

| Card | W1 | W2 | W3 |
|---|---|---|---|
| Уран ⬜ Венера | 03.06.2025 12:00 – 12.07.2025 12:00 | 02.11.2025 12:00 – 22.12.2025 12:00 | 19.03.2026 00:00 – 30.04.2026 00:00 |
| Нептун ⬜ Юпитер | 21.04.2026 12:00 – 28.09.2026 12:00 | 21.02.2027 12:00 – 16.04.2027 12:00 | 10.10.2027 00:00 – 16.02.2028 12:00 |
| Нептун ⬜ Нептун | 27.09.2024 00:00 – 12.10.2024 00:00 | 31.01.2025 12:00 – 29.03.2025 00:00 | 25.10.2025 00:00 – 24.01.2026 12:00 |

### 4.2 Side-by-side engine vs Marina (boundary deltas)

Все JD в MSK.

| Card / Window | Engine start | Marina start | Δstart | Engine end | Marina end | Δend |
|---|---|---|---|---|---|---|
| **U-V W1** | 03.06.2025 06:18 | 03.06.2025 12:00 | +0.2 d | 12.07.2025 19:04 | 12.07.2025 12:00 | +0.3 d |
| **U-V W2** | 02.11.2025 08:22 | 02.11.2025 12:00 | +0.2 d | 22.12.2025 20:33 | 22.12.2025 12:00 | +0.4 d |
| **U-V W3** | 18.03.2026 15:55 | 19.03.2026 00:00 | +0.3 d | 30.04.2026 08:44 | 30.04.2026 00:00 | +0.4 d |
| **N-J W1** | 21.04.2026 03:42 | 21.04.2026 12:00 | +0.4 d | 28.09.2026 16:22 | 28.09.2026 12:00 | +0.2 d |
| **N-J W2** | 21.02.2027 10:16 | 21.02.2027 12:00 | +0.1 d | 16.04.2027 19:20 | 16.04.2027 12:00 | +0.3 d |
| **N-J W3** | 09.10.2027 22:43 | 10.10.2027 00:00 | +0.1 d | 30.01.2028 05:13 | 16.02.2028 12:00 | **+17.3 d** |
| **N-N W1** | 02.04.2024 05:37 | 27.09.2024 00:00 | **+177.8 d** | 12.10.2024 05:51 | 12.10.2024 00:00 | +0.2 d |
| **N-N W2** | 31.01.2025 09:40 | 31.01.2025 12:00 | +0.1 d | 29.03.2025 05:25 | 29.03.2025 00:00 | +0.2 d |
| **N-N W3** | 24.10.2025 19:44 | 25.10.2025 00:00 | +0.2 d | 24.01.2026 18:03 | 24.01.2026 12:00 | +0.3 d |

**Наблюдения:**
- 7 из 9 windows ≤ 0.5 d boundary parity — engine точно совпадает с Marina.
- 1 window (N-J W3 end) — engine на **17 d раньше** Marina. Marina **расширяет**
  окно за пределы engine 1° orb threshold.
- 1 window (N-N W1 start) — engine на **178 d раньше** Marina. Marina **обрезает**
  окно до 15-day tail в конце engine orb window.

### 4.3 Hypothesis test

#### H1 — Tight orb threshold (Marina = 0.5° или 0.3°)

**Идея.** Marina рисует касание от момента, когда `|signedArc| <= 0.5°` вместо 1°.

**Test U-V W1.** Engine orb_enter (1°) = 03.06.2025 06:18. Если уменьшить порог до
0.5° — orb_enter сдвинется позже (планета должна подойти ближе). Marina = 03.06.2025
12:00 = engine + 6 часов. То есть Marina практически совпадает с engine 1° threshold,
не tighter. **H1 не fits U-V** (даже tighter threshold даст ещё более поздний start
по сравнению с Marina).

**Test N-J W3 end.** Engine orb_exit = 30.01.2028 05:13 (планета пересекает +1°
threshold на выходе). Marina end = 16.02.2028 12:00 (на 17 дней позже). Если Marina
использует **wider** orb (например, 1.5°), боундари сдвинется позже — это работает
для N-J W3. Но Marina W1/W2 N-J идеально совпадают с engine 1° threshold. То есть
Marina не использует **одинаковую** wider orb. **H1 не fits N-J W3** (потребует
heterogeneous threshold per window).

**Test N-N W1.** Engine orb_enter = 02.04.2024 05:37. Marina start = 27.09.2024
(на 178 дней позже). Если бы Marina использовала tight orb 0.5°, start сдвинулся
бы примерно на 10-15 дней позже engine 1° (Нептун движется ~0.04°/день), но не
на 178 дней. Чтобы получить start 27.09.2024 при approach к Direct exact 01.05.2024
нужен невероятно tight orb < 0.05° — но тогда engine D exact 01.05 и R exact 05.09
тоже выпадут из orb (они дальше 0.05° от exact в начале их approaches). **H1 не
fits N-N W1**.

**Verdict H1: doesn't fit** на всех 3 примерах.

#### H2 — Anchored at exact-Direct/Retrograde with fixed window half-width

**Идея.** Marina центрирует окно на `exact_jd` каждого raw hit и расширяет на
фиксированную half-width (например, ±20 дней).

**Test U-V W1.** Engine exact = 21.06.2025 13:54. Marina = 03.06-12.07. Half-widths:
`21.06 - 03.06 = 18 d` (start half), `12.07 - 21.06 = 21 d` (end half). Half-width
~20 d.

**Test U-V W2.** Engine exact = 26.11.2025 18:37. Marina = 02.11-22.12. Half-widths:
24 d / 26 d. Half-width ~25 d. Different from W1.

**Test U-V W3.** Engine exact = 11.04.2026 07:28. Marina = 19.03-30.04. Half-widths:
23 d / 19 d. Half-width ~21 d.

**Test N-J W1.** Engine has 2 exacts (D 25.05.2026, R 20.08.2026). Marina = 21.04-28.09.
- Если центрировать на D exact: 21.04-25.05 = 34 d, 25.05-28.09 = 126 d. Asymmetric.
- Если центрировать на R exact: 21.04-20.08 = 121 d, 20.08-28.09 = 39 d. Asymmetric.
- Если центрировать на midpoint D-R: midpoint = 22.07.2026; half-widths: 91 d / 67 d. Asymmetric.

**Test N-N W1.** Marina = 27.09-12.10. Engine exacts: D 01.05.2024, R 05.09.2024.
- Distance Marina center (04.10.2024) от R exact = 29 d. От D exact = 156 d. Не
  центрирована ни на одном.

**Verdict H2: doesn't fit** — Marina widths не fixed и не симметричны вокруг exact.

#### H3 — Heuristic skip of «long drift» periods (Marina shows only tail of long approach)

**Идея.** Если planet остаётся в орбе > N дней без приближения exact (например,
после R station и до exit) — Marina пропускает «long drift» и рисует касание только
как период approach перед exit OR approach перед re-entry.

**Test N-N W1.** Engine W1 = 02.04 - 12.10.2024 (193 days). Внутри:
- 02.04 - 01.05: approach to D exact (Direct motion, 29 days, planet closing in).
- 01.05 - 05.09: post-D, retrograde station and motion away (~127 days drift).
- 05.09 - 12.10: post-R exact, drift to exit (37 days, planet moving away).

Marina W1 = 27.09 - 12.10.2024 — последние 15 days перед exit. Это **tail после
R exact**, но не «approach» — это уже movement-away phase. Гипотеза «Marina shows
period of last approach» не работает для N-N W1 (там approach уже прошёл, остался
drift к выходу).

Альтернатива: «Marina shows last 15-20 days перед orb exit when planet has both
phases done». Тогда window — это `[orb_exit - X, orb_exit]`. X ≈ 15 для N-N W1.
Но N-J W1 показывает full engine window (160 days), не tail. Структура
N-J W1 и N-N W1 **идентична** (D+R в одном orb window, оба exact INSIDE window).
Почему Marina выбрала full window для одного и tail для другого — **не выводимо
из morphology данных**.

**Test N-J W3 end.** Engine end 30.01.2028 (1° orb exit). Marina end 16.02.2028
(+17 d after). Может Marina расширила окно «по умолчанию», или включила какой-то
post-orb tail? Тогда N-J W1 должно ли тоже иметь +17 d extension on end? Engine
W1 end = 28.09.2026, Marina W1 end = 28.09.2026 — точное совпадение. **H3 не
объясняет асимметрию между W1 и W3 N-J.**

**Verdict H3: doesn't fit** — гипотеза «long drift skip» не консистентна между
N-J W1 (full) и N-N W1 (tail) при одинаковой morphology; гипотеза «post-orb
extension» не консистентна между N-J W1 (no extension) и N-J W3 (17d extension).

#### H4 — Editorial / non-deterministic

**Идея.** Marina выбирает boundaries окон ad hoc — по визуальному значению, по
календарной удобности, по своему opinion о «когда транзит начинается реально».
Нет общей formula, отсюда невозможность reverse-engineer rule из 3 примеров.

**Test.** Для всех 3 примеров:
- U-V (быстрая): Marina ≈ engine exactly (±0.5 d), потому что окна короткие и
  «no choice» — окна разнесены и не требуют редакционного отбора.
- N-J W1, W2: Marina = engine (full orb window). Editorial choice — «показываем
  как есть».
- N-J W3: Marina = engine + 17d extension. Editorial choice — «продолжаем до
  более round календарной даты».
- N-N W2, W3: Marina = engine (full orb window of single DR phase).
- N-N W1: Marina = engine tail (15 days). Editorial choice — «показываем только
  значимый approach перед exit, drift игнорируем» либо просто оставляем 1-е
  касание короткое для clean readability.

**Verdict H4: fits — это единственная гипотеза, объясняющая ВСЕ 3 примера без
противоречий.** Marina **не использует deterministic rule**, доступный engine
для воспроизводства. Её выбор — editorial / визуальный judgement.

### 4.4 Best-fit hypothesis

**H4 (editorial / non-deterministic).** Аргументы за:
1. **N-J W1 vs N-N W1 морфологически идентичны** (D+R в одном orb window, similar
   timing offsets D~+29-34d after orb_enter, R~+37-39d before orb_exit), но Marina
   рисует одно как full window, другое как 15-day tail. Это явный сигнал
   редакционного выбора.
2. **N-J W3 extends 17d за engine 1° orb threshold**, но N-J W1 совпадает с
   engine 1° orb. Никакая deterministic orb-based rule не может одновременно
   делать W1=engine и W3=engine+17d.
3. **H1, H2, H3 каждая fits 1-2 из 3 примеров**, но ни одна не fits все 3
   одновременно.

**Возможная sub-hypothesis для подсказки UX.** Marina, вероятно, рисует Marina W1
как «короткий 1-й touch» когда первое orb window длится больше ~150 дней и
содержит два exact moments (D+R) — это «1-й touch» только в формальном смысле
«первое появление в орбе», а реально событийно значимый период наступает только
после R station, ближе к orb exit. Этот UX-rationale **может быть приближён**
правилом «если orb_window > 150d и содержит ≥ 2 phases — Marina anchor's start at
`orb_exit - 15d`», но эта rule **не подтверждена** на 3 примерах: N-J W1 (160d, 2
phases) она бы перерисовала, чего Marina не сделала. То есть rule не universal.

---

## § 5. Path analysis

### Path 1 — Test contract semantic fix (Tier C low cost)

**Что меняется.**
- `_assert_three_phase_intervals` (`tests/test_natalya_transits_acceptance.py:406`)
  перерабатывается с `len(hits) == 3` на `len(aggregate_display_windows(hits)) == 3`
  (используя ту же aggregation, что Phase 4 `outer_cards.aggregate_display_windows`).
- Phase order проверяется как **set of phases per window** (`{Direct, Retrograde}`,
  `{DirectReturn}`, etc.), не strict ordered list.
- Per-window boundary tolerance остаётся `±2d`, но для **explicitly documented
  windows** добавляется per-aspect override (например, `N-N W1: tolerance for start
  = 200d` или `accept Marina-vs-engine divergence`).

**Pros.**
- Низкая стоимость (один файл tests, ~30 строк).
- Не трогает engine, schema, fixtures.
- Соответствует Phase 4 aggregation reality (раз aggregation уже сделана в
  `outer_cards.py`, test может опираться на тот же helper).

**Cons.**
- **Не решает 178d shift для N-N W1**: либо нужны documented exceptions per window
  (что подрывает идею uniform acceptance criteria), либо tolerance расширяется до
  ~200 дней (что делает test бесполезным как regression guard).
- Делает test contract **более weak** — N-J W3 (17d Δ) тоже потребует exception
  или tolerance 20+ дней, что покрывает уже не «boundary parity», а «boundary
  approximately near».
- Не закрывает root cause — engine продолжает эмитить wide orb windows, Marina
  продолжает показывать narrow display windows для 2 из 9 case Натальи.

**Cost estimate.**
- Tier C, Worker subagent.
- ~1 файл, ~30-50 LoC.
- 1 commit, без schema cascade.
- Acceptance: 2 Cat 4 xfail тесты flip → passing с relaxed assertions; ничего
  другого не трогается.

**Specifically about 178d shift.** Path 1 решает только если acceptance test
**explicitly accepts** divergence. То есть Path 1 в чистом виде = Path 3 в маске
теста. Если TL/user не хочет «накрывать» Marina divergence — Path 1 не fits.

### Path 2 — Engine semantic adjustment (Tier A cascade)

**Что меняется.**
- `Domain.TransitCalendar.findOrbWindows` или новая функция `findDisplayWindows`,
  которая эмитит **narrower windows** соответствующие Marina display contacts.
- Возможно extension `TransitContact` или новый field `display_orb_enter_jd /
  display_orb_exit_jd` в schema.
- Fixtures regenerate × 9 cases.

**Per TL ограждение в TASK spec.** Worker обязан доказать deterministic rule на
3 примерах Натальи. § 4 above показывает что **ни одна из тестированных гипотез
(H1, H2, H3) не выводится универсально на всех 3 примерах**. H4 (non-deterministic)
явно не реализуема в engine. Следовательно:

**Path 2 НЕ РАБОТАЕТ** в чистом виде. Любой engine deterministic rule сможет
закрыть максимум 2 из 3 cases, оставив третий xfail.

**Если ослабить требование** (accept что engine закроет только 1 из 2 Cat 4 xfail
— например, изменить boundary logic to narrow N-N W1, но оставить N-J W3 как
documented exception) — это hybrid Path 2+3. Cost остаётся Tier A cascade при
неполной победе. Не рекомендуется.

**Blast radius assessment** (на случай если TL всё же выберет Path 2 для частичной
победы):

Engine `findOrbWindows` сейчас вызывается для **каждой** aspect/target пары через
`findContactsForTarget` (`TransitCalendar.hs:567-581`). Изменение semantics rolls
out на **все** транзиты во всех 9 golden cases (01-Sasha, 02, 03, 04, 05-Ekaterina,
07-Mariya, 08-Natalya, 09, 10-Danila). Affected aspects per case:

- **08-Natalya** (текущий case): U-V (3 windows, 3 raw hits) — narrow Marina rule
  скорее всего НЕ изменит U-V (already 1:1); N-J W1+W2 — full window остаётся
  full; N-J W3 — может быть narrowed на 17d wrong direction (engine end currently
  earlier than Marina); N-N W1+W2+W3 — W1 narrows. Чистый effect: ровно 1 window
  (N-N W1) narrows. **net: +1 test pass, -1 test pass (N-J W3 не fits)**.
- **05-Ekaterina, 07-Mariya, 09, 10-Danila**: пока без Marina reference для outer
  cards, engine output принимается «as is» через current expected.json. Любая
  semantic change потребует **regenerate всех 4 fixtures**, плюс manual sanity
  check каждого — иначе invisible regressions проползут.
- **01, 02, 03, 04**: то же — regen + sanity.

**Cost estimate.**
- Tier A. Mode strict. Worker + Reviewer subagent.
- Files: `core/astrology-hs/src/Domain/TransitCalendar.hs` (~50-150 LoC),
  `packages/contracts/solar-facts.schema.json` (если new field), Haskell roundtrip
  test, Python contract test, `outer_cards.py` (aggregation switches to new field
  if added), all 9 `expected.json` regenerated × verified, `test_natalya_transits_acceptance.py`
  unmark 2 Cat 4 (или 1 если Path 2 partial).
- ~5-10 commits.
- High risk of regression — invisible drift в других cases.

**Recommendation against Path 2** на основе § 4 finding что deterministic rule не
existуется.

### Path 3 — Accept documented exception (Tier C zero cost)

**Что меняется.**
- Test contract `_assert_three_phase_intervals` остаётся as-is.
- 2 Cat 4 Neptune tests остаются `@pytest.mark.xfail(strict=True)` с обновлённым
  reason: `"Marina narrow display window editorial choice — engine wide orb is
  semantically correct; PDF aggregates raw hits to 3 display windows per card
  (Phase 4); boundary parity with Marina not guaranteed for slow movers"`.
- Architecture document `transit-section-program-2026-05-13.md` § 6 ERRATUM block
  получает cross-reference на этот memo + явное заявление что «N-J W3 / N-N W1
  boundary divergence accepted by TL/user on YYYY-MM-DD».
- PDF продолжает рендерить engine-derived dates (через `outer_cards.aggregate_display_windows`).
- Клиентский PDF: Marina может увидеть, что её эталонные `27.09.2024` или
  `16.02.2028` boundaries не совпадают с PDF.

**Pros.**
- Zero implementation cost.
- Reality reflected — engine semantically correct, Marina editorial, нет fake
  fix.
- No regression risk на других cases.
- Cat 4 xfails становятся **permanent xfail** с явно задокументированной причиной.

**Cons.**
- «Hard acceptance assertions» discipline Phase 2 design — Cat 4 становится
  «forever xfail», что подрывает идею strict acceptance contract.
- Продуктовый минус: Marina при показе PDF может зашуметь на 2 датах из 9
  windows (~22% разрыв на boundary level).
- TASK 7 (multi-case calibration) — если выявит ещё outer-planet cases с similar
  Neptune pattern, нужно расширять Path 3 список documented exceptions.

**Acceptable только если TL/user явно принимает** что PDF может не совпадать с
Marina dates для Neptune boundaries в этих двух конкретных windows. Это
**продуктовое решение TL/user**, не technical pre-determination.

**Cost estimate.**
- Tier C, NO Worker code work.
- Update `STATUS_RU.md` + `transit-section-program-2026-05-13.md` § 6 cross-ref.
- Possibly update test xfail reason text (1 file, 4 lines).

### Path 4 — Hybrid relaxation + structured exception (новый вариант)

Не было в TASK spec, но логически следует из § 4 findings. Worker предлагает его
как **improvement над Path 1 чисто и Path 3 чисто**.

**Что меняется.**
- `_assert_three_phase_intervals` относится к **windows count + phase set**
  semantics (Path 1 partial fix).
- Per-window boundary tolerance: для каждого window — `±2d` **по умолчанию**, но
  каждый window может иметь explicit `tolerance_override` с reason.
- Add `REF_NEPTUNE_SQ_NEPTUNE` and `REF_NEPTUNE_SQ_JUPITER` per-window override:
  - N-J W3 end: tolerance `±20d` reason `"Marina extends past engine 1° orb"`.
  - N-N W1 start: tolerance `±200d` reason `"Marina shows tail only of long
    first-orb-window"`.
- 2 Cat 4 xfails flip → passing с этим more nuanced contract.

**Pros.**
- Tests pass без unmark fake — каждая override явно объяснена в коде.
- Test contract продолжает функционировать как regression guard для **остальных
  7 boundaries** (≤2d).
- Engine не трогаем — semantically correct остаётся.
- Marina divergence явно задокумента в коде, не «accepted» в abstract.

**Cons.**
- 2 hardcoded tolerance overrides в test — outliers становятся «нормой» через
  code, что подрывает single-tolerance discipline.
- Если TASK 7 multi-case calibration найдёт ещё похожие Neptune cases — список
  overrides растёт.
- Marina-vs-PDF разрыв сохраняется (как и Path 3) — Path 4 это test-side
  acceptance, не engine fix.

**Cost estimate.**
- Tier C, Worker subagent.
- ~1 файл tests, ~30-50 LoC (per-window override structure + 2 N-related
  overrides).
- 1 commit.
- Acceptance: 113 passed + 10 xfailed → 115 passed + 8 xfailed (если оба Cat 4
  flip; иначе только один).

---

## § 6. Recommendation

**Worker рекомендует Path 4** (hybrid relaxation + structured exception) как
оптимум между technical honesty и product discipline.

**Обоснование (8 предложений).**

1. § 4 hypothesis testing показал что **deterministic rule для Marina display
   boundaries не существует** на 3 примерах Натальи — H1, H2, H3 fits 1-2 из 3,
   только H4 (editorial / non-deterministic) консистентна. Это рубит Path 2 как
   feasible option независимо от cost.
2. Engine **semantically корректен**: 1.0° orb threshold per planet class — это
   принятая astrologической convention, Phase 4 aggregation в `outer_cards.py`
   уже делает Marina-style display windows. Trogать engine в Path 2 — это
   попытка подогнать «как Marina рисует», не «как реально считается аспект»,
   что нарушает invariant «engine содержит правду компьютерных фактов».
3. Path 1 в чистом виде делает test contract бесполезным regression guard —
   tolerance 200d не отлавливает ничего значимого; Path 3 в чистом виде делает
   Cat 4 «forever xfail» что подрывает Phase 2 acceptance discipline.
4. Path 4 структурно явно отделяет «common boundary parity ≤ 2d» от «known
   Marina editorial divergences» — каждый override в коде с reason явно
   объясняет почему именно этот boundary разрешено отклоняться. Это honest и
   maintainable.
5. Marina-vs-PDF разрыв на 2 windows (N-J W3 end, N-N W1 start) **сохраняется**
   в Path 3 и Path 4 одинаково — это **продуктовый** аспект, который должен
   эскалироваться TL → user отдельно («приемлемо ли что PDF на этих двух
   датах разойдётся с эталоном»). Memo НЕ предрешает этот product call.
6. Path 4 sуживает Phase 4 retroactive «9 xfail flips → 7 xfail flips» обратно
   к **9 flips** (2 Cat 4 Neptune становятся passing through structured
   override), что восстанавливает Phase 2 acceptance contract integrity.
7. Path 4 cost identical Path 1 (~1 файл, ~30-50 LoC, 1 commit, Tier C), но
   честнее: явно говорит «эти два window — known Marina editorial choices, не
   engine bugs, не test contract gaps».
8. Если TASK 7 multi-case calibration найдёт ещё похожие Neptune cases — Path 4
   расширяется per-case overrides (acceptable scale до ~10 overrides; если
   больше — пересматриваем подход). Path 3 в такой ситуации просто разрастается
   списком «accepted divergences» без структуры.

**Fallback rank:** Path 3 (zero cost, документация-only) > Path 1 (test
relaxation без exception structure) > Path 2 (engine cascade с partial
guarantees).

---

## § 7. Next TASK templates

### If TL accepts Path 4 (RECOMMENDED)

**TASK X — Phase 2 reopen: Neptune slow-loop window contract with structured
exceptions**

- Tier: C
- Mode: normal
- Layer: services/tests
- Owner: Worker subagent
- Files:
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — refactor
    `_assert_three_phase_intervals` to accept per-window tolerance override; add
    N-J W3 and N-N W1 overrides with reason strings; unmark 2 Cat 4 xfails.
  - **No** schema, fixtures, engine, or PDF code touched.
- Acceptance:
  - `test_neptune_square_jupiter_three_touches_tolerance_2d` passes (N-J W3 end
    tolerance `±20d`).
  - `test_neptune_square_neptune_three_touches_tolerance_2d` passes (N-N W1
    start tolerance `±200d`).
  - All 7 remaining boundaries continue to pass at `±2d` (5 fast + 2 slow ones
    without overrides).
  - tests total: **115 passed + 8 xfailed** (was 113/10).
  - Reviewer subagent: optional per Tier C — TL inline review acceptable.
  - Update `transit-section-program-2026-05-13.md` § 6 ERRATUM block with
    cross-reference to this memo + Path 4 acceptance.
- Estimated cost: 1 commit, ~50 LoC.

### If TL accepts Path 1 (chosen — relaxation without exceptions)

**TASK X — Phase 2 reopen: `_assert_three_phase_intervals` window-count
semantics**

- Tier: C
- Mode: normal
- Layer: services/tests
- Owner: Worker subagent
- Files:
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — switch
    from `len(hits) == 3` to `len(aggregate_display_windows(hits)) == 3`; allow
    set-of-phases per window instead of strict list; tolerance widened uniformly
    to ±200d (или explicit per-test wide tolerance).
- Acceptance:
  - 2 Cat 4 xfails → passing.
  - Test contract no longer functions as boundary regression guard for slow
    movers — acknowledged in code comment.

### If TL accepts Path 2 (NOT RECOMMENDED — engine adjustment)

**TASK X — Engine `findOrbWindows` adjustment for Marina display semantics**

- Tier: A — **Mode strict** per bright-line #8 (schema cascade).
- Layer: core + services + tests + fixtures.
- Owner: Worker subagent + Reviewer subagent (mandatory).
- Files: `core/astrology-hs/src/Domain/TransitCalendar.hs`, possibly
  `packages/contracts/solar-facts.schema.json`, Haskell roundtrip test, Python
  contract test, all 9 `expected.json` (regenerate × manual verify), test
  contract update, `outer_cards.py` (switch aggregation to new field if added).
- Acceptance:
  - Specific rule chosen by TL (warning: § 4 shows no universal rule exists).
  - Schema cascade single commit (one bright-line #8 atomic update).
  - All 9 cases verified post-regen — no invisible regressions.
  - 2 Cat 4 xfails closed OR explicitly downgraded to Path 3 documentation if
    partial fix only.
- High cost / high risk; recommend re-checking § 4 hypothesis findings before
  opening.

### If TL accepts Path 3 (chosen — documentation-only)

**TASK X — NONE (no code work).**

- Update `STATUS_RU.md` — note Phase 4a closed via Path 3.
- Update `transit-section-program-2026-05-13.md` § 6 ERRATUM block — cross-ref
  to this memo + explicit «N-J W3, N-N W1 boundary divergence accepted by
  TL/user on YYYY-MM-DD».
- Optionally update xfail reason text in
  `test_natalya_transits_acceptance.py` from `"TASK 4a — Neptune slow-loop
  contact window semantics"` to permanent reason like `"Marina narrow display
  window editorial choice — engine wide orb semantically correct; accepted
  per TL/user YYYY-MM-DD"`.

---

## Appendix A — Files inspected

- TASK: `project-overlays/astro/TASKS/2026-05-13-transit-contact-window-semantics.md`.
- Architecture: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- Archived HANDOFFs (Phase 4 preflight + Path 3 close).
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp.
  17-22 (3 outer cards).
- Engine source: `core/astrology-hs/src/Domain/TransitCalendar.hs` (lines
  232-242, 303-321, 333-404, 514-549, 567-606).
- Orb config: `packages/rulesets/daragan-orbs-v1.json`.
- Fixture: `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json`.
- Test contract: `services/api-python/tests/test_natalya_transits_acceptance.py`
  (lines 70-131, 406-496).
- Phase 4 aggregation: `services/api-python/app/pdf/outer_cards.py` (lines
  130-302).

---

## Appendix B — Tests sanity (baseline preserved)

```
cd services/api-python && .venv/bin/pytest --tb=no -q
... 113 passed, 10 xfailed in 51.99s
```

Analysis-only TASK; baseline unchanged.

---

## Erratum (2026-05-14, Phase 8B Path 1)

> **Status: ERRATUM** — appended after Phase 8B Worker B2.1 trace 2026-05-14 produced empirical evidence that one of two original Phase 4b «Marina-editorial» boundaries was **misclassified**. Original memo body above is **NOT rewritten** (historical record per audit-trail discipline); this erratum subsection documents the corrective reclassification.

### Finding

Phase 8B Worker B2.1 (TASK `2026-05-14-phase-8b-lexical-horizon-fix-unmark-xfail`) traced the engine sample-window horizon parameter to `services/api-python/app/ephemeris/bridge.py:205`:

```python
_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 540
```

Sample window for outer-planet hit aggregation: `[SR - 540d, SR + 366d + 540d]` = horizon end at `SR + 906d`.

Натальи SR = `2025-08-07 02:13 UTC` → horizon end = `2028-01-30 02:13 UTC`. This matches our **pre-fix N-J W3 end value** (`2028-01-30`) **exactly** (within 1 minute). Engine `orb_exit_jd` = `2461800.5928` = `SR + 906d`.

### Reclassification

Phase 4a hypothesis testing (§ 4 of original memo) on 3 examples (N-J W1, N-J W3, N-N W1) concluded H1/H2/H3 fit max 2 of 3 examples; only H4 (editorial) was consistent. The killer evidence cited was «N-J W3 and N-N W1 morphologically identical (D+R, similar timing offsets), but Marina draws one as 160-day full window, other as 15-day tail».

**Correct reading per Phase 8B trace:**

- **N-J W3 end (-17d Δ Marina) — TRUNCATION ARTIFACT, not editorial.** Engine `orb_exit_jd` lands exactly on `SR + 906d` (horizon boundary). Marina's `16.02.2028` is at `SR + 923d`, beyond original 540d AFTER buffer. Phase 8B horizon extension (AFTER buffer `540 → 730`, total horizon `SR + 1096d`) converges engine output to within ±2d of Marina (Worker empirical preview: `16.02.2028 10:24 UTC` vs Marina `09:00 UTC`, Δ ≈ 1.4 hours).
- **N-N W1 start (-178d Δ Marina) — TRUE EDITORIAL.** Our start at `02.04.2024` = `SR - 491d`, well within 540d BEFORE buffer (not on boundary). Engine genuinely sees orb threshold crossed at this date; Marina's `27.09.2024` is a tighter editorial visualization choice. Phase 4b ±200d structured override stays.

### What this changes

- **N-J W3 +20d structured override in `test_natalya_transits_acceptance.py` — REMOVED** as part of TASK 8B Stage B3.2 (per amendment 2026-05-14 Path 1).
- **N-N W1 +200d structured override — STAYS** unchanged.
- **Phase 4b structured-exception pattern itself stays valid** for true editorial divergences; only the specific N-J W3 entry was misapplied.
- **Phase 4a memo § 6 recommendation (Path 4 chosen)** — the conclusion about Marina editorial discretion holds for at least N-N W1 and similar future cases; Path 4 pattern remains valid programme mechanism. The Phase 4a hypothesis testing simply had one mis-classified observation.

### Why misclassified at original analysis

Phase 4a memo did NOT trace the engine sample-window parameter. The analyst assumed engine output was orb-threshold-bounded for all windows. Without tracing the horizon constant, the engine's identical pre-fix N-J W3 end / Данила-style truncation pattern looked indistinguishable from editorial choice.

**Lesson:** future analyses of «Marina-editorial» boundaries should verify that engine output is NOT pegged to a sample-window boundary before concluding editorial. Phase 8C boundary test contract + Phase 8B horizon trace are now the discipline that catches this.

### Cross-references

- TASK 8B amendment: `project-overlays/astro/TASKS/2026-05-14-phase-8b-lexical-horizon-fix-unmark-xfail.md` § B.2.5.a + § B3.2.
- Phase 8 audit report § A.2.1 SoT boundary table: `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md`.
- Calibration report § 4 TYPE reclassification (post-Phase-8B update).
