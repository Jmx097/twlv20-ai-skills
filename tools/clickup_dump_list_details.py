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


def compact_task(t):
    return {
        "id": t.get("id"),
        "custom_id": t.get("custom_id"),
        "name": t.get("name"),
        "text_content": t.get("text_content"),
        "description": t.get("description"),
        "markdown_description": t.get("markdown_description"),
        "status": t.get("status"),
        "priority": t.get("priority"),
        "assignees": [{"id": a.get("id"), "username": a.get("username"), "email": a.get("email")} for a in t.get("assignees", [])],
        "checklists": t.get("checklists", []),
        "custom_fields": [
            {
                "id": f.get("id"),
                "name": f.get("name"),
                "type": f.get("type"),
                "value": f.get("value"),
                "type_config": f.get("type_config"),
            }
            for f in t.get("custom_fields", [])
        ],
        "dependencies": t.get("dependencies", []),
        "linked_tasks": t.get("linked_tasks", []),
        "url": t.get("url"),
        "date_created": t.get("date_created"),
        "date_updated": t.get("date_updated"),
        "due_date": t.get("due_date"),
    }


def main():
    token = os.environ.get("CLICKUP_TOKEN")
    list_id = os.environ.get("CLICKUP_LIST_ID") or (sys.argv[1] if len(sys.argv) > 1 else None)
    if not token or not list_id:
        print("Need CLICKUP_TOKEN and CLICKUP_LIST_ID", file=sys.stderr)
        sys.exit(2)
    try:
        list_info = api_get(f"/list/{list_id}", token)
        tasks_page = api_get(f"/list/{list_id}/task", token, {"archived": "false", "include_markdown_description": "true", "subtasks": "true"})
        full_tasks = []
        for task in tasks_page.get("tasks", []):
            full_tasks.append(compact_task(api_get(f"/task/{task['id']}", token, {"include_markdown_description": "true"})))
    except HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode('utf-8', errors='replace')}", file=sys.stderr)
        sys.exit(1)
    out = {"list": {"id": list_info.get("id"), "name": list_info.get("name")}, "tasks": full_tasks}
    print(json.dumps(out, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
