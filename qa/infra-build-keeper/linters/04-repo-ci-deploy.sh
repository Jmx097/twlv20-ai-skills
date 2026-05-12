#!/usr/bin/env bash
set -euo pipefail
: "${REPO_DIR:=/root/.openclaw/workspace/twlv20-ai-skills}"
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; }
warn(){ echo "WARN $*"; }

[[ -d "$REPO_DIR/.git" ]] && pass "Repo clone exists: $REPO_DIR" || fail "Set REPO_DIR to local twlv20-ai-skills clone"
cd "$REPO_DIR"
for p in .github/workflows/ci.yml .github/workflows/deploy.yml infra/schema.sql infra/migrations infra/tests/rls_isolation.sql runtime/package.json runtime/tsconfig.json skills/global docs; do
  [[ -e "$p" ]] && pass "layout: $p" || fail "missing: $p"
done
grep -R "pull_request" .github/workflows/ci.yml >/dev/null && pass "CI runs on PR" || fail "CI PR trigger missing"
grep -RE "npm (run )?(test|lint)|pnpm (test|lint)|yarn (test|lint)" .github/workflows/ci.yml >/dev/null && pass "CI includes lint/test-ish command" || warn "CI lint/test command not obvious"
grep -R "branches:.*main\|push:" .github/workflows/deploy.yml >/dev/null && pass "Deploy has push/main-ish trigger" || warn "Deploy trigger needs review"
grep -R "ssh\|appleboy/ssh-action\|rsync" .github/workflows/deploy.yml >/dev/null && pass "Deploy uses SSH/rsync-ish mechanism" || warn "Deploy mechanism not obvious"
warn "Manual GitHub API/UI check still needed: repo private, branch protection, required checks, successful no-op deploy evidence"
