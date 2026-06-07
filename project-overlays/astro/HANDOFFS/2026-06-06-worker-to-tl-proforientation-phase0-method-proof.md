# HANDOFF: worker → tl — proforientation-phase0-method-proof

- Status: open (Phase 0 method-fidelity proof complete; gate for Phase A core)
- Date: 2026-06-06 (analysis executed 2026-06-07)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-06-06-proforientation-phase0-method-proof.md
- Method extract: project-overlays/astro/RESEARCH/daragan-proforientation-method-extract.md
- Memo: project-overlays/astro/ARCHITECTURE/proforientation-module-architecture-2026-06-06.md
- Source book: К. Дараган, «Профессиональная астрология» (Мир Урании, 2019), 690 pp. **Page offset: PDF = printed + 1** (verified on printed page numbers).
- **Product repo status: not applicable (read-only)**

## Summary

Method-fidelity proof for the Daragan proforientation epic. READ-ONLY: no product code.
**The method is REPRODUCIBLE. The golden anchor («Карта 11. Банкир», printed pp. 300–307)
PASSES — my mechanical re-run of the algorithm reproduces every house-ruler assignment in
Daragan's own published stage-1/2 table (printed p. 302), identifies Pluto as a
non-significator exactly as he does, and the conclusion (Jupiter = упр.X в VIII →
успешный финансовый менеджер / банкир) follows from the table my method produces.**

Two factor-definition gaps were found and **one was closed by the golden anchor**:
- **Дорифорий / Возничий**: NOT defined in this book (used in the algorithm + Банкир table
  only). **The Банкир table empirically pins the exact rule** (see § 3) — definition CLOSED,
  but flagged for Marina sign-off because classical doctrine has stricter variants.
- **Фигуры Джонса** (ручка корзины / праща): NOT defined in this book. Standard Jones-pattern
  doctrine applies; the Банкир «Луна = ручка Пращи» is consistent with it. Definition by
  external doctrine — flagged.
- **Благоприятные звёзды**: **NO curated list in this book.** Daragan treats benefic stars as
  primarily an *election* technique (printed pp. 209–211 area; royal-star example «Регул на
  Юпитере / Alphabet Inc»), names only «королевские звёзды» (Regulus) and «астрологически
  значимые звёзды» without enumerating them. **OPEN QUESTION — Phase A cannot derive this
  factor's list from Daragan's book.** Recommended source: Robson / Hofman fixed-star books
  (in the book's own reading list) + royal stars, with Marina approval.

**STOP-gate result: PASS (proceed to Phase A), with 1 open question (benefic-star list) and
2 definitions adopted-from-external-doctrine-pending-Marina-signoff (doryphory, Jones).**
None blocks Phase A core math; all three are isolated stage-2 ability factors that can ship
behind a flag / as a later increment without invalidating the 4-house realization engine.

---

## 1. Method confirmation (5-stage algorithm)

The extract's 5-stage algorithm (printed pp. 292–300) is **complete and correct**. Re-read
verbatim from PDF; no discrepancies with the extract. Nuances captured from the supporting
pages:

- **3-step frame** (p. 293): (1) чем Судьбой разрешено себя обеспечивать → realization;
  (2) сильные стороны / врождённые склонности → abilities; (3) пересечение обоих → выраженные
  склонности, востребованные в социуме. «Лучшие стороны, которые одновременно легче и выгоднее
  монетизировать.»
- **Stage 1 — Realization** (p. 293), 4 houses X/II/VI/VIII, for each: (а) управитель дома;
  (б) планеты в доме; (в) планеты в соединении ИЛИ гармоничном аспекте с управителем дома;
  (г) планеты во взаимной рецепции по обители/экзальтации с управителем ИЛИ планетами дома.
  «Обычно после всех операций остаются пустые строчки.»
- **Stage 2 — Abilities** (p. 294), 8 factors (а–з): (а) управитель Асц + планеты в I доме;
  (б) Дорифорий и Возничий; (в) планеты в обители/экзальтации; (г) управитель солнечного знака;
  (д) соединение/гармония с Солнцем; (е) планета в элевации (выше всех над горизонтом);
  (ж) «ручка корзины»/«праща» в фигурах Джонса; (з) планеты на благоприятных звёздах.
  **«Планеты, упомянутые не по разу, — особо значимы»** → repeat-count is a first-class ranking
  signal.
- **Stage 3 — Filter** (pp. 294–295): keep planets whose rows are densely filled; **a planet
  with ANY empty field (any column) → «рассматривать нежелательно».** Among abilities — priority
  to best zodiac position + best aspectation simultaneously. Among realization — house hierarchy
  **угловой (X) > последующий (II) > падающий (VI)**; VIII only on very favourable combos / real
  context.
- **Stage 4 — Selection** (p. 295): if a top planet is connected with X → usually optimal;
  else list «зёрнышко к зёрнышку» best→worst, angular→cadent; interested in the **first 2–3**.
- **Stage 5 — Interpretation** (pp. 295–297): planet narrows the field, sign narrows further,
  house = the income mode; account for intersecting meanings of planet+house+sign+aspects.

**Extra rules confirmed:** «какая профессия лучше» = the one best described in the chart (p. 297);
several professions at once = normal portfolio diversification (pp. 297–298); connected houses —
check angular sigs first, then succedent, then cadent (p. 298). **Призвание** (pp. 298–300): not
universal; ≥2 of 3 conditions (p. 300) — (1) best-proforientation planet is most prominent with
substantial advantages; (2) it is the Sun, Asc-ruler, or conjunct Asc-ruler/Sun; (3) it sits on
an astrologically significant star, or exactly on an Angle, or in tight aspect to the Lunar Nodes,
or conjunct a planet of a major mundane chart (e.g. last Great Mutation). **Do not impose призвание
where the chart lacks it.**

---

## 2. Significator mappings (for stage-5 interpretation rules, Phase B)

Captured from the «Сигнификаторы» chapter (planet → activity, printed **pp. 69–79**, reinforced
by the business-chart significators **pp. 206–209**) and the house meanings (**pp. 93–97**,
reinforced **pp. 210–212**). **Status: CAPTURED (sufficient for a Phase-B draft ruleset).**
These are data for `packages/rulesets/vocation/` (Марина правит), NOT code.

### 2.1 Planet → activity / товар (pp. 69–79)

| Planet | Core professional domain (pp. cited 69–79) |
|---|---|
| **Солнце** (69–70) | креатив/творчество, шоу-бизнес; всё, где надо «блеснуть»; реклама, PR, публичные проекты; характерные актёрские роли, стендап, ведение тренингов/семинаров; эксклюзив / ручная работа / ювелирка / золото; возглавление на личной харизме (не управление). |
| **Луна** (70–71) | выращивание/воспитание/обеспечение жизнедеятельности; аграрно-сельхоз; успех у публики («симпатии народа»); лицедейство/смена ролей/копирование; психологическая помощь (умение слушать); бытовые/обслуживающие профессии (медсёстры, горничные); скоропортящиеся продукты, вода, детские товары; серебро, кухонная утварь; сигнализации/фильтры. |
| **Меркурий** (71–72) | главный управитель коммерции/посредничества/обмена; торговля знанием; работа со словом/языком/документами (переводчик, журналист, редактор, писатель, программист с Ураном); посредники/торговля/почта/секретари; мелкое воровство; книги/канцелярия/ценные бумаги/нумизматика. |
| **Венера** (72–73) | красота, искусство, удовольствия; создание комфорта (парикмахер, дизайнер, модельер, портной, художник, музыкант, ювелир); чувство меры — одарённость в искусствах, требующих формы/цвета; флористика, «высокая кухня», дизайн интерьеров; куртизанки/содержанки; товары — украшения, платья/ткани, цветы, ароматы, сладости, игрушки. |
| **Марс** (73–74) | военное дело, спорт, физический труд; кузнец, торговля металлами, всё, связанное с огнём/железом; хирург, массаж; ремёсла «руками» (слесарь, столяр, электрик, шофёр); опасные профессии (пожарные, МЧС, силовики); конкурентная борьба, освоение новых рынков, стартапы; криминал — разбой/бандитизм/рейдерство; товары — оружие, инструменты, крепёж. |
| **Юпитер** (73–75) | авторитет/уважение к тому, что человек воплощает; управленцы, менеджеры, представители власти (особо законодательной ветви); идеологи, культура, университетские преподаватели, учёные; религия/служители культа (реже); закон/право — но только адвокаты/нотариусы; крупногабаритные/брендовые товары, оптовая торговля, предметы роскоши/культа; антиквариат (как инвестиция). |
| **Сатурн** (75–76) | высшая контролирующая/наказывающая/запрещающая форма власти; чиновники, исполнительная ветвь, надзор; современные судьи и прокуратура; аудитор, инспектор, контролёр; земля как товар, сельское хозяйство, минералы; строительный бизнес, девелопмент; консерваторы/государственники; товары — кожа, старые вещи, рабочая одежда, свинец/цинк. |
| **Уран** (76–77) | авиация/космос, высокотехнологичное производство, IT, рационализация, изобретательство, инновации; телевидение, программирование (с Меркурием); наука/эксперименты; астрология; «неформатные»/нестандартные ремёсла; товары — высокотехнологичная/необычная электроника, гаджеты, автозапчасти. |
| **Нептун** (77–78) | продукты химпроизводства («вещество/жидкость/субстанция»): нефтепродукты, краски, клей; аптека/фармацевтика; наркотики; крепкие спиртные напитки и табак (как товар); море/морепродукты/дайвинг; кино/фотодело; экология, психология; «коммерческая интуиция»/инсайдерская информация; бизнес на иллюзиях/обмане, контрафакт/контрабанда, «гламурные» товары. |
| **Плутон** (78–79) | системы, переработка, процент с оборота; финансовая/банковская/ростовщическая деятельность; крупные машиностроительные производства полного цикла; переработка (нефтепродукты, обогащение руды, «отмывание»); монополия/власть денег/спецслужбы; коррупция; торговля вооружением; магические/экстрасенсорные услуги, суггестия/гипноз, «тренинги личностного роста». |

### 2.2 House → income mode (pp. 93–97; «денежные» дома pp. 282–291)

| House | Meaning for proforientation |
|---|---|
| **X** (96) | топ-менеджмент, репутация, признание, награды, способность создать бренд/основать дело; власть/официальные должности. «Главный дом успеха в обществе»; успех → автоматически деньги. |
| **II** (93) | личное предпринимательство, «работа на себя»; конвертация таланта в деньги напрямую; доход с «потолком» (ограничен личным трудом). |
| **VI** (95) | работа по найму (контракт, фиксированный доход, соцпакет); подчинённые, HR, сфера обслуживания; творческой свободы нет. |
| **VIII** (95) | совместное/коллективное имущество, долги/кредиты; финансовый/банковский/страховой бизнес; инвестиции в чужое дело; криминал/форс-мажор. «Учитывать только при очень удачных сочетаниях.» |
| (I) (93) | планеты I дома + управитель = врождённые склонности/способности (= stage-2(а)); без связи с II/X — трудно монетизировать. |

### 2.3 Sign-narrowing rule (stage 5, p. 296)

Worked in the book on Марс-упр.X в V: planet→field, then SIGN refines. Examples (p. 296):
Марс в **Льве** → спорт с сольными выступлениями/артистизмом (+ Лев = спина → гребля и т.п.);
Марс в **водном знаке** → водный спорт / у воды / моряк; Марс в **Рыбах** → крепкие спиртные
напитки. Venus is «ленивая» — её успех на «умении нравиться», не на преодолении, поэтому
Венера-сигнификатор тяготеет к сцене/подиуму/кулинарии/искусству, не к борьбе/спорту (p. 296).
**Rule for Phase B ruleset: (planet domain) ∩ (sign element/theme) ∩ (house income-mode).**

---

## 3. Unusual-factor definitions (for Phase A core)

### 3.1 Дорифорий / Возничий — **DEFINITION CLOSED by golden anchor** (flag for Marina)

**Not defined in this book.** Used only in the algorithm (printed p. 294) and the Банкир table
(p. 302). Printed p. 290 area («в старой астрологии… смотрели на Оруженосца и Возничего»)
confirms these are *classical* satellite-of-the-Sun concepts Daragan assumes known.

**The Банкир table pins the exact operative rule.** In that chart: Sun 17° Libra; Daragan
assigns **Юпитер = Дорифорий** and **Нептун = Возничий**. Ecliptic longitudes:
Jupiter 14° Libra (−3° from Sun, lower longitude), Neptune 2° Scorpio (+15°, higher longitude).
Therefore Daragan's operative definition is:

- **Дорифорий** = the planet **closest BEFORE the Sun** in ecliptic longitude (oriental — rises
  before the Sun; the «last star to rise before sunrise»). → Jupiter (−3°). ✓
- **Возничий** = the planet **closest AFTER the Sun** in ecliptic longitude (occidental — rises/
  sets after the Sun). → Neptune (+15°). ✓

I re-derived this mechanically and it matches Daragan exactly (both planets). **Note for Phase A:**
Daragan's usage includes OUTER planets (Neptune qualifies) and applies no visibility-orb cap — it
is the simple nearest-before / nearest-after-Sun rule over all 10 planets. Classical Hellenistic
doryphory has stricter variants (luminaries only, within 7°/sign, aspect-based) — **flag for
Marina sign-off** that we adopt the simple Globa-school/Банкир rule, not the strict Hellenistic one.
Build: needs a signed-separation-from-Sun + nearest-each-side selector (not in core today).

### 3.2 Фигуры Джонса (ручка корзины / праща) — definition by external doctrine (flag)

**Not defined in this book** (used only at p. 294 + Банкир table p. 302, where **Луна = «ручка
Пращи»**). Standard Marc Edmund Jones planetary-pattern doctrine (the only «фигуры Джонса» in
astrology):

- **Корзина / Bucket**: 9 planets occupy one half (≈180° bowl) + 1 singleton roughly opposite =
  the **«ручка корзины» (handle)** — the focal/leverage planet.
- **Праща / Sling (a.k.a. Bundle-with-handle / «funnel» variant)**: the bulk of planets bunched
  within a tight span (≈120°) + 1 singleton opposite = the **handle of the sling** — the outlet/
  release planet.

The Банкир chart is consistent: the bulk of planets cluster in the Libra–Sagittarius arc (+ Uranus
in Pisces) and the **Moon sits roughly opposite as the singleton** → «Луна = ручка Пращи» ✓.
**Build (Phase A):** a chart-shape detector over the 10 longitudes (largest empty arc → bowl vs
bundle vs other; singleton-opposite → handle). The memo's `Domain.Stellium` is NOT reusable (it
counts per-house, not 360° distribution). Pattern recognition is partly subjective at the
boundaries — implement the clear bucket/sling cases, flag borderline. **Flag for Marina:** confirm
that only the handle planet (not the whole figure) feeds stage-2(ж).

### 3.3 Благоприятные неподвижные звёзды — **OPEN QUESTION (no list in book)**

**There is NO curated benefic-star list in this book.** Full-text search: «благоприятные звёзды»
appears at the algorithm step (p. 294) and in the elections discussion (printed pp. 209–211 area),
where Daragan (a) names only «королевские звёзды» with **Regulus** as the example («Регул на
Юпитере» in the Alphabet Inc. election), (b) explicitly scopes benefic stars to **elections**
(«их епархия — элекции для городов / корпораций / мостов / партий»), and (c) for призвание (p. 300)
says only «на одной из астрологически значимых звёзд» without enumeration. The book's own reading
list recommends **Vivian Robson** and **Oskar Hofman** fixed-star monographs (back-matter) — the
implicit source.

**Consequence for Phase A:** the stage-2(з) factor cannot be sourced from Daragan's book. Options:
(1) ship Phase A without (з) (the other 7 ability factors + repeat-count are sufficient — Банкир
validated without (з) carrying the decision); (2) build a small curated list (royal stars Regulus/
Aldebaran/Antares/Fomalhaut + Robson's «fortunate» stars) **with Marina's explicit approval**, not
invented by us (TZ forbids inventing factors). **Recommend (1) for Phase A, (2) as a flagged
later increment.** This is the one genuine open question.

---

## 4. Manual algorithm run — Marina (person_id=4)

Source: `data/astro.db`, consultation 15 `facts_json.natal_chart` (Placidus). Marina: 1989-03-22,
05:34 Europe/Moscow, Ковров (56.36N, 41.31E). Asc **7° Aquarius**, MC **20° Sagittarius**.
Natal (engine-computed): Sun 1° Aries (I, exalt), Moon 28° Virgo (VII), Mercury 18° Pisces (I,
detr+fall), Venus 27° Pisces (I, exalt), Mars 6° Gemini (III), Jupiter 1° Gemini (II, detr),
Saturn 13° Capricorn (XI, domicile), Uranus 5° Capricorn (X), Neptune 12° Capricorn (XI),
Pluto 14° Scorpio (VIII R, domicile).

**Method cross-check:** the engine's own dignity/elevation/aspect-harmony classifications
(`classifications` block) match my hand-derivation (Sun/Venus exalt, Saturn/Pluto domicile,
Mercury detr+fall, Jupiter detr, elevation set above horizon). Doryphory rule applied per § 3.1
(Дорифорий = Venus, closest before Sun −3.5°; Возничий = Jupiter, closest after +60.3°). Cusp
signs: I Aqu, II **Tau**, III Gem, IV Gem, V Can, VI **Can**, VII Leo, VIII **Sco**, IX Sag,
X **Sag**, XI Cap, XII Cap. Intercepted: Aries+Pisces → house I; Virgo+Libra → house VII.

### Stage 1–2 table (counts r/a/total)

| Planet | Realization (stage 1) | Abilities (stage 2) | r/a/Σ |
|---|---|---|---|
| **Jupiter** | упр.X, пл.II, c/h упр.II, c/h упр.VI, c/h упр.VIII | Возничий, c/h Солнце | 5/2/**7** |
| **Venus** | c/h упр.X, упр.II | пл.I, Дорифорий, обит/экз, c/h Солнце | 2/4/**6** |
| **Sun** | c/h упр.X, c/h упр.II, c/h упр.VIII | пл.I, обит/экз | 3/2/**5** |
| **Mars** | c/h упр.X, упр.VIII | упр.солн.знака, c/h Солнце | 2/2/**4** |
| **Mercury** | рец.X, рец.II, c/h упр.VIII | пл.I | 3/1/**4** |
| **Uranus** | пл.X | упр.Асц, элевация | 1/2/3 |
| **Saturn** | c/h упр.VIII | упр.Асц, обит/экз | 1/2/3 |
| **Pluto** | упр.VIII, пл.VIII | обит/экз | 2/1/3 |
| Moon | c/h упр.X, упр.VI | — | 2/0/2 → excluded |
| Neptune | c/h упр.VIII | — | 1/0/1 → excluded |

(«рец.» = mutual reception by domicile/exaltation; «c/h» = conjunction OR harmonious aspect.
Mercury–Pluto, Mercury–Saturn etc. drive Mercury's reception rows: Mercury in Pisces ↔ rulers.)

### Stage 3 — filter
Planets in BOTH columns: Sun, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Pluto.
Excluded (empty abilities column → «нежелательно»): **Moon, Neptune**.

### Stage 4 — top 2–3 combos
1. **Jupiter — упр.X в II доме (Gemini)** — Σ7, X-tier. Ruler of the success-house (X) sitting in
   the self-employment house (II); harmonious to rulers of II/VI/VIII; Возничий; harmonious to Sun.
   **Per Daragan's rule («лучшая планета связана с X → оптимальный вариант») this is the optimum.**
2. **Venus — упр.II, в I доме (Pisces, exalt, Дорифорий)** — Σ6, densest *abilities* column =
   strongest natural talent; rules the self-employment house.
3. **Sun — в I доме (Aries, exalt)** — Σ5; charismatic/creative personality, harmoniously tied to
   the money-house rulers.

### Stage 5 — draft interpretation (planet ∩ house ∩ sign)
- **Jupiter упр.X в II, Gemini** → success realized as **expertise-based private practice**:
  teaching, consulting, methodology, expert/authority work, publishing, law (адвокат/нотариус) —
  «respectable» knowledge work run for oneself (II). Gemini narrows toward word/information/
  intermediation. **Caveat (p. 67):** Jupiter is in **detriment in Gemini** — works via its strong
  house/aspect support, but with the typical Jupiter-in-Gemini tilt to over-generalisation /
  intellectual trust; not a «clean» X-planet, so II-framing (own practice) suits it better than a
  high-pressure pure-X corporate role.
- **Venus упр.II, в I, Pisces (exalt)** → monetizing a **Venusian gift** (art / aesthetics / design /
  beauty / care / music) as self-employment; Pisces refines toward refined/empathic/imaginative
  expression. Strongest *talent* signal in the chart.
- **Sun в I, Aries (exalt)** → a charismatic, self-starting, **public-facing / creative** dimension
  (personal brand, «быть на виду») supporting the above.

**Synthesis:** Marina's optimal proforientation is **expertise-led private practice (Jupiter:
X-via-II)** — consultant / teacher / methodologist / author — supported by a strong **Venus**
talent (art/aesthetics/care, self-employed) and a **charismatic creative Sun**. This is internally
coherent and matches her real role (astrologer-consultant: Jupiter = knowledge-authority, own
practice). **Призвание check (p. 300):** condition (2) is satisfied for the supporting planets
(Sun is the Sun; Venus/Sun in I), but the #1 planet (Jupiter) is not Sun/Asc-ruler/conjunct-them
and is in detriment, so a strong «призвание» claim is NOT warranted — present talent, not an
imposed calling. (Honours the DoD: do not promise призвание where the chart is equivocal.)

---

## 5. Golden anchor — «Карта 11. Банкир» (printed pp. 300–307) — **PASS**

Postановка (p. 301): «стоит ли человеку менять привычный профиль деятельности, и если да — на что».
Chart (Карта 11, p. 301) transcribed from the PDF image: Asc **7° Aquarius**, MC ~25° Sagittarius;
Sun 17° **Libra** (VIII), Mercury 8° Libra (VIII), Mars 11° Libra (VIII), Jupiter 14° Libra (VIII),
Neptune 2° Scorpio (IX), N.Node 17° Scorpio (IX), Venus 1° Sagittarius, Saturn 11° Sagittarius (X),
Uranus 16° Pisces (I), Moon ~5° Taurus (II), Pluto ~Libra/Virgo (VII). VIII cusp **Libra**
(→ Venus rules VIII), Scorpio in IX. (Initial misread of the cluster as Scorpio was corrected by
Daragan's own «упр.солн.знака = Venus», which forces Sun-in-Libra.)

**Daragan's published stage-1/2 table (p. 302)** vs **my mechanical re-run:**

| Claim (Daragan p. 302) | My algorithm | Match |
|---|---|---|
| упр.X = Jupiter | Jupiter (Sag on X cusp) | ✓ |
| упр.II = Mars | Mars (Aries on II cusp) | ✓ |
| упр.VI = Moon | Moon (Cancer on VI cusp) | ✓ |
| упр.VIII = Venus | Venus (Libra on VIII cusp) | ✓ |
| планета X = Saturn | Saturn in X | ✓ (Daragan-stated placement) |
| Луна = Пл.II + упр.VI | Moon in II, rules VI | ✓ |
| планеты VIII = Sun, Mercury, Mars, Jupiter | all four in VIII | ✓ |
| **Pluto = NOT a significator of any of the 4 houses** | Pluto absent from all 4 | ✓ |
| упр.солн.знака = Venus | Sun in Libra → Venus | ✓ |
| упр.Асц = Uranus, соупр.Асц = Saturn | Asc Aquarius → Uranus + Saturn | ✓ |
| **Дорифорий = Jupiter** | closest planet before Sun (−3°) = Jupiter | ✓ |
| **Возничий = Neptune** | closest planet after Sun (+15°) = Neptune | ✓ |
| Луна = ручка Пращи | Moon singleton opposite the bunch | ✓ (consistent) |

**Daragan's filtration (pp. 302–303):** 7 of 10 planets filled (Uranus has only abilities, Pluto
empty, Neptune only realization); 5 «densely filled». Abilities-top-3: **Jupiter, Луна, Меркурий**.
Realization «вершина»: Jupiter (упр.X), Saturn (пл.X), Mars (упр.II), Луна (пл.II), Venus (упр.VIII).

**Daragan's selection (pp. 303–304):** Jupiter (упр.MC в VIII) vs Луна (упр.VI в II) → **Jupiter
wins** (ruler of MC; in II via conjunction with упр.II; mutual reception with Saturn = упр.X; harm.
to Asc-rulers Uranus & Saturn). **Interpretation (pp. 304–307):** упр.X в VIII = «карьера через
сферу VIII дома» (finance/banks/power structures); significator Jupiter → manager/executive/
лоббист/lawyer-in-financial-law (NOT emergency/criminal — IX absent, no problem aspects, benefic
Jupiter is law-abiding). **Real outcome:** the native was an economist who became a де-факто banker
running collective finances — a manager/гарант/медиатор, NOT an accountant/analyst. **Daragan's
teaching point (p. 307):** Pluto (which beginners assume rules finance) is NOT a significator here —
«название профессии = только вывеска; суть важнее».

**Verdict:** my algorithmic conclusion (Jupiter, упр.X в VIII, financial-management/banking via the
VIII income-mode, benefic → legitimate) **matches Daragan's published narrative conclusion.**
**Method fidelity is proven on a real worked example, not just on math.**

---

## 6. Reuse-vs-build inventory (verified by reading the core, 2026-06-07)

Read: `Domain/Dignities.hs`, `Domain/StrengthAnalysis.hs`, `Domain/Aspects.hs`,
`Domain/Houses/Placidus.hs`, `Domain/Ascendant.hs`, `Domain/Planets.hs`, `Domain/Zodiac.hs`,
`Domain/Stellium.hs`, `Domain/Directions.hs` (§ house-set derivation), `Domain/Types.hs`.
Greenfield confirmed: no existing vocation/proforientation code anywhere.

| Method factor | Stage | Verdict | Where / what to build |
|---|---|---|---|
| Управитель дома (sign-on-cusp → ruler, incl. intercepted) | 1а | **REUSE pattern, thin BUILD** | `Dignities.rulersOfSign` + the cusp-rulership loop already implemented in `Directions.housesForPlanet` (lines 274–286). Expose a `rulersOfHouse :: Int -> HouseCusps -> [Planet]` (cusp sign + intercepted-sign rulers via `Houses.Placidus.interceptedSigns`). |
| Планеты в доме | 1б | **REUSE** | `Houses.Placidus.planetInHouse`. |
| Соединение / гармоничный аспект с управителем | 1в | **REUSE** | `Aspects.findAspects` + `aspectsForPlanet` + `filterHarmonious`; **note: Conjunction is classified Neutral**, so «соединение OR гармоничный» needs conjunction-detection (aspectType==Conjunction) UNION harmonious-filter — both available, just combine. |
| **Взаимная рецепция** (domicile/exaltation) | 1г | **BUILD (absent)** | No reception anywhere in core (grep: 0 hits). Build `mutualReception p q = signOf p ∈ (domicileSigns q ∪ {exaltationSign q}) ∧ signOf q ∈ (domicileSigns p ∪ {exaltationSign p})` from existing `Dignities` tables. (Daragan also mentions «смешанная взаимная рецепция» in the Банкир table — mixed domicile×exaltation; the formula above already covers the union.) |
| Управитель Асц + планеты в I доме | 2а | **REUSE** | `Ascendant.ascendantZodiacPosition` → `rulersOfSign`; `planetInHouse == 1`. |
| **Дорифорий / Возничий** | 2б | **BUILD (absent)** | No oriental/occidental/satellite helper. Build signed-separation-from-Sun + nearest-before / nearest-after selector over 10 planets (rule pinned in § 3.1). `Planets.shortestArc` is unsigned — need a signed variant. |
| Планеты в обители / экзальтации | 2в | **REUSE** | `Dignities.isDomicile`, `isExaltation`. |
| Управитель солнечного знака | 2г | **REUSE (compose)** | `rulersOfSign (signOf Sun-longitude)`. No named convenience today — trivial wrapper. |
| Соединение / гармония с Солнцем | 2д | **REUSE** | `aspectsForPlanet Sun` + conjunction/harmonious filters. |
| Планета в элевации (выше всех) | 2е | **REUSE (pick mode)** | `StrengthAnalysis` has `InElevation` with `ElevationMode` (`AboveHorizon` houses 7–12, or `AngularPriority` MC≤10°). Daragan wants the SINGLE highest = nearest-to-MC among above-horizon. Use `Houses.Placidus.isAboveHorizon` + min-arc-to-`hcMc`. Existing `checkElevation` is a boolean per planet, not a single-winner selector → thin BUILD on top of reused predicates. |
| **Фигура Джонса (ручка корзины / праща)** | 2ж | **BUILD (absent)** | No 360°-distribution / chart-shape detector. `Stellium.detectStellia` is per-house, NOT reusable. Build bowl/bundle + singleton-handle detector over the 10 longitudes (§ 3.2). |
| **Благоприятные звёзды** | 2з | **BUILD + OPEN list** | No fixed-star catalog in core (Types.hs/bridge mention precession plumbing only, no curated list). List itself is the open question (§ 3.3) — needs external source + Marina approval. |
| Таблица 4×факторы, фильтрация, ранжирование, топ-2–3 | 1–4 | **BUILD (new `Domain.Vocation`)** | Aggregation + repeat-count + house-tier ranking. Pure, no I/O; takes resolved natal positions + cusps (как `runReturns`). All значимость-логика here (AST-ARCH-1). |
| Правила толкования (planet→domain, sign→narrow, house→mode) | 5 | **BUILD as data** | `packages/rulesets/vocation/*` (§ 2), Марина правит. NOT code. |

**Specifically verified per task ask:**
- **Mutual reception — BUILD** (absent; formula above; covers Daragan's «смешанная» variant).
- **House-ruler accessor — thin BUILD** (the exact cusp+intercepted rulership loop already exists
  inside `Directions.housesForPlanet`; lift/expose the inverse direction as `rulersOfHouse`).
- **Ruler-of-solar-sign — REUSE/compose** (`rulersOfSign (signOf Sun)`; trivial wrapper).

---

## 7. Conventions (for Phase A)

- **Соединение vs гармоничный аспект:** Conjunction = `Neutral` in core; «соединение или гармоничный»
  must be coded as (Conjunction) ∪ (Harmonious), not Harmonious alone. Quincunx is Harmonious in
  this engine (`Aspects.classifyNature`) — confirm with Marina whether quincunx should count for
  stage-1в/2д (Daragan «Транзиты» treats it harmonious; defaulting to include is consistent).
- **Rulership:** dual modern+traditional (`rulersOfSign` returns a list — e.g. Scorpio → [Pluto,
  Mars]; Aquarius → [Uranus, Saturn]; Pisces → [Neptune, Jupiter]). A planet counts as house-ruler
  if it is ANY ruler of the cusp sign OR of an intercepted sign in that house (matches the Банкир
  «соупр.Асц = Saturn» dual-ruler handling).
- **Mutual reception:** by domicile OR exaltation, symmetric (both planets in each other's dignity
  sign). Mixed domicile×exaltation allowed (Daragan «смешанная взаимная рецепция»).
- **Дорифорий/Возничий:** nearest planet before / after the Sun by ecliptic longitude over all 10
  planets, no orb cap (Банкир-validated). Flag: classical strict variants differ — Marina sign-off.
- **Элевация:** single highest = min arc to MC among above-horizon planets (Placidus houses 7–12).
- **Repeat-count:** a planet appearing in multiple lists is «особо значимо» (p. 294) — primary
  ranking signal alongside house-tier (X>II>VI; VIII gated).
- **VIII gate:** include VIII only «при очень удачных сочетаниях / по реальному контексту» (p. 295) —
  low default weight / explicit gate.
- **Призвание:** ≥2 of 3 conditions (p. 300); never emit «призвание» otherwise (DoD).

---

## 8. STOP-gate result & open questions

**STOP-gate: PASS — proceed to Phase A.** The 5-stage method is complete and unambiguous; the
golden anchor (Банкир) reproduces Daragan's published table and conclusion; reuse-vs-build is fully
mapped; manual run on Marina yields a coherent, real-life-consistent top-2–3.

**Open questions / flags (none block the Phase-A realization engine):**
1. **(OPEN) Благоприятные звёзды list** — not in Daragan's book; needs external curated source
   (royal stars + Robson/Hofman) + **Marina approval**, or ship Phase A without stage-2(з).
   Recommend: ship without (з) first; add as flagged increment. *(TZ: do not invent factors.)*
2. **(FLAG) Дорифорий/Возничий rule** — pinned by Банкир (nearest-before/after-Sun, all planets);
   confirm with Marina we use this simple rule, not strict Hellenistic doryphory.
3. **(FLAG) Фигуры Джонса** — defined by external Jones doctrine (book doesn't define); confirm
   bucket-handle / sling-handle cases + that only the handle feeds stage-2(ж); borderline shapes flagged.
4. **(MINOR) Quincunx** in stage-1в/2д — Harmonious in this engine; confirm inclusion with Marina.
5. **(DATA) Additional golden charts** — Банкир is one published worked example; recommend Marina
   supply 1–2 more reference proforientation разборы for Phase-A golden tests beyond Банкир + Marina.

---

## Appendix — artefacts

- Marina natal data: `data/astro.db`, consultations 13/14/15 (person 4); used cons. 15
  `facts_json.natal_chart` (Placidus, julian_day 2447607.607).
- Book pages read (PDF, offset +1): significators 63–80 + 207–213; houses 94–98; algorithm 293–301;
  призвание + Банкир разбор 301–312; тематический указатель 681–682 (confirms no separate index
  entries for Дорифорий/Возничий/Джонс/звёзды); full-text grep for those terms.
- Analysis tooling (scratch, not committed, `/tmp`): mechanical re-run of stages 1–4 for Marina and
  for Банкир (golden validation). Dignity/ruler tables mirror `Domain/Dignities.hs` exactly.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
