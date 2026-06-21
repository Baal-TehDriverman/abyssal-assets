#!/bin/bash
# Deploy MSN / GTC mod sources to local Cyberpunk 2077 install.
set -euo pipefail

MOD_SOURCE="${MOD_SOURCE:-/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods}"
CP2077_MODS="${CP2077_MODS:-/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  GRAND THEFT CYBERPUNK — Six-Track Deploy                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"

if [ ! -d "$CP2077_MODS" ]; then
  echo "ERROR: Cyberpunk mods dir not found: $CP2077_MODS" >&2
  exit 1
fi

deploy_reds() {
  local target="$1"
  local dest="$CP2077_MODS/$target"
  mkdir -p "$dest/scripts"

  # Only deploy structured REDmod payload — never root-level *.reds (duplicate compile surface).
  rsync -a \
    --delete \
    --exclude='.git' --exclude='output' --exclude='packed' --exclude='test_mod' \
    --exclude='msn_magic_starwars_project' \
    "$MOD_SOURCE/scripts/" "$dest/scripts/"
  rsync -a \
    --delete \
    "$MOD_SOURCE/tweakdb/" "$dest/tweakdb/" 2>/dev/null || true
  rsync -a \
    --delete \
    "$MOD_SOURCE/quests/" "$dest/quests/" 2>/dev/null || true
  rsync -a \
    --delete \
    "$MOD_SOURCE/localization/" "$dest/localization/" 2>/dev/null || true
  rsync -a \
    --delete \
    "$MOD_SOURCE/data/" "$dest/data/" 2>/dev/null || true

  for f in info.json redmod.toml msn_integration.toml msn_tweakdb.toml msn_integration.cpmodproj ngd_rnn_optimization.redmod.toml; do
    if [ -f "$MOD_SOURCE/$f" ]; then
      cp -f "$MOD_SOURCE/$f" "$dest/$f"
    fi
  done

  # Purge legacy root-level .reds that cause REDmod redefinition errors.
  find "$dest" -maxdepth 1 -name '*.reds' -delete 2>/dev/null || true

  echo "✓ $target"
}

deploy_reds "msn_integration"
deploy_reds "lyra_dialogue"

# Hell campaign standalone bundle
mkdir -p "$CP2077_MODS/abyssal_assets/scripts"
rsync -a "$MOD_SOURCE/scripts/msn_hell_campaign.reds" "$CP2077_MODS/abyssal_assets/scripts/"
rsync -a "$MOD_SOURCE/scripts/livingsin_hell_integration.reds" "$CP2077_MODS/abyssal_assets/scripts/"
rsync -a "$MOD_SOURCE/scripts/livingsin_time_blade.reds" "$CP2077_MODS/abyssal_assets/scripts/"

python3 "$MOD_SOURCE/tools/validate_magic_jedi.py"

cat > "$CP2077_MODS/gtc_mods_deployed.json" <<EOF
{
  "schema": "gtc.mods_deployed.v4",
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deploy_path": "$CP2077_MODS",
  "tracks": ["dialogue", "hell_campaign", "magic_starwars", "living_sin", "ngd", "hub"],
  "mods": {
    "msn_integration": { "enabled": true, "type": "core" },
    "lyra_dialogue": { "enabled": true, "type": "dialogue" },
    "abyssal_assets": { "enabled": true, "type": "hell_campaign" }
  }
}
EOF

echo "✅ Deploy complete → $CP2077_MODS"
echo "   Console: msn.gtc.status | msn.dialogue.lilith | msn.ngd.optimize"