# Pilot feedback template

Trialling oc-githooks on a real repo? Please copy the block below into a ClickUp task (or a GitHub issue on the repo once published) so we can fold your feedback in before this becomes the org standard.

```markdown
## Pilot feedback — oc-githooks

**Repo:**            <name + stack(s): python / web / node / flutter / swift / kotlin / reactnative / php / laravel / ruby / infra / docker / shell / sql / actions>
**Reviewer:**        <your position/title>
**Lefthook / Gitleaks versions:**  <lefthook version> / <gitleaks version>
**OS:**              <macOS / Linux / WSL>

### Setup
- Adoption path:      [ ] installer script   [ ] copied by hand   [ ] remotes
- Time to set up:     <minutes>
- Anything unclear in INSTALL.md?

### False positives (a hook blocked something it shouldn't have)
| Hook | What was blocked | Why it was a false positive |
|------|------------------|-----------------------------|
|      |                  |                             |

### False negatives (something got through that should have been caught)
| Expected block | What slipped through |
|----------------|----------------------|
|                |                      |

### Friction / speed
- Slowest hook and roughly how long: 
- Did anyone reach for `--no-verify`? Why?
- Commit-time felt:   [ ] fine   [ ] noticeable   [ ] annoying

### Coverage
- A check you wish it had:
- A check that feels unnecessary:
- Stack-specific gaps (commands/tools we missed):

### Verdict
- [ ] Adopt as-is
- [ ] Adopt with the changes above
- [ ] Not ready — blocking issues:
```

## What we especially want to know

1. **False positives** — the fastest way to lose trust in hooks. Tell us anything legitimate that got blocked; we'll either fix the rule or add a `.gitleaks.toml` allowlist pattern.
2. **Setup friction** — if adoption took more than ~5 minutes, where did it snag?
3. **Speed** — if any commit felt slow, which hook, and on what kind of change?
4. **Missing / unwanted checks** — especially per-stack (the right `ruff`/`eslint`/`dart`/`terraform` invocations for *your* repo).
5. **The two open decisions** — the [protected-branch set and commit convention](INSTALL.md#open-decisions): does the current behaviour fit your project's git flow?

Small, specific reports beat general impressions — a one-line "hook X blocked file Y which was fine" is exactly what we need.
