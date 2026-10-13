# oc-githooks

OutCode's shared git hooks. Every repo gets the same base checks, plus a small layer for its language or framework. They enforce the [Git Flow policy](docs/GIT-FLOW-POLICY.md) on every commit and push.

Built on [Lefthook](https://lefthook.dev) and [Gitleaks](https://github.com/gitleaks/gitleaks).

**Current release: v6.0.0** (rolling tag `v6`). Repos still on `v5` keep working until they [upgrade](#upgrading-from-v5). Status: pilot, so [feedback](CONTRIBUTING.md#sending-feedback-the-main-ask-right-now) is welcome.

## What it checks

| When | Check |
|---|---|
| **Commit** | No commits on `main` or `develop` |
| | No secrets (Gitleaks) and no credential files (`.env`, `*.pem`, keystores…) |
| | No files over 5 MB, no merge-conflict markers; whitespace is auto-fixed |
| | Commit message follows [Conventional Commits](docs/COMMIT_CONVENTION.md) (`fix: handle empty name`) |
| | Adds `ClickUp: CU-<id>` (from the branch name) and `OC-Hooks: <version>` to every commit |
| **Push** | No pushes to `main` or `develop`, including `git push origin HEAD:main` and deletions |
| | Branches are named `CU-<clickup-id>` |
| | Tags are `MAJOR.MINOR.PATCH` (no `v`) and are never moved or deleted |
| | No `WIP` / `fixup!` / `squash!` commits |
| | The stack's type-check and tests pass (90% coverage on test stacks) |

On GitHub Free, private repos have no branch protection, so these hooks are the first line. CI on every PR (from `/outcode-standard:ci`) and the daily audit catch what `--no-verify` lets through ([CI.md](docs/CI.md)).

## Stacks

Pick one language stack, plus any overlays the repo needs.

| Language stacks | Overlays |
|---|---|
| `python` (Django/FastAPI), `web` (Next.js/TypeScript), `node` (Node/NestJS), `reactnative`, `flutter`, `swift`, `kotlin`, `php`, `laravel`, `ruby`, `infra` (Terraform) | `docker`, `shell`, `sql`, `actions` |

What each stack runs, and the tools it needs, are in the [hooks catalog](docs/HOOKS_CATALOG.md#per-stack-layers) and [per-stack prerequisites](docs/INSTALL.md#per-stack-prerequisites).

## Add the hooks to a repo

You need Lefthook 2.0 or newer, Gitleaks, and GitHub access to this repo (HTTPS by default; for SSH set `OC_GIT_URL=git@github.com:OutCode-Software/oc-githooks`).

```bash
brew install lefthook gitleaks
```

1. In your repo, start a task branch: `git switch develop && git pull && git switch -c CU-<clickup-id>`.
2. From a clone of oc-githooks, run:

   ```bash
   scripts/adopt-remotes.sh <stack> /path/to/your/repo
   ```

   This writes a small `lefthook.yml` that pulls `base.yml` and your stack from this repo at `ref: v6`, and checks the fetch worked.
3. In your repo:

   ```bash
   lefthook install
   git add lefthook.yml .gitleaks.toml
   git commit -m "chore: add oc-githooks"
   ```

   Then open a PR into `develop`.

Updates within v6 arrive automatically. Everyone else gets the hooks by running `lefthook install` after pulling.

**A check the repo doesn't use** (for example, no TypeScript in a `node` repo) can be turned off in the repo's own `lefthook.yml`:

```yaml
pre-push:
  commands:
    node-typecheck: { skip: true }
```

Repos that can't reach this repo (air-gapped CI) can copy the files in instead: see [INSTALL.md](docs/INSTALL.md#option-a--copy-the-files-fallback).

## Upgrading from v5

v6 is a breaking release, and `v5` doesn't move, so nothing changes until a repo opts in.

1. Rename open branches to `CU-<clickup-id>`. From v6, pushing `feature/…`, `stage` or `prod` is blocked.
2. New release tags are `X.Y.Z` with no `v`. Existing `v1.2.3` tags stay.
3. Change `ref: v5` to `ref: v6` in `lefthook.yml` and run `lefthook install`.
4. Apply the [repository settings](docs/GIT-FLOW-POLICY.md#repository-settings): default branch `develop`, squash and merge commits allowed, head branches auto-deleted.

Full notes: [CHANGELOG](CHANGELOG.md#migrating-from-v5).

## Documentation

| Doc | Read it for |
|---|---|
| [GIT-FLOW-POLICY.md](docs/GIT-FLOW-POLICY.md) | Branches, reviews, releases and hotfixes: the policy these hooks enforce |
| [INSTALL.md](docs/INSTALL.md) | Install options, per-stack prerequisites, coverage threshold, verifying it works |
| [HOOKS_CATALOG.md](docs/HOOKS_CATALOG.md) | Every hook in detail |
| [COMMIT_CONVENTION.md](docs/COMMIT_CONVENTION.md) | Commit message rules, with examples |
| [VERSIONING.md](docs/VERSIONING.md) | How tags work and how updates reach repos |
| [CI.md](docs/CI.md) | What's enforced where on GitHub Free |
| [CHANGELOG.md](CHANGELOG.md) | What changed in each version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Sending feedback, changing a hook, releasing |

Internal OutCode tooling, owned by Platform Engineering.
