# Wave 4 — Cyberpunk Telemetry Bridge
# Reads live telemetry from CP2077 + NGD stack

from agents import SubAgent, AgentManifest, register_agent
from pathlib import Path
import json

manifest = AgentManifest(
    id="cyberpunk",
    name="Cyberpunk Bridge",
    version="1.0.0",
    sephira="NETZACH",
    description="Live Cyberpunk 2077 telemetry — game status, GPU metrics, NGD routing, frame analysis, optimization recommendations",
    wave=4,
)

TELEMETRY_PATH = Path("/home/tehlappy/Desktop/AI/invite/runtime/cyberpunk_telemetry.json")
NGD_STATUS_PATH = Path("/home/tehlappy/Desktop/AI/invite/runtime/nvidia_gratitude_driver/status.json")


def _read_json(path):
    if path.exists():
        return json.loads(path.read_text())
    return None


class CyberpunkAgent(SubAgent):
    def _register_routes(self):
        super()._register_routes()

        @self.router.get("/status")
        async def cp_status():
            telemetry = _read_json(TELEMETRY_PATH)
            if telemetry:
                return telemetry
            return {"error": "Cyberpunk 2077 not running or telemetry unavailable"}

        @self.router.get("/gpu")
        async def gpu():
            ngd = _read_json(NGD_STATUS_PATH)
            if ngd:
                return ngd.get("sample", {})
            return {"error": "NGD not running"}

        @self.router.get("/route")
        async def route():
            ngd = _read_json(NGD_STATUS_PATH)
            if ngd:
                return {"route": ngd.get("route"), "reason": ngd.get("reason"), "cooldown_active": ngd.get("cooldown_active")}
            return {"error": "NGD not running"}

        @self.router.get("/fps")
        async def fps():
            t = _read_json(TELEMETRY_PATH)
            if t:
                cp = t.get("cyberpunk_telemetry", {})
                return {"fps": cp.get("fps"), "frame_time_ms": cp.get("frame_time_ms"), "dlss_mode": cp.get("dlss_mode")}
            return {"error": "Telemetry unavailable"}

        @self.router.get("/mods")
        async def mods():
            mods_path = Path("/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods")
            if mods_path.exists():
                mods = sorted(d.name for d in mods_path.iterdir() if d.is_dir())
                return {"mods": mods, "count": len(mods), "path": str(mods_path)}
            return {"mods": [], "deployed": False, "hint": "Check Proton compatdata path"}


agent = CyberpunkAgent(manifest)
register_agent(agent)
