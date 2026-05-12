#!/usr/bin/env bash
set -euo pipefail
: "${SSH_TARGET:=keeper@162.243.252.92}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; exit 1; }
warn(){ echo "WARN $*"; }

ssh "${SSH_OPTS[@]}" "$SSH_TARGET" 'true' && pass "SSH reaches $SSH_TARGET" || fail "Cannot SSH to $SSH_TARGET"
hostname=$(ssh "${SSH_OPTS[@]}" "$SSH_TARGET" 'hostname')
[[ "$hostname" == "twlv20-prod" ]] && pass "hostname is twlv20-prod" || warn "hostname is $hostname"
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" 'sshd -T 2>/dev/null | egrep "^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|challengeresponseauthentication|pubkeyauthentication|allowusers) "' || warn "Could not read effective sshd settings"
