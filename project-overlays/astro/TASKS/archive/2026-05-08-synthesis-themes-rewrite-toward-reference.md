# TASK: synthesis-themes-rewrite-toward-reference

- Status: done
- Ready: yes
- Date: 2026-05-08
- Project: astro
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: normal

## Problem

Текущий блок `Итоги консультации` всё ещё выглядит как агрегат engine-сигналов, а не как Marina-style final synthesis. Нужно переписать **только presentation/composition layer** блока, не меняя вычислительный слой и не ломая contracts. После debug-cleanup'а (`08bdda8`) остался structural gap: нет `Выводы:`, нет темы `ЛИЧНОСТЬ`, темы рендерятся как bullet-list, дублируются caution-потоки.

### Target structure (ровно эта форма)

1. Заголовок `ИТОГИ КОНСУЛЬТАЦИИ`
2. Под ним — `Выводы:`
3. Затем 10 тематических блоков **в этом порядке**:
   `ЛИЧНОСТЬ` → `ФИНАНСЫ` → `ДОКУМЕНТЫ\ПЕРЕЕЗД\КУРСЫ` → `НЕДВИЖИМОСТЬ\СЕМЬЯ` → `ЛЮБОВЬ\ХОББИ\РАЗВЛЕЧЕНИЯ` → `РАБОТА\ЗДОРОВЬЕ` → `ПАРТНЁРСТВО\КОНТРАКТЫ` → `ЗАГРАНИЦА\ОБУЧЕНИЕ\НАВЫКИ` → `СТАТУС` → `ПЛАНЫ\КОЛЛЕКТИВ\ЕДИНОМЫШЛЕННИКИ\ДРУЗЬЯ`

Никаких дополнительных секций внутри `Итогов`.

### `Выводы:` (content rules)

Содержимое собирается из: соляр `Asc` (общий характер года), соляр `MC` (вектор цели), `primary_axis` / `secondary_axis`, `progressed_moon` (знак + дом + период действия внутри солярного года, если меняется), и **1–2 strongest direction/transit confirmations**.

**`strongest direction/transit confirmations` = (b) structurally-relevant signals:** подтверждения, которые затрагивают `Asc`, `MC`, `1 дом`, или прямо поддерживают главную/вторичную тему года по домам и формулам. **`priority_windows` допустимо использовать только как secondary timing support, не как primary selection rule** для `Выводы:`. Это deliberately ближе к Marina-style, чтобы Worker не уехал в «engine picked top windows».

Форма: 2–4 коротких абзаца, не списки, без слов `score` / `window` / `factor` / `reason` / engine labels.

### Per-theme block (content rules)

Каждая тема = **2–4 коротких связных предложения**, не bullet-list. Шаблон:

1. Что за тема активируется и через какие дома/комбинации (`(2-12)`, `(7-6)`, etc.).
2. Какая прогностика это подтверждает: соляр / прогрессии / дирекции / транзиты.
3. Если есть дата/период — в человеческой форме (`до 30.04.2026 года`, `с октября 2025 года`, `в декабре 2025 года`). НЕ JD, НЕ raw engine timestamp.
4. Какой практический смысл несёт.

### Тема `ЛИЧНОСТЬ` (новая, первой)

Добавить в `LIFE_THEMES`:
- `houses = {1, 12}`
- `priority_themes` — привязать к self / identity / closure / transition / isolation / relocation-type signals
- `caution_keywords` — только те, что реально соответствуют завершению цикла, уединению, смене самоощущения

Смысловое наполнение: комбинации `1-12`, завершение этапа, переход в новый цикл, подведение итогов, иногда эмиграция / удалённая занятость / «вне общества».

### Cautions policy

Текущий **двойной caution-stream** убрать. Оставить **один** поток (Worker выбирает source: либо Python `windows_block` после `08bdda8`, либо Haskell `consultation_skeleton.cautions`; только presentation-side изменения, Haskell не трогать). Caution попадает в тему **только если она реально тематически релевантна**. Запрещено: raw caution как отдельный bullet dump, дублирование одного caution в 5+ темах, вывод `Чувствительный период ... Темы: ...` как системный шаблон. Если caution не удаётся чисто встроить в тему — лучше не показывать его вообще, чем оставить debug-like хвост.

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` — `LIFE_THEMES` (добавление `ЛИЧНОСТЬ`, остальные 10 mappings unchanged); composition functions для `Выводы:` + per-theme prose; caution-stream consolidation на presentation side.
  - `services/api-python/app/pdf/templates/solar.html.j2` — рендер «ИТОГИ КОНСУЛЬТАЦИИ» секции под Target structure (Выводы + 10 тем в указанном порядке, ЛИЧНОСТЬ первой).
- new: —
- delete: —

Опционально (если необходимо для consolidation): adjust where `consultation_skeleton.cautions` consumed in template/Python. Worker возвращается к TL если scope требует выйти за эти 2 файла.

## Do not touch

- `core/astrology-hs/**` — Haskell core inviolate.
- `packages/contracts/**`, `packages/test-fixtures/**`, `packages/rulesets/**` — schema / fixtures / rulesets unchanged.
- `services/api-python/app/pdf/{wheel,builder,direction_themes,house_pair_themes,transit_themes}.py` — другие projector модули не трогать.
- `services/api-python/app/{main,db,persons,consultations,draft,core_client,models}.py`, `app/ephemeris/**`, `app/migrations/**` — orchestration / storage не затрагиваются.
- `apps/**`, `infra/**`, `data/**`, `astro/.claude/**`, `CLAUDE.md`, `docs/**` — out of scope.
- **Selection logic inviolate**: 6 helper-function bodies в `synthesis_themes.py` (`_jd_to_date`, `_jd_to_short_date_str`, `_jd_to_long_date_str`, `_formula_houses`, `_direction_touches_houses`, `_direction_target_label_ru`) — sha-identical к baseline `08bdda8` (function-body guard как в `phase-0-10c-b-literary-synthesis`).
- **`LIFE_THEMES` для существующих 10 тем (FIРАНСЫ … ИТОГИ\ТАЙНЫ\ИЗОЛЯЦИЯ)** — `houses` / `priority_themes` / `caution_keywords` unchanged. Разрешено только добавить новую запись `ЛИЧНОСТЬ` со своими mappings.
- **Wire-format JSON keys** в `Bridge/Solar.hs` и schemas — не трогать. `consultation_skeleton` schema unchanged.
- **No AI / freeform / dynamic generation**: forbidden patterns (`openai`, `anthropic`, `eval(`, `exec(`, `random.`, `requests.`, `sqlite`, `yaml.load`) — diff'у запрещено их вводить. Closed-dictionary frame обязателен.

## Acceptance

### Behavioural invariants (objective, automated)

- [ ] `pytest` 70 passed / 0 failed (в `services/api-python` после правок).
- [ ] **Function-body guard** (sha-identical к `08bdda8`) для 6 selection helpers PASS.
- [ ] **Closed-dictionary forbidden-patterns grep** = 0 на diff `08bdda8..HEAD -- services/api-python/app/pdf/synthesis_themes.py`.
- [ ] **`LIFE_THEMES` existing-10 unchanged**: `git diff 08bdda8..HEAD -- synthesis_themes.py | grep -E '^[+-].*"(houses|priority_themes|caution_keywords)":'` показывает **только** добавления для `ЛИЧНОСТЬ` блока.
- [ ] **Wire-format unchanged**: `git diff 08bdda8..HEAD -- core/ packages/contracts/` empty.

### Visual / content invariants (objective grep + subjective Reviewer judgment)

- [ ] PNG-render «Итогов» before/after сохранён в `/tmp/synthesis-rewrite-{before,after}.pdf` + per-page PNGs `synthesis-{before,after}-{page}.png`. Paths указаны в Worker HANDOFF.
- [ ] Заголовок «ИТОГИ КОНСУЛЬТАЦИИ» → сразу за ним «Выводы:» → 10 тем в указанном порядке (ЛИЧНОСТЬ первая).
- [ ] «Выводы:» = 2–4 абзаца, не списки, без слов `score` / `window` / `factor` / `reason`.
- [ ] В «Выводы:» реально присутствуют сигналы из `Asc` / `MC` / `axis` / `progressed Moon`.
- [ ] `ЛИЧНОСТЬ` — первая тема, текст про завершение цикла / 1-12 / переход.
- [ ] Каждая из 10 тем = 2–4 связных предложения с {houses + dates + reason + practical meaning}.
- [ ] Даты в темах в человеческом виде (`до 30.04.2026 года`, `в декабре 2025 года`), не JD и не raw engine labels.
- [ ] Никаких bullet-dump'ов формата «Чувствительный период X – Y: вовлечена слабая планета. Темы: ...».
- [ ] Один caution-stream, не два (verify: не должно быть двух разных шаблонов «Чувствительный период ...» с разной форматировкой одновременно).
- [ ] `pdftotext` grep на новом PDF: `интенсивность|score [0-9]|Окно [0-9]|\+score|factor|reason` = **0** matches.

### Process invariants

- [ ] ≤ 3 commits поверх `08bdda8`. 1 preferred, max 3 при разбиении на discrete steps (каждый green pytest + render OK).
- [ ] `git status --short` clean перед каждым commit (Correction 008).
- [ ] `git push backup main`; `git ls-remote backup main` == local HEAD.
- [ ] `git show --stat` для каждого commit: пути только в `services/api-python/app/pdf/{synthesis_themes.py,templates/solar.html.j2}`.
- [ ] Worker subagent **сам** создаёт + заполняет HANDOFF + вызывает `make submit-task`. TL не writes Worker HANDOFF.
- [ ] Reviewer subagent **сам** создаёт + заполняет Reviewer HANDOFF + verdict. **Mandatory pass.**

## Context

**Mode normal + Reviewer mandatory** (User decision 2026-05-08): Tier B по graded rule даёт `normal` + Reviewer optional, но для rewrite content/composition (visual quality легко сломать незаметно) — Reviewer mandated. Same-session inline NOT accepted.

**Worker subagent** = separate Agent tool call, fresh memory, owns full lifecycle (read TASK → execute → commit → push → make new-handoff → fill body → make submit-task → return brief summary).

**Reviewer subagent** = separate Agent tool call after Worker submit, fresh memory, given Worker HANDOFF path + Reviewer checklist (см. ниже). Owns own HANDOFF + verdict.

**Reviewer checklist** (TL approved + 2 additions 2026-05-08):

```
- [ ] PNG-render «Итогов» before/after — пути указаны в HANDOFF, открыть и сравнить
- [ ] Заголовок «ИТОГИ КОНСУЛЬТАЦИИ» → сразу за ним «Выводы:» → затем 10 тем именно в указанном порядке
- [ ] «Выводы:» = 2–4 абзаца, не списки, без слов score/window/factor/reason
- [ ] В «Выводы:» реально присутствуют сигналы из Asc / MC / axis / progressed Moon
- [ ] ЛИЧНОСТЬ — первая тема, текст про завершение цикла / 1-12 / переход
- [ ] Каждая из 10 тем = 2–4 предложения с {houses + dates + reason + practical meaning}
- [ ] Даты в темах — в человеческом виде («до 30.04.2026 года», «в декабре 2025 года»), не JD и не raw engine labels
- [ ] Никаких bullet-dump'ов «Чувствительный период X – Y: вовлечена слабая планета. Темы: ...»
- [ ] Один caution-stream, не два
- [ ] LIFE_THEMES: для existing 10 mappings unchanged; добавлена только ЛИЧНОСТЬ
- [ ] grep `интенсивность|score [0-9]|Окно [0-9]|+score|factor|reason` на клиентском рендере = 0
- [ ] pytest 70/70
- [ ] Закрытый словарь сохранён (sha-guards + forbidden-patterns grep)
```

Reviewer verdict = `ACCEPT` / `REQUEST CHANGES` / `REJECT` в § Summary HANDOFF, в собственном написанном тексте.

**Baseline**: `astro:08bdda8` (после `debug-artifact-removal-from-synthesis`), pytest 70/70, branch `main`, clean. Backup mirror parity ✓.

**References**:
- Marina reference PDF: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` (29 страниц, structure pages 25-29 для блока Выводы + per-theme).
- Текущее состояние: `/tmp/astro-natasha-after-cleanup.pdf` (rendered after debug-cleanup, 14 pages, синтез на pages 12-14).
- Render mechanism: `/tmp/render_natasha.py` существует и работает (pull person+consultation+facts из SQLite, call `write_solar_pdf` напрямую без Haskell CLI).
- Previous TASKs: `phase-0-10c-b-literary-synthesis` (Tier B precedent с function-body guard), `debug-artifact-removal-from-synthesis` (Tier C cleanup baseline `08bdda8`).

**Spec-length note**: TASK body превышает рекомендованные ≤60 строк (per новый short template). Это **deliberate** для structural rewrite — content rules + per-theme template + cautions policy + Reviewer checklist не сжимаемы без потери смысла. Mode normal + Tier B оправдывает плотность спеки.

**Ready: no** — TASK существует в open state, Worker НЕ стартует без явного TL go (после User approval). После TL go: TL flips `Ready: yes` (single-field mechanical edit), spawns Worker subagent через Agent tool с self-contained prompt.
