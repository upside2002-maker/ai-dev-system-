# HANDOFF: worker → tl — useful-people-human-readability-polish (Stages 1-5 implementation)

- Status: closed
- Date: 2026-05-24
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-24-useful-people-human-readability-polish.md
- Predecessor (closed): HANDOFFS/archive/2026-05-24-worker-to-tl-intercepted-sign-rulership-fix-impl.md
- Product repo status: committed (`ba806d5` on `main`, backup pushed `d43e05e..ba806d5`)

## Summary

Tier B− text-polish follow-up to the just-closed Path 1 Intercepted-Sign Rulership Fix. Bug 1 (triple-«и» in sign lists) and Bug 2 (astrology jargon в 1st-house planet phrases) both fixed. `[:2]` cap kept + explicit test (clarification 2 = (a)); 3-sentence template untouched (clarification 3 = (a)); legacy dict deleted (clarification 4 = (a)).

**Pytest**: 697 → **705 passed + 3 skipped + 0 failed** (+8 net new tests). 0 xfailed.
**Cabal**: clean.
**Product baseline**: `d43e05e` → product commit `ba806d5`.
**STOP triggers fired**: 0.

### 5 Worker-drafted planet phrases (user confirmation needed at closure)

Per clarification 1 = (a), Worker drafted Moon/Jupiter/Saturn/Uranus/Neptune in the same spirit as user-given 5 (no jargon, описание через стиль присутствия / тип энергии / на что эти люди опираются, начинается с «люди …»):

| Planet  | Drafted phrase (verbatim) |
|---|---|
| Moon    | «люди тёплые, чуткие, умеющие создать ощущение дома и заботы» |
| Jupiter | «люди широкие, оптимистичные, дающие чувство смысла и перспективы» |
| Saturn  | «люди надёжные, выдержанные, умеющие держать структуру и слово» |
| Uranus  | «люди независимые, нестандартные, открывающие неожиданный угол зрения» |
| Neptune | «люди чувствующие, творческие, умеющие услышать невысказанное» |

User-given 5 (verbatim, untouched):

| Planet  | Phrase |
|---|---|
| Sun     | «люди яркие, самостоятельные, с сильным личным центром» |
| Mercury | «люди лёгкие в общении, быстрые на мысль, помогающие договориться и найти нужные слова» |
| Venus   | «люди мягкие, эстетичные, умеющие сглаживать острые углы» |
| Mars    | «люди инициативные, прямые, готовые действовать» |
| Pluto   | «люди сильные, собранные, умеющие проходить через кризисы» |

## Stage 1 — `_join_sign_people` helper

`services/api-python/app/pdf/synthesis_themes.py:955-996` (+42 lines, new helper) — joins list of sign codes into human-readable Russian list. 0 / 1 / 2 / 3+ branches exactly per TASK Stage 1 spec.

Applied in `_useful_people_block` at axis 1 sentence (was lines 1618-1634) and axis 7 sentence (was lines 1638-1654): single call `_join_sign_people(asc_signs)` / `_join_sign_people(dsc_signs)` replaces the prior two-branch `{cusp_label} и {intercepted_join}` logic. Net delete in `_useful_people_block`: −19 lines / +6 lines.

## Stage 2 — `_FIRST_HOUSE_PLANET_PEOPLE_RU` full rewrite

Same file, lines 922-953 (full delete + replace, no `_LEGACY` rename — per clarification 4 = (a)). git blame trace preserved via `git show d43e05e:services/api-python/app/pdf/synthesis_themes.py:927-938`.

10 new entries (5 verbatim from user + 5 Worker-drafted — see Summary table above). All 10 in the same human-quality spirit; no astrology jargon («лунный», «юпитерианский», «сатурнианский», «нептунианский» — все absent).

## Stage 3 — `[:2]` cap kept + explicit test

`synthesis_themes.py:1671` `for planet in first_house_planets[:2]:` UNTOUCHED.

New test `test_useful_people_caps_first_house_at_two` (tests/test_useful_people_polish.py) explicitly pins the cap using Marina (Sun + Mercury + Venus в Дом 1) — asserts Sun + Mercury phrases present, Venus phrase «мягкие, эстетичные» absent. Any future cap change is now deliberate (test must be updated).

## Stage 4 — 3rd sentence structure kept

`_useful_people_block` 3-clause template («Также в этом году хорошо рядом — A; B; и солнечные {sun_label} по той же оси.») UNTOUCHED per clarification 3 = (a). Only inner phrases A/B change naturally via Stage 2 dict rewrite — no structural edit.

## Stage 5 — Tests

### 5.1 — Join helper unit tests (NEW `tests/test_useful_people_polish.py`)

5 tests for `_join_sign_people`:

* `test_join_sign_people_empty` — `[]` → `""`.
* `test_join_sign_people_one` — `["Cancer"]` → `"Раки"`.
* `test_join_sign_people_two` — `["Cancer", "Leo"]` → `"Раки и Львы"`.
* `test_join_sign_people_three` — `["Aquarius", "Pisces", "Aries"]` → `"Водолеи, Рыбы и Овны"`.
* `test_join_sign_people_four` — `["Aquarius", "Pisces", "Aries", "Taurus"]` → `"Водолеи, Рыбы, Овны и Тельцы"` (locks 4+ pattern).

### 5.2 — Olga regression updated

`tests/test_consultation_summary_evidence.py::test_olga_useful_people_block_present`:

* Required substring changed: «марсианск» → **«инициатив»** (new Mars wording).
* Forbidden substring tightened: «Тельцы» → «Тельц» (covers «Тельцы»/«Тельцов»).
* Defensive forbidden added: « и Раки и», « и Козероги и» (canary — Olga has single-sign axes so should never appear, but locks `_join_sign_people` regression).
* Existing required («Раки» / «Козероги» / «солнечные Раки») + forbidden («Овны» / «Львы» / «Скорпион» / «солнечное присутствие» / «меркурианская лёгкость») all preserved.

### 5.3 — Marina regression (NEW)

Marina fixture: synthetic, built from TASK § Context cusps `[328.79, 35.71, 63.01, 80.25, 95.44, 113.48, 148.79, 215.71, 243.01, 260.25, 275.44, 293.48]` + natal Sun 1.45° / Mercury 348.88° / Venus 357.93° (all `house_placidus=1`). Synthetic chosen over DB-load для test determinism (no DB dependency, like Olga's `_olga_facts_extended()` pattern). Documented in test docstring.

* `test_marina_useful_people_block_axis_signs` — required «Водолеи, Рыбы и Овны» + «Львы, Девы и Весы» (Oxford-style join); forbidden «Водолеи и Рыбы и Овны» + «Львы и Девы и Весы» (legacy triple-«и»).
* `test_marina_useful_people_block_first_house_planets` — required «люди яркие, самостоятельные» (Sun) + «лёгкие в общении» (Mercury) + «солнечные Овны» (Sun-axis preserved); forbidden 6 jargon phrases (солнечное присутствие / меркурианская лёгкость / венерианский вкус / плутоническая глубина / сатурнианская выдержка / юпитерианская широта).

### 5.4 — Calibrated 6 cases regression

Smoke-test via direct `_useful_people_block(facts)` on each expected.json fixture:

| Case | lines | jargon leak | triple-«и» | rendered head |
|---|---|---|---|---|
| 02-maksim-2025-2026 | 3 | none | none | «Вам опорно рядом Скорпионы — люди вашей собственной оси…» |
| 03-artem-2025-2026 | 3 | none | none | «Вам опорно рядом Раки — люди вашей собственной оси…» |
| 05-ekaterina-2025-2026 | 3 | none | none | «Вам опорно рядом Водолеи и Рыбы — люди вашей собственной оси…» |
| 07-mariya-2025-2026 | 2 | none | none | «Вам опорно рядом Девы — люди вашей собственной оси…» |
| 08-natalya-2025-2026 | 2 | none | none | «Вам опорно рядом Девы — люди вашей собственной оси…» |
| 10-danila-2025-2026 | 3 | none | none | «Вам опорно рядом Стрельцы — люди вашей собственной оси…» |

0 PDF regression, 0 «Полезные люди» crash. Все existing calibrated outer-card golden-rule tests passing (unrelated path).

Forbidden jargon scan (cross 9 phrases): 0 hits across all 6 calibrated cases.

## Fresh PDF renders (verbatim from rendered PDF)

Both Olga consultation 12 + Marina consultation 15 PDFs invalidated (`UPDATE consultations SET pdf_path=NULL`) and re-rendered via running API server on port 8000.

* `curl /api/v1/consultations/12/pdf` → HTTP 200, 161 714 bytes → `/tmp/olga-12-polished.pdf`.
* `curl /api/v1/consultations/15/pdf` → HTTP 200, 168 805 bytes → `/tmp/marina-15-polished.pdf`.

### Olga rendered «Полезные люди» block (verbatim, pdftotext -layout)

```
Вам опорно рядом Раки — люди вашей собственной оси, через которых год даёт опору и
понятный контур.
По партнёрской оси — Козероги: люди структурные, договороспособные, готовые разделять
ответственность.
Также в этом году хорошо рядом — люди инициативные, прямые, готовые действовать; и
солнечные Раки по той же оси.
```

Acceptance: «Раки» ✓, «Козероги» ✓, «инициатив*» (new Mars) ✓, «солнечные Раки» ✓. Forbidden absent: «Овны» / «Львы» / «Скорпион» / «Тельц» / «солнечное присутствие» / «меркурианская лёгкость» / «марсианская инициатива» — все ✓.

### Marina rendered «Полезные люди» block (verbatim, pdftotext -layout)

```
Вам опорно рядом Водолеи, Рыбы и Овны — люди вашей собственной оси, через которых год
даёт опору и понятный контур.
По партнёрской оси — Львы, Девы и Весы: люди структурные, договороспособные, готовые
разделять ответственность.
Также в этом году хорошо рядом — люди яркие, самостоятельные, с сильным личным
центром; люди лёгкие в общении, быстрые на мысль, помогающие договориться и найти нужные
слова; и солнечные Овны по той же оси.
```

Acceptance: «Водолеи, Рыбы и Овны» (Oxford-style axis 1) ✓, «Львы, Девы и Весы» (Oxford-style axis 7) ✓, «люди яркие, самостоятельные» (Sun) ✓, «лёгкие в общении» (Mercury) ✓, «солнечные Овны» (Sun-axis preserved) ✓. Forbidden absent: legacy triple-«и» / «солнечное присутствие» / «меркурианская лёгкость» / «венерианский вкус» — все ✓. Venus dropped silently by `[:2]` cap ✓ (test_useful_people_caps_first_house_at_two pins).

## Verification

* `cd core/astrology-hs && cabal build` → `Up to date` (clean).
* `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` → **705 passed, 3 skipped, 0 failed** (was 697 + 3 + 0; +8 net new tests as planned).
* Fresh renders: Olga 12 + Marina 15 confirmed verbatim above.
* `git status --short` → clean (intended changes committed).

## STOP triggers (per TASK § STOP triggers)

* Worker fabricates phrase для planet, которая не в natal Дом 1 → **NOT FIRED** (5 user-given + 5 Worker-drafted entries describe planet archetypes via human qualities; only emitted via dict lookup keyed by `_natal_first_house_planets(facts)` — no synthesis without evidence).
* Worker touches Haskell core → **NOT FIRED**.
* Worker modifies `rulership_houses.py` → **NOT FIRED**.
* Worker modifies `_OUTER_CARD_FACTS` → **NOT FIRED**.
* Worker breaks Olga Path 1 acceptance (forbidden phrase reappears OR required phrase disappears) → **NOT FIRED** (verified verbatim above).
* Worker breaks calibrated 6-case PDF render → **NOT FIRED** (6/6 cases verified clean above).
* Worker introduces LLM → **NOT FIRED**.
* Worker copies Daragan verbatim → **NOT FIRED** (5 Worker-drafted phrases composed in same human-qualities spirit as user-given 5; no Daragan source consulted).

## Self-review checklist

- [x] Join helper handles 0/1/2/3/4+ signs (5 unit tests for 5 cases).
- [x] Marina rendered: «Водолеи, Рыбы и Овны» + «Львы, Девы и Весы» (Oxford-style).
- [x] Marina rendered: «люди яркие, самостоятельные» (Sun) + «лёгкие в общении» (Mercury), NO Venus phrase (cap=2).
- [x] Marina rendered: NO «солнечное присутствие», NO «меркурианская лёгкость».
- [x] Marina rendered: «солнечные Овны по той же оси» (preserved).
- [x] Olga rendered: «Раки» + «Козероги» + «инициатив*» + «солнечные Раки» (preserved with new Mars phrasing).
- [x] Olga rendered: all original forbidden phrases still absent.
- [x] 5 drafted planet phrases (Moon / Jupiter / Saturn / Uranus / Neptune) quoted verbatim в HANDOFF (Summary table).
- [x] `[:2]` cap test passes (verifies Venus dropped for Marina).
- [x] Calibrated 6 cases: 0 PDF regression, 0 «Полезные люди» crash.
- [x] pytest 705 (= 697 + 8 new). 0 failed.
- [x] cabal clean.
- [x] No engine / DB / `_OUTER_CARD_FACTS` / Daragan / LLM / fabrication.

## Artifacts

- branch:           main (product) / master (overlay)
- product commit:   `ba806d5` (this implementation)
  - Predecessor:    `d43e05e` (Intercepted-Sign Rulership CLOSED)
- overlay commit:   (created in same submit)
- tests:            pytest **705 passed + 3 skipped + 0 failed** (+8 new)
- Files product:
  * `services/api-python/app/pdf/synthesis_themes.py` — +84/-31 (join helper + axis sentences refactor + `_FIRST_HOUSE_PLANET_PEOPLE_RU` full rewrite + comments)
  * `services/api-python/tests/test_consultation_summary_evidence.py` — +35/-13 (Olga regression updated: new Mars substring + defensive triple-«и» canary)
  * `services/api-python/tests/test_useful_people_polish.py` — NEW +248 (5 join unit tests + 2 Marina regression + 1 cap test)

## Reviewer-Ready

Reviewer **optional** per TASK § Reviewer (Tier B− text polish, no astrology semantics change). Worker self-review confirmed above.

**TL action needed**: user confirmation for 5 Worker-drafted planet phrases (Moon / Jupiter / Saturn / Uranus / Neptune — quoted verbatim в Summary table above) per clarification 1 = (a). If user requests changes, single-edit cycle on the dict; otherwise close as-is.

## Next step

TL surfaces 5 Worker-drafted phrases to user for confirmation. On user ack → submit-task.sh. On user wording delta → minimal edit cycle (Worker re-engage with delta scope only — 5 dict entries, no other touch).
