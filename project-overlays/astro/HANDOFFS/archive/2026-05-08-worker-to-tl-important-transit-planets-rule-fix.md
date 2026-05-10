# HANDOFF: worker → tl — important-transit-planets-rule-fix

- Status: closed
- Date: 2026-05-08 23:16
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code (Worker subagent, separate from TL session)
- Model: Claude Opus
- Role mode: Worker (subagent isolation per TL graded rule 2026-05-06, Mode strict — Tier A)
- TASK: project-overlays/astro/TASKS/2026-05-08-important-transit-planets-rule-fix.md

## Summary

`important_transit_planets` rewritten под Marina's 5 product rules (RulerOfAsc / RulerOfMc / KingOfAspects / RulerOfSunSign / RulerOfStelliumSign) одним atomic коммитом `7b86cf9` со всем schema-gate cascade'ом (15 files: Haskell ADT + logic + unit-test + golden-test fixture + JSON schema + TS types + 9 product golden cases + facts sample). `cabal test` 231/231 green (+2 новых теста), `pytest` 70/70 green, backup parity ✓. Oracle Marina (Соляр_5.pdf p.7) подтверждён: chart Mercury+Sun+Jupiter все присутствуют — но **chart, описанный в Marina ref, фактически соответствует case 8 (Наталья)**, не case 9 (Анастасия), как сказано в TASK title; см. § Conflicts/risks.

## Done

### Cascade files (1 atomic commit `7b86cf9`)

- `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs` — ADT extended до 5 reasons (`RulerOfAsc | RulerOfMc | KingOfAspects | RulerOfSunSign | RulerOfStelliumSign`); `InTenthHouse` removed; `identifyImportantTransitPlanets` rewritten на 5-source union с dedup+accumulate; sign-stellium detection inlined (count planets per sign, ≥3, через `Map.Map ZodiacSign Int`).
- `core/astrology-hs/test/Test/Domain/ImportantTransitPlanetsSpec.hs` — обновлён под новую ADT shape; добавлено 2 новых теста: dual-ruler exception (Asc=Aqu/MC=Sco emit обоих rulers с тем же reason) + sign-stellium emission (Aquarius stellium → Uranus+Saturn `RulerOfStelliumSign`).
- `core/astrology-hs/test/golden/synthetic-solar-1.expected.json` — regen.
- `packages/contracts/solar-computed-facts.schema.json` — enum `ImportantTransitReason` обновлён до ровно тех же 5 strings; описание уточнено про "dual rulers — same reason type, multiple planets, не отдельный type".
- `apps/web-react/src/types.ts` — TS union обновлён до 5 values.
- `packages/test-fixtures/solar-facts-sample.json` — regen (mirrors synthetic golden).
- `packages/test-fixtures/golden-cases/{01..05, 07..10}.expected.json` — regen всех 9 valid product cases.

### Build / test results

- `cabal build` — green (after change).
- `cabal test` — 231/231 (was 229; +2 новых теста: dual-ruler + sign-stellium).
- `pytest` — 70/70 (без изменений; contract-тест continues passing — `test_contracts.py` использует обобщённый `len(reasons) >= 1` без hardcode конкретных enum values, поэтому новый schema enum + regenerated fixtures совместимы).
- baseline pytest (до фикса) — 70/70.
- baseline cabal test (до фикса) — 229/229.

### 9 cases regenerated через rebuilt CLI

| Case | Asc / MC / Sun-sign | Sign-stellium | KoA | Engine output (planet → reasons) |
|---|---|---|---|---|
| 01-Ksenia (Aqu/Sag/Sco) | Sco, Lib | Venus | Venus(KoA, Stellium-Lib); Mars(SunRule-Sco, Stellium-Sco); Jupiter(MC-Sag); Saturn(Asc-Aqu); Uranus(Asc-Aqu); Pluto(SunRule-Sco, Stellium-Sco) |
| 02-Maksim (Sco/Vir/Vir) | Cap | Moon | Moon(KoA); Mercury(MC, SunSign); Mars(Asc-Sco); Saturn(Stellium-Cap); Pluto(Asc-Sco) |
| 03-Artem (Can/Aqu/Lib) | Cap | Jupiter | Moon(Asc); Venus(SunSign); Jupiter(KoA); Saturn(MC-Aqu, Stellium-Cap); Uranus(MC-Aqu) |
| 04-Valeriya (Tau/Cap/Ari) | none | Venus | Venus(Asc, KoA); Mars(SunSign); Saturn(MC) |
| 05-Ekaterina (Aqu/Sag/Pis) | none | Sun | Sun(KoA); Jupiter(MC-Sag, SunSign-Pis); Saturn(Asc-Aqu); Uranus(Asc-Aqu); Neptune(SunSign-Pis) |
| 07-Maria (Vir/Gem/Can) | Can, Cap | Sun | Sun(KoA); Moon(SunSign-Can, Stellium-Can); Mercury(Asc, MC); Saturn(Stellium-Cap) |
| **08-Natalya** (Vir/Gem/Leo) | **Sag** | Venus | **Mercury(Asc, MC); Sun(SunSign); Jupiter(Stellium-Sag); Venus(KoA)** |
| 09-Anastasia (Vir/Tau/Tau) | Tau | Sun | Sun(KoA); Mercury(Asc); Venus(MC, SunSign, Stellium-Tau) |
| 10-Danila (Sag/Lib/Leo) | Aqu | Sun | Sun(KoA, SunSign-Leo); Venus(MC); Jupiter(Asc); Saturn(Stellium-Aqu); Uranus(Stellium-Aqu) |

(Case 06 = stub, не regen.)

### Oracle (Наталья — case 8, не case 9, см. Conflicts/risks)

Marina reference `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` p.7 (не p.8 как сказано в TASK; в PDF действительно стр.7) для Натальи (1984-08-07 8:40 Москва, Asc=Дева, MC=Близнецы, Sun=Лев, стеллиум планет в Стрельце):

> 1. Транзиты Меркурия (т.к. ваш Асц в Деве и МС в Близнецах).
> 2. Транзиты Солнца (управитель солнечного знака, Солнце во Льве).
> 3. Транзиты Юпитера (скопление планет в знаке Стрельца).

После регена `golden-cases/08-natalya-2025-2026.expected.json` (NOT case 9 — TASK file имеет numbering error; chart Натальи живёт в case 8):

```
Mercury    reasons=['RulerOfAsc', 'RulerOfMc']      ← Asc=Дева ⊕ MC=Близнецы (accumulate)
Sun        reasons=['RulerOfSunSign']                ← Sun в Льве, ruler=Sun
Jupiter    reasons=['RulerOfStelliumSign']           ← Moon+Uranus+Neptune все в Стрельце (3 planets) → ruler=Jupiter
Venus      reasons=['KingOfAspects']                 ← engine rule 3 (5 aspects, max в карте Натальи)
```

**Все 3 oracle-prescribed planets (Mercury, Sun, Jupiter) присутствуют с правильными reasons.** Venus добавлена движком по правилу 3 (KingOfAspects); Marina на стр.7 явно перечисляет только 3 планеты, но не пишет "только эти 3" — она называет их в рамках "Меркурий / Солнце / Юпитер ваши важные транзиты", не отрицая другие правила. Engine-spec в TASK эксплицитно требует все 5 sources всегда, поэтому Venus(KoA) — корректный engine output. См. Conflicts/risks для нюанса спецификации.

### Other 9 cases sanity walk-through

Worker self-check: для каждого case'а (1, 2, 3, 4, 5, 7, 9, 10 — case 8 уже выше) проверено, что каждая planet в `important_transit_planets` обоснована хотя бы одним из 5 правил из натальной карты данного case'а. Полная таблица в § Done выше; ни одной случайной planet не обнаружено. Reviewer пробежит независимо.

### Schema cascade integrity

- `git show --stat HEAD` показывает все 15 cascade files в одном коммите `7b86cf9`.
- `git log --oneline 7edbedb..HEAD` = ровно 1 commit.
- ADT (Haskell) ↔ schema (JSON) ↔ TS types: все три источника содержат точно тот же набор 5 strings: `RulerOfAsc, RulerOfMc, KingOfAspects, RulerOfSunSign, RulerOfStelliumSign`.
- `grep InTenthHouse` по `**/*.{hs,ts,json,j2}` — 0 hits в product Haskell/TS/schema/golden-files. Единственный остаточный hit — `services/api-python/app/pdf/builder.py:197`, в do-not-touch zone (см. Conflicts/risks).

### Process compliance

- Correction 008: `git status --short --branch` checked перед `git add -A`, после `git add -A`, `git diff --cached --stat` подтвердил все 15 файлов staged, unstaged tree clean.
- Backup parity: `git ls-remote backup main` == local HEAD (`7b86cf9`).
- Branch: `main`. Один atomic коммит: `7b86cf9`.

## Remaining

Ничего из scope этого TASK'а. Дальнейшие шаги (вне этого TASK'а):

- TL → spawn Reviewer subagent с embedded checklist из TASK § Acceptance.
- After accept: отдельный Tier C TASK для PDF presentation refresh — обновить `_TRANSIT_REASON_RU` в `services/api-python/app/pdf/builder.py` (убрать stale `"InTenthHouse"`, добавить `"RulerOfSunSign"` + `"RulerOfStelliumSign"` translations). Сейчас новые reasons рендерятся как ASCII identifiers через `dict.get(value, value)` fallback — функционально безопасно, эстетически degrade'нуто.

## Artifacts

- branch:               main
- commit(s):            `7b86cf9` (parent `7edbedb`)
- PR:                   — (no GitHub remote)
- tests:                cabal 231/231 green (+2 vs baseline 229); pytest 70/70 green (unchanged)
- Product repo status:  committed (commit:`7b86cf9`)
- backup parity:        OK (`git ls-remote backup main` = `7b86cf9836b156d32f4dc40b34b47626c19ae966`)

## Conflicts / risks

### 1. TASK numbering error: case 9 в title vs Marina ref → case 8 (CRITICAL для Reviewer внимания)

TASK Body, § Oracle (lines 122–125) и § Context (line 191), и Worker prompt от TL — все ссылаются на "case 9 (Наташа)" как oracle. Однако:

- `golden-cases/09-anastasiya-2025-2026.input.json` → birth `2000-05-14T08:45:00Z` Ижевск; Asc=Дева, MC=Телец, Sun=Телец, стеллиум в Тельце (Sun+Venus+Jupiter+Saturn).
- `golden-cases/08-natalya-2025-2026.input.json` → birth `1984-08-07T04:40:00Z` Москва; Asc=Дева, MC=Близнецы, Sun=Лев, стеллиум в Стрельце.
- Marina reference Соляр_5.pdf p.2 (натальная карта) → "Наталья / 7 августа 1984 Вт 8:40 Москва" + p.7 oracle описывает "Асц в Деве и МС в Близнецах ... Солнце во Льве ... скопление планет в знаке Стрельца".

Marina-reference chart **точно matches case 8**, не case 9. Worker proceeded by:

1. Implemented engine per the explicit 5-rule spec from TASK § Problem (rule semantics independent of case numbering).
2. Verified oracle against case 8 (где chart реально совпадает с Marina reference): Mercury+Sun+Jupiter все 3 присутствуют с правильными reasons. ✓
3. Verified case 9 (Анастасия) тоже даёт coherent output под 5 правилами: Mercury(Asc), Venus(MC+SunSign+Stellium-Tau), Sun(KoA) — все объяснимо.

TL может (a) принять интерпретацию Worker'а (case 8 — фактический oracle subject), либо (b) запросить Reviewer'а явно проверить против обоих cases с уточнённым numbering.

### 2. Venus(KingOfAspects) для case 8 — спецификация не строго "exactly 3 planets"

TASK § Acceptance line 125: «Никаких лишних planets кроме этих 3». Однако:

- Worker prompt строкой 70: «KingOfAspects может быть добавлен к одной из этих 3 если engine assigns — это OK; main: все 3 присутствуют, лишних planets нет».
- 5-rule engine spec (§ Problem rule 3) делает KingOfAspects всегда применимым — нет conditional clause "skip if KoA already overlaps".

Для case 8 KoA = Venus (5 major aspects, max в натале), и Venus не входит в Mercury/Sun/Jupiter. Engine эмитит её как 4-ю планету. Worker интерпретация: «лишних planets нет» означает «нет planets не объяснимых правилами»; Venus объяснена rule 3, поэтому не лишняя. Альтернативная строгая интерпретация была бы «engine должен подавлять KoA когда KoA не overlap'ит с другими 3» — это противоречило бы rule 3 как 1-st-class источнику в спецификации. Worker выбрал первую интерпретацию.

Если TL/Reviewer считает строгую "exactly 3" интерпретацию правильной — engine spec надо менять (rule 3 должен иметь conditional, или rule 3 удалить из 5-rule list). Но текущий engine output корректен относительно явно написанной спецификации.

### 3. Marina-reference page numbering: TASK говорит p.8, фактический контент на p.7

TASK § Context line 207 называет страницу 8, но oracle text «Как понять, какие транзиты планет будут важными именно...» с тремя нумерованными пунктами Меркурий/Солнце/Юпитер физически на странице 7 PDF'а. Worker confirm'ил по `Read pages 7-9` MCP-инструментом. Несущественно для logic'и (oracle тот же), но если TL/Reviewer ищет в PDF — стоит знать что искать на p.7.

### 4. PDF presentation `builder.py` остаётся stale (in-scope только функционально, не презентационно)

`services/api-python/app/pdf/builder.py:194-199` содержит `_TRANSIT_REASON_RU` dict с устаревшим ключом `"InTenthHouse": "планета 10 дома"` и без translations для `"RulerOfSunSign"` / `"RulerOfStelliumSign"`. Per TASK § Do not touch — `services/api-python/app/pdf/{builder, ...}.py` НЕ трогается, presentation refresh — отдельный Tier C TASK. Поэтому:

- В рендере PDF новые 2 reasons показываются как ASCII identifiers (через `dict.get(v, v)` fallback) — не crash'ит, но эстетически degraded.
- Stale ключ `"InTenthHouse"` теперь dead code (engine больше не эмитит `InTenthHouse`), но не вредит.

Worker honor'ил do-not-touch boundary. Reviewer должен confirm scope discipline (presentation untouched).

### 5. `Domain.Stellium` не использован для sign-stellium — sign-grouping inlined в `ImportantTransitPlanets`

`Domain.Stellium.detectStellia` принимает `[(Planet, Int)]` (planet, **house**), не sign. Для rule 4 ("ruler of stellium **sign**") нужна sign-based группировка. Worker prompt говорил «Stellium detection — уже существует в `Domain.Stellium.hs`. Используй существующее определение», но оно не подходит. Альтернативы были:

- (a) Расширить `Domain.Stellium` с sign-based вариантом — TASK § Files не listits `Stellium.hs` для modify.
- (b) Inline sign-counting в `ImportantTransitPlanets.hs` — выбран Worker'ом (stays внутри scope'а ImportantTransitPlanets, ≤10 строк).

Решение: inlined `Map.Map ZodiacSign Int`-based counting через `foldl'` + threshold 3. Если в будущем sign-stellia понадобятся в других модулях — refactor в `Domain.Stellium.detectSignStellia` отдельным cleanup TASK'ом.

## Next step

TL: spawn Reviewer subagent (Mode strict — separate session, fresh memory) с self-contained prompt, включающим:

- путь к TASK file: `project-overlays/astro/TASKS/2026-05-08-important-transit-planets-rule-fix.md`
- путь к этому HANDOFF: `project-overlays/astro/HANDOFFS/2026-05-08-worker-to-tl-important-transit-planets-rule-fix.md`
- commit hash для review: `7b86cf9` (parent `7edbedb`)
- embedded Reviewer checklist из TASK § Acceptance — operational form для cold-start
- 4 Conflicts/risks выше для явного решения (особенно #1: case 8 vs 9 numbering, и #2: Venus(KoA) interpretation)

Reviewer должен сам:
1. Прочитать TASK + Worker HANDOFF
2. Independent re-verify (cabal build/test, pytest, schema-ADT-TS consistency, schema cascade в одном commit'е)
3. Logic correctness walk-through (existing 3 reasons preservation для overlap cases, 2 new reasons emission, dual-ruler dual-emission, dedup+accumulate)
4. Oracle для Натальи (на case 8 — chart matches Marina ref; verify Mercury+Sun+Jupiter present с правильными reasons)
5. Other 8 cases sanity (1, 2, 3, 4, 5, 7, 9, 10): для каждой planet в каждом ITP найти applicable rule из 5 — REJECT если есть unexplainable planet
6. Scope discipline: только expected files в commit'е, no PDF/PriorityWindows/Stellium/Lilith touched
7. Process: 1 atomic commit, backup parity verified

Reviewer пишет HANDOFF reviewer→tl с verdict (ACCEPT / REQUEST_CHANGES / REJECT).
