# High-Performance Bash Agent Instructions

## Scope

- This template targets Bash shell script projects managed by `just`.
- `bin/` contains executable entry-point scripts.
- `lib/` contains reusable library functions.
- `tests/` contains Bats-core unit tests.
- No framework-specific assumptions (pure Bash).

## Bash Project Rules (Critical)

1. Never use `eval` or backticks; use `$()` for command substitution.
2. Always start scripts with `#!/usr/bin/env bash` and `set -euo pipefail`.
3. Quote all variables to prevent word splitting: `"$variable"`.
4. Use `[[ ]]` for conditionals, never `[ ]`.
5. Use `local` for all function-scoped variables.
6. Return explicit exit codes; document expected codes in function headers.
7. Run code through `just check` before committing.

## Preferred Tools and Versions

- `bash >= 4.0` — associative arrays, `mapfile`, process substitution
- `shfmt >= 3.7` — consistent formatting (mvdan/sh)
- `shellcheck >= 0.9` — static analysis (koalaman/shellcheck)
- `bats-core >= 1.9` — unit testing framework
- `just >= 1.0` — command runner
- `basher` — package management (basherpm/basher)
- `git-cliff` — changelog generation

## Engineering Principles

### Shell Script Implementation Guidelines

1. Error handling:
   - Always use `set -euo pipefail` at script entry.
   - Use `trap` for cleanup on exit/error.
   - Never ignore errors; check `$?` or use `||` for expected failures.
   - Define explicit error codes as constants.
2. Function design:
   - Document every function with a header block.
   - Use descriptive names: `process_file`, `validate_input`.
   - Keep functions under 50 lines; extract helpers for complex logic.
   - Prefer pure functions (no side effects) when possible.
3. I/O and output:
   - Use `printf` over `echo` for portability.
   - Redirect errors to stderr: `>&2`.
   - Use `read -r` to prevent backslash interpretation.
   - Avoid parsing `ls`; use globs or `find`.
4. Observability:
   - Use structured logging functions (`log_info`, `log_error`, `log_warn`).
   - Include timestamps in log output.
   - Use `set -x` for debug mode (controlled by flags).
5. Configuration:
   - Use environment variables for configuration.
   - Provide sensible defaults: `${VAR:-default}`.
   - Validate required variables at startup.
6. Security:
   - Never hardcode secrets; use environment variables or secret managers.
   - Validate all external input at system boundaries.
   - Use `mktemp` for temporary files; clean up with `trap`.

### Key Design Principles

- Modularity: Design each function so it can be tested independently with clear inputs and outputs.
- Performance: Prefer built-in Bash constructs over external commands in hot paths.
- Extensibility: Use function dispatch tables and source-based composition.
- Type Safety: Validate inputs early; fail fast with clear error messages.

### Performance Considerations

- Prefer Bash built-ins (`[[ ]]`, `(( ))`, `${var//pattern/}`) over external commands (`grep`, `sed`, `awk`).
- Use `mapfile` / `readarray` for reading files into arrays.
- Avoid subshells in loops; use parameter expansion instead.
- Use `<<< "here-string"` instead of `echo "string" | command`.
- Profile with `time` and `bash -x` before optimizing.

### Concurrency and Parallel Execution

- Use `&` for background jobs and `wait` for synchronization.
- Use named pipes (`mkfifo`) for inter-process communication.
- Limit concurrent jobs with `xargs -P` or GNU `parallel`.
- Use `flock` for file-based locking in multi-process scripts.
- Prefer sequential execution unless parallelism provides measurable benefit.

### Memory and Allocation

- Avoid loading entire files into variables; process line-by-line with `while read`.
- Use `<<<` here-strings instead of pipes where possible.
- Prefer `printf -v var` over `var=$(printf ...)` to avoid subshells.
- Use `declare -A` for associative arrays; avoid linear scans.
- Clean up temporary files and variables with `trap`.

### Error Handling Patterns

```bash
# Standard error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_INVALID_ARGS=2
readonly E_FILE_NOT_FOUND=3

# Cleanup trap
cleanup() {
    local exit_code=$?
    rm -f "$TEMP_FILE"
    exit "$exit_code"
}
trap cleanup EXIT

# Input validation
validate_input() {
    local input="$1"
    if [[ -z "$input" ]]; then
        log_error "Input cannot be empty"
        return "$E_INVALID_ARGS"
    fi
}
```

### Common Pitfalls

- Do not use `cd` without checking the return value; prefer absolute paths.
- Do not use `set -e` with commands in `if` conditions that are expected to fail.
- Do not parse output of `ls`; use glob patterns or `find`.
- Do not use `echo` for data; use `printf "%s" "$var"`.
- Do not forget to quote variables in `[[ ]]` tests.

### What to Avoid

- Incomplete implementations: finish features before submitting.
- Large, sweeping changes: keep changes focused and reviewable.
- Mixing unrelated changes: keep one logical change per commit.
- Using `# shellcheck disable` without justification comment.

## Development Workflow

When fixing failures, identify root cause first, then apply idiomatic fixes instead of suppressing warnings or patching symptoms.

Use outside-in development for behavior changes:

- **Git Restrictions:** NEVER use `git worktree`. All code modifications MUST be made directly on the current branch in the existing working directory.
- start with a failing Gherkin scenario under `features/`,
- drive implementation with failing Bats tests,
- keep example-based Bats tests as the default inner loop for named cases and edge cases,
- add property-based tests under `tests/` when the rule is an invariant instead of a single named example,
- treat fuzzing as conditional work for parser-like or hostile-input scripts.

After each feature or bug fix, run:

```bash
just format
just lint
just test
just check
```

If any command fails, report the failure and do not claim completion.

## Testing Requirements

- BDD scenarios: place Gherkin features under `features/`.
- Use BDD to define acceptance behavior first, then use Bats for the inner TDD loop.
- Unit tests: place in `tests/` mirroring the source structure.
- Keep example-based tests as the default; add property-based tests only for invariants.
- Integration tests: place in `tests/integration/`.
- Add tests for behavioral changes and public API changes.
- Use `setup` / `teardown` for test fixtures.
- Use `run` to capture command output and exit status.

## Language Requirement

- Documentation, comments, and commit messages must be English only.
