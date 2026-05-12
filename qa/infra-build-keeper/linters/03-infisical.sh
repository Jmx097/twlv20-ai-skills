#!/usr/bin/env bash
set -euo pipefail
: "${INFISICAL_HOST:=infisical.twlv20.com}"
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; }
warn(){ echo "WARN $*"; }

systemctl is-active --quiet redis-server && pass "Redis active" || warn "Redis service not active"
docker ps --format '{{.Names}} {{.Status}}' | grep -q '^infisical-backend ' && pass "Infisical backend container running" || fail "Infisical backend container not running"
test -f /etc/infisical/.env && pass "/etc/infisical/.env exists" || fail "Infisical env missing"
[[ "$(stat -c %a /etc/infisical/.env)" == "600" ]] && pass "Infisical env perms 600" || fail "Infisical env perms not 600"
for key in ENCRYPTION_KEY AUTH_SECRET DB_CONNECTION_URI REDIS_URL SITE_URL SMTP_HOST; do
  grep -q "^${key}=" /etc/infisical/.env && pass "env key present: $key" || warn "env key missing: $key"
done
curl -fsS http://127.0.0.1:8080/api/status | grep -q '"message":"Ok"' && pass "local /api/status OK" || fail "local /api/status failed"
if [[ -n "$INFISICAL_HOST" ]]; then
  getent ahosts "$INFISICAL_HOST" | grep -q '162.243.252.92' && pass "$INFISICAL_HOST resolves to droplet" || warn "$INFISICAL_HOST does not resolve to droplet"
  curl -fsS "https://${INFISICAL_HOST}/api/status" | grep -q '"message":"Ok"' && pass "public HTTPS /api/status OK" || warn "public HTTPS /api/status failed"
fi
sudo -u postgres psql -d infisical -Atc "select count(*) from users" | grep -qE '^[1-9]' && pass "admin/user exists" || warn "no Infisical users found"
projects=$(sudo -u postgres psql -d infisical -Atc "select count(*) from projects")
identities=$(sudo -u postgres psql -d infisical -Atc "select count(*) from identities")
[[ "$projects" -ge 5 ]] && pass "projects exist: $projects" || warn "expected >=5 projects, found $projects"
[[ "$identities" -ge 5 ]] && pass "machine identities exist: $identities" || warn "expected >=5 identities, found $identities"
# Flag duplicate org/project setup for human cleanup.
dupe_projects=$(sudo -u postgres psql -d infisical -Atc "select count(*) from (select name from projects group by name having count(*)>1) x")
[[ "$dupe_projects" == "0" ]] && pass "no duplicate project names" || warn "duplicate project names detected"
warn "Manual proof still required: offline ENCRYPTION_KEY custody and runtime secret fetch/cross-tenant denial test"
