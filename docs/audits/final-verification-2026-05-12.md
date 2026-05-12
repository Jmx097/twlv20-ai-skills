# Twlv20 Infra Build Verification — 2026-05-12

Verified against `twlv20-prod` and ClickUp list `901415860610`.

## ClickUp status

- `86b9t4c3m` — Infra Build hardened checklist — `to do` at time of pre-report check; used as final checklist wrapper.
- `86b9qbguf` — Droplet Access — `for qa`.
- `86b9m4z8h` — GitHub repo scaffold + CI + deploy hook — `for qa`.
- `86b9m4z7r` — Weekly encrypted Postgres snapshots → Backblaze B2 — `for qa`.
- `86b9m4z6q` — Infisical self-hosted install + per-tenant scoping — `for qa`.
- `86b9m4z5v` — Tenant schema + RLS migration — `for qa`.
- `86b9m4z4w` — Droplet hardening — `for qa`.

## GitHub

Repository: `Twlv20-AI/twlv20-ai-skills`

- Visibility: private.
- Default branch: `main`.
- Latest verified GitHub Actions:
  - CI: success.
  - Deploy: success.
- Runtime service deployed from commit `ce5180a` during the previous deploy verification.

Known blocker: branch protection could not be enabled for a private repo on the current GitHub plan. GitHub returned HTTP 403 requiring GitHub Pro or public visibility.

## Droplet hardening

Host: `twlv20-prod` / `162.243.252.92`

Verified effective SSH settings:

- `permitrootlogin no`
- `passwordauthentication no`
- `pubkeyauthentication yes`
- `kbdinteractiveauthentication no`
- `AllowUsers keeper jon twlv20-deploy`

Verified UFW:

- active
- default incoming deny
- default outgoing allow
- `22/tcp` limit
- `80/tcp` allow
- `443/tcp` allow

Verified services active:

- `ssh`
- `caddy`
- `fail2ban`
- `ufw`
- `unattended-upgrades`
- `postgresql@16-main`
- `redis-server`
- `docker`
- `twlv20-ai-runtime.service`

Verified fail2ban jails:

- `sshd`
- `caddy-status`

Verified Caddy local response:

```text
twlv20-prod Caddy online. Public host routing pending DNS/domain confirmation.
```

## Postgres + RLS

Verified production DB `twlv20`:

- tenant count: `4`
- extensions present: `pgcrypto`, `vector`
- prior RLS isolation test passed and is documented in the ClickUp audit.

## Backups

Verified systemd timer:

```text
NEXT                          LEFT LAST PASSED UNIT                         ACTIVATES
Sun 2026-05-17 02:00:00 UTC 5 days -         - twlv20-postgres-backup.timer twlv20-postgres-backup.service
```

Verified latest manual backup log includes successful upload:

```text
postgres/weekly/2026-05-11/weekly-postgres-2026-05-11-2336UTC.sql.gz.gpg
```

Prior restore drill succeeded: download → decrypt → restore to throwaway DB → verify → drop throwaway DB.

## Infisical

Verified local-only Infisical status:

```json
{"message":"Ok","emailConfigured":false,"inviteOnlySignup":true,"redisConfigured":true}
```

Verified `infisical-backend` container is running.

Known blockers:

- Public `infisical.<domain>` route needs DNS/domain confirmation.
- SMTP is not configured.
- First admin signup, projects, machine identities, and cross-tenant secret checks remain pending.
- Offline backup/custody of `/etc/infisical/.env` / `ENCRYPTION_KEY` must be confirmed before real secrets are migrated.

## Remaining work

1. Confirm real domain/DNS records pointing at `162.243.252.92` for public Caddy routes.
2. Complete Infisical first-admin setup.
3. Create Infisical projects and machine identities.
4. Back up Infisical encryption key offline.
5. Migrate real secrets only after the key backup and project/identity checks.
6. Rotate/clean up exposed legacy credentials now that root SSH is disabled.
7. Resolve GitHub branch protection limitation via GitHub plan upgrade or policy decision.

## Credential cleanup update — 2026-05-12

The original source Word documents were removed from the GitHub repo after hardening because they may contain obsolete access handoff material. Current access instructions are maintained in the runbooks and ClickUp without secrets.

ClickUp `Droplet Access` was sanitized to remove exposed credential material and now only documents key-only access.
