# CI — the server-side gate (and why we default to the free one)

Local lefthook hooks are **fast feedback only** — a developer can skip them with
`git commit --no-verify`. Defense-in-depth needs a server-side gate that *can't* be
bypassed. There are two kinds, and only one costs GitHub Actions minutes.

## Default: the FREE server-side gates (recommended for now)

Outcode is on a free GitHub plan (~2000 Actions minutes/month across 20+ repos), so we
**do not ship an Actions CI workflow by default.** Instead, turn on the two protections
that are **GitHub settings, not workflows** — they cost **zero** minutes:

### 1. Branch-protection rulesets
Repo → **Settings → Rules → Rulesets → New branch ruleset**. Target `develop`, `stage`,
`prod`, `main` and enable:
- **Restrict deletions**
- **Require a pull request before merging** (≥1 approval)
- **Block force pushes**

This makes direct pushes to protected branches impossible on the server — the same rule
our local `protected-branch-guard` enforces, but un-bypassable.

### 2. Secret scanning + push protection
Repo → **Settings → Code security → Secret protection** → enable **Secret scanning** and
**Push protection**. GitHub then **blocks a push that contains a secret even if the dev
used `--no-verify`** — the server-side twin of our gitleaks hook. Free on all repos.

With these two on, the critical, un-bypassable protections (no direct pushes, no leaked
secrets) are covered at no minute cost. Lint/typecheck/test stay as local fast feedback.

## Later (optional): an Actions CI mirror via a reusable workflow

When you decide the lint/test/coverage mirror is worth the minutes, add it centrally:

1. Put the real workflow **once** in `oc-githooks` (`.github/workflows/mirror.yml`, a
   `workflow_call` reusable workflow — with the stack's toolchain + a read token for the
   private repo).
2. Each project adds a **tiny 3-line caller** (one-time — GitHub only runs workflows that
   physically live in the repo):

   ```yaml
   # .github/workflows/hooks.yml
   name: git-hooks-mirror
   on: { pull_request: {}, push: { branches: [develop, stage, prod, main] } }
   jobs:
     mirror:
       uses: OutCode-Software/oc-githooks/.github/workflows/mirror.yml@v2
       secrets: inherit
   ```

After that one-time file, you control the CI logic centrally in `oc-githooks` and every
project picks it up via `@v2`.

> **Note:** this is NOT distributed by lefthook `remotes`. Remotes pull *local hook
> config* only; GitHub Actions only runs workflow files that live in each repo. So CI
> can't be "turned on for everyone" by releasing a new oc-githooks version — each repo
> needs the small caller file. `ci/hooks.yml` in this repo is a starting-point template.

## Summary

| Layer | Where | Cost | Status |
|---|---|---|---|
| lefthook hooks | dev laptop | free | ✅ default (bypassable) |
| Branch-protection rulesets | GitHub | free | ✅ turn on per repo |
| Secret scanning + push protection | GitHub | free | ✅ turn on per repo |
| Actions lint/test mirror | GitHub Actions | **minutes** | ⏸️ opt-in later (reusable workflow) |
