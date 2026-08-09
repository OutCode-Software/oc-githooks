# Commit message convention

Enforced by the `commit-msg` hook. We use **Conventional Commits**.

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
- **ClickUp task ID** (e.g. `ENS-123`) missing → *warning* so the ClickUp status automation can link the commit. (Include it in the subject or body.)
- **`Co-Authored-By: Claude`** trailer → *blocked* (Outcode policy).

## Validated examples

| Subject | Result |
|---|---|
| `feat(auth): add SSO login ENS-9` | ✅ pass |
| `fix: null check on token ENS-9` | ✅ pass |
| `chore(docs): update README ENS-9` | ✅ pass |
| `feat(api)!: breaking change ENS-9` | ✅ pass |
| `refactor(payments/stripe): tidy ENS-9` | ✅ pass |
| `Merge branch 'develop'` | ✅ pass (auto-message) |
| `Revert "feat: x"` | ✅ pass (auto-message) |
| `added some things` | ❌ blocked (no type) |
| `FEAT: shouty` | ❌ blocked (uppercase) |
| `feature: wrong-type` | ❌ blocked (not an allowed type) |
| `feat add colon-missing` | ❌ blocked (no `: `) |

## Why

Beyond consistency, this format is machine-readable: it lets us add **automated changelogs / release notes** later (`git-cliff`, `semantic-release`, etc.) with no extra developer effort.
