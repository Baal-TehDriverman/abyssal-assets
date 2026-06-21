#!/usr/bin/env python3
"""Run full MSN Cyberpunk mod test suite — deploy, validate, APIs, tracks."""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOYED = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration")
GAME_MODS = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods")
GAME = Path("/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077")
CACHE = GAME / "r6/cache"
OUT = ROOT / "output" / "mod_test_results.json"

TRACKS = {
    "core_msn": ["lilith_sovereign_kernel.reds", "msn_master_integration.reds", "msn_grand_theft_cyberpunk_hub.reds"],
    "gaming_engine": [
        "msn_gaming_engine.reds",
        "msn_gtc_sephirotic_router.reds",
        "msn_sephirotic_court_binder.reds",
    ],
    "sephirotic_court": ["msn_sephirotic_npcs.reds", "msn_sephirotic_quests.reds"],
    "ngd": ["cyberpunk_ngd_bridge.reds", "cyberpunk_ngd_integration.reds"],
    "dialogue": ["msn_api_dialogue_bridge.reds", "msn_lyra_dialogue.reds", "lilith_npc.reds"],
    "token_economy": ["msn_token_economy.reds", "nssp_bridge.reds"],
    "hell": ["msn_hell_campaign.reds", "hell_circle_quests.reds", "livingsin_hell_integration.reds"],
    "magic_jedi_sw": ["magic/msn_magic_system.reds", "jedi/msn_jedi_system.reds", "starwars/msn_starwars_system.reds"],
    "procgen_ai": ["msn_procgen_engine.reds", "msn_ai_overhaul.reds", "msn_npc_ai.reds"],
    "restored": ["msn_wanted_level.reds", "msn_crypto_wallet.reds", "msn_freighter_business.reds"],
    "ui": ["ui/corruption_hud.reds", "ui/lightsaber_vfx.reds"],
}

CONSOLE_COMMANDS = [
    "msn.cool.on", "msn.cool.status", "msn.cool.vibe", "msn.cool.pulse",
    "msn.gtc.status", "msn.engine.status", "msn.engine.perf", "msn.gtc.shards",
    "msn.court.status", "msn.court.route",
    "msn.skill.trees", "msn.skill.status", "abyssal.skills.trees",
    "msn.symbiosis.sync", "msn.tokens.sync", "msn.tokens.status",
    "msn.dialogue.lilith", "msn.ngd.status", "msn.ngd.optimize",
    "msn.magic.status", "msn.jedi.status", "msn.starwars.status",
    "lilith.kernel",
]

API_TESTS = [
    {"name": "lilith_health", "url": "http://localhost:3210/health", "expect_codes": [200]},
    {"name": "lyra_state", "url": "http://localhost:3211/lyra/state", "expect_codes": [200, 404]},
    {"name": "antigravity_health", "url": "http://localhost:8002/health", "expect_codes": [200]},
    {"name": "abyssal_api", "url": "http://localhost:8008/health", "expect_codes": [200]},
    {"name": "lilith_fastapi", "url": "http://localhost:3213/health", "expect_codes": [200]},
    {"name": "msn_router", "url": "http://localhost:8007/", "expect_codes": [200, 404]},
    {"name": "gtc_bridge_health", "url": "http://localhost:8766/health", "expect_codes": [200]},
    {"name": "gtc_bridge_symbiosis", "url": "http://localhost:8766/symbiosis", "expect_codes": [200]},
]


def run_py(script: str) -> dict:
    path = ROOT / "tools" / script
    try:
        res = subprocess.run(
            [sys.executable, str(path)],
            capture_output=True, text=True, timeout=120, cwd=str(ROOT),
        )
        return {"ok": res.returncode == 0, "code": res.returncode, "out": (res.stdout or res.stderr)[-800:]}
    except Exception as exc:
        return {"ok": False, "error": str(exc)}


def http_get(url: str, timeout: int = 5) -> dict:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "msn-mod-test/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read(4096).decode("utf-8", errors="replace")
            return {"ok": True, "code": resp.status, "body": body[:500]}
    except urllib.error.HTTPError as exc:
        return {"ok": exc.code in (200, 404), "code": exc.code, "body": ""}
    except Exception as exc:
        return {"ok": False, "code": 0, "error": str(exc)}


def http_post(url: str, payload: dict, headers: dict | None = None) -> dict:
    hdrs = {"Content-Type": "application/json", "User-Agent": "msn-mod-test/1.0"}
    if headers:
        hdrs.update(headers)
    try:
        req = urllib.request.Request(
            url, data=json.dumps(payload).encode(), headers=hdrs, method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return {"ok": True, "code": resp.status, "body": resp.read(1024).decode()[:300]}
    except urllib.error.HTTPError as exc:
        return {"ok": exc.code < 500, "code": exc.code, "body": exc.read(300).decode() if exc.fp else ""}
    except Exception as exc:
        return {"ok": False, "code": 0, "error": str(exc)}


def test_tracks() -> dict:
    scripts = DEPLOYED / "scripts"
    results = {}
    for track, files in TRACKS.items():
        missing = [f for f in files if not (scripts / f).exists()]
        results[track] = {"ok": len(missing) == 0, "missing": missing, "files": len(files)}
    return results


def test_console_commands() -> dict:
    toml = (DEPLOYED / "redmod.toml").read_text(encoding="utf-8", errors="ignore")
    found = [c for c in CONSOLE_COMMANDS if c in toml]
    missing = [c for c in CONSOLE_COMMANDS if c not in toml]
    return {"ok": len(missing) <= 2, "found": found, "missing": missing}


def test_sephirotic_court() -> dict:
    registry = ROOT / "output" / "sephirotic_court_registry.json"
    binder = ROOT / "scripts" / "msn_sephirotic_court_binder.reds"
    if not registry.exists() or not binder.exists():
        return {"ok": False, "error": "court registry or binder missing"}
    data = json.loads(registry.read_text(encoding="utf-8"))
    total = data.get("total_files", 0)
    counts = data.get("sephira_counts", {})
    sealed = sum(1 for e in data.get("files", []) if e.get("scope") == "source")
    return {
        "ok": total >= 200 and len(counts) == 10 and binder.stat().st_size > 200,
        "total_files": total,
        "source_files": sealed,
        "sephira_counts": counts,
    }


def test_gtc_shards() -> dict:
    total = len(list(GAME_MODS.glob("gtc_aethon_sync_*")))
    bad_hooks = 0
    optimized = 0
    for p in GAME_MODS.glob("gtc_aethon_sync_*/scripts/*.reds"):
        text = p.read_text(encoding="utf-8", errors="ignore")
        if "@wrapMethod" in text:
            bad_hooks += 1
        if "PERF_OPTIMIZED" in text:
            optimized += 1
    return {
        "ok": total >= 100 and bad_hooks == 0 and optimized >= 100,
        "total": total, "optimized": optimized, "duplicate_hooks": bad_hooks,
    }


def test_reds_symbols() -> dict:
    checks = {
        "MSNGamingEngine": "msn_gaming_engine.reds",
        "MSNGTCSephiroticRouter": "msn_gtc_sephirotic_router.reds",
        "MSNGrandTheftCyberpunkHub": "msn_grand_theft_cyberpunk_hub.reds",
        "MSNSymbiosisBridge": "msn_symbiosis_bridge.reds",
        "MSNTokenEconomy": "msn_token_economy.reds",
        "LilithSovereignKernel": "lilith_sovereign_kernel.reds",
        "SephiroticCourtBinder": "msn_sephirotic_court_binder.reds",
        "MSNSephiroticCourt": "msn_sephirotic_npcs.reds",
    }
    scripts = DEPLOYED / "scripts"
    missing = []
    for sym, fname in checks.items():
        path = scripts / fname
        if not path.exists() or sym not in path.read_text(encoding="utf-8", errors="ignore"):
            missing.append(sym)
    return {"ok": len(missing) == 0, "missing_symbols": missing}


def test_ingest_bridge() -> dict:
    payload = {
        "source": "mod_test_suite",
        "project_id": "lilith_systems_llc",
        "data": {"test": "mod_integration", "ts": time.time()},
        "convergence_score": 0.9,
    }
    return http_post("http://localhost:8002/ingest/antigravity", payload, {"X-Token": "devtoken"})


def test_compile_ready() -> dict:
    has_scc = (GAME / "engine/tools/scc.exe").exists()
    compiled = (CACHE / "final.redscripts").exists() or (CACHE / "modded/final.redscripts").exists()
    log_dir = GAME / "r6/logs"
    redscript_logs = list(log_dir.glob("*redscript*")) if log_dir.exists() else []
    return {
        "ok": has_scc,
        "scc_installed": has_scc,
        "cache_compiled": compiled,
        "redscript_logs": [p.name for p in redscript_logs[:5]],
        "needs_game_launch": not compiled,
    }


def main() -> int:
    started = datetime.now(timezone.utc).isoformat()
    print("=== MSN Cyberpunk Mod Test Suite ===\n")

    results: dict = {"started": started, "tests": {}, "passed": 0, "failed": 0, "skipped": 0}

    def record(name: str, data: dict) -> None:
        results["tests"][name] = data
        status = "PASS" if data.get("ok") else "FAIL"
        if data.get("skipped"):
            status = "SKIP"
        print(f"  [{status}] {name}")
        if status == "PASS":
            results["passed"] += 1
        elif status == "SKIP":
            results["skipped"] += 1
        else:
            results["failed"] += 1
            if data.get("error"):
                print(f"         error: {data['error']}")
            if data.get("missing"):
                print(f"         missing: {data['missing']}")

    print("[1] Validator scripts")
    record("validate_full_stack", run_py("validate_full_stack.py"))
    record("validate_magic_jedi", run_py("validate_magic_jedi.py"))
    record("build_msn", run_py("build_msn.py"))

    print("\n[2] Deployed mod tracks")
    tracks = test_tracks()
    tracks_ok = all(v.get("ok") for v in tracks.values())
    record("mod_tracks", {"ok": tracks_ok, "tracks": tracks})

    print("\n[3] Console commands")
    record("console_commands", test_console_commands())

    print("\n[4] Sephirotic Court deployment")
    record("sephirotic_court", test_sephirotic_court())

    print("\n[5] GTC Aethon shards")
    record("gtc_shards", test_gtc_shards())

    print("\n[6] REDscript symbols")
    record("reds_symbols", test_reds_symbols())

    print("\n[7] MSN API connectivity")
    for spec in API_TESTS:
        r = http_get(spec["url"])
        r["ok"] = r.get("code", 0) in spec["expect_codes"]
        record(f"api_{spec['name']}", r)

    print("\n[8] Integration bridges")
    record("antigravity_ingest", test_ingest_bridge())
    sym = http_get("http://localhost:8008/api/lochness/status")
    sym["ok"] = sym.get("ok") or sym.get("code") in (200, 404)
    record("lochness_api", sym)

    print("\n[9] Compile readiness")
    record("compile_ready", test_compile_ready())

    results["finished"] = datetime.now(timezone.utc).isoformat()
    results["summary"] = {
        "total": results["passed"] + results["failed"] + results["skipped"],
        "passed": results["passed"],
        "failed": results["failed"],
        "ready_for_ingame": results["failed"] == 0,
        "ingame_step": "Launch Cyberpunk with REDmod → run console_verify commands",
    }
    results["console_verify"] = [
        "msn.gtc.status", "msn.engine.status", "msn.gtc.shards",
        "msn.symbiosis.sync", "msn.tokens.sync", "msn.dialogue.lilith test",
        "msn.court.status", "msn.court.route Keter",
    ]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(results, indent=2))
    print(f"\n=== Results: {results['passed']} passed, {results['failed']} failed ===")
    print(f"Report: {OUT}")
    return 0 if results["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())