#!/usr/bin/env bash
# Usage: scripts/install-into-repo.sh <stack> <path-to-target-repo>
#   <stack> = python | web | flutter | swift | kotlin | reactnative | infra
set -euo pipefail
STACK="${1:?stack required: python|web|flutter|swift|kotlin|reactnative|infra}"
TARGET="${2:?target repo path required}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

case "$STACK" in python|web|flutter|swift|kotlin|reactnative|infra) ;; *) echo "Unknown stack: $STACK"; exit 1;; esac
[ -d "$TARGET/.git" ] || { echo "✗ $TARGET is not a git repo"; exit 1; }

mkdir -p "$TARGET/.githooks/stacks"
cp "$HERE/base.yml"            "$TARGET/.githooks/base.yml"
cp "$HERE/stacks/$STACK.yml"   "$TARGET/.githooks/stacks/$STACK.yml"
cp "$HERE/.gitleaks.toml"      "$TARGET/.gitleaks.toml"
cp "$HERE/examples/lefthook.$STACK.yml" "$TARGET/lefthook.yml"
mkdir -p "$TARGET/.github/workflows"
cp "$HERE/ci/hooks.yml"        "$TARGET/.github/workflows/hooks.yml"

echo "✓ Installed $STACK hooks into $TARGET"
echo "Next:"
echo "  cd $TARGET"
echo "  brew install lefthook gitleaks   # or npm i -g lefthook"
echo "  lefthook install"
echo "  git add .githooks lefthook.yml .gitleaks.toml .github/workflows/hooks.yml"
