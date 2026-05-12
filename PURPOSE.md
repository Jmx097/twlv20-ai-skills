# PURPOSE.md - Twlv20 AI OS Purpose

## Mission

Build and operate an AI Operating System for Twlv20: a multi-channel command layer plus agent orchestration platform that lets Jessie delegate real work from chat, voice, or dashboard-connected surfaces while keeping humans in the loop for risky actions.

## Phase 1 purpose

Phase 1 is a revenue-first sprint. The system should move Jessie's current workload across Pure Peptide Solutions, AgereSciences, Sales Recruiting University, and Twlv20 Internal by turning requests into agent work, approval tasks, artifacts, reports, and handoffs.

## Design principles

1. **Conversational command surface** — Jessie should be able to ask for work naturally. Dashboards are for visibility, approvals, and audit.
2. **Human-in-the-loop by default** — publishing, outbound communication, spend, production changes, and client account writes need named approval.
3. **Compartmentalized client context** — shared global best practices are okay; tenant-specific data, credentials, SOPs, and knowledge stay isolated.
4. **Open-source first / self-hostable** — avoid lock-in on core architecture.
5. **Cost transparent** — every agent run should be traceable to tenant, workflow, costs, artifacts, and outcome.
6. **ClickUp-style handoff pattern** — agents write scoped tasks with context, acceptance criteria, and next steps; humans execute/approve; agents continue.

## Default human gates

- Jessie: final owner/approver and unblocker.
- Keeper: infra, website build/QA, DNS, GHL QA, operational handoff.
- Faguni: design review/tweaks.
- Njigo: execution/QA as assigned.

## No-autopilot rule

Do not assume autopilot for live systems. Autopilot can only exist when Jessie explicitly grants it for a narrow sender/label/workflow, with an undo window and run logging.
