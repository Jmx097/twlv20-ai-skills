# Infisical Assessment — 2026-05-12

Evidence directory: `qa/infra-build-keeper/evidence/infisical-audit-20260512T174628Z/`
Updated linter: `qa/infra-build-keeper/linters/03-infisical.sh`

## Verdict

Infisical is **mostly installed and operational**, but I would not mark the task fully complete yet.

It passes runtime, public route, SMTP, env-permission, project, and machine-identity existence checks. It still needs cleanup/confirmation around duplicate org/project setup, MFA, offline key custody, and an actual runtime cross-tenant secret access test.

## Passes

- `infisical-backend` container is running.
- Docker compose is present at `/opt/infisical/docker-compose.yml`.
- Infisical is listening locally on `127.0.0.1:8080`.
- Local `/api/status` returns OK.
- Public `infisical.twlv20.com` resolves to `162.243.252.92`.
- Public HTTPS `/api/status` returns OK through Caddy.
- Caddy route exists for `infisical.twlv20.com` → `127.0.0.1:8080`.
- `/etc/infisical/.env` is `600 root:root`.
- Expected env keys exist, redacted in evidence:
  - `ENCRYPTION_KEY`
  - `AUTH_SECRET`
  - `DB_CONNECTION_URI`
  - `REDIS_URL`
  - `SITE_URL`
  - SMTP keys
- Health reports:
  - `emailConfigured: true`
  - `inviteOnlySignup: true`
  - `redisConfigured: true`
- Postgres database `infisical` exists.
- Redis is active and local-only.
- One admin/user exists.
- Projects exist.
- Machine identities exist.
- Universal auth entries exist for identities.

## Important findings

### Duplicate org/project setup exists

The database has:

- `2` organizations, both named `Admin Org`.
- `10` projects: two sets of the expected five projects.
- `10` identities: two sets of the expected five runtime identities.

Expected project set appears twice:

- Global
- Pure Peptide Solutions
- AgereSciences
- SRU
- Twlv20 Internal

This likely came from running setup once before final admin signup and again after. It is not necessarily a security failure, but it creates operational ambiguity: agents/humans need to know which org/project IDs are canonical.

### Tenant scoping exists structurally, but cross-tenant denial is not proven

Membership summary shows each runtime identity has project membership only to its matching project, plus organization membership as `member`.

That is promising, but a real completion gate should prove:

1. Pure Peptide identity can read Pure Peptide secret.
2. Pure Peptide identity cannot read AgereSciences/SRU/Internal secrets.
3. Same pattern passes for each tenant identity.

### Admin MFA is not enabled

The admin user exists and is email-verified, but `isMfaEnabled = false`.

For a secrets manager, this should be fixed before real client secrets are migrated.

### Offline key custody is still a human evidence gate

The file exists and is protected, but the task requires custody of the encryption key outside the server. I cannot verify whether the `ENCRYPTION_KEY` is stored in the approved offline/password-manager process without a human attestation.

## Recommended status by sub-area

| Area | Status |
|---|---:|
| Runtime/container | PASS |
| Local health | PASS |
| Public DNS/TLS | PASS |
| SMTP configured | PASS |
| Env permissions | PASS |
| DB/Redis backing services | PASS |
| Admin exists | PASS |
| Tenant projects exist | WARN — duplicate sets |
| Machine identities exist | WARN — duplicate sets |
| Cross-tenant denial test | BLOCKED / NOT PROVEN |
| Offline encryption-key custody | BLOCKED / HUMAN PROOF REQUIRED |
| Admin MFA | FAIL / SHOULD ENABLE |

## Recommended next actions

1. Choose the canonical organization/project set — likely the one containing the real admin user.
2. Remove or archive the duplicate org/project/identity set if Infisical UI supports doing so safely.
3. Enable MFA on the admin account.
4. Confirm `ENCRYPTION_KEY` is backed up offline / in approved vault.
5. Seed one harmless sentinel secret per tenant, then test each machine identity can access only its own tenant’s sentinel.
6. Document canonical project IDs and identity names in the runbook without storing client secrets.

## Current QA recommendation

Do **not** mark `Infisical — self-hosted install + per-tenant scoping` complete yet.

Mark it as: **runtime installed, public route working, tenant scaffolding present, final tenant isolation QA pending.**
