# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`TransformerThermalModel.jl` is a Julia package (currently in early development) for transformer thermal modeling. The package is structured following the BestieTemplate.jl conventions.

## Commands

### Running Tests

```julia-repl
julia> # press ]
pkg> activate .
pkg> test
```

To run tests from the shell:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

### Formatting and Linting

Julia code is formatted with JuliaFormatter (4-space indent, 92-char margin). Always run prek after making changes:

```bash
prek run -a
```

To format Julia files only:

```julia-repl
julia> using JuliaFormatter; format(".")
```

### Building Documentation Locally

```bash
julia --project=docs
```

Then in the Julia REPL:

```julia-repl
pkg> dev .   # first time only
julia> using LiveServer; servedocs()
```

## Code Architecture

### Testing Framework

Tests use `TestItemRunner.jl` — test files contain `@testitem` blocks (not traditional `@testset`). The entry point `test/runtests.jl` calls `@run_package_tests`. Individual test files (e.g., `test/test-basic-test.jl`) use:

- `@testsnippet` — shared data/fixtures available to tests via `setup=[...]`
- `@testmodule` — shared helper modules available via `setup=[...]`
- `@testitem` — individual test cases with optional `tags` for filtering

### Pre-commit Hooks

The pre-commit pipeline enforces: JSON/TOML/YAML validity, markdown linting (markdownlint), CITATION.cff validation, YAML formatting (yamlfmt + yamllint), Julia formatting (JuliaFormatter), trailing whitespace, and LF line endings.

### Branch and Commit Conventions

- Branch names: `{issue-number}-{imperative-description}` (e.g., `14-add-tests`)
- Commit messages: imperative/present tense with informative titles
- History is kept linear — rebase onto `upstream/main` before opening PRs

### Releasing

Update `version` in `Project.toml`, update `CHANGELOG.md`, merge a `release-x.y.z` branch, then comment `@JuliaRegistrator register` on the merge commit on GitHub.
