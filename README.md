# oc-githooks

Outcode's shared **git hooks** standard — one baseline every repository inherits, with thin per-stack layers for each language and framework we use (11 language stacks + 4 cross-cutting overlays). Built on [Lefthook](https://lefthook.dev) (a single fast Go binary, no language runtime required) plus [Gitleaks](https://github.com/gitleaks/gitleaks) for secret scanning.

> **Status: pilot.** This is a draft for real repos to trial and give feedback on before it becomes the org standard. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to send feedback, and [`docs/FEEDBACK.md`](docs/FEEDBACK.md) for the template.

---

## What it does

**Fast local feedback on every commit and push, backed by an un-bypassable CI mirror** (defense-in-depth — local hooks can be skipped with `--no-verify`, so GitHub branch-protection + CI remain the real gate).

On **commit** (`pre-commit` + `commit-msg`):

- 🔐 **Secret scan** of staged changes (Gitleaks) — blocks commits containing keys/tokens/credentials.
- 🚫 **Credential-file guard** — blocks `.env`, `*.pem`, keystores, `*.tfstate`, `.npmrc`, service-account JSON… (allows `.env.example`/`.sample`/`.template`).
- 📦 **Large-file guard** (>5 MB → use Git LFS), **merge-conflict-marker** check, **whitespace/EOF** auto-fix.
- 🌿 **Protected-branch guard** — no direct commits to `develop` / `stage` / `prod` / `main`.
- 📝 **Commit message** must follow [Conventional Commits](docs/COMMIT_CONVENTION.md) (`feat(scope): …`, `fix: …`, …); warns on missing ClickUp task ID; blocks the `Co-Authored-By: Claude` trailer.

On **push** (`pre-push`):

- 🚧 **Protected-branch push guard** — blocks pushing to a protected branch, **including remapped `git push origin HEAD:main`**.
- 🧹 Blocks pushing **WIP / fixup! / squash!** commits; warns on non-standard branch names.
- Runs the stack's **type-check + tests** (see each stack layer).

**Language stacks:** **Python** (ruff, mypy, pytest), **Web** (prettier, eslint, tsc, vitest, no `debugger`/`.only`), **Node/NestJS** (prettier, eslint, tsc, jest), **Flutter** (dart format/analyze, flutter test), **Swift** (swiftformat, swiftlint, swift test), **Kotlin** (ktlint, gradle test), **React Native** (prettier, eslint, tsc, jest, no `debugger`/`console.log`), **PHP** (php-cs-fixer, phpstan, phpunit), **Laravel** (pint, larastan, `artisan test`), **Ruby/Rails** (rubocop, rspec), **Infra** (terraform fmt/validate, tflint, trivy). Test stacks enforce a **≥25% coverage gate** on pre-push.

**Cross-cutting overlays** (add alongside a language stack): **docker** (hadolint), **shell** (shfmt, shellcheck), **sql** (sqlfluff), **actions** (actionlint, yamllint). Full list in [`docs/HOOKS_CATALOG.md`](docs/HOOKS_CATALOG.md).

All 15 stacks were **validated end-to-end** — installed into throwaway repos and exercised with real toolchains (clean pass, guard block, formatter auto-fix, and both sides of the coverage gate). That pass found and fixed 7 real bugs. See [`docs/VALIDATION.md`](docs/VALIDATION.md).

---

## Quick start (adopt in one repo)

From this folder, install into a target repo in one command:

```bash
scripts/install-into-repo.sh <python|web|node|flutter|swift|kotlin|reactnative|php|laravel|ruby|infra|docker|shell|sql|actions> /path/to/your/repo
```

Then, in your repo:

```bash
brew install lefthook gitleaks     # macOS  (or: npm install -g lefthook)
lefthook install                   # activate the hooks in this clone
git add .githooks lefthook.yml .gitleaks.toml .github/workflows/hooks.yml
```

That's it — the next commit runs the hooks. Prefer to do it by hand, or want the auto-updating `remotes` setup instead of copied files? See [`docs/INSTALL.md`](docs/INSTALL.md).

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
├── ci/hooks.yml              # CI mirror — copy to .github/workflows/
├── scripts/install-into-repo.sh
├── .gitleaks.toml            # secret-scan allowlist template
└── docs/
    ├── INSTALL.md            # detailed install, `remotes` path, per-stack prerequisites
    ├── VERSIONING.md         # tag scheme + how updates reach repos
    ├── COMMIT_CONVENTION.md  # the commit-message rules, with examples
    ├── HOOKS_CATALOG.md      # every hook we run + the full menu of options
    ├── VALIDATION.md         # what was tested and how to re-run it
    └── FEEDBACK.md           # structured feedback template for the pilot
```

## How updates propagate

Published at [`OutCode-Software/oc-githooks`](https://github.com/OutCode-Software/oc-githooks) (private). The recommended setup is Lefthook **`remotes`** — a repo's `lefthook.yml` points at `oc-githooks` pinned to `ref: v2` (current line) with `refetch_frequency: 24h`, so non-breaking updates arrive automatically when we fast-forward the rolling major tag. Copying files in is still supported for the pilot. Full mechanics and the two-tier tag policy are in [`docs/INSTALL.md`](docs/INSTALL.md) and [`docs/VERSIONING.md`](docs/VERSIONING.md).

## Design & policy background

This implements the decisions in the *Outcode Git Hooks Standard — Design & Rollout Plan* and fills the open "git-hooks / pre-commit standard" item in **GitHub Governance SOP §7.4**. Protected branches are set to `develop` / `stage` / `prod` / `main` (Governance SOP naming). The commit convention (Conventional Commits) and the warn→block dates for the ClickUp-ID / branch-name checks are pending final ratification in the DM working session (see [`docs/INSTALL.md`](docs/INSTALL.md#open-decisions)).

## License / ownership

Internal Outcode tooling. Owned by Platform Engineering.
