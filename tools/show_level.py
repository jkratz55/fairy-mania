#!/usr/bin/env python3
"""Shows a Fairy Mania level layout as a readable grid with column numbers, and checks it for mistakes.

Layouts live in levels/level_N.tres as one long string, which is hard to read or edit by hand.

    python3 tools/show_level.py 7                  # print level 7 as a grid
    python3 tools/show_level.py 7 --from 90 --to 140
    python3 tools/show_level.py --check            # check every level, print only problems

Uses only the Python standard library (works with the Python 3.9 that ships with macOS).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROWS = 15
LEGEND = set(".#=PGCoh*?TSgfb^MVQR|")


def read_tres_string(text: str, key: str) -> str | None:
    """Returns the value of `key = "..."` (which may span lines), unescaping \\" and \\\\."""
    match = re.search(r'^%s = "((?:[^"\\]|\\.)*)"' % re.escape(key), text, re.M | re.S)
    if match is None:
        return None
    return re.sub(r"\\(.)", r"\1", match.group(1))


def read_signs(text: str) -> list[str]:
    match = re.search(r"^signs = PackedStringArray\((.*?)\)\s*$", text, re.M | re.S)
    if match is None:
        return []
    return [re.sub(r"\\(.)", r"\1", s) for s in re.findall(r'"((?:[^"\\]|\\.)*)"', match.group(1))]


def level_paths() -> list[Path]:
    game = (ROOT / "autoload/game.gd").read_text()
    return [ROOT / p.removeprefix("res://") for p in re.findall(r'"(res://levels/[^"]+\.tres)"', game)]


def known_themes() -> set[str]:
    data = (ROOT / "scripts/level_data.gd").read_text()
    match = re.search(r"@export_enum\(([^)]*)\) var theme", data)
    return set(re.findall(r'"([^"]+)"', match.group(1))) if match else set()


def known_songs() -> set[str]:
    synth = (ROOT / "scripts/synth.gd").read_text()
    block = synth[synth.index("const SONGS"):]
    return set(re.findall(r'^\t"(\w+)": \{', block, re.M))


def resolve(level: str) -> Path:
    if level.isdigit():
        paths = level_paths()
        index = int(level) - 1
        if not 0 <= index < len(paths):
            sys.exit("There are %d levels in Game.LEVELS." % len(paths))
        return paths[index]
    return Path(level).resolve()


def check(path: Path) -> list[str]:
    """Problems that would break the level or confuse players. Empty means it looks fine."""
    text = path.read_text()
    layout = read_tres_string(text, "layout")
    if layout is None:
        return ["no layout found"]
    rows = layout.split("\n")
    flat = "".join(rows)
    problems: list[str] = []
    if len(rows) != ROWS:
        problems.append("has %d rows (levels use %d)" % (len(rows), ROWS))
    widths = {len(r) for r in rows}
    if len(widths) > 1:
        problems.append("rows have different lengths %s (short rows are padded with empty space)" % sorted(widths))
    unknown = sorted(set(flat) - LEGEND)
    if unknown:
        problems.append("unknown layout characters: %s" % " ".join(repr(c) for c in unknown))
    if flat.count("P") != 1:
        problems.append("needs exactly one player start P (found %d)" % flat.count("P"))
    is_boss = "Q" in flat or "R" in flat
    if is_boss and not ("Q" in flat and "R" in flat):
        problems.append("a boss level needs both the Queen Q and her mirror R")
    if not is_boss and "G" not in flat:
        problems.append("has no goal gate G")
    signs = read_signs(text)
    if flat.count("S") != len(signs):
        problems.append("has %d sign cells S but %d sign texts" % (flat.count("S"), len(signs)))
    theme = read_tres_string(text, "theme")
    if theme not in known_themes():
        problems.append("theme %r is not in LevelData's theme list" % theme)
    music = read_tres_string(text, "music")
    if music not in known_songs():
        problems.append("music %r is not a song in Synth.SONGS" % music)
    if path.resolve() not in [p.resolve() for p in level_paths()]:
        problems.append("is not listed in Game.LEVELS (autoload/game.gd)")
    return problems


def show(path: Path, first: int, last: int | None, width: int) -> None:
    text = path.read_text()
    rows = (read_tres_string(text, "layout") or "").split("\n")
    columns = max(len(r) for r in rows)
    rows = [r.ljust(columns, ".") for r in rows]
    last = columns - 1 if last is None else min(last, columns - 1)
    print("%s  %r  theme=%s music=%s  %d columns x %d rows" % (
        path.relative_to(ROOT) if path.is_relative_to(ROOT) else path,
        read_tres_string(text, "title"), read_tres_string(text, "theme"), read_tres_string(text, "music"),
        columns, len(rows)))
    for start in range(first, last + 1, width):
        end = min(start + width, last + 1)
        # Full column numbers every 10 columns (90, 100, 110...) above a row of units digits.
        labels = [" "] * (end - start)
        for c in range(start, end):
            if c % 10 == 0:
                for i, digit in enumerate(str(c)):
                    if c - start + i < len(labels):
                        labels[c - start + i] = digit
        tens = "".join(labels)
        units = "".join(str(c % 10) for c in range(start, end))
        print()
        print("    " + tens)
        print("    " + units)
        for y, row in enumerate(rows):
            print("%2d  %s" % (y, row[start:end]))
    signs = read_signs(text)
    if signs:
        print("\nSigns (left to right):")
        for i, sign in enumerate(signs, 1):
            print("  %d. %s" % (i, sign))
    problems = check(path)
    print("\nProblems:" if problems else "\nNo problems found.")
    for problem in problems:
        print("  - " + problem)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("level", nargs="?", help="level number (as in Game.LEVELS) or a path to a .tres file")
    parser.add_argument("--from", dest="first", type=int, default=0, help="first column to show")
    parser.add_argument("--to", dest="last", type=int, help="last column to show")
    parser.add_argument("--width", type=int, default=100, help="columns per block (default 100)")
    parser.add_argument("--check", action="store_true", help="check every level in Game.LEVELS")
    args = parser.parse_args()
    if args.check:
        failed = False
        for i, path in enumerate(level_paths(), 1):
            problems = check(path)
            failed = failed or bool(problems)
            print("level %d (%s): %s" % (i, path.name, "ok" if not problems else "; ".join(problems)))
        sys.exit(1 if failed else 0)
    if args.level is None:
        parser.error("give a level number, or use --check")
    show(resolve(args.level), max(args.first, 0), args.last, args.width)


if __name__ == "__main__":
    main()
