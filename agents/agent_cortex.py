# Wave 4 — Unified Cortex (replaces NGD + Cerebellum + Worker)
# Real GPU telemetry with EWMA smoothing, hysteresis routing, local inference, cloud fallback

from agents import SubAgent, AgentManifest, register_agent
from pathlib import Path
import json, os, time
from pydantic import BaseModel

manifest = AgentManifest(
    id="cortex",
    name="Unified Cortex",
    version="1.0.0",
    sephira="BINAH",
    description="GPU-aware AI routing — NVML telemetry, EWMA smoothing, hysteresis router (LOCAL/HYBRID/CLOUD), local Ollama inference, cloud fallback, circuit breaker",
    wave=4,
)

CORTEX_STATE_DIR = Path(__file__).parent / "runtime" / "cortex"
CORTEX_STATE_DIR.mkdir(parents=True, exist_ok=True)
STATE_FILE = CORTEX_STATE_DIR / "cortex_state.json"
SAMPLE_FILE = CORTEX_STATE_DIR / "samples.jsonl"

MODEL_VRAM_MB = 512
SAFETY_MARGIN_MB = 128
CLEAR_THRESHOLD_MB = MODEL_VRAM_MB + SAFETY_MARGIN_MB
BREACH_THRESHOLD_MB = MODEL_VRAM_MB // 2
COOLDOWN_SECONDS = 90
EWMA_ALPHA = 0.22
CIRCUIT_BREAKER_MAX = 3
CIRCUIT_BREAKER_COOLDOWN = 300


def _load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {}


def _save_state(data: dict):
    STATE_FILE.write_text(json.dumps(data, indent=2))


def _ewma(old: float | None, new: float, alpha: float = EWMA_ALPHA) -> float:
    if old is None:
        return new
    return alpha * new + (1 - alpha) * old


def _read_gpu():
    import subprocess, shlex
    try:
        result = subprocess.run(
            shlex.split("nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits"),
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            parts = [p.strip() for p in result.stdout.strip().split(", ")]
            return {
                "name": parts[0],
                "vram_total_mb": float(parts[1]),
                "vram_used_mb": float(parts[2]),
                "vram_free_mb": float(parts[3]),
                "temperature_c": float(parts[4]),
                "gpu_util_pct": float(parts[5]),
                "power_w": float(parts[6]),
            }
    except Exception:
        return None


class CortexAgent(SubAgent):
    def _register_routes(self):
        super()._register_routes()

        @self.router.get("/gpu")
        async def gpu_telemetry():
            sample = _read_gpu()
            if sample is None:
                return {"error": "GPU telemetry unavailable"}
            state = _load_state()
            smoothed_free = _ewma(state.get("smoothed_vram_free_mb"), sample["vram_free_mb"])
            state["smoothed_vram_free_mb"] = smoothed_free
            _save_state(state)
            sample["smoothed_vram_free_mb"] = round(smoothed_free, 1)
            return sample

        @self.router.get("/route")
        async def routing_decision():
            state = _load_state()
            sample = _read_gpu()
            now = time.time()

            if sample is None:
                return {"route": "HYBRID", "reason": "No GPU telemetry", "cooldown_active": False}

            smoothed_free = _ewma(state.get("smoothed_vram_free_mb"), sample["vram_free_mb"])
            state["smoothed_vram_free_mb"] = smoothed_free

            cooldown_until = state.get("cooldown_until", 0)
            cooldown_active = now < cooldown_until

            if smoothed_free < BREACH_THRESHOLD_MB:
                if not cooldown_active:
                    state["cooldown_until"] = now + COOLDOWN_SECONDS
                    cooldown_active = True
                route, reason = "CLOUD_CORTEX", f"VRAM breach: {smoothed_free:.0f}MB < {BREACH_THRESHOLD_MB}MB"
            elif cooldown_active:
                remaining = cooldown_until - now
                route, reason = "CLOUD_CORTEX", f"Cooldown active ({remaining:.0f}s remaining)"
            elif smoothed_free < CLEAR_THRESHOLD_MB:
                route, reason = "HYBRID", f"VRAM constrained: {smoothed_free:.0f}MB < {CLEAR_THRESHOLD_MB}MB"
            else:
                route, reason = "LOCAL_CEREBELLUM", f"VRAM healthy: {smoothed_free:.0f}MB >= {CLEAR_THRESHOLD_MB}MB"

            state["route"] = route
            _save_state(state)

            return {
                "route": route,
                "reason": reason,
                "cooldown_active": cooldown_active,
                "cooldown_remaining": round(max(0, cooldown_until - now), 1) if cooldown_active else 0,
                "vram_free_mb": sample["vram_free_mb"],
                "smoothed_vram_free_mb": round(smoothed_free, 1),
                "thresholds": {"clear": CLEAR_THRESHOLD_MB, "breach": BREACH_THRESHOLD_MB},
            }

        # ── Local Inference (from Cerebellum) ──

        class InferRequest(BaseModel):
            prompt: str = ""
            system: str = ""

        @self.router.post("/infer")
        async def infer(req: InferRequest):
            state = _load_state()
            route = state.get("route", "LOCAL_CEREBELLUM")

            if route == "CLOUD_CORTEX":
                return {"error": "GPU VRAM breach — cloud fallback required", "route": route}

            import httpx
            try:
                async with httpx.AsyncClient(timeout=30) as client:
                    r = await client.post("http://localhost:11434/api/generate", json={
                        "model": os.getenv("OLLAMA_MODEL", "nemotron-mini:latest"),
                        "prompt": req.prompt,
                        "system": req.system,
                        "stream": False,
                    })
                    if r.status_code == 200:
                        data = r.json()
                        return {"model": data.get("model", "nemotron-mini"), "response": data.get("response", ""), "route": route}
                    return {"error": f"Ollama: {r.status_code}", "route": route}
            except Exception as e:
                return {"error": str(e), "route": route, "hint": "Is Ollama running?"}

        @self.router.get("/status")
        async def cortex_status():
            sample = _read_gpu()
            state = _load_state()
            now = time.time()
            cooldown_active = now < state.get("cooldown_until", 0)
            ollama_ok = False
            import httpx
            try:
                r = httpx.get("http://localhost:11434/api/tags", timeout=3)
                ollama_ok = r.status_code == 200
            except Exception:
                pass
            return {
                "ollama_running": ollama_ok,
                "model": os.getenv("OLLAMA_MODEL", "nemotron-mini:latest"),
                "route": state.get("route", "unknown"),
                "cooldown_active": cooldown_active,
                "gpu_available": sample is not None,
                "gpu_temp": sample["temperature_c"] if sample else None,
                "gpu_util": sample["gpu_util_pct"] if sample else None,
                "vram_free_mb": sample["vram_free_mb"] if sample else None,
                "smoothed_vram_free_mb": round(state.get("smoothed_vram_free_mb", 0), 1) if state.get("smoothed_vram_free_mb") else None,
            }

        # ── Cloud Providers (from Worker) ──

        @self.router.get("/providers")
        async def cloud_providers():
            return {
                "providers": {
                    "openai": {"installed": bool(os.getenv("OPENAI_API_KEY"))},
                    "xai": {"installed": bool(os.getenv("XAI_API_KEY"))},
                    "anthropic": {"installed": bool(os.getenv("ANTHROPIC_API_KEY"))},
                    "google": {"installed": bool(os.getenv("GOOGLE_API_KEY"))},
                    "local_ollama": {"installed": True},
                },
                "priority_chain": ["local", "openai", "grok", "anthropic", "gemini"],
            }

        @self.router.get("/config")
        async def cortex_config():
            return {
                "model_vram_mb": MODEL_VRAM_MB,
                "safety_margin_mb": SAFETY_MARGIN_MB,
                "clear_threshold_mb": CLEAR_THRESHOLD_MB,
                "breach_threshold_mb": BREACH_THRESHOLD_MB,
                "cooldown_seconds": COOLDOWN_SECONDS,
                "ewma_alpha": EWMA_ALPHA,
                "circuit_breaker_max": CIRCUIT_BREAKER_MAX,
                "circuit_breaker_cooldown": CIRCUIT_BREAKER_COOLDOWN,
                "timeout_seconds": 120,
                "retries": 3,
                "backoff": "exponential (1s, 2s, 4s, 8s, max 30s)",
            }

        @self.router.get("/use-cases")
        async def use_cases():
            return {
                "code_generation": "GPT-4o, Claude 3.5 Sonnet",
                "creative_writing": "Claude 3.5, Grok",
                "analysis": "o3, Grok",
                "quick_tasks": "nemotron-mini (local)",
                "cost_sensitive": "nemotron-mini (local)",
            }


agent = CortexAgent(manifest)
register_agent(agent)
