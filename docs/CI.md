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

The reusable workflow already exists — [`.github/workflows/mirror.yml`](../.github/workflows/mirror.yml).
It authenticates to the private repo, sets up the stack's toolchain, fetches the hooks
via lefthook, and runs them. It runs **only when a project calls it**, so it costs
nothing until you opt in. To turn CI on for a repo:

1. **Once per org:** create an **organization secret** `OC_GITHOOKS_TOKEN` — a
   fine-grained PAT with *read* access to `OutCode-Software/oc-githooks` — so every repo
   can use it via `secrets: inherit`.
2. **Once per project:** add the caller (GitHub only runs workflows that physically live
   in the repo):

   ```yaml
   # .github/workflows/hooks.yml
   name: git-hooks-mirror
   on: { pull_request: {}, push: { branches: [develop, stage, prod, main] } }
   jobs:
     mirror:
       uses: OutCode-Software/oc-githooks/.github/workflows/mirror.yml@v2
       with: { stack: flutter }     # flutter|web|node|reactnative|python
       secrets: inherit             # provides OC_GITHOOKS_TOKEN
   ```

After that one-time file, you control the CI logic centrally in `oc-githooks` and every
project picks it up via `@v2`.

> ⚠️ **Not yet run end-to-end in Actions** — structurally complete but unvalidated on a
> real runner; test on a throwaway repo first. Stacks beyond flutter/web/node/reactnative/
> python fall back to base-only checks; projects with codegen/private deps (e.g. Flutter
> `build_runner`) may need to extend it.

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
