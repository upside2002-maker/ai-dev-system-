#!/usr/bin/env python3
# Контракт-проверка путей методологии. Только-чтение (os.path.exists).
#
# Читает TSV вида <scope>\t<path>\t<source-doc>:
#   scope = intra            — резолв против REPO_ROOT;
#   scope = crossrepo:<slug> — резолв против HOME/Projects/<slug>;
#                              если каталог продуктового репо отсутствует —
#                              путь помечается SKIP (не phantom, не ложный OK).
#
# Аргументы (через окружение, чтобы не плодить флаги):
#   CONTRACT_TSV  — путь к TSV (обязателен);
#   REPO_ROOT     — корень ai-dev-system (обязателен);
#   HOME          — для cross-repo резолва (берётся из окружения);
#   EXTRA_TSV     — опционально: ещё один TSV (для негативного самотеста —
#                   внести фантом во временной копии, не трогая основной список).
#
# Вывод:
#   OK: N путей на месте            — все существуют (cross-repo SKIP не в счёт);
#   PHANTOM: <path> (источник: ...) — на каждый отсутствующий путь;
#   SKIP (cross-repo): <slug> ...   — продуктовый репо недоступен.
# Код выхода: 0 если фантомов нет, 1 если есть хоть один.

import os
import sys


def read_tsv(path):
    rows = []
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 3:
                # терпим неполные строки — пропускаем, но предупреждаем
                print(f"WARN: строка без 3 полей пропущена: {line!r}", file=sys.stderr)
                continue
            scope, rel, source = parts[0].strip(), parts[1].strip(), parts[2].strip()
            rows.append((scope, rel, source))
    return rows


def main():
    tsv = os.environ.get("CONTRACT_TSV")
    repo_root = os.environ.get("REPO_ROOT")
    home = os.environ.get("HOME", "")
    extra = os.environ.get("EXTRA_TSV", "")

    if not tsv or not repo_root:
        print("ERROR: CONTRACT_TSV и REPO_ROOT обязательны", file=sys.stderr)
        return 2

    rows = read_tsv(tsv)
    if extra and os.path.exists(extra):
        rows += read_tsv(extra)

    phantoms = []
    skipped = []
    ok_count = 0

    for scope, rel, source in rows:
        if scope == "intra":
            base = repo_root
        elif scope.startswith("crossrepo:"):
            slug = scope.split(":", 1)[1]
            product_repo = os.path.join(home, "Projects", slug)
            if not os.path.isdir(product_repo):
                # Продуктовый репо недоступен — честный SKIP, не phantom.
                skipped.append((slug, rel))
                continue
            base = product_repo
        else:
            print(f"WARN: неизвестный scope {scope!r} для {rel}", file=sys.stderr)
            phantoms.append((rel, source, f"неизвестный scope {scope}"))
            continue

        full = os.path.join(base, rel)
        if os.path.exists(full):
            ok_count += 1
        else:
            phantoms.append((rel, source, scope))

    if skipped:
        seen_slugs = sorted({slug for slug, _ in skipped})
        for slug in seen_slugs:
            n = sum(1 for s, _ in skipped if s == slug)
            print(f"SKIP (cross-repo): {slug} недоступен — {n} путь(ей) не проверено")

    if phantoms:
        for rel, source, scope in phantoms:
            print(f"PHANTOM: {rel} (источник: {source}; scope: {scope})")
        print(f"ИТОГО: {len(phantoms)} фантом(ов), {ok_count} путей на месте")
        return 1

    print(f"OK: {ok_count} путей на месте")
    return 0


if __name__ == "__main__":
    sys.exit(main())
