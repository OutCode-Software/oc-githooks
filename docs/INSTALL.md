# INSTALL — adopting oc-githooks in a repository

Two prerequisites, then pick a method:

- **Option B — `remotes` (recommended default).** The repo holds only a `lefthook.yml` pointer; Lefthook pulls the hook configs from this central repo and auto-updates them. **No committed `.githooks/` folder**, no drift. Use this unless you have a specific reason not to.
- **Option A — copy the files (fallback).** Copies `base.yml` + your stack into a committed `.githooks/` folder. Use **only** when a repo or its CI can't reach the private `oc-githooks` (air-gapped, no access); you then have to update the copied files by hand.

## Prerequisites (once per machine)

Install **lefthook** + **gitleaks**. `brew` is macOS-only, so use your platform's:

| OS | lefthook | gitleaks |
|---|---|---|
| macOS | `brew install lefthook` | `brew install gitleaks` |
| Windows | `winget install evilmartians.lefthook` (or scoop/choco) | `winget install gitleaks` |
| Linux (Debian/Ubuntu) | `curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.deb.sh' \| sudo -E bash && sudo apt install lefthook` | download `linux_x64` from [releases](https://github.com/gitleaks/gitleaks/releases) → put on `PATH` |
| Any OS (Node) | `npm install -g lefthook` | — (still need the gitleaks binary) |

**Pin versions for the whole team** (recommended): commit a `.mise.toml` and run `mise install`:

```toml
[tools]
lefthook = "2.1.10"
gitleaks = "8.30.1"
```

Verify: `lefthook version` and `gitleaks version`.

---

## Option A — copy the files (fallback)

> Use this only when `remotes` (Option B, below) isn't reachable — it creates a
> committed `.githooks/` folder you must keep up to date by hand. Most repos should
> use Option B.

No external dependency at hook-run time (the configs are vendored in). From the `oc-githooks` folder:

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

(The Actions CI mirror is **not** installed by default — see [`CI.md`](CI.md). Use the
free GitHub branch-protection rulesets + secret scanning as the server-side gate.)

Then, in your repo:

```bash
lefthook install                 # writes the git hooks for this clone
git add .githooks lefthook.yml .gitleaks.toml
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

## Option B — `remotes` (recommended default)

No copied files: Lefthook pulls `base.yml` + your stack straight from the central
`oc-githooks` repo and merges them locally. Your repo holds only this pointer.

**One-command setup** (from a clone of `oc-githooks`):

```bash
scripts/adopt-remotes.sh <stack> /path/to/your/repo
```

It writes the `remotes` `lefthook.yml`, copies `.gitleaks.toml`, drops any starter
tool configs, gitignores generated dirs, runs `lefthook install`, and — crucially —
**verifies the remote actually fetched** (see the warning below). Override the URL/ref
with `OC_GIT_URL=` / `OC_REF=`.

To do it by hand instead, replace your `lefthook.yml` with:

```yaml
remotes:
  - git_url: https://github.com/OutCode-Software/oc-githooks   # HTTPS (matches repo origins)
    ref: v5                     # rolling major tag (current line); see docs/VERSIONING.md
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

> ⚠️ **A failed remote fetch fails SILENTLY.** If Lefthook can't reach the repo (no
> access, wrong URL), it prints `Couldn't sync … Will continue anyway`, **exits 0, and
> leaves your hooks EMPTY** — and `lefthook validate` still says "All good". You get zero
> protection with no obvious error. **Verify the fetch worked:** confirm
> `.git/info/lefthook-remotes/oc-githooks-<ref>/base.yml` exists, or just use
> `adopt-remotes.sh` (it checks for you). Don't rely on `lefthook validate`.

> **Private-repo auth.** Because `oc-githooks` is private, Lefthook clones it with the
> developer's own git credentials. Default is the **HTTPS** `git_url` — it matches how
> OutCode-Software repos are cloned, so devs are already authenticated for it. If your
> team uses **SSH** keys with OutCode-Software access, override with
> `git_url: git@github.com:OutCode-Software/oc-githooks` (or your SSH-config alias).
> Confirm access first: `git ls-remote <git_url> v5`. **CI** needs its own access: give
> the `git-hooks-mirror` workflow a deploy key or a PAT with read access to `oc-githooks`.

**Getting updates:** with `ref: v5` + `refetch_frequency: 24h`, non-breaking updates
arrive automatically within a day (we fast-forward the rolling major tag on each release). Pin an
exact tag (`ref: v5.0.0`) for reproducible builds and bump deliberately. Breaking changes
ship as the next major tag (`v6`), which a repo opts into deliberately. Full policy in
[`VERSIONING.md`](VERSIONING.md).

---

## Per-stack prerequisites

Hooks run on **staged files** using **your repo's own toolchain**. Each stack needs
its tools installed and, for some, a config file. Verified end-to-end — see
[`VALIDATION.md`](VALIDATION.md).

**Starter configs are shipped automatically.** `install-into-repo.sh` copies a
starter config for stacks that need one — `swift` (`.swiftlint.yml` excluding
`.build`, **required**), `sql` (`.sqlfluff` with the mandatory header), `php`
(`.php-cs-fixer.dist.php`), `ruby` (`.rubocop.yml`) — and never overwrites one you
already have. `remotes`-model repos: copy them from [`configs/<stack>/`](../configs)
in this repo.

**All stacks:** gitignore build/dependency dirs (`node_modules/`, `vendor/`,
`.build/`, `build/`, `coverage/`). If committed, the hooks will lint them.

| Stack | Tools | Required config / notes |
|---|---|---|
| python | ruff, pytest, **pytest-cov**; mypy *(optional)* | type-check is **opt-in** — needs a `[tool.mypy]` config; coverage root auto-detects `apps/` |
| web | prettier, eslint, typescript, vitest, **@vitest/coverage-v8** | `tsconfig.json`, `eslint.config.js` |
| node | prettier, eslint, typescript, **vitest or jest** (auto-detected) | as web; with jest set `collectCoverageFrom` to catch untested files |
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

> **JS stacks run the repo's own binaries from `node_modules/.bin/`, never `npx`.**
> So the dependencies must actually be installed — a repo whose `node_modules` is
> missing fails the hook with `Run: npm ci` rather than reaching out to the registry.
> (`npx tsc` was the specific hazard: the npm package named `tsc` is an abandoned
> 2016 compiler release, not TypeScript.)

## Coverage threshold (central default + per-repo override)

The pre-push coverage gate defaults to **90%**, set centrally by oc-hooks (so a release
can move the org default). A repo can raise its **own** bar without forking the stack —
add an `env:` block overriding `OC_MIN_COVERAGE` on its coverage command in the repo's
committed `lefthook.yml` (this merges over the config pulled from `remotes`):

```yaml
remotes:
  - git_url: https://github.com/OutCode-Software/oc-githooks
    ref: v5
    configs: [base.yml, stacks/flutter.yml]

# raise THIS repo's coverage floor above the org default (90):
pre-push:
  commands:
    flutter-test:              # the coverage command for your stack (table below)
      env:
        OC_MIN_COVERAGE: "95"
```

Coverage command name per stack: `python`→`py-test`, `web`→`web-test`, `node`→`node-test`,
`reactnative`→`rn-test`, `flutter`→`flutter-test`, `swift`→`swift-test`, `kotlin`→`kotlin-test`,
`php`→`php-test`, `laravel`→`laravel-test`, `ruby`→`ruby-test`.

**Python coverage scope** is auto-detected (`apps/` if present, else `.`) and overridable —
see [Python stack knobs](#python-stack-knobs) below.

**Node test runner:** the `node` stack auto-detects the runner — **Vitest** if
`node_modules/.bin/vitest` is present, otherwise **Jest** — so an Express/Drizzle backend on
Vitest and a NestJS service on Jest both use `stacks/node.yml`. Pin it explicitly when a repo
has both installed:

```yaml
pre-push:
  commands:
    node-test:
      env:
        OC_TEST_RUNNER: vitest    # or: jest
```

> Raising a repo's own floor is safe (only stricter). Raising the **org-wide** default in
> oc-hooks is a **breaking** change (it can fail pushes that used to pass) → ships as a new
> major tag, per [`VERSIONING.md`](VERSIONING.md).

## Python stack knobs

The `python` stack reads three environment variables. All are set per-repo with an `env:`
block on the command in your own committed `lefthook.yml` (it merges over `remotes`).

| Var | Default | Purpose |
|---|---|---|
| `OC_COV_SOURCE` | `apps` if an `apps/` dir exists, else `.` | coverage measurement root |
| `OC_MIN_COVERAGE` | `90` | coverage floor (ratchet it up per repo) |
| `OC_PY_RUNNER` | *(empty — runs on the host)* | command prefix used to run `mypy`/`pytest` (e.g. in Docker) |

**Type-checking is opt-in.** `py-typecheck` runs only when mypy is available *and* the repo
has a mypy config (`[tool.mypy]` in `pyproject.toml`, or `[mypy]` in `mypy.ini` / `setup.cfg` /
`.mypy.ini`). Without one it prints a hint and passes — bare `mypy .` on an untyped Django
codebase reports mostly missing third-party stubs and blocks every push. Enable it by adding
the config:

```toml
[tool.mypy]
ignore_missing_imports = true
```

**Docker-first repos** (interpreter, dependencies and DB live in the container, not on the
laptop) set `OC_PY_RUNNER` once so the two pre-push commands run where the toolchain actually
is. Keep it on **pre-push only** — never prefix the pre-commit `ruff` commands, since spinning
up a container on every commit destroys the ~2s commit budget:

```yaml
pre-push:
  commands:
    py-typecheck:
      env:
        OC_PY_RUNNER: "docker compose run --rm -T api"
    py-test:
      env:
        OC_PY_RUNNER: "docker compose run --rm -T api"
```

The `apps/` detection and the mypy-config lookup both run on the **host** (same working tree
that is mounted into the container), so they behave identically either way. `-T` disables TTY
allocation, which keeps hook output clean on older Compose versions.

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

`git commit --no-verify` / `git push --no-verify` skip local hooks — but the free
server-side gates still catch the important cases: **secret scanning + push protection**
block a leaked secret regardless, and **branch-protection rulesets** block direct pushes
to protected branches (see [`CI.md`](CI.md)). Use `--no-verify` only in a genuine
emergency, not as a habit; for a Gitleaks false positive, add an allowlist entry to
`.gitleaks.toml` instead.

---

## Open decisions

One value is still pending ratification (DM working session):

1. **Commit convention.** Conventional Commits is enabled; confirm this is the org standard and set the warn→block date for the ClickUp-ID and branch-name checks.

**Resolved:** the protected-branch set is `develop / stage / prod / main` (the Git→ClickUp doc's `staging` was dropped in favour of the Governance SOP naming). Enforced by the `protected` list in `base.yml` and mirrored in `ci/hooks.yml`.
