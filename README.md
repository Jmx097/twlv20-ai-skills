# twlv20-ai-skills

Phase 1 scaffold for the Twlv20 AI OS: tenant-aware skills, runtime host, infra SQL, CI, and deploy wiring.

## Layout

- `skills/` — tenant/global skill definitions and tests
- `runtime/` — Node.js runtime host scaffold
- `infra/` — Postgres schema, migrations, and RLS tests
- `docs/` — architecture and runbooks
- `.github/workflows/` — CI and deploy workflows

## Current tenants

- `pure-peptide` — Pure Peptide Solutions
- `agere-sciences` — AgereSciences
- `sru` — Sales Recruiting University
- `twlv20-internal` — Twlv20 Internal

## Local checks

```bash
cd runtime
npm ci
npm run lint
npm test
npm run build
```
