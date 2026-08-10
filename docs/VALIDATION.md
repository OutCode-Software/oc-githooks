# Validation

Everything in this repo was **validated by execution**, not by inspection — Lefthook 2.1.10, Gitleaks 8.21.2, git 2.x on Linux, against throwaway repos and a real bare remote. `lefthook validate` returns **All good** on `base.yml` and the original stack files (`python`, `web`, `infra`). A clean commit runs in ~0.3s.

> **Stack expansion (v1.x, 2026-08-10).** `mobile.yml` was replaced by per-language
> stacks (`flutter`, `swift`, `kotlin`, `reactnative`), and `node`, `php`, `laravel`,
> `ruby` language stacks plus `docker`, `shell`, `sql`, `actions` cross-cutting
> overlays were added. All 15 stack files' YAML parses cleanly (via psych) and every
> **pattern-based guard** below is validated (block + near-miss). The **tool-dependent**
> commands (swiftformat/swiftlint, ktlint, flutter/jest/rspec/phpunit, hadolint,
> shellcheck, sqlfluff, actionlint, and the ≥25% coverage gates) are the documented
> commands but have **not yet been run end-to-end** — pending a machine with those
> toolchains installed (same open caveat as `ruff`/`terraform`). `lefthook validate`
> on the new files is likewise pending (Lefthook not installed in the authoring env).

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
| Web / RN `debugger` (statement, EOL, `debugger()`) | ✅ | `debuggerUtil`, `mydebugger` (fixed: trailing boundary) |
| Web / RN `describe.only` / `it.only` | ✅ | a normal `describe/it`; `const onlyThing` |
| Flutter / Swift `print(` | ✅ (warn) | `debugPrint(`, `sprint(` |
| Kotlin `println(` | ✅ (warn) | `myprintln(` |
| React Native / Node `console.log` / `console.debug` | ✅ (warn) | `console.error`, `myconsole.log` |
| PHP `var_dump(`/`dd(`/`print_r(` | ✅ (warn) | `$obj->dump()` method call |
| Laravel `dd(`/`dump(`/`ray(` | ✅ (block) | `$collection->dump()` method call |
| Ruby `binding.pry`/`byebug`/`debugger` | ✅ (block) | `my_byebug` identifier |
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
