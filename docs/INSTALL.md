# INSTALL — adopting oc-githooks in a repository

Two prerequisites, then pick **A** (copy — recommended for the pilot) or **B** (`remotes` — for after the repo is published).

## Prerequisites (once per machine)

```bash
# macOS
brew install lefthook gitleaks

# or, cross-platform via npm (lefthook) + binary (gitleaks)
npm install -g lefthook
# gitleaks: https://github.com/gitleaks/gitleaks/releases  (or `brew install gitleaks`)
```

Verify: `lefthook version` and `gitleaks version`.

---

## Option A — copy the files (recommended for the pilot)

Fastest path, no external dependency. From the `oc-githooks` folder:

```bash
scripts/install-into-repo.sh <python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions> /path/to/your/repo
```

This copies:

| From | To (in your repo) |
|---|---|
| `base.yml` | `.githooks/base.yml` |
| `stacks/<stack>.yml` | `.githooks/stacks/<stack>.yml` |
| `.gitleaks.toml` | `.gitleaks.toml` |
| `examples/lefthook.<stack>.yml` | `lefthook.yml` |
| `ci/hooks.yml` | `.github/workflows/hooks.yml` |

Then, in your repo:

```bash
lefthook install                 # writes the git hooks for this clone
git add .githooks lefthook.yml .gitleaks.toml .github/workflows/hooks.yml
git commit -m "chore: adopt oc-githooks (TASK-ID)"
```

**Doing it by hand** (if you don't want to run the script): create the same files. Your `lefthook.yml` only needs:

```yaml
extends:
  - .githooks/base.yml
  - .githooks/stacks/web.yml   # your stack
```

> Every developer who clones the repo must run `lefthook install` once. Wire it into your bootstrap: web repos add `"prepare": "lefthook install"` to `package.json`; others add it to `make setup` / the setup step in `AGENTS.md`.

---

## Option B — `remotes` (recommended standard, now published)

No copied files: Lefthook pulls `base.yml` + your stack straight from the central
`oc-githooks` repo and merges them locally. Your repo holds only this pointer.
Replace your `lefthook.yml` with:

```yaml
remotes:
  - git_url: git@github.com:OutCode-Software/oc-githooks   # SSH — repo is PRIVATE
    ref: v1                     # rolling major tag; see docs/VERSIONING.md
    refetch_frequency: 24h      # re-pull the ref at most once/day
    configs:
      - base.yml
      - stacks/web.yml          # your language stack
      # add cross-cutting overlays as needed:
      # - stacks/docker.yml
      # - stacks/shell.yml
```

> **Multiple overlays.** A repo lists every stack it needs — its language stack
> plus any cross-cutting overlays (`docker`, `shell`, `sql`, `actions`). Each
> check is `glob`-gated, so it only runs on matching files. A polyglot repo can
> list several language stacks too.

Then `lefthook install`. Lefthook shallow-clones the ref into `.git/info/lefthook-remotes/`
(local cache, not committed) and merges the configs. Hooks then run from that cache
with no per-commit network call.

> **Private-repo auth.** Because `oc-githooks` is private, Lefthook clones it with the
> developer's own git credentials — use the **SSH** `git_url` above so each dev's SSH key
> works transparently. **CI** needs its own access: give the `git-hooks-mirror` workflow a
> deploy key or a PAT with read access to `oc-githooks`, or it can't fetch the remote.

**Getting updates:** with `ref: v1` + `refetch_frequency: 24h`, non-breaking updates
arrive automatically within a day (we fast-forward the `v1` tag on each release). Pin an
exact tag (`ref: v1.2.0`) for reproducible builds and bump deliberately. Breaking changes
ship as `v2`. Full policy in [`VERSIONING.md`](VERSIONING.md).

---

## Per-stack prerequisites

Hooks run on **staged files** using **your repo's own toolchain**. Each stack needs
its tools installed and, for some, a config file. Verified end-to-end — see
[`VALIDATION.md`](VALIDATION.md).

**All stacks:** gitignore build/dependency dirs (`node_modules/`, `vendor/`,
`.build/`, `build/`, `coverage/`). If committed, the hooks will lint them.

| Stack | Tools | Required config / notes |
|---|---|---|
| python | ruff, mypy, pytest, **pytest-cov** | coverage uses `--cov=.` (counts untested files) |
| web | prettier, eslint, typescript, vitest, **@vitest/coverage-v8** | `tsconfig.json`, `eslint.config.js` |
| node | prettier, eslint, typescript, jest, ts-jest | as web; set jest `collectCoverageFrom` to catch untested files |
| reactnative | prettier, eslint, typescript, jest | as node |
| flutter | dart, flutter | untested files may not lower coverage — use a barrel-import test |
| swift | swiftformat, swiftlint | **`.swiftlint.yml` with `excluded: [.build, .swiftpm, Pods]`** (else it lints build output) |
| kotlin | ktlint, gradle, JDK 17+ | JaCoCo plugin + `xml.required=true`; `./gradlew` wrapper committed |
| php | php-cs-fixer, phpstan, phpunit | **`.php-cs-fixer(.dist).php`**, `phpstan.neon`; pcov/xdebug for coverage |
| laravel | pint, larastan, php artisan | pcov/xdebug for `artisan test --coverage` |
| ruby | rubocop, rspec, simplecov (ruby ≥2.7) | SimpleCov must write `coverage/.last_run.json` |
| infra | terraform, tflint, trivy | — |
| sql | sqlfluff | **`.sqlfluff` with a `[sqlfluff]` header + `dialect`** |
| docker | hadolint | — |
| shell | shfmt, shellcheck | — |
| actions | actionlint, yamllint | uses `yamllint -d relaxed`; add a `.yamllint` to customise |

## Verifying it works

```bash
# should be BLOCKED:
echo 'x="ghp_examplereplacewitharealtokenpattern"' > leaktest.txt && git add leaktest.txt && git commit -m "feat: test"
git commit -m "not a conventional message"

# should PASS:
git commit -m "feat(auth): add login (TASK-123)"
```

Run all hooks over the whole repo on demand:

```bash
lefthook run pre-commit --all-files
lefthook run pre-push   --all-files
```

## Bypassing (rare, and still caught by CI)

`git commit --no-verify` / `git push --no-verify` skip local hooks — but the CI mirror (`.github/workflows/hooks.yml`) re-runs them, and GitHub branch-protection blocks protected-branch pushes regardless. Use `--no-verify` only in a genuine emergency, not as a habit; for a Gitleaks false positive, add an allowlist entry to `.gitleaks.toml` instead.

---

## Open decisions

One value is still pending ratification (DM working session):

1. **Commit convention.** Conventional Commits is enabled; confirm this is the org standard and set the warn→block date for the ClickUp-ID and branch-name checks.

**Resolved:** the protected-branch set is `develop / stage / prod / main` (the Git→ClickUp doc's `staging` was dropped in favour of the Governance SOP naming). Enforced by the `protected` list in `base.yml` and mirrored in `ci/hooks.yml`.
