# crypto-research — сбор по трейдингу/макро/крипте

Всё, что собрано из видео для проекта crypto-platform: базы знаний, разборы,
формализованные StrategySpec-черновики. Источники — 104 видео (Дмитрий Солодин +
14 англоязычных авторов по макро/эконом/трейдингу).

## С чего начать
- **[KNOWLEDGE_BASE_INDEX.md](KNOWLEDGE_BASE_INDEX.md)** — общий вход: статистика, разбивка по авторам, объединённая очередь кандидатов.
- **[CROSS_THESIS_MAP.md](CROSS_THESIS_MAP.md)** — карта кросс-тезисов 2026: консенсус/расхождения по 12 темам + сигнальные метрики (теги `[CRYPTO]`).

## Базы знаний (контент с кликабельными таймкодами)
- [KNOWLEDGE_BASE_SOLODIN.md](KNOWLEDGE_BASE_SOLODIN.md) — 39 видео (213 механик, 372 гипотезы, 367 фундаментал-блоков).
- [KNOWLEDGE_BASE_ENGLISH.md](KNOWLEDGE_BASE_ENGLISH.md) — 65 видео, 14 каналов (77 механик, 416 гипотез, 496 фундаментал).

## Формализованные стратегии
- `strategy-specs/` — 18 StrategySpec-черновиков по контракту crypto-platform. Обзор — [strategy-specs/INDEX.md](strategy-specs/INDEX.md). Включает **3** негативных контроля (мартингейл/разгон/parlay) — ожидаемый вердикт трубы KILL.

> **Поправки после состязательной проверки 2026-06-13** (см. `../CORPUS_TRUST_MAP_2026-06-13.md`): негативных контролей **3**, не 4 (четвёртым ранее считался вторичный разбор `zvezdin_razgon_18days.md`). `validate_spec.py` — внешняя зависимость платформенной трубы, в этом корпусе ОТСУТСТВУЕТ, поэтому заявление «0 ошибок валидатора» из корпуса непроверяемо. Внесено аналитическое ядро (~15 МБ); сырые субтитры `.json3` (~100 МБ) и дубль-json сводки в репозиторий НЕ внесены.

## Точечные разборы (отчёты trading-video-insights)
- [solodin_small_account_options.md](solodin_small_account_options.md) — опционы на малом счёте.
- [solodin_silver_pyramiding.md](solodin_silver_pyramiding.md) — пирамидинг SLV + защитный пут.
- [solodin_macro_peak_filter.md](solodin_macro_peak_filter.md) — макро-фильтр пика рынка.
- [zvezdin_razgon_18days.md](zvezdin_razgon_18days.md) — разбор «разгона депозита» (funnel-схема, негативный контроль).

## Корпус (сырьё)
- `solodin_channel/<id>/` — транскрипт + meta + `extract.md` по каждому видео (39).
- `english_videos/<id>/` — то же по англоязычным (65).
- `*_knowledge.json` — машиночитаемые сводки извлечения (вход для сборщиков/спеков).
- `english_targets.json`, `english_authors_seed.json` — отобранные видео и курируемый список авторов.
- `*.log` — логи скачивания.

## Не входит
Курс К. Дарагана по астрологии — это другой проект (`~/Downloads/astro_daragan/`).
