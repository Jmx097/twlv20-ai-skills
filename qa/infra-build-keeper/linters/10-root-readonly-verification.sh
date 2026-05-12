#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-/root/.openclaw/workspace/qa/infra-build-keeper/evidence/root-readonly-$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$OUT_DIR"

run() {
  local name="$1"; shift
  echo "===== $name =====" | tee -a "$OUT_DIR/summary.log"
  { "$@"; } >"$OUT_DIR/$name.out" 2>"$OUT_DIR/$name.err" || true
  sed -n '1,120p' "$OUT_DIR/$name.out" | tee -a "$OUT_DIR/summary.log"
  if [[ -s "$OUT_DIR/$name.err" ]]; then
    echo "--- stderr ---" | tee -a "$OUT_DIR/summary.log"
    sed -n '1,80p' "$OUT_DIR/$name.err" | tee -a "$OUT_DIR/summary.log"
  fi
  echo | tee -a "$OUT_DIR/summary.log"
}

# Host/resources
run host-info bash -lc 'hostname; cat /etc/os-release; echo "nproc=$(nproc)"; awk "/MemTotal/ {print \"mem_kb=\"$2}" /proc/meminfo; timedatectl status --no-pager'
run listening-ports bash -lc 'ss -ltnup'

# SSH hardening, no secrets
run sshd-effective bash -lc 'sshd -T | egrep "^(permitrootlogin|passwordauthentication|challengeresponseauthentication|kbdinteractiveauthentication|pubkeyauthentication|maxauthtries|logingracetime|allowusers) "'
run sshd-config-files bash -lc 'ls -la /etc/ssh/sshd_config /etc/ssh/sshd_config.d || true; grep -RniE "^(PermitRootLogin|PasswordAuthentication|ChallengeResponseAuthentication|KbdInteractiveAuthentication|PubkeyAuthentication|MaxAuthTries|LoginGraceTime|AllowUsers)" /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null || true'

# Firewall/fail2ban/Caddy
run ufw-status bash -lc 'ufw status verbose; ufw status numbered'
run fail2ban-status bash -lc 'systemctl is-active fail2ban; fail2ban-client status; for jail in $(fail2ban-client status 2>/dev/null | sed -n "s/.*Jail list:[[:space:]]*//p" | tr "," " "); do echo "--- $jail"; fail2ban-client status "$jail"; done'
run caddy-status bash -lc 'systemctl is-active caddy; caddy version; caddy validate --config /etc/caddy/Caddyfile; sed -n "1,220p" /etc/caddy/Caddyfile'

# Postgres/RLS
run postgres-listen bash -lc 'systemctl is-active postgresql; ss -ltnp | grep -E ":5432|postgres" || true; sudo -u postgres psql -Atc "show listen_addresses; show port;"'
run postgres-roles-dbs bash -lc 'sudo -u postgres psql -Atc "select datname from pg_database where datistemplate=false order by 1;"; sudo -u postgres psql -Atc "select rolname, rolsuper, rolbypassrls from pg_roles where rolname like '\''twlv20%'\'' or rolname like '\''infisical%'\'' order by 1;"'
run postgres-rls bash -lc 'sudo -u postgres psql -d twlv20 -Atc "select n.nspname||'\''.'\''||c.relname, c.relrowsecurity, c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where c.relkind='\''r'\'' and n.nspname not in ('\''pg_catalog'\'','\''information_schema'\'') order by 1;"; sudo -u postgres psql -d twlv20 -Atc "select schemaname, tablename, policyname, qual, with_check from pg_policies order by 1,2,3;"'

# Infisical: redact env values, show keys/perms only
run infisical-files bash -lc 'ls -ld /etc/infisical /opt/infisical 2>/dev/null || true; find /etc/infisical /opt/infisical -maxdepth 2 -type f -printf "%m %u:%g %p\n" 2>/dev/null | sort; if test -f /etc/infisical/.env; then echo "--- .env keys only ---"; sed -n "s/^\([^#=][^=]*\)=.*/\1=<redacted>/p" /etc/infisical/.env | sort; fi'
run infisical-runtime bash -lc 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -iE "infisical|redis|postgres" || true; docker compose ls 2>/dev/null || true; curl -fsS http://127.0.0.1:8080/api/status 2>/dev/null || curl -fsS http://127.0.0.1:3000/api/status 2>/dev/null || true'

# Backups: redact secret values; inspect scripts/units
run backup-units bash -lc 'systemctl list-timers --all | grep -Ei "twlv20|postgres|backup" || true; systemctl cat twlv20-postgres-backup.timer twlv20-postgres-backup.service twlv20-postgres-backup-alert@.service 2>/dev/null || true'
run backup-scripts bash -lc 'for f in /usr/local/sbin/twlv20-postgres-backup /usr/local/sbin/twlv20-pg-b2.py /usr/local/sbin/twlv20-postgres-backup-alert; do echo "===== $f ====="; if test -f "$f"; then ls -l "$f"; sed -E "s/(password|passphrase|applicationKey|key|secret|token)([A-Z_]*=|[[:space:]]*[:=][[:space:]]*)[^[:space:]'\''\"]+/\1\2<redacted>/Ig" "$f"; else echo missing; fi; done'
run backup-secret-files bash -lc 'find /root/.secrets -maxdepth 1 -type f -printf "%m %u:%g %p\n" 2>/dev/null | sort; for f in /root/.secrets/b2-backup.env /root/.secrets/pg-backup-gpg.pass; do if test -f "$f"; then echo "===== $f keys/perms only ====="; stat -c "%a %U:%G %n" "$f"; if [[ "$f" == *.env ]]; then sed -n "s/^\([^#=][^=]*\)=.*/\1=<redacted>/p" "$f" | sort; else echo "present_bytes=$(wc -c < "$f")"; fi; fi; done'
run backup-logs bash -lc 'journalctl -u twlv20-postgres-backup.service -n 160 --no-pager 2>/dev/null || true; journalctl -u "twlv20-postgres-backup-alert@*" -n 80 --no-pager 2>/dev/null || true'

# GitHub/repo local
run repo-local bash -lc 'cd /opt/twlv20-ai-skills 2>/dev/null && git -c safe.directory=/opt/twlv20-ai-skills status --short && git -c safe.directory=/opt/twlv20-ai-skills log -1 --oneline && find .github/workflows infra docs -maxdepth 3 -type f | sort | sed -n "1,160p" || true'

cat <<EOF | tee -a "$OUT_DIR/summary.log"
===== DONE =====
Evidence directory: $OUT_DIR
Summary: $OUT_DIR/summary.log
EOF
