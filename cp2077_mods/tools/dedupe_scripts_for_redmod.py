#!/usr/bin/env python3
"""Remove orphan/duplicate REDscripts that break REDmod compile on launch."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def manifest_scripts() -> set[str]:
    toml = (ROOT / "redmod.toml").read_text(encoding="utf-8")
    block = toml.split("scripts = [", 1)[1].split("]", 1)[0]
    return set(re.findall(r'"([^"]+\.reds)"', block))


def orphan_paths() -> list[Path]:
    allowed = manifest_scripts()
    orphans: list[Path] = []
    for path in SCRIPTS.rglob("*.reds"):
        rel = path.relative_to(SCRIPTS).as_posix()
        if rel not in allowed:
            orphans.append(path)
    return sorted(orphans)


def duplicate_type_scan() -> list[tuple[str, list[str]]]:
    pat = re.compile(r"^public (?:class|struct|enum) (\w+)")
    defs: dict[str, list[str]] = {}
    allowed = manifest_scripts()
    for path in SCRIPTS.rglob("*.reds"):
        rel = path.relative_to(SCRIPTS).as_posix()
        if rel not in allowed:
            continue
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            m = pat.match(line.strip())
            if m:
                defs.setdefault(m.group(1), []).append(rel)
    return [(name, locs) for name, locs in sorted(defs.items()) if len(locs) > 1]


def main() -> int:
    removed = 0
    for path in orphan_paths():
        path.unlink()
        removed += 1
        print(f"removed orphan: scripts/{path.relative_to(SCRIPTS).as_posix()}")

    dups = duplicate_type_scan()
    if dups:
        print("\nWARNING: duplicate types remain in manifest scripts:")
        for name, locs in dups:
            print(f"  {name}: {locs}")
        return 1

    print(f"\nOK: {removed} orphan scripts removed; manifest={len(manifest_scripts())} scripts remain")
    return 0


if __name__ == "__main__":
    sys.exit(main())