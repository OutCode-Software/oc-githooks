# Commit message convention

Enforced by the `commit-msg` hook. We use **Conventional Commits**. PR titles follow the same format: task branches are squash-merged into `develop`, so the PR title becomes the commit subject ([Git Flow policy §2](GIT-FLOW-POLICY.md#2-day-to-day-work-task-branch--develop)).

```
<type>(<optional scope>)<optional !>: <subject>

<optional body>

<optional footer(s)>
```

`type` + `: ` + a non-empty subject are required. Scope, the breaking-change `!`, body, and footer are optional.

## Types

| type | use for | example |
|---|---|---|
| `feat` | a new feature | `feat(auth): add SSO login` |
| `fix` | a bug fix | `fix: null-check the token refresh` |
| `chore` | tooling, deps, config; no product change | `chore(docs): update README` |
| `docs` | documentation only | `docs: document the webhook payload` |
| `refactor` | neither a feature nor a fix | `refactor(payments/stripe): extract client` |
| `perf` | performance | `perf: cache the account lookup` |
| `test` | tests | `test: cover the expiry edge case` |
| `build` | build system / packaging | `build: bump Docker base image` |
| `ci` | CI configuration | `ci: add the secret-scan job` |
| `revert` | revert a previous commit | `revert: "feat: waitlist"` |

## Rules

- **Type is lowercase** and from the list — `FEAT:` and `feature:` are rejected.
- **Scope** is optional, in parentheses, lowercase; may contain `- _ / .` and spaces — `feat(api):`, `refactor(payments/stripe):`.
- **Breaking change:** add `!` before the colon — `feat(api)!: change the response envelope`.
- **A space after the colon** and a non-empty subject are required.
- Git's own **`Merge …` / `Revert "…"` / `fixup! …` / `squash! …`** messages pass through; the hook is skipped during merge/rebase.
- **Subject length** over 72 chars → *warning* (not a block).
- **ClickUp task ID** — you don't type it. The `prepare-commit-msg` hook adds a `ClickUp: CU-<id>` trailer from the branch name (branches are `CU-<clickup-id>`), plus an `OC-Hooks:` trailer. ClickUp links any commit whose message contains `CU-<id>`, and the trailers survive a squash merge, so the task keeps its commit history after the branch is deleted.
- **`Co-Authored-By: Claude`** trailer → *blocked* (Outcode policy).

## Validated examples

| Subject | Result |
|---|---|
| `feat(auth): add SSO login` | ✅ pass |
| `fix: null check on token` | ✅ pass |
| `chore(docs): update README` | ✅ pass |
| `feat(api)!: breaking change` | ✅ pass |
| `refactor(payments/stripe): tidy` | ✅ pass |
| `Merge branch 'develop'` | ✅ pass (auto-message) |
| `Revert "feat: x"` | ✅ pass (auto-message) |
| `added some things` | ❌ blocked (no type) |
| `FEAT: shouty` | ❌ blocked (uppercase) |
| `feature: wrong-type` | ❌ blocked (not an allowed type) |
| `feat add colon-missing` | ❌ blocked (no `: `) |

## Why

Beyond consistency, this format is machine-readable: it lets us add **automated changelogs / release notes** later (`git-cliff`, `semantic-release`, etc.) with no extra developer effort.
