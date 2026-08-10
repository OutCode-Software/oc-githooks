#!/usr/bin/env bash
# Usage: scripts/adopt-remotes.sh <stack> <path-to-target-repo>
#   language stacks:   python | web | node | flutter | swift | kotlin | reactnative | php | laravel | ruby | infra
#   cross-cutting:     docker | shell | sql | actions   (add alongside a language stack)
#
# Sets up oc-githooks via the Lefthook `remotes` model (auto-updating): writes a
# `lefthook.yml` that pulls base.yml + the stack from oc-githooks pinned to a tag,
# copies the gitleaks allowlist (remotes can't fetch non-lefthook files), drops any
# starter tool configs, gitignores generated dirs, then runs `lefthook install`.
#
# Env overrides:  OC_REF (default v2)   OC_GIT_URL (default the private SSH URL)
set -euo pipefail

REF="${OC_REF:-v2}"
GIT_URL="${OC_GIT_URL:-git@github.com:OutCode-Software/oc-githooks}"

STACK="${1:?stack required (e.g. python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions)}"
TARGET="${2:?target repo path required}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

case "$STACK" in
  python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions) ;;
  *) echo "Unknown stack: $STACK"; exit 1;;
esac
[ -d "$TARGET/.git" ] || { echo "✗ $TARGET is not a git repo"; exit 1; }

# 1) lefthook.yml (remotes) — never clobber an existing one
if [ -e "$TARGET/lefthook.yml" ]; then
  echo "• lefthook.yml already exists — left untouched."
  echo "  Add manually if needed: remotes -> $GIT_URL @ $REF : base.yml, stacks/$STACK.yml"
else
  cat > "$TARGET/lefthook.yml" <<YAML
remotes:
  - git_url: $GIT_URL
    ref: $REF                 # rolling major tag; auto-gets non-breaking updates
    refetch_frequency: 24h    # re-pull the ref at most once/day
    configs:
      - base.yml
      - stacks/$STACK.yml
YAML
  echo "• wrote lefthook.yml (remotes @ $REF, stacks/$STACK.yml)"
fi

# 2) .gitleaks.toml — remotes only fetch lefthook configs, so copy it (if absent)
if [ -e "$TARGET/.gitleaks.toml" ]; then
  echo "• kept existing .gitleaks.toml"
else
  cp "$HERE/.gitleaks.toml" "$TARGET/.gitleaks.toml"
  echo "• added .gitleaks.toml"
fi

# 3) starter tool configs for the stack (swift/sql/php/ruby), never clobbering
CFG_DIR="$HERE/configs/$STACK"
if [ -d "$CFG_DIR" ]; then
  for f in "$CFG_DIR"/.[!.]* "$CFG_DIR"/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    if [ -e "$TARGET/$base" ]; then echo "• kept existing $base"; else cp "$f" "$TARGET/$base"; echo "• added starter config $base"; fi
  done
fi

# 4) gitignore generated dirs (only lines not already present)
GI="$TARGET/.gitignore"; touch "$GI"
add_ignore() { grep -qxF "$1" "$GI" 2>/dev/null || { echo "$1" >> "$GI"; echo "• .gitignore += $1"; }; }
add_ignore "coverage/"
case "$STACK" in
  web|node|reactnative) add_ignore "node_modules/" ;;
  php|laravel)          add_ignore "vendor/" ;;
  swift)                add_ignore ".build/" ;;
  kotlin)               add_ignore "build/"; add_ignore ".gradle/" ;;
esac

# 5) fetch remote config + wire hooks.
#    IMPORTANT: `lefthook install` "continues anyway" on a failed remote fetch and
#    still exits 0, leaving the hooks EMPTY (no protection) — and `lefthook validate`
#    still says "All good". So we don't trust exit codes: we verify the remote was
#    actually cached (lefthook stores it at .git/info/lefthook-remotes/<repo>-<ref>/).
if command -v lefthook >/dev/null 2>&1; then
  ( cd "$TARGET" && lefthook install ) 2>&1 | sed 's/^/  lefthook: /' || true
  if find "$TARGET/.git/info/lefthook-remotes" -maxdepth 2 -name 'base.yml' 2>/dev/null | grep -q .; then
    echo "✓ remote fetched — base + $STACK hooks are active"
  else
    echo "✗ REMOTE FETCH FAILED — hooks are EMPTY and provide NO protection."
    echo "  Lefthook silently 'continues anyway' on a failed sync. Most likely you"
    echo "  cannot reach $GIT_URL. Verify access, then re-run this script:"
    echo "    git ls-remote $GIT_URL $REF"
    echo "  (Auth: SSH needs a key on GitHub; or set OC_GIT_URL to the https:// URL"
    echo "   if your team uses an HTTPS credential helper / gh.)"
    exit 1
  fi
else
  echo "⚠ lefthook not on PATH. Install it (see docs/INSTALL.md), then re-run this script."
  exit 1
fi

echo
echo "✓ Adopted oc-githooks ($STACK, remotes @ $REF) in $TARGET"
echo "Next:"
echo "  cd \"$TARGET\""
echo "  git add lefthook.yml .gitleaks.toml .gitignore"
echo "  # commit on a feature branch, then open an MR into develop"
echo "  # teammates: install lefthook + gitleaks, then run 'lefthook install' once"
echo "  # CI mirror needs separate setup (private-repo auth + toolchain) — see docs/INSTALL.md"
