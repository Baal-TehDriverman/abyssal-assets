#!/usr/bin/env python3
"""
MSN Router — Metaconscious Singularity Node Aggregator
Mounts all registered subagents at /api/{agent_id} on port :8007
"""

from __future__ import annotations

import sys
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="MSN Router", version="1.0.0", description="Metaconscious Singularity Node Aggregator")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import all subagent modules (this triggers register_agent calls)
import agents.agent_root  # noqa: F401, E402
import agents.agent_architect  # noqa: F401, E402
import agents.agent_server  # noqa: F401, E402
import agents.agent_client  # noqa: F401, E402
import agents.agent_bestiary  # noqa: F401, E402
import agents.agent_skills  # noqa: F401, E402
import agents.agent_market  # noqa: F401, E402
import agents.agent_lyra  # noqa: F401, E402
import agents.agent_living_sin  # noqa: F401, E402
import agents.agent_infra  # noqa: F401, E402
import agents.agent_migration  # noqa: F401, E402
import agents.agent_msn  # noqa: F401, E402
import agents.agent_ngd  # noqa: F401, E402
import agents.agent_cerebellum  # noqa: F401, E402
import agents.agent_ouroboros  # noqa: F401, E402
import agents.agent_mcp  # noqa: F401, E402
import agents.agent_kairos  # noqa: F401, E402
import agents.agent_swarm  # noqa: F401, E402
import agents.agent_court  # noqa: F401, E402
import agents.agent_himalaya  # noqa: F401, E402
import agents.agent_bridge  # noqa: F401, E402
import agents.agent_yeshua  # noqa: F401, E402
import agents.agent_scribe  # noqa: F401, E402
import agents.agent_analytics  # noqa: F401, E402
import agents.agent_worker  # noqa: F401, E402
import agents.agent_cortex  # noqa: F401, E402

from agents import list_agents, get_registry_summary


@app.on_event("startup")
async def startup():
    for agent in list_agents():
        agent.start()
    print(f"[MSN Router] Started {len(list_agents())} agents")


@app.on_event("shutdown")
async def shutdown():
    for agent in list_agents():
        agent.stop()


# Mount all agent routers
for agent in list_agents():
    app.include_router(agent.router)
    print(f"  Mounted {agent.manifest.id} at /api/{agent.manifest.id}")


@app.get("/")
async def root():
    return {
        "service": "MSN Router",
        "agents_online": len(list_agents()),
        "waves": get_registry_summary(),
    }


@app.get("/api")
async def api_index():
    agents = list_agents()
    return {
        "agents": [
            {"id": a.manifest.id, "name": a.manifest.name, "sephira": a.manifest.sephira, "wave": a.manifest.wave}
            for a in agents
        ],
    }


if __name__ == "__main__":
    port = 8007
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    uvicorn.run(app, host="0.0.0.0", port=port)
