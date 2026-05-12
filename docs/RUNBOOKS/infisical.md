# Infisical runbook

Self-hosted Infisical foundation for Twlv20 AI OS.

## Current status

Infisical is installed locally on `twlv20-prod` and listening on `127.0.0.1:8080`.

The public `infisical.<domain>` URL is blocked until Caddy/domain/DNS are completed in the hardening task.

## Production locations

- Compose directory: `/opt/infisical`
- Compose file: `/opt/infisical/docker-compose.yml`
- Root-only environment file: `/etc/infisical/.env`
- Container: `infisical-backend`
- Database: Postgres database `infisical`
- Database role: `infisical_app`
- Redis: apt-managed `redis-server`, bound to localhost only

## Secret/key locations

`/etc/infisical/.env` is root-only and contains:

- `ENCRYPTION_KEY` — Infisical master encryption key; must be backed up offline before real secrets are stored.
- `AUTH_SECRET`
- `DB_CONNECTION_URI`
- `REDIS_URL`

Do not commit, paste, or copy these values into ClickUp/chat/docs. Move custody into the approved offline password manager process once Jessie confirms ownership.

## Health checks

```bash
sudo docker ps --filter name=infisical-backend
sudo docker logs --tail 100 infisical-backend
curl -fsS http://127.0.0.1:8080/api/status
ss -tlnp | egrep ':(8080|6379|5432)'
```

Expected `/api/status` fields while local-only:

- `message: Ok`
- `redisConfigured: true`
- `emailConfigured: false` until SMTP is configured

## Restart

```bash
cd /opt/infisical
sudo docker compose up -d
```

## Admin signup

Until Caddy/DNS are configured, use an SSH tunnel:

```bash
ssh -N -L 8080:127.0.0.1:8080 root@162.243.252.92
```

Then open:

```text
http://127.0.0.1:8080/admin/signup
```

After the first admin account exists, create projects:

- Global
- Pure Peptide Solutions
- AgereSciences
- Sales Recruiting University
- Twlv20 Internal

Then create Machine Identities scoped per project/tenant. Do not use deprecated Service Tokens.

## Blocked items

- Public URL/TLS: needs Caddy + DNS for `infisical.<domain>`.
- SMTP/email: needs approved SMTP provider/credentials.
- Offline backup: Jessie must confirm where the `/etc/infisical/.env` encryption key is stored offline.
- Secret migration: do not store real client/API secrets until admin account, project structure, machine identities, and offline key backup are confirmed.
