# audit-report — Implementation Tasks

| Metadata | Details |
| :--- | :--- |
| **Design Doc** | specs/2026-03-22-01-audit-report/design.md |
| **Owner** | pb-plan agent |
| **Start Date** | 2026-03-22 |
| **Target Date** | TBD |
| **Status** | Planning |

## Summary & Phasing

This spec implements `audit-report`, a non-invasive Linux security auditing tool that auto-detects the OS distribution and runs multiple security scanners (Lynis, rkhunter, chkrootkit, OpenSCAP), consolidating all outputs into a timestamped directory.

- **Planner Contract Rule:** Contract-complete, build-eligible spec in markdown artifacts
- **Packet Contract Rule:** Blocked-build and DCR expectations carried as markdown sections
- **State Contract Rule:** Status markers: 🔴 TODO -> 🟡 IN PROGRESS -> 🟢 DONE, with ⏭️ SKIPPED, 🔄 DCR, ⛔ OBSOLETE
- **Property Testing Rule:** N/A for Bash (external tool orchestration)
- **Fuzzing Rule:** N/A (no parsers/protocols)
- **Benchmark Rule:** N/A (no performance requirements)
- **Identity Alignment Rule:** Rename `bash-app` to `audit-report` in Justfile
- **Architecture Decisions Rule:** Strategy pattern for modules, Template method for execution flow
- **Dependency Injection Rule:** $OUTPUT_DIR passed to all modules, tool paths resolved at runtime
- **Behavior Preservation Rule:** All behavior from design.md must be implemented
- **Simplification Rule:** Flattened control flow, clear function names, explicit over clever
- **Phase 1: Foundation** — Scaffolding, CLI parsing, core utilities
- **Phase 2: Core Logic** — OS detection, module implementations
- **Phase 3: Integration** — Module orchestration, report generation
- **Phase 4: Polish** — Tests, documentation, CI verification

---

## Phase 1: BDD Harness & Scaffolding

### Task 1.1: Fix Project Identity (Justfile Rename)

> **Context:** The Justfile still contains generic `bash-app` and `bash_app` identifiers from the template. These must be renamed to `audit-report` and `audit_report` to match the project identity.
> **Verification:** Running `just run --help` shows audit-report usage, not bash-app.

- **Priority:** P0
- **Scope:** Justfile identity alignment
- **Requirement Coverage:** R1 (CLI entry point)
- **Scenario Coverage:** CLI argument parsing
- **Loop Type:** TDD-only
- **Behavioral Contract:** Change from generic template name to project-specific name
- **Simplification Focus:** N/A (simple rename)
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Replace `bash-app` with `audit-report` in Justfile lines 83-84, 88
- [ ] Step 2: Replace `bash_app` with `audit_report` in Justfile line 99
- [ ] Step 3: Update run recipe to reference bin/audit-report
- [ ] Step 4: Update build and install-app recipes
- [ ] BDD Verification: `just run --help` shows "audit-report" not "bash-app"
- [ ] Verification: `grep -c "bash-app" Justfile` returns 0
- [ ] Advanced Test Verification: N/A (infrastructure task)
- [ ] Runtime Verification: N/A (build-time change)

### Task 1.2: Create Directory Structure and Core Utilities

> **Context:** Create the lib/audit_report/ directory structure and implement core.sh with logging, error handling, and common utilities. This is the foundation that all other modules depend on.
> **Verification:** All core functions can be sourced and tested independently.

- **Priority:** P0
- **Scope:** Directory structure + core utility library
- **Requirement Coverage:** R1, R11 (CLI foundations, non-invasive principles)
- **Scenario Coverage:** Logging, error handling
- **Loop Type:** TDD-only
- **Behavioral Contract:** New code — establish patterns for all subsequent modules
- **Simplification Focus:** Clear function names, consistent logging interface
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create directory structure: `mkdir -p lib/audit_report`
- [ ] Step 2: Create lib/audit_report/core.sh with:
  - Version constant
  - log_info(), log_warn(), log_error() functions
  - die() function with exit codes
  - command_exists() helper
- [ ] Step 3: Ensure all functions use `local` for variables
- [ ] Step 4: Add header comments documenting each function
- [ ] BDD Verification: `bats tests/core.bats` passes for core function tests
- [ ] Verification: `shellcheck lib/audit_report/core.sh` passes
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A (library code)

### Task 1.3: Implement CLI Argument Parsing in Main Entry Point

> **Context:** Create bin/audit-report as the main entry point. Implement CLI argument parsing for --output, --modules, --skip-missing/--no-skip-missing, --verbose, --help, and --version. Validate required arguments.
> **Verification:** All CLI flags work correctly and --help shows proper usage.

- **Priority:** P0
- **Scope:** Main entry point CLI parsing
- **Requirement Coverage:** R1 (CLI interface), R9 (output directory)
- **Scenario Coverage:** CLI argument parsing, help display
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New CLI interface — no existing behavior to preserve
- **Simplification Focus:** Explicit flag handling with case statement
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create bin/audit-report with shebang and set options
- [ ] Step 2: Source lib/audit_report/core.sh
- [ ] Step 3: Implement usage() function with help text
- [ ] Step 4: Implement parse_args() with getopts or manual parsing
- [ ] Step 5: Handle --output (required), --modules, --skip-missing, --verbose, --help, --version
- [ ] Step 6: Validate --output provided
- [ ] Step 7: Make bin/audit-report executable
- [ ] BDD Verification: `bats tests/core.bats` passes for CLI tests
- [ ] Verification: `./bin/audit-report --help` shows usage
- [ ] Verification: `./bin/audit-report 2>&1 | grep -q "output is required"`
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A

### Task 1.4: Implement Root Check and Output Directory Setup

> **Context:** Add root privilege enforcement (exit if EUID != 0) and output directory creation with timestamped subdirectory. Set up the RUN_DIR where all reports will be written.
> **Verification:** Running as non-root exits immediately; running as root creates the timestamped directory.

- **Priority:** P0
- **Scope:** Root check and directory setup
- **Requirement Coverage:** R2 (root enforcement), R9 (timestamped output)
- **Scenario Coverage:** Root privilege check, output directory creation
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — root enforcement at entry point
- **Simplification Focus:** Clear error message, explicit directory creation
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Add root check immediately after argument parsing:
  - `if [[ $EUID -ne 0 ]]; then die "must be run as root" $E_NOT_ROOT; fi`
- [ ] Step 2: Generate timestamp: `TIMESTAMP=$(date +%Y%m%d-%H%M%S)`
- [ ] Step 3: Construct RUN_DIR: `RUN_DIR="${OUTPUT_DIR}/${TIMESTAMP}"`
- [ ] Step 4: Create directory: `mkdir -p "$RUN_DIR" || die "cannot create output dir"`
- [ ] Step 5: Export RUN_DIR for module use
- [ ] BDD Verification: `bats tests/core.bats` passes root check tests
- [ ] Verification: `runuser -u nobody -- ./bin/audit-report 2>&1 | grep -q "must be run as root"`
- [ ] Verification: `sudo ./bin/audit-report --output /tmp/test-$$ && ls /tmp/test-$$/*`
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A

---

## Phase 2: Scenario Implementation

### Task 2.1: Implement OS Detection Module (detect.sh)

> **Context:** Implement lib/audit_report/detect.sh with functions to detect OS family (debian/rhel/arch) from /etc/os-release, determine package manager, and detect SCAP content paths and profiles.
> **Verification:** OS detection functions work for Ubuntu, Rocky Linux, and Arch test cases.

- **Priority:** P0
- **Scope:** OS detection module with full SCAP support
- **Requirement Coverage:** R3 (OS detection), R13 (SCAP content), R14 (SCAP profile)
- **Scenario Coverage:** OS detection for various distributions, SCAP content resolution
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — detection from /etc/os-release
- **Simplification Focus:** Pattern matching in case statement, clear variable names
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create lib/audit_report/detect.sh with header
- [ ] Step 2: Implement detect_os() — parse /etc/os-release, return debian/rhel/arch/unknown
- [ ] Step 3: Implement detect_package_manager() — map family to apt/dnf/yum/pacman
- [ ] Step 4: Implement detect_scap_content() — construct exact filename from family and version
- [ ] Step 5: Implement detect_scap_profile() — run `oscap info` and select best profile
- [ ] Step 6: Add helper detect_os_version() to extract VERSION_ID
- [ ] Step 7: Write OS info to detect.txt in RUN_DIR
- [ ] BDD Verification: `bats tests/detect.bats` passes all OS detection scenarios
- [ ] Verification: `shellcheck lib/audit_report/detect.sh` passes
- [ ] Verification: Mock /etc/os-release tests pass for ubuntu, rocky, arch
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A

### Task 2.2: Implement Lynis Module (lynis.sh)

> **Context:** Implement lib/audit_report/lynis.sh with functions to check if lynis is available and run lynis audit with output directed to the run directory.
> **Verification:** Lynis module correctly runs lynis when available and gracefully skips when not installed.

- **Priority:** P0
- **Scope:** Lynis audit module
- **Requirement Coverage:** R4 (Lynis audit module)
- **Scenario Coverage:** Lynis execution, missing tool handling
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — lynis wrapper
- **Simplification Focus:** Clear check/run interface
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create lib/audit_report/lynis.sh
- [ ] Step 2: Implement lynis_check() — return 0 if lynis in PATH, 1 otherwise
- [ ] Step 3: Implement lynis_run() — run lynis with --logfile and --report-file to output_dir
- [ ] Step 4: Implement lynis_get_output_files() — return paths to generated .log and .dat files
- [ ] Step 5: Handle lynis exit codes (lynis exits non-zero for warnings)
- [ ] BDD Verification: `bats tests/lynis.bats` passes all lynis scenarios
- [ ] Verification: `shellcheck lib/audit_report/lynis.sh` passes
- [ ] Verification: Mock lynis binary test passes
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: If lynis installed: `sudo bin/audit-report --output /tmp/test && cat /tmp/test/*/lynis*.log`

### Task 2.3: Implement rkhunter and chkrootkit Modules (rkhunter.sh, chkrootkit.sh)

> **Context:** Implement lib/audit_report/rkhunter.sh and lib/audit_report/chkrootkit.sh with the same interface pattern as lynis. rkhunter runs with --skip-keypress; chkrootkit output is captured to file.
> **Verification:** Both modules run correctly when tools are available and skip gracefully when not installed.

- **Priority:** P0
- **Scope:** rkhunter and chkrootkit wrapper modules
- **Requirement Coverage:** R5 (rkhunter), R6 (chkrootkit)
- **Scenario Coverage:** rkhunter execution, chkrootkit execution, missing tool handling
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — wrapper modules following same pattern
- **Simplification Focus:** Consistent interface across all modules
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create lib/audit_report/rkhunter.sh
- [ ] Step 2: Implement rkhunter_check() — check if rkhunter in PATH
- [ ] Step 3: Implement rkhunter_run() — run with --check --skip-keypress --logfile
- [ ] Step 4: Implement rkhunter_get_output_file() — return log file path
- [ ] Step 5: Create lib/audit_report/chkrootkit.sh
- [ ] Step 6: Implement chkrootkit_check() — check if chkrootkit in PATH
- [ ] Step 7: Implement chkrootkit_run() — run and redirect stdout/stderr to file
- [ ] Step 8: Implement chkrootkit_get_output_file() — return output file path
- [ ] BDD Verification: `bats tests/rkhunter.bats` and `bats tests/chkrootkit.bats` pass
- [ ] Verification: `shellcheck lib/audit_report/rkhunter.sh lib/audit_report/chkrootkit.sh` passes
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: If tools installed: `sudo bin/audit-report --output /tmp/test`

### Task 2.4: Implement OpenSCAP Module (openscap.sh)

> **Context:** Implement lib/audit_report/openscap.sh with SCAP content auto-detection and profile selection. This is the most complex module as it requires detecting the correct datastream file and profile.
> **Verification:** OpenSCAP module correctly finds SCAP content, selects appropriate profile, and generates HTML/XML reports.

- **Priority:** P0
- **Scope:** OpenSCAP evaluation module with SCAP content detection
- **Requirement Coverage:** R7 (OpenSCAP), R13 (SCAP content), R14 (SCAP profile)
- **Scenario Coverage:** SCAP content resolution, profile selection, evaluation execution
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — complex wrapper with auto-detection
- **Simplification Focus:** Separate content detection from evaluation
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create lib/audit_report/openscap.sh
- [ ] Step 2: Implement openscap_check() — check if oscap in PATH
- [ ] Step 3: Implement openscap_detect_content() — find ssg-*-ds.xml file
- [ ] Step 4: Implement openscap_detect_profile() — run oscap info, select profile
- [ ] Step 5: Implement openscap_run() — run oscap xccdf eval with HTML/XML output
- [ ] Step 6: Handle oscap exit codes (non-zero for failed rules, not tool failure)
- [ ] Step 7: Implement openscap_get_output_files() — return HTML and XML paths
- [ ] BDD Verification: `bats tests/openscap.bats` passes all SCAP scenarios
- [ ] Verification: `shellcheck lib/audit_report/openscap.sh` passes
- [ ] Verification: Mock oscap and content file tests pass
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: If oscap+ssg installed: `sudo bin/audit-report --output /tmp/test && ls /tmp/test/*/oscap*.html`

### Task 2.5: Implement Module Orchestration in Main Entry Point

> **Context:** Wire up all modules in bin/audit-report with the template method execution pattern. Implement the loop that runs each module sequentially, handles skip logic, and tracks status.
> **Verification:** Main entry point correctly orchestrates all modules with proper error handling and status tracking.

- **Priority:** P0
- **Scope:** Main entry point module orchestration
- **Requirement Coverage:** R8 (sequential execution), R12 (missing tool handling)
- **Scenario Coverage:** Sequential execution, missing tool handling, status tracking
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — module orchestration
- **Simplification Focus:** Template method pattern, clear status tracking
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Source all module files in bin/audit-report
- [ ] Step 2: Define MODULE_STATUS and MODULE_OUTPUT associative arrays
- [ ] Step 3: Implement run_module() template function that:
  - Checks if module is available (module_check)
  - Handles SKIP_MISSING logic
  - Runs module (module_run)
  - Captures output file path
  - Updates status arrays
- [ ] Step 4: Implement main loop over MODULES array
- [ ] Step 5: Add verbose logging for module execution
- [ ] BDD Verification: `bats tests/core.bats` passes orchestration tests
- [ ] Verification: `shellcheck bin/audit-report` passes
- [ ] Verification: Sequential execution test passes
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: `sudo bin/audit-report --output /tmp/test --verbose 2>&1 | grep -q "Running module"`

### Task 2.6: Implement Report Generation Module (report.sh)

> **Context:** Implement lib/audit_report/report.sh with generate_summary() function that creates summary.txt with scan timestamp, detected OS, per-module status, key findings counts, and paths to all report files.
> **Verification:** Summary report is generated with all required information in the correct format.

- **Priority:** P0
- **Scope:** Summary report generation module
- **Requirement Coverage:** R10 (summary report generation)
- **Scenario Coverage:** Summary generation, status aggregation
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** New behavior — report generation
- **Simplification Focus:** Clear formatting, consistent output structure
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create lib/audit_report/report.sh
- [ ] Step 2: Implement generate_summary() function:
  - Accept output_dir, module_status array ref, module_output array ref
  - Extract hostname, timestamp
  - Read detected OS info
  - Aggregate module statuses
  - Parse findings from module outputs (if possible)
- [ ] Step 3: Write summary.txt with sections:
  - Header (scan timestamp, hostname)
  - System Information (OS family, version)
  - Module Results (table: module, status, output file)
  - Key Findings (counts: warnings, suggestions, failures)
  - File Locations (list of all generated files)
- [ ] Step 4: Ensure summary is written to RUN_DIR/summary-${TIMESTAMP}.txt
- [ ] BDD Verification: `bats tests/report.bats` passes summary generation tests
- [ ] Verification: `shellcheck lib/audit_report/report.sh` passes
- [ ] Verification: Summary file format matches design spec
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: `sudo bin/audit-report --output /tmp/test && cat /tmp/test/*/summary*.txt | grep -q "Module Results"`

---

## Phase 3: Integration & Features

### Task 3.1: Integrate All Modules and End-to-End Testing

> **Context:** Wire together all components and perform end-to-end testing. Ensure modules are sourced correctly, the main loop runs all modules sequentially, and the summary is generated at the end.
> **Verification:** Full end-to-end run produces all expected output files.

- **Priority:** P0
- **Scope:** End-to-end integration and testing
- **Requirement Coverage:** All requirements (R1-R14)
- **Scenario Coverage:** Full audit run, all modules, summary generation
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** Integration of all modules into working system
- **Simplification Focus:** Clean error propagation, clear module boundaries
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Ensure all module files are sourced in correct order in bin/audit-report
- [ ] Step 2: Verify MODULES array default includes all modules: (lynis rkhunter chkrootkit openscap)
- [ ] Step 3: Test with all modules installed (if possible)
- [ ] Step 4: Test with some modules missing (verify skip behavior)
- [ ] Step 5: Test with --modules flag to limit modules
- [ ] Step 6: Test with --verbose flag
- [ ] Step 7: Test with --no-skip-missing flag
- [ ] Step 8: Verify summary.txt contains all expected sections
- [ ] BDD Verification: `bats tests/` passes all tests
- [ ] Verification: End-to-end test produces output directory with all expected files
- [ ] Verification: `just check` passes (format, lint, test)
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: `sudo bin/audit-report --output /tmp/e2e-test && ls /tmp/e2e-test/*/*.txt`

### Task 3.2: Update Justfile Recipes for audit-report

> **Context:** Update Justfile to replace generic `bash-app` references with `audit-report`. Update run, build, install-app recipes to work with the new project structure.
> **Verification:** `just run --help` works and shows audit-report usage.

- **Priority:** P1
- **Scope:** Justfile recipe updates
- **Requirement Coverage:** R1 (CLI entry point)
- **Scenario Coverage:** Just recipe functionality
- **Loop Type:** TDD-only
- **Behavioral Contract:** Update template references to project-specific names
- **Simplification Focus:** N/A (rename task)
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Update run recipe: replace `bash-app` with `audit-report`
- [ ] Step 2: Update build recipe: copy bin/audit-report and lib/audit_report/
- [ ] Step 3: Update install-app recipe: install to /usr/local/bin/audit-report
- [ ] Step 4: Update clean recipe to handle audit-report artifacts
- [ ] BDD Verification: `just run --help` shows audit-report help
- [ ] Verification: `just build` creates dist/ with audit-report
- [ ] Verification: `grep -c "bash-app" Justfile` returns 0
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: `sudo just run --output /tmp/just-test` works

---

## Phase 4: Polish, QA & Docs

### Task 4.1: Write BDD Scenarios and Bats Tests

> **Context:** Create comprehensive Bats tests for all modules and BDD scenarios in features/audit.feature. Ensure all code paths are covered by tests.
> **Verification:** All Bats tests pass, including edge cases and error conditions.

- **Priority:** P0
- **Scope:** Test coverage for all modules
- **Requirement Coverage:** All requirements (R1-R14)
- **Scenario Coverage:** All BDD scenarios from design.md
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** Tests verify all specified behavior
- **Simplification Focus:** Clear test names, readable assertions
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Create tests/core.bats with CLI parsing tests, root check tests
- [ ] Step 2: Create tests/detect.bats with OS detection tests (mock /etc/os-release)
- [ ] Step 3: Create tests/lynis.bats with lynis wrapper tests
- [ ] Step 4: Create tests/rkhunter.bats with rkhunter wrapper tests
- [ ] Step 5: Create tests/chkrootkit.bats with chkrootkit wrapper tests
- [ ] Step 6: Create tests/openscap.bats with OpenSCAP wrapper tests
- [ ] Step 7: Create tests/report.bats with summary generation tests
- [ ] Step 8: Create features/audit.feature with Gherkin scenarios
- [ ] Step 9: Ensure all tests follow Bats best practices (setup/teardown)
- [ ] BDD Verification: `bats tests/` passes all tests with 0 failures
- [ ] Verification: `bats tests/` shows 100% of tests passing
- [ ] Verification: Test coverage includes all modules and error paths
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A (test code only)

### Task 4.2: Write README Documentation

> **Context:** Update README.md with comprehensive documentation including installation instructions, usage examples, supported distributions, dependency information, and contribution guidelines.
> **Verification:** README is complete, accurate, and helpful for new users.

- **Priority:** P1
- **Scope:** README.md documentation
- **Requirement Coverage:** Documentation for all features
- **Scenario Coverage:** User documentation
- **Loop Type:** TDD-only
- **Behavioral Contract:** Documentation matches implemented behavior
- **Simplification Focus:** Clear examples, straightforward language
- **Advanced Test Coverage:** N/A (documentation)
- **Status:** 🔴 TODO
- [ ] Step 1: Write overview section describing what audit-report does
- [ ] Step 2: List supported distributions (Debian/Ubuntu, RHEL/CentOS/Fedora/Rocky/Alma, Arch)
- [ ] Step 3: Document installation requirements and optional dependencies
- [ ] Step 4: Provide basic usage examples (--output flag)
- [ ] Step 5: Document all CLI options (--modules, --skip-missing, --verbose, etc.)
- [ ] Step 6: Explain output directory structure and summary.txt format
- [ ] Step 7: Add troubleshooting section for common issues
- [ ] Step 8: Add contribution guidelines
- [ ] BDD Verification: N/A (documentation)
- [ ] Verification: README.md renders correctly (no broken markdown)
- [ ] Verification: All CLI options documented match actual implementation
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: N/A

### Task 4.3: Final QA and CI Verification

> **Context:** Run full quality assurance: format check, lint, test, and end-to-end verification. Ensure all code follows project standards and works correctly.
> **Verification:** All QA checks pass and end-to-end run produces valid output.

- **Priority:** P0
- **Scope:** Final QA and verification
- **Requirement Coverage:** All requirements (R1-R14)
- **Scenario Coverage:** All features
- **Loop Type:** BDD+TDD
- **Behavioral Contract:** All specified behavior verified
- **Simplification Focus:** Clean, well-formatted, well-tested code
- **Advanced Test Coverage:** Example-based only
- **Status:** 🔴 TODO
- [ ] Step 1: Run `just format-check` — ensure all files properly formatted
- [ ] Step 2: Run `just lint` — ensure shellcheck passes for all scripts
- [ ] Step 3: Run `just test` — ensure all Bats tests pass
- [ ] Step 4: Run `just check` — ensure format, lint, and test all pass
- [ ] Step 5: Perform end-to-end test with all modules installed (if possible)
- [ ] Step 6: Perform end-to-end test with some modules missing
- [ ] Step 7: Verify output directory structure matches design spec
- [ ] Step 8: Verify summary.txt contains all required sections
- [ ] BDD Verification: `just check` passes with 0 failures
- [ ] Verification: End-to-end run produces valid output directory
- [ ] Verification: All spec requirements (R1-R14) are satisfied
- [ ] Advanced Test Verification: N/A
- [ ] Runtime Verification: Final end-to-end test run succeeds

---

## Summary & Timeline

| Phase | Tasks | Target Date | Status |
| :--- | :---: | :--- | :--- |
| **1. Foundation** | 4 | 2026-03-22 | Planning |
| **2. Core Logic** | 6 | 2026-03-23 | Planning |
| **3. Integration** | 2 | 2026-03-24 | Planning |
| **4. Polish** | 3 | 2026-03-25 | Planning |
| **Total** | **15** | | |

## Definition of Done

1. [ ] **Linted:** No lint errors (`just lint` passes).
2. [ ] **Tested:** Unit tests covering all added logic (`just test` passes).
3. [ ] **Formatted:** Code formatter applied (`just format-check` passes).
4. [ ] **Verified:** All verification criteria in tasks met.
5. [ ] **Advanced-Tested:** Property/fuzz/benchmark N/A (justified in design).
6. [ ] **Runtime-Evidenced:** End-to-end runs produce valid output (verified).
7. [ ] **Behavior-Preserved:** All design.md requirements implemented.
8. [ ] **Simplified:** Code follows simplification constraints from design.
