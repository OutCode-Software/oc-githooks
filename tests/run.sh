#!/usr/bin/env bash
#
# Exercises base.yml end to end the way projects consume it: through Lefthook
# `remotes`, against a throwaway local "GitHub" (a bare repo). Nothing touches a
# real remote. Covers the Git Flow rules in docs/GIT-FLOW-POLICY.md.
#
#   tests/run.sh             # uses a temp dir, removed afterwards
#   KEEP=1 tests/run.sh      # keep the temp dir for inspection
#
# Needs: git, lefthook >= 2.0, gitleaks. The working tree is tested as-is
# (uncommitted changes included), so this checks what you're about to commit.

set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d "${TMPDIR:-/tmp}/ochooks.XXXXXX")"
[ "${KEEP:-0}" = 1 ] && echo "workdir: $W" || trap 'rm -rf "$W"' EXIT
PASS=0 FAIL=0

check() { # check ok|fail "label" cmd...
  local want=$1 label=$2 out got; shift 2
  if out=$("$@" 2>&1); then got=ok; else got=fail; fi
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1)); printf '  ✓ %s\n' "$label"
  else FAIL=$((FAIL + 1)); printf '  ✗ %s (expected %s, got %s)\n' "$label" "$want" "$got"; printf '%s\n' "$out" | tail -6 | sed 's/^/      /'
  fi
}
assert() { # assert "label" test-cmd...
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then PASS=$((PASS + 1)); printf '  ✓ %s\n' "$label"
  else FAIL=$((FAIL + 1)); printf '  ✗ %s\n' "$label"; fi
}
remote_has() { git -C "$W/remote.git" rev-parse --verify --quiet "$1" >/dev/null; }
last_msg() { git log -1 --format=%B; }
gitq() { git -c core.hooksPath=/dev/null "$@"; }

for tool in git lefthook gitleaks; do
  command -v "$tool" >/dev/null || { echo "✗ $tool is required"; exit 1; }
done

# oc-githooks as projects see it: a git repo with a tag to pin `ref:` to.
git init -q "$W/oc-githooks" && (cd "$W/oc-githooks" \
  && rsync -a --exclude .git --exclude tests "$SRC/" . \
  && git add -A && gitq -c user.email=t@t -c user.name=t commit -q -m "test snapshot" \
  && git tag v-test)

# A fake GitHub with main + develop, and a project that adopts oc-githooks via remotes.
git init -q --bare "$W/remote.git"
git init -q "$W/seed" && (cd "$W/seed" \
  && cat > lefthook.yml <<EOF
remotes:
  - git_url: file://$W/oc-githooks
    ref: v-test
    configs:
      - base.yml
EOF
  echo "# project" > README.md \
  && git add -A && gitq -c user.email=t@t -c user.name=t commit -q -m "chore: seed" \
  && git branch -M main && git branch develop \
  && git push -q "$W/remote.git" main develop)

echo "Setup"
git clone -q "$W/remote.git" "$W/clone" && cd "$W/clone" || exit 1
git config user.email dev@example.com && git config user.name Dev
lefthook install >/dev/null 2>&1
assert "lefthook install wires the hooks" test -x .git/hooks/pre-push -a -x .git/hooks/commit-msg -a -x .git/hooks/prepare-commit-msg
assert "the remote config was fetched" sh -c 'find .git/info/lefthook-remotes -name base.yml | grep -q .'

echo "Commits"
git switch -q develop && echo a > a.txt && git add a.txt
check fail "commit on develop is blocked" git commit -m "feat: on develop"
git switch -q main
check fail "commit on main is blocked" git commit -m "feat: on main"
git switch -q -c CU-86e3abc12
check fail "'fixed stuff' is rejected" git commit -m "fixed stuff"
check fail "a Co-Authored-By: Claude trailer is rejected" git commit -m "fix: x" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
check ok   "'fix: handle empty name' is accepted" git commit -m "fix: handle empty name"
assert "commit carries the OC-Hooks trailer" grep -q '^OC-Hooks: v6' <(last_msg)
assert "commit carries the ClickUp trailer from the branch" grep -qx 'ClickUp: CU-86e3abc12' <(last_msg)
git commit -q --amend --no-edit >/dev/null 2>&1
assert "amending doesn't duplicate trailers" test "$(last_msg | grep -c '^ClickUp: ')" = 1
git switch -q -c scratch && git commit -q --allow-empty -m "chore: off-policy branch" >/dev/null 2>&1
assert "no ClickUp trailer on a non-CU branch" sh -c '! git log -1 --format=%B | grep -q "^ClickUp: "'
git switch -q CU-86e3abc12 && git branch -q -D scratch

echo "Branch pushes"
check fail "git push origin HEAD:main is blocked" git push origin HEAD:main
check fail "git push origin HEAD:develop is blocked" git push origin HEAD:develop
check ok   "CU-86e3abc12 can be pushed" git push -u origin CU-86e3abc12
git commit -q --allow-empty -m "chore: no file changes" >/dev/null 2>&1
check fail "HEAD:develop is blocked even when the push changes no files" git push origin HEAD:develop
assert "   …and develop on the remote is untouched" test "$(git -C "$W/remote.git" log -1 --format=%s develop)" = "chore: seed"
git switch -q -c feature/ENS-123-waitlist
check fail "feature/ENS-123-waitlist is blocked" git push origin feature/ENS-123-waitlist
git switch -q -c CU-UPPER
check fail "CU-UPPER (uppercase id) is blocked" git push origin CU-UPPER
git switch -q CU-86e3abc12
check fail "deleting develop on the remote is blocked" git push origin :develop
check ok   "deleting a task branch is allowed" git push origin :CU-86e3abc12

echo "Pushes with WIP commits"
git commit -q --allow-empty --no-verify -m "wip: half done" >/dev/null 2>&1
check fail "a WIP commit blocks the push" git push origin CU-86e3abc12
git reset -q --soft HEAD~1

echo "Tags"
git tag v0.2.0 && git tag 0.2 && git tag -a 0.1.0 -m "Release 0.1.0" HEAD~1
check fail "v0.2.0 is blocked" git push origin v0.2.0
check fail "0.2 is blocked" git push origin 0.2
check ok   "0.1.0 can be pushed" git push origin 0.1.0
check fail "deleting tag 0.1.0 is blocked" git push origin :refs/tags/0.1.0
assert "   …and 0.1.0 still exists on the remote" remote_has refs/tags/0.1.0
git tag -f -a 0.1.0 -m moved HEAD >/dev/null
check fail "moving tag 0.1.0 is blocked" git push -f origin 0.1.0

echo "Release tags from an up-to-date main (a push that changes no files)"
git switch -q main && git pull -q --ff-only
git tag v1.0.0 && git tag -a 1.0.0 -m "Release 1.0.0"
check fail "v1.0.0 from main is blocked" git push origin v1.0.0
check ok   "1.0.0 from main can be pushed" git push origin 1.0.0

echo "Bypass"
git switch -q CU-86e3abc12
git commit -q --allow-empty --no-verify -m "chore: bypassed" >/dev/null 2>&1
assert "a --no-verify commit still carries both trailers" sh -c 'git log -1 --format=%B | grep -q "^OC-Hooks: " && git log -1 --format=%B | grep -q "^ClickUp: CU-86e3abc12"'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
