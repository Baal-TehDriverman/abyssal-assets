#!/usr/bin/env python3
"""Resolve active Cyberpunk 2077 install path (Steam Proton may use D:)."""

from __future__ import annotations

import os
from pathlib import Path

CANDIDATES = [
    "/mnt/d/Games/steamapps/common/Cyberpunk 2077",
    os.path.expanduser("~/.local/share/Steam/steamapps/common/Cyberpunk 2077"),
    os.path.expanduser("~/.steam/steam/steamapps/common/Cyberpunk 2077"),
]


def resolve() -> Path:
    for c in CANDIDATES:
        p = Path(c)
        if (p / "bin" / "x64" / "Cyberpunk2077.exe").exists() or (p / "REDprelauncher.exe").exists():
            return p
    for c in CANDIDATES:
        p = Path(c)
        if p.exists():
            return p
    return Path(CANDIDATES[0])


if __name__ == "__main__":
    print(resolve())