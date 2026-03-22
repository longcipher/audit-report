# audit-report

A non-invasive Linux security auditing tool that auto-detects the OS distribution and runs multiple security scanners, consolidating all outputs into a timestamped directory.

## Features

- **Auto-detection**: Automatically detects OS family (Debian/Ubuntu, RHEL/CentOS/Fedora/Rocky, Arch)
- **Multiple scanners**: Runs Lynis, rkhunter, chkrootkit, and OpenSCAP
- **Graceful degradation**: Skips missing tools with warnings (or fails on request)
- **Timestamped output**: Creates `YYYYMMDD-HHMMSS` subdirectories for each run
- **Summary report**: Generates a consolidated summary of all scan results
- **Non-invasive**: Read-only system access; writes only to specified output directory

## Supported Distributions

| Family | Distributions | Package Manager |
|--------|--------------|-----------------|
| Debian | Ubuntu, Debian, Linux Mint, Pop!_OS | apt |
| RHEL | CentOS, RHEL, Rocky Linux, AlmaLinux, Fedora, Oracle Linux | dnf / yum |
| Arch | Arch Linux, Manjaro, EndeavourOS | pacman |

## Requirements

- Bash >= 4.0
- Root privileges (for accessing privileged system files)

### Optional Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| [Lynis](https://cisofy.com/lynis/) | Security auditing | `apt install lynis` / `dnf install lynis` |
| [rkhunter](http://rkhunter.sourceforge.net/) | Rootkit detection | `apt install rkhunter` / `dnf install rkhunter` |
| [chkrootkit](http://www.chkrootkit.org/) | Rootkit detection | `apt install chkrootkit` / `dnf install chkrootkit` |
| [OpenSCAP](https://www.open-scap.org/) | SCAP evaluation | `apt install libopenscap8` / `dnf install openscap-scanner` |
| scap-security-guide | SCAP content | `apt install ssg-debian` / `dnf install scap-security-guide` |

## Installation

```bash
git clone <repository-url>
cd audit-report

# Or install system-wide
sudo just install-app
```

## Usage

### Basic Usage

```bash
# Run all available scanners
sudo ./bin/audit-report --output /var/log/audits

# Run specific modules only
sudo ./bin/audit-report --output /tmp/reports --modules lynis,rkhunter

# Verbose output
sudo ./bin/audit-report --output /tmp/reports --verbose

# Fail if any tool is missing (instead of skipping)
sudo ./bin/audit-report --output /tmp/reports --no-skip-missing
```

### CLI Options

| Option | Description |
|--------|-------------|
| `-o, --output DIR` | Output directory for reports (required) |
| `-m, --modules LIST` | Comma-separated list of modules to run |
| `--skip-missing` | Skip modules whose tools are not installed (default) |
| `--no-skip-missing` | Fail if a required tool is not installed |
| `-v, --verbose` | Enable verbose output |
| `-h, --help` | Show help message |
| `--version` | Show version information |

### Available Modules

- `lynis` — System security auditing
- `rkhunter` — Rootkit detection
- `chkrootkit` — Rootkit detection
- `openscap` — SCAP evaluation with auto-detected profiles

## Output Structure

```text
<output-dir>/
└── YYYYMMDD-HHMMSS/
    ├── detect.txt              # OS detection results
    ├── lynis-YYYYMMDD-HHMMSS.log
    ├── lynis-YYYYMMDD-HHMMSS.dat
    ├── rkhunter-YYYYMMDD-HHMMSS.log
    ├── chkrootkit-YYYYMMDD-HHMMSS.txt
    ├── oscap-results-YYYYMMDD-HHMMSS.xml
    ├── oscap-report-YYYYMMDD-HHMMSS.html
    └── summary-YYYYMMDD-HHMMSS.txt
```

## Development

### Running Tests

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/core.bats

# Run all checks (format, lint, test)
just check
```

### Project Structure

```text
audit-report/
├── bin/
│   └── audit-report          # Main entry point
├── lib/
│   └── audit_report/
│       ├── core.sh           # Logging, error handling, utilities
│       ├── detect.sh         # OS detection functions
│       ├── lynis.sh          # Lynis wrapper
│       ├── rkhunter.sh       # rkhunter wrapper
│       ├── chkrootkit.sh     # chkrootkit wrapper
│       ├── openscap.sh       # OpenSCAP wrapper
│       └── report.sh         # Summary report generation
├── tests/
│   ├── core.bats             # CLI and core function tests
│   ├── detect.bats           # OS detection tests
│   ├── lynis.bats            # Lynis module tests
│   ├── rkhunter.bats         # rkhunter module tests
│   ├── chkrootkit.bats       # chkrootkit module tests
│   ├── openscap.bats         # OpenSCAP module tests
│   ├── report.bats           # Report generation tests
│   └── test_helper.bash      # Shared test utilities
├── features/
│   └── audit.feature         # BDD acceptance scenarios
└── specs/                    # Design specifications
```

## Troubleshooting

**"must be run as root" error**
The tool requires root privileges for accurate audit results. Run with `sudo`.

**Module skipped unexpectedly**
Use `--verbose` to see which tools are detected. Install missing tools or use `--modules` to select only available ones.

**SCAP content not found**
Install the `scap-security-guide` package for your distribution:

- Debian/Ubuntu: `apt install ssg-debian ssg-app`
- RHEL/CentOS: `dnf install scap-security-guide`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the project conventions (`set -euo pipefail`, `[[ ]]`, `local`, `printf`)
4. Run `just check` to verify
5. Submit a pull request

## License

MIT License
