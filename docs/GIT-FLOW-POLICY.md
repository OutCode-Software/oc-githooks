# OutCode Git Flow Policy

**Version:** 1.1 · **Status:** Final, ready for sign-off · **Applies to:** every repository in `OutCode-Software`
**Owner:** Engineering (Ashwin Shrestha) · **Last updated:** 2026-10-13

This policy defines how code moves from a developer's branch to production. oc-githooks
(v6 and later), the daily audit and the deploy guards are built against it.

---

## 1. Branches

| Branch | Lifetime | Purpose | Deploys to |
|---|---|---|---|
| `main` | Permanent | Code released to staging; the source of production tags | **Staging** (on every merge) |
| `develop` | Permanent | Integration branch for finished work | Nothing |
| Task branches | Short-lived | One ClickUp task each | Nothing |

- `main` and `develop` are the **only** long-lived branches, and the only protected ones.
  Nobody commits or pushes to them directly, in a terminal or in the GitHub web editor.
- A new project creates `main` first, then creates `develop` from `main`, and sets
  `develop` as the default branch so PRs target it.
- `stage`, `staging`, `prod`, `production`, `dev`, `development` and `master` branches are
  not used. See [§9 Migration](#9-migration-of-existing-repos).

### Branch naming

A task branch is named with **just the ClickUp task ID**, with no type prefix:

```
CU-86e3m6v34
```

- The format is `^CU-[0-9a-z]+$`. Hotfix branches use the same format: a branch is a
  hotfix because it was created from a release tag and its PR targets `main` (§5).
- The type of change is recorded where it's needed: in the Conventional Commit subject of
  each commit and of the PR title (§2).

### ClickUp linking

ClickUp links GitHub activity to a task when `CU-<id>` appears in the branch name, a
commit message, or the PR title or description. oc-githooks adds two trailers to every
commit, so nobody has to type the ID:

```
fix: handle empty name

ClickUp: CU-86e3m6v34
OC-Hooks: v6.0.0
```

- `ClickUp:` comes from the branch name. It keeps the task's commit history intact after
  the branch is squash-merged and deleted.
- `OC-Hooks:` marks the commit as made with the hooks installed. Both trailers are added
  even with `git commit --no-verify`.

---

## 2. Day-to-day work: task branch → `develop`

1. Create the branch from the latest `develop`: `git switch -c CU-86e3m6v34 develop`
2. Commit using [Conventional Commits](COMMIT_CONVENTION.md).
3. Push the branch and open a PR into `develop`. The **PR title is a Conventional Commit
   subject** (`feat(auth): add SSO login`), because it becomes the commit on `develop`.
4. The PR needs at least **one approving review from anyone other than the author**. The
   author can never approve their own PR. This applies to every project, including
   single-developer projects.
5. **Squash and merge**, then delete the branch. `develop` gets one commit per task.

---

## 3. Release to staging: `develop` → `main`

1. Open a PR from `develop` into `main`.
2. It needs at least **one approving review from anyone other than the author**.
3. Merge it with **"Create a merge commit"**. Never squash or rebase it: either would
   rewrite commit IDs and cause every later `develop → main` PR to conflict.
4. When the merge lands, a GitHub Action deploys `main` to **staging**.

If a problem is found on staging, fix it forward: open a new task branch from `develop`
and repeat §2–§3. Nobody commits directly to `main`.

---

## 4. Release to production: tag `main`, then deploy

1. Confirm that staging has been accepted.
2. Get the **DM's sign-off** for the release. The sign-off can be given verbally; it isn't
   recorded anywhere.
3. Create an annotated tag on `main` and push it. The tag push **builds and tests the
   release**; it does not deploy it.

   ```bash
   git switch main && git pull
   git tag -a 1.4.0 -m "Release 1.4.0"
   git push origin 1.4.0
   ```

4. When that run has passed, **deploy it by hand**: in GitHub, **Actions → Deploy production →
   Run workflow**, enter `1.4.0`. This deploys the artifact the tag built, without rebuilding
   it, and the run records who pressed the button. Production never deploys automatically.

**Rules**
- **Format:** `MAJOR.MINOR.PATCH`, with **no `v` prefix**: `1.4.0`, `1.4.1`, `2.0.0`. Other
  formats don't build a release.
- **Tag only commits that are on `main`** and have already been deployed to staging. The
  one exception is the hotfix flow in §5.
- **Who can tag and deploy:** any developer, once the DM has signed off.
- **Rolling back:** run Deploy production with the previous tag (while its build artifact is
  still kept), or switch to the previous
  release on the server (§8).
- Tags are **never moved or deleted**. If a release is bad, ship a new version.

---

## 5. Hotfixes

Use this flow when production is broken and `main` contains work that hasn't been
released yet.

```
1.4.2 (prod) ──► CU-86e3m6v34   (branched from the tag)
                     │
                     ├─ 1. fix, then open a PR into main (reviewed by anyone but the author)
                     ├─ 2. after approval + DM sign-off: tag 1.4.3 on this branch, then Deploy production ──► production
                     ├─ 3. merge the PR into main with a MERGE COMMIT ──► staging redeploys
                     └─ 4. merge into develop with a MERGE COMMIT the same day, then delete the branch
```

1. **Branch from the latest production tag:** `git switch -c CU-86e3m6v34 1.4.2`
2. **Open the PR into `main` before tagging**, so the fix is reviewed before it ships.
3. **Tag the approved commit on the hotfix branch, then run Deploy production for that tag**
   (§4). This sends only the last release plus the fix to production, and none of the
   unreleased work on `main`. The deploy guard
   accepts a tag that isn't on `main` only when its commit is the head of a PR into `main`.
4. **Merge into `main` with a merge commit, never squash.** This keeps the tagged commit in
   `main`'s history.
5. **Merge back into `develop` with a merge commit**, either with a second PR from the
   hotfix branch into `develop` or a PR from `main` into `develop`. This is the one PR into
   `develop` that isn't squashed: the tagged commit must be in `develop`'s history too. Do
   it the same day.

### Emergencies outside working hours

If production is down and no reviewer is available, the hotfix may be tagged and deployed
**without approval**. The PR must still be opened, and must be reviewed **within 24 hours**. The
audit flags the release until that review happens.

---

## 6. Reviews

| PR | Merge method | Required approval |
|---|---|---|
| Task branch → `develop` | Squash | Anyone other than the author |
| `develop` → `main` | Merge commit | Anyone other than the author |
| Hotfix → `main` | Merge commit | Anyone other than the author (within 24h after the release, in an emergency) |
| Hotfix or `main` → `develop` | Merge commit | Anyone other than the author |
| Dependabot / bot PRs | Squash | A human reviewer, the same as any other PR |

A PR that is merged without an approval from someone other than its author is a violation.

### Repository settings

These are available on GitHub Free and are part of adopting the policy:

- Default branch: `develop`.
- Allow **squash merging** (default message: *Pull request title and commit details*, so
  the `ClickUp:` trailers carry over) and **merge commits**. Disable rebase merging.
- Automatically delete head branches.

---

## 7. Enforcement

OutCode is on **GitHub Free**, which can't enforce branch protection, required reviews,
tag rules or protected environments on private repositories. It also can't limit who may
run the Deploy production workflow: anyone with write access can press it. The policy is enforced with
three layers instead:

| Layer | What it does | Limits |
|---|---|---|
| **oc-githooks v6 (Lefthook)** | Blocks commits on `main`/`develop`; pushes to `main`/`develop` (including `HEAD:main` and deletions); branch names other than `CU-<id>`; tags that aren't `MAJOR.MINOR.PATCH` or that move or delete an existing tag; non-Conventional commit messages. Adds the `ClickUp` and `OC-Hooks` trailers | Only works after `lefthook install`. It can be bypassed with `--no-verify`, and it doesn't run for GitHub web edits |
| **Deploy guard on each server** | Re-checks every deployment against GitHub itself: staging only from `main`; production only from a valid tag whose commit is on `main` or is the head of a PR into `main`. Logs every attempt | A workflow can't edit it, but it trusts the artifact the workflow hands it (artifact signing is phase 2) |
| **Daily audit + weekly summary** | Reports direct pushes, PRs merged without a non-author approval, tags not on `main`, who created each tag, who deployed each release to production, and commits without the `OC-Hooks` trailer | Detects violations after the fact. It doesn't prevent them |

**Follow-up:** the audit runs daily, and a weekly summary covers all projects. The
engineering team talks to each developer named in a violation.

Every developer runs `lefthook install` in each repo they clone (npm projects can do it
from the `prepare` script).

---

## 8. CI/CD

| Event | CI | CD |
|---|---|---|
| Push to a task branch, PR into `develop` | None. The developer's pre-push hook runs lint and tests | — |
| Push to `develop` | Lint + test | — |
| PR `develop` → `main` | Lint + test + build | — |
| Merge to `main` | Build the artifact | Deploy to **staging** |
| Tag `X.Y.Z` | Lint + test + build the artifact from the tagged commit | None: the release is ready to deploy |
| **Deploy production** (run by hand) | — | Deploy that tag's artifact to **production** |

- **CI and CD run in different places.** CI runs untrusted branch code, so its runners hold
  **no deploy credentials**. CD runs on a runner on (or dedicated to) each environment, which
  can deploy only that environment.
- **Production deploys only when someone runs Deploy production.** It's a manual workflow
  (`workflow_dispatch`) that takes the tag, finds that tag's passed build and deploys its
  artifact. On GitHub Team or Enterprise the same step can also require a named approver
  (a protected environment); GitHub Free doesn't offer that for private repos.
- **Production servers never build or test.** They install a finished artifact and restart.
- Every deployment goes through the deploy guard (§7). After a deploy, the workflow checks
  that the running service reports the expected commit.
- Keep the last few releases on each server, so a rollback is a switch to the previous
  release, not a rebuild.

---

## 9. Migration of existing repos

All active repositories move to this flow **within 30 days** of the policy's approval.

1. Rename `master` → `main` where needed.
2. Create `develop` from `main` if it doesn't exist, and make it the default branch.
3. Apply the repository settings in §6.
4. Adopt oc-githooks **v6** (`scripts/adopt-remotes.sh <stack> <repo>`, or set `ref: v6` in an
   existing `remotes` block). v6 blocks branch names other than `CU-<id>`, so rename open
   branches first.
5. Change the deployment workflows: a merge to `main` deploys staging, a tag builds the
   release, and Deploy production (run by hand) deploys it, through a deploy guard.
6. After the first production release from a tag, freeze the old `stage` / `staging` /
   `prod` / `production` / `dev` branches, then delete or archive them. The hooks allow
   deleting remote branches for this.

---

## 10. Open items

These are outside version 1.0 and will be decided separately:

- **Production secrets for other deploy targets.** The pilot covers AWS EC2 with a runner on
  each server. VPS, Vercel/Netlify and other targets need their own answer, because on the
  Free plan repository secrets can be read by any workflow on any branch.
- **Mobile apps:** what a merge to `main` deploys (TestFlight or a Play internal track), and
  how the build number relates to the tag.
- **Artifact signing or promotion** between CI and the deploy guard (phase 2).
