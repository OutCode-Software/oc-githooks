# Changelog

All notable changes to oc-githooks. Format loosely follows Keep a Changelog; versions are the tags repos pin to via `remotes`.

## [v1] — 2026-08-10

First tagged release. Published to `OutCode-Software/oc-githooks`; repos can now
adopt via the Lefthook `remotes:` path pinned to `ref: v1` (see `docs/INSTALL.md`).

### Added
- **base.yml** — `pre-commit`: gitleaks staged secret scan, credential/state-file guard (`.env`, keys, `*.tfstate`, `.npmrc`, `.pypirc`; allows `.env.example`), large-file guard (>5 MB), merge-conflict-marker check, whitespace/EOF auto-fix, protected-branch commit guard.
- **base.yml** — `commit-msg`: Conventional Commits, subject-length warning, ClickUp task-ID warning, block `Co-Authored-By: Claude`.
- **base.yml** — `pre-push`: protected-branch push guard (blocks direct + remapped `HEAD:main` pushes), WIP/fixup/squash guard, branch-name warning.
- **stacks/** — python, web, mobile, infra overlays (format/lint/typecheck/test + debug-statement / focused-test / TF-state guards).
- **examples/**, **scripts/install-into-repo.sh**, **ci/hooks.yml** (CI mirror), **.gitleaks.toml** template.
- **docs/** — INSTALL, COMMIT_CONVENTION, HOOKS_CATALOG, VALIDATION, FEEDBACK.

### Validated
- lefthook 2.1.10, gitleaks 8.21.2: commit matrix (13), push matrix (6), commit-format matrix (12), stack-guard matrix (10) — all green. See `docs/VALIDATION.md`.

### Changed
- Protected-branch set reconciled to `develop stage prod main` (Governance SOP naming; dropped `staging`). Applied to `base.yml` (commit + push guards) and `ci/hooks.yml`.

### Pending (DM working session)
- Ratify Conventional Commits; set warn→block date for ClickUp-ID and branch-name checks.
- Validate stack overlays end-to-end with real toolchains (ruff, eslint, dart, terraform).
