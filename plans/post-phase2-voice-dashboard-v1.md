# Post-Phase-2 Build Plan — Voice + HTML Dashboard

Created: 2026-05-12 UTC
Owner: Jessie / Twlv20
Status: queued after Phase 2 completion

## Decision

After Phase 2 is finalized, Twlv20 should add:
- a Twilio-backed voice intake layer on top of OpenClaw
- a separate branded HTML dashboard for visibility, approvals, and client-safe views
- Slack remains the internal operator/control surface

## Why this direction

This keeps command and ops work in Slack while giving Twlv20 a cleaner product surface for:
- client-facing visibility
- executive summaries / briefs
- approval queues
- voice intake without exposing internal Slack workflows

## Recommended architecture

### Surfaces
- Slack: internal operator command surface
- Twilio number: inbound/outbound voice surface
- HTML dashboard: branded visibility and approval surface
- OpenClaw: orchestration/runtime layer
- Postgres: source of truth for runs, approvals, tenants, workflow state, audit trail
- Infisical: secrets

### Voice path
1. Caller dials Twilio number
2. Twilio sends webhook/media stream to OpenClaw voice-call plugin
3. OpenClaw transcribes / handles conversation
4. OpenClaw creates or updates run/task/approval records
5. Summary and artifacts appear in Slack + dashboard
6. Human approval gates remain enforced for risky actions

### Dashboard path
1. Authenticated user logs into Twlv20 dashboard
2. Dashboard shows tenant-scoped runs, approvals, KPIs, recent activity, and briefs
3. Approvals or review actions trigger controlled workflow actions
4. OpenClaw / workflow layer continues execution and records outcomes

## Implementation order

### Phase A — finish Phase 2 first (blocking prerequisites)
Do not start the dashboard/voice build until the current infra work is complete:
- SMTP for Infisical
- migration of real secrets into Infisical
- Backblaze B2 key rotation to bucket-scoped access
- PR #1 review/check

Strongly recommended before voice/dashboard work:
- confirm OpenClaw and Gateway upgrade plan
- confirm public domain / subdomains strategy
- confirm auth strategy for dashboard users
- confirm tenant model and approval model in DB

### Phase B — voice intake MVP
Goal: inbound call -> transcript/summary -> Slack + run log

Tasks:
1. Install and enable `@openclaw/voice-call`
2. Buy/configure Twilio number
3. Expose stable public webhook URL for voice webhooks
4. Configure provider creds, from number, webhook security, and session scope
5. Decide initial call mode:
   - notify / voicemail-style intake first (recommended)
   - full realtime conversation later
6. Configure STT/TTS provider:
   - low complexity: OpenAI/Azure speech
   - premium experience: ElevenLabs
7. Add tenant-aware call routing rules
8. Store call transcript, summary, caller, tenant, and resulting task/run in DB
9. Post summary to Slack operator channel
10. Add simple dashboard call log view

Acceptance criteria:
- inbound call reaches system reliably
- transcript and summary are stored
- Slack receives the summary
- tenant association is visible/correct
- no risky action occurs without approval

### Phase C — dashboard MVP
Goal: branded web UI for visibility + approvals

Suggested stack:
- Next.js frontend
- auth layer (simple admin auth first; expand later)
- API layer that reads tenant-safe data from Postgres / OpenClaw/Gateway surfaces

Initial screens:
1. Login
2. Overview / command center
3. Tenant switcher
4. Run log / activity feed
5. Approval queue
6. Call log
7. Task/workflow detail
8. Daily brief / summary panel

Initial cards/modules:
- active runs
- pending approvals
- recent voice requests
- workflow health
- tenant status
- latest artifacts / drafts

Acceptance criteria:
- dashboard is tenant-aware
- approvals can be reviewed safely
- recent runs/calls are visible
- branding is distinct from raw OpenClaw UI
- no client can see another tenant's data

### Phase D — workflow integration
Goal: dashboard actions actually move work

Tasks:
1. Define action types allowed from dashboard
2. Map each action to approval policy
3. Connect approval actions to workflow engine / task system
4. Log all actions with actor, timestamp, tenant, and outcome
5. Add audit-friendly event timeline per run

Recommended early allowed actions:
- approve / reject draft
- assign human owner
- mark ready for review
- request revision
- re-run summary / regenerate brief

Avoid in v1:
- direct production mutations without explicit human gate
- broad autopilot execution
- complex client self-service editing

### Phase E — polish / Phase 2 for this product line
After MVP works:
- realtime live conversational voice
- outbound calls / reminders
- executive morning brief
- PWA/mobile optimization
- role-based client portals
- richer KPI modules
- narrow autopilot lanes with undo windows

## Recommended sequencing

1. Finish current Phase 2 infra items
2. Stabilize secrets + backups + repo state
3. Launch voice intake MVP
4. Launch dashboard MVP
5. Wire approvals and run log deeply
6. Add realtime voice + polish

## Suggested v1 decisions

### Voice mode
Start with **intake/summary mode**, not full live AI receptionist.
Reason: lower risk, faster to ship, easier approval posture.

### Dashboard users
Start with **internal-only users**:
- Jessie
- Keeper
- optionally Njigo / Faguni

Then expand to client-safe views after tenancy and permissions are proven.

### Design direction
Use a dark command-center UI inspired by LaRossa/Paperclip style, but make it Twlv20-native:
- tenant-first
- approval-first
- run-log visibility
- operator/human-gate visibility

## Risks / dependencies
- Twilio webhook/public exposure must be stable
- auth and tenant isolation must be correct before client-facing rollout
- voice costs can climb if realtime mode is used too early
- approval logic must be explicit to avoid accidental live actions
- OpenClaw plugin/config changes should be tested in a controlled lane first

## Recommendation

Proceed only after current Phase 2 infra work is closed. Once that happens, the best first build is:
- Twilio voice intake MVP
- internal-only dashboard MVP
- approvals + run log as the core product behavior

That gives Twlv20 a real product surface without overextending into full autopilot too early.
