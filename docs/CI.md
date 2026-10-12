# CI — the server-side gate on GitHub Free

Local lefthook hooks are **fast feedback only** — a developer can skip them with
`git commit --no-verify`. Defense-in-depth needs a server-side gate that *can't* be
bypassed. There are two kinds, and only one costs GitHub Actions minutes.

## Default: what GitHub Free can and can't enforce

OutCode is on **GitHub Free with private repos**. On that plan, **branch-protection rulesets,
required reviews, tag protection and secret-scanning push protection are not available**
(the API returns 403). Nothing on GitHub's side can stop a direct push, so don't design
around it. The [Git Flow policy](GIT-FLOW-POLICY.md#7-enforcement) is enforced in three
layers instead:

1. **These hooks** on every laptop (bypassable with `--no-verify`; every commit is stamped
   with an `OC-Hooks:` trailer so a missing install shows up in the audit).
2. **A deploy guard on each server** (for example a root-owned `/opt/deploy/deploy.sh` on each EC2):
   it re-checks the ref and commit against GitHub before installing anything. Workflow
   files can be edited on any branch; files on the server can't.
3. **The daily audit**: reports direct pushes, PRs merged without a non-author approval,
   tags not on `main`, and commits without the `OC-Hooks` trailer.

If a repo is **public**, or the org moves to a paid plan, also turn on the GitHub settings
(zero Actions minutes): a branch ruleset on `main` and `develop` (restrict deletions,
require a PR with ≥1 approval, block force pushes) and secret scanning with push protection.

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
   on: { pull_request: {}, push: { branches: [develop, main] } }
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
| Deploy guard | each server | free | ✅ per deploy target (see the Git Flow policy) |
| Daily audit | audit host | free | ✅ org-wide |
| Branch rulesets + secret push protection | GitHub | free on public / paid plans only | ⏸️ not available for private repos on Free |
| Actions lint/test mirror | GitHub Actions | **minutes** | ⏸️ opt-in later (reusable workflow) |
