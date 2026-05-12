#!/usr/bin/env bash
set -euo pipefail
: "${SSH_TARGET:=keeper@162.243.252.92}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)
remote(){ ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"; }
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; }
warn(){ echo "WARN $*"; }

remote 'grep -q "24.04" /etc/os-release' && pass "Ubuntu 24.04" || fail "Not Ubuntu 24.04"
remote 'test "$(nproc)" -ge 8' && pass "vCPU >= 8" || warn "vCPU < 8"
remote 'awk "/MemTotal/ {exit !(\$2 >= 15000000)}" /proc/meminfo' && pass "RAM roughly 16GB" || warn "RAM below expected"
remote 'systemctl is-enabled unattended-upgrades >/dev/null 2>&1 || dpkg -s unattended-upgrades >/dev/null 2>&1' && pass "unattended-upgrades present" || fail "unattended-upgrades missing"
remote 'sudo -n sshd -T | grep -qi "permitrootlogin no"' && pass "root SSH disabled" || warn "Could not confirm root SSH disabled; sudo may require password/TTY"
remote 'sudo -n sshd -T | grep -qi "passwordauthentication no"' && pass "password SSH disabled" || warn "Could not confirm password SSH disabled; sudo may require password/TTY"
remote 'sudo -n ufw status verbose' || warn "Could not read UFW with sudo -n"
remote 'systemctl is-active --quiet fail2ban' && pass "fail2ban active" || fail "fail2ban inactive"
remote 'systemctl is-active --quiet caddy && caddy version && sudo -n caddy validate --config /etc/caddy/Caddyfile' && pass "Caddy active/config valid" || warn "Caddy active/version OK but config validation may require sudo"
remote 'ss -tulpn | egrep ":(22|80|443)\b"' || warn "Could not confirm public ports"
