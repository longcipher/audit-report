# Design Document: audit-report Linux Security Auditor

| Metadata | Details |
| :--- | :--- |
| **Author** | pb-plan agent |
| **Status** | Draft |
| **Created** | 2026-03-22 |
| **Reviewers** | N/A |
| **Related Issues** | N/A |

## 1. Executive Summary

**Problem:** Linux security auditing requires multiple tools (Lynis, rkhunter, chkrootkit, OpenSCAP) each with different configurations, output formats, and distribution-specific handling. There is no unified, portable solution that automatically detects the OS and runs all relevant audits.

**Solution:** Build `audit-report`, a non-invasive Bash-based security auditing tool that auto-detects the Linux distribution, runs multiple security scanners, and consolidates all outputs into a single timestamped directory. The tool gracefully handles missing dependencies and enforces root-only execution for accurate results.

---

## 2. Source Inputs & Normalization

### 2.1 Source Materials

The primary source material is `docs/design.md`, a comprehensive design document specifying:

- OS distribution detection strategy (Debian/Ubuntu, RHEL/CentOS/Fedora, Arch)
- Module specifications for lynis, rkhunter, chkrootkit, openscap
- CLI interface with --output, --modules, --skip-missing flags
- Error handling and non-invasive principles
- Output structure and report generation

### 2.2 Normalization Approach

Raw requirements were extracted and normalized into a source requirement ledger. Key design decisions preserved:

- Strict root enforcement at entry point
- Sequential module execution (not parallel)
- Timestamped output subdirectories
- No auto-installation of missing tools
- Distribution-specific SCAP content path resolution

### 2.3 Source Requirement Ledger

| Requirement ID | Source Summary | Type | Notes |
| :--- | :--- | :--- | :--- |
| `R1` | CLI entry point with --output flag | Functional | Required flag for output directory |
| `R2` | Root privilege enforcement | Constraint | Must exit with error if EUID != 0 |
| `R3` | OS distribution auto-detection | Functional | Parse /etc/os-release for debian/rhel/arch |
| `R4` | Lynis audit module | Functional | Run if installed, skip with warning if not |
| `R5` | rkhunter scan module | Functional | Run with --skip-keypress for non-interactive |
| `R6` | chkrootkit scan module | Functional | Capture output to timestamped file |
| `R7` | OpenSCAP evaluation module | Functional | Detect content path, run XCCDF evaluation |
| `R8` | Sequential module execution | Constraint | No parallel execution to avoid I/O contention |
| `R9` | Timestamped output directories | Functional | Create YYYYMMDD-HHMMSS subdir in --output |
| `R10` | Summary report generation | Functional | Aggregate results into summary.txt |
| `R11` | No system modification | Constraint | Read-only system access, write only to output |
| `R12` | No auto-installation | Constraint | Log warnings for missing tools, never install |
| `R13` | SCAP content path resolution | Functional | Construct exact filename per distro version |
| `R14` | SCAP profile fallback | Functional | Try cis, then standard, then first available |

---

## 3. Requirements & Goals

### 3.1 Problem Statement

Linux security auditing requires running multiple specialized tools, each with:

- Different configuration requirements per distribution
- Various output formats and locations
- Distribution-specific installation and invocation
- Complex SCAP content path management

Currently, administrators must manually coordinate these tools, leading to inconsistent coverage and scattered results.

### 3.2 Functional Goals

1. **Unified CLI:** Single entry point with --output flag to specify report destination
2. **Auto-detection:** Parse /etc/os-release to determine distribution family (debian/rhel/arch)
3. **Modular Scans:** Run lynis, rkhunter, chkrootkit, and OpenSCAP as independent modules
4. **Graceful Degradation:** Skip modules when tools are missing, logging warnings but continuing
5. **SCAP Intelligence:** Auto-detect SCAP content paths and profiles per distribution
6. **Report Consolidation:** Generate summary.txt with pass/fail/warn counts and file paths

### 3.3 Non-Functional Goals

- **Portability:** Support Debian/Ubuntu, RHEL/CentOS/Fedora/Rocky/Alma, and Arch Linux
- **Non-invasive:** Read-only system access, write only to specified output directory
- **Reproducibility:** Timestamped output directories ensure historical preservation
- **Root Enforcement:** Require root for accurate audit results (access to privileged files)
- **Sequential Execution:** Avoid I/O contention by running modules one at a time

### 3.4 Out of Scope

- Auto-installation of missing tools (security risk, violates non-invasive principle)
- Parallel module execution (intentionally sequential to avoid resource conflicts)
- Container image auditing (Docker/Podman) — future enhancement
- CI/CD pipeline integration — future enhancement
- JSON/HTML output formats — future enhancement
- Email/Slack notifications — future enhancement
- Differential scanning against previous runs — future enhancement

### 3.5 Assumptions

- Target systems have Bash >= 4.0 (for associative arrays, mapfile)
- Standard Linux filesystem layout (/etc/os-release, /usr/share, etc.)
- Root access is available (tool enforces this but assumes user can obtain it)
- SCAP Security Guide content follows standard naming conventions
- Tool binaries (when installed) are in $PATH or standard locations

### 3.6 Code Simplification Constraints

- **Behavior Preservation Boundary:** All existing behavior from design spec must be preserved unless explicitly modified
- **Repo Standards To Follow:** Bash >= 4.0, `set -euo pipefail`, quote all variables, use `[[ ]]` not `[ ]`, use `local` for function variables
- **Readability Priorities:** Explicit control flow, clear function names, reduced nesting, removal of redundant abstractions
- **Refactoring Non-Goals:** No unrelated cleanup outside touched modules
- **Clarity Guardrails:** Avoid nested ternary operators (not applicable in Bash), avoid clever one-liners

---

## 4. Requirements Coverage Matrix

| Requirement ID | Covered In Design | Scenario Coverage | Task Coverage | Status / Rationale |
| :--- | :--- | :--- | :--- | :--- |
| R1 | CLI Interface (§5) | CLI argument parsing | Task 1.2, 2.1 | Covered |
| R2 | Non-Invasive Principles (§6) | Root privilege check | Task 1.2, 2.5 | Covered |
| R3 | Modules/detect.sh (§4.1) | OS detection scenarios | Task 2.2 | Covered |
| R4 | Modules/lynis.sh (§4.2) | Lynis execution | Task 2.3 | Covered |
| R5 | Modules/rkhunter.sh (§4.3) | rkhunter execution | Task 2.3 | Covered |
| R6 | Modules/chkrootkit.sh (§4.4) | chkrootkit execution | Task 2.3 | Covered |
| R7 | Modules/openscap.sh (§4.5) | OpenSCAP evaluation | Task 2.4 | Covered |
| R8 | Architecture/CLI (§5) | Sequential execution | Task 1.2, 2.1 | Covered |
| R9 | Output Structure (§7) | Timestamped directories | Task 1.2, 2.6 | Covered |
| R10 | Modules/report.sh (§4.6) | Summary generation | Task 2.6 | Covered |
| R11 | Non-Invasive Principles (§6) | Read-only access | All tasks | Covered |
| R12 | Error Handling (§8) | Skip missing tools | Task 2.3, 2.4 | Covered |
| R13 | Modules/openscap.sh (§4.5) | Content path resolution | Task 2.4 | Covered |
| R14 | Modules/openscap.sh (§4.5) | Profile fallback | Task 2.4 | Covered |

---

## 5. Architecture Overview

### 5.1 System Context

```text
┌─────────────────────────────────────────────────────────────────┐
│                         User (root)                             │
│                         audit-report --output /path             │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    bin/audit-report (CLI)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐   │
│  │ Arg Parse   │  │ Root Check  │  │ Output Dir Setup        │   │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘   │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  lib/audit_report/detect.sh                     │
│                    OS Detection Logic                             │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Module Execution (Sequential)                        │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌─────────────────┐    │
│  │ lynis.sh │ │rkhunter. │ │chkrootkit. │ │   openscap.sh   │    │
│  │          │ │   sh     │ │    sh      │ │                 │    │
│  └────┬─────┘ └────┬─────┘ └─────┬──────┘ └────────┬────────┘    │
│       │            │             │                  │               │
│       └────────────┴─────────────┴──────────────────┘               │
│                              │                                    │
│                              ▼                                    │
│                     lib/audit_report/report.sh                      │
│                       Summary Generation                          │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Key Design Principles

1. **Non-invasive by design** — Read-only system access, write only to specified output directory
2. **Fail gracefully** — Missing tools are logged as warnings, not errors; execution continues
3. **Distribution-agnostic** — Auto-detect OS family and adapt tool paths/arguments
4. **Root enforcement** — Clear error if not running as root (UID 0)
5. **Sequential execution** — One module at a time to avoid I/O contention
6. **Self-contained output** — All artifacts in one timestamped directory

### 5.3 Existing Components to Reuse

| Component | Location | How to Reuse |
| :--- | :--- | :--- |
| Bats test framework | tests/*.bats | Extend with new test files for each module |
| Just task runner | Justfile | Already has format, lint, test commands |
| ShellCheck config | .shellcheckrc | Use for all shell scripts |
| shfmt config | Justfile | Use -i 4 -bn -ci -sr -w for formatting |

No existing reusable shell library modules identified — this is a greenfield implementation.

### 5.4 Architecture Decisions

| Decision ID | Status | Selected Pattern / Principle | Why It Fits Here | Alternatives Rejected | Simplification Impact |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AD-01` | New | **Strategy Pattern** for modules | Each audit module (lynis, rkhunter, etc.) has same interface but different implementation | Monolithic script rejected | Keeps modules independent, testable, allows selective skipping |
| `AD-02` | New | **Template Method** for module execution | Common flow: check tool → run → capture output → return status | Each module handling its own flow rejected | Eliminates duplication in status tracking and error handling |
| `AD-03` | Inherited | **Fail-fast on root check** | AGENTS.md specifies `set -euo pipefail` and clear error handling | Continuing without root rejected | Prevents misleading incomplete audits |
| `AD-04` | New | **Pure functions for detection** | OS detection has no side effects, takes no args, returns string | Modifying global state rejected | Makes detection testable without mocks |

**Architecture Decision Snapshot Inputs:**

- From AGENTS.md: `set -euo pipefail`, quote all variables, use `[[ ]]`, use `local`, explicit exit codes
- From Justfile: shfmt with -i 4 -bn -ci -sr flags, shellcheck for linting
- From design.md: Non-invasive principles, sequential execution, timestamped output

**SRP Check:**

- `detect.sh` — only OS detection, no tool execution
- `lynis.sh`, `rkhunter.sh`, `chkrootkit.sh`, `openscap.sh` — each only handles one tool
- `report.sh` — only aggregation and summary generation
- `audit-report` (bin) — only CLI parsing and orchestration

**DIP Check:**

- Modules depend on abstract output directory, not concrete paths
- Tool detection uses `$PATH` abstraction, not hardcoded paths
- SCAP content resolution is injected based on detected OS

**Dependency Injection Plan:**

- `$OUTPUT_DIR` passed as argument to all module functions
- Tool paths resolved at runtime via `command -v`
- SCAP content path constructed from detected OS family and version

**Code Simplifier Alignment:**

- Strategy pattern keeps each module focused without complex conditionals
- Template method eliminates repetitive status tracking code
- Pure detection functions are easier to test than stateful ones

### 5.5 Project Identity Alignment

| Current Identifier | Location | Why It Is Generic or Misaligned | Planned Name / Action |
| :--- | :--- | :--- | :--- |
| `bash-app` | Justfile (lines 83-84, 88, 97-98) | Generic template placeholder | Rename to `audit-report` |
| `bash_app` | Justfile (line 99) | Generic template placeholder | Rename to `audit_report` |

These identifiers in Justfile should be updated to match the project name `audit-report`.

### 5.6 BDD/TDD Strategy

- **BDD Runner:** `bats-core` (Bash Automated Testing System)
- **BDD Command:** `bats tests/*.bats` or `just test`
- **Unit Test Command:** `bats tests/<module>.bats`
- **Property Test Tool:** `N/A` — Bash scripts use file system and external tools; property testing less applicable
- **Fuzz Test Tool:** `N/A` — No parsers or protocol implementations
- **Benchmark Tool:** `N/A` — No performance-sensitive hot paths
- **Outer Loop:** BDD scenarios in `features/audit.feature` drive acceptance
- **Inner Loop:** Bats unit tests for each module in `tests/*.bats`
- **Step Definition Location:** `tests/*.bats` (Bats serves as both BDD runner and unit test framework for Bash)

> Note: For Bash projects, Bats-core serves dual purpose as both BDD acceptance test runner (via feature-style test organization) and unit test framework. Property/fuzz/benchmark testing are typically N/A for shell scripts unless parsing complex formats.

### 5.7 BDD Scenario Inventory

| Feature File | Scenario | Business Outcome | Primary Verification | Supporting TDD Focus |
| :--- | :--- | :--- | :--- | :--- |
| `features/audit.feature` | OS Detection - Ubuntu | Correctly identifies Debian family | `bats tests/detect.bats` | `detect_os` function |
| `features/audit.feature` | OS Detection - Rocky Linux | Correctly identifies RHEL family | `bats tests/detect.bats` | `detect_os` with ID_LIKE |
| `features/audit.feature` | OS Detection - Arch | Correctly identifies Arch family | `bats tests/detect.bats` | Arch/Manjaro detection |
| `features/audit.feature` | Root Privilege Check | Fails fast with clear error | `bats tests/core.bats` | Entry point guard |
| `features/audit.feature` | Missing Tool Handling | Continues with warning | `bats tests/lynis.bats` | Skip logic for missing tools |
| `features/audit.feature` | SCAP Content Resolution | Finds correct datastream | `bats tests/openscap.bats` | `detect_scap_content` |
| `features/audit.feature` | Sequential Execution | Runs modules in order | `bats tests/core.bats` | Module orchestration |
| `features/audit.feature` | Summary Generation | Creates summary.txt | `bats tests/report.bats` | `generate_summary` function |
| `features/audit.feature` | Timestamped Output | Creates dated subdirectory | `bats tests/core.bats` | Directory creation |

### 5.8 Simplification Opportunities in Touched Code

| Area | Current Complexity or Smell | Planned Simplification | Why It Preserves or Clarifies Behavior |
| :--- | :--- | :--- | :--- |
| Module execution | Repeated status tracking in each module | Template method with common run_module wrapper | Eliminates duplication while keeping module-specific logic isolated |
| OS detection | Nested conditionals for each distro | Case statement with pattern matching | Flattened control flow, same output semantics |
| SCAP content path | String concatenation inline | Dedicated function with clear variable names | Self-documenting code, easier to test |

---

## 6. Detailed Design

### 6.1 Module Structure

```text
bin/
└── audit-report              # Main CLI entry point

lib/
└── audit_report/
    ├── core.sh               # Common utilities, logging, error handling
    ├── detect.sh             # OS detection functions
    ├── lynis.sh              # Lynis audit module
    ├── rkhunter.sh           # rkhunter scan module
    ├── chkrootkit.sh         # chkrootkit scan module
    ├── openscap.sh           # OpenSCAP evaluation module
    └── report.sh             # Summary report generation

tests/
├── detect.bats               # OS detection tests
├── lynis.bats                # Lynis wrapper tests
├── rkhunter.bats             # rkhunter wrapper tests
├── chkrootkit.bats           # chkrootkit wrapper tests
├── openscap.bats             # OpenSCAP wrapper tests
├── report.bats               # Report generation tests
└── core.bats                 # CLI and core function tests

features/
└── audit.feature             # BDD acceptance scenarios
```

### 6.2 Data Structures & Types

```bash
# Global configuration (set at startup)
readonly AUDIT_REPORT_VERSION="0.1.0"
OUTPUT_DIR=""           # User-specified output base directory
TIMESTAMP=""            # YYYYMMDD-HHMMSS format
RUN_DIR=""              # OUTPUT_DIR/TIMESTAMP (actual output path)
VERBOSE=0               # 0 or 1 (set by --verbose)
SKIP_MISSING=1          # 1=skip with warning, 0=fail if tool missing
MODULES=()              # Array: lynis rkhunter chkrootkit openscap

# OS detection results
DISTRO_FAMILY=""        # debian, rhel, arch, or unknown
DISTRO_ID=""            # ubuntu, rocky, arch, etc.
DISTRO_VERSION=""       # 22.04, 9, etc.
PKG_MANAGER=""          # apt, dnf, yum, or pacman

# Module status tracking (associative array)
declare -A MODULE_STATUS  # MODULE_STATUS[lynis]="ran|skipped|failed"
declare -A MODULE_OUTPUT  # MODULE_OUTPUT[lynis]="/path/to/output"

# PlannedSpecContract
# - design.md contains architecture, BDD/TDD strategy, detailed design,
#   verification, and implementation plan
# - tasks.md contains TaskContract blocks for all implementation work
# - features/ contains .feature files with Scenarios

# TaskContract
# - heading: "### Task X.Y: <name>"
# - required fields: Context, Verification, Scenario Coverage, Loop Type,
#   Behavioral Contract, Simplification Focus, Status, Step checkboxes,
#   BDD Verification, Advanced Test Verification, Runtime Verification

# BuildBlockedPacket
# - header: "🛑 Build Blocked — Task X.Y: <name>"
# - sections: Reason, Loop Type, Scenario Coverage, What We Tried,
#   Failure Evidence, Failing Step, Suggested Design Change, Impact, Next Action

# DesignChangeRequestPacket
# - header: "🔄 Design Change Request — Task X.Y: <name>"
# - sections: Scenario Coverage, Problem, What We Tried, Failure Evidence,
#   Failing Step, Suggested Change, Impact
```

### 6.3 Interface Design

```bash
# Core utility functions (lib/audit_report/core.sh)
log_info() { local msg="$1"; ... }      # Print info message (respects VERBOSE)
log_warn() { local msg="$1"; ... }      # Print warning to stderr
log_error() { local msg="$1"; ... }     # Print error to stderr
die() { local msg="$1"; local code="${2:-1}"; ... }  # Print error and exit

# OS detection functions (lib/audit_report/detect.sh)
detect_os() { ... }                     # Returns: debian, rhel, arch, or unknown
detect_package_manager() { ... }        # Returns: apt, dnf, yum, or pacman
detect_scap_content() { ... }           # Returns: full path to ssg-*-ds.xml
detect_scap_profile() { local scap_file="$1"; ... }  # Returns: profile ID

# Module interface (each module implements these)
# lib/audit_report/lynis.sh
lynis_check() { ... }                   # Returns 0 if lynis available, 1 otherwise
lynis_run() { local output_dir="$1"; ... }  # Runs lynis, writes to output_dir
lynis_get_output_file() { ... }         # Returns path to generated output

# lib/audit_report/rkhunter.sh
rkhunter_check() { ... }
rkhunter_run() { local output_dir="$1"; ... }
rkhunter_get_output_file() { ... }

# lib/audit_report/chkrootkit.sh
chkrootkit_check() { ... }
chkrootkit_run() { local output_dir="$1"; ... }
chkrootkit_get_output_file() { ... }

# lib/audit_report/openscap.sh
openscap_check() { ... }
openscap_run() { local output_dir="$1"; ... }
openscap_get_output_file() { ... }

# Report generation (lib/audit_report/report.sh)
report_generate_summary() {
    local output_dir="$1"
    local -n _module_status="$2"
    local -n _module_output="$3"
    ...
}
```

### 6.4 Logic Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                         START                                   │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  bin/audit-report                                               │
│  1. Parse CLI arguments (--output, --modules, --verbose, etc)   │
│  2. Validate --output provided and directory writable          │
│  3. If --output not provided → die with usage                   │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ROOT CHECK                                                     │
│  if [[ $EUID -ne 0 ]]; then                                     │
│      die "Error: audit-report must be run as root (use sudo)."  │
│  fi                                                               │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SETUP OUTPUT DIRECTORY                                         │
│  1. Generate TIMESTAMP=$(date +%Y%m%d-%H%M%S)                   │
│  2. RUN_DIR="${OUTPUT_DIR}/${TIMESTAMP}"                        │
│  3. mkdir -p "$RUN_DIR"                                         │
│  4. If mkdir fails → die with clear error                       │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  DETECT OS (lib/audit_report/detect.sh)                         │
│  1. Source /etc/os-release                                       │
│  2. Determine DISTRO_FAMILY (debian, rhel, arch, unknown)      │
│  3. Log detected OS to detect.txt in RUN_DIR                    │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  MODULE LOOP (Sequential, one at a time)                        │
│  for module in "${MODULES[@]}"; do                              │
│      run_module "$module" "$RUN_DIR"                          │
│  done                                                             │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  RUN_MODULE (Template Method)                                    │
│  1. Check if module available (module_check)                   │
│     - If not available:                                          │
│       - If SKIP_MISSING=1: log warning, mark skipped, return 0  │
│       - If SKIP_MISSING=0: die with error                        │
│  2. Run module (module_run "$RUN_DIR")                          │
│  3. Capture output file path                                     │
│  4. Update MODULE_STATUS and MODULE_OUTPUT                      │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GENERATE SUMMARY (lib/audit_report/report.sh)                   │
│  1. Read MODULE_STATUS and MODULE_OUTPUT                        │
│  2. Count warnings, suggestions, failures from each output      │
│  3. Write summary-{TIMESTAMP}.txt to RUN_DIR                    │
│     - Scan timestamp and hostname                               │
│     - Detected OS family and version                            │
│     - Per-module status (ran/skipped/not-installed)            │
│     - Key findings counts                                       │
│     - Paths to all generated report files                       │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         END                                     │
│  Exit code 0 on success, non-zero on fatal error                │
└─────────────────────────────────────────────────────────────────┘
```

### 6.5 Configuration

```bash
# Configuration is via CLI arguments and environment

# CLI Arguments (parsed by bin/audit-report)
OUTPUT_DIR=""           # -o, --output (required)
MODULES=()            # -m, --modules (default: all)
SKIP_MISSING=1          # --skip-missing (default: 1)
VERBOSE=0               # -v, --verbose

# Environment Variables (optional overrides)
LYNIS_PATH=""           # Override lynis binary path
RKHUNTER_PATH=""        # Override rkhunter binary path
CHKROOTKIT_PATH=""      # Override chkrootkit binary path
OSCAP_PATH=""           # Override oscap binary path

# No config files needed — all configuration via CLI flags
```

### 6.6 Error Handling

```bash
# Error codes (conventional Bash exit codes)
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_INVALID_ARGS=2
readonly E_NOT_ROOT=3
readonly E_OUTPUT_NOT_WRITABLE=4
readonly E_TOOL_MISSING=5

# Error handling patterns

# 1. Fatal errors (die immediately)
die() {
    local msg="$1"
    local code="${2:-$E_GENERAL}"
    log_error "$msg"
    exit "$code"
}

# Usage examples:
# die "--output is required" $E_INVALID_ARGS
# die "Must run as root" $E_NOT_ROOT
# die "Output directory not writable: $dir" $E_OUTPUT_NOT_WRITABLE

# 2. Non-fatal warnings (log and continue)
warn() {
    local msg="$1"
    log_warn "$msg"
}

# Usage examples:
# warn "lynis not found, skipping"
# warn "SCAP content not found, skipping OpenSCAP"

# 3. Command failure handling
# Use || for expected failures:
if ! some_command; then
    warn "Command failed, continuing"
fi

# Use die for unexpected failures:
some_critical_command || die "Critical step failed"

# 4. Trap for cleanup (if needed)
cleanup() {
    local exit_code=$?
    # Cleanup temp files if any
    exit "$exit_code"
}
trap cleanup EXIT
```

### 6.7 Maintainability Notes

- **Function naming:** Use `verb_noun` pattern: `detect_os`, `run_lynis`, `generate_summary`
- **Variable naming:** UPPER_CASE for globals, lower_case for locals with `local` keyword
- **File naming:** lowercase with underscores matching function names
- **Module isolation:** Each module in lib/audit_report/*.sh is independently testable
- **Documentation:** Each function has header comment with description, args, return value
- **Error messages:** Start with capital letter, no trailing period, include relevant variable values
- **Logging:** Use log_info/log_warn/log_error consistently, respect VERBOSE flag

---

## 7. Verification & Testing Strategy

### 7.1 Unit Testing

| Test File | Coverage | Mock Strategy |
| :--- | :--- | :--- |
| `tests/detect.bats` | OS detection functions | Mock /etc/os-release via temporary files |
| `tests/lynis.bats` | Lynis wrapper functions | Mock `command -v` and lynis binary |
| `tests/rkhunter.bats` | rkhunter wrapper functions | Mock rkhunter binary |
| `tests/chkrootkit.bats` | chkrootkit wrapper functions | Mock chkrootkit binary |
| `tests/openscap.bats` | OpenSCAP wrapper, SCAP path detection | Mock oscap binary and content files |
| `tests/report.bats` | Summary generation | Mock module status/output arrays |
| `tests/core.bats` | CLI parsing, root check, directory setup | Mock environment variables and filesystem |

### 7.2 Property Testing

| Target Behavior | Why Property Testing Helps | Tool / Command | Planned Invariants |
| :--- | :--- | :--- | :--- |
| N/A | Bash scripts interact with external tools and filesystem | N/A | N/A |

Property testing not applicable for this Bash project — the domain involves external tool execution and filesystem operations rather than pure functions with large input domains.

### 7.3 Integration Testing

| Test Scenario | Approach | Verification |
| :--- | :--- | :--- |
| End-to-end run with all modules | Run `sudo bin/audit-report --output /tmp/test-audit` | Verify directory created, summary.txt exists, all module outputs present |
| Missing tool handling | Run with lynis uninstalled | Verify warning logged, other modules still run, summary shows lynis as skipped |
| Non-root execution | Run as non-root user | Verify immediate exit with error code 3 and clear message |
| Unknown distribution | Mock /etc/os-release with unknown ID | Warning logged, best-effort detection attempted |

### 7.4 BDD Acceptance Testing

| Scenario ID | Feature File | Command | Success Criteria |
| :--- | :--- | :--- | :--- |
| **BDD-01** | `features/audit.feature` | `bats tests/detect.bats` | All OS detection scenarios pass |
| **BDD-02** | `features/audit.feature` | `bats tests/core.bats` | Root check, CLI parsing scenarios pass |
| **BDD-03** | `features/audit.feature` | `bats tests/lynis.bats` | Lynis module scenarios pass |
| **BDD-04** | `features/audit.feature` | `bats tests/openscap.bats` | OpenSCAP module scenarios pass |
| **BDD-05** | `features/audit.feature` | `sudo bin/audit-report --output /tmp/bdd-test` | End-to-end scenario produces valid output directory with summary.txt |

### 7.5 Robustness & Performance Testing

| Test Type | When It Is Required | Tool / Command | Planned Coverage or Reason Not Needed |
| :--- | :--- | :--- | :--- |
| **Fuzz** | Parser/protocol/unsafe paths only | N/A | No parsers or protocol implementations — audit-report wraps external tools |
| **Benchmark** | Explicit latency requirements | N/A | No performance requirements defined; execution time dominated by external tool runtime |

### 7.6 Critical Path Verification (The "Harness")

| Verification Step | Command | Success Criteria |
| :--- | :--- | :--- |
| **VP-01** | `just check` | All format, lint, and test commands pass |
| **VP-02** | `sudo bin/audit-report --output /tmp/audit-test` | Directory /tmp/audit-test/YYYYMMDD-HHMMSS/ created with summary.txt |
| **VP-03** | `ls /tmp/audit-test/*/summary.txt` | Summary file exists and contains "Scan completed" or similar |
| **VP-04** | `runuser -u nobody -- bin/audit-report --output /tmp/test 2>&1` | Exit code 3, output contains "must be run as root" |
| **VP-05** | `bats tests/` | All Bats tests pass (0 failures) |

**Why this matters:** These verification commands ensure the tool works end-to-end as a security auditing solution. The harness validates root enforcement, output generation, and test coverage that proves each module functions correctly.

### 7.7 Validation Rules

| Test Case ID | Action | Expected Outcome | Verification Method |
| :--- | :--- | :--- | :--- |
| **TC-01** | Run without --output | Exit with error code 2, show usage | `bats tests/core.bats` |
| **TC-02** | Run with non-writable output dir | Exit with error code 4 | `bats tests/core.bats` |
| **TC-03** | Run on Ubuntu 22.04 | Detect debian family, use apt paths | `bats tests/detect.bats` |
| **TC-04** | Run on Rocky Linux 9 | Detect rhel family, use dnf paths | `bats tests/detect.bats` |
| **TC-05** | Run without lynis installed | Warning logged, continue with other modules | `bats tests/lynis.bats` |
| **TC-06** | Run without SCAP content | Warning with install instructions | `bats tests/openscap.bats` |
| **TC-07** | Module produces findings | Summary includes warning/fail counts | `bats tests/report.bats` |
| **TC-08** | All modules skip | Summary shows all skipped, no failures | `bats tests/report.bats` |

---

## 8. Implementation Plan

- [ ] **Phase 1: Foundation** — Project setup, directory structure, core utilities, CLI parsing
- [ ] **Phase 2: Core Logic** — OS detection, module wrappers (lynis, rkhunter, chkrootkit, openscap)
- [ ] **Phase 3: Integration** — Module orchestration, report generation, end-to-end wiring
- [ ] **Phase 4: Polish** — BDD scenarios, comprehensive tests, documentation, CI verification

---

## 9. Cross-Functional Concerns

### Security Review

- Tool requires root to read privileged files (/etc/shadow, kernel params, audit logs)
- No network access required (local-only audit)
- Output directory permissions should restrict access to root
- No secrets or credentials stored in code

### Backward Compatibility

- First release (v0.1.0) — no backward compatibility concerns
- Future versions should maintain CLI flag compatibility

### Documentation Updates

- README.md to be updated with installation and usage instructions
- Add man page or --help output documentation
- Document distribution-specific SCAP content package names

### Rollback Strategy

- No persistent system changes — rollback is simply deleting output directory
- No services to stop or configurations to revert
