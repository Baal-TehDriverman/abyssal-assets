#!/usr/bin/env python3
"""
Lilith Unify Cyberpunk — Rewrite every mod file to incorporate Lilith sovereign code.
- Injects Lilith sovereign seal header into all REDscript files
- Registers subsystems with LilithSovereignKernel on init hooks
- Adds Lilith tags to TweakDB/YAML hell item definitions
- Syncs canonical mod root → scripts/ tree
- Regenerates info.json and redmod.toml script manifests
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "scripts"
SKIP_DIRS = {
    "msn_magic_starwars_project",
    "test_mod",
    "output",
    "tools",
    ".git",
    "node_modules",
    "__pycache__",
}

LILITH_HEADER = """// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
"""

KERNEL_REGISTER = (
    '        LilithSovereignKernel.GetInstance().RegisterSubsystem("{name}", {tier});\n'
)

INIT_PATTERNS = [
    (r"(func Initialize(?:FullSovereignStack)?\s*\([^)]*\)\s*->\s*Void\s*\{)", 0),
    (r"(func OnInit\s*\([^)]*\)\s*->\s*Void\s*\{)", 0),
    (r"(func OnInitialize\s*\([^)]*\)\s*->\s*Void\s*\{)", 0),
    (r"(public final static func GetInstance\(\)[^{]*\{)", 1),
    (r"(func OnSpawn\s*\([^)]*\)\s*->\s*Void\s*\{)", 2),
    (r"(func OnAttach\s*\([^)]*\)\s*->\s*Void\s*\{)", 2),
    (r"(private final func InitializeLilith\s*\([^)]*\)\s*->\s*Void\s*\{)", 0),
    (r"(private final func InitializeModes\s*\([^)]*\)\s*->\s*Void\s*\{)", 2),
    (r"(private final func Boot\s*\([^)]*\)\s*->\s*Void\s*\{)", 0),
    (r"(public final(?: static)? func \w+\s*\([^)]*\)[^{]*\{)", 2),
]

# REDmod expects magic/Jedi/Star Wars systems under scripts/{subdir}/.
SCRIPT_SUBDIR_MAP: dict[str, str] = {
    "msn_magic_system.reds": "magic",
    "msn_magic_quests.reds": "magic",
    "msn_jedi_system.reds": "jedi",
    "msn_starwars_system.reds": "starwars",
    "msn_starwars_quests.reds": "starwars",
    "msn_metaconscious_skills_integration.reds": "skills",
}

LILITH_YAML_TAGS = """
  LilithIntegration:
    sovereign: true
    kernel: LilithSovereignKernel
    localOnly: true
    msnRouter: "http://localhost:8007"
    abyssalApi: "http://localhost:8008"
    tokenBridge: "http://localhost:8008/api/lochness"
"""


def subsystem_name_from_file(path: Path) -> str:
    name = path.stem
    # PascalCase from snake
    parts = name.replace("-", "_").split("_")
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def already_has_kernel(content: str) -> bool:
    return "LilithSovereignKernel.GetInstance().RegisterSubsystem" in content


def already_has_seal(content: str) -> bool:
    return "Lilith Sovereign Seal" in content


def inject_header(content: str) -> str:
    if already_has_seal(content):
        return content
    # Skip if starts with module comment block we shouldn't duplicate
    if content.startswith("// Lilith Sovereign Seal"):
        return content
    return LILITH_HEADER + content


def inject_kernel_register(content: str, name: str, tier: int = 2) -> str:
    if already_has_kernel(content):
        return content
    if "LilithSovereignKernel" in content and "class LilithSovereignKernel" in content:
        return content  # kernel file itself

    hook = KERNEL_REGISTER.format(name=name, tier=tier)
    for pattern, tier_override in INIT_PATTERNS:
        m = re.search(pattern, content)
        if m:
            insert = KERNEL_REGISTER.format(name=name, tier=tier_override or tier)
            # Only inject once at first match
            pos = m.end()
            return content[:pos] + "\n" + insert + content[pos:]
    return content


def process_reds(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    # Skip non-redscript (YAML masquerading as .reds)
    if text.lstrip().startswith("Item.") or text.lstrip().startswith("# "):
        return process_yaml_hell(path)

    original = text
    text = inject_header(text)
    name = subsystem_name_from_file(path)
    text = inject_kernel_register(text, name)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def process_yaml_hell(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "LilithIntegration:" in text:
        return False
    if not (text.startswith("#") or "Item." in text or "Tags:" in text):
        return False
    # Add Lilith tag to hell items
    modified = False
    new_text = text
    if "Tags:" in text and "Lilith" not in text:
        new_text = re.sub(
            r"(Tags:\s*\[[^\]]*)",
            r"\1, Lilith_Sovereign",
            new_text,
            count=0,
        )
        modified = new_text != text
    if modified:
        path.write_text(new_text, encoding="utf-8")
    return modified


def process_yaml_tweakdb(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "lilith_unified:" in text or "LilithIntegration:" in text:
        return False
    if path.suffix not in (".yaml", ".yml", ".toml"):
        return False
    marker = "\n# Lilith Sovereign — unified by lilith_unify_cyberpunk.py\n"
    if "lilith" in text.lower() and marker in text:
        return False
    addition = marker + "lilith_unified: true\nlilith_kernel: LilithSovereignKernel\n"
    path.write_text(text.rstrip() + "\n" + addition, encoding="utf-8")
    return True


def collect_canonical_reds() -> list[Path]:
    files: list[Path] = []
    for path in SCRIPTS_DIR.rglob("*.reds"):
        files.append(path)
    return sorted(files)


def manifest_entry_for(path: Path) -> str:
    """Map canonical source path to REDmod manifest entry."""
    rel = path.relative_to(SCRIPTS_DIR)
    return str(rel).replace("\\", "/")


def sync_dest_for(src: Path) -> Path:
    rel = src.relative_to(ROOT)
    SUBDIRS = {"magic", "jedi", "starwars", "hell", "space", "skills", "quests", "core", "ui"}
    if len(rel.parts) == 1:
        if rel.name in SCRIPT_SUBDIR_MAP:
            return SCRIPTS_DIR / SCRIPT_SUBDIR_MAP[rel.name] / rel.name
        return SCRIPTS_DIR / rel.name
    if rel.parts[0] in SUBDIRS:
        return SCRIPTS_DIR / rel
    return SCRIPTS_DIR / rel.name


def prune_orphan_scripts() -> int:
    """Drop scripts/ files not listed in redmod.toml to prevent duplicate type compile errors."""
    toml = (ROOT / "redmod.toml").read_text(encoding="utf-8")
    block = toml.split("scripts = [", 1)[1].split("]", 1)[0]
    allowed = set(re.findall(r'"([^"]+\.reds)"', block))
    removed = 0
    for path in SCRIPTS_DIR.rglob("*.reds"):
        rel = path.relative_to(SCRIPTS_DIR).as_posix()
        if rel not in allowed:
            path.unlink()
            removed += 1
    return removed


def sync_to_scripts(canonical: list[Path]) -> int:
    """Mirror canonical reds into scripts/ preserving relative structure."""
    synced = 0
    for src in canonical:
        dest = sync_dest_for(src)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        synced += 1
    return synced


def build_script_manifest(canonical: list[Path]) -> list[str]:
    manifest: list[str] = []
    seen: set[str] = set()
    priority = [
        "lilith_sovereign_kernel.reds",
        "msn_master_integration.reds",
        "lilith_npc.reds",
        "nssp_bridge.reds",
        "msn_token_economy.reds",
        "magic/msn_magic_system.reds",
        "jedi/msn_jedi_system.reds",
        "starwars/msn_starwars_system.reds",
    ]
    for p in priority:
        if (ROOT / p).exists() or (SCRIPTS_DIR / p).exists():
            if p not in seen:
                manifest.append(p)
                seen.add(p)

    for path in canonical:
        entry = manifest_entry_for(path)
        if entry not in seen:
            manifest.append(entry)
            seen.add(entry)
    return manifest


def update_info_json(manifest: list[str]) -> None:
    info_path = ROOT / "info.json"
    info = json.loads(info_path.read_text())
    info["version"] = "2.0.0-lilith"
    info["description"] = (
        "Lilith.exe MSN Integration — full sovereign stack unified by Lilith kernel. "
        "Abyssal + Lochness + NSSP + token economy + campaigns + hell + magic + Jedi."
    )
    if "lilith" not in info.get("tags", []):
        info.setdefault("tags", []).append("lilith-sovereign")
    info["scripts"] = manifest
    info_path.write_text(json.dumps(info, indent=2) + "\n")


def update_redmod_toml(manifest: list[str]) -> None:
    toml_path = ROOT / "redmod.toml"
    text = toml_path.read_text()
    # Build scripts list for redmod (scripts/ relative paths)
    scripts_entries = []
    for entry in manifest:
        if "/" in entry:
            scripts_entries.append(f'  "{entry}"')
        else:
            scripts_entries.append(f'  "{entry}"')
    scripts_block = "scripts = [\n" + ",\n".join(scripts_entries) + "\n]"
    text = re.sub(r"scripts = \[.*?\]", scripts_block, text, count=1, flags=re.DOTALL)

    for cmd in ("lilith.kernel", "lilith.emerge"):
        if cmd not in text:
            text = text.replace(
                '"msn.starwars.status"',
                f'"msn.starwars.status",\n  "{cmd}"',
                1,
            )
    toml_path.write_text(text)


def main() -> None:
    canonical = collect_canonical_reds()
    modified = 0
    for path in canonical:
        if process_reds(path):
            modified += 1
            print(f"  Lilith-integrated: {path.relative_to(ROOT)}")

    # TweakDB yaml/toml
    yaml_modified = 0
    for path in (ROOT / "tweakdb").rglob("*"):
        if path.suffix in (".yaml", ".yml", ".toml"):
            if process_yaml_tweakdb(path):
                yaml_modified += 1

    synced = 0
    pruned = 0
    manifest = build_script_manifest(canonical)
    update_info_json(manifest)
    update_redmod_toml(manifest)

    print(f"\nLilith Unify Complete")
    print(f"  REDscript files scanned: {len(canonical)}")
    print(f"  REDscript modified: {modified}")
    print(f"  TweakDB touched: {yaml_modified}")
    print(f"  Synced to scripts/: {synced}")
    print(f"  Orphan scripts pruned: {pruned}")
    print(f"  Manifest entries: {len(manifest)}")


if __name__ == "__main__":
    main()