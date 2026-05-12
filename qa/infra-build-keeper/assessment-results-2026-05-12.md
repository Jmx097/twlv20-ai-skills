# Infra Build (Keeper) — Assessment Results

Date: 2026-05-12 UTC
Target: `keeper@162.243.252.92` / `twlv20-prod`
Source list: ClickUp `02 — Infra Build (Keeper)` / `901415860610`

## Executive summary

The infra build is partially successful and ready for focused QA, not blanket signoff.

Strong passes:
- SSH access works for `keeper`.
- Hostname is `twlv20-prod`.
- Ubuntu 24.04 is installed.
- UFW is active with default incoming deny and HTTP/HTTPS/SSH allowed.
- fail2ban is active.
- Caddy is active and config validates.
- PostgreSQL 16 is active.
- pgvector is installed.
- `twlv20_app` exists and is not superuser / does not bypass RLS.
- Four tenants exist.
- RLS isolation test passes.
- Backup timer exists and prior docs claim a successful manual upload + restore drill.
- Repo workflows exist for CI and deploy.

Primary blockers / gaps:
- Droplet resources do **not** match task spec: observed `2` vCPU and ~`8 GB` RAM, while ClickUp specifies `8 vCPU / 16 GB`.
- SSH hardening could not be directly reverified via linter because non-interactive sudo is limited, but repo audit docs claim the effective settings were previously verified.
- UFW has `22/tcp ALLOW`, not `LIMIT`, despite task/audit expectation saying SSH should be limited.
- Infisical exists but is incomplete: env path is root-only/no readable confirmation, public route/domain unconfirmed, SMTP/admin/projects/machine identities/tenant secret checks pending.
- GitHub branch protection is blocked by plan limitation per existing audit doc.
- Backup implementation differs from initial linter assumptions: no `rclone` confirmed; runbook uses custom B2 helper. Need direct script inspection or root evidence for final backup signoff.

## Chunk results

### Chunk 0 — Access + evidence setup

Status: PASS

Evidence:
- `qa/infra-build-keeper/evidence/00-access.log`

Findings:
- SSH reaches `keeper@162.243.252.92`.
- `hostname` returns `twlv20-prod`.
- Effective sshd settings require sudo; initial linter could not read them.

### Chunk 1 — Base droplet hardening

Status: WARN / PARTIAL

Evidence:
- `qa/infra-build-keeper/evidence/01-droplet-hardening.log`
- `qa/infra-build-keeper/evidence/01-droplet-hardening.rerun.log`
- `qa/infra-build-keeper/evidence/manual-probes-2026-05-12.log`

Passes:
- Ubuntu 24.04.
- unattended-upgrades present.
- UFW active.
- fail2ban active.
- Caddy active and config valid.
- Ports 22, 80, 443 are listening.

Warnings/fails:
- Observed resources: `2` vCPU, `8132496` KB RAM. This fails the `8 vCPU / 16 GB` requirement.
- UFW output shows `22/tcp ALLOW`, not `LIMIT`.
- Could not directly confirm root/password SSH disabled from the linter because effective sshd settings require sudo. Existing remote audit document claims:
  - `permitrootlogin no`
  - `passwordauthentication no`
  - `pubkeyauthentication yes`
  - `kbdinteractiveauthentication no`
  - `AllowUsers keeper jon twlv20-deploy`

### Chunk 2 — Postgres + tenant RLS isolation

Status: PASS, pending deeper schema coverage review

Evidence:
- `qa/infra-build-keeper/evidence/02-postgres-rls.log`

Passes:
- Postgres client 16.
- Postgres service active.
- `pgvector` extension installed.
- `twlv20_app|f|f` confirms app role is not superuser and does not bypass RLS.
- Tenant count: `4`.
- RLS isolation test passed.

Review note:
- Linter listed RLS/FORCE RLS tables as `approvals`, `artifacts`, `runs`, `tenant_secrets_refs`. The ClickUp spec names a broader set: `users`, `credentials`, `skills`, `kb_docs`, `agents`, `runs`, `approvals`, `artifacts`. Need a schema diff to determine if the implemented schema intentionally narrowed scope or if tables are missing.

### Chunk 3 — Infisical / secrets platform

Status: BLOCKED / INCOMPLETE

Evidence:
- `qa/infra-build-keeper/evidence/03-infisical.log`
- `qa/infra-build-keeper/evidence/manual-probes-2026-05-12.log`
- Remote doc: `/opt/twlv20-ai-skills/docs/audits/final-verification-2026-05-12.md`

Findings:
- `/etc/infisical` and `/opt/infisical` exist and are root-only.
- `/etc/infisical/.env` could not be read/listed by the linter due to permission denial; this is good for secrecy but blocks value validation.
- Existing audit says Infisical backend container is running and local health returns OK.

Known blockers from remote audit:
- Public `infisical.<domain>` route needs DNS/domain confirmation.
- SMTP is not configured.
- First admin signup pending.
- Projects, machine identities, and cross-tenant secret checks remain pending.
- Offline backup/custody of encryption key must be confirmed before real secrets are migrated.

### Chunk 4 — GitHub repo + CI/deploy

Status: PARTIAL PASS / POLICY BLOCKER

Evidence:
- `qa/infra-build-keeper/evidence/repo-ci-deploy-probe.log`

Passes:
- `/opt/twlv20-ai-skills/.github/workflows/ci.yml` exists.
- CI runs on `pull_request` and `push` to `main`.
- CI performs `npm ci`, `npm run lint`, `npm run build`, `npm test`.
- `deploy.yml` exists.
- Deploy runs on push to `main` and `workflow_dispatch`.
- Deploy uses `appleboy/ssh-action` and restarts `twlv20-ai-runtime.service`.
- Runtime scripts include `build`, `lint`, `test`, `start`.

Warnings/blockers:
- `git status` could not run as `keeper` because the repo has dubious ownership. This is not necessarily a deploy failure, but it means Keeper cannot inspect git state without adding a safe.directory exception or using the owning account.
- Existing audit says branch protection could not be enabled because GitHub returned HTTP 403 requiring GitHub Pro or public visibility.

### Chunk 5 — Backups + restore drill

Status: PARTIAL PASS / NEED ROOT EVIDENCE

Evidence:
- `qa/infra-build-keeper/evidence/05-backups-restore.log`
- `qa/infra-build-keeper/evidence/manual-probes-2026-05-12.log`

Passes:
- `twlv20-postgres-backup.timer` exists.
- Timer schedule is Sunday 02:00 UTC, not Sunday 03:00 UTC from the ClickUp task.
- Service runs `/usr/local/sbin/twlv20-postgres-backup`.
- `pg_dump` and `gpg` are installed.
- Backup runbook documents B2 helper, secret paths, retention, restore drill, and alert script.
- Existing audit claims prior restore drill succeeded.

Warnings/blockers:
- `rclone` was not installed/confirmed. The implementation appears to use custom B2 helper `/usr/local/sbin/twlv20-pg-b2.py`, which may be acceptable but differs from the task's rclone wording.
- Direct inspection of `/usr/local/sbin/twlv20-postgres-backup` was not available without root.
- Need non-secret root evidence for encryption flags, upload destination, retention behavior, and alert delivery.

## Recommended next chunks

1. **Resource mismatch decision** — decide whether the droplet spec should be upgraded to 8 vCPU / 16 GB or the ClickUp acceptance criteria revised to 2 vCPU / 8 GB.
2. **Root-assisted verification packet** — ask Keeper to run a bounded read-only command bundle as root and paste output. This should confirm sshd effective settings, UFW limit rule, backup script internals without secrets, Infisical service status, and Postgres listen addresses.
3. **Infisical completion chunk** — complete admin/project/machine identity setup, then run a tenant isolation secret fetch test.
4. **GitHub policy chunk** — either upgrade GitHub plan for branch protection or explicitly accept an alternate control.
5. **Backup finalization chunk** — verify schedule mismatch, backup script, B2 object listing, retention, and restore drill evidence.

## Signoff recommendation

Do not mark the whole list complete yet.

Safe to mark as likely QA-pass after evidence review:
- Droplet Access
- Postgres 16 + pgvector install
- Tenant schema + RLS migration, with schema-scope caveat

Keep open / blocked:
- Droplet hardening until resource mismatch and UFW SSH limit are resolved/accepted.
- Infisical until tenant-scoped projects/machine identities and key custody are proven.
- GitHub repo scaffold until branch protection decision is made.
- Backups until script/restore evidence is verified by root-readable output.
