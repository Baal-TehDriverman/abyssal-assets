#!/usr/bin/env python3
"""Restore incomplete REDscript implementations from .msn_engine_bak backups."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOYED = Path(
    "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration"
)
GTC_UI = Path(
    "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/scripts/gtc_unified"
)

STRIP_MARKERS = [
    "// === LILITH + BAAL IMPROVED MSN ALGORITHM",
    "// === MSN GAMING ENGINE v3.0",
    "# === MSN GAMING ENGINE v3.0",
    "MSN_Engine:",
]


def strip_injection(text: str) -> str:
    for marker in STRIP_MARKERS:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx]
    return text.rstrip() + "\n"


def restore_from_bak(bak: Path, dest: Path) -> bool:
    if dest.exists():
        return False
    content = strip_injection(bak.read_text(encoding="utf-8", errors="ignore"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")
    return True


def fix_gtc_sync(reds_path: Path) -> bool:
    text = reds_path.read_text(encoding="utf-8", errors="ignore")
    original = text
    text = re.sub(
        r"\n// Force the shard to announce on load\n@wrapMethod\(ScriptableSystem\)\nprotected func OnAttach\(\) -> Void \{[^}]+\}\s*$",
        "",
        text,
        flags=re.DOTALL,
    )
    text = re.sub(
        r'GTCSync_\d+\\("mod_loaded_synchronized"\\);',
        'GTCSync_029("mod_loaded_synchronized");',
        text,
    )
    text = re.sub(
        r'(GTCSync_\d+\(s"system_attach[^"]*"\);)\s*\}',
        r'\1\n    GTCSync_029("mod_loaded_synchronized");\n}',
        text,
        count=1,
    )
    if text == original:
        return False
    reds_path.write_text(text.rstrip() + "\n", encoding="utf-8")
    return True


def main() -> int:
    restored = 0
    for bak in sorted(DEPLOYED.glob("*.reds.msn_engine_bak")):
        name = bak.name.replace(".msn_engine_bak", "")
        dest = ROOT / name
        if restore_from_bak(bak, dest):
            print(f"  restored {name}")
            restored += 1

    ui_dir = ROOT / "scripts" / "ui"
    if GTC_UI.exists():
        for src in GTC_UI.glob("*.reds"):
            if src.name.endswith(".msn_engine_bak"):
                continue
            dest = ui_dir / src.name
            if dest.exists():
                continue
            content = strip_injection(src.read_text(encoding="utf-8", errors="ignore"))
            ui_dir.mkdir(parents=True, exist_ok=True)
            dest.write_text(content, encoding="utf-8")
            print(f"  ui restored {src.name}")
            restored += 1

    mods_dir = DEPLOYED.parent
    fixed = 0
    for sync_mod in mods_dir.glob("gtc_aethon_sync_*/scripts/*.reds"):
        if fix_gtc_sync(sync_mod):
            fixed += 1

    print(f"Restored {restored} scripts, fixed {fixed} gtc_aethon_sync mods")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())