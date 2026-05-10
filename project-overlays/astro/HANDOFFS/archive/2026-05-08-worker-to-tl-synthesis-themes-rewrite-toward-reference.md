# HANDOFF: worker → tl — synthesis-themes-rewrite-toward-reference

- Status: closed
- Date: 2026-05-08 16:10
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code (Worker subagent, separate from TL session)
- Model: Claude Opus
- Role mode: Worker (subagent isolation per TL graded rule 2026-05-06, Mode normal)
- TASK: project-overlays/astro/TASKS/2026-05-08-synthesis-themes-rewrite-toward-reference.md

## Summary

«Итоги консультации» переписаны в Marina-style shape: заголовок → `Выводы:` (2–4 абзаца) → 10 тематических блоков прозой в целевом порядке (ЛИЧНОСТЬ → ФИНАНСЫ → ДОКУМЕНТЫ\ПЕРЕЕЗД\КУРСЫ → НЕДВИЖИМОСТЬ\СЕМЬЯ → ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ → РАБОТА\ЗДОРОВЬЕ → ПАРТНЁРСТВО\КОНТРАКТЫ → ЗАГРАНИЦА\ОБУЧЕНИЕ\НАВЫКИ → СТАТУС → ПЛАНЫ\КОЛЛЕКТИВ\ЕДИНОМЫШЛЕННИКИ\ДРУЗЬЯ). Один commit `7edbedb` поверх `08bdda8`, pytest 70/70 green, backup parity ✓.

## Done

### Code changes (одним коммитом `7edbedb`)

**`services/api-python/app/pdf/synthesis_themes.py`** (+525/–) :
- Добавлена запись `LIFE_THEMES["ЛИЧНОСТЬ"]` с `houses={1, 12}`, `priority_themes={"Mystery", "Move"}` (engine surfaces 12-th house Mystery flags + Move/relocation flags), `caution_keywords=("лично", "себе", "уединен", "итог", "переход", "эмигр", "удалён", "удален", "релокац", "имидж", "самоощущ")`. Существующие 10 entries не тронуты на 3 protected-полях.
- Добавлен список `THEME_DISPLAY_ORDER: list[tuple[str, str]]` — presentation contract (display_title, life_themes_key) для рендеринга 10 блоков в целевом порядке. ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ entry остаётся в LIFE_THEMES (no `–` lines), но не появляется в display order — её h12 сигналы поглощаются через `houses={1, 12}` ЛИЧНОСТИ.
- Добавлен `_jd_to_dotted_year_str` (Marina idiom «до DD.MM.YYYY года»).
- Добавлен `_THEME_PROSE` static dict — lead_in + fallback фразы для каждого из 10 display titles (closed dictionary).
- Добавлен `_direction_describe_ru`, `_transit_describe_ru` — компактные RU-фразы для одной дирекции / транзита.
- Добавлен `_structural_houses(analysis) → set[int]` = {1} ∪ primary_axis ∪ secondary_axis houses.
- Добавлен `_select_strongest_signals(facts, structural)` — реализация (b) canon: directions matching Asc/MC OR formulas overlapping structural set; outer transits в structural set; sort by exit_jd / enter_jd; at most 2 directions + 1 transit. priority_windows НЕ используются как primary selector.
- Добавлен `_compose_summary_paragraphs(facts) → list[str]` — собирает 2–4 абзаца «Выводы:» из `consultation_skeleton.opening` (asc_phrase + mc_phrase в одном абзаце; primary + secondary axis в следующем) + `psychological_setting` + 1–2 strongest direction/transit confirmations.
- Добавлен `_compose_theme_prose(facts, display_title, theme_def) → list[str]` — 2–4 абзаца на тему: lead_in + dir confirmations + transit confirmations + fallback when no signals. Использует frozen `_direction_touches_houses` / `_formula_houses` для selection.
- Заменён `themed_synthesis(facts)` — теперь итерирует `THEME_DISPLAY_ORDER`, эмитит `{title, paragraphs}` (был `{title, signals}`).
- Расширен `summary_table(facts)` — добавлен ключ `conclusions` (вызов `_compose_summary_paragraphs`); 4 cell-fields оставлены unchanged для BC, но не рендерятся в template.
- Добавлен публичный `summary_paragraphs(facts) → list[str]` (тонкая обёртка). `__all__` расширен.
- 6 protected helpers (`_jd_to_date`, `_jd_to_short_date_str`, `_jd_to_long_date_str`, `_formula_houses`, `_direction_touches_houses`, `_direction_target_label_ru`) **byte-identical** к baseline `08bdda8`. `_theme_signals` оставлен как dead-code (не вызывается, но не удалён — нет diff-noise на старых entries).

**`services/api-python/app/pdf/templates/solar.html.j2`** (–134, +/–):
- Удалён `<table>` блок «Сводная таблица всех методов прогностики» (4 columns) — Marina reference его не имеет в final synthesis.
- Удалён старый рендер `Выводы по сферам жизни` с bullet-list `<ul>` × 4 (directions / transits / windows / cautions).
- Новый рендер: title → «Выводы:» (`<p>` × N) → 10 `<div class="section-block">` с `<h3>` + `<p>`-абзацами на каждую тему.
- `Заключительные акценты` (editor-only `closing_notes`) вынесены в **отдельный `<section>` ПОСЛЕ «Итоги»**, чтобы synthesis-секция держала target shape exactly «title → Выводы → 10 themes»; editor PDF re-render test (`test_api_pdf_uses_overrides_when_present`) остался green.

### Function-body sha-guard output (все 6 OK)

```
OK: _jd_to_date (baseline=5f0276a06a34, current=5f0276a06a34)
OK: _jd_to_short_date_str (baseline=4ab99a1236cb, current=4ab99a1236cb)
OK: _jd_to_long_date_str (baseline=d2a3a35ad70e, current=d2a3a35ad70e)
OK: _formula_houses (baseline=69f4fe2def5c, current=69f4fe2def5c)
OK: _direction_touches_houses (baseline=103ebf466b8e, current=103ebf466b8e)
OK: _direction_target_label_ru (baseline=97e7bc71b9dd, current=97e7bc71b9dd)
guard exit: 0
```

### Closed-dictionary forbidden-patterns grep

```
git diff 08bdda8..HEAD -- services/api-python/app/pdf/synthesis_themes.py | grep -cE '^\+.*(openai|anthropic|eval\(|exec\(|random\.|requests\.|sqlite|yaml\.load)'
→ 0
```

### LIFE_THEMES existing-10 unchanged

```
git diff 08bdda8 -- services/api-python/app/pdf/synthesis_themes.py | grep -E '^[+-].*"(houses|priority_themes|caution_keywords)":'
→ +        "houses":          {1, 12},
  +        "priority_themes": {"Mystery", "Move"},
  +        "caution_keywords": (
```

3 строки добавлений (для нового ЛИЧНОСТЬ блока), 0 удалений / модификаций существующих 10.

### Wire-format unchanged

```
git diff 08bdda8 -- core/ packages/contracts/
→ (empty)
```

### pytest

- before changes: 70 passed (на baseline `08bdda8`).
- after changes: **70 passed** в 23.31s. Никаких xfail / skipped изменений.
  - `tests/test_draft.py::test_api_pdf_uses_overrides_when_present` остался green после переноса `closing_notes` в отдельный `<section>` ПОСЛЕ «Итоги».

### pdftotext forbidden-patterns grep на AFTER PDF

```
pdftotext /tmp/synthesis-rewrite-after.pdf - | grep -cE 'интенсивность|score [0-9]|Окно [0-9]|\+score|factor|reason'
→ 0
```

Дополнительно проверил на `Чувствительный период|Сводная таблица` — 0 в AFTER, 22 в BEFORE.

### Cautions consolidation choice + reasoning

**Выбрано: drop BOTH presentation-side caution streams** (Python `windows_block` bullets + Haskell `consultation_skeleton.cautions` "Чувствительный период X – Y…" template).

**Reasoning:**
1. Marina reference (Соляр 2025-2026_5.pdf pages 27-29) не показывает caution-bullets как отдельный блок ни в `Выводы:`, ни в темах — cautions встроены в narrative прозу через дирекции / транзиты с датами.
2. TASK § Cautions policy: «Если caution не удаётся чисто встроить в тему — лучше не показывать его вообще, чем оставить debug-like хвост.» Двойной поток в текущей engine-архитектуре производит почти идентичные дублирующие сигналы; чистая интеграция в narrative требовала бы доп. text-warping логики, которая выходит за scope содержательной правки.
3. Cautions остаются в `facts.analysis.consultation_skeleton.cautions` для editor consumption через Draft Editor (consultant может добавить их в `closing_notes` через PUT `/draft/overrides`).
4. Engine-level priority windows + cautions не тронуты — они нужны для будущих editor flows и для Reviewer-режима, но в client PDF не surfaced.

### Composition decisions worth noting

- **(b) canon implementation:** «strongest direction/transit confirmations» = signals where `directed`/`target` ∈ {Asc, MC} OR formula-houses ∩ ({1} ∪ primary_axis_houses ∪ secondary_axis_houses) ≠ ∅. Sort directions by `exit_jd` ascending (earliest-clearing first — matches Marina's «ближайший срок» idiom). At most 2 directions + 1 transit (count Marina uses in reference). priority_windows DO NOT influence selection — used neither as primary signal source nor as a sort key. (See `_select_strongest_signals` + `_structural_houses`.)
- **«Выводы:» paragraphing:** 4 paragraphs total when all data present — (1) Asc + MC bound by `; `, (2) primary + secondary axis bound by `; `, (3) progressed Moon prose, (4) confirmations sentence introduced by «Из подтверждений в прогностике на этих темах: …». Each paragraph collapses gracefully to skip when its source field is null/missing.
- **Per-theme paragraphing:** 2 paragraphs minimum (lead_in + fallback when no engine signals); up to 4 when both directions and transits hit (lead_in + dir-paragraph + transit-paragraph). Direction phrasing strips the original «по формулам …» tail and reattaches only the houses-relevant subset (so e.g. ФИНАНСЫ shows formula `10+8` only, not `10+3, 10+8, 10+9`). Retrograde-loop transits dedup'ed by `(planet, house, exit_jd)` key.
- **Date format:** all dates in theme prose + Выводы: rendered as `DD.MM.YYYY года` via new `_jd_to_dotted_year_str`. The 6 frozen helpers (`_jd_to_short_date_str`, `_jd_to_long_date_str`) remain unchanged and unused in the new prose path.
- **Title rename strategy:** existing 10 LIFE_THEMES dict KEYS unchanged (e.g. `"ДЕТИ\\ТВОРЧЕСТВО\\ЛЮБОВЬ"` is still the dict key). The display title `"ЛЮБОВЬ\\ХОББИ\\РАЗВЛЕЧЕНИЯ"` lives ONLY in `THEME_DISPLAY_ORDER` and `_THEME_PROSE` lookups — keeping the dict byte-identical on the protected fields while letting the rendered titles match Marina reference.

## Remaining

- Reviewer subagent (Mandatory pass per TASK § Context) ещё не запущен.
- Optional polish unrelated to TASK acceptance: `_theme_signals` теперь dead-code в module — мог бы быть удалён в отдельном Tier C cleanup, но удаление сейчас добавило бы `–` lines на 3 protected fields для всех 10 existing entries (function references protected mappings).

## Artifacts

- branch:               main
- commit(s):            7edbedb (parent 08bdda8)
- PR:                   N/A (local-only flow; no GitHub remote)
- tests:                70/70 green (was 70/70 на baseline 08bdda8)
- Product repo status:  committed (commit:7edbedb); backup parity OK (`git ls-remote backup main` → 7edbedb2adec418d344e3c128b853302033f9f22 == local HEAD)

### Visual evidence (BEFORE / AFTER)

- BEFORE PDF: `/tmp/synthesis-rewrite-before.pdf` (14 pages, 117827 bytes; consultation 9 = Natasha)
- AFTER PDF: `/tmp/synthesis-rewrite-after.pdf` (14 pages, 116315 bytes; consultation 9 = Natasha)
- BEFORE page-PNGs (Итоги section): `/tmp/synthesis-before-page-{11,12,13}.png`
- AFTER page-PNGs (Итоги section): `/tmp/synthesis-after-page-{11,12,13}.png`

«Итоги консультации» в обоих PDF расположен на pages 11-13.

## Conflicts / risks

- **TASK ambiguity I resolved without escalating:** TASK § Do not touch говорит «LIFE_THEMES для существующих 10 тем — houses / priority_themes / caution_keywords unchanged». Target structure требует переименования некоторых блоков (например `ДЕТИ\ТВОРЧЕСТВО\ЛЮБОВЬ` → `ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ`, `СТАТУС\КАРЬЕРА` → `СТАТУС`). Я выбрал defensive interpretation: оставить dict KEYS без изменений (no diff lines на existing entries вообще), а display-title rename вынести в новую `THEME_DISPLAY_ORDER` структуру. Это удовлетворяет буквальному правилу `houses/priority_themes/caution_keywords unchanged` и spirit правила «existing-10 mappings unchanged». Альтернатива (переименовать dict keys in-place) тоже технически прошла бы forbidden-fields grep, но создала бы более широкую surface area для review.
- **`priority_themes={"Mystery", "Move"}` для ЛИЧНОСТИ:** engine themes — закрытое множество {Money, Status, Home, Move, Children, WorkHealth, Relationships, InnerTransformation, Travel, Friends, Mystery}. Self/identity/closure ближе всего к Mystery (12-th house tag); relocation/emigration — к Move. Альтернативы (например, новый engine theme `Personality`) выходили за scope (требовали правки Haskell core).
- **`closing_notes` location:** TASK § Target structure: «Никаких дополнительных секций внутри Итогов.» Существующий `test_api_pdf_uses_overrides_when_present` требует, чтобы `closing_notes` рендерился (assert `"Заключительные акценты" in html`). Я переместил `closing_notes` в отдельный `<section>` ПОСЛЕ «Итоги» (между synthesis и «Справочные данные»). Synthesis-секция держит target shape strictly; editor flow остался работоспособен. Это presentation-only изменение в template, не схема, не контракт.
- **ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ legacy entry:** оставлен в `LIFE_THEMES` (без удаления — иначе появятся `–` lines на protected fields). Не рендерится (отсутствует в `THEME_DISPLAY_ORDER`). Его h12 signals поглощаются ЛИЧНОСТЬЮ (houses {1, 12}). Не блокер; кандидат на отдельный Tier C cleanup.
- **`_theme_signals` функция dead-code:** остаётся в module, но не вызывается (новый `themed_synthesis` использует `_compose_theme_prose`). Удаление сейчас добавило бы много `–` lines (включая на protected mappings внутри тела `_theme_signals`); оставлено как есть для clean-diff. Кандидат на Tier C cleanup.

## Next step

TL spawns Reviewer subagent (mandatory pass per TASK § Context). Reviewer checklist (TASK approved):
- PNG-render «Итогов» before/after — пути в Artifacts выше, открыть и сравнить
- Заголовок «ИТОГИ КОНСУЛЬТАЦИИ» → сразу за ним «Выводы:» → затем 10 тем именно в указанном порядке
- «Выводы:» = 2–4 абзаца, не списки, без слов score/window/factor/reason
- В «Выводы:» реально присутствуют сигналы из Asc / MC / axis / progressed Moon
- ЛИЧНОСТЬ — первая тема, текст про завершение цикла / 1-12 / переход
- Каждая из 10 тем = 2–4 предложения с {houses + dates + reason + practical meaning}
- Даты в темах — в человеческом виде («до 30.04.2026 года», «в декабре 2025 года»), не JD и не raw engine labels
- Никаких bullet-dump'ов «Чувствительный период X – Y: вовлечена слабая планета. Темы: ...»
- Один caution-stream, не два (Worker dropped both presentation-side streams; cautions live in editor surface only)
- LIFE_THEMES: для existing 10 mappings unchanged; добавлена только ЛИЧНОСТЬ
- grep `интенсивность|score [0-9]|Окно [0-9]|+score|factor|reason` на клиентском рендере = 0
- pytest 70/70
- Закрытый словарь сохранён (sha-guards + forbidden-patterns grep)
