#!/bin/bash
# Sync, validate, deploy, and compile the full MSN Cyberpunk mod stack.
set -euo pipefail

MOD_SOURCE="${MOD_SOURCE:-/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods}"
CP2077="${CP2077:-/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077}"
WOLVENKIT="${WOLVENKIT:-/home/tehlappy/.local/bin/wolvenkit/WolvenKit.CLI}"

echo "=== MSN Cyberpunk Full Stack Build ==="

cd "$MOD_SOURCE"

echo "[1/7] Lilith unify + script sync"
python3 tools/lilith_unify_cyberpunk.py

echo "[1b/7] Strip duplicate GTC sync hooks"
python3 tools/optimize_gtc_sync_mods.py

echo "[2/6] Validate stack"
python3 tools/validate_full_stack.py
python3 tools/validate_magic_jedi.py

echo "[3/6] Sync symbiosis live data"
cp -f data/symbiosis_coop_live.json "$MOD_SOURCE/data/symbiosis_coop_live.json" 2>/dev/null || true
if [ -f "/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods/data/symbiosis_coop_live.json" ]; then
  echo "  symbiosis data present"
fi

echo "[4/6] Deploy to game mods dir"
bash deploy_all_mods.sh

echo "[5/6] Write Cyberpunk PID for NGD bridge (if game running)"
pgrep -f "Cyberpunk2077.exe|Cyberpunk2077" 2>/dev/null | head -1 > /tmp/cyberpunk_pid.txt || echo "0" > /tmp/cyberpunk_pid.txt
mkdir -p "$HOME/.wine/drive_c/tmp" 2>/dev/null || true
cp /tmp/cyberpunk_pid.txt "$HOME/.wine/drive_c/tmp/cyberpunk_pid.txt" 2>/dev/null || true

echo "[6/6] WolvenKit compile (msn_integration)"
if [ -x "$WOLVENKIT" ]; then
  DOTNET_ROLL_FORWARD=Major "$WOLVENKIT" build "$MOD_SOURCE/msn_integration.cpmodproj" \
    2>&1 | tee output/full_stack_build.log || {
      echo "WARN: WolvenKit build failed — mods deployed as REDscript sources."
      echo "      Install REDmod + redscript in-game, or fix WolvenKit project."
      exit 0
    }
  echo "Build log: $MOD_SOURCE/output/full_stack_build.log"
else
  echo "WARN: WolvenKit not found at $WOLVENKIT"
  echo "      Mods deployed as source — enable REDmod in game launcher."
fi

echo "=== Full stack build complete ==="
echo "In-game console: msn.gtc.status | msn.symbiosis.sync | msn.tokens.sync"