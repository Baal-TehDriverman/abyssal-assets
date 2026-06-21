#!/usr/bin/env python3
"""Regenerate msn_integration.cpmodproj from scripts/ and tweakdb/."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
TWEAKDB = ROOT / "tweakdb"
QUESTS = ROOT / "quests"
LOC = ROOT / "localization" / "en"

PRIORITY = [
    "lilith_sovereign_kernel.reds",
    "msn_gaming_engine.reds",
    "msn_service_endpoints.reds",
    "msn_symbiosis_bridge.reds",
    "msn_master_integration.reds",
    "msn_grand_theft_cyberpunk_hub.reds",
]


def rel_scripts() -> list[str]:
    found = sorted(p.relative_to(SCRIPTS).as_posix() for p in SCRIPTS.rglob("*.reds"))
    ordered: list[str] = []
    seen: set[str] = set()
    for name in PRIORITY:
        if name in found and name not in seen:
            ordered.append(name)
            seen.add(name)
    for name in found:
        if name not in seen:
            ordered.append(name)
            seen.add(name)
    return ordered


def tweakdb_files() -> list[str]:
    patterns = ("*.yaml", "*.yml", "*.toml", "*.tweakdb")
    files: list[str] = []
    for pat in patterns:
        files.extend(p.relative_to(ROOT).as_posix() for p in TWEAKDB.rglob(pat))
    if (ROOT / "msn_tweakdb.toml").exists():
        files.insert(0, "msn_tweakdb.toml")
    return sorted(set(files))


def main() -> int:
    reds = rel_scripts()
    tweaks = tweakdb_files()
    quests = sorted(p.relative_to(ROOT).as_posix() for p in QUESTS.glob("*.yaml"))
    locs = sorted(p.relative_to(ROOT).as_posix() for p in LOC.glob("*.loc")) if LOC.exists() else []

    lines = [
        '<Project Sdk="WolvenKit.REDmod.Sdk">',
        "  <PropertyGroup>",
        "    <TargetFramework>WolvenKit.REDmod</TargetFramework>",
        "    <Name>msn_integration</Name>",
        "    <Version>2.0.0-lilith</Version>",
        "    <Author>Lilith Systems LLC</Author>",
        "    <Description>MSN Integration — complete sovereign Lilith stack for Cyberpunk 2077</Description>",
        "    <GameVersion>2.12+</GameVersion>",
        "    <RedmodVersion>1.0</RedmodVersion>",
        "  </PropertyGroup>",
        "  <ItemGroup>",
        '    <TweakDB Include="msn_tweakdb.toml" />',
    ]
    for r in reds:
        win_path = "scripts\\" + r.replace("/", "\\")
        lines.append(f'    <REDscript Include="{win_path}" />')
    lines.append("  </ItemGroup>")
    lines.append("  <ItemGroup>")
    for t in tweaks:
        if t == "msn_tweakdb.toml":
            continue
        win_path = t.replace("/", "\\")
        lines.append(f'    <TweakDBFile Include="{win_path}" />')
    lines.append("  </ItemGroup>")
    if locs:
        lines.append("  <ItemGroup>")
        for loc in locs:
            lines.append(f'    <Localization Include="{loc.replace("/", "\\")}" />')
        lines.append("  </ItemGroup>")
    if quests:
        lines.append("  <ItemGroup>")
        for q in quests:
            lines.append(f'    <Quest Include="{q.replace("/", "\\")}" />')
        lines.append("  </ItemGroup>")
    lines.append("</Project>")

    out = ROOT / "msn_integration.cpmodproj"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {out.name}: {len(reds)} REDscripts, {len(tweaks)} TweakDB, {len(quests)} quests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())