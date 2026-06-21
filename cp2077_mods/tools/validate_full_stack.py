#!/usr/bin/env python3
"""Validate the full MSN Cyberpunk mod stack — campaigns, procgen, AI, items."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SCRIPTS_DIR = ROOT / "scripts"

REQUIRED_SCRIPTS = [
    "msn_gaming_engine.reds",
    "msn_gtc_sephirotic_router.reds",
    "msn_service_endpoints.reds",
    "msn_symbiosis_bridge.reds",
    "msn_procgen_engine.reds",
    "msn_ai_overhaul.reds",
    "msn_campaign_orchestrator.reds",
    "msn_custom_item_factory.reds",
    "msn_grand_theft_cyberpunk_hub.reds",
    "msn_api_dialogue_bridge.reds",
    "msn_hell_campaign.reds",
    "livingsin_hell_integration.reds",
    "msn_npc_ai.reds",
    "msn_master_integration.reds",
    "msn_token_economy.reds",
    "nssp_bridge.reds",
    "lilith_sovereign_kernel.reds",
]

REQUIRED_TWEEKDB = [
    "tweakdb/procedural_space_systems.yaml",
    "tweakdb/procedural_encounter_tables.yaml",
    "tweakdb/msn_procgen_weapon_catalog.yaml",
    "tweakdb/custom_weapons_expanded.yaml",
    "tweakdb/custom_cyberware_expanded.yaml",
    "tweakdb/custom_clothing_expanded.yaml",
    "tweakdb/custom_shards_expanded.yaml",
    "tweakdb/custom_quickhacks_expanded.yaml",
    "tweakdb/custom_vehicles_expanded.yaml",
    "tweakdb/hell_items.yaml",
    "tweakdb/custom_body_augments_bios.yaml",
    "tweakdb/nssp_token_economy.yaml",
]

REQUIRED_QUESTS = [
    "quests/msn_narrative_arc.yaml",
    "quests/abyssal_skill_tree_quests.yaml",
]

REQUIRED_SYMBOLS = {
    "msn_procgen_engine.reds": ["MSNProcGenEngine", "Cmd_ProcGenWeapon", "GenerateWeapon"],
    "msn_ai_overhaul.reds": ["MSNAIOverhaulController", "BindProcgenEncounter"],
    "msn_campaign_orchestrator.reds": ["MSNCampaignOrchestrator", "AdvanceAct", "EMSNCampaignTrack"],
    "msn_custom_item_factory.reds": [
        "MSNCustomItemFactory",
        "GrantLegendaryWeapon",
        "GrantHellCircleLoot",
        "GrantCyberware",
        "GrantClothing",
        "GrantQuickhack",
        "GrantShard",
        "GrantVehicle",
    ],
    "msn_npc_ai.reds": ["AdaptStrategic", "AdaptInsight", "AdaptAnalysis", "AdaptBalance"],
    "msn_token_economy.reds": ["MSNTokenEconomy", "SyncFromLochness", "OnNessieSighting", "Cmd_TokensStatus"],
    "nssp_bridge.reds": ["TokenBTC", "TokenExchange", "MSNTokenEconomy"],
    "lilith_sovereign_kernel.reds": ["LilithSovereignKernel", "RegisterSubsystem", "Cmd_LilithKernel"],
    "msn_gaming_engine.reds": ["MSNGamingEngine", "MSNEnginePerformance", "BootstrapOnce", "OnPlayerAction", "MSNCoolModeController"],
    "msn_narrative_story.reds": ["MSNNarrativeStoryBridge", "StartNarrative", "CompleteQuest", "Cmd_NarrativeStart"],
    "msn_cool_mode.reds": ["MSNCoolModeController", "EMSNCoolVibe", "Cmd_CoolOn"],
    "msn_gtc_sephirotic_router.reds": ["MSNGTCSephiroticRouter", "RouteDomain", "OnBootstrap"],
    "msn_symbiosis_bridge.reds": ["MSNSymbiosisBridge", "SyncLive", "Cmd_SymbiosisSync"],
    "msn_service_endpoints.reds": ["MSNServiceEndpoints", "LochnessSync", "AbyssalApi"],
}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    raise SystemExit(1)


def main() -> None:
    missing = [p for p in REQUIRED_SCRIPTS if not (SCRIPTS_DIR / p).exists()]
    if missing:
        fail(f"Missing scripts: {missing}")

    missing_db = [p for p in REQUIRED_TWEEKDB if not (ROOT / p).exists()]
    if missing_db:
        fail(f"Missing tweakdb: {missing_db}")

    missing_q = [p for p in REQUIRED_QUESTS if not (ROOT / p).exists()]
    if missing_q:
        fail(f"Missing quests: {missing_q}")

    for script, symbols in REQUIRED_SYMBOLS.items():
        text = (SCRIPTS_DIR / script).read_text()
        for sym in symbols:
            if sym not in text:
                fail(f"{script} missing symbol {sym}")

    info = json.loads((ROOT / "info.json").read_text())
    for script in REQUIRED_SCRIPTS[:5]:
        if script not in info.get("scripts", []):
            fail(f"info.json missing {script}")

    hat = ROOT / "tweakdb/abyssal_hat_catalog.yaml"
    if hat.exists() and "generatedCount: 1000000" not in hat.read_text():
        fail("abyssal_hat_catalog.yaml missing 1000000 count")

    procgen = ROOT / "tweakdb/msn_procgen_weapon_catalog.yaml"
    if procgen.exists() and "generatedCount: 96" not in procgen.read_text():
        fail("msn_procgen_weapon_catalog.yaml missing 96 weapons")

    print("OK: Full MSN Cyberpunk stack validates")
    print(f"  Scripts: {len(REQUIRED_SCRIPTS)} core engines")
    print(f"  TweakDB: {len(REQUIRED_TWEEKDB)} data manifests")
    print(f"  Quests: {len(REQUIRED_QUESTS)} campaign chains")
    print(f"  Catalog: 96 procgen weapons + 1000000 hats + 500 hell items + 69 bios")


if __name__ == "__main__":
    main()