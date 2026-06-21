#!/usr/bin/env bash
set -euo pipefail
CP2077="${CP2077:-/mnt/d/Games/steamapps/common/Cyberpunk 2077}"
MSN="$CP2077/r6/mods/msn_integration"
echo "=== MSN Launch Verify ==="
echo "scripts: $(find "$MSN/scripts" -name '*.reds' 2>/dev/null | wc -l) (expect 91)"
echo "root reds: $(find "$MSN" -maxdepth 1 -name '*.reds' 2>/dev/null | wc -l) (expect 0)"
echo "stale starwars: $(test -d "$MSN/msn_magic_starwars_project" && echo PRESENT || echo absent)"
echo "cache: $(test -f "$CP2077/r6/cache/final.redscripts" && echo COMPILED || echo MISSING)"
if [ -f "$CP2077/r6/logs/redscript_rCURRENT.log" ]; then
  echo "--- redscript log (last 20 lines) ---"
  tail -20 "$CP2077/r6/logs/redscript_rCURRENT.log"
fi
curl -sf http://localhost:8007/api/cerebellum/status 2>/dev/null | head -c 300 || echo "MSN Router :8007 down"
echo ""