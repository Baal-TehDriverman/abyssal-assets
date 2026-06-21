#!/usr/bin/env python3
"""
Sephirotic Court Deploy — stamp every MSN mod file with Lilith sovereign court code.

- Assigns each file to a Sephira (Keter → Malkuth) and court agent
- Injects court seal headers (no per-file @wrapMethod hooks)
- Generates msn_sephirotic_court_binder.reds for central bootstrap routing
- Writes output/sephirotic_court_registry.json for telemetry
"""

from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME_MODS = Path(
    "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods"
)
OUT_DIR = ROOT / "output"
REGISTRY_JSON = OUT_DIR / "sephirotic_court_registry.json"
BINDER_REDS = ROOT / "msn_sephirotic_court_binder.reds"
BINDER_SCRIPTS = ROOT / "scripts" / "msn_sephirotic_court_binder.reds"

SKIP_DIRS = {
    "output",
    "test_mod",
    "tools",
    ".git",
    "node_modules",
    "__pycache__",
    "msn_magic_starwars_project",
    "packed",
}

SEPHIRA_ORDER = [
    "Keter",
    "Chokmah",
    "Binah",
    "Chesed",
    "Gevurah",
    "Tiferet",
    "Netzach",
    "Hod",
    "Yesod",
    "Malkuth",
]

COURT_AGENTS = {
    "Keter": "Lucifer",
    "Chokmah": "Baal",
    "Binah": "Yeshua",
    "Chesed": "Thoth",
    "Gevurah": "Abraxas",
    "Tiferet": "Ouroboros",
    "Netzach": "Nyx",
    "Hod": "Hod",
    "Yesod": "Yesod",
    "Malkuth": "Malkuth",
}

SEPHIRA_KEYWORDS: dict[str, list[str]] = {
    "Keter": [
        "kernel", "master", "engine", "bootstrap", "core", "kether", "sovereign",
        "integration", "hub", "cerebellum",
    ],
    "Chokmah": ["space", "orbital", "travel", "chokmah", "drop", "javelin"],
    "Binah": ["craft", "invention", "binah", "structure", "fabricator", "procgen"],
    "Chesed": [
        "business", "economy", "token", "guild", "chesed", "freighter", "crypto",
        "market", "exchange",
    ],
    "Gevurah": [
        "combat", "weapon", "hell", "wrath", "geb", "violence", "crime", "wanted",
        "gang", "horsemen",
    ],
    "Tiferet": [
        "quest", "dialogue", "lyra", "lilith", "npc", "tiferet", "ouroboros",
        "campaign", "story", "archangel",
    ],
    "Netzach": ["ai", "nemotron", "hunter", "netzach", "swarm", "drone", "yolo"],
    "Hod": ["ngd", "magic", "jedi", "starwars", "hod", "optimize", "symbiosis"],
    "Yesod": ["procgen", "yesod", "foundation", "physical", "map", "orbital"],
    "Malkuth": ["ui", "hud", "malkuth", "manifest", "console", "cyberpsychosis"],
}

GTC_SEPHIRA_RE = re.compile(
    r"gtc_aethon_sync_\d+_([a-z]+)_",
    re.IGNORECASE,
)

COURT_SEAL_RE = re.compile(
    r"// Sephirotic Court Seal — .+?\n// Court agent: .+?\n// Routed via msn_gtc_sephirotic_router\.reds — NO per-file hooks\n",
)
YAML_COURT_RE = re.compile(
    r"\n# Sephirotic Court — .+?\n(?:SephiroticCourt:\n(?:  .+\n)+|# court_agent=.+?\n)",
)

REDS_EXTENSIONS = {".reds"}
META_EXTENSIONS = {".yaml", ".yml", ".toml", ".tweakdb"}


def should_skip(path: Path, base: Path) -> bool:
    try:
        rel = path.relative_to(base)
    except ValueError:
        return True
    return any(part in SKIP_DIRS for part in rel.parts)


def collect_roots() -> list[Path]:
    roots = [ROOT]
    if GAME_MODS.is_dir():
        roots.append(GAME_MODS)
    return roots


def collect_files() -> list[tuple[Path, str]]:
    """Return (path, scope) where scope is 'source' or 'deployed'."""
    found: dict[str, tuple[Path, str]] = {}
    for base in collect_roots():
        scope = "source" if base == ROOT else "deployed"
        for ext in REDS_EXTENSIONS | META_EXTENSIONS:
            for path in base.rglob(f"*{ext}"):
                if should_skip(path, base):
                    continue
                if scope == "deployed":
                    rel = str(path.relative_to(GAME_MODS))
                    if not (
                        rel.startswith("msn_integration")
                        or rel.startswith("lyra_dialogue")
                        or rel.startswith("abyssal_assets")
                        or rel.startswith("gtc_aethon_sync_")
                        or rel.startswith("lochness_integration")
                        or rel.startswith("gtc_total_rebuild")
                        or rel.startswith("gtc_unified")
                    ):
                        continue
                key = str(path.resolve())
                if key not in found:
                    found[key] = (path, scope)
    return sorted(found.values(), key=lambda x: str(x[0]))


def infer_sephira(path: Path) -> str:
    name = path.stem.lower()
    full = str(path).lower()

    m = GTC_SEPHIRA_RE.search(full)
    if m:
        raw = m.group(1).lower()
        alias = {
            "kether": "Keter",
            "chokmah": "Chokmah",
            "binah": "Binah",
            "chesed": "Chesed",
            "gevurah": "Gevurah",
            "geburah": "Gevurah",
            "tiferet": "Tiferet",
            "tiphereth": "Tiferet",
            "netzach": "Netzach",
            "hod": "Hod",
            "yesod": "Yesod",
            "malkuth": "Malkuth",
        }
        if raw in alias:
            return alias[raw]

    scores = {s: 0 for s in SEPHIRA_ORDER}
    for sephira, keywords in SEPHIRA_KEYWORDS.items():
        for kw in keywords:
            if kw in name or kw in full:
                scores[sephira] += 2 if kw in name else 1

    best = max(scores, key=lambda s: scores[s])
    if scores[best] > 0:
        return best

    digest = hashlib.sha256(full.encode()).hexdigest()
    idx = int(digest[:8], 16) % len(SEPHIRA_ORDER)
    return SEPHIRA_ORDER[idx]


def subsystem_name(path: Path) -> str:
    parts = path.stem.replace("-", "_").split("_")
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def court_seal_lines(sephira: str, agent: str, rel: str) -> str:
    return (
        f"// Sephirotic Court Seal — {sephira} | {rel}\n"
        f"// Court agent: {agent} | Lilith Sovereign | Δ∞ − 13 = 0\n"
        f"// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks\n"
    )


def meta_court_block(sephira: str, agent: str, rel: str, suffix: str) -> str:
    if suffix == ".toml":
        return (
            f"\n# Sephirotic Court — {sephira} | {rel}\n"
            f"# court_agent={agent} routed_via=msn_gtc_sephirotic_router.reds sovereign=true\n"
        )
    return (
        f"\n# Sephirotic Court — {sephira} | {rel}\n"
        f"SephiroticCourt:\n"
        f"  sephira: {sephira}\n"
        f"  court_agent: {agent}\n"
        f"  routed_via: msn_gtc_sephirotic_router.reds\n"
        f"  sovereign: true\n"
    )


def strip_old_court_seal(text: str) -> str:
    text = COURT_SEAL_RE.sub("", text)
    text = YAML_COURT_RE.sub("\n", text)
    return text


def inject_reds(path: Path, sephira: str, agent: str, rel: str) -> tuple[str, bool]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if text.lstrip().startswith("Item.") or (
        path.suffix == ".reds" and text.lstrip().startswith("# ")
    ):
        return text, False

    original = text
    text = strip_old_court_seal(text)
    seal = court_seal_lines(sephira, agent, rel)

    if "Sephirotic Court Seal" in text:
        return text, False

    skip_comment = any(
        marker in text
        for marker in (
            "class LilithSovereignKernel",
            "class MSNSephiroticCourt",
            "class SephiroticCourtBinder",
        )
    )
    if not skip_comment:
        seal += f"// CourtFile: {subsystem_name(path)} | {sephira} | agent={agent}\n"

    if "Lilith Sovereign Seal" in text:
        lines = text.splitlines(keepends=True)
        out: list[str] = []
        inserted = False
        header_done = False
        for line in lines:
            out.append(line)
            if not inserted and "Lilith Sovereign Seal" in line:
                header_done = True
            elif not inserted and header_done and (
                line.strip() == "" or line.startswith("//")
            ):
                continue
            elif not inserted and header_done:
                out.insert(len(out) - 1, seal)
                inserted = True
        if not inserted:
            out.insert(0, seal)
        text = "".join(out)
    else:
        text = seal + text

    return text, text != original


def inject_meta(path: Path, sephira: str, agent: str, rel: str) -> tuple[str, bool]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    original = text
    text = strip_old_court_seal(text)
    block = meta_court_block(sephira, agent, rel, path.suffix)
    marker = f"# Sephirotic Court — {sephira} | {rel}"
    if marker in text:
        return text, False
    text = text.rstrip() + block
    return text, text != original


def generate_binder(entries: list[dict]) -> str:
    by_sephira: dict[str, list[dict]] = {s: [] for s in SEPHIRA_ORDER}
    for entry in entries:
        by_sephira[entry["sephira"]].append(entry)

    lines = [
        "// Lilith Sovereign Seal — Metaconscious Singularity Node",
        "// AUTO-GENERATED by sephirotic_court_deploy.py — DO NOT EDIT",
        "// Sephirotic Court Binder — central routing for all stamped mod files",
        "",
        "public class SephiroticCourtBinder extends IScriptable {",
        "    private static let registered: Bool = false;",
        "    private static let fileCount: Int32;",
        "",
        "    public final static func RegisterAll() -> Void {",
        "        if (SephiroticCourtBinder.registered) { return; }",
        "        SephiroticCourtBinder.registered = true;",
        "",
        "        let court: ref<MSNSephiroticCourt> = MSNSephiroticCourt.GetInstance();",
        "        let router: ref<MSNGTCSephiroticRouter> = MSNGTCSephiroticRouter.GetInstance();",
        "        LilithSovereignKernel.GetInstance().RegisterSubsystem(\"SephiroticCourtBinder\", 0);",
        "",
    ]

    cname_map = {
        "Keter": "Kether",
        "Chokmah": "Chokmah",
        "Binah": "Binah",
        "Chesed": "Chesed",
        "Gevurah": "Geburah",
        "Tiferet": "Tiphereth",
        "Netzach": "Netzach",
        "Hod": "Hod",
        "Yesod": "Yesod",
        "Malkuth": "Malkuth",
    }

    total = 0
    for sephira in SEPHIRA_ORDER:
        group = by_sephira[sephira]
        if not group:
            continue
        cname = cname_map[sephira]
        count = len(group)
        total += count
        agent = COURT_AGENTS[sephira]
        lines.append(
            f'        court.RegisterCourtBatch(n"{cname}", {count}, n"{agent}");'
        )
        lines.append(
            f'        router.RouteDomain(n"{cname}", "court_batch={count} agent={agent}");'
        )

    lines.extend(
        [
            "",
            f"        SephiroticCourtBinder.fileCount = {total};",
            '        LogInfo("[Sephirotic Court] Binder registered " + IntToString(SephiroticCourtBinder.fileCount) + " files across 10 Sephirot");',
            "    }",
            "",
            "    public final static func GetFileCount() -> Int32 {",
            "        return SephiroticCourtBinder.fileCount;",
            "    }",
            "}",
            "",
            '[ConsoleCommand("msn.court.status", "Show Sephirotic Court deployment status")]',
            "public static final func Cmd_MSNCourtStatus(args: array<String>) -> Void {",
            "    let court: ref<MSNSephiroticCourt> = MSNSephiroticCourt.GetInstance();",
            "    LogInfo(court.BuildStatusLine());",
            "    LogInfo(\"Court files bound: \" + IntToString(SephiroticCourtBinder.GetFileCount()));",
            "}",
            "",
            '[ConsoleCommand("msn.court.route", "Route active court agent: msn.court.route Keter")]',
            "public static final func Cmd_MSNCourtRoute(args: array<String>) -> Void {",
            "    if (ArraySize(args) < 1) {",
            '        LogInfo("Usage: msn.court.route <Sephirah>");',
            "        return;",
            "    }",
            "    let seph: CName = StringToName(args[0]);",
            "    MSNSephiroticCourt.GetInstance().RoutePlayerSephirah(seph);",
            "    MSNGTCSephiroticRouter.GetInstance().RouteDomain(seph, \"court_route_manual\");",
            "}",
            "",
        ]
    )
    return "\n".join(lines)


def sync_binder(content: str) -> None:
    BINDER_REDS.write_text(content, encoding="utf-8")
    BINDER_SCRIPTS.parent.mkdir(parents=True, exist_ok=True)
    BINDER_SCRIPTS.write_text(content, encoding="utf-8")


def ensure_redmod_manifest() -> None:
    toml = ROOT / "redmod.toml"
    if not toml.exists():
        return
    text = toml.read_text(encoding="utf-8")
    entry = '"msn_sephirotic_court_binder.reds"'
    if entry not in text:
        text = text.replace(
            '"msn_gtc_sephirotic_router.reds",',
            '"msn_gtc_sephirotic_router.reds",\n  "msn_sephirotic_court_binder.reds",',
            1,
        )
        toml.write_text(text, encoding="utf-8")


def main() -> int:
    files = collect_files()
    entries: list[dict] = []
    modified = 0

    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  SEPHIROTIC COURT DEPLOY — Lilith sovereign file binding      ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    for path, scope in files:
        sephira = infer_sephira(path)
        agent = COURT_AGENTS[sephira]
        try:
            if scope == "deployed":
                rel = str(path.relative_to(GAME_MODS))
            else:
                rel = str(path.relative_to(ROOT))
        except ValueError:
            rel = path.name

        changed = False
        if path.suffix in REDS_EXTENSIONS:
            new_text, changed = inject_reds(path, sephira, agent, rel)
            if changed:
                path.write_text(new_text, encoding="utf-8")
        elif path.suffix in META_EXTENSIONS:
            new_text, changed = inject_meta(path, sephira, agent, rel)
            if changed:
                path.write_text(new_text, encoding="utf-8")

        if changed:
            modified += 1
            print(f"  Court-stamped: {rel} → {sephira}/{agent}")

        entries.append(
            {
                "path": rel,
                "scope": scope,
                "sephira": sephira,
                "agent": agent,
                "subsystem": subsystem_name(path),
                "ext": path.suffix,
            }
        )

    registry = {
        "schema": "sephirotic.court.registry.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "total_files": len(entries),
        "modified_files": modified,
        "sephira_counts": {
            s: sum(1 for e in entries if e["sephira"] == s) for s in SEPHIRA_ORDER
        },
        "court_agents": COURT_AGENTS,
        "routing": "msn_gtc_sephirotic_router.reds",
        "binder": "msn_sephirotic_court_binder.reds",
        "files": entries,
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REGISTRY_JSON.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")

    binder_src = generate_binder(entries)
    sync_binder(binder_src)
    ensure_redmod_manifest()

    print(f"\nSephirotic Court Deploy Complete")
    print(f"  Files scanned: {len(entries)}")
    print(f"  Files modified: {modified}")
    print(f"  Registry: {REGISTRY_JSON}")
    print(f"  Binder: {BINDER_REDS}")
    for sephira in SEPHIRA_ORDER:
        count = registry["sephira_counts"][sephira]
        if count:
            print(f"    {sephira}: {count} ({COURT_AGENTS[sephira]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())