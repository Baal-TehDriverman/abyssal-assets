#!/usr/bin/env bash
# Safe deploy — validates manifest, skips dedupe, deploys + tests.
set -euo pipefail

MOD_SOURCE="${MOD_SOURCE:-/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods}"
cd "$MOD_SOURCE"

COUNT=$(rg '^\s+".*\.reds"' redmod.toml -c --no-heading 2>/dev/null || true)
COUNT=${COUNT:-0}
if [[ "$COUNT" -lt 90 ]]; then
  echo "ABORT: redmod.toml has only $COUNT scripts — dedupe/manifest corrupt" >&2
  exit 1
fi
echo "Manifest OK: $COUNT scripts"

python3 tools/validate_full_stack.py
python3 tools/validate_magic_jedi.py
bash deploy_all_mods.sh
python3 tools/test_all_mods.py

if [[ -d "$HOME/.steam/steam/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="$HOME/.steam/steam/steamapps/common/Cyberpunk 2077"
elif [[ -d "/mnt/d/Games/steamapps/common/Cyberpunk 2077/r6" ]]; then
  export CP2077="/mnt/d/Games/steamapps/common/Cyberpunk 2077"
fi
if [[ -n "${CP2077:-}" ]]; then
  bash tools/launch_verify.sh
fi

echo "Safe deploy complete — dedupe SKIPPED"