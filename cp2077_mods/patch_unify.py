import re

path = "tools/lilith_unify_cyberpunk.py"
content = open(path).read()

# Replace collect_canonical_reds
new_collect = """def collect_canonical_reds() -> list[Path]:
    files: list[Path] = []
    for path in SCRIPTS_DIR.rglob("*.reds"):
        files.append(path)
    return sorted(files)"""
content = re.sub(r"def collect_canonical_reds\(\).*?return sorted\(files\)", new_collect, content, flags=re.DOTALL)

# Replace manifest_entry_for
new_manifest = """def manifest_entry_for(path: Path) -> str:
    return str(path.relative_to(SCRIPTS_DIR)).replace("\\\\", "/")"""
content = re.sub(r"def manifest_entry_for\(path: Path\) -> str:.*?return str\(rel\)\.replace\(\"\\\\\\\\\", \"/\"\)", new_manifest, content, flags=re.DOTALL)

# Disable prune and sync
content = content.replace("synced = sync_to_scripts(canonical)", "synced = 0")
content = content.replace("removed = prune_orphan_scripts()", "removed = 0")

open(path, "w").write(content)
