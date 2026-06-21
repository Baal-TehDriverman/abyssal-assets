#!/usr/bin/env python3
"""Generate mod completion report with checklist."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOYED = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration")
GAME_MODS = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods")
CACHE = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/cache")
GAME = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077")

CORE_SCRIPTS = [
    "msn_gaming_engine.reds",
    "msn_gtc_sephirotic_router.reds",
    "msn_grand_theft_cyberpunk_hub.reds",
    "msn_symbiosis_bridge.reds",
    "msn_token_economy.reds",
    "msn_procgen_engine.reds",
    "lilith_sovereign_kernel.reds",
]


def count_gtc() -> tuple[int, int]:
    total = len(list(GAME_MODS.glob("gtc_aethon_sync_*")))
    optimized = 0
    for p in GAME_MODS.glob("gtc_aethon_sync_*/scripts/*.reds"):
        if "PERF_OPTIMIZED" in p.read_text(encoding="utf-8", errors="ignore"):
            optimized += 1
    return total, optimized


def cpmodproj_scripts() -> int:
    proj = ROOT / "msn_integration.cpmodproj"
    if not proj.exists():
        return 0
    return proj.read_text().count("REDscript Include")


def main() -> int:
    scripts_dir = DEPLOYED / "scripts"
    deployed_scripts = len(list(scripts_dir.rglob("*.reds"))) if scripts_dir.exists() else 0
    source_scripts = len(list((ROOT / "scripts").rglob("*.reds")))
    gtc_total, gtc_opt = count_gtc()
    missing_core = [s for s in CORE_SCRIPTS if not (scripts_dir / s).exists() and not (scripts_dir / "ui" / s).exists()]

    compiled = (CACHE / "final.redscripts").exists() or (CACHE / "modded" / "final.redscripts").exists()
    has_scc = (GAME / "engine/tools/scc.exe").exists()
    has_red4ext = (GAME / "red4ext").exists()

    checks = {
        "source_scripts": source_scripts,
        "deployed_scripts": deployed_scripts,
        "cpmodproj_entries": cpmodproj_scripts(),
        "core_scripts_present": len(missing_core) == 0,
        "missing_core": missing_core,
        "gtc_sync_mods": gtc_total,
        "gtc_optimized": gtc_opt,
        "redscript_framework": has_scc,
        "red4ext_installed": has_red4ext,
        "compiled_cache": compiled,
        "info_json": (DEPLOYED / "info.json").exists(),
        "redmod_toml": (DEPLOYED / "redmod.toml").exists(),
        "msn_tweakdb": (DEPLOYED / "msn_tweakdb.toml").exists(),
    }

    complete = (
        checks["core_scripts_present"]
        and checks["deployed_scripts"] >= 100
        and checks["cpmodproj_entries"] >= 100
        and checks["gtc_sync_mods"] >= 100
        and checks["gtc_optimized"] >= 100
        and checks["redscript_framework"]
        and checks["info_json"]
        and checks["redmod_toml"]
    )

    report = {
        "schema": "msn.mod_completion.v1",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "2.0.0-lilith",
        "complete": complete,
        "compiled_ready": compiled,
        "checks": checks,
        "tracks": {
            "core_msn": True,
            "gaming_engine_v2": (scripts_dir / "msn_gaming_engine.reds").exists(),
            "sephirotic_router": (scripts_dir / "msn_gtc_sephirotic_router.reds").exists(),
            "hell_campaign": (scripts_dir / "msn_hell_campaign.reds").exists(),
            "magic_jedi_starwars": (scripts_dir / "magic").exists(),
            "living_sin": (scripts_dir / "livingsin_time_blade.reds").exists(),
            "ngd_bridge": (scripts_dir / "cyberpunk_ngd_bridge.reds").exists(),
            "token_economy": (scripts_dir / "msn_token_economy.reds").exists(),
            "restored_systems": (scripts_dir / "msn_wanted_level.reds").exists(),
            "ui_layer": (scripts_dir / "ui").exists(),
        },
        "next_step": (
            "Launch game with REDmod enabled — compiles final.redscripts on first run"
            if not compiled
            else "Mods complete — play and verify console commands"
        ),
        "console_verify": [
            "msn.gtc.status",
            "msn.engine.status",
            "msn.gtc.shards",
            "msn.symbiosis.sync",
            "msn.tokens.sync",
            "msn.dialogue.lilith hello",
        ],
    }

    out = ROOT / "output" / "completion_report.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))
    return 0 if complete else 1


if __name__ == "__main__":
    raise SystemExit(main())