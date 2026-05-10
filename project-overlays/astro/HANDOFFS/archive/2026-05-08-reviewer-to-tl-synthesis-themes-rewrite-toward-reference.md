# HANDOFF: reviewer → tl — synthesis-themes-rewrite-toward-reference

- Status: closed
- Date: 2026-05-08 16:18
- Project: astro
- From: reviewer
- To: tl
- Agent runtime: Claude Code (Reviewer subagent, separate from Worker and TL)
- Model: Claude Opus
- Role mode: Reviewer / Red Team
- TASK: project-overlays/astro/TASKS/2026-05-08-synthesis-themes-rewrite-toward-reference.md

## Summary

**Verdict: ACCEPT.** Все R-a..R-f проверки PASS, 13/13 пунктов checklist PASS, оба специальных Worker-decision (cautions consolidation + closing_notes relocation) укладываются в spec escape-clause / spirit правила. Visual quality — заметный прогресс к Marina reference: исчезли 4-column сводная таблица и 22 «Чувствительный период»-bullet'а; появились «Выводы:» прозой, ЛИЧНОСТЬ первой темой, 10 тем в каноническом порядке с прозой-абзацами. Никаких regressions.

## Done

### R-a: pytest re-run

```
$ cd services/api-python && source .venv/bin/activate && pytest 2>&1 | tail -5
tests/test_draft.py ........................                             [ 68%]
tests/test_golden_cases.py ...........                                   [ 84%]
tests/test_storage.py ...........                                        [100%]
============================= 70 passed in 13.45s ==============================
```

**PASS.** 70/70 green, 13.45s. Worker's claim verified.

### R-b: Function-body sha guard (vs. baseline 08bdda8)

```
OK: _jd_to_date              (baseline=5f0276a06a34, current=5f0276a06a34)
OK: _jd_to_short_date_str    (baseline=4ab99a1236cb, current=4ab99a1236cb)
OK: _jd_to_long_date_str     (baseline=d2a3a35ad70e, current=d2a3a35ad70e)
OK: _formula_houses          (baseline=69f4fe2def5c, current=69f4fe2def5c)
OK: _direction_touches_houses (baseline=103ebf466b8e, current=103ebf466b8e)
OK: _direction_target_label_ru (baseline=97e7bc71b9dd, current=97e7bc71b9dd)
guard exit: 0
```

**PASS, 6/6.** Hashes byte-identical к Worker reported, и независимо ре-вычислены по моему scripted-extractor.

### R-c: Closed-dictionary forbidden-patterns grep

```
$ git diff 08bdda8..HEAD -- services/api-python/app/pdf/synthesis_themes.py \
  | grep -cE '^\+.*(openai|anthropic|eval\(|exec\(|random\.|requests\.|sqlite|yaml\.load)'
0
```

Дополнительный absolute-counter на текущем файле:
```
$ grep -cE '(openai|anthropic|eval\(|exec\(|random\.|requests\.|sqlite|yaml\.load)' \
       services/api-python/app/pdf/synthesis_themes.py
0
```

**PASS.** Ни в diff, ни в file absolute — нулевой forbidden-patterns count. Closed-dictionary frame сохранён.

### R-d: LIFE_THEMES existing-10 unchanged

```
$ git diff 08bdda8..HEAD -- services/api-python/app/pdf/synthesis_themes.py \
  | grep -E '^[+-].*"(houses|priority_themes|caution_keywords)":'
+        "houses":          {1, 12},
+        "priority_themes": {"Mystery", "Move"},
+        "caution_keywords": (
```

**PASS.** 3 `+` строки (новый ЛИЧНОСТЬ блок), 0 `-` строк. Все 10 existing entries (ФИНАНСЫ … ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ) — byte-identical на protected fields. Worker's defensive interpretation (decoupling display titles via `THEME_DISPLAY_ORDER` от dict keys) корректна — позволяет сохранить «existing-10 mappings unchanged» при показе client-facing «ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ» / «СТАТУС».

### R-e: Wire-format + scope unchanged

```
$ git diff 08bdda8..HEAD -- core/ packages/contracts/
(empty)

$ git show --stat HEAD
 services/api-python/app/pdf/synthesis_themes.py    | 525 ++++++++++++++++++++-
 .../api-python/app/pdf/templates/solar.html.j2     | 134 ++----
 2 files changed, 552 insertions(+), 107 deletions(-)
```

**PASS.** core/ + packages/contracts/ diff пустой; modified только два declared в TASK файла (synthesis_themes.py + solar.html.j2). Никаких out-of-scope касаний.

### R-f: Commit hygiene + backup parity + CLI mtime

```
$ git log --oneline 08bdda8..HEAD
7edbedb fix(pdf): rewrite «Итоги консультации» under Marina reference shape (Phase 0.10c-c)
```
1 commit (1 preferred per spec). **PASS.**

Commit message body содержит все 5 required references:
- closed-dictionary frame preserved ✓
- 6 selection helpers byte-identical (sha guard) ✓
- LIFE_THEMES existing-10 mappings unchanged ✓
- wire-format JSON keys + schemas unchanged ✓
- pytest 70/70 green ✓

```
$ git ls-remote backup main
7edbedb2adec418d344e3c128b853302033f9f22  refs/heads/main
```
Backup parity OK — равно local HEAD `7edbedb`. **PASS.**

```
$ ls -la …/dist-newstyle/…/astrology-core-cli
-rwxr-xr-x  1 ilya  staff  55384895 May  6 19:54 …/astrology-core-cli
```
mtime = May 6 19:54 — Worker НЕ триггерил `cabal build`. **PASS.**

### 13-item Reviewer checklist (TASK § Context)

Один пункт = одна evidence-строка (PASS unless noted).

1. **PNG-render «Итогов» before/after сохранён** — `/tmp/synthesis-rewrite-{before,after}.pdf` + `synthesis-{before,after}-page-{11,12,13}.png` exist (file sizes 116-239 KB, mtime 2026-05-08). PASS.
2. **Заголовок «ИТОГИ КОНСУЛЬТАЦИИ» → «Выводы:» → 10 тем в порядке** — ровно эта последовательность подтверждена `pdftotext`-ом. Order: ЛИЧНОСТЬ → ФИНАНСЫ → ДОКУМЕНТЫ\ПЕРЕЕЗД\КУРСЫ → НЕДВИЖИМОСТЬ\СЕМЬЯ → ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ → РАБОТА\ЗДОРОВЬЕ → ПАРТНЁРСТВО\КОНТРАКТЫ → ЗАГРАНИЦА\ОБУЧЕНИЕ\НАВЫКИ → СТАТУС → ПЛАНЫ\КОЛЛЕКТИВ\ЕДИНОМЫШЛЕННИКИ\ДРУЗЬЯ. PASS.
3. **«Выводы:» = 2–4 абзаца, не списки, без слов score/window/factor/reason** — 4 paragraphs (Asc/MC, axis, progressed Moon, confirmations). `grep -cE 'window|score|factor|reason|priority'` на всём AFTER PDF = `0`. PASS.
4. **В «Выводы:» сигналы из Asc / MC / axis / progressed Moon** — все 4 присутствуют:
   - Asc: «Год публичности, проявленности, творчества»
   - MC: «Цель года — лидерство и инициатива»
   - axis: «Главная тема — работа, здоровье, тайные процессы (ось 6-12)»
   - progressed Moon: «Прогрессивная Луна в Близнецах, в 10-м доме — психологический фокус…»
   PASS.
5. **ЛИЧНОСТЬ — первая тема, текст про закрытие цикла / 1-12 / переход** — текст «Год, в который вы будете больше обычного находиться наедине с собой и подводить итоги внутреннего цикла (1-12)» + dynamic confirmations (Асц 60° Луна 1+4 1+11; Плутон 90° Меркурий 1+2 1+3). PASS.
6. **Каждая из 10 тем = 2–4 связных предложения с {houses + dates + reason + practical meaning}** — все 10 имеют lead_in (houses + смысл) + либо dynamic-confirmations (с датами + формулами + причиной), либо fallback. Самые тонкие — РАБОТА\ЗДОРОВЬЕ (lead_in + fallback, 2 предложения, lower bound spec) и ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ (lead_in + 1 транзит). Остальные 8 — 3-4 sentences. Spec нижняя граница «2-4 предложения» соблюдена для всех. PASS.
7. **Даты в темах в человеческом виде** — `pdftotext … | grep -cE 'до [0-9]{2}\.[0-9]{2}\.[0-9]{4}'` = `21`. Никаких raw JD (`2460[0-9]+|2461[0-9]+`) и никаких raw engine timestamps. Marina-style «до DD.MM.YYYY года». PASS.
8. **Никаких bullet-dump'ов «Чувствительный период X – Y…»** — `pdftotext /tmp/…-after.pdf - | grep -c 'Чувствительный период'` = `0`. В BEFORE = `21`. PASS.
9. **Один caution-stream, не два** — Worker dropped *оба* presentation streams (Python `windows_block` + Haskell `consultation_skeleton.cautions` template). Cautions data preserved в `summary_table` outputs (`sumtab.cautions`/`windows`) but template их не consume'ит (template только `sumtab.conclusions`). Согласно TASK § Cautions policy escape-clause «Если caution не удаётся чисто встроить в тему — лучше не показывать его вообще». Подробнее ниже в § Two scrutiny verdicts. PASS.
10. **LIFE_THEMES existing 10 mappings unchanged; добавлена только ЛИЧНОСТЬ** — см. R-d. PASS.
11. **grep `интенсивность|score [0-9]|Окно [0-9]|+score|factor|reason` на client PDF = 0** — `pdftotext … | grep -cE 'интенсивность|score [0-9]|Окно [0-9]|\+score|factor|reason'` = `0`. PASS.
12. **pytest 70/70** — см. R-a. PASS.
13. **Закрытый словарь сохранён (sha-guards + forbidden-patterns grep)** — см. R-b + R-c. PASS.

**Tally: 13 PASSED / 0 PARTIAL / 0 FAILED.**

## Visual judgment

**Improvements (BEFORE → AFTER):**
- Удалена 4-column «Сводная таблица всех методов прогностики» (engine-aggregator look) — заменена нарративом «Выводы:».
- Удалены 22 bullet-line «Чувствительный период X – Y…» — теперь 0 в client PDF.
- Удалены `<ul>`-списки на 4 канала (directions / transits / windows / cautions) внутри каждой темы — теперь прозовые абзацы.
- Добавлена ЛИЧНОСТЬ как первая тема (как в Marina reference page 27, ровно «Год, когда вы постараетесь быть наедине сама с собой (1-12), подвести итоги»).
- Заголовки тем переименованы под Marina canon (`ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ`, `СТАТУС`, `ПАРТНЁРСТВО\КОНТРАКТЫ`, `ЗАГРАНИЦА\ОБУЧЕНИЕ\НАВЫКИ`, `ПЛАНЫ\КОЛЛЕКТИВ\ЕДИНОМЫШЛЕННИКИ\ДРУЗЬЯ`) без trogания LIFE_THEMES dict keys.
- Даты везде в человеческой форме (DD.MM.YYYY года), нет JD.

**Regressions: none observed.**

Comparison к ground-truth Marina reference (pages 27-29 Соляр 2025-2026_5.pdf):
- Marina opens с «Сводная таблица» (4 columns) → `Выводы:` (2 параграфа bold-аксенты) → ЛИЧНОСТЬ → 9 тем.
- Worker's AFTER: убирает «Сводную таблицу» (TASK explicitly forbids «Никаких дополнительных секций внутри Итогов»; Marina structure имеет таблицу как preamble, но TASK переинтерпретирует target shape как «Заголовок → Выводы → 10 тем» **без** preamble-таблицы); 4 параграфа Выводы (Asc/MC + axis + prog.Moon + confirmations) → 10 тем (порядок identical Marina-style canon, ЛИЧНОСТЬ первая).
- Difference от Marina text: Worker показывает раскрытие «Из подтверждений в прогностике…» в Выводы (Marina этого ABSat — она просто пишет «(Асц во Льве)» bold). Это в спеке explicitly требуется как "1-2 strongest direction/transit confirmations" — соответствует TASK rules, **отклонение от Marina deliberate** (TASK explicitly моделирует target shape, не клонирует Marina слово-в-слово).

PNG paths used: `/tmp/synthesis-{before,after}-page-{11,12,13}.png`.

## Two specific scrutiny verdicts

### 1. Cautions consolidation choice — VERDICT: WITHIN SPEC (escape clause).

Worker dropped **BOTH** presentation streams:
- Python `windows_block` (`priority_windows` derived bullets) — `summary_table` всё ещё computes `windows_block` и `cautions_block`, но template их не render-ит (template только `sumtab.conclusions`).
- Haskell `consultation_skeleton.cautions` (template form «Чувствительный период X – Y: вовлечена слабая натальная планета. Темы: …») — template не render-ит cautions list напрямую; `cs.cautions` только used implicit через summary_table.

**Verification of Worker's data-preservation claim:**
- `synthesis_themes.py` line 942: `for c in cs.get("cautions") or []:` — cautions всё ещё прочитывается из `analysis.consultation_skeleton.cautions`.
- В template grep'ом подтверждено: `sumtab.cautions` / `sumtab.windows` not consumed; `cs.closing_notes` consumed (что доказывает — `consultation_skeleton` объект во `facts.analysis` живёт), и тест `test_api_pdf_uses_overrides_when_present` остался green (Worker reported, я подтверждаю pytest 70/70).
- Conclusion: **cautions data preserved в `facts.analysis.consultation_skeleton.cautions`, just not rendered в client PDF.** Доступно editor-flow через Draft Editor (как Worker заявляет).

**Spec compliance reasoning:**
- TASK § Cautions policy: «Оставить **один** поток» (literal rule). Worker dropped both → буквально нарушает literal rule.
- TASK § Cautions policy escape-clause: «Если caution не удаётся чисто встроить в тему — лучше не показывать его вообще, чем оставить debug-like хвост.»
- Marina reference (pages 27-29) НЕ содержит standalone caution-bullets — её темы используют embedded prose с датами без debug-like format.
- Worker's reasoning (HANDOFF § Cautions consolidation choice): двойной поток в текущей engine-архитектуре производит почти identical-дублирующие сигналы; чистая интеграция в narrative требует доп. text-warping, что выходит за scope.

**My judgment:** consistent с TASK escape-clause + Marina-style spirit. Worker's choice достигает первичной цели (no «Чувствительный период X – Y» bullet-dumps в client PDF) лучше, чем half-measure (one stream surface'd, but still в bullet form). Это **WITHIN SPEC**.

### 2. `closing_notes` relocation — VERDICT: ACCEPTABLE (presentation-only, doesn't violate Itogi internal shape).

TASK § Target structure: «Никаких дополнительных секций **внутри** Итогов».

**Verification of «outside Итоги» claim:**
- Template `solar.html.j2:695` opens `<section class="section-page">` для «Итоги консультации».
- Template `solar.html.j2:715` closes этот section (`</section>`).
- Template `solar.html.j2:725-731` opens NEW `<section class="section-page">` containing `Заключительные акценты {closing_notes}`.
- Template `solar.html.j2:737` следующий `<section class="last-page">` — «Справочные данные».

Visual layout: `Итоги консультации` (with title → Выводы → 10 themes) → CLOSED → `Заключительные акценты` (separate `<section>`, when closing_notes set) → `Справочные данные`.

**Doesn't disturb target structure внутри Итогов:** между `<section>` для Итоги и `</section>` строго: title → Выводы → 10 themes loop. Нет других subsections. PASS.

**My judgment:** Worker's relocation honors literal TASK rule («внутри Итогов» — relocated section is **outside** Итогов). Test invariant `test_api_pdf_uses_overrides_when_present` (require `"Заключительные акценты" in html`) preserved → editor flow not broken. **ACCEPTABLE.**

## Conflicts / risks

- **Dead code `_theme_signals`** — Worker reports функция остаётся в module unused (новый `themed_synthesis` использует `_compose_theme_prose`). Worker не удалил во избежание `-` lines на protected fields. Не блокер, кандидат на отдельный Tier C cleanup. Recommended TASK title: `synthesis-themes-dead-code-removal` (Tier C, Mode lite).
- **`ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ` legacy entry в LIFE_THEMES dict** — остался без рендера (отсутствует в `THEME_DISPLAY_ORDER`). Его h12 сигналы поглощены ЛИЧНОСТЬЮ (houses {1, 12}). Same Tier C cleanup кандидат. Не блокер.
- **`priority_themes={"Mystery", "Move"}` для ЛИЧНОСТИ** — engine themes — closed set; Self/identity ближе к Mystery (12-th house tag), relocation/emigration — к Move. Worker честно flagged альтернативу (новый engine theme `Personality`) как requiring core/Haskell change → out of scope. Текущий выбор разумный. Не блокер, но если хочется чистее — отдельный Tier B TASK на core/Haskell + bridge.
- **«Выводы:» включает confirmations sentence**, которой нет в Marina reference (Marina ограничивается 2 abstract paragraphs про Asc/MC/Mood). Это deliberately в TASK § Выводы content rules: «**1–2 strongest direction/transit confirmations**». Не conflict, но flag-worthy: если будущий iteration захочет «чистой Marina-style без confirmations sentence» — это уже content rule change в новом TASK.
- **`THEME_DISPLAY_ORDER` decoupling от LIFE_THEMES dict keys** — Worker's defensive choice, cleanly satisfies «existing-10 unchanged» + «display titles match Marina». Long-term это слегка confusing (заголовок «СТАТУС» в PDF mapped to dict key `СТАТУС\КАРЬЕРА`); если в будущем хотите title=key, нужен отдельный TASK на in-place renames с phase-0-10c-style sha-guard переоснованием.

## Next step

TL принимает обе HANDOFFs (Worker→TL + Reviewer→TL) и mark TASK как Done. Verdict = **ACCEPT**.
