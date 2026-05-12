#!/usr/bin/env python3
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / ".env.clickup"

if ENV_FILE.exists():
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

token = os.environ.get("CLICKUP_API_TOKEN")
if not token or token.startswith("pk_your_"):
    print("Missing CLICKUP_API_TOKEN. Create .env.clickup from .env.clickup.example or export the variable.", file=sys.stderr)
    sys.exit(2)

req = urllib.request.Request(
    "https://api.clickup.com/api/v2/team",
    headers={"Authorization": token, "Content-Type": "application/json"},
)
try:
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read().decode("utf-8"))
except Exception as e:
    print(f"ClickUp auth/check failed: {e}", file=sys.stderr)
    sys.exit(1)

teams = data.get("teams", [])
print(f"ClickUp auth OK. Accessible workspaces: {len(teams)}")
for team in teams:
    print(f"- {team.get('name')} (team_id/workspace_id: {team.get('id')})")
