# Grand Theft Cyberpunk: Quest Generation Pipeline

## Overview
This document outlines the end-to-end quest generation pipeline for Grand Theft Cyberpunk, driven by the Metaconscious Singularity Node (MSN) and Lilith Engine.

## Pipeline Architecture

### 1. Lilith Engine (Python / Core AI)
- **Role**: Master Orchestrator and Content Generator.
- **Process**: 
  - Generates quest narratives, objectives, and parameters dynamically.
  - Interfaces with Metaconscious capabilities (NSSP, Ouroboros) for context-aware generation.
  - Outputs structured quest definitions (JSON/YAML) and dialogue scripts.

### 2. REDscript Integration (msn_cortex_link.reds, nssp_bridge.reds)
- **Role**: Logic binding and in-game event orchestration.
- **Process**:
  - REDscript scripts listen to state changes and connect directly to local MSN services via HTTP/WebSocket hooks.
  - Interprets the structured data received from Lilith Engine.
  - Spawns entities, assigns objectives, and handles dialogue state progression.

### 3. TweakDB (msn_tweakdb.toml)
- **Role**: Data persistence and static asset linkage.
- **Process**:
  - The mod defines custom quest records, items, NPC archetypes, and modifiers via TweakDB.
  - Python scripts (`append_tweakdb.py`, `integrate_msn.py`) programmatically inject new quest data into the TweakDB compiler format.
  - WolvenKit compiles the modified TweakDB for in-game ingestion.

### 4. In-Game Execution
- **Role**: Player experience.
- **Process**:
  - Cyberpunk 2077 engine loads the compiled REDmod (`msn_integration.redmod`).
  - REDscript hooks fire off on game tick / player actions.
  - The game updates the UI, spawns custom NPCs (e.g., Archangels, Sephirotic Entities), and plays generated dialogue (via audio replacements/hooks).
  - Telemetry is sent back to Lilith Engine via `nssp_bridge.reds` for recursive feedback.
