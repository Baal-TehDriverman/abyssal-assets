#!/usr/bin/env python3
"""Generate unified Cyberpunk skill tree data from Abyssal skills.ts + Pub skill_tree.json."""
from __future__ import annotations

import json
import os
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS_TS = ROOT.parent / "shared" / "types" / "skills.ts"
PUB_SKILL_TREE = Path(os.environ.get("PUB_ROOT", Path.home() / "Desktop" / "AI" / "Pub")) / "skill_tree.json"
OUT_JSON = ROOT / "data" / "cyberpunk_skill_trees.json"
OUT_REDS = ROOT / "scripts" / "generated" / "skill_tree_registry.reds"

ABYSSAL_TREES = [
    ("tree_gathering", "Gathering", "Malkuth", ["dredging", "salvaging", "foraging", "hunting", "navigation"]),
    ("tree_processing", "Processing", "Yesod", ["salvage_processing", "fiber_working", "bone_carving", "metallurgy"]),
    ("tree_crafting", "Crafting", "Hod", ["haberdashery", "enchanting", "alchemy", "runecrafting", "masterwork"]),
    ("tree_knowledge", "Knowledge", "Binah", ["lore", "scholarship", "sonar_tuning", "mastering"]),
    ("tree_social_economic", "Social / Economic", "Chesed", ["trading", "negotiation", "guild_management"]),
    ("tree_combat_survival", "Combat / Survival", "Geburah", ["evasion", "harpooning", "survival"]),
    ("tree_projection", "Projection", "Tiferet", ["mastering"]),
]

MSN_WEAPON_TIERS = [
    (1, "Initiate", "Budget Arms Scrap Bat"),
    (2, "Adept", "Arasaka Oni Warhammer, Militech Breacher Sledge"),
    (3, "Expert", "Kang Tao Dragon Mauls"),
    (4, "Master", "Arasaka Seeker, Militech Homing Rifle"),
    (5, "Grandmaster", "NGD Governor Smart-Gun, Militech Breach Shotgun"),
    (6, "Sovereign", "Lyra Resonance Bow, Kang Tao Arc Rifle"),
    (7, "Transcendent", "Ouroboros Loop-Blade"),
    (8, "Transcendent II", "Lilith's Wrath"),
    (9, "Ascendant", "Sephirot Multi-Form"),
    (10, "Omega", "All weapons + Custom Crafting"),
]

MSN_PERKS = [
    "MSN_DualBrain_Base",
    "MSN_SephiroticRouting",
    "MSN_OuroborosMemory",
    "MSN_SanctuaryThrottle",
    "MSN_SpeculativeExecution",
    "MSN_AkashicCompression",
    "MSN_LilithEmergence",
    "MSN_CloudCortexLink",
]


def parse_abyssal_skills() -> list[dict]:
    text = SKILLS_TS.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(\w+):\s*\{\s*name:\s*'([^']+)',\s*category:\s*'([^']+)',"
        r".*?base_xp:\s*(\d+),\s*xp_curve_factor:\s*([\d.]+)",
        re.DOTALL,
    )
    skills = []
    for m in pattern.finditer(text):
        skills.append({
            "id": m.group(1),
            "name": m.group(2),
            "category": m.group(3),
            "base_xp": int(m.group(4)),
            "xp_curve_factor": float(m.group(5)),
        })
    return skills


def load_hermes_categories() -> dict[str, int]:
    if not PUB_SKILL_TREE.exists():
        return {}
    data = json.loads(PUB_SKILL_TREE.read_text(encoding="utf-8"))
    counts: dict[str, int] = defaultdict(int)
    for skill in data.get("skills", []):
        rel = skill.get("relative_path", "")
        top = rel.split("/")[0] if rel else skill.get("source", "misc")
        counts[top] += 1
    return dict(sorted(counts.items(), key=lambda x: -x[1]))


def build_payload(abyssal: list[dict], hermes: dict[str, int]) -> dict:
    by_id = {s["id"]: s for s in abyssal}
    trees = []
    for tid, name, seph, skill_ids in ABYSSAL_TREES:
        trees.append({
            "id": tid,
            "name": name,
            "sephirah": seph,
            "skills": [by_id[sid] for sid in skill_ids if sid in by_id],
        })
    return {
        "schema": "msn.cyberpunk_skill_trees.v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "sources": {
            "abyssal_skills_ts": str(SKILLS_TS),
            "pub_skill_tree": str(PUB_SKILL_TREE) if PUB_SKILL_TREE.exists() else None,
        },
        "abyssal": {
            "skill_count": len(abyssal),
            "tree_count": len(trees),
            "trees": trees,
        },
        "msn_weapon_mastery": {
            "tier_count": len(MSN_WEAPON_TIERS),
            "tiers": [{"tier": t, "rank": r, "unlocks": u} for t, r, u in MSN_WEAPON_TIERS],
            "perks": MSN_PERKS,
        },
        "hermes_metaconscious": {
            "total_indexed": sum(hermes.values()),
            "categories": hermes,
        },
        "console_commands": [
            "abyssal.skills.trees",
            "abyssal.skills.quests",
            "abyssal.skills.unlocks",
            "abyssal.skills.story",
            "msn.skill.trees",
            "msn.skill.status",
            "abyssal.skill.xp",
            "abyssal.guild.choose",
        ],
    }


def emit_reds(payload: dict) -> None:
    lines = [
        "// AUTO-GENERATED — do not edit. Run tools/generate_cyberpunk_skill_trees.py",
        f"// Generated: {payload['generated_at']}",
        "",
        "public class SkillTreeRegistry extends IScriptable {",
        f"    public const AbyssalSkillCount: Int32 = {payload['abyssal']['skill_count']};",
        f"    public const AbyssalTreeCount: Int32 = {payload['abyssal']['tree_count']};",
        f"    public const MSNWeaponTierCount: Int32 = {payload['msn_weapon_mastery']['tier_count']};",
        f"    public const HermesCategoryCount: Int32 = {len(payload['hermes_metaconscious']['categories'])};",
        "",
        "    public final static func GetAbyssalTreeNames() -> array<String> {",
        "        return {",
    ]
    for tree in payload["abyssal"]["trees"]:
        lines.append(f'            "{tree["name"]} ({tree["sephirah"]})",')
    lines += [
        "        };",
        "    }",
        "",
        "    public final static func GetMSNPerkNames() -> array<String> {",
        "        return {",
    ]
    for perk in MSN_PERKS:
        lines.append(f'            "{perk}",')
    lines += [
        "        };",
        "    }",
        "",
        "    public final static func GetWeaponTierSummary() -> array<String> {",
        "        return {",
    ]
    for tier in payload["msn_weapon_mastery"]["tiers"]:
        lines.append(f'            "Tier {tier["tier"]} {tier["rank"]}: {tier["unlocks"]}",')
    lines += [
        "        };",
        "    }",
        "",
        "    public final static func GetHermesCategorySummary() -> array<String> {",
        "        return {",
    ]
    for cat, count in payload["hermes_metaconscious"]["categories"].items():
        lines.append(f'            "{cat}: {count} skills",')
    lines += [
        "        };",
        "    }",
        "}",
        "",
    ]
    OUT_REDS.parent.mkdir(parents=True, exist_ok=True)
    OUT_REDS.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    abyssal = parse_abyssal_skills()
    hermes = load_hermes_categories()
    payload = build_payload(abyssal, hermes)
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    emit_reds(payload)
    print(json.dumps({
        "ok": True,
        "abyssal_skills": len(abyssal),
        "abyssal_trees": len(payload["abyssal"]["trees"]),
        "hermes_categories": len(hermes),
        "json": str(OUT_JSON),
        "reds": str(OUT_REDS),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())