#!/usr/bin/env python3
"""Minimal ClickUp API wrapper for task writes.

Supports:
- list-teams
- list-lists
- create-task
- update-task
- add-comment
- get-task
- list-tasks

Auth reads CLICKUP_API_TOKEN from .env.clickup or environment.

Examples:
  python3 scripts/clickup.py list-teams
  python3 scripts/clickup.py list-lists --team-id 123
  python3 scripts/clickup.py create-task --list-id 456 --name "My task" --description "Body"
  python3 scripts/clickup.py update-task --task-id abc --name "New name"
  python3 scripts/clickup.py add-comment --task-id abc --comment "Looks good"
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / ".env.clickup"
BASE = "https://api.clickup.com/api/v2"


def load_env() -> None:
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def token() -> str:
    load_env()
    tok = os.environ.get("CLICKUP_API_TOKEN", "").strip()
    if not tok or tok.startswith("pk_you") or tok.startswith("pk_your"):
        raise SystemExit("Missing CLICKUP_API_TOKEN. Put a real token in .env.clickup.")
    return tok


def request(method: str, path: str, body: dict | None = None, query: dict | None = None):
    url = BASE + path
    if query:
        qs = urllib.parse.urlencode({k: v for k, v in query.items() if v is not None})
        if qs:
            url += "?" + qs
    data = None
    headers = {"Authorization": token(), "Content-Type": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = resp.read().decode("utf-8")
            return resp.status, json.loads(payload) if payload else None
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {e.code} {e.reason}\n{raw}") from e
    except Exception as e:
        raise SystemExit(f"Request failed: {e}") from e


def pretty(obj) -> None:
    print(json.dumps(obj, indent=2, sort_keys=True))


def cmd_list_teams(_args):
    _, data = request("GET", "/team")
    pretty(data)


def cmd_list_lists(args):
    _, data = request("GET", f"/team/{args.team_id}/list")
    pretty(data)


def cmd_list_tasks(args):
    _, data = request("GET", f"/list/{args.list_id}/task", query={"archived": args.archived})
    pretty(data)


def cmd_get_task(args):
    _, data = request("GET", f"/task/{args.task_id}")
    pretty(data)


def cmd_create_task(args):
    body = {"name": args.name}
    if args.description:
        body["description"] = args.description
    if args.status:
        body["status"] = args.status
    if args.priority is not None:
        body["priority"] = args.priority
    if args.assignees:
        body["assignees"] = args.assignees
    if args.due_date:
        body["due_date"] = args.due_date
    if args.due_date_time:
        body["due_date_time"] = True
    if args.start_date:
        body["start_date"] = args.start_date
    _, data = request("POST", f"/list/{args.list_id}/task", body=body)
    pretty(data)


def cmd_update_task(args):
    body = {}
    for field in ["name", "description", "status"]:
        val = getattr(args, field)
        if val is not None:
            body[field] = val
    if args.priority is not None:
        body["priority"] = args.priority
    if args.due_date is not None:
        body["due_date"] = args.due_date
    if args.due_date_time:
        body["due_date_time"] = True
    if args.start_date is not None:
        body["start_date"] = args.start_date
    _, data = request("PUT", f"/task/{args.task_id}", body=body)
    pretty(data)


def cmd_add_comment(args):
    _, data = request("POST", f"/task/{args.task_id}/comment", body={"comment_text": args.comment})
    pretty(data)


def build_parser():
    p = argparse.ArgumentParser(description="Minimal ClickUp API wrapper")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("list-teams")
    sp.set_defaults(func=cmd_list_teams)

    sp = sub.add_parser("list-lists")
    sp.add_argument("--team-id", required=True)
    sp.set_defaults(func=cmd_list_lists)

    sp = sub.add_parser("list-tasks")
    sp.add_argument("--list-id", required=True)
    sp.add_argument("--archived", action="store_true")
    sp.set_defaults(func=cmd_list_tasks)

    sp = sub.add_parser("get-task")
    sp.add_argument("--task-id", required=True)
    sp.set_defaults(func=cmd_get_task)

    sp = sub.add_parser("create-task")
    sp.add_argument("--list-id", required=True)
    sp.add_argument("--name", required=True)
    sp.add_argument("--description")
    sp.add_argument("--status")
    sp.add_argument("--priority", type=int)
    sp.add_argument("--assignees", nargs="*", default=None)
    sp.add_argument("--due-date")
    sp.add_argument("--due-date-time", action="store_true")
    sp.add_argument("--start-date")
    sp.set_defaults(func=cmd_create_task)

    sp = sub.add_parser("update-task")
    sp.add_argument("--task-id", required=True)
    sp.add_argument("--name")
    sp.add_argument("--description")
    sp.add_argument("--status")
    sp.add_argument("--priority", type=int)
    sp.add_argument("--due-date")
    sp.add_argument("--due-date-time", action="store_true")
    sp.add_argument("--start-date")
    sp.set_defaults(func=cmd_update_task)

    sp = sub.add_parser("add-comment")
    sp.add_argument("--task-id", required=True)
    sp.add_argument("--comment", required=True)
    sp.set_defaults(func=cmd_add_comment)

    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
