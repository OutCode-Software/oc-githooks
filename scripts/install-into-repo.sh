#!/usr/bin/env bash
# Usage: scripts/install-into-repo.sh <stack> <path-to-target-repo>
#   language stacks:   python | web | node | flutter | swift | kotlin | reactnative | php | laravel | ruby | infra
#   cross-cutting:     docker | shell | sql | actions   (add alongside a language stack)
set -euo pipefail
STACK="${1:?stack required (e.g. python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions)}"
TARGET="${2:?target repo path required}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

case "$STACK" in
  python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions) ;;
  *) echo "Unknown stack: $STACK"; exit 1;;
esac
[ -d "$TARGET/.git" ] || { echo "✗ $TARGET is not a git repo"; exit 1; }

mkdir -p "$TARGET/.githooks/stacks"
cp "$HERE/base.yml"            "$TARGET/.githooks/base.yml"
cp "$HERE/stacks/$STACK.yml"   "$TARGET/.githooks/stacks/$STACK.yml"
cp "$HERE/.gitleaks.toml"      "$TARGET/.gitleaks.toml"
cp "$HERE/examples/lefthook.$STACK.yml" "$TARGET/lefthook.yml"
# NOTE: the GitHub Actions CI mirror is NOT installed by default (it costs Actions
# minutes and needs per-stack toolchain setup). Use the free server-side gates instead
# — GitHub branch-protection rulesets + secret scanning. See docs/CI.md to opt into a
# reusable-workflow CI later.

# Starter tool configs for stacks that need them (swift/sql are required for the
# hooks to run at all). Never overwrite a config the repo already has.
CFG_DIR="$HERE/configs/$STACK"
if [ -d "$CFG_DIR" ]; then
  for f in "$CFG_DIR"/.[!.]* "$CFG_DIR"/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    if [ -e "$TARGET/$base" ]; then
      echo "• kept existing $base (starter not copied)"
    else
      cp "$f" "$TARGET/$base"
      echo "• added starter config $base"
    fi
  done
fi

echo "✓ Installed $STACK hooks into $TARGET"
echo "Next:"
echo "  cd $TARGET"
echo "  brew install lefthook gitleaks   # or npm i -g lefthook"
echo "  lefthook install"
echo "  git add .githooks lefthook.yml .gitleaks.toml"
echo "  # server-side gate = free GitHub branch protection + secret scanning (see docs/CI.md)"
