# Twlv20 AI OS Architecture

The repo is organized around tenant-safe execution:

- Runtime requests set `app.tenant_id` before tenant-scoped DB reads/writes.
- Tenant-scoped Postgres tables use forced RLS policies.
- Skills are separated by tenant folder to reduce context bleed.
- Human-in-the-loop approval remains required for production/client writes, publishing, outbound messaging, spend, and irreversible changes.

The production Postgres foundation and RLS schema are tracked under `infra/`.
