# ClickUp Task Draft — Phase 3: Voice Intake + Dashboard MVP

Task name:
Phase 3 — Twilio Voice Intake + Internal HTML Dashboard MVP

Suggested owner:
Jessie / Twlv20 (break out sub-tasks to Keeper / Njigo / Faguni as needed)

Suggested status:
backlog / planned

Priority:
high

Description:

Outcome

After current Phase 2 infra work is complete, Twlv20 begins Phase 3: a product-facing interface layer on top of the existing OpenClaw stack.

Phase 3 will:
- keep Slack as the internal operator/control surface
- add a Twilio-backed voice intake layer through OpenClaw
- add a separate branded HTML dashboard for visibility, approvals, run logs, and client-safe views
- preserve human-in-the-loop approval gates for any risky or live actions

Why

Slack is strong for internal operations but not the full product surface. Phase 3 creates a cleaner Twlv20-native experience for intake, visibility, approvals, and eventual client-safe access.

Scope

1. Finish current Phase 2 blockers first
- SMTP for Infisical
- migrate real secrets into Infisical
- rotate Backblaze B2 app key to bucket-scoped access
- check / close PR #1

2. Voice intake MVP
- install and enable OpenClaw voice-call plugin
- configure Twilio number and stable public webhook
- configure initial STT/TTS provider
- start with intake/summary mode, not full live AI receptionist
- inbound call -> transcript/summary -> Slack + run log
- ensure tenant-aware routing and approval-safe behavior

3. Internal dashboard MVP
- branded HTML dashboard (recommended stack: Next.js)
- login/auth for internal users first
- overview / command center
- tenant switcher
- run log / activity feed
- approvals queue
- call log
- workflow detail views
- daily brief / summary panel

4. Workflow actions and audit trail
- allow safe actions only in v1: approve, reject, assign owner, request revision, rerun summary
- log actor, tenant, timestamp, action, and outcome
- maintain strict tenant separation

Acceptance criteria

- current Phase 2 infra items are complete before Phase 3 build starts
- Twilio voice intake can reliably receive a call and generate a stored transcript/summary
- Slack receives the call summary
- dashboard shows recent runs, pending approvals, and recent calls
- dashboard is tenant-aware and does not leak data across tenants
- no risky action can execute without the intended approval gate
- Phase 3 direction is documented and actionable for implementation kickoff

Recommended sequence

1. close Phase 2 infra tasks
2. stabilize secrets / backups / repo state
3. ship voice intake MVP
4. ship internal dashboard MVP
5. wire workflow approvals into dashboard actions
6. add realtime voice and polish later

Do not include in v1

- broad autopilot execution
- client self-service editing of live systems
- production mutations without explicit human gate
- full AI receptionist behavior before intake MVP is proven

References

Detailed implementation plan saved locally at:
- plans/post-phase2-voice-dashboard-v1.md
