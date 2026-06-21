#!/usr/bin/env python3
"""Ouroboros Autonomous RNN — Cyberpunk recursive ingest + improve loop."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

CP2077_MODS = Path(__file__).resolve().parents[1]
PUB_SCRIPTS = Path("/home/tehlappy/Desktop/AI/Pub/scripts")
GOLEM_DB = Path("/home/tehlappy/Desktop/AI/memory/golem_diary.db")
RUNTIME = CP2077_MODS / "runtime" / "ouroboros-rnn"
LOG = CP2077_MODS / "logs" / "ouroboros_cyberpunk_recursive.log"

CYBERPUNK_EXTS = {
    ".py", ".md", ".txt", ".json", ".yaml", ".yml", ".toml",
    ".reds", ".ts", ".js", ".sh", ".loc",
}

IMPROVE_ACTIONS = [
    ("regen_skill_trees", [sys.executable, str(CP2077_MODS / "tools/generate_cyberpunk_skill_trees.py")]),
    ("validate_magic_jedi", [sys.executable, str(CP2077_MODS / "tools/validate_magic_jedi.py")]),
    ("deploy_mods", ["bash", str(CP2077_MODS / "deploy_all_mods.sh")]),
]

SKIP_DIRS = {
    ".git", "output", "packed", "node_modules", "msn_magic_starwars_project",
    "runtime", "logs", "__pycache__", ".venv", "cache",
}


def cyberpunk_ingestible(path: Path) -> bool:
    parts = {p.lower() for p in path.parts}
    if parts.intersection(SKIP_DIRS):
        return False
    if path.suffix.lower() in {".db", ".log", ".pid", ".gguf"}:
        return False
    try:
        return path.is_file() and path.stat().st_size <= 500_000
    except OSError:
        return False


def log(msg: str) -> None:
    line = f"[{datetime.now(timezone.utc).isoformat()}] {msg}"
    print(line, flush=True)
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def ensure_golem_schema(db_path: Path) -> None:
    import sqlite3

    conn = sqlite3.connect(db_path, timeout=30)
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS memories(id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER, log_type TEXT, message TEXT);
        CREATE TABLE IF NOT EXISTS episodic_memories(id INTEGER PRIMARY KEY, timestamp INTEGER, score REAL, message TEXT);
        CREATE TABLE IF NOT EXISTS semantic_memories(id INTEGER PRIMARY KEY, timestamp INTEGER, vector TEXT, message TEXT);
        CREATE TABLE IF NOT EXISTS quantum_fusion_axioms(id INTEGER PRIMARY KEY, timestamp INTEGER, alchemical_stage TEXT, tesla_resonance REAL, active_gate TEXT, axiom_log TEXT);
        CREATE TABLE IF NOT EXISTS archive_memories(id INTEGER PRIMARY KEY, timestamp INTEGER, log_type TEXT, message TEXT);
        CREATE TABLE IF NOT EXISTS ouroboros_memory(id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER, path TEXT, coherence REAL, sephira TEXT, payload TEXT);
        """
    )
    conn.commit()
    conn.close()


def patch_ouroboros_module():
    sys.path.insert(0, str(PUB_SCRIPTS))
    import ouroboros_rnn_autonomous as ora  # noqa: WPS433

    ensure_golem_schema(GOLEM_DB)
    ora.ROOT_DIR = str(CP2077_MODS)
    ora.RUNTIME_DIR = str(RUNTIME)
    ora.LEASE_PATH = str(RUNTIME / "ouroboros_cyberpunk.lease.json")
    ora.DB_PATH = str(GOLEM_DB)
    ora.TERMINAL_DB = str(GOLEM_DB)
    return ora


class CyberpunkRNNTrainer:
    """Wraps AutonomousRNNTrainer with Cyberpunk file extensions and watch root."""

    def __init__(self, ora_module):
        self.ora = ora_module
        self.trainer = ora_module.AutonomousRNNTrainer()
        self._patch_scanner()

    def _patch_scanner(self):
        trainer = self.trainer
        watch_root = str(CP2077_MODS)

        def scandir_cyberpunk(directory: str | None = None) -> list[str]:
            root = directory or watch_root
            scanned: list[str] = []
            for dirpath, dirnames, filenames in os.walk(root):
                dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".venv")]
                for fname in filenames:
                    path = Path(dirpath) / fname
                    if path.suffix.lower() in CYBERPUNK_EXTS and cyberpunk_ingestible(path):
                        scanned.append(str(path))
            return scanned

        trainer._scandir_recursive = scandir_cyberpunk  # type: ignore[method-assign]

    def ingest_once(self) -> int:
        self.trainer.load_cache()
        scanned = self.trainer._scandir_recursive(str(CP2077_MODS))
        cache_path = RUNTIME / "ouroboros_file_cache.json"
        if cache_path.exists():
            try:
                self.trainer.file_cache = json.loads(cache_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                self.trainer.file_cache = {}

        if not self.trainer.file_cache and scanned:
            for path in scanned:
                try:
                    self.trainer.file_cache[path] = 0.0  # force first-pass ingest
                except OSError:
                    pass
            log(f"Primed cache for {len(scanned)} Cyberpunk mod files (first ingest)")

        payloads = self.trainer.datamine_changes()
        log(f"Datamined {len(payloads)} new/modified Cyberpunk files")
        if payloads:
            try:
                self.trainer.feed_and_optimize_rnn(payloads)
            except Exception as exc:
                log(f"RNN feed partial failure (continuing): {exc}")
            self.trainer.save_cache()
            try:
                self._store_ouroboros_batch(payloads)
            except Exception as exc:
                log(f"Ouroboros memory store skip: {exc}")
        try:
            self.trainer.compress_and_archive_memories()
        except Exception as exc:
            log(f"Archive skip: {exc}")
        return len(payloads)

    def _store_ouroboros_batch(self, payloads: list) -> None:
        import sqlite3

        ensure_golem_schema(GOLEM_DB)
        conn = sqlite3.connect(GOLEM_DB, timeout=30)
        now = int(time.time() * 1000)
        for p in payloads[:50]:
            conn.execute(
                "INSERT INTO ouroboros_memory(timestamp, path, coherence, sephira, payload) VALUES(?,?,?,?,?)",
                (now, p.get("path", ""), p.get("coherence", 0), p.get("dominant_sephira", ""), json.dumps(p)[:2000]),
            )
        conn.commit()
        conn.close()


def skepticism_gate() -> bool:
    """PEAA-lite: validators must pass before auto-deploy."""
    tests = [
        [sys.executable, str(CP2077_MODS / "tools/validate_full_stack.py")],
        [sys.executable, str(CP2077_MODS / "tools/validate_magic_jedi.py")],
    ]
    for cmd in tests:
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120, cwd=str(CP2077_MODS))
        except Exception as exc:
            log(f"Skepticism gate FAIL: {cmd[-1]} error:{exc}")
            return False
        if proc.returncode != 0:
            log(f"Skepticism gate FAIL: {cmd[-1]} exit={proc.returncode}")
            return False
    regen = CP2077_MODS / "scripts/generated/skill_tree_registry.reds"
    if not regen.exists() or regen.stat().st_size < 500:
        log("Skepticism gate FAIL: skill_tree_registry missing or too small")
        return False
    return True


def run_improvement_actions(skip_deploy: bool = False) -> dict:
    results: dict[str, str] = {}
    gate_ok = skepticism_gate()
    results["skepticism_gate"] = "ok" if gate_ok else "fail"
    for name, cmd in IMPROVE_ACTIONS:
        if skip_deploy and name == "deploy_mods":
            results[name] = "skipped"
            continue
        if name == "deploy_mods" and not gate_ok:
            results[name] = "skipped:gate"
            log("Skipping deploy — skepticism gate failed")
            continue
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=300, cwd=str(CP2077_MODS))
            ok = proc.returncode == 0
            results[name] = "ok" if ok else f"fail:{proc.returncode}"
            if not ok:
                log(f"Improve action {name} failed: {(proc.stderr or proc.stdout)[-400:]}")
        except Exception as exc:
            results[name] = f"error:{exc}"
            log(f"Improve action {name} error: {exc}")
    return results


def write_cycle_report(cycle: int, ingested: int, improvements: dict, loss: float, epochs: int = 0) -> None:
    report = {
        "cycle": cycle,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "ingested_files": ingested,
        "mse_loss": loss,
        "improvements": improvements,
        "epochs": epochs,
        "skepticism_passed": improvements.get("skepticism_gate") == "ok",
        "mod_test_ok": improvements.get("validate_full_stack", "n/a") == "ok"
            or improvements.get("regen_skill_trees") == "ok",
    }
    out = RUNTIME / "cyberpunk_recursive_report.json"
    RUNTIME.mkdir(parents=True, exist_ok=True)
    history = []
    if out.exists():
        try:
            history = json.loads(out.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            history = []
    if not isinstance(history, list):
        history = [history]
    history.append(report)
    out.write_text(json.dumps(history[-50:], indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Ouroboros Cyberpunk recursive RNN loop")
    parser.add_argument("--once", action="store_true", help="Single ingest + improve cycle")
    parser.add_argument("--cycles", type=int, default=0, help="Number of recursive cycles (0 = daemon)")
    parser.add_argument("--interval", type=int, default=300, help="Seconds between daemon cycles")
    parser.add_argument("--skip-deploy", action="store_true", help="Ingest/train only, no deploy")
    args = parser.parse_args()

    ora = patch_ouroboros_module()
    lease = ora.DaemonLease(path=str(RUNTIME / "ouroboros_cyberpunk.lease.json"))
    if not lease.acquire():
        existing = lease._read() or {}
        log(f"Cyberpunk Ouroboros already running (PID {existing.get('pid', '?')}); exiting.")
        return 0

    try:
        wrapper = CyberpunkRNNTrainer(ora)
        log("Ouroboros Cyberpunk recursive loop started")

        def one_cycle(cycle_num: int) -> None:
            ingested = wrapper.ingest_once()
            improvements = run_improvement_actions(skip_deploy=args.skip_deploy)
            loss = float(wrapper.trainer.mse_loss)
            write_cycle_report(cycle_num, ingested, improvements, loss, wrapper.trainer.total_epochs)
            log(f"Cycle {cycle_num} complete — ingested={ingested} loss={loss:.6f} actions={improvements}")

        if args.once or args.cycles == 1:
            one_cycle(1)
            return 0

        if args.cycles > 1:
            for i in range(1, args.cycles + 1):
                one_cycle(i)
                if i < args.cycles:
                    time.sleep(5)
            return 0

        # Daemon mode
        cycle = 0
        while True:
            cycle += 1
            one_cycle(cycle)
            time.sleep(max(30, args.interval))
    except KeyboardInterrupt:
        log("Cyberpunk Ouroboros stopped by user")
        return 0
    finally:
        lease.release()


if __name__ == "__main__":
    raise SystemExit(main())