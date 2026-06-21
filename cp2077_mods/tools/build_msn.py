#!/usr/bin/env python3
"""Verify deployed MSN mod install and report working-condition status."""

from __future__ import annotations

import json
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1]
DEPLOYED = Path(
    "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration"
)
CACHE = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/cache")
REQUIRED = [
    "scripts/lilith_sovereign_kernel.reds",
    "scripts/msn_service_endpoints.reds",
    "scripts/msn_symbiosis_bridge.reds",
    "scripts/msn_grand_theft_cyberpunk_hub.reds",
    "scripts/msn_api_dialogue_bridge.reds",
    "scripts/msn_token_economy.reds",
    "scripts/msn_procgen_engine.reds",
    "scripts/cyberpunk_ngd_bridge.reds",
    "scripts/msn_gaming_engine.reds",
    "scripts/msn_gtc_sephirotic_router.reds",
    "info.json",
    "redmod.toml",
    "msn_tweakdb.toml",
]


def main() -> int:
    missing = [p for p in REQUIRED if not (DEPLOYED / p).exists()]
    compiled = (CACHE / "final.redscripts").exists()
    tweakdb = (CACHE / "tweakdb.bin").exists()
    game_root = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077")
    has_redscript = (game_root / "engine/tools/scc.exe").exists() or (
        game_root / "engine/tools/scc"
    ).exists()
    cache_dir = CACHE.exists()

    info = json.loads((DEPLOYED / "info.json").read_text()) if (DEPLOYED / "info.json").exists() else {}
    script_count = len(list((DEPLOYED / "scripts").rglob("*.reds"))) if (DEPLOYED / "scripts").exists() else 0

    report = {
        "deployed": DEPLOYED.exists(),
        "scripts_deployed": script_count,
        "info_version": info.get("version"),
        "missing_required": missing,
        "compiled_redscripts": compiled,
        "compiled_tweakdb": tweakdb,
        "cache_dir_exists": cache_dir,
        "redscript_framework": has_redscript,
        "working_condition": len(missing) == 0 and has_redscript and DEPLOYED.exists(),
        "next_step": (
            "Run tools/install_frameworks.sh then launch game with REDmod enabled"
            if not has_redscript
            else (
                "Launch game with REDmod — cache compiles on first run"
                if not compiled
                else "In-game: msn.gtc.status | msn.engine.status"
            )
        ),
    }
    out = SOURCE / "output" / "working_condition.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2))

    print(json.dumps(report, indent=2))
    return 0 if len(missing) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())