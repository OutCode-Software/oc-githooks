# INSTALL — adopting oc-githooks in a repository

Two prerequisites, then pick **A** (copy — recommended for the pilot) or **B** (`remotes` — for after the repo is published).

## Prerequisites (once per machine)

```bash
# macOS
brew install lefthook gitleaks

# or, cross-platform via npm (lefthook) + binary (gitleaks)
npm install -g lefthook
# gitleaks: https://github.com/gitleaks/gitleaks/releases  (or `brew install gitleaks`)
```

Verify: `lefthook version` and `gitleaks version`.

---

## Option A — copy the files (recommended for the pilot)

Fastest path, no external dependency. From the `oc-githooks` folder:

```bash
scripts/install-into-repo.sh <python|web|mobile|infra> /path/to/your/repo
```

This copies:

| From | To (in your repo) |
|---|---|
| `base.yml` | `.githooks/base.yml` |
| `stacks/<stack>.yml` | `.githooks/stacks/<stack>.yml` |
| `.gitleaks.toml` | `.gitleaks.toml` |
| `examples/lefthook.<stack>.yml` | `lefthook.yml` |
| `ci/hooks.yml` | `.github/workflows/hooks.yml` |

Then, in your repo:

```bash
lefthook install                 # writes the git hooks for this clone
git add .githooks lefthook.yml .gitleaks.toml .github/workflows/hooks.yml
git commit -m "chore: adopt oc-githooks (TASK-ID)"
```

**Doing it by hand** (if you don't want to run the script): create the same files. Your `lefthook.yml` only needs:

```yaml
extends:
  - .githooks/base.yml
  - .githooks/stacks/web.yml   # your stack
```

> Every developer who clones the repo must run `lefthook install` once. Wire it into your bootstrap: web repos add `"prepare": "lefthook install"` to `package.json`; others add it to `make setup` / the setup step in `AGENTS.md`.

---

## Option B — `remotes` (after oc-githooks is published to GitHub)

No copied files; pull the base + stack straight from the central repo, pinned to a tag. Replace your `lefthook.yml` with:

```yaml
remotes:
  - git_url: https://github.com/OutCode-Software/oc-githooks
    ref: v1                     # pin to a tag; bump deliberately to adopt updates
    configs:
      - base.yml
      - stacks/web.yml          # your stack
```

Then `lefthook install`. Updating everyone is a one-line tag bump in each repo (or org automation).

---

## Verifying it works

```bash
# should be BLOCKED:
echo 'x="ghp_examplereplacewitharealtokenpattern"' > leaktest.txt && git add leaktest.txt && git commit -m "feat: test"
git commit -m "not a conventional message"

# should PASS:
git commit -m "feat(auth): add login (TASK-123)"
```

Run all hooks over the whole repo on demand:

```bash
lefthook run pre-commit --all-files
lefthook run pre-push   --all-files
```

## Bypassing (rare, and still caught by CI)

`git commit --no-verify` / `git push --no-verify` skip local hooks — but the CI mirror (`.github/workflows/hooks.yml`) re-runs them, and GitHub branch-protection blocks protected-branch pushes regardless. Use `--no-verify` only in a genuine emergency, not as a habit; for a Gitleaks false positive, add an allowlist entry to `.gitleaks.toml` instead.

---

## Open decisions

Two values are still pending ratification (DM working session):

1. **Protected branches.** GitHub Governance SOP uses `develop / stage / prod / main`; the Git→ClickUp doc uses `develop / staging / main`. The config enforces the **union** (`develop stage staging prod main`) until reconciled — edit the `protected` list in `base.yml` once decided.
2. **Commit convention.** Conventional Commits is enabled; confirm this is the org standard and set the warn→block date for the ClickUp-ID and branch-name checks.
