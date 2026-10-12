# oc-githooks

Outcode's shared **git hooks** standard — one baseline every repository inherits, with thin per-stack layers for each language and framework we use (11 language stacks + 4 cross-cutting overlays). Built on [Lefthook](https://lefthook.dev) (a single fast Go binary, no language runtime required) plus [Gitleaks](https://github.com/gitleaks/gitleaks) for secret scanning.

> **Status: pilot.** This is a draft for real repos to trial and give feedback on before it becomes the org standard. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to send feedback, and [`docs/FEEDBACK.md`](docs/FEEDBACK.md) for the template.

---

## What it does

**Enforces OutCode's [Git Flow policy](docs/GIT-FLOW-POLICY.md) on every commit and push.** On GitHub Free, private repos get no branch protection, so these hooks are the first of three layers: a deploy guard on each server and a daily audit catch what `--no-verify` lets through (see [`docs/CI.md`](docs/CI.md)). An Actions lint/test mirror is opt-in later.

On **commit** (`pre-commit` + `commit-msg`):

- 🔐 **Secret scan** of staged changes (Gitleaks) — blocks commits containing keys/tokens/credentials.
- 🚫 **Credential-file guard** — blocks `.env`, `*.pem`, keystores, `*.tfstate`, `.npmrc`, service-account JSON… (allows `.env.example`/`.sample`/`.template`).
- 📦 **Large-file guard** (>5 MB → use Git LFS), **merge-conflict-marker** check, **whitespace/EOF** auto-fix.
- 🌿 **Protected-branch guard** — no direct commits to `main` / `develop`.
- 📝 **Commit message** must follow [Conventional Commits](docs/COMMIT_CONVENTION.md) (`feat(scope): …`, `fix: …`, …); blocks the `Co-Authored-By: Claude` trailer.
- 🏷️ **Trailers** — every commit gets `ClickUp: CU-<id>` (from the branch name, so the ClickUp task keeps its commit history after a squash merge) and `OC-Hooks: <version>` (the audit flags commits without it).

On **push** (`pre-push`):

- 🚧 **Ref guard** — blocks pushing to `main` / `develop` (**including remapped `git push origin HEAD:main`** and deletions), branch names other than `CU-<clickup-id>`, and tags that aren't `MAJOR.MINOR.PATCH` (no `v`) or that would move or delete an existing tag. Runs on every push, including tag-only and empty pushes.
- 🧹 Blocks pushing **WIP / fixup! / squash!** commits.
- Runs the stack's **type-check + tests** (see each stack layer).

**Language stacks:** **Python/Django** (ruff, pytest, opt-in mypy), **Web** (prettier, eslint, tsc, vitest, no `debugger`/`.only`), **Node/NestJS** (prettier, eslint, tsc, jest), **Flutter** (dart format/analyze, flutter test), **Swift** (swiftformat, swiftlint, swift test), **Kotlin** (ktlint, gradle test), **React Native** (prettier, eslint, tsc, jest, no `debugger`/`console.log`), **PHP** (php-cs-fixer, phpstan, phpunit), **Laravel** (pint, larastan, `artisan test`), **Ruby/Rails** (rubocop, rspec), **Infra** (terraform fmt/validate, tflint, trivy). Test stacks enforce a **≥90% coverage gate** on pre-push.

**Cross-cutting overlays** (add alongside a language stack): **docker** (hadolint), **shell** (shfmt, shellcheck), **sql** (sqlfluff), **actions** (actionlint, yamllint). Full list in [`docs/HOOKS_CATALOG.md`](docs/HOOKS_CATALOG.md).

All 15 stacks were **validated end-to-end** — installed into throwaway repos and exercised with real toolchains (clean pass, guard block, formatter auto-fix, and both sides of the coverage gate). That pass found and fixed 7 real bugs. See [`docs/VALIDATION.md`](docs/VALIDATION.md).

---

## Quick start (adopt in one repo)

**Recommended method: `remotes`** — the repo holds only a small `lefthook.yml` pointer; Lefthook pulls `base.yml` + your stack from this central repo and auto-updates them. Nothing is copied in, so there is **no `.githooks/` folder** to maintain or let go stale. From a clone of this repo:

```bash
scripts/adopt-remotes.sh <python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions> /path/to/your/repo
```

Then, in your repo:

```bash
brew install lefthook gitleaks     # macOS  (or: npm install -g lefthook)
lefthook install                   # activate the hooks in this clone
git add lefthook.yml .gitleaks.toml
```

That's it — the next commit runs the hooks, and non-breaking updates arrive automatically. `adopt-remotes.sh` also **verifies the remote actually fetched** (a failed fetch fails silently — see [`docs/INSTALL.md`](docs/INSTALL.md)).

> **Fallback: copy method.** Only if a repo/CI can't reach the private `oc-githooks` (air-gapped, no access), copy the files in instead — this creates a committed `.githooks/` folder that must be updated by hand. See [Option A in `docs/INSTALL.md`](docs/INSTALL.md#option-a--copy-the-files-fallback).

---

## Repository layout

```
oc-githooks/
├── base.yml                  # base hooks — every repo inherits these
├── stacks/                   # language stacks + cross-cutting overlays
│   ├── python.yml            # Python / FastAPI
│   ├── web.yml               # Next.js / TypeScript
│   ├── node.yml              # Node.js / NestJS backend
│   ├── flutter.yml           # Flutter / Dart
│   ├── swift.yml             # iOS / Swift
│   ├── kotlin.yml            # Android / Kotlin
│   ├── reactnative.yml       # React Native (JS/TS)
│   ├── php.yml               # PHP
│   ├── laravel.yml           # Laravel (PHP)
│   ├── ruby.yml              # Ruby / Rails
│   ├── infra.yml             # Terraform / IaC
│   ├── docker.yml            # Dockerfile (cross-cutting)
│   ├── shell.yml             # shell scripts (cross-cutting)
│   ├── sql.yml               # SQL (cross-cutting)
│   └── actions.yml           # GitHub Actions + YAML (cross-cutting)
├── examples/                 # per-repo lefthook.yml to copy (uses `extends`)
├── configs/                  # starter tool configs (.swiftlint.yml, .sqlfluff, …)
├── ci/hooks.yml              # CI mirror TEMPLATE (opt-in later; see docs/CI.md)
├── scripts/install-into-repo.sh   # copy method
├── scripts/adopt-remotes.sh       # one-command `remotes` (auto-update) setup
├── .lefthook/pre-push/ref-guard.sh  # Git Flow ref rules (a Lefthook script, see base.yml)
├── tests/run.sh              # end-to-end test of base.yml through `remotes`
├── .gitleaks.toml            # secret-scan allowlist template
└── docs/
    ├── INSTALL.md            # detailed install, `remotes` path, per-stack prerequisites
    ├── CI.md                 # server-side gate: free GitHub protections now, Actions later
    ├── VERSIONING.md         # tag scheme + how updates reach repos
    ├── GIT-FLOW-POLICY.md    # the branch / review / release policy these hooks enforce
    ├── COMMIT_CONVENTION.md  # the commit-message rules, with examples
    ├── HOOKS_CATALOG.md      # every hook we run + the full menu of options
    ├── VALIDATION.md         # what was tested and how to re-run it
    └── FEEDBACK.md           # structured feedback template for the pilot
```

## How updates propagate

Published at [`OutCode-Software/oc-githooks`](https://github.com/OutCode-Software/oc-githooks) (private). The recommended setup is Lefthook **`remotes`** — a repo's `lefthook.yml` points at `oc-githooks` pinned to `ref: v6` (current line) with `refetch_frequency: 24h`, so non-breaking updates arrive automatically when we fast-forward the rolling major tag. Copying files in is still supported for the pilot. Full mechanics and the two-tier tag policy are in [`docs/INSTALL.md`](docs/INSTALL.md) and [`docs/VERSIONING.md`](docs/VERSIONING.md).

## Design & policy background

This implements the decisions in the *Outcode Git Hooks Standard — Design & Rollout Plan* and fills the open "git-hooks / pre-commit standard" item in **GitHub Governance SOP §7.4**. Since v6 the branch, tag and commit rules follow the [Git Flow policy](docs/GIT-FLOW-POLICY.md): `main` and `develop` are the protected branches, task and hotfix branches are `CU-<clickup-id>`, and releases are `MAJOR.MINOR.PATCH` tags. Run `tests/run.sh` to check the rules end to end.

## License / ownership

Internal Outcode tooling. Owned by Platform Engineering.
