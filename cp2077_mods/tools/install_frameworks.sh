#!/bin/bash
# Install redscript + RED4ext + TweakXL + ArchiveXL into Steam Cyberpunk install.
set -euo pipefail

CP2077="${CP2077:-/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077}"

if [ ! -d "$CP2077" ]; then
  echo "ERROR: Cyberpunk dir not found: $CP2077" >&2
  exit 1
fi

python3 - <<'PY'
import io, json, os, urllib.request, zipfile

CP_DIR = os.environ.get("CP2077", "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077")
MODS = [
    {"repo": "jac3km4/redscript", "match": ".zip", "skip": ["macos"]},
    {"repo": "WopsS/RED4ext", "match": ".zip", "skip": []},
    {"repo": "psiberx/cp2077-tweak-xl", "match": ".zip", "skip": []},
    {"repo": "psiberx/cp2077-archive-xl", "match": ".zip", "skip": []},
]

for mod in MODS:
    print(f"Fetching {mod['repo']}...")
    req = urllib.request.Request(f"https://api.github.com/repos/{mod['repo']}/releases/latest")
    req.add_header("User-Agent", "Mozilla/5.0")
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            data = json.loads(response.read().decode())
        assets = data.get("assets", [])
        asset_url = None
        for a in assets:
            name = a["name"].lower()
            if not a["name"].endswith(mod["match"]):
                continue
            if any(s in name for s in mod["skip"]):
                continue
            asset_url = a["browser_download_url"]
            break
        if not asset_url:
            print(f"  SKIP: no matching asset for {mod['repo']}")
            continue
        print(f"  Downloading {asset_url}")
        with urllib.request.urlopen(asset_url, timeout=120) as zresponse:
            with zipfile.ZipFile(io.BytesIO(zresponse.read())) as z:
                z.extractall(CP_DIR)
        print(f"  OK: {mod['repo']}")
    except Exception as e:
        print(f"  FAIL: {mod['repo']}: {e}")
PY

mkdir -p "$CP2077/r6/cache"
echo "Framework install complete. Cache dir ready at $CP2077/r6/cache"