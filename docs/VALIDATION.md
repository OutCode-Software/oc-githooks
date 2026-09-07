# Validation

Everything in this repo was **validated by execution**, not by inspection — Lefthook 2.1.10, Gitleaks 8.21.2, git 2.x on Linux, against throwaway repos and a real bare remote. `lefthook validate` returns **All good** on `base.yml` and the original stack files (`python`, `web`, `infra`). A clean commit runs in ~0.3s.

## Local-binary invocation replacing `npx` (2026-09-08, lefthook 2.1.12, npm 10.9.8, macOS)

Throwaway repos extending `stacks/web.yml`. `lefthook validate` = **All good**.

| Case | Repo setup | Expected | Result |
|---|---|---|---|
| A | no `node_modules` at all | block with an actionable message, no registry fetch | ✅ `✗ typescript is not installed here. Run: npm ci` / same for vitest, in 0.03s |
| B | typescript + vitest + coverage installed | pre-push passes | ✅ both commands green |
| C | prettier installed, a badly-formatted staged file | auto-fix still applies | ✅ file reformatted; `{staged_files}` substitutes correctly inside the new multi-line `run:` |

> **What this fixed.** `npx --no-install tsc` does not fail fast on npm 10 — it resolves
> `tsc` from the registry and refuses only for lack of an interactive yes. `tsc` on npm is
> "A deprecated release of the TypeScript compiler" (2.0.4, 2016). The hook was one prompt
> away from typechecking with the wrong compiler, and its failure message named npx internals
> rather than the actual problem.

## `node` test-runner auto-detection (2026-09-08, lefthook 2.1.12, macOS)

Throwaway repos extending `stacks/node.yml`, exercising **both sides of the coverage gate on
both runners** plus the regression guard and the empty case. `lefthook validate` = **All good**.

| Case | Repo setup | Expected | Result |
|---|---|---|---|
| 1 | vitest + `@vitest/coverage-v8`, 100% lines | pass | ✅ `node-test` green |
| 2 | same, uncovered multi-line fn (14.28% lines) | block | ✅ exit 1, `ERROR: Coverage for lines (14.28%) does not meet global threshold (90%)` |
| 3 | jest, 100% lines (**regression guard**) | pass | ✅ `✓ Coverage 100% (>=90%)` |
| 3b | jest, 44.44% lines | block | ✅ exit 1, `✗ Line coverage 44.44% is below the 90% minimum.` |
| 4 | no runner installed | block **with a fix** | ✅ `✗ No test runner found. Install dependencies first (npm ci)…` |
| 5 | `OC_TEST_RUNNER=vitest` explicit | uses vitest | ✅ |

> **Gotcha worth knowing (not a stack bug):** with the v8 provider, a one-line uncovered
> arrow function still counts as a *covered line* (its declaration executes) — case 2 first
> read **100% lines / 33% statements**. The gate is a **line** floor by org policy, so
> single-line dead code can slip under it on any JS stack, `web` included. Multi-line
> uncovered code is caught normally.

## End-to-end validation of all 15 stacks (2026-08-10, lefthook 2.1.10)

Every stack was installed into a throwaway repo via `install-into-repo.sh`, then
exercised with real toolchains: a clean pass, a guard block, formatter auto-fix,
and **both sides of the ≥25% coverage gate**. `lefthook validate` = **All good**
on all 15. This pass **found and fixed 6 real bugs** (see below).

| Stack | validate | pre-commit (pass/block/fix) | pre-push tests | coverage gate (pass+block) | notes |
|---|---|---|---|---|---|
| python | ✅ | ✅ | ✅ mypy+pytest | ✅ blocks 5% / passes | fixed `--cov`→`--cov=.` |
| web | ✅ | ✅ | ✅ tsc+vitest | ✅ blocks 4.76% / passes | best: no blind spot |
| node | ✅ | ✅ | ✅ tsc+jest | ✅ (jest json-summary) | — |
| reactnative | ✅ | ✅ (pattern) | ✅ = node's jest block | ✅ by equivalence to node | identical jest block |
| flutter | ✅ | ✅ | ✅ flutter test | ✅ blocks 6% / passes 50% | lcov parser OK; untested-file blind spot |
| swift | ✅ | ✅ | ✅ swift test | ✅ llvm-cov reads line% (89.66) | needs `.swiftlint.yml` excl `.build`; fixed failure-swallow |
| kotlin | ✅ | ✅ | ✅ gradle test | ✅ blocks 3% / passes | jacoco parser OK; no blind spot |
| php | ✅ | ✅ (fmt/syntax/guard) | ✅ phpstan + phpunit (pcov) | ✅ blocks 4% / passes (live) | fixed multi-path php-cs-fixer; pcov has untested-file blind spot |
| laravel | ✅ | ✅ pint + dd guard | ⏳ `artisan test` needs Laravel app+driver | — | pint+guard live |
| ruby | ✅ | ✅ rubocop -A + guard (ruby 4.0) | ✅ rspec | ✅ blocks 7% / passes 80% (live) | fixed format/lint parallel race |
| infra | ✅ | ✅ fmt autofix + trivy | ✅ validate/tflint | n/a | — |
| docker | ✅ | ✅ hadolint pass/block | n/a | n/a | — |
| shell | ✅ | ✅ shfmt+shellcheck | n/a | n/a | — |
| sql | ✅ | ✅ sqlfluff pass/block | n/a | n/a | needs `.sqlfluff` w/ `[sqlfluff]` header |
| actions | ✅ | ✅ actionlint+yamllint | n/a | n/a | fixed: `yamllint -d relaxed` |

### Bugs found & fixed by this pass
1. **Coverage failure-swallowing** (swift/flutter/kotlin/php/ruby/node/reactnative) —
   multi-line `run:` blocks returned the trailing `echo`'s exit status, so a **failing
   test suite passed the gate**. Fixed: `<test cmd> || exit 1` in every block.
2. **python `--cov`** measured only imported modules → untested files invisible (100%
   when actually 5%). Fixed to `--cov=.`.
3. **swift** `swiftlint --strict` lints `.build/` build artifacts → always fails.
   Requires a `.swiftlint.yml` excluding `.build` (see prerequisites).
4. **actions** default `yamllint` false-positives on valid GitHub workflows. Fixed to
   `yamllint -d relaxed`.
5. **php** `php-cs-fixer fix <file-list>` errors on multiple paths. Fixed to a per-file loop.
6. **sql** stack comment showed an invalid `.sqlfluff` (no `[sqlfluff]` header → crash). Fixed.
7. **Format/lint parallel race** (ruby/kotlin/sql) — pre-commit runs `parallel: true`, so a
   separate non-fixing lint command raced the auto-fixer and read the *pre-fix* file, false-blocking
   a commit that just needed formatting. Collapsed each into one auto-fixing command
   (`rubocop -A` / `ktlint -F` / `sqlfluff fix`) that also exits non-zero on unfixable offenses.

### Coverage "untested file" blind spot (by tool)
A gate only sees code the tests touch unless the tool is told to include all sources:
**python** (fixed via `--cov=.`), **web/vitest** (includes all — no blind spot),
**kotlin/jacoco** & **swift/llvm-cov** (include the whole target — no blind spot),
**flutter/lcov** & **jest** (node/RN) & **ruby/SimpleCov** & **php/pcov** — blind spot
remains; a wholly untested (never-loaded) file may not lower the %. (php with Xdebug +
`includeUncoveredFiles` avoids it.) Documented in each stack; teams should configure
`collectCoverageFrom` (jest) / a barrel-import test (flutter) / SimpleCov filters as needed.

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
