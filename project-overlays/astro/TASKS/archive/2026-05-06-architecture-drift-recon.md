# TASK: architecture-drift-recon

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

После git bootstrap (`astro:4937c00`, 2026-05-06) overlay-документы Architecture (`target-architecture.md` от 2026-04-24, `migration-plan.md`, `PHASE_0_TASKS.md`) описывают prescriptive picture, тогда как продуктовый код в `/Users/ilya/Projects/astro` за период 2026-04-24 → 2026-05-06 успел пройти серию продуктовых фаз (нумерация 0.5–0.10b — введена в продуктовых сессиях, в overlay не зафиксирована): Draft Editor, component split, Solar Arc migration, 144-cell house pair interpretations, direction interpretations, transit-by-house narratives, monthly transit matrix, theme-grouped «Итоги консультации» synthesis.

Это «Bootstrap risk #2 (architecture drift)» из `project-overlays/astro/README.md` § Bootstrap risks. До сих пор он явно открыт. Цель текущего TASK — **не разрешить дрейф**, а только зафиксировать его на бумаге evidence-based: что реально есть в `astro:4937c00`, что в overlay-документах устарело, и какой минимальный безопасный следующий шаг возможен. Решения по поводу обновления prescriptive документов и/или явной фиксации deviations — следующим отдельным TASK по результатам этого recon.

## Scope

Входит:
- Один новый markdown-документ `project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md` со следующими 7 секциями (в указанном порядке):
  1. **Baseline и метод.** Зафиксировать: рекон выполнен на `astro:4937c00`; перечислить overlay-документы, против которых сверка (5 файлов из § Test commands ниже); метод evidence (`git ls-tree`, `git show`, `find`, `grep` по конкретным путям); явное ограничение «recon-only, никаких prescriptive решений в этом документе».
  2. **Что реально реализовано в `astro:4937c00`.** Inventory по слоям (Core / Services / Frontend / Contracts / Infra / Tests). Каждый пункт — путь файла + 1-2 предложения о роли + git evidence (`git ls-tree astro:4937c00 -- path` или `git show astro:4937c00:path | head`). Особое внимание на модули, которые в overlay не зафиксированы:
     - Haskell: `Domain/Directions.hs`, `Domain/HouseAxisAnalysis.hs`, `Domain/PriorityWindows.hs`, `Domain/SolarReturn.hs`, `Domain/StrengthAnalysis.hs`, `Domain/Stellium.hs`, `Domain/TransitCalendar.hs`, `Domain/WeaknessAnalysis.hs`, `Domain/KingOfAspects.hs`, `Domain/ImportantTransitPlanets.hs`, `Domain/Progressions.hs`, `Domain/ConsultationSkeleton.hs`, `Domain/Houses/Placidus.hs`.
     - Python PDF: `services/api-python/app/pdf/{builder,direction_themes,house_pair_themes,synthesis_themes,transit_themes,wheel}.py` + Jinja2 template `solar.html.j2`.
     - Python contracts/storage: `services/api-python/app/{consultations,core_client,db,draft,persons}.py`, `app/migrations/00{1,2}_*.sql`, `app/ephemeris/{bridge,cache}.py`.
     - Frontend: `apps/web-react/src/components/draft-editor/*` (16 файлов: `ActionBar.tsx`, `CautionsEditor.tsx`, `ClosingNotesEditor.tsx`, `ConfirmResetModal.tsx`, `ExtendedThemesEditor.tsx`, `FieldOverride.tsx`, `FinalPreview.tsx`, `KeyPeriodCard.tsx`, `KeyPeriodsEditor.tsx`, `ListOverride.tsx`, `OpeningEditor.tsx`, `PsychSettingEditor.tsx`, `SectionShell.tsx`, `StatusBadge.tsx`, `helpers.ts`, `styles.ts`); `pages/{ConsultationForm,ConsultationView,DraftEditor,PersonDetails,PersonForm,PersonList}.tsx`; `lib/{draftMerge,i18n}.ts`.
     - Contracts: `packages/contracts/{consultation-draft-overrides,consultation,person,solar-computed-facts,solar-resolved-input}.schema.json`; rulesets v1 / v2 / daragan-orbs-v1; 9 golden-cases input/expected pairs + `06-incomplete-2025-2026.stub.json`; `_compare_directions.py`, `_generate.py`.
     - Tests: Haskell test specs (24 файла: King/Strength/Weakness/Stellium/SolarReturn/Progressions/HouseAxisAnalysis/PriorityWindows/Directions/TransitCalendar и др.), Python tests (test_api/test_bridge/test_contracts/test_draft/test_golden_cases/test_storage), golden snapshots (`placidus-reference.json`, `synthetic-solar-1.{input,expected}.json`).
  3. **Какие пункты `PHASE_0_TASKS.md` уже фактически закрыты.** Walk через каждый блок в `PHASE_0_TASKS.md` (T-A.x, T-B.x, …); по каждому пункту — статус: `closed-in-fact` / `partial` / `not-started` / `obsolete-by-evolution`. Каждый `closed-in-fact` — путь файла в `astro:4937c00`, который реализует пункт (evidence). Каждый `obsolete-by-evolution` — что именно устарело и какая реальность пришла на замену.
  4. **Какие пункты `target-architecture.md` расходятся с реальным продуктом.** Walk по секциям `target-architecture.md` (особое внимание § 6 «PDF layout — Phase 0», § 11 «8 bright lines», § 1-2 «треугольник + слои»). Для каждой секции — `aligned` / `divergent` / `silent` (overlay молчит, реальность активна). Divergent цитируется одной короткой выдержкой (≤ 15 слов) с указанием строки overlay vs evidence из `astro:4937c00`.
  5. **Conscious deviations vs real drift.** Разнести divergences по двум корзинам:
     - **Conscious deviation** — пункт нарушения prescriptive документа, который при ретро-анализе видится как осознанное продуктовое решение (например, расширение PDF за рамки «без графики и интерпретации» под прямой запрос Марины). Требует фиксации в `astro/.claude/corrections.md` или явного комментария в overlay; не требует переработки кода.
     - **Real drift** — пункт нарушения, который не объясняется бизнес-эволюцией; результат отсутствия дисциплины фиксации. Требует решения: либо обновить prescriptive документ, либо вернуть код к prescriptive.
     Для каждого пункта — короткое обоснование выбора корзины (1 предложение).
  6. **Какой следующий product TASK безопасно делать первым.** Worker формулирует **одно** конкретное предложение (TL может его принять, изменить или отклонить отдельным go) — TASK должен быть:
     - docs-only ИЛИ ≤ 30 строк product-code patch (Tier C);
     - не trigger'ить bump `.overlay-maturity`;
     - не требовать BA-резолюции бизнес-вопросов;
     - давать TL ясный следующий ход (например «зафиксировать deviation X в `astro/.claude/corrections.md`», «добавить раздел 6.5 в `target-architecture.md` под Solar Arc», «explicit deprecation для T-X.Y в `PHASE_0_TASKS.md`»).
     **Никаких** «целиком обновить target-architecture.md» / «переписать § 6» / «реализовать все недостающие пункты» — это не Tier C.
  7. **Evidence appendix.** Список конкретных команд, которыми Worker собирал evidence (`git ls-tree astro:4937c00`, `git show astro:4937c00:path`, `find /Users/ilya/Projects/astro -name '...'`, `grep -rn '...' /Users/ilya/Projects/astro`). Каждая команда — с одной короткой выдержкой реального вывода (≤ 5 строк) или явным «empty». Это позволяет TL воспроизвести проверки.

Не входит:
- любая модификация product code в `/Users/ilya/Projects/astro`;
- любая модификация `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, `current-mvp-review.md`, `git-bootstrap-plan.md`, `git-bootstrap-execution.md` (только цитировать);
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` / `KNOWN_ISSUES.md` / `NEXT_ACTIONS.md` / `PROJECT_MAP.md`;
- запись в `astro/.claude/corrections.md` или `astro/.claude/architecture-invariants.md`;
- любая git-операция в `/Users/ilya/Projects/astro` кроме read-only (`git ls-tree`, `git show`, `git log`, `git status`);
- запуск `cabal build` / `pytest` / `npm install` / `tsc` (recon — не валидация работоспособности кода, а сверка с overlay-документами).

## Files

- new:    `project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md`
- modify: —
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких write операций; разрешены только read-only `git`, `cat`, `find`, `grep`, `ls`.
- `/Users/ilya/Backups/**` — не трогать.
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/{target-architecture,migration-plan,PHASE_0_TASKS,current-mvp-review,git-bootstrap-plan,git-bootstrap-execution}.md` — только цитировать (≤ 15 слов на цитату).
- `project-overlays/astro/starts/**`, `RESEARCH/**`, `archive/**` — не трогать.
- `astro/.claude/{corrections,architecture-invariants}.md` (внутри продуктового repo) — не трогать.

## Acceptance criteria

- [ ] Создан `project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md` с **ровно 7 секциями** в порядке Scope § 1–7.
- [ ] Каждая claim о наличии файла в продуктовом repo подтверждена evidence: путём (`<path>`) и одной из форм git-доказательства — `git ls-tree astro:4937c00 -- <path>` (показывает blob hash), `git show astro:4937c00:<path> | head -N`, `git log astro:4937c00 -- <path>` (для «когда появился»). Никаких «по памяти из предыдущей сессии» — только из текущего рекона.
- [ ] Каждая claim о расхождении overlay vs реальность сопровождена **одной** короткой цитатой ≤ 15 слов из overlay-документа в кавычках + evidence-pointer на продуктовом коде.
- [ ] Секция § 5 (Conscious vs drift) содержит **обе** корзины непустыми, ИЛИ явное обоснование почему одна из корзин пуста (нельзя замолчать).
- [ ] Секция § 6 (Next product TASK) содержит **ровно одно** предложение, удовлетворяющее всем 4 критериям («docs-only или ≤30 строк», «не bumps maturity», «не BA», «ясный следующий ход») — не список вариантов.
- [ ] Секция § 7 (Evidence appendix) содержит ≥ 8 reproducible команд (`git ls-tree`, `git show`, `find`, `grep`).
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает создаваемый TASK как `Active TASKS` (до submit) либо `RECENTLY ARCHIVED` (после accept).
- [ ] Worker не выполнил ни одной write-операции в `/Users/ilya/Projects/astro` или в любых заблокированных в § «Do not touch» путях. В HANDOFF — явная фраза подтверждения.
- [ ] Worker не запускал `cabal`, `pytest`, `npm`, `tsc` — recon-only.

## Test commands

Read-only evidence (Worker запускает локально для составления документа):

```
# Overlay reading set (5 файлов):
project-overlays/astro/starts/TECH_LEAD.md
project-overlays/astro/README.md
project-overlays/astro/ARCHITECTURE/target-architecture.md
project-overlays/astro/ARCHITECTURE/migration-plan.md
project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md

# Product baseline:
cd /Users/ilya/Projects/astro && git rev-parse HEAD              # ожидаемо 4937c00...
git ls-tree -r astro:4937c00 | wc -l                              # 161 ожидаемо
git ls-tree astro:4937c00 -- core/astrology-hs/src/Domain/        # для inventory секции 2
git ls-tree astro:4937c00 -- services/api-python/app/pdf/         # PDF inventory
git ls-tree astro:4937c00 -- apps/web-react/src/components/       # frontend inventory
git ls-tree astro:4937c00 -- packages/                            # contracts inventory

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-architecture-drift-recon.md FROM=worker TO=tl` (без manual touch файла), потом заполняет body. Шапка строго по `templates/HANDOFFS_TEMPLATE.md`.

В теле обязательно:
- список созданных файлов (один — `architecture-drift-recon.md`, с `wc -l`);
- краткое summary § 5 (сколько conscious deviations, сколько real drift);
- одно предложение § 6 (recommended next TASK) — буквально цитатой;
- результат `make check` и `make status SLUG=astro`;
- `Product repo status:` — текущее состояние `/Users/ilya/Projects/astro` относительно `astro:main` (`clean / commit:4937c00` ожидаемо, потому что Worker делает только read-only operations);
- evidence-rule подтверждение: «Worker выполнял в `/Users/ilya/Projects/astro` только read-only команды (`git ls-tree`, `git show`, `git log`, `git status`, `cat`, `find`, `grep`); ни одной write-операции в продуктовый repo не было»;
- ссылка на § 6 (Next product TASK) — Worker формулирует одно предложение, которое TL может принять как новый TASK или отклонить.

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-architecture-drift-recon.md`. **TL не делает manual edit `Status:`** — это требование Success criteria из ТЗ.

Reviewer: optional. Если TL по результатам HANDOFF решит запросить ревью — отдельный шаг с собственным `make new-handoff FROM=reviewer TO=tl`. Reviewer пишет findings **в файл HANDOFF**, не в stdout (требование ТЗ).
