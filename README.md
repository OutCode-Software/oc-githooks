# oc-githooks

Outcode's shared **git hooks** standard — one baseline every repository inherits, with thin per-stack layers for backend, web, mobile, and infrastructure. Built on [Lefthook](https://lefthook.dev) (a single fast Go binary, no language runtime required) plus [Gitleaks](https://github.com/gitleaks/gitleaks) for secret scanning.

> **Status: pilot.** This is a draft for real repos to trial and give feedback on before it becomes the org standard. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to send feedback, and [`docs/FEEDBACK.md`](docs/FEEDBACK.md) for the template.

---

## What it does

**Fast local feedback on every commit and push, backed by an un-bypassable CI mirror** (defense-in-depth — local hooks can be skipped with `--no-verify`, so GitHub branch-protection + CI remain the real gate).

On **commit** (`pre-commit` + `commit-msg`):

- 🔐 **Secret scan** of staged changes (Gitleaks) — blocks commits containing keys/tokens/credentials.
- 🚫 **Credential-file guard** — blocks `.env`, `*.pem`, keystores, `*.tfstate`, `.npmrc`, service-account JSON… (allows `.env.example`/`.sample`/`.template`).
- 📦 **Large-file guard** (>5 MB → use Git LFS), **merge-conflict-marker** check, **whitespace/EOF** auto-fix.
- 🌿 **Protected-branch guard** — no direct commits to `develop` / `stage` / `staging` / `prod` / `main`.
- 📝 **Commit message** must follow [Conventional Commits](docs/COMMIT_CONVENTION.md) (`feat(scope): …`, `fix: …`, …); warns on missing ClickUp task ID; blocks the `Co-Authored-By: Claude` trailer.

On **push** (`pre-push`):

- 🚧 **Protected-branch push guard** — blocks pushing to a protected branch, **including remapped `git push origin HEAD:main`**.
- 🧹 Blocks pushing **WIP / fixup! / squash!** commits; warns on non-standard branch names.
- Runs the stack's **type-check + tests** (see each stack layer).

Per-stack extras: **Python** (ruff format/lint, mypy, pytest, no `pdb`/`breakpoint()`), **Web** (prettier, eslint, tsc, vitest, no `debugger`, no `.only` focused tests), **Mobile** (dart format/analyze, flutter test), **Infra** (terraform fmt/validate, tflint, trivy, no committed state). Full list in [`docs/HOOKS_CATALOG.md`](docs/HOOKS_CATALOG.md).

Everything here was **validated by execution** (lefthook 2.1.10, gitleaks 8.21.2) — see [`docs/VALIDATION.md`](docs/VALIDATION.md).

---

## Quick start (adopt in one repo)

From this folder, install into a target repo in one command:

```bash
scripts/install-into-repo.sh <python|web|mobile|infra> /path/to/your/repo
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
├── stacks/
│   ├── python.yml            # Python / FastAPI layer
│   ├── web.yml               # Next.js / TypeScript layer
│   ├── mobile.yml            # Flutter / Dart layer
│   └── infra.yml             # Terraform / IaC layer
├── examples/                 # per-repo lefthook.yml to copy (uses `extends`)
├── ci/hooks.yml              # CI mirror — copy to .github/workflows/
├── scripts/install-into-repo.sh
├── .gitleaks.toml            # secret-scan allowlist template
└── docs/
    ├── INSTALL.md            # detailed install + the `remotes` upgrade path
    ├── COMMIT_CONVENTION.md  # the commit-message rules, with examples
    ├── HOOKS_CATALOG.md      # every hook we run + the full menu of options
    ├── VALIDATION.md         # what was tested and how to re-run it
    └── FEEDBACK.md           # structured feedback template for the pilot
```

## How updates propagate (once published)

For the pilot, hooks are **copied** into each repo (simple, no dependency). Once `oc-githooks` is published to the Outcode GitHub org, repos switch their `lefthook.yml` to Lefthook `remotes` pinned to a version tag — then a tag bump propagates changes everywhere. Both setups are in [`docs/INSTALL.md`](docs/INSTALL.md).

## Design & policy background

This implements the decisions in the *Outcode Git Hooks Standard — Design & Rollout Plan* and fills the open "git-hooks / pre-commit standard" item in **GitHub Governance SOP §7.4**. Protected-branch names and the commit convention are pending final ratification in the DM working session — the config enforces the union of both documented branch models until then (see [`docs/INSTALL.md`](docs/INSTALL.md#open-decisions)).

## License / ownership

Internal Outcode tooling. Owned by Platform Engineering.
