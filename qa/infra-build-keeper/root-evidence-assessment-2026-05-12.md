# Root Evidence Assessment — Infra Build (Keeper)

Date: 2026-05-12 UTC
Evidence: `qa/infra-build-keeper/evidence/root-readonly-20260512T173357Z/summary.log`

## Critical findings

### 1. SSH hardening failed

Effective sshd settings show:

```text
permitrootlogin yes
passwordauthentication yes
allowusers keeper
allowusers jon
allowusers twlv20-deploy
allowusers root
```

Config files also explicitly set root/password login to yes:

```text
/etc/ssh/sshd_config: PermitRootLogin yes
/etc/ssh/sshd_config.d/50-cloud-init.conf: PasswordAuthentication yes
/etc/ssh/sshd_config.d/60-cloudimg-settings.conf: PasswordAuthentication yes
/etc/ssh/sshd_config.d/99-twlv20-hardening.conf: PermitRootLogin yes
/etc/ssh/sshd_config.d/99-twlv20-hardening.conf: PasswordAuthentication yes
/etc/ssh/sshd_config.d/99-twlv20-hardening.conf: AllowUsers keeper jon twlv20-deploy root
```

This directly fails the ClickUp hardening requirement:

- root SSH disabled
- password SSH disabled
- key-only SSH
- AllowUsers should exclude root

Severity: **CRITICAL**

Recommended action: remediate immediately after confirming `keeper` and/or `jon` key-based sudo access works.

---

### 2. Droplet size does not match spec

Observed:

```text
nproc=2
```

Earlier direct probe observed memory around 8 GB. The task requires `8 vCPU / 16 GB / NVMe`.

Severity: **HIGH / ACCEPTANCE MISMATCH**

Recommended action: either resize droplet or revise acceptance criteria.

---

### 3. UFW SSH rule is not rate-limited

Observed:

```text
22/tcp ALLOW IN Anywhere
22/tcp (v6) ALLOW IN Anywhere (v6)
```

The checklist expects `ufw limit 22/tcp`.

Severity: **HIGH**

Recommended action: replace SSH allow rules with limit rules after confirming stable access.

---

### 4. Backup task partially passes but differs from spec

Passes:

- systemd timer exists
- failure alert unit exists
- backup script exists and is root-only executable
- B2 env/passphrase files are root-only `600`
- AES256 GPG encryption is used
- retention helper exists
- B2 helper supports upload/retention/latest/download

Gaps:

- Timer is Sunday `02:00 UTC`; task says Sunday `03:00 UTC`.
- Script dumps only `twlv20`, not both `twlv20` and `infisical`.
- Script uses `pg_dump --format=plain`, not `pg_dump -Fc` custom format.
- Script uses gzip + plain SQL, not custom-format dump.
- No journal entries were found for `twlv20-postgres-backup.service`, despite prior docs claiming a manual backup.
- Implementation uses custom B2 helper, not rclone. This may be acceptable if intentionally approved, but it is not what the task specifies.

Severity: **HIGH / PARTIAL FAIL**

---

### 5. Infisical base runtime passes, but tenant-scoping remains unproven

Passes:

- `/etc/infisical` and `/opt/infisical` are root-only.
- `/etc/infisical/.env` is `600 root:root`.
- Required env keys exist and were redacted.
- Docker compose shows `infisical running(1)`.
- Local health is OK.
- `emailConfigured: true`.
- `inviteOnlySignup: true`.
- Redis configured.
- Caddy route exists for `infisical.twlv20.com`.

Still unproven:

- First admin setup complete.
- One project per tenant + global project.
- Machine identities scoped per tenant.
- Runtime can fetch tenant-scoped secrets.
- Cross-tenant secret denial test.
- Offline custody of `ENCRYPTION_KEY` confirmed by human evidence.

Severity: **MEDIUM / INCOMPLETE**

---

### 6. Postgres and RLS mostly pass, with schema-scope caveat

Passes:

- Postgres active.
- Listens only on localhost / loopback.
- Databases include `twlv20` and `infisical`.
- Roles `twlv20_app` and `infisical_app` are non-superuser and non-BYPASSRLS.
- RLS/FORCE RLS are enabled on implemented tenant tables.
- Policies use tenant isolation helper.
- Prior RLS isolation linter passed.

Caveat:

Implemented tenant-scoped tables shown are:

- `approvals`
- `artifacts`
- `runs`
- `tenant_secrets_refs`

The ClickUp spec named a broader set. Confirm whether this narrowed schema is intentional.

Severity: **LOW/MEDIUM CAVEAT**

---

### 7. Public exposure notes

Listening externally:

- `22/tcp` SSH on IPv4/IPv6
- `80/tcp` Caddy
- `443/tcp` Caddy
- `25/tcp` Postfix on IPv4/IPv6

Local-only:

- Postgres `5432`
- Redis `6379`
- OpenClaw dashboard `18788/18790`
- Infisical backend `8080`

Port 25 exposure should be intentional. If only outbound alert mail is needed, inbound SMTP probably does not need to be public.

## Task-by-task status recommendation

| ClickUp task | QA status | Recommendation |
|---|---:|---|
| Droplet Access | FAIL / SECURITY | Root password SSH is currently enabled; sanitize/rotate exposed credentials and disable root/password SSH. |
| Droplet hardening | FAIL | SSH hardening and UFW limit requirements are not met; droplet size mismatch. |
| Hardened checklist | FAIL | Wrapper checklist cannot pass while SSH/root/password/UFW/size fail. |
| Postgres 16 + pgvector | PASS with caveat | Core install passes; confirm memory sizing decision. |
| Tenant schema + RLS | PASS with schema caveat | Isolation passes; confirm intended table scope. |
| Infisical | INCOMPLETE | Runtime up, but tenant project/machine identity tests remain. |
| GitHub repo scaffold + CI/deploy | PARTIAL | Workflows exist; branch protection remains blocked by GitHub plan. |
| Backups | PARTIAL FAIL | Encryption/B2 pieces exist, but dump format, DB coverage, schedule, and log evidence fail task spec. |

## Immediate remediation priority

1. Confirm key-based `keeper` or `jon` login and sudo works in a second terminal.
2. Disable root SSH and password SSH.
3. Replace UFW SSH allow with limit.
4. Rotate the ClickUp API token because it appears in terminal transcript/log context.
5. Decide whether to resize droplet to 8 vCPU / 16 GB or revise the ClickUp spec.
6. Fix backup script to include both `twlv20` and `infisical`, use custom-format dumps, and align schedule.
7. Complete Infisical tenant-scoping tests.
