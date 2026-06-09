# TASK: proforientation-phase-b2-pdf-ui

- Status: open
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: mixed (services PDF-секция + frontend UI-панель; presentation-only; финал эпика профориентации)
- Risk tier: B (presentation двух клиентских поверхностей; движок/контракт/правила landed A1/A2/B1)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет — Tier B)

## Problem

Phase B2 (финальная) эпика профориентации. Phase A (ядро+контракт) + B1 (правила толкования + оркестрация + endpoint `GET /persons/{id}/vocation`, `6c24c11`) дали работающий бэкенд: по наталу → топ-2–3 «планета+дом» + черновое толкование из правил. B2 — **видимая часть**: раздел в консультации (PDF) + UI-панель, по образцу возвратов Phase E.

## Decisions (locked)
- **Reuse B1 целиком:** `build_vocation_snapshot` + `run_core_analysis` + `compose_vocation_draft` (НЕ дублировать; НЕ пере-вычислять; математика в ядре).
- **PDF-секция** — раздел «Профориентация» в `solar.html.j2`: топ-2–3 сочетания (планета · дом · знак) + черновое толкование (помечено «черновое»). Reuse оркестрации B1 напрямую (один вызов, не HTTP). Размещение Worker предлагает (рядом с прочими натальными/справочными разделами) — TL смотрит на живом PDF.
- **UI-панель** — компонент «Профориентация» в `PersonDetails` (как `ReturnsPanel`): `getPersonVocation(id)` → таблица топ-сочетаний + толкование. API-клиент по образцу `getPersonReturns`.
- **Честная рамка «черновое толкование»** видна и в PDF, и в UI (не выдавать за финал — TZ).
- **Текст — только из правил B1** (composer); B2 не сочиняет толкование, только показывает.

## Scope

### B2.1 — PDF-секция (services)
- Хелпер `app/pdf/vocation_section.py` (по образцу `returns_section.py`): person → reuse `build_vocation_snapshot` + `run_core_analysis` + `compose_vocation_draft` → форматировать топ-2–3 (планета/дом/знак + черновой текст + пометка «черновое»).
- Jinja-блок «Профориентация» в `templates/solar.html.j2` + builder wire-up. Заголовок/размещение Worker предлагает.

### B2.2 — UI-панель (frontend)
- API-клиент `getPersonVocation(id)` (по образцу `geocodePlace`/returns) + типы.
- Компонент `VocationPanel.tsx` (по образцу `ReturnsPanel.tsx`): топ-сочетания + толкование + «черновое». Встроить в `PersonDetails.tsx`.
- `tsc --noEmit` чисто.

### B2.3 — Регрессия + живой рендер
- Существующие соляр-секции (+ секция возвратов) целы (кроме добавленной профориентации).
- `pytest` зелёный (existing + новые pdf-тесты).
- Живой рендер соляр-PDF Марины (consultation 15): секция профориентации присутствует + корректна + существующее цело. Живой UI-скрин панели (опц.).
- (Опц., не обязат.) свернуть косметику A2-ревью R1/R2 (комментарий «ascending», score min) — тривиально.

## Files
- new: `services/api-python/app/pdf/vocation_section.py`; `apps/web-react/src/components/VocationPanel.tsx`; `services/api-python/tests/test_vocation_section.py`.
- modify: `app/pdf/templates/solar.html.j2` + builder; `apps/web-react/src/api.ts` (+ types) + `pages/PersonDetails.tsx`; `OPERATING/journal/2026-06.md`.
- delete: —

## Do not touch
- Ядро/контракт/`Bridge.*`/`Main.hs` — A1/A2 closed.
- `vocation_sampler.py`/`vocation_composer.py`/`app/api/vocation.py`/правила B1 — НЕ менять логику (только reuse; правила — данные Марины).
- Возвраты/соляр прочие секции, synthesis, outer_cards (кроме добавления блока).
- DB schema.
- **NO сочинения толкования** (только из правил B1). **NO math/пере-вычисления** в presentation. **NO выдача чернового за финал.** **NO Daragan verbatim.** **NO LLM.**

## Acceptance
- [ ] PDF: секция «Профориентация» в соляр-PDF (топ-2–3 планета/дом/знак + черновой текст + пометка «черновое»); reuse B1 (один вызов, не HTTP).
- [ ] UI: панель профориентации в PersonDetails (топ-сочетания + толкование + «черновое»); `getPersonVocation`.
- [ ] Существующие секции (вкл. возвраты) целы — живой рендер Марины.
- [ ] `pytest --tb=short -q` зелёный; `tsc --noEmit` чисто; `cabal test` не затронут (спот).
- [ ] `git status` чисто для intended. Один product commit (PDF+UI+tests); один overlay (HANDOFF+journal); push, parity.
- [ ] Reviewer: client-facing → TL inline-verify + живой осмотр PDF/UI; внешний Reviewer optional (Tier B).

## STOP triggers
- Worker сочиняет толкование в коде (вместо правил B1) → STOP.
- Worker пере-вычисляет факторы/отбор в presentation → STOP (#7).
- Worker зовёт HTTP endpoint из PDF (вместо функции B1) → STOP.
- Worker меняет ядро/контракт/логику B1/правила → STOP.
- Worker ломает существующие соляр-секции / возвраты → STOP.
- Черновик выдан за финал (нет пометки) → STOP.

## Context
**Mode normal + Tier B (presentation).**
**Baseline:** product `6c24c11` (B1); endpoint `GET /persons/4/vocation` работает; `build_vocation_snapshot`/`compose_vocation_draft` (B1) — reuse. pytest 741/3/0; cabal 338/0; tsc clean. Марина = person 4 / consultation 15.
**Cross-references:**
- B1: `app/ephemeris/vocation_sampler.py`, `app/vocation_composer.py`, `app/api/vocation.py`, `packages/rulesets/vocation/`.
- Образец витрины: возвраты Phase E — `app/pdf/returns_section.py`, `ReturnsPanel.tsx`, `getPersonReturns`, секция в `solar.html.j2`.
**Флаг (не B2-блокер):** B1 composer берёт income-mode по приоритетному дому (X), не по placement (II). Cross-house уточнение — отдельно (правка правил Мариной или follow-up composer'а), НЕ в B2.
**Не в scope:** полный голос Марины (отдельный трек); cross-house composer.
**Ready: yes** — бэкенд+правила готовы (B1), образец (возвраты E) есть, presentation-only.
