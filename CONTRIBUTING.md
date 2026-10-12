# Contributing to oc-githooks

This is a **pilot**. The goal right now is to trial the hooks on real repos and gather feedback before this becomes the org standard. Contributions of feedback are as valuable as code.

## Sending feedback (the main ask right now)

Use the template in [`docs/FEEDBACK.md`](docs/FEEDBACK.md). Focus on: false positives, setup friction, speed, and missing/unwanted checks per stack. Small and specific beats general.

## Changing a hook

1. **Edit** `base.yml` (all repos) or the relevant `stacks/<stack>.yml` (one stack only). Keep the base minimal — stack-specific logic belongs in a stack file.
2. **Validate**: `lefthook validate`.
3. **Prove it by running it** — don't eyeball. Create a throwaway repo, install the config, and test both the block case *and* a near-miss that must *not* be blocked (false-positive guard). Add the scenario to [`docs/VALIDATION.md`](docs/VALIDATION.md).
4. **Keep it fast.** Commit-time budget is ~2s; anything heavier (typecheck, tests, build) belongs on `pre-push` or in CI, not `pre-commit`.
5. **Fail with a fix, not just a "no."** Every blocking hook prints the command or action to remediate.
6. **Update docs in the same change** — the hook and its entry in `HOOKS_CATALOG.md` / `COMMIT_CONVENTION.md` move together.
7. **Bump `CHANGELOG.md`** and, once published, the version tag.

## Branches and releases

This repo follows the same [Git Flow](docs/GIT-FLOW-POLICY.md) as every OutCode project, with
one difference: **`main` stays the default branch**, because it is the released line.

- Branch from `develop` as `CU-<clickup-id>` (create a ClickUp task), open a PR into `develop`,
  get one approval from someone other than the author, then **squash and merge**.
- Release: a PR `develop → main` merged with a **merge commit**, then the version tags in
  [`docs/VERSIONING.md`](docs/VERSIONING.md#release-checklist-maintainers). This repo's own `vN`
  tags are the one exception to "tags never move": the rolling major tag is how `remotes`
  delivers updates.
- Nobody commits or pushes to `main` or `develop` directly.

## Principles

- **Defense-in-depth:** local hooks are fast feedback, not the only gate. On GitHub Free, private repos get no branch rulesets, so the deploy guard and the daily audit catch what `--no-verify` lets through ([CI.md](docs/CI.md)); the opt-in CI mirror adds lint and tests.
- **Portable:** hooks run on macOS and Linux. Avoid GNU-only flags (e.g. `sed -i` without a suffix); prefer `perl -i`, POSIX `grep -E`, and the `git symbolic-ref` / `git cat-file` plumbing already used.
- **One fact, one home:** don't duplicate policy across base and stack files.

## Local dev quickstart

```bash
brew install lefthook gitleaks
# make a scratch repo, drop base.yml + a stack in .githooks/, add a lefthook.yml that extends them, then:
lefthook install && lefthook validate
```

## Repository layout

```
oc-githooks/
├── base.yml                         # base hooks: every repo inherits these
├── stacks/                          # one file per language stack or overlay
├── .lefthook/pre-push/ref-guard.sh  # Git Flow ref rules (a Lefthook script, see base.yml)
├── examples/                        # per-repo lefthook.yml to copy (copy method)
├── configs/                         # starter tool configs (.swiftlint.yml, .sqlfluff, …)
├── ci/hooks.yml                     # CI mirror template (opt-in, see docs/CI.md)
├── scripts/adopt-remotes.sh         # `remotes` setup (recommended)
├── scripts/install-into-repo.sh     # copy method
├── tests/run.sh                     # end-to-end test of base.yml through `remotes`
├── .gitleaks.toml                   # secret-scan allowlist template
└── docs/                            # policy, install, catalog, versioning, validation
```

Run `tests/run.sh` before opening a PR that touches `base.yml` or the ref guard.
