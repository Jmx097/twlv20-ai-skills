# Infra Build (Keeper) — QA Assessment Plan

Source: ClickUp list `02 — Infra Build (Keeper)` / `901415860610`.
Generated: 2026-05-12.

## Goal

Verify whether each infra task actually succeeded using repeatable, mostly read-only checks. Treat each check like a linter: it should return PASS / WARN / FAIL, produce evidence, and avoid making production changes.

## Manageable chunks

### Chunk 0 — Access + evidence setup

Purpose: prove we can safely inspect the droplet and collect outputs.

Tasks covered:
- `86b9qbguf` — Droplet Access

Acceptance gates:
- SSH reaches `162.243.252.92` as an approved non-root user.
- Hostname is `twlv20-prod`.
- Root SSH and password SSH are disabled.
- Evidence directory is created locally under `qa/infra-build-keeper/evidence/`.

Linter seed:
- `linters/00-access.sh`

---

### Chunk 1 — Base droplet hardening

Purpose: verify the production host is hardened before deeper app checks.

Tasks covered:
- `86b9m4z4w` — Droplet hardening — Caddy/TLS, SSH-key-only, fail2ban
- `86b9t4c3m` — Hardened checklist

Acceptance gates:
- Ubuntu 24.04 LTS.
- Expected resources roughly match 8 vCPU / 16 GB.
- Unattended upgrades installed/enabled.
- SSH hardening config exists and effective settings disable root/password login.
- UFW denies incoming by default, allows outgoing, limits SSH, allows 80/443.
- fail2ban active with SSH and Caddy jails/log monitoring.
- Caddy installed, active, and validates config.
- DNS A records for public hostnames resolve to droplet IP.
- HTTP(S) routes respond with valid TLS where domains are live.

Linter seed:
- `linters/01-droplet-hardening.sh`

---

### Chunk 2 — Postgres + tenant isolation

Purpose: verify the data spine and prove tenant data isolation fails closed.

Tasks covered:
- `86b9m4z55` — Postgres 16 + pgvector install
- `86b9m4z5v` — Tenant schema + RLS migration

Acceptance gates:
- PostgreSQL 16 installed and running.
- Postgres listens only on Unix socket / `127.0.0.1`, not public interfaces.
- `pgvector` extension available/installed.
- `twlv20` database exists.
- `twlv20_app` role exists, is non-superuser, and does not bypass RLS.
- Tenant-scoped tables have `tenant_id`, RLS enabled, FORCE RLS enabled, and policies using `current_setting('app.tenant_id')` or equivalent fail-closed logic.
- Four tenant rows exist.
- Pairwise RLS isolation test passes.

Linter seed:
- `linters/02-postgres-rls.sh`

---

### Chunk 3 — Secrets platform / Infisical

Purpose: verify Infisical is production-ish, scoped by tenant, and not a single shared secret bucket.

Tasks covered:
- `86b9m4z6q` — Infisical — self-hosted install + per-tenant scoping

Acceptance gates:
- Infisical compose/service is installed and running.
- Infisical is behind Caddy at the expected hostname with TLS.
- Infisical database and Redis exist and are not public.
- `/etc/infisical/.env` exists, is root-only readable, and contains required non-placeholder values.
- Encryption key backup has been confirmed by human evidence, without exposing the key.
- One project per tenant plus global project exists.
- Machine identities exist and are scoped per tenant.
- Runtime can fetch tenant-scoped secrets without cross-tenant access.

Linter seed:
- `linters/03-infisical.sh`

---

### Chunk 4 — Repo, CI, deploy hook

Purpose: verify the repo scaffold is present and the automation lane is safe.

Tasks covered:
- `86b9m4z8h` — GitHub repo scaffold + CI + deploy hook (`twlv20-ai-skills`)

Acceptance gates:
- Private repo exists and has the specified directory layout.
- CI workflow runs lint + unit tests on PR.
- Deploy workflow triggers only on merge/push to `main` and SSHes to droplet using a constrained key.
- Branch protection requires PR review and passing checks.
- No-op deploy has succeeded and evidence is linked.
- Runtime restart uses systemd and does not require interactive shell secrets.

Linter seed:
- `linters/04-repo-ci-deploy.sh`

---

### Chunk 5 — Backups + restore drill

Purpose: prove recovery, not just backup creation.

Tasks covered:
- `86b9m4z7r` — Weekly encrypted Postgres snapshots → S3 / Backblaze B2

Acceptance gates:
- Weekly Sunday 03:00 UTC systemd timer or cron exists.
- Dumps include both `twlv20` and `infisical` DBs in custom format (`pg_dump -Fc`).
- Dumps are GPG AES256 encrypted before upload.
- rclone remote points to private B2 bucket.
- Retention keeps the 8 most recent weekly snapshots.
- Failure notification is configured.
- Scratch restore drill has been performed and documented with timestamp + result.

Linter seed:
- `linters/05-backups-restore.sh`

## Run order

1. Run Chunk 0 first. Stop if SSH/auth is not proven.
2. Run Chunk 1. Stop on serious host hardening failures before touching DB/app checks.
3. Run Chunk 2. RLS is a release blocker: any fail-open result blocks signoff.
4. Run Chunk 3. Treat missing encryption-key custody evidence as blocked, not pass.
5. Run Chunk 4. Requires GitHub access/token or a local repo clone.
6. Run Chunk 5. A backup system is not accepted until restore evidence exists.

## Status rubric

- **PASS** — check succeeded with command output evidence.
- **WARN** — likely acceptable but needs human review, missing optional evidence, or slightly different implementation.
- **FAIL** — requirement not met or security posture is unsafe.
- **BLOCKED** — cannot inspect because credentials, hostnames, tokens, or non-secret human evidence are missing.

## Required inputs before full assessment

- SSH key/access for `keeper` or `jon` to `162.243.252.92`.
- Confirm public domain(s) mapped to Caddy/Infisical.
- GitHub access to `twlv20-ai-skills` or local clone path.
- Infisical admin/API access for project and machine identity checks.
- Backblaze/rclone read-only visibility or evidence exports.
- Non-secret proof that encryption keys/passphrases are stored in the approved vault/offline backup.
