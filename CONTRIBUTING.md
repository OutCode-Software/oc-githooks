# Contributing to oc-githooks

This is a **pilot**. The goal right now is to trial the hooks on real repos and gather feedback before this becomes the org standard. Contributions of feedback are as valuable as code.

## Sending feedback (the main ask right now)

Use the template in [`docs/FEEDBACK.md`](docs/FEEDBACK.md). Focus on: false positives, setup friction, speed, and missing/unwanted checks per stack. Small and specific beats general.

## Changing a hook

1. **Edit** `base.yml` (all repos) or the relevant `stacks/<stack>.yml` (one stack only). Keep the base minimal — stack-specific logic belongs in a stack file.
2. **Validate**: `lefthook validate`.
3. **Prove it by running it** — don't eyeball. Create a throwaway repo, install the config, and test both the block case *and* a near-miss that must *not* be blocked (false-positive guard). Add the scenario to [`docs/VALIDATION.md`](docs/VALIDATION.md).
4. **Keep it fast.** Commit-time budget is ~2s; anything heavier (typecheck, tests, build) belongs on `pre-push` or in CI, not `pre-commit`.
5. **Fail with a fix, not just a "no."** Every blocking hook prints the command or action to remediate.
6. **Update docs in the same change** — the hook and its entry in `HOOKS_CATALOG.md` / `COMMIT_CONVENTION.md` move together.
7. **Bump `CHANGELOG.md`** and, once published, the version tag.

## Principles

- **Defense-in-depth:** local hooks are fast feedback; GitHub rulesets + the CI mirror are the authoritative gate. A local hook that blocks must have a CI equivalent.
- **Portable:** hooks run on macOS and Linux. Avoid GNU-only flags (e.g. `sed -i` without a suffix); prefer `perl -i`, POSIX `grep -E`, and the `git symbolic-ref` / `git cat-file` plumbing already used.
- **One fact, one home:** don't duplicate policy across base and stack files.

## Local dev quickstart

```bash
brew install lefthook gitleaks
# make a scratch repo, drop base.yml + a stack in .githooks/, add a lefthook.yml that extends them, then:
lefthook install && lefthook validate
```
