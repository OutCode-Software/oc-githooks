#!/bin/sh
# oc-githooks ref guard (pre-push) — the Git Flow rules for what may be pushed.
#
# Shipped as a Lefthook *script*, not a command: Lefthook skips every pre-push
# *command* when a push changes no files (a release tag pushed from an up-to-date
# main, a branch deletion, an empty commit), which let those pushes past the old
# command-based guard. Scripts always run.
#
# git passes "<local ref> <local sha> <remote ref> <remote sha>" lines on stdin.
#   - main and develop are never pushed to (also catches `git push origin HEAD:main`)
#   - branches are CU-<clickup-id>; deleting a remote branch is allowed (legacy cleanup)
#   - tags are MAJOR.MINOR.PATCH with no "v", and are never moved or deleted

zero=0000000000000000000000000000000000000000
status=0

while read -r lref lsha rref rsha; do
  [ -z "$rref" ] && continue
  case "$rref" in
    refs/heads/main|refs/heads/develop)
      echo "✗ Push to '${rref#refs/heads/}' is blocked. Open a PR instead (Git Flow policy §2–§3)."
      status=1 ;;
    refs/heads/*)
      b=${rref#refs/heads/}
      [ "$lsha" = "$zero" ] && continue
      if ! printf '%s\n' "$b" | grep -qE '^CU-[0-9a-z]+$'; then
        echo "✗ Branch '$b' must be named CU-<clickup-id>, e.g. CU-86e3m6v34 (Git Flow policy §1)."
        echo "  Rename it: git branch -m CU-<id> && git push -u origin CU-<id>"
        status=1
      fi ;;
    refs/tags/*)
      t=${rref#refs/tags/}
      if [ "$lsha" = "$zero" ] || [ "$rsha" != "$zero" ]; then
        echo "✗ Tag '$t' already exists on the remote. Tags are never moved or deleted; ship a new version."
        status=1
      elif ! printf '%s\n' "$t" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "✗ Tag '$t' must be MAJOR.MINOR.PATCH with no 'v', e.g. 1.4.0 (Git Flow policy §4)."
        status=1
      fi ;;
  esac
done

exit "$status"
