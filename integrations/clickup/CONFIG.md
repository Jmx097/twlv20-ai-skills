# ClickUp Config

Last verified: 2026-05-05 UTC

## Workspace

- Name: Twlv20
- Workspace/team ID: `90141182095`

## Spaces visible to current token

- `90145300556` — Space
- `90145300562` — Team Space

## Auth

- Token is stored locally in `.env.clickup` and intentionally ignored by git.
- Verification command: `python3 scripts/clickup_check.py`

## Default behavior

- Read/list ClickUp freely for requested work.
- Ask Jessie before creating/updating/deleting tasks unless he explicitly grants a workflow-specific autopilot lane.
- For task creation, include tenant, workflow, context, acceptance criteria, human gate, artifacts, and proof-of-completion request.
