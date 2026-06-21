#!/usr/bin/env python3
"""Strip duplicate @wrapMethod hooks from gtc_aethon_sync mods — central engine owns hooks."""

from __future__ import annotations

import re
from pathlib import Path

MODS = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods")
SOURCE_MODS = Path(__file__).resolve().parents[1]

HOOK_BLOCK = re.compile(
    r"\n@wrapMethod\(ScriptableSystem\).*?"
    r"@wrapMethod\(NPCPuppet\).*?"
    r"GTCSync_\d+\(s\"domain_event[^\"]*\"\);\n\}\n",
    re.DOTALL,
)

SINGLE_HOOKS = [
    re.compile(r"\n@wrapMethod\(ScriptableSystem\)[\s\S]*?\n\}\n", re.MULTILINE),
    re.compile(r"\n@wrapMethod\(PlayerPuppet\)[\s\S]*?\n\}\n", re.MULTILINE),
    re.compile(r"\n@wrapMethod\(NPCPuppet\)[\s\S]*?\n\}\n", re.MULTILINE),
]


def slim_reds(text: str) -> str:
    text = text.replace("import MSNGamingEngine.*\n", "")
    text = text.replace('GTCSync_029("mod_loaded_synchronized");', "")
    for pat in SINGLE_HOOKS:
        text = pat.sub("\n", text)
    # Route through central engine comment
    if "PERF_OPTIMIZED" not in text and "public static func GTCSync_" in text:
        text = text.replace(
            "/// Do not touch the title here.",
            "/// Do not touch the title here.\n/// PERF_OPTIMIZED: hooks removed — routed via msn_gaming_engine.reds",
        )
    return re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n"


def process(path: Path) -> bool:
    original = path.read_text(encoding="utf-8", errors="ignore")
    updated = slim_reds(original)
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    changed = 0
    for root in (MODS, SOURCE_MODS):
        for p in root.glob("gtc_aethon_sync_*/scripts/*.reds"):
            if process(p):
                changed += 1
    print(f"Optimized {changed} gtc_aethon_sync mods (hooks stripped)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())