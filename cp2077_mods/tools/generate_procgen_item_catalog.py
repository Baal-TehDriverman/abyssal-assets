#!/usr/bin/env python3
"""Generate deterministic procgen weapon catalog for MSN Cyberpunk mods."""

from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "tweakdb/msn_procgen_weapon_catalog.yaml"

FAMILIES = [
    ("Voidsplitter", "SniperRifle", "Physical+Void", "Binah"),
    ("Kraken", "HeavyWeapon", "Physical+Void+Pressure", "Geburah"),
    ("Nyx", "Melee", "Physical+Void", "Hod"),
    ("Lucifer", "Pistol", "Thermal+Light", "Kether"),
    ("LivingSin", "Katana", "Temporal+Paradox", "Tiphareth"),
    ("Phantom", "SMG", "Physical+Net", "Yesod"),
    ("Nessie", "Shotgun", "Physical+Pressure", "Chesed"),
    ("Ouroboros", "AssaultRifle", "Physical+Memory", "Malkuth"),
]

PREFIXES = [
    "Abyssal", "Orbital", "Sovereign", "Chromatic", "Nacre", "Void",
    "Solar", "Phantom", "Crimson", "Violet", "Nyx", "Thoth",
]

SUFFIXES = ["Mk I", "Mk II", "Mk III", "Prime", "Echo", "Resonance"]

RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

lines = [
    "schema: msn.procgen_weapon_catalog.v1",
    "localOnly: true",
    "generatedCount: 96",
    "purpose: >",
    "  Deterministic procgen weapon variants for MSN ProcGen Engine.",
    "  Same seed recreates same item; memory hash mutates stats.",
    "integration:",
    "  engine: scripts/msn_procgen_engine.reds",
    "  factory: scripts/msn_custom_item_factory.reds",
    "  consoleCommands:",
    "    - msn.procedural.generate_weapon",
    "    - msn.items.grant procgen",
    "items:",
]

for i in range(96):
    family, category, dmg_type, seph = FAMILIES[i % len(FAMILIES)]
    prefix = PREFIXES[(i * 7) % len(PREFIXES)]
    suffix = SUFFIXES[(i * 3) % len(SUFFIXES)]
    rarity = RARITIES[min(4, i // 20)]
    tier = 1 + (i // 12)
    damage = int(80 * tier + (i % 12) * 15)
    item_id = f"MSN_ProcGen_{prefix}_{family}_{i:03d}"
    lines += [
        f"  - id: {item_id}",
        f"    displayName: \"{prefix} {family} {suffix}\"",
        f"    category: {category}",
        f"    rarity: {rarity}",
        f"    damage: {damage}",
        f"    damageType: {dmg_type}",
        f"    sephirah: {seph}",
        f"    seedChannel: {i}",
        f"    procgenTag: msn.procgen.weapon.v1",
    ]

OUT.write_text("\n".join(lines) + "\n")
print(f"Wrote {OUT} ({96} procgen weapons)")