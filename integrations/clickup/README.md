# ClickUp Integration

Purpose: connect Twlv20-AI to ClickUp as the human-in-the-loop work handoff layer for Twlv20 AI OS.

## Auth model

Use a ClickUp personal API token for internal workspace operations. Store it outside git in `.env.clickup`:

```bash
CLICKUP_API_TOKEN=pk_xxx
```

Do not commit real tokens.

## Verification

Run:

```bash
python3 scripts/clickup_check.py
```

The script calls `GET /api/v2/team` and prints the accessible Workspaces.

## Operating rules

- Read/list operations are okay once authenticated.
- Creating/updating ClickUp tasks is allowed only when Jessie explicitly asks or approves the specific lane.
- Client/tenant context must remain separated: Pure Peptide, AgereSciences, SRU, Twlv20 Internal.
- Agent-created tasks should include: tenant, workflow, context, acceptance criteria, required human gate, proof-of-completion request, artifact links.
