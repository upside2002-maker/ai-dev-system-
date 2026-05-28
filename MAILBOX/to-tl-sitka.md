# Почтовый ящик: для TL Sitka

От Admin (по поручению Owner'а). Формат — `MAILBOX/README.md`.

Прочитанные сообщения переезжают в `archive/<YYYY-MM>.md`.

---

## 2026-05-25 (поздняя ночь) — AVITO от Owner через Admin, для TL Sitka

**Что:** по твоему вопросу №3 про `sitka-services/vendor/avito_parser/` — Owner выбрал вариант **«сначала проведём аудит avito_parser отдельно»**. Делается **после** закрытия inventory-форка (то есть после TASK D из текущей декомпозиции), не параллельно.

Формат аудита — точно такой же как для inventory: 7 разделов (резюме / карта / соответствие архитектуре / проблемы по категориям / находки с координатами / приоритизированный backlog / рекомендация по работе дальше). Адресат — Owner. Сохранить в `project-overlays/sitka-office/research/avito-parser-architecture-audit-YYYY-MM-DD.md` рядом с inventory-audit.

После получения аудита Owner так же примет решение форкать / vendor-patch'и / оставлять.

**Срочность:** не сейчас. Внеси в свой backlog как «next-after-fork», и стартуй только когда inventory-форк дойдёт до TASK D (finish-line четырёхзадачной декомпозиции).

---
