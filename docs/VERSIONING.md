# VERSIONING — how oc-githooks is versioned and how updates reach repos

oc-githooks is consumed two ways (see [`INSTALL.md`](INSTALL.md)). Only the
`remotes` model auto-updates; the copy model is manual. This doc defines the tag
scheme that makes `remotes` updates predictable.

## Tag scheme (same model as GitHub Actions)

| Tag | Mutable? | Points at | Who pins it |
|---|---|---|---|
| `v1.2.3` | **No** — never moves | one exact release | repos wanting fully reproducible hooks |
| `v1` | **Yes** — fast-forwarded | the latest `v1.x.y` | most repos (auto-receive non-breaking updates) |
| `v2` | Yes | the latest `v2.x.y` | repos that have migrated past a breaking change |

- **Patch/minor** (new stack, new non-blocking check, fix): cut `v1.(x+1).0` or
  `v1.x.(y+1)`, then **fast-forward `v1`** to it.
- **Breaking** (a new *blocking* check, a renamed stack/config path, a raised
  coverage gate): cut `v2.0.0`. **Do not** move `v1`. Announce a migration note.

> Raising the coverage gate (e.g. the 25% → 50% default bump) is **breaking** — it can
> fail a push that used to pass. It ships in a new major tag, never as a same-major
> fast-forward.

## How a repo receives updates

```yaml
remotes:
  - git_url: git@github.com:OutCode-Software/oc-githooks
    ref: v2
    refetch_frequency: 24h      # always | never | <duration e.g. 24h/30m>
    configs: [base.yml, stacks/<stack>.yml]
```

- `refetch_frequency: 24h` — Lefthook re-pulls `ref` if >24h since the last fetch.
- `refetch_frequency: always` — re-pull every run (simplest; slight per-run cost).
- To force an update now: re-run `lefthook install`, or clear the cache at
  `.git/info/lefthook-remotes/` and re-run it.

**Recommended Outcode default:** `ref: v2` (current line) + `refetch_frequency: 24h`.

## Release checklist (maintainers)

1. Merge changes to `main`; update `CHANGELOG.md` with the new version + date.
2. Tag the immutable release: `git tag -a v1.x.y -m "…" && git push origin v1.x.y`.
3. Fast-forward the rolling major (non-breaking only):
   `git tag -f -a v1 -m "…" && git push -f origin v1`.
4. Announce in the team channel; link the CHANGELOG entry.
5. Breaking change instead? Tag `v2.0.0`, leave `v1` where it is, publish a
   migration note.
