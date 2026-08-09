# Validation

Everything in this repo was **validated by execution**, not by inspection — Lefthook 2.1.10, Gitleaks 8.21.2, git 2.x on Linux, against throwaway repos and a real bare remote. `lefthook validate` returns **All good** on `base.yml` and all four stack files. A clean commit runs in ~0.3s.

## Commit matrix (base)

| Scenario | Expected | Result |
|---|---|---|
| Clean commit on a feature branch | allow | ✅ |
| First commit on an unborn branch | allow (no blocking error) | ✅ |
| `.env.example` committed | allow | ✅ |
| Markdown setext `=======` heading | allow (not a conflict marker) | ✅ |
| Real secret (GitHub PAT) in a file | **block** (shows rule/file/line) | ✅ |
| `.env` file | **block** | ✅ |
| `*.tfstate` file | **block** | ✅ |
| Trailing whitespace / missing final newline | auto-fix + re-stage | ✅ |
| Non-conventional message | **block** | ✅ |
| `Co-Authored-By: Claude` trailer | **block** | ✅ |
| Direct commit to `develop` | **block** | ✅ |
| 6 MB binary | **block** | ✅ |
| Real conflict markers | **block** | ✅ |

## Push matrix (base, against a real bare remote)

| Scenario | Expected | Result |
|---|---|---|
| Push a feature branch | allow | ✅ |
| Push to `develop` | **block** | ✅ |
| `git push origin HEAD:main` (remap) | **block** | ✅ |
| `git push origin feature:develop` (remap) | **block** | ✅ |
| Push containing a `WIP` commit | **block** | ✅ |
| Push a clean feature branch | allow | ✅ |

## Commit-format matrix

`feat(auth):`, `fix:`, `chore(docs):`, `feat(api)!:`, `refactor(payments/stripe):`, `perf:`, `Merge …`, `Revert "…"` → all pass. `added some things`, `FEAT:`, `feature:`, `feat add x` (no colon) → all blocked. (Full table in [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md).)

## Stack-guard matrix

| Guard | blocks | allows (no false positive) |
|---|---|---|
| Python `breakpoint()` / `import pdb` / `import ipdb` | ✅ | `# comment mentioning pdb` |
| Web `debugger;` | ✅ | `"…debugger…"` inside a string |
| Web `describe.only` / `it.only` | ✅ | a normal `describe/it` |
| Infra `*.tfstate` / `.terraform/` | ✅ | regular `*.tf` files |

## Notable findings from validation

- **Gitleaks `protect --staged` is deprecated (v8.19+)** → we use `gitleaks git --staged --verbose --redact`, which keeps file/line context and honors `.gitleaks.toml`.
- `AKIA…EXAMPLE` is Gitleaks' own allowlisted sample — never use it to test detection (it won't trip).
- **Lefthook consumes git's pre-push stdin itself**, so the protected-branch push guard needs `use_stdin: true` and must be the *sole* stdin consumer (`priority: 1`).
- Use `git symbolic-ref --short -q HEAD` (works on an unborn branch) rather than `git rev-parse --abbrev-ref HEAD`.

## Re-running the checks

```bash
lefthook validate                       # config sanity
lefthook run pre-commit --all-files     # run all pre-commit hooks over the repo
lefthook run pre-push   --all-files
```
