# HANDOFF: Worker → TL — Phase 9.1 Directions Filter — **STOP** (CLOSED 2026-05-17)

- Status: closed (Option β — TASK closed honestly без code change per user direction 2026-05-17; Phase 9.0 memo § 5.1 erratum landed)
- Дата: 2026-05-17.
- TASK: `project-overlays/astro/TASKS/2026-05-17-phase-9-1-directions-filter.md` (Ready: yes; Status: open).
- Tier: B (Reviewer optional).
- Worker mode: normal.
- Outcome: **STOP at Stage 0** — per user direction 2026-05-17, Worker обязан не «улучшать» правило молча; Stage 0 empirical validation показал что **A2 supplement (любой его вариант) исключает Marina-selected directions** в калиброванных кейсах (case 01, 05, 09, 10). Эскалация к TL.
- Baseline: product main @ `aca694b`; overlay master @ `c9a85e7` (pre-9.1); pytest **368 passed + 2 skipped + 0 failed** (preserved — no product code touched); cabal clean; `git status --short` clean.

---

## § 0. Worker scope discipline preserved

✓ NO product code modified (filter NOT implemented).
✓ NO new files created in product.
✓ NO Haskell engine / schema / fixtures touched.
✓ NO `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` modified.
✓ NO `test_directions_section.py` weakened.
✓ NO new heuristic rules introduced beyond A1/A2/A3 from memo § 5.1.
✓ NO «improved» A2/A3 silently — Worker honoured STOP-trigger per user direction 2026-05-17 explicit warning.

Pytest baseline preserved. Cabal clean. Product `git status` clean.

---

## § 1. Stage 0 — A1-alone validation для Ольги consultation 11

### 1.1 Computed S(Ольги)

Source: `data/astro.db` consultation 11 `facts_json.natal_chart`.

```
Asc longitude: 94.15° = Cancer 4°09'  → Asc sign = Cancer
MC longitude:  323.31° = Aquarius 23°18'
```

Natal positions, house_placidus:
```
Sun        Cancer  21°00'      house 2
Moon       Virgo    9°55'      house 4
Mercury    Cancer  26°06'      house 2
Venus      Virgo    2°26'      house 4
Mars       Cancer   9°51'      house 1   ← 1st-house planet
Jupiter    Sagittarius 1°25'R  house 6
Saturn     Libra   27°51'      house 5
Uranus     Sagittarius 5°28'R  house 6
Neptune    Sagittarius 27°13'R house 6
Pluto      Libra   26°43'      house 5
```

- **1st-house planets** (per `house_placidus`): `{Mars}`.
- **Asc-ruler:** Asc in Cancer → traditional ruler = **Moon** (modern co-ruler N/A for Cancer; Cancer has only Moon).
- **Moon-fallback** (per TASK 2026-05-17 clarification 3): NOT applied — Asc-ruler known. Moon ∈ S **as Asc-ruler**, not as fallback.

**Final S(Ольги) = {Asc, MC, Mars, Moon}** (S has 4 elements).

### 1.2 A1-alone count для 9 emit-set

A1 rule (verbatim TASK spec, Marina-verbatim memo § 5.1): `direction.directed ∈ S OR direction.target ∈ S`.

| # | Engine direction | directed ∈ S? | target ∈ S? | A1 match? | Marina-selected? |
|---|------------------|--------------|-------------|-----------|------------------|
| 1 | MC 90° Asc       | MC ∈ S       | Asc ∈ S     | ✓        | ✓ |
| 2 | Moon 90° Sun     | Moon ∈ S     | Sun ∉ S     | ✓        | ✗ |
| 3 | Saturn 150° Mars | Saturn ∉ S   | Mars ∈ S    | ✓        | ✓ |
| 4 | Saturn 90° Moon  | Saturn ∉ S   | Moon ∈ S    | ✓        | ✗ |
| 5 | MC 120° Uranus   | MC ∈ S       | Uranus ∉ S  | ✓        | ✓ |
| 6 | Neptune 150° Mars| Neptune ∉ S  | Mars ∈ S    | ✓        | ✗ |
| 7 | Neptune 150° Moon| Neptune ∉ S  | Moon ∈ S    | ✓        | ✗ |
| 8 | Pluto 150° Mars  | Pluto ∉ S    | Mars ∈ S    | ✓        | ✗ |
| 9 | Sun 60° Asc      | Sun ∉ S      | Asc ∈ S     | ✓        | ✓ |

**A1-alone matches: 9 of 9.**

Marina's curated 4 (TASK spec):
- MC 90° Asc ✓
- MC 120° Uranus ✓
- Sun 60° Asc ✓
- Saturn 150° Mars ✓

All 4 PRESENT in engine emit. A1 correctly identifies them — but over-predicts by 5 (FP rate 56%).

**Stage 0 decision tree branch (per TASK spec):** A1-alone matches **> 4** → **A2 needed**.

---

## § 2. Stage 0 — A2 / A3 empirical validation (STOP-discovery)

### 2.1 Test approach

Per TASK spec discipline (Worker mode normal):
> «Apply A2 carefully — does A2 exclude any Marina-selected direction? If YES → STOP, escalation memo (A2 not Marina-supported)».

Per user direction 2026-05-17:
> «9.1 должен строго опираться на явно найденное правило Марины, а не на новый heuristic soup. Если rule A2/A3 начнут спорить с текстом Марины — Worker обязан STOP, не "улучшать" правило молча.»

Worker tested **4 filter variants** against all 9 cases (8 calibrated golden fixtures + Ольга consultation 11). For each case Worker computed Marina ∩ engine-emit (Marina-selected directions present in engine output) and compared с filter output.

Filter variants:
- **V1:** A1 only — `target ∈ S OR directed ∈ {Asc, MC}`.
- **V2:** V1 + A2 simple-drop-transpersonal-source + A3 Jaccard > 0.8 dedup (keep first by enter_jd).
- **V3:** V1 + A3 dedup (no A2).
- **V4:** A1 broader — `target ∈ S OR directed ∈ S` + A2 + A3.

### 2.2 Per-case results

| Case | Asc sign | S | Engine emit | Marina-selected | Marina ∩ engine | V1 match | V2 match | V3 match | V4 match |
|------|----------|---|-------------|-----------------|-----------------|----------|----------|----------|----------|
| 01 Ксения | Aquarius | {Asc,MC,Moon,Saturn,Uranus} | 4 | 1 | 1 (Neptune 120° Saturn) | ✗ extra | **✗ DROPS Marina-selected (Neptune source)** | ✗ extra | **✗ DROPS Marina-selected (Neptune source)** |
| 02 Максим | Scorpio | {Asc,MC,Mars,Jupiter,Pluto} | 4 | 1 | 1 (Mars 0° Pluto) | ✗ extra | ✗ extra | ✗ extra | ✗ extra |
| 03 Артем | Cancer | {Asc,MC,Moon,Jupiter} | 6 | 5 (only 3 in engine emit — 2 Chiron-direction отсутствуют в engine) | 3 | ✗ extra/miss | ✗ miss+extra | ✗ miss+extra | ✗ miss+extra |
| 04 Валерия | Taurus | {Asc,MC,Moon,Venus} | 8 | not extracted memo § 1.1 | — | — | — | — | — |
| 05 Екатерина | Aquarius | {Asc,MC,Sun,Mercury,Venus,Mars,Saturn,Uranus} | 3 | 2 | 2 | ✗ extra | **✗ DROPS Marina-selected (Neptune Conj Asc)** | ✗ extra | **✗ DROPS Marina-selected (Neptune Conj Asc)** |
| 07 Мария | Virgo | {Asc,MC,Mercury} | 6 | not extracted | — | — | — | — | — |
| 08 Наталья | Virgo | {Asc,MC,Mercury} | 3 | 2 | 2 | ✗ extra | ✓ **EXACT** | ✗ extra | ✓ **EXACT** |
| 09 Анастасия | Virgo | {Asc,MC,Mercury} | 1 | 5 (only 1 in engine emit — 4 отсутствуют — данных engine не хватает для 9-9.0 reference) | 1 | ✓ | **✗ DROPS Marina-selected (Neptune Sq Mercury)** | ✓ | **✗ DROPS Marina-selected (Neptune Sq Mercury)** |
| 10 Данила | Sagittarius | {Asc,MC,Mars,Pluto,Jupiter} | 7 | 6 | 6 | ✗ miss/extra | **✗ DROPS 3 Marina-selected (Pluto/Uranus sources + Jupiter directed-side)** | ✗ miss | **✗ DROPS 2 (Pluto/Uranus sources)** |
| 11 Ольга consultation 11 | Cancer | {Asc,MC,Mars,Moon} | 9 | 4 | 4 | ✗ extra | ✓ **EXACT** | ✗ extra | ✗ drops Sun 60° Asc |

### 2.3 Critical finding — STOP trigger evidence

**V2 (the only variant giving EXACT match for Ольги)** drops Marina-selected directions in 4 calibrated cases:

- **Case 01 Ксения:** Marina selects «Нептун 120° Сатурн» — V2 drops as transpersonal source.
- **Case 05 Екатерина:** Marina selects «Нептун 0° АС» — V2 drops as transpersonal source.
- **Case 09 Анастасия:** Marina selects «Нептун 90° Меркурий» (engine emits 1, Marina = 5 of which 4 missing engine) — V2 drops as transpersonal source.
- **Case 10 Данила:** Marina selects «Плутон 180° Юпитер» + «Уран 90° Марс» — V2 drops both as transpersonal source.

**Memo § 3.1 explicit acknowledgement (line 232):**
> «Case 01 Marina-selected source = Neptune — counter-example. Marina selects 1 outer-source direction (Нептун 120 Сатурн). ⇒ H2 fits 7/8 (case 01 breaker).»

И:
> «Сатурн = планета 7 дома + управитель 12 + соуправитель 1 дома. Сатурн is 1st-house element для Ксении ⇒ Marina rule matches.»

Marina'rule «target ∈ S» catches Neptune-Saturn для case 01 because Saturn ∈ S (Asc-ruler Aquarius traditional). But A2 («drop transpersonal source») would still drop it. **Memo refined A2** (line 231): «transpersonal source included ONLY if unique formulas not covered by personal-source direction». Тест на Ольгу:

- **Нептун 150° Марс** formulas = `{1+6, 1+11}` — NOT covered by any personal-source direction (no personal direction has 1+11 in emit set).
- Per refined A2 → KEEP. **Marina excludes**. ⇒ **Refined A2 ALSO breaks Marina-text** для Ольги.

Both A2 formulations contradict Marina (simple = drops case 01 selected; refined = keeps Ольгины transpersonal-source despite Marina exclusion).

### 2.4 A3 ambiguity

Original A3 = Jaccard > 0.8 formula-overlap dedup (keep first by enter_jd).

For Ольги emit ordered by `enter_jd`:
- `Moon 90° Sun` formulas = `{1+2, 1+3, 1+4}`
- `Sun 60° Asc` formulas = `{1+2, 1+3, 1+4}` — Jaccard = 1.0 with «Moon 90° Sun».

If A3 keeps first by enter_jd: **drops Sun 60° Asc** (Marina-selected) keeps «Moon 90° Sun» (Marina-excluded). **Direct Marina contradiction → STOP**.

Re-ordering attempt (e.g. Marina-priority — prefer source ∈ angles): not in memo specification; would be Worker «improving» rule beyond Marina text → forbidden by user direction.

### 2.5 Verdict — no formulation of A1+A2+A3 reproduces Marina

Worker tested 4 combinatorial variants of A1+A2+A3. **NONE** reproduces Marina selection in all 8 analyzable calibrated cases + Ольга simultaneously:

- **V2** matches Ольги (4/4) and case 08 (2/2) but breaks 4 other calibrated cases (drops Marina-selected transpersonal-source directions).
- **V1/V3** keep Marina-selected transpersonal-source but emit 1-4 extra over-broad directions Marina excludes.
- **V4** broadens A1 but still has the same A2-transpersonal trade-off.

**Memo § 3.1 claim** (line 492): «**Combined rule predicts 4 includes + 5 excludes EXACT match Marina's selection (4 / 9)**» — Worker confirms this is **Ольга-specific**, not generalizable to calibrated set. Memo § 2.1 summary table line 247 acknowledges «Ольга-row: rule fits 4/4 Marina-positive but over-predicts on 5/9 engine-emit cases» — but does NOT cross-validate refined rule against calibrated cases 01/05/09/10 where Marina selects outer-source directions.

---

## § 3. STOP rationale per user direction

User direction 2026-05-17 verbatim в TASK spec § «Worker framing»:

> **«9.1 должен строго опираться на явно найденное правило Марины, а не на новый heuristic soup. Если rule A2/A3 начнут спорить с текстом Марины — Worker обязан STOP, не "улучшать" правило молча.»**

STOP triggers per TASK spec § «STOP triggers»:
- ✓ «A2 implementation excludes Marina-selected direction → STOP, A2 not Marina-supported.» **TRIGGERED** for cases 01, 05, 09, 10.
- ✓ «A3 implementation excludes Marina-selected direction → STOP, A3 not Marina-supported.» **TRIGGERED** for Ольги Sun 60° Asc (if A3 dedup keeps «Moon 90° Sun» first by enter_jd).
- ✓ «Worker tempted to introduce new heuristic beyond A1/A2/A3 → STOP, scope creep.» **AVOIDED** — Worker did NOT silently improve A2/A3.

Marina's verbatim text (memo § 5.1):
> «Чтобы событие произошло, то, в первую очередь, мы должны рассмотреть аспекты к Асц (1 дом), элементам 1 дома и МС, смотрим, есть ли такие.»

Marina's verbatim rule is **A1-only**. **A2 and A3 are Worker's empirical supplements with explicit Marina-text-disagreement risk** (per memo § 5.1 «Worker supplement — verify against Marina text before applying»). Stage 0 empirical validation demonstrates that **both A2 formulations and A3 dedup contradict Marina-text in calibrated cases**.

---

## § 4. Per-case ground-truth ambiguities (out of filter scope)

Worker observation: even pure A1-alone matching has data-source ambiguities **beyond filter scope**:

- **Case 03 Артем:** memo § 1.1 lists 5 Marina-selected directions including «Хирон 180° МС» and «Нептун 150° Хирон». **Engine emit для case 03 (`03-artem-2025-2026.expected.json`) does NOT contain Chiron** as direction-eligible body (Chiron is scoped to TransitCalendar per Correction 009, not Directions). So 2 of 5 Marina-row references are **fundamentally not reproducible by engine output**. Filter cannot match these.
- **Case 09 Анастасия:** memo § 1.1 lists 5 Marina-selected directions; engine emit for case 09 contains **only 1** (Нептун 90° Меркурий). 4 of 5 Marina-references are outside engine emit. This is a Phase 8 audit § A.2.1.D «TYPE-D SR-time mismatch» footprint — engine output for case 09 fundamentally differs from Marina reference.
- **Case 04 / 07:** Marina selections **not extracted** в memo § 1.1.

These are **engine-emit-vs-Marina-reference gaps**, not filter problems. Filter cannot resolve them. Any Phase 9.1 reformulation must address scope: **filter operates on engine output**, не на «conceptual Marina-selected set» which may include items engine does not emit.

---

## § 5. Stage 0 decision branch (per TASK spec)

Per TASK spec § Stage 0 decision tree:

```
- A1-alone matches > 4 → A2 needed.
  - Apply A2 (transpersonal-source duplicate-formula filtering).
  - Verify: does A2 exclude any Marina-selected direction?
    - YES (cases 01, 05, 09, 10) → STOP, escalation memo (A2 not Marina-supported).
```

**Decision: STOP, escalation memo to TL.**

---

## § 6. Open questions to TL (for re-spec or task closure)

1. **Re-frame Phase 9.1 scope:** is target «exact Marina match для Ольги only» (тогда V2-style filter as Ольга-only with explicit override discipline for other cases — fits 2/9 calibrated naturally) OR «universal Marina-matching rule across 9 calibrated cases» (тогда no extractable rule per Worker's 4-variant test)?
2. **Outer-source inclusion:** Marina includes transpersonal-source directions в cases 01/05/09/10 but excludes them в case 11. Is this **per-client significator weighting** (similar to Phase 9.2 outer-cards heuristic per memo § 5.2) — i.e. Marina chooses transpersonal-source based on chart-specific «significator-ness» of the target planet? If so, this is the same per-client-significator problem as sub-problem B (Phase 9.2), не just sub-problem A.
3. **Formula-dedup ordering:** if A3 needed, what is the «winning» direction tie-break rule when Marina-selected and Marina-excluded directions have identical formulas? Marina's text doesn't specify; Worker can't extract «source ∈ angles preferred» from memo without conflict.
4. **Chiron emit:** memo Marina-row reference includes Chiron-direction entries for case 03 that engine does not emit. Is this an upstream engine gap (Phase 0.4 lock-in scoped Chiron away from Directions per Correction 005/009) or a memo-row data error?
5. **Case 09 engine reference:** is the existing case-09 expected.json («1 direction Neptune 90° Mercury») the correct engine output для current product main? If so, what is the source of memo § 1.1 «Marina selected 5» (likely Marina PDF cleaned independently of engine emit; not reconcilable by filter).
6. **«Ольга-only» MVP path:** would TL accept Ольга-only filter as Phase 9.1 deliverable (V2 applied; existing 9 calibrated cases preserved without filter via case_label allowlist OR Marina-allowlist style override)? This would close Ольга acceptance criteria while leaving calibrated regression test only on Ольгу's 4/9.

---

## § 7. Recommended next steps (Worker proposal — TL decides)

**Option α — Spec narrows to Ольга-only filter:**
- Apply V2 filter (`target ∈ S OR directed ∈ ANGLES; drop transpersonal source; Jaccard dedup`) **only when `case_label` is NOT in `OUTER_CARD_ALLOWLIST`** (i.e. non-calibrated path).
- Calibrated cases preserve current `directions-show-all-active` full-list behavior — no filter applied.
- Risk: Phase 9.1 produces 2 different presentations for «calibrated» vs «non-calibrated» — but this mirrors Phase 8 `OUTER_CARD_ALLOWLIST` + `generic_outer_cards` separation discipline.
- Tests: regression test on Ольга 4/9 + assertion that calibrated cases pass through unchanged.
- Reviewer concerns: V2 may fail на future non-calibrated cases с outer-source Marina-selected (like Ольга case 11 был для outer cards in Phase 9.0 — engine + Marina diverge).

**Option β — Phase 9.1 closed without product change:**
- Accept that «Marina selection rule for directions» is **NOT extractable as deterministic filter rule from 10-case sample**.
- Memo § 5.1 verdict «hybrid (deterministic-leaning)» is empirically not enough to justify product filter — recipe for false negatives in 4-5 calibrated cases.
- Phase 9.1 closed as «**verified not deterministic — directions remain show-all-active per 2026-05-16 TASK**».
- Document as Phase 9.0 follow-up finding: «sub-problem A is **more editorial than memo § 5.1 verdict implied**».

**Option γ — Extended memo + Phase 9.1 re-spec:**
- Re-open Phase 9.0 memo для re-validation: test refined A2 on cases 01/05/09/10 explicitly; extract Marina's per-client «significator weighting» (Marina pisits «Транзиты Венеры – король аспектов» в Ольги; similar lines в Натальи / Анастасии). Per-client significator may be the **real** rule, не «transpersonal/personal source bias».
- Phase 9.1 deferred until refined rule is validated.

**Worker recommendation:** Option β (closure без product change) **OR** Option α (Ольга-only V2 explicitly gated by `case_label is None`). Option γ is research-y, reasonable but Phase-9.0-scope-reopen.

---

## § 8. Files

- **Created (overlay):**
  - `project-overlays/astro/HANDOFFS/2026-05-17-worker-to-tl-phase-9-1-directions-filter-STOP.md` (this file).
  
- **Will modify (overlay) before submit:**
  - `project-overlays/astro/STATUS_RU.md` — append Phase 9.1 STOP entry.
  - TASK file — Status «open» preserved (NOT advanced to review); add «STOP_AT_STAGE_0» tag + cross-reference to this HANDOFF.

- **Product code:** ZERO changes. `git status --short` clean.

---

## § 9. Acceptance verification (Stage 0 + scope discipline)

**Stage 0 (per TASK spec):**
- [x] A1-alone count для Ольги reported: **9 of 9**.
- [x] A1 alone matches > 4 → A2 needed (per decision tree).
- [x] A2 application tested — **excludes Marina-selected** in cases 01, 05, 09, 10 → STOP.
- [x] A3 dedup tested — **excludes Marina-selected** «Sun 60° Asc» в Ольги emit-set → STOP.

**Acceptance gates:**
- Stage 1-4 NOT executed (STOP at Stage 0).
- Pytest baseline preserved: **368 passed + 2 skipped + 0 failed** (no test changes).
- Cabal: clean (no Haskell touched).
- `git status --short`: clean for product; 1 new overlay file (this HANDOFF).
- Product commits: 0.
- Overlay commits: 1 (after STATUS_RU update + this HANDOFF + TASK STOP-tag).

**Authorization:** Tier B normally requires Reviewer; per user direction 2026-05-17 Reviewer optional. Worker pre-empts at Stage 0 STOP — no implementation to review.

---

## § 10. Conclusion

Worker honoured user direction 2026-05-17 verbatim:
> «9.1 должен строго опираться на явно найденное правило Марины, а не на новый heuristic soup. Если rule A2/A3 начнут спорить с текстом Марины — Worker обязан STOP, не "улучшать" правило молча.»

**A1-alone (Marina-verbatim)** matches 9 of 9 engine emit для Ольги — over-predicts by 5.

**A2 (Worker supplement)** in any formulation tested excludes Marina-selected transpersonal-source directions in calibrated cases 01/05/09/10. This is **direct contradiction of Marina-text** для those cases — STOP trigger.

**A3 (Worker supplement)** in stated form excludes Marina-selected «Sun 60° Asc» from Ольги emit-set when applied with enter_jd ordering and Jaccard > 0.8 on identical formulas. STOP trigger.

**No combinatorial variant of A1+A2+A3 satisfies all 8 analyzable calibrated cases + Ольга** simultaneously.

**Conclusion:** sub-problem A directions selection is **more editorial than memo § 5.1 verdict (`hybrid/deterministic-leaning`) implied**. Phase 9.1 cannot land deterministic universal filter без contradicting Marina-text. Escalation to TL for re-spec OR closure.

End of HANDOFF.
