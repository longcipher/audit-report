---
description: Use when user wants to Run automated Linux security audits with multiple scanners
name: audit-report
---

# audit-report

A non-invasive Linux security auditing skill that auto-detects the OS distribution and runs multiple security scanners, consolidating all outputs into a timestamped directory.

## Description

This skill provides automated Linux security auditing capabilities. It detects the operating system family (Debian/Ubuntu, RHEL/CentOS/Fedora/Rocky, Arch) and runs available security scanners including Lynis, rkhunter, chkrootkit, and OpenSCAP. The skill gracefully handles missing tools and generates comprehensive reports with timestamps.

## When to Use

Use this skill when you need to:

- Perform security audits on Linux systems
- Run automated security scans with multiple tools
- Generate consolidated security reports
- Check for rootkits, vulnerabilities, and security misconfigurations
- Evaluate system compliance against security standards

## Trigger Examples

The skill can be triggered with requests like:

- "Run a security audit on this Linux system"
- "Scan for vulnerabilities and rootkits"
- "Perform a Lynis security check"
- "Audit the system security configuration"
- "Check for security issues on this server"
- "Run rkhunter and chkrootkit scans"
- "Generate a security compliance report"

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `output` | string | Yes | Output directory path for reports |
| `modules` | string | No | Comma-separated list of modules to run (lynis,rkhunter,chkrootkit,openscap) |
| `skip_missing` | boolean | No | Skip missing tools (default: true). Set to false to fail on missing tools |
| `verbose` | boolean | No | Enable verbose output |

## Output

The skill generates:

- **Timestamped directory**: `YYYYMMDD-HHMMSS` subdirectory for each run
- **Individual scanner logs**: Separate log files for each tool
- **OS detection results**: `detect.txt` with detected distribution info
- **Summary report**: Consolidated summary of all scan results
- **SCAP reports**: HTML and XML reports when OpenSCAP is used

## Example Usage

```bash
# Basic security audit
sudo ./bin/audit-report --output /var/log/audits

# Run specific modules only
sudo ./bin/audit-report --output /tmp/reports --modules lynis,rkhunter

# Verbose output with all modules
sudo ./bin/audit-report --output /tmp/reports --verbose

# Fail if any tool is missing
sudo ./bin/audit-report --output /tmp/reports --no-skip-missing
```

## Requirements

- Bash >= 4.0
- Root privileges (for accessing privileged system files)
- Linux operating system (Debian/Ubuntu, RHEL/CentOS/Fedora/Rocky, or Arch)

### Optional Dependencies

| Tool | Purpose |
|------|---------|
| [Lynis](https://cisofy.com/lynis/) | System security auditing |
| [rkhunter](http://rkhunter.sourceforge.net/) | Rootkit detection |
| [chkrootkit](http://www.chkrootkit.org/) | Rootkit detection |
| [OpenSCAP](https://www.open-scap.org/) | SCAP evaluation |
| scap-security-guide | SCAP content profiles |

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

## Security Notes

- The skill requires root privileges for accurate audit results
- All operations are read-only system access
- Reports are written only to the specified output directory
- No system modifications are performed during the audit
