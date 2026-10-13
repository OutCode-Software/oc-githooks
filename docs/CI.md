# CI — the checks after the hooks, on GitHub Free

Local lefthook hooks are **fast feedback**: a developer can skip them with
`git commit --no-verify`, and they only run where `lefthook install` was run. The checks
after them run on GitHub's side.

## What GitHub Free can and can't enforce

OutCode is on **GitHub Free with private repos**. On that plan, **branch-protection rulesets,
required reviews, required status checks, tag protection and secret-scanning push protection
are not available** (the API returns 403). Nothing on GitHub's side can stop a direct push or
a merge, so don't design around it. The [Git Flow policy](GIT-FLOW-POLICY.md#7-enforcement)
is enforced in three layers instead:

1. **These hooks** on every laptop (bypassable with `--no-verify`; every commit is stamped
   with an `OC-Hooks:` trailer so a missing install shows up in the audit).
2. **CI and the release guard**, from outcode-standard's `/outcode-standard:ci`: CI (format,
   lint, type-check, test, build) on every PR and push to `develop`; the release guard on
   every release build and production deploy (tag format, tag on `main` or the head of a
   hotfix PR, a manual run started from `main`, a passed release build). A red check can't
   block a merge on Free, but the reviewer sees it.
3. **The daily audit**: reports direct pushes, PRs merged without a non-author approval,
   tags not on `main`, who deployed each release, and commits without the `OC-Hooks` trailer.

CI runs on the runner named by the `CI_RUNS_ON` repo or org variable. GitHub-hosted runners
are blocked by org billing, so OutCode runs its own: see the
[self-hosted runner runbook](https://github.com/OutCode-Software/ci-workflows/blob/main/docs/self-hosted-runner.md)
in ci-workflows.

How each project deploys is its own choice (policy §8); a server-side deploy guard is
recommended where a project can run one, not required.

If a repo is **public**, or the org moves to a paid plan, also turn on the GitHub settings:
a branch ruleset on `main` and `develop` (restrict deletions, require a PR with ≥1 approval
and the CI check, block force pushes) and secret scanning with push protection.

## Superseded: the Actions hooks mirror

[`.github/workflows/mirror.yml`](../.github/workflows/mirror.yml) and `ci/hooks.yml` re-ran
these hooks in Actions. `/outcode-standard:ci` replaces them with per-stack CI that runs the
project's own checks. No repository calls the mirror; don't adopt it.

## Summary

| Layer | Where | Status |
|---|---|---|
| lefthook hooks | dev laptop | ✅ default (bypassable) |
| CI + release guard (`/outcode-standard:ci`) | the project's runner (`CI_RUNS_ON`) | ✅ per project (advisory on Free) |
| Daily audit | audit host | ✅ org-wide |
| Server-side deploy guard | where the project deploys | optional, the project's choice |
| Branch rulesets + secret push protection | GitHub | ⏸️ public repos or paid plans only |
