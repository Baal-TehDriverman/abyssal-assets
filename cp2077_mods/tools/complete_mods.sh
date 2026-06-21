#!/bin/bash
# Complete MSN Cyberpunk mod stack — unify, validate, generate project, deploy, package.
set -euo pipefail

MOD_SOURCE="${MOD_SOURCE:-/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods}"
CP2077="${CP2077:-/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077}"
STAMP=$(date -u +%Y%m%d)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MSN CYBERPUNK — COMPLETE MOD STACK                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"

cd "$MOD_SOURCE"

echo "[1/10] Lilith unify"
python3 tools/lilith_unify_cyberpunk.py
python3 tools/dedupe_scripts_for_redmod.py

echo "[2/10] Sephirotic Court deploy (stamp all mod files)"
python3 tools/sephirotic_court_deploy.py

echo "[3/10] Optimize GTC sync shards"
python3 tools/optimize_gtc_sync_mods.py

echo "[4/10] Generate WolvenKit cpmodproj"
python3 tools/generate_cpmodproj.py

echo "[5/10] Validate"
python3 tools/validate_full_stack.py
python3 tools/validate_magic_jedi.py

echo "[6/10] Install frameworks (if needed)"
if [ ! -f "$CP2077/engine/tools/scc.exe" ]; then
  bash tools/install_frameworks.sh
else
  echo "  redscript/scc present"
fi

echo "[7/10] Deploy core mods"
bash deploy_all_mods.sh

echo "[8/10] Verify GTC shard mods"
GTC_COUNT=$(find "$CP2077/r6/mods" -maxdepth 1 -type d -name 'gtc_aethon_sync_*' | wc -l)
OPT_COUNT=$(rg -l 'PERF_OPTIMIZED' "$CP2077/r6/mods/gtc_aethon_sync_"*/scripts/*.reds 2>/dev/null | wc -l || echo 0)
echo "  GTC sync mods: $GTC_COUNT | optimized: $OPT_COUNT"

echo "[9/10] Working condition + test suite"
python3 tools/build_msn.py
python3 tools/build_completion_report.py
python3 tools/test_all_mods.py

echo "[10/10] Package release"
OUT="$MOD_SOURCE/output/msn_integration_complete_${STAMP}.tar.gz"
tar -czf "$OUT" \
  --exclude='.git' --exclude='output' --exclude='test_mod' --exclude='packed' \
  -C "$MOD_SOURCE" \
  info.json redmod.toml msn_tweakdb.toml msn_integration.cpmodproj \
  scripts tweakdb quests localization character data manifest tools/*.py tools/*.sh
echo "  Release: $OUT"

echo "✅ MSN mod stack complete"
echo "   Launch Cyberpunk with REDmod → first run compiles cache"
echo "   Console: msn.gtc.status | msn.engine.status | msn.gtc.shards"