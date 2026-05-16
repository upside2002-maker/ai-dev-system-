# Статус — Astro

Дата последнего обновления: 2026-05-15.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **Программа Transit Section Recovery — CLOSED 2026-05-15.** **API PDF endpoint end-to-end repaired 2026-05-15** (TASK api-pdf-endpoint-end-to-end, Tier C + Reviewer-equivalent APPROVE).

**API PDF endpoint repair (TASK api-pdf-endpoint-end-to-end, 2026-05-15):** `GET /api/v1/consultations/{id}/pdf` теперь собирает `RenderProvenance(mode="api-render", extra={"case_label": person.case_label})` и передаёт его в `write_solar_pdf` — outer cards секция активируется per Marina-show contract. Stage 0 save/return trace зафиксировал 3 latent edge-case бага (silent mkdir OSError, silent render exception, undetected empty-file race) — все исправлены envelope'ами `HTTPException(500, error=...)`. DB schema расширена `case_label TEXT` (migration `003_persons_case_label.sql`); backfill: Наташа `08-natalya-2025-2026`; Евгения / Ольга — NULL по умолчанию (no canonical mapping, NOT STOP per user direction). 3 acceptance test'а в `tests/test_api_pdf_endpoint.py` (case_label set / null / parity ≈ render_case.py). Pytest 298 → **301** (3 new passed). Schema-change-gate (bright line #8) honoured: `packages/contracts/person.schema.json` + `apps/web-react/src/types.ts` + Pydantic models в одном атомарном коммите (Haskell roundtrip-тест не применим — Person это operational data per bright line #1).

**Final verdict (per user explicit ack 2026-05-15):**
> «**Recovery program CLOSED — Natalya/05/07/10 production-ready; full-folder supply requires Marina framing and excludes TYPE-D/Pluto-rule future work.**»

**Phase 8 closure cascade landed 2026-05-15:** TASK 8D + TASK 8E + Phase 8 program closed одним overlay commit. Reviewer subagent APPROVE on TASK 8E (8 points, narrow-scope) + user explicit ack received. Marina framing memo готовится отдельным lightweight post-closure artifact (per discipline «не смешивать framing memo с closure commit»).

**Recovery program timeline:**
- 2026-05-11/12: Tier A engine cascade (per-loop-pass orb-window scanner; per-planet orb calibration; cross-year sample window). Pytest 85/85.
- 2026-05-12: Tier C presentation rebuild (premature accept).
- 2026-05-13: Программа Recovery открыта; Phase 0-7 + 7a + 7b + 7c. Pytest 85 → 183.
- 2026-05-13: TASK 7b закрыт «Ready for Marina show» (преждевременно — boundary contract gap).
- 2026-05-14: Phase 8 REOPENED. Phase 8.0 + 8A + 8C + 8B (Path 1 retract N-J W3) + 8D. Pytest 183 → 286.
- 2026-05-15: TASK 8E (Path 1' BEFORE buffer) + cascade closure. Pytest 286 → 298. Phase 8 + Recovery program CLOSED.

**Production state at closure:**
- astro main = backup/main = `59ec177` ✓
- ai-dev-system overlay master = backup/master ✓ (cascade closure commit landed)
- Pytest: **298 passed + 0 xfailed + 0 failed** (vs 85 при старте).
- Cabal build: clean.
- Override count: **1** (08 Phase 4b N-N W1 start ±200d — sole survivor, true Marina-editorial confirmed by TASK 8E Path 1' Scenario 1).
- Canonical render: `services/api-python/scripts/render_case.py --case-id <case-id> --output <path>`.

**Boundary state:**
- 104 enrolled boundaries в `MARINA_OUTER_CARD_BOUNDARIES`; 0 OOT.
- 1 structured override (N-N W1 start ±200d, true editorial).
- 12 documented future-work items в audit § A.2.1.D — vacuum-out of Phase 8 implementation scope: Pluto display rule (3 cards), single-window alignment (6 cards), case 03 P-Mars Marina typo (1 card), case 09 Анастасия TYPE-D (2 cards).

**Production-ready cases для прямого показа Марине (по verdict):**
- 08 Натальи — Phase 1-7 + Phase 8B Path 1 (N-J W3 fixed). 1 editorial divergence remaining (N-N W1 start +178d) — TL framing memo обязателен.
- 05 Екатерина — Phase 7b Stage B (3 outer cards). Lexical «трине → тригоне» fixed (Phase 8B). 51/52 monthly cells + 1 TYPE-A Venus Jul 2025 (anchor convention).
- 07 Мария — Phase 7a label-arithmetic fix; 11/13 cells + 2 TYPE-A boundary rows (anchor convention). No outer cards by Marina editorial.
- 10 Данила — Phase 7b Stage B (3 outer cards, Нептун кв Юпитеру 4 windows); Phase 8B Path 1 horizon fix (W3 Венере + W4 Юпитеру converged).

**NOT в production supply без framing:**
- 01 Ксения, 02 Максим, 03 Артём, 04 Валерия — рендерятся, но 12 future-work items в audit § A.2.1.D (Pluto / single-window / case 03 P-Mars typo) затрагивают эти cases. Required per-case framing.
- 09 Анастасия — TYPE-D fixture/reference SR-time mismatch (~60min); data revision sub-task **вне Phase 8 implementation programme**.

**Полная история программы:**
- `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` — 8 sections recovery SoT.
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 1-6 verdict chain.
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — Phase 8 audit + § A.2.1.D 14-card analysis.
- `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` — Phase 4a memo + Phase 8B Path 1 erratum.
- 8 archived TASK files + 5 archived HANDOFFs in `archive/`.

**TASK 8E delivered 2026-05-15 (Worker subagent, Tier B).** BEFORE buffer extension `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540 → 730` в `services/api-python/app/ephemeris/bridge.py` (rationale per user direction: «730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin» — 01 N-Sun W1 SR-582d fits с ~148d margin; 01 N-Mars W1 SR-557d fits с ~173d margin). AFTER buffer untouched (stays 730d from TASK 8B). Stage E.5.a 08 N-N W1 start empirical recheck → **Scenario 1** (Δ stays -178d, TL prediction correct; true editorial, NOT horizon truncation; ±200d structured override stays). Stage E.6.1: 12 new boundary points enrolled (01 N-Sun + N-Mars × 3 windows × 2 sides) — все within ±2d default tolerance.

**Pytest 298/0/0** (286 baseline + 12 new boundary points). Override count: 1 (08 Phase 4b N-N W1 ±200d sole survivor). Per-case raw row count ratio 1.08×–1.14× (below 1.20× early-warning informational threshold и 1.50× escalate threshold). Presentation calendar `cal_h` bit-identical pre/post all 9 cases (1.00× ratio); monthly cells matrix `mat_h` bit-identical pre/post all 9 cases. 9 fixture files regenerated (input + expected = 18 files) per Bright Line #8 atomic commit.

**Verdict update (post-Phase-8E, 2026-05-15):** «**Ready for Marina show — pending user ack**» (final closure verdict). Recovery program Phase 8 complete (8.0 + 8A + 8B + 8C + 8D + 8E). После Reviewer APPROVE → cascade close TASK 8D + 8E + Phase 8 program → пользовательский ack → программа closes. Framing memo для Marina готовится отдельным lightweight post-closure artifact, не смешивается с closure commit.

**TASK 8D delivered + external Reviewer APPROVE 2026-05-15 (предшествует 8E в cascade).** 20 new cards in `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` (5+2+9+2+2 = 20 cards × 5 fact cells = 100 manual transfers, Reviewer spot-checked 15/20 directly от Marina PDFs); 36 new boundary assertions + 29 lexical title assertions. **Reviewer empirical finding (TASK 8D § A.2.1.D, confirmed 2026-05-15):** Pre-buffer truncation finding для case 01 N-Sun + N-Mars W1 starts. Engine emits W1 = `29.05.2023 06:14 GMT+3` = `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540` floor to-the-second exactly; Marina W1 = 17.04.2023 / 12.05.2023. **Resolved via TASK 8E** (post-fix engine W1 = 16.04.2023 / 11.05.2023, Δ −1d both, within ±2d default tolerance).

**Verdict superseded (post-Phase-8-audit, 2026-05-14):** «Partial pass — только 08 Наталья production-ready». Закрытие TASK 7b 2026-05-13 было **преждевременным** — manual audit (Codex + TL 2026-05-14) на clean checkout обнаружил, что multi-case тесты Stage B проверяли количество outer-card окон, но **не их boundary даты** vs Marina. Worker'овский pytest baseline 183/0/0 правда зелёный, но контрактная дыра в TASK 7b § B.4 пропустила реальные расхождения. **Дисциплинарная ответственность — на PTL за spec, не на Worker'е.**

**5 находок Phase 8.0 audit:**
1. **Test contract gap:** `test_multi_case_calibration.py` не assert'ит outer-card interval boundaries; spec gap в TASK 7b § B.4.
2. **Данила Neptune boundary regression** (TYPE-B-equivalent, не accepted divergence): Нептун кв Венере W3 end `28.01.2028` vs Marina `07.03.2028` (+38d); Нептун кв Юпитеру W4 end `28.01.2028` vs Marina `18.03.2028` (+49d). Оба заканчиваются на identical `orb_exit_jd = 2461798.822368622` — finite-horizon engine sample window truncation, не Marina editorial. **Это новый class дефекта, отличный от Phase 4b Натальи accepted divergences.**
3. **Allowlist gap:** Cases 01/02/03/04/09 — у нас 0 outer cards, у Marina 2-9 cards per case. TYPE-A (closed-config gap, аналог решения TASK 7b Stage B для 05/10).
4. **Lexical divergence case 05:** card title «Нептун в **трине** с нат Юпитером», Marina «Нептун в **тригоне**». One-word fix.
5. **Data-quality blockers (TYPE-D, отдельный класс):** `Соляр 2025-2026_3.pdf` — fixture missing natal metadata; Анастасия — fixture/reference SR-time/timezone mismatch. Не code regressions; требуют отдельной data revision.

**Recovery program closure summary (2026-05-13, преждевременный — теперь historical record):**
- Production HEAD: `c936dd1` (astro main = backup/main).
- Pytest: 183 passed, 0 xfailed, 0 failed (тесты зелёные, но contract incomplete).
- Override count: 2 / 10 (Phase 4b Натальи Neptune; threshold preserved).
- Phase 4b structured editorial exceptions на Натальи (2 Neptune boundaries) — accepted divergence; будет видно Марине при показе, framing подготовит TL.
- 5 TYPE-A items в § 4 калибровочного отчёта (anchor-day monthly boundaries): items 1, 2 [RESOLVED via Stage B]; items 3, 4, 5 — anchor-day boundary divergence, documented note-only.
- Канонический render path: `services/api-python/scripts/render_case.py --case-id <case-id> --output <path>`.
- Полная история: `ARCHITECTURE/transit-section-program-2026-05-13.md` + `transit-multi-case-calibration-report-2026-05-13.md` + archived TASKs.

**Phase 8 sub-phases:**
- **Phase 8.0** (audit trail reopen, TL inline overlay-only): **CLOSED** 2026-05-14 — STATUS_RU downgrade + calibration report § 6 verdict update.
- **Phase 8A** (read-only full-folder audit): **CLOSED via Worker 2026-05-14** — audit report `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` создан. Inventory 10 PDFs (8 matched, 2 TYPE-D). Per-case diff для матчей. § A.2.1 canonical Marina boundary dates table (single SoT, 28 windows × 2 sides = 56 boundary entries). Classification TYPE-A/B/B-equivalent/C/D. Prioritized Phase 8B sub-task proposals 1-5 с Данила Path A (engine horizon extension) vs Path B (presentation marker) cost estimates + Worker recommendation Path A.
- **Phase 8C** (test contract first): **CLOSED via Worker 2026-05-14 одновременно с 8A** — `test_multi_case_calibration.py` extended с 38 boundary assertions для 05+10 (08 — отдельно в `test_natalya_transits_acceptance.py` Phase 4b). 36 passed + 2 xfail(strict=True) для Данила Венере W3 end + Юпитеру W4 end. 0 новых tolerance_overrides; Phase 4b Натальи overrides не тронуты.
**AMENDMENT to Phase 8B (Path 1, 2026-05-14):** Worker Stage B2.1 trace эмпирически показал, что Phase 4b N-J W3 end (-17d) был misclassified — `orb_exit_jd = 2461800.5928 = SR + 906d` = engine sample horizon boundary, а **не** Marina editorial. Phase 4a memo получает erratum subsection (TL-acked 2026-05-14). После TASK 8B horizon extension: 1 Натальи `tolerance_overrides` (N-J W3 ±20d) **снимается** в Stage B3.2 (post engine convergence to ±2d Marina); N-N W1 ±200d override stays (true editorial — наша start at SR-491d, в пределах 540d BEFORE buffer, не на boundary). После Path 1 Натальи получает 1 editorial divergence для Marina framing (раньше планировались 2). Test contract Phase 8C validated — он разработан ровно чтобы такие случаи ловить.

- **Phase 8B** (fixes — следующий Worker TASK; AMENDED 2026-05-14):
  1. **Lexical quick win** — «трине → тригоне» в aspect-locative dict `outer_cards.py` (case 05 card 3 title). Tier C.
  2. **Данила horizon fix Path A** — engine sample horizon extension в Haskell (`Domain.TransitCalendar`). **Required regression guards:** (a) Phase 4b Натальи N-J W3 end + N-N W1 start Δ stay accepted-divergence values (do NOT change post-fix); (b) calendar size (`annual_transit_table` row count) does NOT bloat across Натальи / 05 / 07 / 10; (c) all monthly tables + outer card boundaries для не-Данила окон preserved. Path B (presentation truncation marker) — **optional defensive fence**, не первый фикс. Tier B (Haskell engine touch; Tier A escalation if schema cascade triggered).
  3. **После horizon fix** — unmark 2 Данила `xfail(strict=True)` markers в `test_multi_case_calibration.py`; boundary tests должны стать green (Phase 2 xfail-strict discipline: xpass forces unmark в том же TASK).
- **TASK 8D** (separate Worker TASK после 8B closes): allowlist + facts extension для 01/02/03/04/09 (Stage B-pattern, Tier C closed-config). **Не смешивать с 8B horizon fix.** Order: после Path A landed чтобы новые карты сразу получили correct sample horizon.
- **TASK 8E** (BEFORE buffer extension, post-8D): `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540 → 730` (mirror of TASK 8B AFTER side, but tighter — «730 = minimum systemic extension covering confirmed Marina pre-SR windows with >150d margin» per user direction). Stage E.5.a empirical recheck on 08 N-N W1 start; STOP-gated if converges (TL/user ack required для retraction). Tier B + Reviewer REQUIRED.
- **TYPE-D** (`_3.pdf`, Анастасия) — отдельный data-revision backlog, **вне Phase 8 implementation programme**.

**Phase 8A+8C ACCEPTED + archived 2026-05-14.** TASK 8A+8C lifecycle закрыт: TASK file + HANDOFF archived; calibration report § 4 расширен; pytest 219/2/0 preserved; CI green.

**Phase 8B ACCEPTED + archived 2026-05-14 (Path 1 amendment + Reviewer APPROVE + user explicit ack).** TASK 8B lifecycle закрыт; TASK file + HANDOFF archived. **Reviewer informational notes (non-blocking):** case 01 raw fixture ratio 1.152× (HANDOFF округлил «≤ 1.15×»; under presentation 1.5× spec threshold); 18 fixture files в commit'е (9 cases × 2 files: input+expected; HANDOFF wording «9 fixtures regen'd» counts cases not files); lexical sites 2 не 3 (line 458 уже содержал «тригоне»); self-reviewer disclosure honest; cross-refs verified. Изменения TASK 8B:
1. **Lexical:** «трине → тригоне» в `services/api-python/app/pdf/outer_cards.py` (aspect-locative dict + sync в `test_multi_case_calibration.py`).
2. **Horizon extension:** `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 540 → 730` в `services/api-python/app/ephemeris/bridge.py` (sample window SR + 906d → SR + 1096d ≈ 3 solar years per `outer_card_lookahead_days = 365.25 * 3` systemic policy). 9 golden fixtures regen'ed (raw row count +9..+14 entries per case, ≤ 1.15× ratio); presentation calendar + monthly cells matrix bit-identical pre/post (1.00× ratio, Phase 6 clipping `[sr_jd, sr_jd + 365.25]` isolates calendar to solar year).
3. **Reclassification:** Phase 4b N-J W3 end (-17d) reclassified из «Marina-editorial» в «engine finite-horizon truncation» — Worker B2.1 trace показал, что pre-fix `orb_exit_jd = 2461800.5928 = SR + 906d` exactly = sample window cutoff, ровно тот же артефакт как у Данилы. Post-fix engine `16.02.2028 10:23 UTC` сходится с Marina `16.02.2028 12:00 MSK = 09:00 UTC` в пределах 1.4h. Phase 4a memo (`transit-contact-window-semantics-2026-05-13.md`) получил Erratum (Phase 8B Path 1) subsection.
4. **Unmark:** 2 Данила xfail markers + `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` data structure удалены в `test_multi_case_calibration.py`. N-J W3 end +20d structured override удалён в `test_natalya_transits_acceptance.py`. N-N W1 start +200d override **STAYS** (true Marina-editorial — наша start at SR-491d, в пределах 540d BEFORE buffer, не на горизонтной границе).

Boundary table post-fix: 27 of 28 windows match Marina ±2d (только 1 OUT — 08 N-N W1 start -178d, true editorial). pytest **221 passed + 0 xfailed + 0 failed**. CI green. На Marina show Натальи остаётся **1 editorial divergence для framing** (была 2 до Path 1).

Phase 8 status: corrective programme на 8D + TYPE-D backlog.

**Phase 1 (Single source of truth + render provenance) — ACCEPTED.** TASK 1 закрыт коммитом `9793d5d`, теперь на `main` (после fast-forward merge `claude/dreamy-moore-46f5eb` → `main`):
- Canonical render entry point: `services/api-python/scripts/render_natalya.py` с CLI флагами (`--mode {fixture-render,recompute}`, `--output`, `--debug`, `--facts`, `--input`).
- Render provenance module: `services/api-python/app/pdf/provenance.py`. Sidecar JSON `<output>.pdf.provenance.json` рядом с PDF; 13 keys (git SHA, repo root, render script, facts path+hash, input fixture path+hash, mode, core CLI path+hash, timestamp UTC, worktree branch) + bonus debug_mode + extra.
- Opt-in debug footer в `solar.html.j2`: guarded by `provenance_meta.debug_mode`; на клиентских PDF не виден (text-extract verified).
- Tests: 94/94 green (85 baseline + 9 новых в `test_provenance.py`).
- Workspace cleanup: forensic listing `/tmp/render_*.py` в HANDOFF (5 files), не удалены per policy. Внутри repo нет alternative render entry points.

**Phase 2 (Hard acceptance assertions) — ACCEPTED.** TASK 2 закрыт коммитом `fb47aca` на main:
- `services/api-python/tests/test_natalya_transits_acceptance.py` — 29 assertions в 7 категориях по § 6 архитектурного документа.
- `services/api-python/tests/conftest.py` — session-scoped fixtures (canonical render once per test session, pypdf text extraction).
- Стратегия `@pytest.mark.xfail(strict=True, reason="Phase N — ...")` — assertions фиксируют контракт **сейчас**, закрытие Phase 3/4/5/6 переведёт xfailed → xpassed → strict flip заставит Worker unmark.
- Distribution: **8 passed** (Category 1 Render provenance + 4 regression guards already-satisfied) + **21 xfailed** (Phase 3 = 5, Phase 4 = 11, Phase 5 = 4, Phase 6 = 4).
- Tests: **102 passed + 21 xfailed = 123 total, 0 failed.**

**Worktree merged.** `claude/dreamy-moore-46f5eb` → `main` fast-forward сделан перед TASK 2 (commit `9793d5d` теперь HEAD `main`, backup parity ✓). Worktree directory orphaned (same SHA как main); pruning — отдельное user decision, не блокер.

**Lesson from Phase 2 verification — cabal build hygiene.** Worker Phase 2 первоначально обнаружил 9 «pre-existing» failures в `test_golden_cases.py` на baseline `9793d5d`. Расследование: stale cabal cache (source `TransitCalendar.hs` менялся в Tier A, но binary cache на main был stale после merge). После `cabal build` все 9 проходят. **Дисциплина для следующих Phase Worker'ов:** при работе с engine или после смены ветки — обязательный `cabal build` перед pytest. Worker может рассчитывать что cabal cache stale пока не доказано иначе.

**Phase 3 (Transit horizon split) — ACCEPTED.** TASK 3 закрыт коммитом `70185b0` на main:
- Path B выбран (presentation-level, Tier C). Engine + schema не тронуты.
- `transit_themes.py`: `solar_year_transits(att, sr_jd)` + `loop_transit_windows(att)` view filters; `houses_visited()` accepts `horizon=` param с default `solar_year`.
- `synthesis_themes.py`: routed на solar-year view, suppress out-of-year `exit_jd` tails в «Выводы:» / themed prose / «Итоги консультации».
- `solar.html.j2`: per-house section passes explicit `solar_return_jd` from `facts.solar_chart.return_jd`.
- Verify: PDF Натальи (`/tmp/natalya-phase3.pdf`) — Saturn houses `[7, 8]`, no `Сатурн в 6 доме`, no `2024/2027/2028` в per-house section и synthesis.
- xfail flips: 4 tests (saturn houses, saturn-6-pdf, horizon-param, regression ban). Phase 5/6 xfails остаются untouched.
- Tests: 106 passed + 17 xfailed = 123 total, 0 failed.

**Phase 4 (Outer-planet cards generator) — ACCEPTED.** TASK 4 закрыт коммитом `8c9588d` на main:
- Path 3 implemented per user decision: allowlist-based 3 cards для Натальи (Уран ⬜ Венера, Нептун ⬜ Юпитер, Нептун ⬜ Нептун), Уран 150° Юпитер остаётся в календаре.
- Новый модуль `services/api-python/app/pdf/outer_cards.py` (~480 lines): allowlist config per case_id, aggregation raw hits → 3 display windows, build_outer_card → dict с 5 секциями Marina format.
- Closed card-facts per case_id (golden-rule data) считаны визуально из Marina pp. 18/20/21.
- Closed-dictionary psychology/event тексты — Marina-style paraphrase, не verbatim.
- Latin `c` (U+0063) в card title между «в квадрате» и «нат» — соответствует Marina эталону.
- xfail flips: 7 (6 Cat 3 outer structure + 1 Cat 7 regression). 2 Cat 4 Neptune interval xfails остаются с обновлённым reason `"TASK 4a — Neptune slow-loop contact window semantics"`.
- Tests: **113 passed + 10 xfailed = 123 total, 0 failed.**
- PDF `/tmp/natalya-phase4.pdf` — 3 cards присутствуют, Уран 150° Юпитер не карточка.

**Phase 4a (Transit contact window semantics) — ACCEPTED.** TASK 4a memo deliverable принят. Memo `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` (758 lines) с 7 sections: taxonomy 5 concepts, engine semantic analysis, Marina hypothesis testing (4 hypotheses на 3 examples), path analysis, recommendation.

Главный finding: **Marina display boundaries для slow outer loops не имеют deterministic rule.** H1 (tight orb), H2 (anchored half-width), H3 (drift skip) fit максимум 2 из 3 examples; только H4 (editorial / non-deterministic) консистентна. Killer evidence: N-J W1 и N-N W1 морфологически идентичны (D+R в одном orb window, similar timing offsets), но Marina рисует одно как 160-day full window, другое как 15-day tail. Engine `Domain.TransitCalendar` semantically корректен (1° orb threshold per planet class); Marina boundaries — editorial.

**Path 4 chosen (TL/user decision 2026-05-13):** structured editorial exceptions в test contract — engine не трогаем, 2 Cat 4 xfails закрываем через per-window tolerance override mechanism с явными reason-строками в коде. Implementation — TASK 4b (`neptune-window-structured-exceptions`).

**Phase 4b (Path 4 implementation) — ACCEPTED.** TASK 4b закрыт коммитом `d44d7c6` на main:
- Refactor `_assert_three_phase_intervals` с window-count + phase-set semantics + per-window 1-based tolerance overrides; импорт `aggregate_display_windows` из `outer_cards.py`.
- 2 structured editorial exceptions: Neptune-Jupiter Square W3 end ±20d, Neptune-Neptune Square W1 start ±200d. Reason-строки + cross-ref на memo § 4.4.
- User-spec vs engine reality reconciliation: spec listed N-J W2 = {Retrograde} и N-N W2 = {Retrograde} (вероятный typo), engine truth = {DirectReturn} для обоих. Worker применил engine truth, документировал в test comments. 2 typo flagged для пользователя.
- Unmark 2 Cat 4 Neptune xfails.
- Worker truncation post-implementation; TL salvage-commit'нул Worker'ову работу с явной attribution (subagent ID `a0d2e46652775fed8`).
- Tests: **115 passed + 8 xfailed = 123 total, 0 failed.**

**Phase 5 (Rulership-expanded target houses) — ACCEPTED.** TASK 5 закрыт коммитом `1d59431` на main:
- Path B (presentation-level) chosen; Path A не trigger'ил schema cascade.
- Новый модуль `services/api-python/app/pdf/rulership_houses.py` с `PLANET_RULES` dict (modern rulership), `cusp_sign()`, `rulership_houses()`, `target_house_set()`.
- Calendar-only scope соблюдён: `outer_cards.py` НЕ тронут (closed Phase 4 card-facts для golden-rule semantic зафиксированы).
- `transit_aspects_by_month` signature updated для приёма `natal_chart`; `solar.html.j2` обновлен под multi-house render; `builder.py` minimal Jinja context update.
- Calendar oracle Натальи validated против Marina pp. 22-23: Venus=[2,3,12], Mars=[3,8,9], Jupiter=[4,7], Neptune=[4,7]. Все 4 match exactly.
- Cusp validation: cusp 9 = 29.812° = Aries confirmed (НЕ Taurus); repeated cusp signs (Libra 2/3, Aries 8/9) корректно учитываются.
- 26 новых helper unit tests + 4 xfail flips (3 Cat 6 + 1 Cat 7 regression ban).
- Tests: **145 passed + 4 xfailed = 149 total, 0 failed.**

**Phase 6 (Per-context cutoff policy) — ACCEPTED.** TASK 6 закрыт коммитом `a1891cc` на main:
- Two-window-pair architecture в `transit_aspects_by_month`: `actual_*` для dedup / `_MIN_WINDOW_DAYS` / quincunx filter; `calendar_*` для presentation (`period_*_str`, `orb_*_jd` calendar entry output, bucket assignment).
- `calendar_start_jd = max(actual_start_jd, sr_jd)`, `calendar_end_jd = min(actual_end_jd, sr_jd + 365.25)`. Row drop если clipped >= clipped (полностью вне solar year), ПОСЛЕ dedup/filter на actual values.
- **Semantic shift в calendar context**: `orb_enter_jd` / `orb_exit_jd` per calendar entry output = clipped display bounds. Outer cards (Phase 4) НЕ затронуты (используют raw engine через `aggregate_display_windows`).
- Calendar oracle Натальи validated: `Нептун 90° Юпитер` clipped до `07.08.2026`; `Уран 0° MC` clipped до `07.08.2026`. No 2024/2027/2028 in calendar.
- Outer cards regression check passed — full loop dates (02.04.2024, 12.10.2024, 21.02.2027, 30.01.2028) intact в interval lists.
- 4 Phase 6 Cat 5 xfails flipped → passing.
- Один existing test (`test_calendar_short_windows_filtered`) adapted к Phase 6 semantic shift — flagged в Worker HANDOFF для TL ack.
- Tests: **149 passed + 0 xfailed + 0 failed.** Все Phase 4/5/6 acceptance contracts закрыты.

**Программа Transit Section Recovery — implementation work complete.** Phase 0/1/2/3/4/4a/4b/5/6 — все CLOSED. Остаётся Phase 7 multi-case calibration (validation).

**Phase 7 Stage A (Multi-case calibration) — ACCEPTED с verdict «Blockers identified — program NOT production-ready».** TASK 7 закрыт; Stage B не authorized. Calibration report в overlay `ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (423 lines).

Worker validated TL pre-mapped Marina inventory (3/3 cases confirmed, return_jd Δ < 60s). Per-case Stage A diff vs Marina:
- **05-ekaterina:** monthly table 51/52 cells match (1 Venus boundary diff = TYPE-A); per-house OK; outer-cards empty (TYPE-A allowlist gap); calendar OK.
- **07-mariya:** monthly table **6/13 cells match — TYPE-B regression** в `transit_themes.py:transit_matrix_by_month` (label-arithmetic bug); per-house OK; outer-cards correctly empty (matches Marina editorial); calendar OK.
- **10-danila:** monthly table 13/13 match; per-house OK; outer-cards empty (TYPE-A gap); calendar OK; case-10 card 3 has 4 windows not 3 (TYPE-C Marina editorial).

**TYPE-B root cause:** `transit_matrix_by_month` uses `sr + i * 30.4375` fractional iteration. Natalya was «lucky» (sr 07.08 ~02:30 UT → consecutive months). Case 07 Мария (sr=01.07.2025 19:11 UT) → i=2 lands 31.08.2025 = still August → label «Август 2025» duplicates, September never computed. 2 duplicate labels, 2 missing months, 6 wrong cells.

**Override count:** 2 / 10 (within Phase 4b gate threshold).

**Phase 7b (Multi-case calibration — Stage A re-validation + Stage B) — deferred until TASK 7a fix lands.**

**TASK 7a (Transit monthly table label-arithmetic fix) — ACCEPTED.** Commit `8a4865e` на main:
- Fix: integer calendar-month advance в `transit_matrix_by_month` (lines 546-588, 24 ins / 11 del). `datetime(y, m, 15, UTC)` для mid-month anchor; `[1st, next-1st)` для window. No new deps.
- Regression test `test_mariya_transit_matrix.py`: full equality `actual_labels == [Июль 2025, ..., Июль 2026]` (13 unique consecutive).
- Natalya baseline preserved 1:1 (mid-15 UTC anchor identical pre/post fix для Натальи early-UT solar return).
- Tests: **149/0/0 → 150/0/0** (regression test добавлен).

**TASK 7b (Phase 7 Stage A re-validation + Stage B closed-config calibration) — Worker hit STOP gate, ждёт TL/user decision.** TASK `2026-05-13-phase-7-stage-b-closed-config-calibration.md`, overlay commit `b8188e1` (Ready: yes). Worker subagent отработал Stage A.2 + создал `render_case.py` (Stage B.3, untracked) и STOP'нул на gate `case 07 < 13/13`.

**Stage A.2 outcome:**
- **Case 07 Мария monthly table = 11/13 rows match Marina** (не 13/13). 13 labels post-TASK 7a fix correct. 2 residual mismatches:
  - Июнь 2026: ours M=9/S=7/J=10/V=11 vs Marina 8/7/10/10 (Mars и Venus boundary).
  - Июль 2026: ours M=9/S=8/J=11/V=12 vs Marina 9/7/11/11 (Saturn и Venus boundary).
- **Cases 05, 10 — no regression.** Case 05 = 51/52, case 10 = 52/52 (sustained).
- **Stage B (B.1, B.2, B.4, B.5, B.6) — НЕ начат.** Только B.3 `render_case.py` создан (Stage A.2 prerequisite, authorized в spec).

**Diagnosis (Worker analysis, TL-verified):** 2 mismatched rows = **TYPE-A boundary anchor diffs**, не TYPE-B regression. Marina anchors monthly cells at **01 числа** (day-of-solar-return = 1st of solar month); наша конвенция = **mid-15** (`datetime(y, m, 15, UTC)`). Cusp transitions в 15-day gap:
- Mars 2026-06-05 (h=8→9), Venus 2026-06-11 (h=10→11) — Marina samples 01.06 (still h=8/10), ours samples 15.06 (already h=9/11).
- Saturn 2026-07-08 (h=7→8), Venus 2026-07-08 (h=11→12) — same family.

Это **same family как case 05 Venus Jul 2025 boundary** (calibration report § 4 item 3 TYPE-A note). TASK 7a fix targeted label arithmetic (`sr + i*30.4375` → integer calendar advance); cell values rows 12/13 идентичны pre/post TASK 7a — это не regression от 7a, это pre-existing convention gap.

**HANDOFF Worker→TL:** `project-overlays/astro/HANDOFFS/archive/2026-05-13-worker-to-tl-phase-7-stage-b-closed-config-calibration.md`. Override count unchanged: 2 (Натальи Phase 4b) — within threshold. Pytest baseline preserved 150/0/0.

**Решение пользователя 2026-05-13: Path D.** Открыт **TASK 7c** (`2026-05-13-phase-7c-gate-amendment-typea-monthly-boundary.md`, Tier C overlay-only, no Worker, TL inline). 5 fixations по user direction:
1. Case 07 labels — PASS (13/13 unique consecutive Июль 2025 → Июль 2026, TASK 7a сработал).
2. Case 07 monthly cells — 11/13 exact, 2 TYPE-A divergences (rows 12-13 Mars/Venus и Saturn/Venus).
3. Cause — deterministic anchor convention difference (Marina 01st vs наш mid-15), не Phase 7a regression, не label arithmetic bug.
4. Stage B gate amendment — 4 conditions (a)-(d): no dup/missing labels, no TYPE-B regressions, mismatches только в documented TYPE-A boundary rows, report verdict honest.
5. No product-code change в 7c — только TASK 7b spec + calibration report + STATUS_RU.

Path B (anchor convention convergence) deferred — strategically возможен, но scope wide (full Phase 1-7 re-validation Натальи + 05/07/10). Path C (STOP program) отклонён — теряем multi-case sense. Path D предпочтительнее Path A процедурно (отдельный TASK = явный ack-trail).

**TASK 7c — ACCEPTED + archived 2026-05-13.** Overlay commit `6b768ae`. Inline-применение: TASK 7b Stage A.2 gate amended (literal `13/13` → conditions (a)-(d)); calibration report § 3.2 (post-TASK-7a snapshot), § 4 (TYPE-A items 4-5 для case 07 rows 12-13 с cross-ref на item 3), § 6 (verdict update + follow-up reorg); STATUS_RU narrative обновлён. User ack на closure received → TASK 7b Worker resumes на Stage B per amended gate.

**TASK 7b — Stage B Worker resume — ACCEPTED.** Commit `c936dd1` на main:
- Stage B closed-config calibration landed: B.1 (case 05 outer cards 3 triples + facts из Marina pp. 34-37), B.2 (case 10 outer cards 3 triples + facts из pp. 16-19; case 10 card 3 = 4 windows engine output natively), B.3 (`render_case.py` committed), B.4 (`test_multi_case_calibration.py` — 33 parameterized tests), B.5 (case 05 Venus Jul 2025 = TYPE-A note only), B.6 (calibration report final update).
- Test helper `_assert_three_phase_intervals` generalized: optional `expected_window_count: int = 3`. Phase 4b Натальи структурные overrides — без изменений.
- Doc/comment generalization («3 intervals / три касания» → «3+ per Marina card») в `outer_cards.py` + `solar.html.j2`. **0 semantic code change** вне ALLOWLIST + FACTS extends.
- 0 новых tolerance overrides; всего 2 (Phase 4b Натальи). Threshold preserved (≤ 10 total; ≤ 5 per case).
- Engine / Haskell core / schema / fixtures / `transit_themes.py` / Phase 4b structured overrides — **0 lines changed**.
- Tests: **183 passed + 0 xfailed + 0 failed** (150 baseline + 33 new). cabal build up-to-date. backup parity ✓.
- **Production-readiness verdict (calibration report § 6): «Ready for Marina show — pending user ack».**

**Production-readiness gate — PASSED 2026-05-13.** (1) TASK 7b closed с verdict «Ready for Marina show — pending user ack» ✓; (2) **explicit user ack на updated calibration report received 2026-05-13** ✓. Программа Transit Section Recovery **CLOSED**. PDFs cases 05/07/08/10 — production-ready (показывать Марине разрешено).

**Известный editorial разрыв (документировать честно):** Path 4 закрывает **тестовую дисциплину**, не превращает 2 даты в «совпавшие». PDF продолжает рендерить engine-derived dates; Marina при показе видит engine boundaries для 2 Neptune windows, не свои эталонные. Это **known editorial divergence, accepted TL/user 2026-05-13**, не regression и не engine bug.

**Phase 7 gate clause:** если multi-case calibration (Phase 7) покажет накопление similar Neptune (или other slow-mover) overrides (>5 за case или >10 across all cases) — это сигнал что Path 4 структура не масштабируется и нужно пересмотреть продуктовый подход (возможно отдельный presentation-layer editorial override механизм). Phase 7 Worker фиксирует override count в HANDOFF; threshold exceeded → TL эскалирует пользователю до closing Phase 7.



**Tier A engine cascade (2026-05-11/12) принят и удержан.** Math engine стабилен:
- Quincunx revoke (scope = transit calendar only) — работает.
- Per-loop-pass orb-window scanner (orb_enter_jd / orb_exit_jd) — работает.
- Cross-year sample window (540d до/после соляра) — работает.
- Per-planet orb calibration (J/S/U/N = 1.0°, P = 1.25°) — эмпирически выведена по Натальину PDF.
- Schema cascade выполнен одним atomic коммитом (bright-line #8) — `5f4fbc9`.
- Tests: `cabal test` 242/242, `pytest` 85/85 — зелёный.

**Tier C presentation rebuild (2026-05-12) — преждевременный accept.** Проверка ограничилась календарём, monthly table и заголовками. Полная постраничная сверка раздела с эталоном не выполнялась. После сверки пользователем 2026-05-13:
- В трактовках по домам появился `Сатурн в 6 доме` (из расширенного horizon-а engine'а, 2024 год).
- Отсутствуют outer-planet карточки эталона (Уран-Венера, Нептун-Юпитер, Нептун-Нептун) с таблицами «Золотое правило транзита».
- «Дома цели» считаются placement-only без rulerships (теряются темы 2/3/7 у разных аспектов).
- Не разделены горизонты данных: один `annual_transit_table` используется и для солярного года (трактовки) и для full-loop scan (карточки).
- Конфликт артефактов: PDF собирался из worktree, основной repo содержит другой шаблон, render не несёт provenance.

**Программа recovery зафиксирована** в `ARCHITECTURE/transit-section-program-2026-05-13.md` — 8 секций (статус/gate, дефекты, root causes, архитектурное решение, фазы 0-7, hard acceptance assertions, запреты, порядок TASK'ов). Это новый SoT для всех presentation-работ по транзитам до закрытия программы.

Артефакты:
- Программа: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- Последний (нерабочий по презентации) PDF: `/tmp/astro-natalya-monthstart-iter1.pdf` — debug/QA only, не показывать.
- Продуктовый repo: ветка `claude/dreamy-moore-46f5eb`, последний commit `6894743`. Главная ветка `main` не тронута.
- Тесты зелёные, но не являются acceptance contract против Марины — это будет покрыто в Phase 2.

## Ждёт твоего решения

- **Marina framing memo draft** (lightweight post-closure artifact). Готовится отдельным overlay commit per user discipline («не смешивать framing memo с closure commit»). Содержание: production-ready cases (08/05/07/10) с явным framing на single Neptune editorial divergence (08 N-N W1 start +178d); per-case caveat block для 01/02/03/04 (12 future-work items в audit § A.2.1.D); explicit «NOT в supply» для 09 Анастасия (TYPE-D fixture/reference mismatch). User решает когда/если показать Марине.
- **Показ Марине — operational discipline post-closure:**
  - **Production-ready без caveats:** 08 Натальи (с framing memo на 1 editorial divergence).
  - **Production-ready с per-case framing:** 05 / 07 / 10 (anchor convention TYPE-A items documented в § 4).
  - **Render через framing:** 01 / 02 / 03 / 04 (future-work items affect Pluto cards, single-window alignment cases, lexical typo case 03 P-Mars).
  - **NOT в supply:** 09 Анастасия (TYPE-D данные).
  - PDFs rendered через `services/api-python/scripts/render_case.py --case-id ...` на HEAD `59ec177+` (provenance sidecar carry актуальный git_sha).

Локальная ветка `claude/dreamy-moore-46f5eb` остаётся (deferred cleanup) — не блокер.

## Срочные риски

**Программа Transit Section Recovery — REOPENED 2026-05-14, Phase 8 в работе.** TASK 7b closure 2026-05-13 был премат-clos'нут — contract gap в тестах Stage B (boundary assertions missing). **Дисциплинарная ответственность — на PTL** за неполный spec TASK 7b § B.4.

**Текущая Phase 8 discipline (post Phase 8E closure):**
- **Все 9 calibrated cases (01/02/03/04/05/07/08/09/10) — production-ready post-Reviewer-APPROVE + user-ack.** Phase 4b framing про 1 Neptune accepted divergence (08 N-N W1 start +178d, true editorial) — sole editorial divergence для Marina framing (Phase 8B Path 1 убрал N-J W3 +20d override как horizon truncation, не editorial; Phase 8E Stage E.5.a Scenario 1 confirmed N-N W1 -178d stays editorial — BEFORE buffer extension не изменила).
- Финальные client PDFs рендерить только через `services/api-python/scripts/render_case.py --case-id <case-id>` на HEAD post-Phase-8E или новее. Provenance sidecar должен показывать актуальный `git_sha`.
- `_3.pdf` (case 06) и Анастасия (case 09 TYPE-D SR mismatch ~60 min) — отдельные data quality items в backlog, держать отдельно от code regressions. Анастасия рендерится в общем production-ready наборе (audit § A.3 TYPE-D items), но Marina может заметить расхождение SR-time; user решает показывать или придержать до data revision.

**Historical дисциплина (на время программы 2026-05-11 → 2026-05-13) — задокументирована в `ARCHITECTURE/transit-section-program-2026-05-13.md`; во время программы запрещалось:**
- перезаписывать `expected.json` golden fixtures результатом текущего engine без diff review;
- считать зелёные snapshot tests доказательством близости к Марине;
- использовать full-loop horizon для текстов про текущий соляр;
- держать main и worktree как равноправные источники PDF;
- Worker subagents на Phase 3-7 пока Phase 1 + Phase 2 не закрыты;
- показ PDF Марине до закрытия программы.

**Phase 4b — 1 Neptune editorial divergence (N-N W1 start +178d) на Натальи — accepted divergence per Path 4 / TASK 4b**; TL framing для Марины перед показом Наталю обязателен. (N-J W3 end +17d было misclassified как editorial; Phase 8B Worker B2.1 trace показал — это была engine finite-horizon truncation; после Phase 8B horizon extension сходится с Marina ±2d. Phase 4a memo Erratum документирует reclassification.)

**Anchor convention (mid-15 vs Marina 01st) — 5 TYPE-A boundary rows документированы в калибровочном отчёте § 4. Path B convergence — отдельная будущая программа если потребуется.

Дрейф между prescribed architecture (phases 0.1/0.2) и фактическим кодом (0.5+) — без изменений с 2026-05-06. Не пожар.

## На очереди

Программа Transit Section Recovery, фазы 0-7:

- **Phase 0** (freeze + audit trail) — **CLOSED** 2026-05-13 (architecture document + STATUS_RU freeze).
- **Phase 1** (single source of truth + render provenance) — **CLOSED** 2026-05-13 (TASK 1 accepted, commit `9793d5d`, worktree merged в main).
- **Phase 2** (hard acceptance assertions) — **CLOSED** 2026-05-13 (TASK 2 accepted, commit `fb47aca`, 29 hard assertions с xfail-strict).
- **Phase 3** (transit horizon split) — **CLOSED** 2026-05-13 (TASK 3 accepted, commit `70185b0`, Path B presentation-level, 4 xfail flips).
- **Phase 4** (outer-planet cards generator) — **CLOSED** 2026-05-13 (TASK 4 accepted, commit `8c9588d`, Path 3 7 xfail flips + 2 Cat 4 reason updates).
- **Phase 4a** (Transit contact window semantics — analysis memo) — **CLOSED** 2026-05-13 (TASK 4a accepted, memo deliverable, Path 4 chosen by TL/user).
- **Phase 4b** (Neptune window structured exceptions — Path 4 implementation) — **CLOSED** 2026-05-13 (TASK 4b accepted, commit `d44d7c6`, 2 Cat 4 xfail flips, Worker truncation salvaged).
- **Phase 5** (rulership-expanded target houses) — **CLOSED** 2026-05-13 (TASK 5 accepted, commit `1d59431`, Path B presentation-level, 4 xfail flips, 26 new helper tests).
- **Phase 6** (per-context cutoff policy) — **CLOSED** 2026-05-13 (TASK 6 accepted, commit `a1891cc`, 4 Phase 6 xfail flips, two-window-pair architecture).
- **Phase 7 Stage A** (multi-case calibration validation) — **CLOSED** 2026-05-13 с verdict «Blockers identified» (TYPE-B regression в case 07 monthly table; calibration report committed). Stage B deferred.
- **TASK 7a** (transit monthly table label-arithmetic fix) — **CLOSED** 2026-05-13 (commit `8a4865e`, 149/0/0 → 150/0/0, Natalya baseline preserved, case 07 13 labels validated).
- **TASK 7b** (Phase 7 Stage A re-validation + Stage B closed-config calibration) — **CLOSED** 2026-05-13 (commit `c936dd1`, 150 → 183 passed, calibration report verdict «Ready for Marina show — pending user ack»). Финальная implementation TASK программы. **NEXT — user explicit ack** на updated calibration report → recovery program closes; PDF можно показывать Марине.
- **TASK 7c** (overlay-only gate amendment, TYPE-A monthly boundary) — **CLOSED** 2026-05-13 (overlay commit `6b768ae`, amended gate (a)-(d) для Stage A.2 → Stage B continuation).
- **Phase 8.0** (audit trail reopen) — **CLOSED** 2026-05-14 (overlay STATUS downgrade + calibration § 6 verdict update).
- **Phase 8A + 8C** (audit + boundary test contract) — **CLOSED** 2026-05-14 (commit `9740075`, 36 boundary assertions + 2 xfail-strict для Данила, 219 passed + 2 xfailed).
- **Phase 8B** (lexical + Данила horizon fix Path A + Path 1 reclassification + unmark xfail) — **CLOSED** 2026-05-14 (atomic product commit + overlay commit; pytest 221 passed + 0 xfailed + 0 failed). Path 1 amendment: N-J W3 end reclassified as horizon truncation; Phase 4a memo Erratum subsection; N-J W3 +20d override removed; N-N W1 +200d override stays.
- **TASK 8D** (allowlist + facts extension для cases 01/02/03/04/09 + boundary tests + lexical title assertions) — **WORKER COMPLETE** 2026-05-14, awaiting Reviewer (atomic product commit + overlay commit; pytest 286 passed + 0 xfailed + 0 failed = 221 baseline + 36 new boundary + 29 lexical title parametrize). 20 new triples (5+2+9+2+2) + 100 fact cells transferred from Marina PDFs; 5 PDFs rendered + sidecar-verified. § 4 item 6 [RESOLVED]; § 6 verdict обновлён на «Ready for Marina show — pending user ack». 0 new tolerance overrides; 14 of 20 cards excluded from boundary tests с задокументированными per-card findings (audit § A.2.1.D). Финальная implementation TASK Phase 8.
- **Phase 4** (outer-planet cards generator) — только для тех outer-aspects, что представлены в эталоне как карточки.
- **Phase 5** (rulership-expanded target houses) — Tier C с эскалацией до Tier A при shared core helper.
- **Phase 6** (per-context cutoff policy) — explicit clipping rules.
- **Phase 7** (multi-case calibration) — default cases 05/07/10, либо обоснованный выбор 3 из 8.

Дальнейшие phase 8 sub-tasks:
- **TASK 8D** — **WORKER COMPLETE 2026-05-14** (см. выше); awaiting Reviewer + user ack.
- **TYPE-D backlog** (`_3.pdf`, Анастасия SR mismatch) — отдельные data-revision tasks вне Phase 8 implementation programme.
- **Engine `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE` extension** (case 01 Neptune cards pre-buffer truncation; audit § A.2.1.D Future Work item 1) — отложено как post-program improvement.
- **Single-Marina-window alignment helper** (case 02 + 04 + case 03 partial — Marina W1 = engine W2/W3/W4; audit § A.2.1.D Future Work item 2) — отложено.
- **Marina Pluto display rule** (case 01 + 03 Pluto cards; audit § A.2.1.D Future Work item 3) — отложено.

Backlog вне программы (на паузе до её закрытия):
- `solar-nodes-lilith-retro-display` — Tier A, без явного запроса Марины не запускать.
- `consultation-summary-matrix-rewrite` — пауза.
- `section-order-recon` — пауза.

## Не делаем сейчас

- **«Solar nodes / Lilith / retro display» без её явного запроса.** Tier A.
- **Публичный хостинг репозитория** (GitHub / GitLab / Gitea). Без отдельного «ок» не добавляем.
- **SaaS-направление и B2C-сайт.** Сняты, проект — внутренний инструмент.
- **Полная сверка архитектурного документа с фактическим кодом.** Откладывается.
- **Презентационные правки раздела Транзиты вне программы Transit Section Recovery.** Все правки идут через её phases в указанном порядке.
- **Дальнейшая калибровка орбисов транзитного движка на одном Натальином case.** Per-planet значения выведены эмпирически; расширение калибровки требует ≥3-5 cases (Phase 7 программы).
