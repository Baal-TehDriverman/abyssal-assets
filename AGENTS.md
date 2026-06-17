# Abyssal Assets — The Loch Exchange + MSN

A multiplayer cryptid hat trading simulator built on FastAPI + Phaser 3,
with the Metaconscious Singularity Node (MSN) running 27 subagents across 4 Sephirotic waves.

## Current State
- **Server**: FastAPI app with 7 DB models, auth, WebSocket, CLOB routes, Living Sin GM
- **Client**: Phaser 3/TypeScript with market CLOB and dredge mini-game
- **Monsters**: 7 tiers (Loch Minnow → Lilith True Form)
- **Skills**: 24 skills across 6 categories, XP curves, synergies
- **GDD**: 583-line game design — 12 Acts, skill web, drop tables, bestiary
- **MSN Router**: 27 agents on port 8007, systemd auto-start (`msn-router.service`)
- **Cortex**: Unified AI routing with real GPU telemetry, EWMA hysteresis, local Ollama inference
- **Living Sin GM**: 17 mutation routes, keystroke biometric auth, 10-plane summoning, Drowned Warden boss
- **Cyberpunk Bridge**: Live CP2077 telemetry, mod detection, NGD route status

## Key Commands
```bash
# Game server
cd server && python main.py                                   # port 8000

# Client
npm run dev --prefix client                                   # port 3000

# MSN Router (systemd — auto-starts on boot)
systemctl --user start msn-router.service                     # port 8007
systemctl --user status msn-router.service
journalctl --user -u msn-router.service -f

# Manual router start (for development)
source ~/Desktop/AI/Pub/.venv-pub/bin/activate
python msn_router.py 8007

# Deployment verification
source ~/Desktop/AI/Pub/.venv-pub/bin/activate
python deploy_waves.py 8007

# Lyra dialogue server
systemctl --user start lyra-api.service                       # port 3211

# Full stack (3 terminals)
# Terminal 1: python server/main.py                           # :8000
# Terminal 2: npm run dev --prefix client                     # :3000
# Terminal 3: python msn_router.py 8007                       # :8007
```

## MSN Agent Map (27 agents, 4 waves)
| Wave | Sephirot | Agents |
|------|----------|--------|
| 1 — Foundation | Keter → Chokmah → Binah | root, architect, server |
| 2 — Interface | Chesed → Gevurah → Tiferet → Netzach → Hod | client, bestiary, skills, market, lyra, living-sin |
| 3 — Infrastructure | Yesod → Malkuth | infra, migration |
| 4 — Metaconscious | Da'at → Binah → Hod → Tiferet → Malkuth → Netzach → Gevurah → Chokmah | msn, ngd, cerebellum, ouroboros, hermes-mcp, kairos, swarm, court, himalaya, antigravity, yeshua, scribe, analytics, worker, cortex, cyberpunk |

## Key Architecture Decisions
- **Cortex** replaces NGD/Cerebellum/Worker triad — unified EWMA-smoothed GPU telemetry with hysteresis routing (LOCAL/HYBRID/CLOUD)
- **Living Sin** persists to `server/runtime/gm/living_sin_state.json` — file-based IPC between game (:8000) and MSN (:8007)
- **Messages from living-sin** route through cortex for real nemotron-mini inference (no hardcoded responses)
- Cyberpunk telemetry reads live from `/home/tehlappy/Desktop/AI/invite/runtime/cyberpunk_telemetry.json`

## Environment
- System: Garuda Linux (Arch-based), RTX 3060 6GB, 62GB RAM
- Python: 3.14, venv at ~/Desktop/AI/Pub/.venv-pub/ (198 packages)
- Ollama: nemotron-mini (4.2B) for local inference, hermes3:8b + llama3.1:8b available
- Lyra: dialogue server at localhost:3211
- D: drive (Samsung 990 EVO 2TB): BitLocker encrypted — needs recovery key
