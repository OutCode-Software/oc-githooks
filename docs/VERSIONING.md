# VERSIONING — how oc-githooks is versioned and how updates reach repos

oc-githooks is consumed two ways (see [`INSTALL.md`](INSTALL.md)). Only the
`remotes` model auto-updates; the copy model is manual. This doc defines the tag
scheme that makes `remotes` updates predictable.

## Tag scheme (same model as GitHub Actions)

| Tag | Mutable? | Points at | Who pins it |
|---|---|---|---|
| `v5.0.0` | **No** — never moves | one exact release | repos wanting fully reproducible hooks |
| `v5` | **Yes** — fast-forwarded | the latest `v5.x.y` | **current line** — most repos (auto-receive non-breaking updates) |
| `v4` | Yes | the latest `v4.x.y` | repos not yet migrated past the last breaking change |

- **Patch/minor** (new stack, new non-blocking check, fix): cut `vN.(x+1).0` or
  `vN.x.(y+1)`, then **fast-forward `vN`** to it.
- **Breaking** (a new *blocking* check, a renamed stack/config path, a raised
  coverage gate): cut `v(N+1).0.0`. **Do not** move `vN`. Announce a migration note.

> Raising the coverage gate (e.g. the 80% → 90% default bump in v5.0.0) is **breaking** — it can
> fail a push that used to pass. It ships in a new major tag, never as a same-major
> fast-forward.

## How a repo receives updates

```yaml
remotes:
  - git_url: git@github.com:OutCode-Software/oc-githooks
    ref: v5
    refetch_frequency: 24h      # always | never | <duration e.g. 24h/30m>
    configs: [base.yml, stacks/<stack>.yml]
```

- `refetch_frequency: 24h` — Lefthook re-pulls `ref` if >24h since the last fetch.
- `refetch_frequency: always` — re-pull every run (simplest; slight per-run cost).
- To force an update now: re-run `lefthook install`, or clear the cache at
  `.git/info/lefthook-remotes/` and re-run it.

**Recommended Outcode default:** `ref: v5` (current line) + `refetch_frequency: 24h`.

## Release checklist (maintainers)

1. Merge changes to `main`; update `CHANGELOG.md` with the new version + date.
2. Tag the immutable release: `git tag -a vN.x.y -m "…" && git push origin vN.x.y`.
3. Fast-forward the rolling major (non-breaking only):
   `git tag -f -a vN -m "…" && git push -f origin vN`.
4. Announce in the team channel; link the CHANGELOG entry.
5. Breaking change instead? Tag `v(N+1).0.0`, leave `vN` where it is, publish a
   migration note — and bump the `OC_REF` default in `scripts/adopt-remotes.sh`
   plus the `ref:` pins in README/INSTALL/VERSIONING once repos should adopt it.
