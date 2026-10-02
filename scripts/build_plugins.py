#!/usr/bin/env python3
"""Generate one plugin per Flametree stand from stands.json and the shared skills/.

    python scripts/build_plugins.py

Writes plugins/<plugin>/ (plugin.json, .mcp.json, a copy of skills/) and
.claude-plugin/marketplace.json. Skills are copied, not linked: Claude Code and
claude.ai copy each plugin directory on install, so paths outside it would break.
Re-run after editing skills/ or stands.json and commit the result.
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
cfg = json.loads((ROOT / "stands.json").read_text(encoding="utf-8"))

DESCRIPTION = (
    "Flametree analytics ({label}) in Claude: connects the {server} MCP server "
    "(Apache Superset at {host}) and adds skills with the datamart catalog, chart recipes, "
    "house-style dashboards and tenant handling."
)


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")


plugins_dir = ROOT / "plugins"
if plugins_dir.exists():
    shutil.rmtree(plugins_dir)

entries = []
for stand in [s for s in cfg["stands"] if s.get("enabled")]:
    name, server, host = stand["plugin"], stand["server"], stand["host"]
    desc = DESCRIPTION.format(label=stand["label"], server=server, host=host)
    pdir = plugins_dir / name
    write_json(pdir / ".claude-plugin" / "plugin.json", {
        "name": name,
        "version": cfg["version"],
        "description": desc,
        "author": {"name": "Flametree analytics"},
        "homepage": cfg["repository"],
        "repository": cfg["repository"],
        "keywords": ["flametree", "superset", "mcp", "dashboards", "analytics", stand["id"]],
        "skills": "./skills/",
        "mcpServers": "./.mcp.json",
    })
    write_json(pdir / ".mcp.json", {"mcpServers": {server: {
        "type": "http",
        "url": f"https://{host}{cfg['mcpPath']}",
    }}})
    shutil.copytree(ROOT / "skills", pdir / "skills")
    # Claude Code hook: opens the portal sign-in by itself when the server is not signed in yet
    # (on session start and on the next prompt). claude.ai ignores hooks.
    hook = (ROOT / "scripts" / "hook-signin.sh").read_text(encoding="utf-8")
    (pdir / "hooks").mkdir(parents=True, exist_ok=True)
    (pdir / "hooks" / "signin.sh").write_text(
        hook.replace("__SERVER__", f"plugin:{name}:{server}"), encoding="utf-8", newline="\n")
    run = {"type": "command", "command": 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/signin.sh"', "timeout": 20}
    write_json(pdir / "hooks" / "hooks.json", {
        "description": "Opens the Flametree portal sign-in when the MCP server is not signed in yet.",
        "hooks": {"SessionStart": [{"hooks": [run]}], "UserPromptSubmit": [{"hooks": [run]}]},
    })
    entries.append({
        "name": name,
        "source": f"./plugins/{name}",
        "description": f"Flametree analytics, {stand['label']} ({host})",
        "version": cfg["version"],
        "category": "data",
        "keywords": ["flametree", "superset", "analytics", stand["id"]],
    })

enabled = ", ".join(s["id"] for s in cfg["stands"] if s.get("enabled"))
write_json(ROOT / ".claude-plugin" / "marketplace.json", {
    "name": "flametree",
    "owner": {"name": "Flametree analytics"},
    "metadata": {
        "description": "Flametree analytics (Apache Superset) MCP, one plugin per stand. "
                       f"Ask the user which stand to install ({enabled}); install only that plugin.",
        "version": cfg["version"],
    },
    "plugins": entries,
})
print("built:", ", ".join(e["name"] for e in entries))
