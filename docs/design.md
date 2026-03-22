# Audit Report — System Design Document

## 1. Overview

**Project Name:** audit-report  
**Version:** 0.1.0  
**Language:** Bash (>= 4.0)  
**License:** Apache-2.0

`audit-report` is a non-invasive Linux security auditing tool that automatically detects the host operating system distribution and generates comprehensive security audit reports. It leverages industry-standard tools (Lynis, rkhunter, chkrootkit, OpenSCAP) and consolidates all output into a single user-specified directory.

### Design Goals

1. **Non-invasive** — Never modifies system files, permissions, or configurations. Only reads system state and writes reports to a designated output directory.
2. **Portable** — Automatically detects the Linux distribution family and adapts tool invocation, package names, and SCAP content paths accordingly.
3. **Self-contained** — All reports, logs, and artifacts are written to one timestamped directory with no side effects elsewhere.
4. **Reproducible** — Timestamped output ensures historical reports are never overwritten.
5. **Strict root enforcement** — The wrapper must run as root to ensure audit tools can access privileged system state (e.g., `/etc/shadow`, kernel parameters, audit logs). Running as a non-root user would produce incomplete and misleading results.

---

## 2. Supported Distributions

| Distribution Family | Identifiers                             | Package Manager | SCAP Content Path Pattern                         |
|---------------------|-----------------------------------------|-----------------|---------------------------------------------------|
| Debian / Ubuntu     | debian, ubuntu, linuxmint, pop          | apt             | `/usr/share/xml/scap/ssg/content/ssg-*-ds.xml`    |
| RHEL / CentOS / Fedora / AlmaLinux / Rocky | rhel, centos, fedora, almalinux, rocky | dnf / yum       | `/usr/share/xml/scap/ssg/content/ssg-rhel*-ds.xml` |
| Arch Linux          | arch, manjaro, endeavouros              | pacman          | `/usr/share/xml/scap/ssg/content/ssg-*-ds.xml`    |

### Distribution Detection Strategy

The tool reads `/etc/os-release` (or falls back to `/etc/redhat-release`, `/etc/arch-release`) and extracts:

- `ID` — primary distribution identifier (e.g., `ubuntu`, `arch`, `rhel`)
- `ID_LIKE` — space-separated family hints (e.g., `debian`, `rhel fedora`)
- `VERSION_CODENAME` / `VERSION_ID` — version-specific SCAP content selection

Detection logic:

```text
1. Parse /etc/os-release → ID, ID_LIKE
2. Classify into family:
   - If ID or ID_LIKE contains "debian" or "ubuntu" → debian
   - If ID or ID_LIKE contains "rhel", "centos", "fedora", "almalinux", "rocky" → rhel
   - If ID or ID_LIKE contains "arch", "manjaro" → arch
3. Map family → tool installation commands, SCAP content path, CIS profile name
```

---

## 3. Architecture

### 3.1 Component Diagram

```text
audit-report (bin/audit-report)
│
├── lib/audit-report/
│   ├── detect.sh        # OS detection (distro family, version)
│   ├── lynis.sh         # Lynis audit wrapper
│   ├── rkhunter.sh      # rkhunter scan wrapper
│   ├── chkrootkit.sh    # chkrootkit scan wrapper
│   ├── openscap.sh      # OpenSCAP XCCDF/OVAL evaluation wrapper
│   └── report.sh        # Report aggregation and summary
│
├── docs/
│   └── design.md        # This document
│
├── tests/
│   ├── detect.bats      # Tests for OS detection
│   ├── lynis.bats       # Tests for Lynis wrapper
│   └── ...
│
├── features/
│   └── audit.feature    # BDD acceptance scenarios
│
├── justfile             # Task runner (format, lint, test, build)
├── .shellcheckrc        # ShellCheck configuration
└── .editorconfig        # Editor formatting rules
```

### 3.2 Data Flow

```text
User invokes: audit-report --output /path/to/reports
         │
         ▼
   ┌─────────────┐
   │ detect.sh   │  Read /etc/os-release → distro family
   └──────┬──────┘
          │
          ▼
   ┌──────────────────────────────────────────┐
   │  For each enabled audit module:          │
   │                                          │
   │  lynis.sh    →  lynis-{ts}.log           │
   │  rkhunter.sh →  rkhunter-{ts}.log        │
   │  chkrootkit  →  chkrootkit-{ts}.txt      │
   │  openscap.sh →  oscap-{ts}.html + .xml   │
   │                                          │
   │  All output written to OUTPUT_DIR        │
   └──────────────────────────────────────────┘
          │
          ▼
   ┌─────────────┐
   │ report.sh   │  Generate summary.txt with pass/fail/warn counts
   └─────────────┘
```

---

## 4. Modules

### 4.1 `detect.sh` — OS Detection

**Purpose:** Identify the Linux distribution family to select appropriate tool commands and SCAP content.

**Functions:**

| Function                  | Returns         | Description                                      |
|---------------------------|-----------------|--------------------------------------------------|
| `detect_os`               | `distro_family` | Parse `/etc/os-release`; return `debian`, `rhel`, or `arch` |
| `detect_package_manager`  | `pkg_mgr`       | Return `apt`, `dnf`, `yum`, or `pacman`          |
| `detect_scap_content`     | `path`          | Locate and return the exact SCAP datastream file path |
| `detect_scap_profile`     | `profile_id`    | Return the best available CIS/standard profile ID |

**Detection Rules:**

```bash
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        local id="${ID:-unknown}"
        local id_like="${ID_LIKE:-}"

        case "$id $id_like" in
            *debian*|*ubuntu*)                             echo "debian" ;;
            *rhel*|*centos*|*fedora*|*almalinux*|*rocky*)  echo "rhel" ;;
            *arch*|*manjaro*)                              echo "arch" ;;
            *)                                             echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}
```

### 4.2 `lynis.sh` — Lynis Audit

**Purpose:** Run Lynis system audit and capture results.

**Key behavior:**

- Locate Lynis binary: check `lynis` in `$PATH`, then `/usr/sbin/lynis`, then `/usr/local/bin/lynis`
- If not installed, log a warning and skip (do **not** auto-install)
- Invoke with `--logfile` and `--report-file` pointing to `$OUTPUT_DIR`
- Capture console output separately for quick review

### 4.3 `rkhunter.sh` — Rootkit Hunter

**Purpose:** Run rkhunter rootkit scan.

**Key behavior:**

- Locate rkhunter binary in `$PATH`
- If not installed, log a warning and skip
- Use `--logfile` to write directly to `$OUTPUT_DIR`
- Run with `--skip-keypress` for non-interactive mode

### 4.4 `chkrootkit.sh` — chkrootkit

**Purpose:** Run chkrootkit scan.

**Key behavior:**

- Locate chkrootkit binary in `$PATH`
- If not installed, log a warning and skip
- Redirect stdout/stderr to `$OUTPUT_DIR/chkrootkit-{timestamp}.txt`

### 4.5 `openscap.sh` — OpenSCAP Evaluation

**Purpose:** Run OpenSCAP XCCDF evaluation against CIS benchmarks.

**Key behavior:**

- Locate `oscap` binary in `$PATH`
- If not installed, log a warning and skip
- Auto-detect SCAP content path using `detect_scap_content` (must resolve to an **exact** filename, not a glob pattern)
- If SCAP content is not installed, log a warning with install instructions for the detected distro family
- Generate both XML results and HTML report in `$OUTPUT_DIR`

**SCAP content filename resolution:**

`detect_scap_content` must construct the exact datastream filename per distribution:

| Family  | Filename pattern example                          |
|---------|--------------------------------------------------|
| debian  | `ssg-ubuntu2204-ds.xml` or `ssg-debian12-ds.xml` |
| rhel    | `ssg-rhel9-ds.xml` or `ssg-centos8-ds.xml`       |
| arch    | `ssg-archlinux-ds.xml` (if available)             |

The function reads `VERSION_ID` from `/etc/os-release` and interpolates it into the filename, then verifies the file exists on disk before returning.

**Profile fallback strategy:**

Not all distributions ship CIS profiles. `detect_scap_profile` must dynamically extract available profiles and select the best match:

```bash
detect_scap_profile() {
    local scap_file="$1"
    local available_profiles
    available_profiles=$(oscap info "$scap_file" 2>/dev/null | grep "Id: xccdf_org" | awk '{print $2}')

    if echo "$available_profiles" | grep -q "profile_cis"; then
        echo "xccdf_org.ssgproject.content_profile_cis"
    elif echo "$available_profiles" | grep -q "profile_standard"; then
        echo "xccdf_org.ssgproject.content_profile_standard"
    else
        # Fallback: use the first available profile
        echo "$available_profiles" | head -1
    fi
}
```

**SCAP content install hints by distro:**

| Family  | Content package (install hint)                               |
|---------|--------------------------------------------------------------|
| debian  | `apt install ssg-debian` or `ssg-ubuntu`                     |
| rhel    | `dnf install scap-security-guide`                            |
| arch    | `pacman -S scap-security-guide` (from AUR if not in repos)   |

### 4.6 `report.sh` — Summary Report

**Purpose:** Aggregate results from all modules into a human-readable summary.

**Output:** `summary-{timestamp}.txt` containing:

- Scan timestamp and hostname
- Detected OS family and version
- Per-module status (ran / skipped / not-installed)
- Key findings: WARNING count, SUGGESTION count, FAIL count
- Paths to all generated report files

---

## 5. CLI Interface

```text
audit-report [OPTIONS]

Options:
  -o, --output DIR       Output directory for reports (required)
  -m, --modules LIST     Comma-separated list of modules to run
                         (default: lynis,rkhunter,chkrootkit,openscap)
  --skip-missing         Skip modules whose tools are not installed (default)
  --no-skip-missing      Fail if any required tool is missing
  -v, --verbose          Enable verbose output
  -h, --help             Show help message
  --version              Show version
```

**Execution order:** All modules run **sequentially** (one at a time) to avoid I/O contention and resource locking (e.g., dpkg/rpm database locks). Parallel execution is explicitly not supported.

**Output directory behavior:** The tool automatically creates a timestamped subdirectory (e.g., `YYYYMMDD-HHMMSS/`) inside the provided `--output` directory. Running the tool multiple times with the same `--output` path will never overwrite previous reports.

**Examples:**

```bash
# Run all modules, output to ~/audit-reports/20260322-213000/
sudo audit-report --output ~/audit-reports

# Run only Lynis and rkhunter
sudo audit-report --output /tmp/audit --modules lynis,rkhunter

# Verbose mode for debugging
sudo audit-report --output ./reports --verbose
```

---

## 6. Non-Invasive Principles

| Principle                          | Implementation                                                                 |
|------------------------------------|--------------------------------------------------------------------------------|
| **Strict root enforcement**        | Wrapper must run as root (UID 0). Entry point validates `$EUID` and exits with a clear error if non-root. Deep audit tools (Lynis, rkhunter, OpenSCAP) require root to read privileged files (`/etc/shadow`, kernel parameters, audit logs). Running without root produces incomplete and misleading results. |
| **No system modification**         | Tool only reads system state; writes exclusively to `--output` dir            |
| **No auto-installation**           | Missing tools are logged as warnings, never installed automatically           |
| **No permission changes**          | No `chmod`, `chown`, or `setfacl` calls on system paths                       |
| **No temp files outside output**   | All intermediate data stays within `$OUTPUT_DIR`                               |
| **Read-only system access**        | Only `/etc/os-release`, tool binaries, and SCAP content are read              |

**Entry point guard:**

```bash
if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: audit-report must be run as root (use sudo)." >&2
    exit 1
fi
```

---

## 7. Output Structure

```text
~/audit-reports/
├── 20260322-213000/
│   ├── detect.txt                  # Detected OS info
│   ├── lynis-20260322-213000.log
│   ├── lynis-report-20260322-213000.dat
│   ├── rkhunter-20260322-213000.log
│   ├── chkrootkit-20260322-213000.txt
│   ├── oscap-results-20260322-213000.xml
│   ├── oscap-report-20260322-213000.html
│   └── summary-20260322-213000.txt
```

Each run creates a timestamped subdirectory to preserve historical reports.

---

## 8. Error Handling

| Scenario                        | Behavior                                              |
|---------------------------------|-------------------------------------------------------|
| Unknown distro                  | Warn and attempt best-effort detection; skip SCAP     |
| Tool not installed              | Log warning; skip module; continue with others        |
| SCAP content missing            | Log install instructions for detected distro; skip    |
| SCAP profile unavailable        | Fallback to `standard` profile, then first available  |
| Output dir not writable         | Fail immediately with clear error message             |
| Not running as root             | Fail immediately at entry point with clear error      |
| Partial failure (1 of N modules)| Complete remaining modules; report per-module status  |

---

## 9. Testing Strategy

### Unit Tests (Bats-core)

- `tests/detect.bats` — Mock `/etc/os-release` content; verify family detection
- `tests/lynis.bats` — Verify correct flags and output paths
- `tests/openscap.bats` — Verify SCAP content path resolution per distro

### BDD Scenarios

```gherkin
Feature: OS Detection
  Scenario: Detect Ubuntu
    Given /etc/os-release contains ID=ubuntu
    When I run detect_os
    Then the result should be "debian"

  Scenario: Detect Arch Linux
    Given /etc/os-release contains ID=arch
    When I run detect_os
    Then the result should be "arch"

  Scenario: Detect Rocky Linux
    Given /etc/os-release contains ID=rocky ID_LIKE="rhel centos fedora"
    When I run detect_os
    Then the result should be "rhel"

  Scenario: Root privilege check
    Given the current user is not root
    When I run audit-report
    Then it should exit with error "must be run as root"

  Scenario: Sequential execution
    Given all modules are enabled
    When I run audit-report
    Then modules should execute in order: lynis, rkhunter, chkrootkit, openscap
```

---

## 10. Dependencies

| Tool        | Required | Purpose                        | Install (Debian)           | Install (RPM)              | Install (Arch)             |
|-------------|----------|--------------------------------|----------------------------|----------------------------|----------------------------|
| Lynis       | Optional | System hardening audit         | `apt install lynis`        | `dnf install lynis`        | `pacman -S lynis`          |
| rkhunter    | Optional | Rootkit detection              | `apt install rkhunter`     | `dnf install rkhunter`     | `pacman -S rkhunter`       |
| chkrootkit  | Optional | Rootkit detection              | `apt install chkrootkit`   | `dnf install chkrootkit`   | `pacman -S chkrootkit`     |
| OpenSCAP    | Optional | CIS benchmark evaluation       | `apt install libopenscap8` | `dnf install openscap-scanner` | `pacman -S openscap`  |
| SSG content | Optional | SCAP datastream files          | `apt install ssg-debian`   | `dnf install scap-security-guide` | `pacman -S scap-security-guide` (AUR) |

All dependencies are **optional** — the tool gracefully skips modules when tools are not available.

---

## 11. Future Enhancements

- [ ] JSON output format for machine-readable results
- [ ] Integration with CI/CD pipelines (GitHub Actions, GitLab CI)
- [ ] HTML dashboard aggregating all module results
- [ ] Email/Slack notification on critical findings
- [ ] Differential scanning (compare against previous run)
- [ ] Support for container image auditing (Docker, Podman)
