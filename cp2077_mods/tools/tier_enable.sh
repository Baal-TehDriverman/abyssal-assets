#!/usr/bin/env bash
# Enable Tier 3 packs or GTC Aethon shard ranges (1-100)
set -euo pipefail

if [[ -d "$HOME/.steam/steam/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="$HOME/.steam/steam/steamapps/common/Cyberpunk 2077"
elif [[ -d "/mnt/d/Games/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="/mnt/d/Games/steamapps/common/Cyberpunk 2077"
else
  echo "CP2077 not found" >&2; exit 1
fi
GAME_MODS="$CP2077/r6/mods"
MODE="${1:-tier3}"

enable_gtc_shard() {
  local num="$1"
  local padded
  padded=$(printf '%03d' "$num")
  local src dst match
  for src in "$GAME_MODS"/_disabled_gtc_aethon_sync_"${padded}"*; do
    [[ -e "$src" ]] || continue
    dst="${src/#\/_disabled_/}"
    mv "$src" "$dst"
    echo "Enabled $(basename "$dst")"
    return 0
  done
  if compgen -G "$GAME_MODS/gtc_aethon_sync_${padded}_*" > /dev/null; then
    echo "Already active: gtc_aethon_sync_${padded}_*"
    return 0
  fi
  echo "Missing shard $padded" >&2
  return 1
}

case "$MODE" in
  tier3)
    for d in abyssal_assets lyra_dialogue; do
      if [[ -d "$GAME_MODS/_disabled_$d" ]]; then
        mv "$GAME_MODS/_disabled_$d" "$GAME_MODS/$d"
        echo "Enabled $d"
      elif [[ -d "$GAME_MODS/$d" ]]; then
        echo "Already active: $d"
      fi
    done
    ;;
  gtc)
    BATCH="${2:-10}"
    START="${3:-1}"
    END=$((START + BATCH - 1))
    for i in $(seq "$START" "$END"); do
      enable_gtc_shard "$i" || true
    done
    ;;
  gtc-all|1-100|range)
    START="${2:-1}"
    END="${3:-100}"
    [[ "$MODE" == "1-100" ]] && START=1 && END=100
    for i in $(seq "$START" "$END"); do
      enable_gtc_shard "$i" || true
    done
    ;;
  status)
    echo -n "GTC shards active: "
    ls -d "$GAME_MODS"/gtc_aethon_sync_* 2>/dev/null | wc -l
    echo -n "GTC shards disabled: "
    ls -d "$GAME_MODS"/_disabled_gtc_aethon_sync_* 2>/dev/null | wc -l || echo 0
    ;;
  *)
    echo "Usage:"
    echo "  tier_enable.sh tier3"
    echo "  tier_enable.sh gtc [batch_size] [start_index]"
    echo "  tier_enable.sh gtc-all [start] [end]   # default 1-100"
    echo "  tier_enable.sh 1-100"
    echo "  tier_enable.sh status"
    exit 1
    ;;
esac

rm -rf "$CP2077/r6/cache/"* 2>/dev/null || true
echo "Cache purged — relaunch game to recompile"