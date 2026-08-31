# Changelog

All notable changes to oc-githooks. Format loosely follows Keep a Changelog; versions are the tags repos pin to via `remotes`.

## [v3.0.0] — 2026-08-31

### Changed (BREAKING)
- **Org-wide coverage default raised 25% → 50%.** Every test-running stack now falls back
  to `${OC_MIN_COVERAGE:-50}` (JS stacks: `OC_MIN_COVERAGE||50`) when a repo doesn't set its
  own floor. This can fail pushes that previously passed at 25–49% line coverage, so per
  `docs/VERSIONING.md` it ships as a new **major** tag: repos pinned to `ref: v2` keep the
  25% default until they move to `ref: v3`. Repos that already set their own `OC_MIN_COVERAGE`
  (e.g. backend 75, gifthound 90) are unaffected. Docs updated: README, HOOKS_CATALOG, INSTALL.

## [v2.5.0] — 2026-08-11

### Added
- **Configurable python coverage source.** The `python` stack now runs
  `pytest --cov=${OC_COV_SOURCE:-.} --cov-fail-under=${OC_MIN_COVERAGE:-25}` — default
  `.` (flat services), but Django / `apps/`-layout repos set `OC_COV_SOURCE=apps` so the
  gate measures app packages, not migrations/settings. Lets those repos use the standard
  py-test command (instead of skipping it) while keeping a correct scope + their own bar.

## [v2.4.0] — 2026-08-11

### Added
- **Configurable coverage threshold.** Every stack's pre-push coverage gate now reads
  `${OC_MIN_COVERAGE:-25}` — the 25% default stays central (in oc-hooks), but a repo can
  raise its own bar via an `env:` block on its coverage command in the committed
  `lefthook.yml` (merges over the `remotes` config). Verified end-to-end with pytest
  (default 25 → PASS at 85.7%; override 90 → BLOCK). Docs in INSTALL.md.

## [v2.3.0] — 2026-08-11

### Added
- **`.github/workflows/mirror.yml`** — the central **reusable** CI mirror. Lives once
  here; a project opts in with a tiny caller (`uses: …/mirror.yml@v2`, `with: {stack}`,
  `secrets: inherit`). Authenticates to the private repo, sets up the stack toolchain
  (flutter/web/node/reactnative/python), fetches hooks via lefthook, runs them. Costs no
  minutes until a project calls it; you then control CI centrally via `@v2`.
  Token passed via `env:` (not inline `${{ }}`). **Not yet run in Actions** — validate on
  a throwaway repo first. `docs/CI.md` updated with the org-secret + caller setup.

## [v2.2.0] — 2026-08-11

### Changed
- **No Actions CI mirror by default.** `install-into-repo.sh` no longer copies
  `ci/hooks.yml` into repos — it costs GitHub Actions minutes (limited on the free
  plan) and needs per-stack toolchain + private-repo auth. The server-side gate is now
  the **free** GitHub **branch-protection rulesets + secret scanning / push protection**.
- **`docs/CI.md`** — documents the free-server-side-gate approach and the opt-in
  reusable-workflow path for adding an Actions mirror later (with the caveat that CI
  can't be distributed via lefthook `remotes` — each repo needs a small caller file).
- `ci/hooks.yml` is retained as a **template** for that later opt-in, not auto-installed.

## [v2.1.2] — 2026-08-11

### Fixed
- **`adopt-remotes.sh` false alarm** — when a repo already had a *non-remotes*
  `lefthook.yml` (e.g. the copy method's `extends:` block), the script skipped
  writing but then ran its remote-fetch check and wrongly reported
  `✗ REMOTE FETCH FAILED — hooks are EMPTY` even though the copy-method hooks were
  active. It now detects a non-remotes config and exits with clear guidance to remove
  the copy-method files (`lefthook.yml`, `.githooks/`) before switching to remotes.

## [v2.1.1] — 2026-08-11

### Changed
- **Default `git_url` is now HTTPS** (`https://github.com/OutCode-Software/oc-githooks`)
  in `adopt-remotes.sh` and INSTALL.md — every OutCode-Software repo uses an HTTPS
  origin, so devs are already authenticated for it; the old SSH default failed for
  anyone without an OutCode-scoped SSH key. Override with `OC_GIT_URL=git@…` for SSH.

## [v2.1.0] — 2026-08-11

### Added
- **`scripts/adopt-remotes.sh`** — one-command `remotes` (auto-update) setup:
  writes the `remotes` `lefthook.yml`, copies `.gitleaks.toml` (remotes can't fetch
  it), drops starter tool configs, gitignores generated dirs, runs `lefthook install`,
  and **verifies the remote actually fetched**. Overridable via `OC_GIT_URL`/`OC_REF`.
- **Cross-platform tool-install matrix** + `.mise.toml` pinning guidance in INSTALL.md
  (`brew` is macOS-only; added Windows/Linux/npm/mise paths).

### Documented (important gotcha)
- **A failed `remotes` fetch fails silently** — Lefthook prints `Couldn't sync … Will
  continue anyway`, exits 0 with **empty hooks**, and `lefthook validate` still says
  "All good". Verify via `.git/info/lefthook-remotes/<repo>-<ref>/base.yml` (or just use
  `adopt-remotes.sh`, which checks). Do **not** trust `lefthook validate` for this.

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
