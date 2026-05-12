# Post-Fix Summary — Infra Build Keeper

Date: 2026-05-12 UTC

## Fixed

### SSH hardening

Effective settings now verify:

```text
permitrootlogin no
passwordauthentication no
kbdinteractiveauthentication no
pubkeyauthentication yes
maxauthtries 3
logingracetime 20
allowusers keeper
allowusers jon
allowusers twlv20-deploy
```

Backups/evidence:

- `qa/infra-build-keeper/evidence/fix-20260512T173926Z/`
- `qa/infra-build-keeper/evidence/post-fix-20260512T173956Z/post-fix-summary.log`

### UFW SSH rate limiting

UFW now shows:

```text
22/tcp LIMIT IN Anywhere
22/tcp (v6) LIMIT IN Anywhere (v6)
```

### Backup script alignment

Updated `/usr/local/sbin/twlv20-postgres-backup` to:

- include both `twlv20` and `infisical`
- use `pg_dump --format=custom`
- encrypt each dump with GPG AES256
- upload each encrypted dump to B2 through the existing helper
- run retention after uploads

Updated timer to:

```text
Sun *-*-* 03:00:00 UTC
```

Validation passed:

- `systemd-analyze verify`
- `bash -n /usr/local/sbin/twlv20-postgres-backup`
- timer enabled and next run shows Sunday 03:00 UTC

Backups/evidence:

- `qa/infra-build-keeper/evidence/fix-20260512T173945Z-backups/`
- `qa/infra-build-keeper/evidence/post-fix-20260512T173956Z/post-fix-summary.log`

## Reverified

Postgres/RLS linter still passes after fixes:

- Postgres 16 active
- pgvector installed
- `twlv20_app` non-superuser / non-BYPASSRLS
- 4 tenants
- RLS isolation test passed

## Still open

1. Droplet size still needs a decision: observed 2 vCPU / about 8 GB vs task spec 8 vCPU / 16 GB.
2. Backup script was validated but not manually executed/upload-tested after the fix.
3. Infisical tenant projects, machine identities, and cross-tenant secret denial checks remain unproven.
4. GitHub branch protection remains blocked by plan limitation unless Twlv20 upgrades or accepts alternate control.
5. ClickUp API token should be rotated because it appeared in chat/transcript context.
