#!/usr/bin/env bash
# Phase D — Tier 1 compile prep: purge cache, disable non-core mods
set -euo pipefail

MOD_SOURCE="${MOD_SOURCE:-/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods}"
if [[ -d "$HOME/.steam/steam/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="$HOME/.steam/steam/steamapps/common/Cyberpunk 2077"
elif [[ -d "/mnt/d/Games/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="/mnt/d/Games/steamapps/common/Cyberpunk 2077"
else
  echo "CP2077 install not found" >&2
  exit 1
fi

COUNT=$(rg '^\s+".*\.reds"' "$MOD_SOURCE/redmod.toml" -c --no-heading 2>/dev/null || echo 0)
if [[ "$COUNT" -lt 90 ]]; then
  echo "ABORT: manifest has only $COUNT scripts" >&2
  exit 1
fi
echo "Manifest OK: $COUNT scripts"

rm -rf "$CP2077/r6/cache/"*
rm -f "$CP2077/r6/logs/redscript_rCURRENT.log"
echo "Cache purged"

GAME_MODS="$CP2077/r6/mods"
for d in gtc_aethon_sync_* gta_mods gtc_unified gtc_total_rebuild YoloModeEngaged abyssal_assets lyra_dialogue; do
  if [[ -d "$GAME_MODS/$d" && ! "$d" =~ ^_disabled ]]; then
    mv "$GAME_MODS/$d" "$GAME_MODS/_disabled_$d" 2>/dev/null || true
    echo "Disabled: $d"
  fi
done

echo "Tier 1 ready — launch Cyberpunk with REDmod enabled"
echo "Monitor: tail -f $CP2077/r6/logs/redscript_rCURRENT.log"