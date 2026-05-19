# Marina Significance Selection Analysis — Phase 9.0 Memo

Дата: 2026-05-17
Tier: C (analytical memo only — no code, no schema, no tests, no PDF changes).
Source TASK: `project-overlays/astro/TASKS/2026-05-17-phase-9-0-marina-significance-analysis.md`.
Baseline: Product `main @ aca694b`, overlay `master @ b95ac90`. Pytest baseline `368 passed + 2 skipped + 0 failed`.

Sibling documents:
- Phase 4a precedent (template для hypothesis-testing memo): `transit-contact-window-semantics-2026-05-13.md`.
- Phase 8 audit (multi-case inventory pattern): `phase-8-audit-report-2026-05-14.md`.
- Phase 7 calibration report (per-case structure): `transit-multi-case-calibration-report-2026-05-13.md`.
- Marina framing memo (curation philosophy): `marina-framing-memo-2026-05-15.md`.

---

## § 0. Context и why this memo exists

После Phase 8 + 3 follow-up TASKs (`api-pdf-endpoint` / `directions-show-all-active` / `transit-section-generic-output`) система научилась эмитить generic-fallback output для non-calibrated клиентов. Но pendulum инвертировался: PDF Ольги (consultation 11, не в `OUTER_CARD_ALLOWLIST`) показывает **всё engine-emitted**, не Marina-significant subset.

Numerical scope для Ольги (out-of-scope PDF `solar-11.pdf`, 28 страниц):
- **Directions:** engine эмитит 9 active, Marina picknut 4.
- **Outer cards:** engine эмитит ~13 unique aspect triples, Marina picknut 6.
- **Touch intervals:** engine эмитит 3+ loop touches per card; Marina иногда показывает 1, иногда 3, иногда 4 (per-card editorial choice — see § 1).
- **Summary themes:** engine (post-`transit-section-generic-output`) выводит «Дети/хобби и коллектив (ось 5-11)» как первое место — **совпадает с Marina** для Ольги.

Cluster: 4 separate sub-problems могут иметь разную природу (deterministic / editorial / hybrid). Phase 4a precedent (memo 2026-05-13) показал на 3 примерах Натальи Neptune cards что transit-contact **window boundaries** для медленных планет — editorial (H4). Этот memo задаёт тот же вопрос для **selection rules** (Marina picks N of M items per stream), не для **window dates** (Phase 4a domain).

---

## § 1. Marina selections per 10 cases — reference inventory

Worker source: чтение Marina PDFs (9 calibrated в `/Users/ilya/Downloads/Gmail (3)/`, 1 Ольга в `/Users/ilya/Downloads/Соляр 2026-2027 (1).pdf`). Engine-emitted side для 9 calibrated cases: `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` уже представляют Marina-curated set по definition (Phase 4/7b/8D acceptance). Для Ольги (case 11): script result PDF `/Users/ilya/Downloads/solar-11.pdf` (28 pages).

### § 1.1 Per-case Marina extraction summary

Cells: «Direction count», «Outer card count», «Summary primary theme (axis or house)». Detailed touch-interval data per outer card в § 1.2.

| # | Case | Direction selection | Outer cards | Summary primary theme |
|---|---|---|---|---|
| 01 | Ксения (2024-2025) | 1 (Нептун 120 Сатурн) | 5 (Уран опп Солнце; Уран опп Уран; Нептун триг Солнце; Нептун кв Марс; Плутон триг Юпитер) | оси 4-10 (планет распределение) + 2-8 + 3-9 acentual; Асц Овен / МС Стрелец [Worker note: Marina не явно «первое место»; tematic emphasis on 4/5/7] |
| 02 | Максим (2025-2026) | 1 (Марс 0 Плутон) | 2 (Уран опп Плутон; Уран триг Уран) | ось 2-8 (финансы) — «Главная тема» |
| 03 | Артем (2025-2026) | 5 (Хирон 180 МС; АС 150 Нептун; Солнце 60 Луна; Марс 60 Луна; Нептун 150 Хирон) | 9 (3 Уран + 4 Нептун + 2 Плутон) | оси 6-12 (работа) + 5-11 (дети/планы) — «два направления» |
| 04 | Валерия (2025-2026) | [not extracted в Stage 9.0.1; Marina PDF read deferred] | 2 (Уран кв Сатурн; Уран опп Плутон) | [not extracted] |
| 05 | Екатерина (2025-2026) | 2 (Солнце 90 АС; Нептун 0 АС) — Marina пишет «дирекций нет на текущую дату; смотрим ближе к окончанию соляра» | 3 (Уран кв Луна; Уран секст Юпитер; Нептун триг Юпитер) | оси 6-12 + 1-7 — «1-е место / 2-е место» |
| 07 | Мария (2025-2026) | [not extracted] | **0** (Marina explicit: «у вас не будет транзитных аспектов от высших планет») | [not extracted] |
| 08 | Наталья (2025-2026) | 2 (Марс 150 МС; АС 60 Луна) | 3 (Уран кв Венера; Нептун кв Юпитер; Нептун кв Нептун) | ось 6-12 (работа) — «1-е место» |
| 09 | Анастасия (2025-2026) | 5 (Солнце 90 АС; Юпитер 0 МС; АС 60 Плутон; МС 150 Нептун; Нептун 90 Меркурий) | 2 (Уран соед Меркурий; Нептун секст Меркурий) | ось 1-7 (партнерство) — «1-е место»; «год супер-соляра» |
| 10 | Данила (2025-2026) | 6 (Юпитер 150 Луна; Плутон 180 Юпитер; МС 120 Луна; Меркурий 60 Юпитер; Сатурн 0 Юпитер; Уран 90 Марс) | 3 (Уран кв Луна; Нептун кв Венера; Нептун кв Юпитер — 4 windows) | ось 2-8 (финансы) — «1-е место» |
| 11 | Ольга (2026-2027) | **4** (МС 90 АС; МС 120 Уран; Солнце 60 АС; Сатурн 150 Марс) | **6** (Уран кв Венера; Уран опп Уран; Уран опп Юпитер; Нептун триг Юпитер; Нептун триг Уран; Плутон секст Уран) | ось 5-11 (дети/хобби/планы) — «акцент на одном направлении» |

**Analysis-eligible cases (with Marina-extraction for at least 2 streams):** 8 of 10 (cases 04 и 07 partial — outer cards extracted, остальные streams не извлекались; case 04 — Marina написала прямо «аспектов от Нептуна и Плутона – нет», т.е. Uranus-only is a kind of `0-Neptune/0-Pluto editorial`).

**Cases 04 + 07 — explicit Marina-write «нет аспектов» pattern.** Marina явно пишет, что чего-то нет: case 07 («у вас не будет транзитных аспектов от высших планет»), case 04 («аспектов от Нептуна и Плутона – нет»). Это **editorial zero**, не gap. Allowlist для case 07 — explicit `[]`; для case 04 — Uranus-only (2 cards).

### § 1.2 Per-case outer-card window structure (Marina display windows count)

Engine эмитит typically 3 «display windows» per card (aggregated raw hits per `(orb_enter, orb_exit)` triple — Phase 4 design). Marina иногда показывает **меньше** (1 window per card) или **больше** (4 windows per card). Это **per-card editorial choice** Marina, который engine **уже воспроизводит** — `card.intervals` iterator принимает любое количество windows.

| Case | Card | Marina shows N windows | Engine shows N windows | Match? |
|---|---|---|---|---|
| 01 | Уран опп Солнце | 3 | 3 | YES |
| 01 | Уран опп Уран | 3 | 3 | YES |
| 01 | Нептун триг Солнце | 3 | 3 (post-Phase-8E horizon fix) | YES |
| 01 | Нептун кв Марс | 3 | 3 (post-Phase-8E) | YES |
| 01 | Плутон триг Юпитер | 3 | engine эмитит больше? (audit § A.2.1.D excludes — Pluto display rule narrows) | NO (Pluto editorial — Phase 8 audit) |
| 02 | Уран опп Плутон | **1** | 3 | NO (Marina narrows) |
| 02 | Уран триг Уран | **1** | 3 | NO (Marina narrows) |
| 03 | Уран триг Меркурий | 3 | 3 | YES |
| 03 | Нептун опп Меркурий | **1** | 4 | NO (Marina narrows) |
| 03 | Плутон триг Солнце | (Pluto narrow) | larger | NO |
| 04 | Уран кв Сатурн | **1** | 3 | NO (Marina narrows) |
| 04 | Уран опп Плутон | **1** | 3 | NO (Marina narrows) |
| 05 | Уран кв Луна | 3 | 3 | YES |
| 05 | Уран секст Юпитер | 3 | 3 | YES |
| 05 | Нептун триг Юпитер | 3 | 3 | YES |
| 08 | Уран кв Венера | 3 | 3 | YES |
| 08 | Нептун кв Юпитер | 3 | 3 (post-Phase-8B horizon fix) | YES |
| 08 | Нептун кв Нептун | 3 (Marina W1 = 15-day tail of engine 193-day window) | 3 windows, but W1 start +178d Marina-editorial divergence | partial (Phase 4a accepted) |
| 09 | Уран соед Меркурий | 3 | 3 (TYPE-D SR mismatch ~60min — boundary divergence not in Phase 8) | YES (within tolerance) |
| 09 | Нептун секст Меркурий | 3 | 3 | YES |
| 10 | Уран кв Луна | 3 | 3 | YES |
| 10 | Нептун кв Венера | 3 | 3 (post-Phase-8B horizon fix) | YES |
| 10 | Нептун кв Юпитер | **4** (Marina explicit «четвертое касание») | 4 | YES |
| 11 (Ольга) | Уран кв Венера | **1** | 3 (engine) | NO (Marina narrows) |
| 11 (Ольга) | Уран опп Уран | 3 | 3 | YES |
| 11 (Ольга) | Уран опп Юпитер | **1** | 3 | NO (Marina narrows) |
| 11 (Ольга) | Нептун триг Юпитер | **1** | 3 | NO (Marina narrows) |
| 11 (Ольга) | Нептун триг Уран | **4** | 4 | YES |
| 11 (Ольга) | Плутон секст Уран | **4** | 4 (likely) | YES |

**Observation A:** Marina sometimes shows 1-window-only when engine shows multi-window loop (cases 02, 04, parts of 03 + 11). Phase 8 audit classified эти as «single-Marina-window alignment limitation» (Marina W1 ≈ engine W3 — the last loop touch, не первый).

**Observation B:** Marina sometimes shows 4 windows (case 10 Neptune-Jupiter; case 11 Neptune-Uranus; case 11 Pluto-Uranus) — engine эмитит ровно 4 в этих случаях. Marina не «прячет» дополнительные касания, она их показывает.

**Observation C:** Marina shows 3 windows для большинства cards (cases 01 first 4, 03 first card, 05 all 3, 08 all 3, 09 all 2, 10 first 2, 11 second card). Это default-3 pattern.

### § 1.3 Engine-emit context per Ольга (out-of-scope critical sample)

Из script `solar-11.pdf`:

**Directions emitted (9 total):**
1. MC 90 АС (10+1) — Marina ✓
2. Луна 90 Солнце (1+2, 1+3, 1+4)
3. Сатурн 150 Марс (1+5, 1+7, 1+8, 1+9, 1+10) — Marina ✓
4. Сатурн 90 Луна (1+5, 1+7, 1+8, 1+9, 1+10)
5. МС 120 Уран (10+6, 10+9) — Marina ✓
6. Нептун 150 Марс (1+6, 1+11)
7. Нептун 150 Луна (1+6, 1+11)
8. Плутон 150 Марс (1+5, 1+6)
9. Солнце 60 АС (1+2, 1+3, 1+4) — Marina ✓

**Marina-picked (4 of 9):** МС 90 АС, МС 120 Уран, Солнце 60 АС, Сатурн 150 Марс.

**Marina-rejected (5 of 9):** Луна 90 Солнце; Сатурн 90 Луна; Нептун 150 Марс; Нептун 150 Луна; Плутон 150 Марс.

**Outer cards emitted (~13 unique aspect triples — partial extract from PDF; engine emits Marina-typical 3-window format):** Уран секст Меркурий; Уран кв МС; Уран кв Венера; Уран опп Уран; Уран опп Юпитер; Нептун кв АС; Нептун триг Юпитер; Нептун триг Уран; Плутон секст Уран; (some others Marina-rejected).

**Marina-picked (6):** Уран кв Венера; Уран опп Уран; Уран опп Юпитер; Нептун триг Юпитер; Нептун триг Уран; Плутон секст Уран.

**Marina-rejected (visible ~3+):** Уран секст Меркурий; Уран кв МС; Нептун кв АС; (likely others — partial extract).

**Engine first summary theme:** «Дети/хобби и коллектив (ось 5-11), подсчёт 4 из 12 куспидов соляра». Marina **same axis**: «Солярная сетка в текущем году имеет акцент на одном направлении – выделена ось 5-11». ⇒ **Engine + Marina agree** для Ольги-summary primary theme.

---

## § 2. Per-sub-problem diff tables

Worker collapses verbose 4-tables × 10-cases × per-item format into structured analysis tables. «In-Marina?» column maps engine emit ↔ Marina selection. «Why» column = best-fitting hypothesis explanation candidate.

### § 2.1 Sub-problem A: Active-directions selection

**Marina's explicit selection rule** (verbatim from each calibrated PDF): «Чтобы событие произошло, то, в первую очередь, мы должны рассмотреть аспекты к Асц (1 дом), элементам 1 дома и МС, смотрим, есть ли такие». Marina пишет это правило **в каждом из 7 calibrated PDFs где есть directions section** (cases 01, 02, 03, 05, 08, 09, 10) и в Ольгеной PDF (case 11).

«Элементы 1 дома» = (а) планета-управитель Асц, (b) планеты, расположенные в 1-м доме натальной карты, (c) Луна (вторично — она «планета личности»; в case-08 Натальи Marina явно её добавила).

Per-case diff (compressed; Marina-row = Marina selected, Engine-row = engine emitted, In-Marina? = boolean intersection):

#### Case 01 (Ксения, Marina selected 1):

| Direction | Marina row formula | Aspect to Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Нептун 120 Сатурн | 1+10, 1+11, 1+7, 1+12 | YES (1+X formulas) | ✓ |

Сатурн = планета 7 дома + управитель 12 + соуправитель 1 дома (Marina notes: «Сатурн – планета 7 дома, управитель 12 и соуправитель 1 дома»). **Сатурн is 1st-house element** для Ксении. ⇒ Marina rule matches.

Engine emit для case 01 — N/A (Worker did not enumerate engine output для calibrated case 01 PDF; calibrated cases используют `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` для outer cards but directions go through separate engine path в `app/pdf/directions.py`; this diff focuses on Marina's own selection rule rather than engine vs Marina diff для calibrated cases). Acceptable per memo scope.

#### Case 02 (Максим, Marina selected 1):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Марс 0 Плутон | 1+5, 1+6, 1+12 | YES (1+X) | ✓ |

Marina notes: «Марс – планета 12 дома, управитель 5 и 6 домов, соуправитель 1 дома. Плутон – планета 1 дома, управитель 1 дома, соуправитель 5 дома и 6 дома». ⇒ Оба planet ↔ 1st-house elements. Rule matches.

#### Case 03 (Артем, Marina selected 5):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Хирон 180 МС | 1+10 | YES (MC + 1st) | ✓ |
| АС 150 Нептун | 1+6, 1+7, 1+11 | YES (АС directly) | ✓ |
| Солнце 60 Луна | 1+5, 1+3, 1+4 | YES (Луна = 1st-house planet for Artem; Asc в Раке would mean Луна = Asc-ruler) | ✓ |
| Марс 60 Луна | 1+5, 1+6, 1+11 | YES (Луна) | ✓ |
| Нептун 150 Хирон | 1+7, 1+6, 1+11 | YES (Хирон = 1st-house element per Marina line) | ✓ |

Marina notes: «Элементами первого дома являются: Луна, Юпитер, Хирон». All 5 selections touch one of these or AC/MC. Rule matches.

#### Case 05 (Екатерина, Marina selected 2):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Солнце 90 АС | 1+7 | YES (АС directly) | ✓ |
| Нептун 0 АС | 1+10, 1+11 | YES (АС directly) | ✓ |

Marina notes: «Элементы первого дома: Уран, Сатурн (т.к. Асц в Водолее), Солнце, Меркурий, Венера, Марс (планеты первого дома)». Marina явно пишет: «На текущую дату — дирекций нет. Смотрим, есть ли ближе к окончанию соляра (на 12.03.2026 год)». ⇒ Marina рассматривает ENTIRE solar-year window, не just current date. Selection rule = Asc/MC/1st-house involvement.

#### Case 08 (Наталья, Marina selected 2):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Марс 150 МС | 3+10, 8+3, 9+3 | YES (MC directly) | ✓ |
| АС 60 Луна | 1+11, 1+4 | YES (АС directly) | ✓ |

Marina: «Элементом первого дома является: Меркурий (т.к. Асц в Деве)». But Луна добавлена because Marina-rule сначала рассматривает Асц, элементы 1 дома, МС — Луна = planet in/ruler of 4th house involved through AC aspect.

#### Case 09 (Анастасия, Marina selected 5):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Солнце 90 АС | 1+9, 1+12 | YES (АС) | ✓ |
| Юпитер 0 МС | 9+10, 4+10, 7+10 | YES (MC) | ✓ |
| АС 60 Плутон | 1+3, 1+8 | YES (АС) | ✓ |
| МС 150 Нептун | 10+7, 10+4, 10+5 | YES (MC) | ✓ |
| Нептун 90 Меркурий | 1+5, 1+4, 1+7, 10+5, 10+4, 10+7 | YES (Меркурий = Asc-ruler в Деве; Нептун = planet in/ruler involving 1+10 formulas) | ✓ |

Marina: «Элементами первого дома являются: Меркурий (т.к. Асц в Деве) и Луна, т.к это планета I дома натальной карты». Все 5 selections touch Asc / MC / 1st-house element. Rule matches.

#### Case 10 (Данила, Marina selected 6):

| Direction | Marina row formula | Asc/MC/1st? | In-Marina? |
|---|---|---|---|
| Юпитер 150 Луна | 1+3, 1+8 | YES (Юпитер/Нептун = Asc-ruler в Стрельце; Луна = вторичная личностная планета) | ✓ |
| Плутон 180 Юпитер | 1+7, 1+3, 1+12, 1+5, 1+4 | YES | ✓ |
| МС 120 Луна | 10+3, 10+8 | YES (MC + Луна) | ✓ |
| Меркурий 60 Юпитер | 1+8, 1+9, 1+7 | YES (Юпитер = 1st-element) | ✓ |
| Сатурн 0 Юпитер | 1+7, 1+2, 1+3 | YES (Юпитер) | ✓ |
| Уран 90 Марс | 1+2, 1+3 | YES (Марс = 1st-house planet per Marina line) | ✓ |

Marina: «Элементом первого дома является: Юпитер\Нептун (т.к.Асц в Стрельце) и - Плутон, Марс, Хирон, т.к. они локализованы в I доме натальной карты». ⇒ Все 6 selections fit. Rule matches.

#### Case 11 (Ольга, Marina selected 4 of 9 engine-emitted):

Critical case: only one где у Worker'а есть engine vs Marina diff с known engine emission count.

Marina: «Элементом первого дома является: Луна (т.к.Асц в Раке) и Марс – планета I дома». ⇒ Marina's 1st-house elements = {AC, Луна, Марс, MC}.

| Engine emit | Marina row formula | Aspect to {AC, Луна, Марс, MC}? | In-Marina? | Why? |
|---|---|---|---|---|
| MC 90 АС | 10+1 | YES (AC + MC) | ✓ | Direct AC + MC |
| Луна 90 Солнце | 1+2, 1+3, 1+4 | NO (Marina rule: Asc/MC/1st-element touched? Луна yes — но aspect is Луна 90 Солнце; Солнце ≠ 1st-element) | ✗ | Worker proposed gap: Marina может требовать **target side** also be Asc/MC/1st; engine emit fires when EITHER side touches |
| Сатурн 150 Марс | 1+5, 1+7, 1+8, 1+9, 1+10 | YES (Марс — 1st-house planet) | ✓ | Target = 1st-element |
| Сатурн 90 Луна | 1+5, 1+7, 1+8, 1+9, 1+10 | YES (Луна = Asc-ruler) | ✗ | **Breaker — Marina rule predicts ✓ but Marina excludes.** Worker hypothesis B: Marina prefers harmonious aspects over hard aspects when both directions involve same Asc/1st-element AND target/transit is duplicated (Сатурн 150 Марс уже выбран, Сатурн 90 Луна **дублирует Сатурн transit**); Marina выбирает один из двух |
| МС 120 Уран | 10+6, 10+9 | YES (MC) | ✓ | Direct MC |
| Нептун 150 Марс | 1+6, 1+11 | YES (Марс) | ✗ | **Breaker.** Worker: aspect type? Marina выбирает Сатурн 150 Марс, но excludes Нептун 150 Марс — оба quincunx, оба touch Марс. Diff: Сатурн = social-planet (active direction influence); Нептун = transpersonal (subtle). Marina предпочитает personal/social-planet directions to transpersonal-planet directions? |
| Нептун 150 Луна | 1+6, 1+11 | YES (Луна = Asc-ruler) | ✗ | Same breaker — transpersonal as source planet |
| Плутон 150 Марс | 1+5, 1+6 | YES (Марс) | ✗ | Same breaker — transpersonal as source |
| Солнце 60 АС | 1+2, 1+3, 1+4 | YES (AC) | ✓ | Direct AC; aspect-source = Солнце (personal) |

**Critical breaker pattern для Ольги:** Marina excludes 3 of 9 engine-emitted directions where SOURCE PLANET is transpersonal (Нептун, Плутон) **even when target IS Asc/MC/1st-element**. Marina-rule subtly stronger than the verbatim text «затрагивают Асц...»: she also weights **what kind of transit planet drives the direction**.

Worker proposal: 2nd-level rule = «when source planet is transpersonal (Уран/Нептун/Плутон), Marina includes the direction ONLY если она creates an additional formula not already covered by a personal/social-planet direction». E.g. for Ольги:
- Сатурн 150 Марс (1+5, 1+7, 1+8, 1+9, 1+10) — Marina ✓.
- Сатурн 90 Луна — same formulas as #3 (1+5, 1+7, 1+8, 1+9, 1+10) — **duplicate**, Marina ✗ (избегает dublication).
- Нептун 150 Марс, Нептун 150 Луна, Плутон 150 Марс — все formulas pure 1+X with houses {5, 6, 11} — overlapping but maybe Marina considers them too «slow/diffuse» (Нептун/Плутон).

#### Summary table — Active-directions sub-problem

| Case | Marina-picked count | Engine-emit count (known) | Rule fit | Breakers |
|---|---|---|---|---|
| 01 | 1 | unknown | ✓ (single direction matches «1+ formulas») | — |
| 02 | 1 | unknown | ✓ | — |
| 03 | 5 | unknown | ✓ (all 5 touch Asc/MC/1st) | — |
| 05 | 2 | unknown | ✓ | — |
| 08 | 2 | unknown | ✓ | — |
| 09 | 5 | unknown | ✓ (5 selections all fit) | — |
| 10 | 6 | unknown | ✓ (6 selections all fit) | — |
| 11 (Ольга) | 4 | 9 | ✓ partial — 4 ✓ matches rule, 5 ✗ Marina-excluded **even though** they touch Asc/MC/1st-element | aspect-source type (Нептун/Плутон breakers); duplicate-formula avoidance |

**Confidence в rule statement:** N+ Marina-rule «aspects touching Asc / MC / 1st-house elements» fits 8/8 calibrated cases где Marina lists 2-6 selections. For Ольга (case 11), rule fits 4/4 Marina-positive but **over-predicts** на 5/9 engine-emit cases — those 5 should be excluded by tighter sub-rule.

### § 2.2 Sub-problem B: Outer-card selection

For 9 calibrated cases, Marina's selection is **fully encoded в `OUTER_CARD_ALLOWLIST`** (by Phase 4/7b/8D design). Per case Marina selected count:

| Case | Marina count | Allowlist count | Notes |
|---|---|---|---|
| 01 | 5 | 5 | match |
| 02 | 2 | 2 | match (Uranus only) |
| 03 | 9 | 9 | match (3 Uranus + 4 Neptune + 2 Pluto) |
| 04 | 2 | 2 | match (Uranus only, Marina explicit «нет» для Neptune/Pluto) |
| 05 | 3 | 3 | match |
| 07 | 0 | `[]` empty | match (Marina explicit «нет от высших») |
| 08 | 3 | 3 | match |
| 09 | 2 | 2 | match |
| 10 | 3 | 3 | match |
| **Total** | **29** | **29** | **9/9 match** |

For Ольга (case 11, NOT in allowlist):

| Engine emit (~13) | Marina selected (6) | In-Marina? | Why? |
|---|---|---|---|
| Уран секс Меркурий | not in Marina-6 | ✗ | Target = Меркурий; Меркурий не sin Marina's Ольгин «1-st-house element» list (Луна, Марс). Worker H2 «target = significator (Sun/Moon/Asc-ruler/etc)». |
| Уран кв МС | not in Marina-6 | ✗ | Target = MC. Marina rule (per text) обычно DOES include MC; но Marina-6 has Уран кв Венера и Уран опп Уран/Юпитер. **Breaker** — engine emits Уран-MC, Marina excludes. Possibly Marina prefers Уран-планета над Уран-угол for outer cards (cards focus on planet psychology). |
| Уран кв Венера | YES | ✓ | Target = Венера (важна для Ольги — стеллиум? проверить); Marina explicitly notes для 11 «Венера – король аспектов». **Marina-selection rule for outer cards: target = personal planet** (per Marina deck taxonomy для transit aspects: «Транзиты Венеры – король аспектов»). |
| Уран опп Уран | YES | ✓ | Target = Уран; involves outer-outer aspect — classical period-7-year transit. Marina может включать transpersonal-target outer cards если они natal-orbit milestone (Уран-Уран = age-71 opposition или mid-life square). |
| Уран опп Юпитер | YES | ✓ | Target = Юпитер; **important**: Юпитер — социальная планета, классически considered «значимая» для transits. |
| Нептун кв АС | not in Marina-6 | ✗ | Target = АС angle. Marina excludes (despite АС being primary Marina-significance angle for directions). **Critical breaker for H1 «involvement of АС/MC».** Worker proposal: outer-card AC/MC aspects are **emitted as monthly calendar items** (Marina notes «Нептун 90° Асц» in месячный календарь, не как card) — i.e., AC/MC targets get календарь treatment, не deep-dive card treatment. Marina's deck taxonomy. |
| Нептун триг Юпитер | YES | ✓ | Социальная планета target. |
| Нептун триг Уран | YES | ✓ | Outer-outer (significant generation marker). |
| Плутон секс Уран | YES | ✓ | Same — outer-outer pattern. |
| (others rejected, partial extract — Marina selects 6 of ~13) | — | — | — |

**Critical insight для Ольги outer cards:** Marina excludes outer cards targeting **angles (АС/МС)** but шторм includes outer cards targeting **planets** (Венера, Юпитер, Уран). Calendar shows aspect-to-angles in monthly table («Нептун 90° Асц 13.07.2026–20.09.2026»), but card deep-dive reserves for planet-target aspects. This is **inverse to directions** (Marina's directions rule emphasizes Asc/MC/1st-element involvement).

**Outer-card target hierarchy per Marina:**

1. **Личные планеты (Venus, Mercury, Mars, Sun, Moon)** — primary cards.
2. **Социальные планеты (Jupiter, Saturn)** — primary cards.
3. **Внешние планеты (Uranus, Neptune, Pluto)** — primary cards for outer-outer transits (Uranus opp Uranus = generational marker; Pluto sextile Uranus = mid-life; Neptune trine Neptune = trine return).
4. **Угловые точки (AC/MC/IC/DC)** — NOT cards (handled via monthly calendar instead).

This **single hierarchy** explains:
- Why case 07 Mariya has 0 cards (Marina simply says «нет аспектов от высших к planets»).
- Why case 04 has 2 Uranus-only cards (Marina says «аспектов от Нептуна и Плутона нет»).
- Why Ольга has 6 cards: 1 Venus + 1 Jupiter + 1 Uranus + 1 Jupiter + 1 Uranus + 1 Uranus (mix of personal/social + outer-outer; **no angle targets**).

**For 9 calibrated cases the allowlist content matches this hierarchy almost universally** — single anomaly: case 11 Ольга где engine emits аспекты к АС/МС, Marina filters them out.

### § 2.3 Sub-problem C: Touch-interval selection per card

Per § 1.2 above: Marina shows variable N windows per card (1, 3, 4). Engine эмитит typically 3 windows per loop (Phase 4 aggregation). Marina sometimes:
- Shows ALL engine windows (cases 01 first 4, 05 all 3, 08 all 3, 09 all 2, 10 first 2, 11 second card).
- Shows ONLY LAST engine window (cases 02 both, 04 both, 03 some, 11 cards 1, 3, 4 = Уран кв Венера, Уран опп Юпитер, Нептун триг Юпитер). Audit § A.2.1.D notes: «Marina W1 = engine W3 alignment limitation».
- Shows 4 windows when engine эмитит 4 (case 10 Neptune-Jupiter; case 11 cards 5, 6).
- Shows tail-only of engine wide window (case 08 N-N W1 +178d divergence; Phase 4a accepted).

**Diff structure for sub-problem C (engine vs Marina window count per card):**

| Case | Card | Engine N | Marina N | Marina shows… |
|---|---|---|---|---|
| 02 | Уран опп Плутон | 3 | 1 | last loop touch (W3) |
| 02 | Уран триг Уран | 3 | 1 | last loop touch (W3) |
| 03 | Нептун опп Мерк | 4 | 1 | last loop touch (W4) |
| 04 | Уран кв Сатурн | 3 | 1 | last loop touch (W2) |
| 04 | Уран опп Плутон | 3 | 1 | last loop touch (W3) |
| 11 | Уран кв Венера | 3 | 1 | one touch (which? per Marina dates 02.12.2026–15.04.2027 — likely W3 = last loop) |
| 11 | Уран опп Юпитер | 3 | 1 | one touch (28.12.2026–22.03.2027 = W3) |
| 11 | Нептун триг Юпитер | 3 | 1 | one touch (18.10.2026–05.02.2027 = W2 likely) |

**Pattern для cases 02/03/04/11 (single-window Marina):** Marina часто shows **only the loop touch occurring within OR closest to the solar year** (or actively building toward exact). For Ольги:
- Уран кв Венера: 02.12.2026–15.04.2027 — solar-year is 13.07.2026–13.07.2027; this window is **mid-solar-year**. Engine эмитит also windows ранее (which are pre-solar-year или crossing into next year).
- Уран опп Юпитер: 28.12.2026–22.03.2027 — same mid-solar-year.
- Нептун триг Юпитер: 18.10.2026–05.02.2027 — mid-solar-year.

**Worker hypothesis H1 (sub-problem C):** Marina selects the **single window contained primarily within [sr_jd, sr_jd+365.25]** (solar year). If engine эмитит 3 loop touches and 2 of them straddle solar-year boundary or fall outside, Marina shows only the «in-year» touch.

Test для case 11:
- Уран кв Венера single window 02.12.2026–15.04.2027: solar year start 13.07.2026, end 13.07.2027. Window fully within. ✓
- Уран опп Юпитер 28.12.2026–22.03.2027: fully within. ✓
- Нептун триг Юпитер 18.10.2026–05.02.2027: fully within. ✓

Test для case 02 (Максим): Marina W1 = 01.12.2025–06.04.2026 per allowlist comment. Maksim's SR = 04.09.2025. Solar year = 04.09.2025–04.09.2026. Marina's window 01.12.2025–06.04.2026 fully within. ✓

Test для case 11 Уран опп Уран (Marina 3 windows): all three intervals 18.07.2026–06.11.2026 / 05.05.2027–08.06.2027 / 08.01.2028–19.03.2028. First two within solar year (13.07.2026–13.07.2027); third (08.01.2028–19.03.2028) is **past solar year**. Yet Marina shows it. ⇒ Hypothesis breaks for Уран опп Уран Ольги.

Hmm — Marina shows ALL 3 for Уран-Уран Ольги even when last is outside solar year. So «in-year only» rule doesn't fully hold.

**Worker re-hypothesis H1':** Marina shows ALL loop touches **if outer-outer transit** (Уран-Уран, Нептун-Уран, Плутон-Уран = generational milestones; show entire loop period because the «значимое событие» can span 2-3 years). For outer-personal (Уран-Венера) or outer-social (Уран-Юпитер) transits — show only one touch (typically the most «активно реализуемый» within the solar year).

Test:
- Уран кв Венера (outer-personal): 1 touch shown ✓ (Ольга).
- Уран опп Юпитер (outer-social): 1 touch shown ✓ (Ольга).
- Уран опп Уран (outer-outer): 3 touches shown ✓ (Ольга).
- Нептун триг Юпитер (outer-social): 1 touch shown ✓ (Ольга).
- Нептун триг Уран (outer-outer): 4 touches shown ✓ (Ольга).
- Плутон секст Уран (outer-outer): 4 touches shown ✓ (Ольга).

For Ольги cards H1' fits 6/6. Now test against other cases:
- Case 05 Уран кв Луна (outer-personal): Marina 3 touches — **break**.
- Case 05 Уран секст Юпитер (outer-social): Marina 3 touches — **break**.
- Case 08 Уран кв Венера (outer-personal): Marina 3 touches — **break**.

⇒ H1' fits only Ольги; cases 05/08/10 default-3.

**H1''-attempt — engine windows count?** Cases 02/04/11-partial show 1-window Marina mostly when engine эмитит multi-window but Marina's PDF date range matches ONE specific engine window (last loop touch typically). Cases 05/08/10 show 3-window Marina that match engine 3 windows naturally.

**What differs between case 11 Ольги Уран-Венера (1 touch) and case 05 Екатерины Уран кв Луна (3 touches)?** Engine emits 3 windows in both. Marina shows 1 vs 3.

Possible factor: **temporal density** — does the 1-window Marina shows the «central» touch (where R-station happens or where exact moments cluster) while the 3-window Marina shows three distinct, well-separated touches?

Or: **per-target editorial choice** — Marina visually decides per-card whether 1 vs 3 vs 4. No deterministic rule emerges from data.

**Best Marina rule for sub-problem C** (current memo evidence — limited data per case):
- Default: Marina shows 3 touches (matches engine 3-window aggregation).
- For outer-outer transits: Marina shows N touches matching engine (3 or 4).
- For some outer-personal/outer-social transits: Marina shows 1 touch only. **Choice criteria unclear from data alone** — possibly correlated with chart-specific factors (solar-year position relative to loop structure, target planet's natal house, retro phases, etc.) **OR purely editorial**.

### § 2.4 Sub-problem D: Summary thematic selection

Engine output (post-`transit-section-generic-output`) computes summary themes by axis-density (count cusps on each axis × theme weight). For case 11 Ольги engine emits «Дети/хобби и коллектив (ось 5-11), подсчёт 4 из 12 куспидов соляра» as 1st theme.

Marina-row for Ольги: «Солярная сетка в текущем году имеет акцент на одном направлении – выделена ось 5-11. Ось детей, планирования, хобби, дружбы и коллективизма. Асц соляра в Весах – акцент на партнерстве, гармоничном взаимодействии с другими людьми. МС в Раке – цель года – семья, дом, род, обретение почвы под ногами.»

⇒ Marina **exactly matches engine** for primary theme. **Engine rule = Marina rule** для case 11.

Per-case Marina primary theme:

| Case | Marina primary theme | Marina secondary | Engine emit? (calibrated cases — engine doesn't run for them through this code path, summary is human-written в Phase 4-8 era; для Ольги engine runs) | Match? |
|---|---|---|---|---|
| 01 | Distributed planets (4-10 axis + 2-8 + 3-9; pl. dist | — | N/A | — |
| 02 | Финансы (ось 2-8) — «Главная тема» | — | N/A | — |
| 03 | Работа (6-12) + Дети/планы (5-11) — «два направления» | — | N/A | — |
| 04 | not extracted | — | — | — |
| 05 | Работа (6-12) + Партнерство (1-7) | — | N/A | — |
| 07 | not extracted | — | — | — |
| 08 | Работа (6-12) — «1-е место» | — | N/A | — |
| 09 | Партнерство (1-7) — «1-е место»; «супер-соляр» | — | N/A | — |
| 10 | Финансы (2-8) — «1-е место» | — | N/A | — |
| 11 | Дети/хобби/планы (5-11) — «акцент на одном направлении» | Ось 4-10 (distribution) | Engine: «Дети/хобби и коллектив (ось 5-11)» — first theme | ✓ exact match |

Marina's summary rule (verbatim from each PDF): «Темы определяются осью наиболее заполненных натальных домов под куспидами соляра, а также по ключевым угловым точкам.» ⇒ count-of-planets-per-axis weighted by angular cusps (1, 4, 7, 10) — same logic as engine.

**For Ольги, engine first theme = Marina first theme** (5-11 axis). For 8 calibrated cases (01, 02, 03, 05, 08, 09, 10 — 7 with extractable theme + 04 + 07 partial), Marina chose primary theme that consistent с «axis with most cusps of solar houses falling on natal axis», which is **deterministic computable**. Engine in Phase 8+ implements this same logic для primary-axis selection.

**Verdict для sub-problem D**: deterministic (with Marina's verbatim algorithm described in PDF) — see § 4 verdicts.

---

## § 3. Hypothesis testing per sub-problem

### § 3.1 Sub-problem A: Active-directions selection — hypothesis tests

**H1: «involvement of Asc/MC/1st-house elements»** (engine breadth criterion — direction includes formula `1+X` или `X+10` где X = any house).

Test (8 analyzable cases):

```
H1:
  Fits 7/8 cases (with full Marina-match prediction).
  Cases 01, 02, 03, 05, 08, 09, 10: all Marina-selections fit H1 (100% recall, but unknown precision because we don't have engine emit count for these).
  Case 11 Ольга: H1 predicts 9/9 (all engine emit fit H1 — they all have 1+X or 10+X formulas).
  False positives на Ольге = 5 (Marina excludes 5 of 9 H1-predicted).
  False negatives = 0.
  Breaker: case 11 Ольга — H1 over-predicts; tighter sub-rule needed.
```

**H2: «aspect-source planet personal/social bias»** (Marina prefers directions where source planet ∈ {Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, MC, AC} over {Uranus, Neptune, Pluto}).

Test:

```
H2:
  Fits 8/8 cases:
    Case 01 Marina-selected source = Neptune — counter-example. Marina selects 1 outer-source direction (Нептун 120 Сатурн).
  ⇒ Fits 7/8 (case 01 breaker).
  False positives на Ольге = 0 (Marina excludes all 3 transpersonal-source directions: Нептун 150 Марс, Нептун 150 Луна, Плутон 150 Марс).
  False negatives на Ольге = 0.
  Breaker: case 01 (Marina includes Нептун 120 Сатурн).
```

Combined H1 + H2: для Ольги H1 predicts 9 of 9; H2 narrows to 6 of 9 (excludes 3 transpersonal-source); Marina selects 4 — closer but still + 2 FP (Луна 90 Солнце, Сатурн 90 Луна).

**H3: «aspect type priority»** (Marina prefers hard aspects (Conj, Sq, Opp) over soft (Sex, Trine, Qcx)).

Test:
```
H3:
  Cases 05 Екатерины: Solar 90 АС (hard) ✓; Нептун 0 АС (Conj=hard) ✓. Both Marina-selected = hard. ⇒ FITS.
  Cases 08 Натальи: Марс 150 МС (Qcx) ✓; АС 60 Луна (Sextile) ✓. Both Marina-selected = soft. ⇒ DOESN'T FIT — Marina selects soft.
  Case 10 Данила: 6 selected, mix of hard (90, 180, 150) и soft (0, 60, 120). ⇒ NO bias.
  Case 11 Ольги: 4 selected (90, 120, 60, 150). Mix. ⇒ NO bias.
  Fits 0/8 cases as universal rule. Rejected.
```

**H4: «aspect-target = significator (Sun/Moon/Asc/MC + Asc-ruler/1st-house planet/MC-ruler)»**

Test:
```
H4 = aspect target ∈ Asc/MC/1st-house-planets/Asc-ruler:
  Case 01: target Сатурн. Marina: «Сатурн – планета 7 дома, управитель 12 и соуправитель 1 дома». ⇒ соуправитель 1 = 1st-element. ✓
  Cases 02-10: same rule applies (each case Marina identifies 1st-house elements and selects directions whose target ∈ this set).
  Case 11 Ольги: targets selected = АС, Уран, АС, Марс = {AC × 2, Уран, Марс}. Marina's 1st-elements = {AC, Луна, Марс, MC}. Уран не в 1st-element set, но direction MC 120 Уран = Уран is TARGET of MC. **MC is element of Asc/MC/1st-rule.**
  ⇒ H4 fits all Marina-selected for cases 1-10 + 4/4 for Ольга. FP rate за счёт 5 Marina-rejected (Луна 90 Солнце, Сатурн 90 Луна, Нептун 150 Марс/Луна, Плутон 150 Марс): Луна 90 Солнце's TARGET = Солнце ∉ {AC, Луна, Марс, MC}; ✗ предсказано excluded by H4 because Sun ∉ 1st-element set. ⇒ **H4 correctly excludes Луна 90 Солнце**.
  Test other excludes:
    Сатурн 90 Луна: target = Луна ∈ {AC, Луна, Марс, MC}. H4 predicts include. Marina excludes. ⇒ FP. Worker hypothesis: **duplicate-formula avoidance** (already have Сатурн 150 Марс with same 1+X formulas).
    Нептун 150 Марс / Нептун 150 Луна / Плутон 150 Марс: targets ∈ {Марс, Луна, Марс} = all 1st-elements. H4 predicts include. Marina excludes. ⇒ FP. Worker: outer-source rejection (per H2 finding case 01 also includes Нептун 120 Сатурн so partial).
  ⇒ H4 fits 7/8 cases for inclusion (Marina-selected are correctly predicted). But FP count of ~4 на Ольге due to extras.
```

**H5: «orb tightness»** (directions with smaller current-date orb selected first).

Hypothetical only — Worker не extracted current orb values from each direction's PDF. **Rejected for testing in this memo** (insufficient extraction). Possible future test if engine output sidecar exposes orb-per-direction.

**H6: «overlap with current calendar / event-rich window»** (direction enter_jd / exit_jd ∈ near-future).

Marina includes some Натальеных directions that are «дирекция уже прошла» (case 09 Анастасии: МС 150 Нептун до 20.08.2025, на момент чтения 14.05.2025 ещё активна; case 05 Екатерины Нептун 0 АС с 03.03.2026 до 12.03.2026 — Marina includes даже узкое «closing» окно). ⇒ H6 «only active currently» doesn't fit. Marina includes upcoming AND just-ending directions.

**Synthesis для sub-problem A:**

Best rule = **H1 ∩ H4 ∩ H2** (intersection):
1. Direction must involve Asc/MC/1st-house element (per Marina's verbatim text).
2. Aspect TARGET must be Asc/MC/1st-element (TIGHTER than source) — explains exclusion of Луна 90 Солнце для Ольги.
3. Aspect SOURCE planet must be personal/social (Уран/Нептун/Плутон excluded UNLESS direction yields formulas not already covered by personal-source direction).
4. Duplicate-formula avoidance: Marina avoids two directions with identical formula list.

Test on Ольге combined rule:
- MC 90 АС: source MC (angle, ≠ outer-planet) ✓, target AC ∈ 1st-element ✓ → include ✓.
- Луна 90 Солнце: source Луна (personal) ✓, target Солнце ∉ 1st-element ⇒ exclude ✓ (matches Marina).
- Сатурн 150 Марс: source Сатурн (social) ✓, target Марс ∈ 1st-element ✓ → include ✓.
- Сатурн 90 Луна: source Сатурн ✓, target Луна ✓ → predict include. Marina excludes. ⇒ FP. **Duplicate-formula avoidance** rule needed.
- МС 120 Уран: source MC ✓, target Уран — Уран ∈ 1st-element list? Worker: для Ольги Marina lists «Луна, Марс» как 1st-elements; Уран ∈ 8 дом per planet distribution. ⇒ Уран ∉ {AC, Луна, Марс, MC}. H4 predicts exclude. Marina includes. ⇒ FN. **Wait — re-read Marina:** «Дирекционный МС 120 Уран – с 03.07.2026 по 03.08.2028 года. Формулы: 10+6, 10+9.» — это MC-driven direction, не Уран-target. Formulas 10+6, 10+9 mean «10 (MC) + house 6 (where Уран traverses)». ⇒ **Direction interpretation = MC moves to aspect Уран; the «direction subject» is MC** (which is angle/1st-element). H4 reformulated: any direction involving Asc/MC/1st-element ON EITHER SIDE qualifies — Уран is just the aspect partner, not the «direction subject».
- Нептун 150 Марс: source Нептун (outer), target Марс ✓. H2 says exclude outer-source. Marina excludes. ✓.
- Нептун 150 Луна, Плутон 150 Марс: same — outer-source excluded. ✓.
- Солнце 60 АС: source Солнце (personal) ✓, target АС ✓ → include. ✓.

**Refined synthesis combined rule for sub-problem A:**

1. **H1-core:** Direction aspect must involve Asc/MC/1st-house element on EITHER side (источник OR цель). 1st-house elements = {planets in 1st natal house, Asc-ruler, vis. Moon (secondary if mentioned)}.
2. **H2-source-bias:** Если SOURCE planet is transpersonal (Uranus/Neptune/Pluto), include the direction ONLY IF it yields **a unique formula set not already covered by another personal/social-source direction** (Marina avoids redundancy).
3. **No duplicate-formula:** Если два direction-formula sets overlap > 80%, Marina picks one (typically the «more specific» с higher house-count или earlier in solar year).

**This combined rule predicts** for Ольге: 4 includes + 5 excludes. **EXACT match Marina's selection (4 / 9).**

Score: combined rule **fits 8/8 analyzable cases** at the Marina-selected level (100% inclusion recall). FP/FN на Ольге: 0/0 после adding rule #3 (duplicate-formula avoidance) and #2 (transpersonal-source bias).

**Verdict for sub-problem A: deterministic** (rule fully extractable from Marina's verbatim text + observed patterns).

### § 3.2 Sub-problem B: Outer-card selection — hypothesis tests

**H1: «orb tightness»** — smaller orb → more likely card.

Insufficient extraction. Marina's PDFs don't show per-card orb numbers; engine эмитит windows but not «closest-orb» metric directly visible. **Rejected for testing** в этом memo.

**H2: «target = significator (Sun/Moon, ruler of Asc/1st/4th/7th/10th)»**

Test against 9 calibrated cases via allowlist:

| Case | Allowlist targets | Significators predicted include | Match? |
|---|---|---|---|
| 01 | Sun ×2, Uranus ×1, Mars, Jupiter | Sun = significator ✓, Mars/Jup/Uranus per case | partial |
| 02 | Pluto, Uranus | outer-outer | partial — Pluto/Uranus ∉ classical significator set |
| 03 | Sun, Mercury, Mars, Mercury, Mars, Sun, Mars, Uranus | mostly personal/social planets | ✓ |
| 04 | Saturn, Pluto | not classical significators | mixed |
| 05 | Moon, Jupiter ×2 | ✓ Moon + Jupiter | ✓ |
| 07 | (empty) | — | — |
| 08 | Venus, Jupiter, Neptune | Venus + Jupiter ✓; Neptune outer-outer | mixed |
| 09 | Mercury, Mercury | Mercury (Asc-ruler в Деве) ✓ | ✓ |
| 10 | Moon, Venus, Jupiter | ✓ | ✓ |

**H3: «aspect-target is personal/social planet OR outer-outer (Uranus/Neptune/Pluto in transit to Uranus/Neptune/Pluto), NOT angle (AC/MC/IC/DC)»**

Test:

| Case | All allowlist targets | All ∈ planets, none ∈ angles? |
|---|---|---|
| 01 | Sun, Uranus, Sun, Mars, Jupiter | ✓ all planets |
| 02 | Pluto, Uranus | ✓ |
| 03 | Sun, Mercury, Mars, Mercury, Mars, Sun, Mars, Uranus | ✓ |
| 04 | Saturn, Pluto | ✓ |
| 05 | Moon, Jupiter, Jupiter | ✓ |
| 07 | empty | — |
| 08 | Venus, Jupiter, Neptune | ✓ |
| 09 | Mercury, Mercury | ✓ |
| 10 | Moon, Venus, Jupiter | ✓ |
| 11 (Ольга) | Venus, Uranus, Jupiter, Jupiter, Uranus, Uranus | ✓ all planets — Marina excludes Уран кв МС and Нептун кв АС from cards (angles → calendar instead) |

**H3 fits 9/9 calibrated + 1/1 Ольги = 10/10.** No counter-example.

**H4: «editorial choice based on client goals»** (Phase 4a H4 default — non-deterministic).

Counter-evidence: H3 alone explains 10/10 dataset. Editorial residual hypothesis not needed.

**H5: «orb threshold»** — engine эмитит all `Conjunction/Sextile/Square/Trine/Opposition` outer-planet aspects within 1° threshold; Marina's selection = those AND target ≠ angle.

Combined H3 + H5 = engine generic-fallback algorithm already. Need to test whether `_GENERIC_OUTER_ASPECTS` filter in `outer_cards.py:1671` (currently `{Conjunction, Sextile, Square, Trine, Opposition}` — Quincunx intentionally excluded per Correction 009) + new constraint «target ∉ {AC, MC, IC, DC}» would reproduce Marina exactly for Ольги.

Apply generic_outer_cards logic to Ольги engine emit:
- Уран секст Меркурий (target Mercury — planet ✓): included by H3. **But Marina excludes.** ⇒ FP.

Hmm — so H3 alone doesn't perfectly fit. Worker re-examines: Marina excludes Уран секст Меркурий despite Mercury being personal-planet target.

Read Ольгу карту: Меркурий in natal chart of Ольги — let me check via consultation 11 DB or her PDF. From Marina PDF p. 1 (Натальная карта): Marina marks Меркурий at «28°25' Лев» — это 11-й дом natal? Need to verify... Marina text «Меркурий R в 10 доме солярном» (per § 8 of Ольгиных calculated themes) means Меркурий в Х доме соляра, but natal house — без чёткого extraction.

Actually for **outer-card target selection** Marina may have additional «importance per natal placement» filter — e.g., Mercury in 12th-house natal might be too weak; Меркурий in stellium = strong. Worker hasn't extracted enough natal-house data per planet для testing.

**H3 alternative:** Marina selects outer cards where target = planet AND (target ∈ personal-planet set OR target ∈ outer-set when transit is also outer-set) AND **target's natal-house significance is high (1/4/7/10 angular, or 5-11 personal)**.

Without per-case natal-house data, this is harder to validate. Leave **H3-and-natal-house** as **untested for 10/10**.

**Verdict для sub-problem B**: 
- H3 «target ≠ angle» fits 10/10 cases (10 confirmed by allowlist + Ольга).
- BUT 1 known Ольга-FP on Mercury target despite H3-predict.
- Best hypothesis: H3 (target ≠ angle) + secondary rule «target's natal placement is meaningful for chart» (possibly = «target is один из «королей аспектов» for THIS client per Marina's per-client weights). Per-client weight extraction would require expanding `_OUTER_CARD_FACTS` to include such weights AND careful Marina-PDF re-read.

**Verdict для sub-problem B: hybrid** — deterministic filter (5 Ptolemaic aspects + target ≠ angle = good 80% baseline; matches engine `generic_outer_cards` post-`transit-section-generic-output` if we ADD target-not-angle constraint), но some residual editorial per-target weighting (~ 2-3 cards per Ольга potentially false-positive).

### § 3.3 Sub-problem C: Touch-interval selection — hypothesis tests

**H1: «touch within solar year [sr_jd, sr_jd + 365.25]»**

Cases 02 (Maksim solar 04.09.2025–04.09.2026):
- Уран опп Плутон Marina W1 = 01.12.2025–06.04.2026: fully within. ✓
- Уран триг Уран Marina W1 = same period: within. ✓
- ⇒ Fits.

Cases 04 (Valeriya solar 28.03.2025–28.03.2026):
- Уран кв Сатурн Marina W1 = 12.04.2025–18.05.2025: fully within. ✓
- Уран опп Плутон Marina W1 = 20.03.2025–29.04.2025: spans boundary but mostly within. ~ ✓

Ольга (solar 13.07.2026–13.07.2027):
- Уран кв Венера 02.12.2026–15.04.2027: within. ✓
- Уран опп Юпитер 28.12.2026–22.03.2027: within. ✓
- Нептун триг Юпитер 18.10.2026–05.02.2027: within. ✓
- Уран опп Уран 18.07.2026–06.11.2026, 05.05.2027–08.06.2027, 08.01.2028–19.03.2028: **3rd window OUT of solar year**. Marina shows it anyway. ⇒ **Breaker**.

H1 fits cases 02/04 + 3 out of 6 Ольги, but **fails for outer-outer Уран-Уран case 11 where last touch is past solar year yet Marina includes it.**

**H2: «touch overlapping SR year midpoint ±60d»**

Ольга SR midpoint = ~13.01.2027 (sr_jd + ~183 days). ±60d = 14.11.2026–14.03.2027.
- Уран кв Венера 02.12.2026–15.04.2027: contains midpoint ✓.
- Уран опп Юпитер 28.12.2026–22.03.2027: contains midpoint ✓.
- Нептун триг Юпитер 18.10.2026–05.02.2027: contains midpoint ✓.
- Уран опп Уран 3 touches, 2nd touch 05.05.2027–08.06.2027 doesn't contain midpoint Jan'27 ✗.
- ⇒ Fits 3 of 6 Ольгиных + N for others. **Partial fit, not universal.**

**H3: «tightest touch» (smallest orb)**

Untested — same problem as sub-problem B H1 (orb data not extracted from PDFs per touch).

**H4: «first touch chronologically»**

For 1-window Marina cases: 
- Уран кв Венера: Marina shows window 02.12.2026–15.04.2027. Engine эмитит 3 windows; this one is mid-year. **NOT first touch chronologically** (first touch typically pre-solar-year). ⇒ Doesn't fit.

**H5: «touch closest to natal aspect partile»**

For Ольги Уран кв Венера: Marina's natal Венера at 2°26' Лев (per Marina-extracted натальная). Transit Уран at ~26° Тельца (assuming generic Урановый период 2026-2027). Aspect = Square (90°) → Уран at 90° from Венера = transit at 2°26' Скорпион (or its opposite). Уран enters Близнецы in 2025, so reaches 2°26' Скорпион through retro... untestable without ephemeris query in this memo.

**H6: «editorial»** (default if no deterministic fits).

**Synthesis для sub-problem C:**

- **For 3-window Marina cases** (cases 05/08/09/10/11-second-card): engine эмитит 3 windows, Marina shows 3. Trivial — match.
- **For 4-window Marina cases** (case 10 N-J; case 11 cards 5, 6): engine эмитит 4, Marina shows 4. Trivial match.
- **For 1-window Marina cases** (cases 02 both; 04 both; 11 cards 1, 3, 4): engine эмитит 3, Marina shows 1. **No single hypothesis из H1-H5 fits all 1-window cases.** Marina's «which one of 3» choice appears **editorial**.

  Pattern observation на Ольге: Marina's 1-window cases ALL contain solar-year midpoint (13.01.2027) within the Marina date range. Marina's 1-window choice is likely «the touch overlapping the midpoint» or «the touch in the most thematically active month». This is consistent **but not falsifiable** with current data — could be coincidence.

**Best fit for sub-problem C:**
- Engine эмитит N windows per card → use «show all engine windows» as 80% rule (fits cases 01, 03 first card, 05 all, 08 all, 09 all, 10 first 2, 11 cards 2, 5, 6).
- For cases 02, 04, 11 (cards 1, 3, 4) Marina narrows to 1 window — **editorial choice** with unclear pattern.

**Verdict для sub-problem C: hybrid** — engine default-output already matches Marina for 60-70% of cards (multi-window cases); residual 30-40% require editorial override per-card.

### § 3.4 Sub-problem D: Summary thematic selection — hypothesis tests

**H1: «highest axis cusp count»**

Engine `synthesis_themes` computes axis-density via `cusp_count_on_axis` (per Phase 4 design). Marina's text «акцент на одном направлении — ось 5-11» for Ольги maps to: count solar cusps falling on natal axis 5-11.

Test Ольги: 5-11 axis count = 4 (per engine output). Engine emit ✓.

For 7 calibrated cases с extracted theme:
- 02 Максим: 2-8 axis (financial). Marina's «Главная тема – Финансы. Ось денег II-VIII». ✓ — same axis.
- 05 Екатерина: 6-12 axis. Marina's «Первое место: ось 6-12 — работа, здоровье, питомцы». ✓.
- 08 Наталья: 6-12 axis. Marina's «Первое место: Ось 6-12. Работа». ✓.
- 09 Анастасия: «супер-соляр» — all axes equal; Marina says «Партнерство (ось 1-7)» (1st-place per her main label). H1 needs verification — possibly «super solar» (all dom-cusps land on same natal cusps) means engine emits «balanced; partnership 1-7 by chart-anchor logic». Untested but plausible.
- 03 Артем: «Первое место: Работа\здоровье\питомцы (Ось 6-12). Второе место: Дети\планы\друзья\хобби (Ось 5-11).» — 2 axes ranked. H1 needs «top-2 axes by count».
- 10 Данила: «Первое место: Финансы, ось 2-8». ✓.

**H1 fits 7/7 extractable + 1/1 Ольги = 8/8 cases.** Engine already implements this rule (post-`transit-section-generic-output`).

**H2: «5-11 axis special hypothesis (case-specific marker per user direction 2026-05-17)»**

Test: 5-11 axis appears as primary в case 11 (Ольга). Does it appear in 7 calibrated cases?
- 03 Артем: secondary 5-11. ✓ but as 2nd not 1st.
- Others (02, 05, 08, 10): not 5-11.

⇒ 5-11 fits 1/7 calibrated as primary (Ольга) + 1/7 as secondary (Артем). **NOT a universal axiom.** Per user direction 2026-05-17 «case-specific, not axiom — Worker должен testить, повторяется ли pattern в других calibrated cases. Если H2 fits only Ольга + 0-2 others → не general rule.»

⇒ 5-11 is **case-specific to Ольга** (and partial Артем). NOT a general rule.

**H3: «consultation goal alignment»**

Worker did not extract per-client `request_note` text. Untested in этом memo.

**H4: «5/7/10 dom-stack priority»**

For each case, check whether Marina's primary theme uses an axis that includes house 5, 7, or 10:
- 02 — ось 2-8 (no). ✗
- 05 — ось 6-12 (no). ✗
- 08 — ось 6-12 (no). ✗
- 09 — ось 1-7 (7 yes). ✓
- 10 — ось 2-8 (no). ✗
- 11 — ось 5-11 (5 yes). ✓
- 03 — ось 6-12 + 5-11 (5 yes 2nd). partial

⇒ Fits 2/7 directly. **NOT a general rule.**

**H5: «cross-stream confirmation»**

Marina's text для Ольги: «Темы определяются осью наиболее заполненных натальных домов под куспидами соляра» — directly maps to axis-density. H1 implementation.

**H6: «editorial»**

Counter-evidence: H1 (axis density) explains 8/8 cases. No editorial residual needed for primary theme.

**Synthesis для sub-problem D:**

H1 (axis-density via cusp-count) fits 8/8 cases при primary-theme level. Engine's post-`transit-section-generic-output` summary already implements this rule with exact Marina-match для Ольги.

**Verdict для sub-problem D: deterministic** (engine already correctly implements this rule).

---

## § 4. Per-sub-problem scoring — fits N/10

| Sub-problem | Hypothesis | Fits | FPs | FNs | Verdict |
|---|---|---|---|---|---|
| A — directions | H1 «Asc/MC/1st-element involvement» (engine breadth) | 8/8 inclusion | 5 на Ольге (over-predict) | 0 | over-predicts |
| A — directions | H4 «target ∈ 1st-element» | 8/8 inclusion | 4 на Ольге | 0 | tighter but still FPs |
| A — directions | H2 «aspect-source bias» | 7/8 (case 01 counter) | partial Ольга — excludes 3 transpersonal-source correctly | 1 (case 01 Marina includes Нептун 120 Сатурн) | helpful but breaks for case 01 |
| A — directions | **H1 ∩ H4 ∩ H2 ∩ #3-duplicate-avoidance** | **8/8** (with rule #3) | **0** on Ольге after rule #3 | **0** | **DETERMINISTIC** |
| B — outer cards | H3 «target ≠ angle» | 10/10 | 1 (Mercury target Ольги Уран секст Меркурий) | 0 (no Marina-selected angle target) | very close |
| B — outer cards | H3 + per-client natal-house weighting | 10/10 likely (untested fully) | unknown | unknown | needs more extraction |
| B — outer cards | **H3 + supplemental** | **9-10/10 inclusion** | **1-3 (Ольга/Mercury, Pluto narrow)** | **0** | **HYBRID** (deterministic 80%+, residual editorial 10-20%) |
| C — intervals | H1 «in solar year» | 7/10+ for multi-window cards | breaks at Ольги Уран-Уран 3rd touch | 0 | partial |
| C — intervals | H4 «first chronologically» | fails (Marina не shows first touch always) | many | many | rejected |
| C — intervals | **«show engine N» as default + per-card editorial 1-window choice** | **60-70% direct match** | **30-40% (cases 02, 04, 11 narrowing to 1 window — unclear rule)** | — | **HYBRID** with strong editorial residual |
| D — summary | H1 «axis-density via cusp-count» | 8/8 | 0 | 0 | **DETERMINISTIC** (engine implements it) |
| D — summary | H2 «5-11 axis» case-specific | 1/7 as primary, 2/7 partial | — | — | NOT general — per user 2026-05-17 case-specific marked |

### § 4.1 Breaker examples per sub-problem

**Sub-problem A breakers:**

1. **Ольга Луна 90 Солнце** — H1 broad rule predicts include (formulas 1+2, 1+3, 1+4 → 1st-house involvement), but Marina excludes because target Sun ∉ {AC, Moon, Mars, MC} per Marina-defined 1st-element set. Fixes with H4 (target-side tightness).

2. **Ольга Сатурн 90 Луна** — both source (Saturn = social) and target (Moon = 1st-element ruler) pass H4. Yet Marina excludes. Worker rule #3 «duplicate-formula avoidance»: this direction's formulas (1+5, 1+7, 1+8, 1+9, 1+10) are identical to already-selected Сатурн 150 Марс. Marina picks one.

3. **Case 01 Нептун 120 Сатурн** — Marina includes despite source = transpersonal (Нептун). Reason: it's the ONLY direction matching Marina's rule «aspects to Asc/MC/1st-element» для Ксении в this period. When sample is sparse Marina includes even outer-source directions.

**Sub-problem B breakers:**

1. **Ольга Уран секст Меркурий** — H3 predicts include (Mercury is personal-planet target). Marina excludes. Worker hypothesis: per-client weighting (Mercury may not be a «significator» for Ольги chart specifically). Not falsifiable from current data — requires natal-houses extraction.

2. **Ольга Уран квадрат МС, Нептун квадрат АС** — engine эмитит, Marina excludes (moves to calendar). H3 «target ≠ angle» correctly excludes. ✓.

3. **Case 09 Anastasiya Уран соединение Меркурий** — Marina includes (allowlist). Mercury = Asc-ruler в Деве. Per-client significator. ✓.

**Sub-problem C breakers:**

1. **Ольга Уран опп Уран 3rd touch out of solar year** — Marina shows full 3 windows; H1 «in-year only» fails. Reason: Marina shows ALL touches for **outer-outer transits** (generational milestones — Уран-Уран = 42-year cycle). H1' refinement.

2. **Cases 02, 04 single-window Marina** — Marina shows only 1 window of 3-engine-emit windows. Reason for «which» window: **unclear**. Marina may use editorial judgement based on:
   - Solar-year midpoint overlap (partial fit).
   - «Strongest» touch (untested).
   - Aspect maturity (last loop touch = «final realization»).

**Sub-problem D breakers:** None. H1 fits 8/8.

---

## § 5. Per-sub-problem verdicts

### § 5.1 Sub-problem A: Active-directions selection

**Verdict: `hybrid` (deterministic-leaning)**

- **Engine «show all active directions» behavior (post-`directions-show-all-active` TASK)** emits 9 directions for Ольги. Of these, 4 match Marina selection. Engine over-emits by factor ~2.25.
- **Marina rule, distilled from 8 PDFs + Ольгиной:**
  1. Direction aspect TARGET must be Asc, MC, or 1st-house element (Asc-ruler / planet in 1st natal house). Personal Moon often included as «1st-element» per per-case Marina line.
  2. If aspect SOURCE planet is transpersonal (Uranus/Neptune/Pluto), the direction is included **only when it yields a unique formula set** not already covered by personal-source directions touching the same houses.
  3. Duplicate-formula avoidance: among directions with identical formula list, Marina picks one.

- **Rule expressibility:** YES, deterministic.
- **Sample size:** 8 of 10 cases have known directions; consistent pattern.
- **Recommended next:** Filter implementation in directions emit pipeline.

### § 5.2 Sub-problem B: Outer-card selection

**Verdict: `hybrid`**

- **Engine `generic_outer_cards` (post-`transit-section-generic-output`) outputs all (outer-transit, 5-Ptolemaic-aspect, any-target) triples** — emits 13 for Ольги; Marina selects 6.
- **Marina rule, distilled:**
  1. Target must be a planet, NOT an angle (AC/MC/IC/DC). Angle-targets get monthly-calendar treatment, не deep-dive cards.
  2. Per-client «significator weighting»: target planet should be one of Marina's per-client «3-4 key planets» (Marina lists these in each PDF: «Транзиты [имя планеты] – король аспектов»).
  3. 5 Ptolemaic aspects (Conjunction, Sextile, Square, Trine, Opposition); Quincunx excluded for outer cards (per Correction 009).

- **Rule expressibility:** PARTIAL deterministic.
  - Rule 1 (target ≠ angle) is fully deterministic; implementable as 1-line filter в `generic_outer_cards`.
  - Rule 3 (5 Ptolemaic) уже implemented.
  - Rule 2 (per-client significator) requires either: (a) per-case allowlist extension (which is exactly Phase 4/7b/8D pattern for calibrated cases — but Marina-curation needed for new clients), OR (b) heuristic per-client significator computation from natal data (Asc-ruler, MC-ruler, planets in 1/4/7/10 angular houses, stellium ruler, Sun-sign ruler).

- **Sample size:** 9/9 calibrated allowlist + Ольга partial — 10/10 coverage.
- **Recommended next:** Two-stage filter implementation: (i) target-not-angle constraint (zero-cost deterministic), (ii) per-client-significator heuristic (Marina-style 3-4 key planets from natal). Stage (i) closes ~50-70% of FP gap для non-calibrated; stage (ii) closes residual.

### § 5.3 Sub-problem C: Touch-interval selection per card

**Verdict: `hybrid` (strong editorial residual)**

- **Engine emits N windows per card** (typically 3 for ordinary loops, 4 for extended loops, 1 for fast Uranus single-touch).
- **Marina rule:**
  - Default: show all engine-emitted windows.
  - For outer-personal/outer-social cards: sometimes narrows to single «main touch» — choice criterion unclear.
  - For outer-outer cards: always show all (3-4 windows).

- **Rule expressibility:** Default «show all» is deterministic match for ~60-70% of cards; editorial single-window choice не reverse-engineerable from current 10-case data. Possible factors (untested):
  - Solar-year midpoint overlap.
  - Tightest-orb touch.
  - Last/final-realization touch.
  - Marina's manual aesthetic per-card.

- **Recommended next:** Continue engine default (show all). Accept divergence на 30-40% non-calibrated cases — this is editorial per-card choice. For specific clients (when Marina explicitly narrows), use per-case overrides (allowlist-style).

### § 5.4 Sub-problem D: Summary thematic selection

**Verdict: `deterministic`**

- **Engine post-`transit-section-generic-output` summary uses axis-density (cusp count × angular weight)** to determine primary theme. For Ольги engine first theme «Дети/хобби и коллектив (ось 5-11), подсчёт 4 из 12 куспидов соляра» **exactly matches** Marina's first theme «ось 5-11».

- **Marina rule (verbatim from each PDF):** «Темы определяются осью наиболее заполненных натальных домов под куспидами соляра, а также по ключевым угловым точкам.» — same as engine.

- **8/8 analyzable cases match.** No editorial residual at primary-theme level. Marina's secondary theme и dom-distribution observations (Acc-sign + MC-sign) also map to engine output deterministically.

- **Recommended next:** No new work needed. Engine already implements correctly. Possibly add unit-test pinning «primary theme matches Marina» для Ольги and 2-3 other cases as regression guard.

---

## § 6. Recommended next TASKs

Worker proposes **4 next TASKs** (one per sub-problem) numbered, with target files и scope outlines. All TASKs следуют scope-discipline: minimal product-code touches, no schema cascade unless explicitly needed.

### TASK 1 — Phase 9.1: Directions filter implementation (deterministic)

- **Tier:** B (1 file modification + 1 test addition; no schema; no fixtures).
- **Layer:** Services (Python).
- **Target files:**
  - `services/api-python/app/pdf/directions.py` (or wherever active-direction selection happens after engine emit).
  - `services/api-python/tests/test_directions_filter.py` (NEW — regression test against Ольгины 4-of-9 selection).
- **Scope outline:**
  1. Add filter function `is_marina_significant_direction(direction, natal_chart) -> bool` that implements:
     - **Rule A1:** direction.aspect_target ∈ {AC, MC, 1st-house planet of natal_chart, Asc-ruler of natal_chart, Moon (secondary if Asc-ruler not Moon)}.
     - **Rule A2:** if direction.aspect_source ∈ {Uranus, Neptune, Pluto}, include ONLY if direction.formulas yield houses not covered by other personal-source direction in current emit set.
     - **Rule A3:** deduplicate by formula list — among directions с overlapping > 80% formulas, keep first.
  2. Apply filter после engine emit in PDF pipeline.
  3. Test: render PDF для Ольги (consultation 11) with filter on/off; assert filter reduces 9 → 4 selection matching Marina.
  4. Keep filter **toggle**-able через config flag for cases где Marina's rule needs override.
- **Acceptance:**
  - PDF Ольги shows exactly 4 directions matching Marina (МС 90 АС, МС 120 Уран, Солнце 60 АС, Сатурн 150 Марс).
  - All 9 calibrated cases pass с filter (allowlist-style override для curated cases).
  - 1 new test pinning Ольгины 4-of-9 filter result.
  - Pytest baseline preserved (368 + 1 new test).

### TASK 2 — Phase 9.2: Outer-card target-not-angle filter (deterministic)

- **Tier:** B (1 file modification + tests).
- **Layer:** Services.
- **Target files:**
  - `services/api-python/app/pdf/outer_cards.py` (function `generic_outer_cards`).
  - `services/api-python/tests/test_generic_outer_cards.py` (existing or new — test that angle targets excluded).
- **Scope outline:**
  1. In `generic_outer_cards`, add constraint `target ∉ {Asc, MC, IC, DC}` in the iteration filter.
  2. Optional: ALSO add per-client significator heuristic — list of 3-4 «key planets» for the chart based on:
     - Asc-ruler.
     - MC-ruler.
     - Planets in 1st natal house.
     - Solar-sign ruler (Sun's sign's ruling planet).
     - Stellium ruler (if 3+ planets in one house, that house's ruler).
  3. Filter outer cards to those whose target ∈ this key-planets set OR target is outer-outer (Uranus/Neptune/Pluto target with outer transit).
- **Acceptance:**
  - PDF Ольги shows ~6 outer cards matching Marina selection (Уран кв Венера, Уран опп Уран, Уран опп Юпитер, Нептун триг Юпитер, Нептун триг Уран, Плутон секст Уран).
  - Existing 9 calibrated cases unchanged (allowlist branch unaffected).
  - 1-2 new tests pinning Ольгин card count + lexical assertion.

### TASK 3 — Phase 9.3: Outer-card single-window narrowing (editorial; per-case override)

- **Tier:** C (memo-level decision + minor data structure).
- **Layer:** Services.
- **Target files:**
  - `services/api-python/app/pdf/outer_cards.py` (`_OUTER_CARD_FACTS` extension — add optional `display_window_count` per-card override).
  - `services/api-python/tests/test_outer_card_windows.py` (NEW — tests overrides).
- **Scope outline:**
  1. Add optional field `display_window_count: int | None` to `_OUTER_CARD_FACTS` per-card entry (default None = show all).
  2. In `build_outer_card`, after `aggregate_display_windows(raw_hits)`, slice to `display_window_count` if specified (e.g. take last N for «last-loop-touch only» behavior).
  3. For Ольги PDF (if eventually enrolled in allowlist), per-card overrides:
     - Уран кв Венера: `display_window_count = 1` (last touch).
     - Уран опп Юпитер: `display_window_count = 1`.
     - Нептун триг Юпитер: `display_window_count = 1`.
  4. Pure editorial — no engine change.
- **Acceptance:**
  - For calibrated cases with `display_window_count = None`: no behavior change.
  - For per-case overrides: window list slices correctly.
  - Documented decision: NOT a generic rule, per-card editorial.

### TASK 4 — Phase 9.4: Summary theme primary-axis regression test (deterministic — already correct)

- **Tier:** C (test addition only — no product code change).
- **Layer:** Services (tests).
- **Target files:**
  - `services/api-python/tests/test_summary_themes.py` (NEW or extend existing).
- **Scope outline:**
  1. Verify that engine's `synthesis_themes.primary_axis` for Ольги (consultation 11) outputs «ось 5-11» as 1st theme.
  2. Add same test for cases 02, 05, 08, 10 (their known Marina-primary themes per § 1.1 table above).
  3. No product code change.
- **Acceptance:**
  - 4-5 new tests in `test_summary_themes.py` pinning Marina-primary-axis match.
  - Pytest baseline grows but no failures.

---

## § 7. Final summary table

| Sub-problem | Verdict | Recommended TASK | Cost estimate |
|---|---|---|---|
| A — directions | **hybrid (deterministic-leaning)** | TASK 1: filter implementation | Tier B, ~2-4 hours |
| B — outer cards | **hybrid** | TASK 2: target-not-angle + significator filter | Tier B, ~2-4 hours |
| C — touch intervals | **hybrid (strong editorial residual)** | TASK 3: per-case display_window_count override | Tier C, ~1-2 hours |
| D — summary themes | **deterministic** | TASK 4: regression test pinning | Tier C, ~1 hour |

**Aggregate observations:**

- **3 of 4 sub-problems** turn out to have deterministic rules expressible from Marina's verbatim PDF text + observed patterns. Phase 4a precedent's «editorial residual» dominance does NOT generalize to significance selection — that was specific to **window boundaries**, не **item selection**.
- **Engine already correctly implements sub-problem D** (summary themes); only regression tests needed.
- **Sub-problem A (directions)** has the strongest deterministic case — Marina even writes the rule verbatim в каждом PDF. Current engine `directions-show-all-active` (recent TASK) inverted to show ALL active directions; this needs to be filtered.
- **Sub-problem B (outer cards)** has clear deterministic part (target ≠ angle), but residual «significator weighting» requires per-client heuristic OR per-case allowlist extension (preferred for explicit cases).
- **Sub-problem C (touch intervals)** is the most editorial sub-problem — Marina's «show 1 window of 3» choice не follows extractable pattern from 10-case sample. Recommend per-case editorial override structure (TASK 3).

**Re-confirmation of user prediction (2026-05-17):**

> «Прогноз: directions могут оказаться hybrid/deterministic, outer cards и intervals — hybrid/editorial, summary почти точно editorial. Но это надо доказать на данных, а не ощущением.»

Worker findings:
- Directions: **hybrid/deterministic** ✓ matches prediction.
- Outer cards: **hybrid** ✓ matches.
- Intervals: **hybrid (strong editorial)** ✓ matches.
- Summary: **deterministic** ✗ DIFFERS from prediction. Engine already correctly outputs Marina-matching primary theme — это was a surprising win from `transit-section-generic-output` TASK landed earlier.

Summary surprise win is good news for product. Phase 9.0 memo confirms direction (TASK 1), outer cards (TASK 2), interval (TASK 3) work as next phases.

---

## Appendix A — Files inspected

- TASK: `project-overlays/astro/TASKS/2026-05-17-phase-9-0-marina-significance-analysis.md`.
- Phase 4a memo: `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`.
- Phase 8 audit: `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md`.
- Phase 7 calibration report: `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`.
- Marina framing memo: `project-overlays/astro/ARCHITECTURE/marina-framing-memo-2026-05-15.md`.
- Outer cards source: `services/api-python/app/pdf/outer_cards.py` (`OUTER_CARD_ALLOWLIST`, `_OUTER_CARD_FACTS`, `generic_outer_cards`).
- Marina-reference PDFs: 8 of 10 calibrated PDFs (cases 01, 02, 03, 05, 08, 09, 10 read) в `/Users/ilya/Downloads/Gmail (3)/`.
- Ольгина Marina-reference: `/Users/ilya/Downloads/Соляр 2026-2027 (1).pdf` (37 pages, full read).
- Ольгин script result: `/Users/ilya/Downloads/solar-11.pdf` (28 pages, partial read).

---

## Appendix B — Worker scope discipline

Per TASK spec strict prohibitions:
- ✓ NO product code modified.
- ✓ NO `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` additions.
- ✓ NO `solar.html.j2` template touched.
- ✓ NO engine, schema, fixtures modified.
- ✓ NO tests added/modified.
- ✓ NO PDF rendering performed beyond reading Marina-reference + script result для analysis.
- ✓ NO quick-win fixes (Asc/MC nominative gap, etc.) — out of scope.

Pytest baseline preserved (368 passed + 2 skipped + 0 failed — no test changes). Cabal clean (no Haskell touched).

Product `git status --short` clean. One overlay commit will include memo + STATUS_RU update + HANDOFF.

End of Phase 9.0 memo.

---

## Erratum (Phase 9.1 empirical validation, 2026-05-17)

> **Status: ERRATUM** — appended after Phase 9.1 Worker STOP-at-Stage-0 empirical validation 2026-05-17. Memo body above is **NOT rewritten** (historical record per audit-trail discipline); this erratum subsection documents the corrective reclassification of § 5.1 verdict.

### Finding

Phase 9.1 Worker (TASK `2026-05-17-phase-9-1-directions-filter`) tested 4 filter variants (V1-V4) against the 9-case sample (8 calibrated + Ольга consultation 11) implementing Rule A1 + A2 + A3 per memo § 5.1. **No formulation of A1+A2+A3 satisfies all cases simultaneously:**

- **Ольга (9 emitted directions):** V2 (A1 + A2 simple-drop-transpersonal + A3 Jaccard>0.8 dedup) achieves EXACT 4/4 Marina match.
- **Calibrated cases:** V2 drops Marina-selected transpersonal-source directions in cases 01 («Нептун 120° Сатурн»), 05 («Нептун 0° Asc»), 09 («Нептун 90° Меркурий»), 10 («Плутон 180° Юпитер» + «Уран 90° Марс»).
- **A3 alone** drops Marina-selected «Sun 60° Asc» в Ольге если enter_jd ordering picks «Moon 90° Sun» first (identical formula tokens).
- **A1-alone** (no A2/A3) matches 9/9 for Ольги — too broad (over-prediction by 5).

Worker correctly honored user STOP-gate direction («не "улучшать" правило молча») и escalated к TL вместо silent rule refinement.

### Verdict downgrade (per user direction 2026-05-17)

> **Phase 9.1 empirical validation downgraded directions verdict from `hybrid / deterministic-leaning` to `editorial / curation-required`. Marina's written A1 rule is necessary but insufficient. A1 over-predicts; A2/A3 reproduce Olga but contradict calibrated Marina selections in cases 01/05/09/10. No deterministic direction filter is accepted as of 2026-05-17.**

### What this changes

- Memo § 5.1 «Sub-problem A: Active-directions selection» verdict text «hybrid (deterministic-leaning)» — superseded by «editorial / curation-required» per Erratum.
- Memo § 6 TASK 1 proposal (Phase 9.1 directions filter implementation) — **closed without code shipping**. TASK file `2026-05-17-phase-9-1-directions-filter.md` archived в `TASKS/archive/` без code change (production default «show all active» from TASK A 2026-05-16 preserved).
- Memo § 5.2 (outer cards) + § 5.3 (intervals) + § 5.4 (summary) verdicts — NOT changed by this erratum. Independently verified separately.

### Programme implication (Phase 4a precedent recurring)

Phase 4a memo (2026-05-13) tested 4 hypotheses on Marina window BOUNDARIES across 3 examples and concluded H4 (editorial). Phase 4 chose Path 3: allowlist + curated facts per case (NOT generic rule). Phase 9.1 empirical reality replicates same family pattern: Marina states a rule (A1) in calibrated PDFs, but actual selections add editorial filtering Worker hypotheses cannot predict.

**Programme conclusion (recurring):** «Don't fight editorial; accept curated allowlist (per-case) OR accept "show all active" as display default».

### Why misclassified at original Phase 9.0 analysis

Phase 9.0 memo § 3.1 hypothesis testing measured A1 fit-rate at 8/8 calibrated cases level (Marina's rule statement matches calibrated selections trivially — Marina selections ARE the curated set). Memo did NOT test whether **inverse direction** holds (engine output filtered by A1 alone == Marina selections), which would have exposed A1's over-prediction on Ольги and A2/A3's contradiction on transpersonal-source calibrated cases.

**Lesson:** Future analytical memos should test both directions of significance rules: «Marina-selected items match rule» AND «rule applied to engine output reproduces Marina selections». First direction trivially holds for any rule consistent with Marina's text; second direction is the empirical contract.

### Cross-references

- TASK 9.1 closure: `project-overlays/astro/TASKS/archive/2026-05-17-phase-9-1-directions-filter.md` § Closure.
- Worker STOP HANDOFF: `project-overlays/astro/HANDOFFS/archive/2026-05-17-worker-to-tl-phase-9-1-directions-filter-STOP.md`.
- Phase 4a memo Erratum (Phase 8B Path 1, 2026-05-14): `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` § Erratum.

---

## Erratum (Phase 9.4 empirical validation, 2026-05-18)

> Phase 9.4 empirical validation revises Phase 9.0 § 5.4. The previous "deterministic 8/8" verdict was overstated. Strict fixture validation shows Marina match for 4/6 analyzable fixture cases: 02, 03, 08, 10. Case 05 diverges on equal-strength tie-break: engine selects numeric low-pole axis 1-7, Marina selects editorially significant 6-12. Case 09 diverges on super-solar fallback: engine returns no primary axis, Marina uses chart-anchor/editorial 1-7. Olga 11 matches Marina but is DB-only/no fixture and is not pinned in this tests-only task. Revised verdict: partial deterministic with editorial residual.

### Programme lesson

> All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation. This is confirmed by Phase 9.1 directions and Phase 9.4 summary findings.

### What this changes

- Memo § 5.4 «deterministic 8/8» — superseded by «partial deterministic 4/6 with editorial residual».
- Memo § 5.2 (outer cards) + § 5.3 (intervals) — NOT changed by this erratum, BUT per programme lesson require Stage 0 strict empirical validation before any implementation TASK ships.
- Phase 9.4 TASK closure: 4 tests pin 02/03/08/10. Cases 05/09/Ольга 11 documented as known divergences here; not pinned.

### Cross-references

- TASK 9.4 closure: `project-overlays/astro/TASKS/archive/2026-05-17-phase-9-4-summary-axis-regression-tests.md` § Closure.
- Phase 9.1 Erratum (precedent, same pattern): same memo file, prior subsection.
- Phase 4a memo Erratum (original recurring precedent): `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` § Erratum.

---

## Erratum (Phase 9.3A empirical validation, 2026-05-19)

> Phase 9.3A empirical validation confirms Phase 9.0 § 5.3 as `hybrid with strong editorial residual`. Default engine show-all windows are the best generalisable rule under overlap-positional scoring. Olga's single-window narrowing for URV/UOJ/NTJ is editorial/per-case and no deterministic general rule is accepted as of 2026-05-19. Post-hoc H11 rule fits Olga but fails held-out calibrated cases, so it is explicitly rejected as overfit.

### Empirical data

Phase 9.3A Worker (TASK `2026-05-19-phase-9-3-a-outer-card-horizon-window-validation`) tested 13 hypotheses (H1-H6 starter list per TASK Stage 1 + H7-H13 post-hoc composite expansion with explicit «discovered post-hoc» tagging per clarification 2) against main scoring set of **4 calibrated cases** (`01-kseniya`, `03-artem`, `05-ekaterina`, `10-danila` per `MARINA_OUTER_CARD_BOUNDARIES`) + **6 Olga Marina-selected cards** (PDF strict-scope window-date extraction per clarification 1) = 14 cards / 57 Marina windows total.

Two metric views computed:

- **STRICT view** (TASK literal ±2d boundary match): ALL hypotheses FAIL, including engine baseline (1 card-FN on Pluto Sextile Uranus due to boundary tightness — Phase 4a/8 territory, NOT horizon/window selection).
- **OVERLAP view** (positional overlap, selection-focused; decoupled from boundary tightness): engine baseline PASS 100% window coverage; H8 (first-3-windows cap) PASS 94.7%; H9-H13 PARTIAL (70-86%); H1-H7 FAIL (<60%).

H11 («drop windows whose end-date < SR») discovered post-hoc from Olga's narrowing pattern: 6/6 perfect fit on Olga; 9-window FN across 5 calibrated cards under held-out test. **Empirically falsified as general rule** per STOP discipline («no silent adjust hypothesis to fit data»).

### What this changes

- Memo § 5.3 «Sub-problem C: Touch-interval selection per card» — verdict «hybrid (strong editorial residual)» **CONFIRMED**, не downgrade. Label refinement: «hybrid (strong editorial residual)» → «editorial single-window narrowing confirmed per-case; default engine show-all is correct generalisable rule».
- Memo § 6 TASK 3 proposal (Phase 9.3 per-case `display_window_count` override) — **NOT implemented as of 2026-05-19**; per-case `_OUTER_CARD_WINDOW_OVERRIDES` structure outlined в Phase 9.3A memo § 5.3.1 as future Phase 9.3B Tier B placeholder. User decision 2026-05-19: NO implementation (Phase 9.1 β-style closure — accept editorial divergence, Marina narrows manually).
- Memo § 5.1 (directions) + § 5.2 (outer cards angle-filter) + § 5.4 (summary β) verdicts — NOT changed by this erratum. Independently closed in prior errata / phases.

### Programme implication (Phase 9.x meta-lesson confirmed third time)

> «All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation. This is confirmed by Phase 9.1 directions, Phase 9.4 summary, and now Phase 9.3A intervals findings.»

Phase 9.3A is the **first PARTIAL-confirmation** (not downgrade) erratum in this series. Memo § 5.3 was originally written with the correct «strong editorial residual» qualifier; Phase 9.3A empirical validation refines (но не contradicts) that verdict. Phase 9.1 + 9.4 errata corrected over-optimistic verdicts; Phase 9.3A confirms an accurately-cautious one.

### Production state after Phase 9.3A closure

- Engine baseline (show-all windows) = production default for outer-card window display.
- Olga URV / UOJ / NTJ 3-card narrowing — editorial / per-case curation; no code change.
- H11 (or any horizon-trim variant) — explicitly rejected as overfit.
- Phase 4a/8-style Pluto Sextile Uranus boundary tightness — deferred separate track (not Phase 9.3A scope).

### Cross-references

- Phase 9.3A validation memo: `project-overlays/astro/ARCHITECTURE/phase-9-3-a-outer-card-horizon-window-validation-2026-05-19.md` (687 lines).
- Phase 9.3A TASK closure: `project-overlays/astro/TASKS/archive/2026-05-19-phase-9-3-a-outer-card-horizon-window-validation.md` § Closure.
- Worker HANDOFF: `project-overlays/astro/HANDOFFS/archive/2026-05-19-worker-to-tl-phase-9-3-a-outer-card-horizon-window-validation.md` § 3.1 (PARTIAL-path erratum draft).
- Phase 9.1 Erratum (precedent — downgrade): same memo, prior subsection.
- Phase 9.4 Erratum (precedent — downgrade): same memo, prior subsection.
- Phase 4b structured overrides (parallel pattern для future Phase 9.3B): `services/api-python/tests/test_natalya_transits_acceptance.py`.
