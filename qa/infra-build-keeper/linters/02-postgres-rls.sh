#!/usr/bin/env bash
set -euo pipefail
: "${SSH_TARGET:=keeper@162.243.252.92}"
: "${DB_NAME:=twlv20}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)
remote(){ ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"; }
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; }
warn(){ echo "WARN $*"; }

remote 'psql -V | grep -q "16\."' && pass "Postgres client 16" || fail "psql 16 not found"
remote 'systemctl is-active --quiet postgresql' && pass "Postgres active" || fail "Postgres inactive"
remote "sudo -u postgres psql -d $DB_NAME -Atc \"select extname from pg_extension where extname='vector'\" | grep -qx vector" && pass "pgvector extension installed" || fail "pgvector extension missing"
remote "sudo -u postgres psql -Atc \"select rolname, rolsuper, rolbypassrls from pg_roles where rolname='twlv20_app'\"" | tee /tmp/twlv20_role_check.txt
remote "sudo -u postgres psql -d $DB_NAME -Atc \"select count(*) from tenants\"" || fail "Cannot query tenants"
remote "sudo -u postgres psql -d $DB_NAME -Atc \"select n.nspname||'.'||c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where c.relkind='r' and c.relrowsecurity and c.relforcerowsecurity order by 1\"" || warn "Could not list RLS tables"
remote "sudo -u postgres psql -d $DB_NAME -Atc \"select schemaname, tablename, policyname, qual, with_check from pg_policies where qual::text like '%app.tenant_id%' or with_check::text like '%app.tenant_id%' order by 1,2,3\"" || warn "Could not inspect tenant policies"
if remote 'test -f /opt/twlv20-ai-skills/infra/tests/rls_isolation.sql'; then
  remote "sudo -u postgres psql -v ON_ERROR_STOP=1 -d $DB_NAME -f /opt/twlv20-ai-skills/infra/tests/rls_isolation.sql" && pass "RLS isolation test passed" || fail "RLS isolation test failed"
else
  warn "RLS isolation SQL not found at expected path"
fi
