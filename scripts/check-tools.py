#!/usr/bin/env python3
"""Check every tool the plugin's skills call exists on a Fulcra MCP server.

Lists the tools a fulcra-context-mcp checkout offers as the hosted server
(model-visible ones, the way a client sees them) and compares them with every
`tool_name(` call written in the skills.

    scripts/check-tools.py <fulcra-context-mcp checkout>

Exits 1 if a skill calls a tool the server doesn't offer, except the ones in
OPTIONAL, which the skills only use when the connector offers them.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "plugins" / "fulcra" / "skills"

# Tools a skill calls only if offered, with the alternative it falls back to.
OPTIONAL: dict[str, str] = {}

LIST_TOOLS = """
import asyncio, json
from fastmcp import Client
from fulcra_mcp.main import mcp
async def go():
    async with Client(mcp) as c:
        tools = await c.list_tools()
    names = [t.name for t in tools
             if "model" in ((t.meta or {}).get("ui") or {}).get("visibility", ["model"])]
    print(json.dumps(names))
asyncio.run(go())
"""

CALL = re.compile(r"`([a-z][a-z0-9]*(?:_[a-z0-9]+)+)\(")


def offered(checkout: str) -> set[str]:
    out = subprocess.run(
        ["uv", "run", "--directory", checkout, "python", "-c", LIST_TOOLS],
        env={**os.environ, "FULCRA_ENVIRONMENT": "prod"},
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return set(json.loads(out.strip().splitlines()[-1]))


def called() -> dict[str, list[str]]:
    calls: dict[str, list[str]] = {}
    for path in sorted(SKILLS.rglob("*.md")):
        for name in CALL.findall(path.read_text()):
            calls.setdefault(name, []).append(str(path.relative_to(ROOT)))
    return calls


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    tools = offered(sys.argv[1])
    missing = 0
    for name, where in sorted(called().items()):
        if name in tools:
            continue
        files = ", ".join(sorted(set(where)))
        if name in OPTIONAL:
            print(f"optional, not offered: {name} ({OPTIONAL[name]}) in {files}")
        else:
            print(f"MISSING: {name} in {files}")
            missing += 1
    print(f"{len(tools)} model-visible tools offered; {missing} missing")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
