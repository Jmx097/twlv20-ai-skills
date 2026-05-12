#!/usr/bin/env bash
set -euo pipefail
: "${SSH_TARGET:=keeper@162.243.252.92}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)
remote(){ ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"; }
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; }
warn(){ echo "WARN $*"; }

remote 'systemctl list-timers --all | grep -Ei "backup|postgres|pg_dump" || crontab -l 2>/dev/null | grep -Ei "pg_dump|backup" || sudo grep -R "pg_dump" /etc/cron* /var/spool/cron 2>/dev/null' && pass "backup schedule found" || fail "No backup schedule found"
remote 'command -v pg_dump && command -v gpg && command -v rclone' && pass "pg_dump/gpg/rclone installed" || fail "required backup tooling missing"
remote 'grep -R "pg_dump .*\-Fc\|pg_dump .*--format=custom" /etc /opt /usr/local/bin 2>/dev/null | head' && pass "custom-format pg_dump referenced" || warn "Could not confirm pg_dump -Fc"
remote 'grep -R "AES256\|cipher-algo AES256" /etc /opt /usr/local/bin 2>/dev/null | head' && pass "AES256 encryption referenced" || warn "Could not confirm AES256 config"
remote 'rclone listremotes 2>/dev/null | grep -Ei "b2|backblaze|backup"' && pass "rclone B2-ish remote exists" || warn "rclone remote not confirmed"
remote 'grep -R "delete\|retention\|max-age\|8" /etc /opt /usr/local/bin 2>/dev/null | grep -Ei "backup|snapshot|rclone|pg_dump" | head' && pass "retention logic visible" || warn "retention logic not confirmed"
warn "Manual check required: restore drill evidence on scratch host, failure email/alert delivery evidence, non-secret GPG passphrase custody"
