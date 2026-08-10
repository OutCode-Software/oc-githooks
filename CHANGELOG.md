# Changelog

All notable changes to oc-githooks. Format loosely follows Keep a Changelog; versions are the tags repos pin to via `remotes`.

## [v2.0.0] — 2026-08-11

**Breaking:** `stacks/mobile.yml` was removed (split into per-language stacks).
Repos on the old `mobile` stack move to `flutter` (or the matching per-language
overlay). Pin `ref: v2` for this line; `v1` stays on the pre-split release.

### Fixed (end-to-end validation pass)
- **Coverage gates swallowed test failures** — multi-line `run:` blocks
  (swift/flutter/kotlin/php/ruby/node/reactnative) returned the trailing echo's
  exit code, so a failing test suite *passed* the gate. Now `<test> || exit 1`.
- **python** coverage measured only imported modules (`--cov`); untested files were
  invisible. Now `--cov=.`.
- **actions** `yamllint` default config false-positived on valid GitHub workflows →
  `yamllint -d relaxed`.
- **php** `php-cs-fixer` rejects a multi-file path list → per-file loop.
- **sql** stack comment showed an invalid `.sqlfluff` (missing `[sqlfluff]` header).
- **swift** documented required `.swiftlint.yml` excluding `.build` (else it lints
  build artifacts). Added per-stack prerequisites table to INSTALL.md.
- **Format/lint parallel race** (ruby/kotlin/sql) — under pre-commit `parallel: true`
  a separate lint command raced the auto-fixer and false-blocked commits needing
  formatting. Collapsed to one auto-fixing command (`rubocop -A`/`ktlint -F`/`sqlfluff fix`).
- Validated all 15 stacks end-to-end with real toolchains; results in VALIDATION.md.

### Changed
- **Split the `mobile` stack into per-language overlays** — `stacks/mobile.yml`
  removed; added `stacks/flutter.yml`, `stacks/swift.yml`, `stacks/kotlin.yml`,
  `stacks/reactnative.yml` (+ matching `examples/lefthook.<stack>.yml`). The old
  `mobile` overlay was Flutter-only and its unguarded `flutter` pre-push commands
  misfired in native repos. Install script + all docs updated.
- **Coverage gate on pre-push** — every test-running stack now enforces a **≥25%
  line-coverage** minimum (deliberately low; rises over time). Retrofitted `web`
  (`vitest --coverage`) and `python` (`pytest --cov-fail-under=25`).
- **Fixed a `debugger` false positive** in `web`/`reactnative` — the guard now uses
  a trailing boundary so `debuggerUtil`/`mydebugger` no longer trip it.

### Added
- **Starter tool configs** (`configs/<stack>/`) auto-installed by the installer,
  never clobbering an existing one: `swift` `.swiftlint.yml` (excludes `.build` —
  required), `sql` `.sqlfluff` (mandatory header), `php` `.php-cs-fixer.dist.php`,
  `ruby` `.rubocop.yml`. Swift now works out-of-the-box (was blocked by swiftlint
  linting build artifacts).
- **New language stacks** — `node` (Node.js/NestJS), `php`, `laravel`, `ruby`
  (Ruby/Rails). Each has format + lint + type-check/static-analysis + tests with
  the ≥25% coverage gate, plus a debug-statement guard.
- **New cross-cutting overlays** — `docker` (hadolint), `shell` (shfmt +
  shellcheck), `sql` (sqlfluff), `actions` (actionlint + yamllint). These lint
  files that appear across repos and are added alongside a language stack.
- **docs/VERSIONING.md** — two-tier tag scheme (immutable `v1.x.y` + rolling `v1`),
  `refetch_frequency` update mechanism, and the maintainer release checklist.
- **docs/INSTALL.md** — `remotes` is now the recommended standard: SSH `git_url`
  (repo is private), `refetch_frequency: 24h`, and CI deploy-key/PAT guidance.

### Pending
- Run the new stack overlays end-to-end with real toolchains (swiftformat/swiftlint,
  ktlint, flutter, jest) and `lefthook validate`; record results in `docs/VALIDATION.md`.

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
