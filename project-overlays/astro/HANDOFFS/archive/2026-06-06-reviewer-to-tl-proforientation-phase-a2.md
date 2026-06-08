# HANDOFF: reviewer → tl — proforientation Phase A2 (независимый ревью)

- Status: closed
- Date: 2026-06-06
- From: Reviewer (независимая сессия, не участвовал в реализации)
- To: Tech Lead (astro)
- Agent runtime: Claude Code
- Model: Claude Opus 4.8
- Role mode: Reviewer (Tier A schema-gate, Correction 021)
- TASK: `TASKS/archive/2026-06-06-proforientation-phase-a2-schema-gate.md`
- Subject: product `b7cf858` (vocation schema-gate), diff `7dc313e..b7cf858`
- Product repo status: not applicable (read-only ревью)

## Вердикт: APPROVE-WITH-FINDINGS (нитки косметические; A2 закрывается)

Воспроизведено независимо (с нуля, не доверяя HANDOFF):
- `cabal test` **338/0** (334 baseline + 4 vocation golden); build clean.
- `pytest test_contracts` **11** (8 + 3 vocation); `tsc --noEmit` clean.
- **Атомарность (bright line #8):** все 5 групп артефактов + удаление F1 в ОДНОМ коммите `b7cf858` (13 файлов, +1374/−8).
- **solar/returns бит-в-бит:** diff по solar-*/returns-* схемам + их golden/fixtures пуст; `Bridge.Solar.hs` и `Bridge.Returns.hs` — 0 изменений.
- **Dispatch вживую:** vocation→реальный вывод; `{"workflow":"bogus"}`→exit 2; solar/returns→свои пути (не сломаны). Main.hs diff аддитивный.
- **Схема↔Bridge↔TS 1:1:** RealizationFactorKey(5), AbilityFactorKey(9), MoneyHouseNumber{10,2,6,8}, VocationCombination{planet, connected_houses, factor_keys, rank, score}, factor_table — идентичны в schema / Bridge ToJSON / Domain ToJSON / types.ts.
- **Reuse DTO (Correction 001):** Bridge.Vocation импортирует BridgePlanetPosition + BridgeMeta из Bridge.Solar; factor_table reuse `Domain.Vocation.PlanetFactors`. Единственный новый record — `BridgeHouseCuspsIn` (новый смысл входа, не дубль).
- **Вход/выход:** вход = натал+куспиды (без samples/reference_jd); выход = combos + factor_table, машинные ключи, БЕЗ прозы. F1 (`planetsInHouse`) удалён чисто; golden бит-в-бит; golden воспроизводит вывод Банкира (Jupiter rank 1, Pluto пуст).
- **Нет Phase-B creep:** нет api/, ephemeris/, .j2, .tsx (кроме types.ts). 0 STOP.

## Находки (косметические — в Phase B touch-up)
| ID | severity | где | суть |
|---|---|---|---|
| R1 | trivial doc | `Bridge/Vocation.hs:179` | комментарий «connected_houses ascending» неверен — порядок приоритетный (X,II,VI,VIII), напр. `[10,2,8]`. Схема+TS говорят «priority order» верно; поведение верно, только комментарий. |
| R2 | trivial doc | `vocation-output.schema.json:159-162` | `score minimum:1`, описание говорит «≥2». Безвредно (констрейнт слабее реальности). |
| R3 | info | `Bridge/Vocation.hs:220-257` | Bridge переисчисляет factor-key строки независимо от Domain (хелперы Domain не экспортированы). Drift-риск заперт golden'ом. Отметить для Phase B. |

## Рекомендация TL
Ship, A2 закрывается. R1/R2 свернуть в Phase B; R3 — отметить. Re-engagement не нужен.
