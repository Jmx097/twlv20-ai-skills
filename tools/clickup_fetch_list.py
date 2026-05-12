#!/usr/bin/env python3
import json
import os
import sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError

BASE = "https://api.clickup.com/api/v2"


def api_get(path, token, params=None):
    url = f"{BASE}{path}"
    if params:
        url += "?" + urlencode(params)
    req = Request(url, headers={"Authorization": token, "Content-Type": "application/json"})
    with urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main():
    token = os.environ.get("CLICKUP_TOKEN")
    list_id = os.environ.get("CLICKUP_LIST_ID") or (sys.argv[1] if len(sys.argv) > 1 else None)

    if not token:
        print("Missing CLICKUP_TOKEN env var", file=sys.stderr)
        sys.exit(2)
    if not list_id:
        print("Usage: CLICKUP_TOKEN=... CLICKUP_LIST_ID=<list_id> clickup_fetch_list.py", file=sys.stderr)
        sys.exit(2)

    try:
        list_info = api_get(f"/list/{list_id}", token)
        tasks = api_get(f"/list/{list_id}/task", token, {"archived": "false", "include_markdown_description": "true"})
    except HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)

    out = {
        "list": {
            "id": list_info.get("id"),
            "name": list_info.get("name"),
            "task_count": len(tasks.get("tasks", [])),
        },
        "tasks": [
            {
                "id": t.get("id"),
                "name": t.get("name"),
                "status": (t.get("status") or {}).get("status"),
                "priority": (t.get("priority") or {}).get("priority") if t.get("priority") else None,
                "due_date": t.get("due_date"),
                "url": t.get("url"),
            }
            for t in tasks.get("tasks", [])
        ],
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
