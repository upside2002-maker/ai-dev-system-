# TASK: inventory-parser-fork-task-b-title-matches

- Status: open
- Ready: yes
- Date: 2026-05-27
- Project: sitka-office
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Закрывает **P0-1** из архитектурного аудита 2026-05-21 (`research/inventory-parser-architecture-audit-2026-05-21.md`, §6).

Сейчас `BaseStoreAdapter.title_matches` (`sitka-services/app/inventory/adapters/base.py:452-470`) после форка работает так:

```python
def title_matches(self, title, parsed_query) -> bool:
    matched_tokens = self.matched_tokens(title, parsed_query)
    if len(matched_tokens) != len(parsed_query.search_tokens):
        return False
    if parsed_query.query_mode == "broad" or len(parsed_query.search_tokens) <= 1:
        return True
    # target mode (3+ search_tokens) — требует фразу substring в title:
    search_phrase = normalize_text(parsed_query.search_text)
    normalized_title = normalize_text(title)
    if search_phrase in normalized_title:
        return True
    # special case: gtx → gore-tex / gore tex / goretex substitution
    ...
    return False
```

PR #89 поднял порог `<= 1` → `<= 2` в `query.py:113`, переведя двусловные запросы в broad mode и обойдя substring-check. Но **3+ словные запросы** (`"sitka stratus jacket"` после фильтрации stopwords всё ещё 3 токена, либо реальные `"blizzard aerolite parka"`) попадают в target mode, и substring-check режет валидные товары: «Sitka Men's Blizzard AeroLite Bib Parka» не содержит `"blizzard aerolite parka"` как substring (между ними стоит «Bib»).

**Цель TASK B:** убрать substring-check совсем. Сохранить требование «все токены матчат title» (это уже работает через `matched_tokens` count-check). Покрыть property-тестами через `hypothesis`, чтобы случайно не наловить регрессии в будущем.

Закрывает класс багов «N-словный поиск со словами через разделитель в названии товара».

## Files

- modify: `sitka-services/app/inventory/adapters/base.py` (только функция `title_matches`, ~20 строк).
- modify: `sitka-services/tests/test_inventory_title_matches.py` — расширить существующие 13 кейсов: добавить 3+ token positives (раньше падавшие через substring), сохранить broad positives/negatives.
- new: `sitka-services/tests/test_inventory_title_matches_property.py` — property-тесты через `hypothesis`. Минимум 2 property-функции:
  - **Property 1 — soundness:** для любого `parsed_query` с непустым `search_tokens` и любого `title`, **если** `title_matches(title, parsed_query) == True`, **то** все токены из `search_tokens` присутствуют как substring в `normalize_text(title)`. (Нет ложных positive.)
  - **Property 2 — completeness:** для любого `parsed_query` и `title`, **если** все токены из `search_tokens` присутствуют как substring в `normalize_text(title)`, **то** `title_matches(title, parsed_query) == True` независимо от `query_mode` (нет ложных negative — главный fix).
  - Hypothesis strategies: `search_tokens` из `lists(text(alphabet="abcdefghijklmnopqrstuvwxyz0123456789", min_size=2, max_size=8), min_size=1, max_size=5)`; `title` строится либо из `search_tokens` с произвольными prefix/suffix/infix словами, либо из чужих токенов (negative cases).
- modify: `sitka-services/requirements.txt` (если `hypothesis` не запинен) **или** `.github/workflows/ci.yml` Python-test step — добавить `pip install "hypothesis>=6,<7"`. Если в requirements.txt — то этого достаточно для CI; проверь grep'ом сначала.

## Do not touch

- `query.py` — порог `<= 2` уже правильный после PR #89 + TASK B (после fix substring-check broad/target различие почти исчезает, но `query_mode` остаётся для будущих use cases).
- `_RUN_STORE_TIMEOUT_SECONDS=35.0` в `runtime/service.py` — это TASK C.
- Adapter-файлы под `app/inventory/adapters/stores/*.py` — fix полностью локален в shared `BaseStoreAdapter`.
- `_sitka_catalog.py` — TASK A2, не B scope.
- `sitka-core/`, миграции, avito vendor — не трогать.
- Special-case GTX substitution (line 462-469) — можно **оставить** как есть (костыль на «gtx» ↔ «gore-tex» / «gore tex» / «goretex») **или удалить** (после снятия substring-check сам по себе матчинг GTX уже работает, если в title есть «gtx» отдельным токеном). На усмотрение Worker'а — если удаляешь, добавь explicit test что «sitka blizzard gtx» матчит «Sitka Blizzard Gore-Tex Glove». Если оставляешь — отметь в HANDOFF почему «just in case».

## Acceptance

- [ ] `BaseStoreAdapter.title_matches` упрощён: substring-check (line 458-461) удалён. Логика становится:
  ```python
  def title_matches(self, title, parsed_query) -> bool:
      matched_tokens = self.matched_tokens(title, parsed_query)
      return len(matched_tokens) == len(parsed_query.search_tokens)
  ```
  (GTX-секция — на усмотрение Worker'а, см. Do not touch.)
- [ ] `sitka-services/tests/test_inventory_title_matches.py` — расширен: новые 3+ token positives, broad/target различие явно протестировано (broad и target теперь равноценны).
- [ ] `sitka-services/tests/test_inventory_title_matches_property.py` — новый файл с двумя property-функциями (soundness + completeness), `@given(...)` через `hypothesis`. Минимум 200 examples каждая (default).
- [ ] `cd sitka-services && .venv/bin/python -m pytest tests/test_inventory_title_matches.py tests/test_inventory_title_matches_property.py -v` зелёный.
- [ ] Полный `make services-test` зелёный.
- [ ] Smoke: `cd sitka-services && .venv/bin/python -c "from app.inventory.adapters.base import BaseStoreAdapter; from app.inventory.query import parse_query; from app.inventory.types import ParsedQuery; q = parse_query('blizzard aerolite parka'); print('matches:', BaseStoreAdapter.title_matches(BaseStoreAdapter.__new__(BaseStoreAdapter), 'Sitka Men\\'s Blizzard AeroLite Bib Parka', q))"` → `matches: True` (главный smoke; до fix'а возвращал False, потому что `'blizzard aerolite parka'` не substring в title из-за `Bib` между `AeroLite` и `Parka`).
- [ ] CI зелёный (все 8 lanes), включая `Python: test`.

## Context

- Архитектурный аудит §6 P0-1 — конкретное место бага с координатами + предложенное направление.
- Архитектурный аудит §1 «Sharpest finding» — формулировка про contiguous-phrase matching.
- PR #89 (master `ccac24b`) — частичный workaround через broad mode для 2-словных. После TASK B необходимость broad/target различия снижается (но не убираем — это backwards-compat).
- TASK A (master `8f1d5c4`) — `base.py` уже живёт в `app/inventory/adapters/base.py` после форка.

После закрытия — TL отчитывается запиской в `to-admin.md` (PR-номер + что закрыто из аудита + SHA master + smoke-результат на 3+ словном запросе). TASK C идёт следующим (Amazon timeout).
