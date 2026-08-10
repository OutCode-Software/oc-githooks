# Hooks catalog

Every hook we run today, plus the full menu of what git hooks *can* do and what we could add. Legend: **In use** = shipped in `base.yml`/`stacks/` · **Candidate** = sensible to add · **Rarely** = niche.

## What we run today

### `pre-commit` (base — all repos)

| Command | Blocks? | What it does |
|---|---|---|
| `secret-scan` | ✅ | `gitleaks git --staged --verbose --redact` — secrets in staged changes (fails closed if gitleaks missing) |
| `secret-file-guard` | ✅ | blocks `.env`, `*.pem/p12/pfx/key/keystore/jks`, `id_rsa`, `service-account*.json`, `*.tfstate`, `.npmrc`, `.pypirc` — allows `.env.example/.sample/.template/.dist` |
| `large-file-guard` | ✅ | blocks files >5 MB (use Git LFS) |
| `merge-conflict-markers` | ✅ | blocks `<<<<<<< ` / `>>>>>>> ` markers (won't false-positive on Markdown `=======` headings) |
| `normalize-whitespace` | auto-fix | trims trailing whitespace, ensures final newline (text files; re-stages) |
| `protected-branch-guard` | ✅ | no direct commits to `develop/stage/prod/main` |

### `commit-msg` (base)

| Command | Blocks? | What it does |
|---|---|---|
| `conventional-commit` | ✅ | enforces the [commit convention](COMMIT_CONVENTION.md) |
| `subject-length` | warn | warns over 72 chars |
| `clickup-task-id` | warn | warns if no `ENS-123`-style ID present |
| `no-ai-coauthor` | ✅ | blocks the `Co-Authored-By: Claude` trailer |

### `pre-push` (base)

| Command | Blocks? | What it does |
|---|---|---|
| `protected-branch-push-guard` | ✅ | blocks push to a protected branch, **including `git push origin HEAD:main`** (reads git's ref list via `use_stdin`, `priority:1`) |
| `no-wip-fixup-push` | ✅ | blocks pushing `WIP` / `fixup!` / `squash!` commits |
| `branch-name` | warn | expects `feature|fix|chore|hotfix/<TASKID>-desc` |

### Per-stack layers

- **Python** (`stacks/python.yml`): `ruff format` + `ruff check --fix` (pre-commit), no `pdb`/`breakpoint()`/`ipdb`; `mypy` + `pytest -x -q` (pre-push).
- **Web** (`stacks/web.yml`): `prettier --write` + `eslint --fix` (pre-commit), no `debugger`, no `.only` focused tests; `tsc --noEmit` + `vitest run --changed` (pre-push).
- **Mobile** (`stacks/mobile.yml`): `dart format` + `dart analyze` (pre-commit), warn on `print()`; `flutter analyze` + `flutter test` (pre-push).
- **Infra** (`stacks/infra.yml`): `terraform fmt` + block `.tfstate`/`.terraform/` + `trivy config` (pre-commit); `terraform validate` + `tflint` (pre-push).

---

## The full git-hook menu

### There is **no `post-push` hook**

Git has no client hook that fires *after* a push. The client push lifecycle ends at `pre-push` (fires before data is sent; can block). Anything that must react after a push runs **server-side** — on GitHub that's **branch-protection rulesets** and **Actions triggered `on: push`** (our CI mirror). That's the correct place for authoritative enforcement, since a client hook can always be skipped with `--no-verify`.

### Client-side hooks

| Hook | Fires when | Can block? | Status |
|---|---|---|---|
| `pre-commit` | before a commit is created | ✅ | **In use** |
| `prepare-commit-msg` | before the editor opens | ✅ | **Candidate** — auto-insert the ClickUp ID from the branch name |
| `commit-msg` | after the message is written | ✅ | **In use** |
| `post-commit` | after the commit | ❌ (advisory) | **Candidate** — reminders/notifications only |
| `pre-merge-commit` | before a merge commit | ✅ | Rarely |
| `post-merge` | after `merge`/`pull` | ❌ | **Candidate** — "lockfile changed, reinstall deps" |
| `post-checkout` | after branch switch | ❌ | **Candidate** — deps/LFS reminder |
| `pre-rebase` | before a rebase | ✅ | **Candidate** — refuse rebasing a published branch |
| `post-rewrite` | after `amend`/`rebase` | ❌ | Rarely |
| `pre-push` | before push data is sent | ✅ | **In use** |
| `pre-auto-gc` | before automatic `gc` | ✅ | Rarely |

### Server-side (the authoritative layer)

| Git server hook | GitHub equivalent we use | Purpose |
|---|---|---|
| `pre-receive` / `update` | **branch-protection rulesets** | reject bad pushes at the source (no direct push/force-push/delete; required reviews + checks) |
| — | **secret scanning + push protection** | block secrets even when the local hook was skipped |
| `post-receive` | **Actions `on: push` / `on: pull_request`** (CI mirror) | full lint/typecheck/test/SAST/SCA; deploy; update ClickUp status |

---

## Ideas we could add (pick-list)

**base pre-commit:** case-insensitive filename-collision guard · non-ASCII filename guard · TODO/FIXME-without-ticket warn · lockfile/manifest in-sync check.
**Python:** `no print()` warn · `bandit` quick SAST on staged files · forbid bare `# type: ignore`.
**Web:** `console.log` warn · block imports from `dist/` · package-lock in-sync check.
**Mobile:** `pubspec.lock` committed check · forbid `// ignore:` without a reason.
**Infra:** forbid `*.tfvars` with obvious secrets · require provider lockfile.
**commit-msg:** make ClickUp-ID a *block* after grace period · forbid trailing period · imperative-mood lint.
**pre-push:** Gitleaks over the outgoing commit range (catches `--no-verify` commits) · block force-push to shared branches.
**post-merge / post-checkout:** "your lockfile changed — run `npm ci` / `flutter pub get` / `uv sync`" · auto `git lfs pull`.

Suggest additions via [the feedback process](FEEDBACK.md).
