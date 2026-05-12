# Tenant schema + RLS draft

This draft supports Phase 1 tenant isolation and Run-Log requirements.

Tables:
- `tenants`
- `runs`
- `artifacts`
- `approvals`
- `tenant_secrets_refs`

Tenant-scoped tables carry `tenant_id`, have RLS enabled, and force RLS. Policies compare `tenant_id` to `current_setting('app.tenant_id', true)` via `app_current_tenant_id()`.

Seed tenants:
- Pure Peptide Solutions: `pure-peptide`
- AgereSciences: `agere-sciences`
- Sales Recruiting University: `sru`
- Twlv20 Internal: `twlv20-internal`

This is a draft and should be reviewed before production application.
