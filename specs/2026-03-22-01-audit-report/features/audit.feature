Feature: Linux Security Audit Report Generation
  As a system administrator
  I want to run automated security audits on Linux systems
  So that I can identify security issues and maintain compliance

  # OS Detection Scenarios

  Scenario: Detect Ubuntu OS family
    Given /etc/os-release contains ID=ubuntu and ID_LIKE=debian
    When I run detect_os
    Then the result should be "debian"
    And the package manager should be "apt"

  Scenario: Detect Rocky Linux OS family
    Given /etc/os-release contains ID=rocky and ID_LIKE="rhel centos fedora"
    When I run detect_os
    Then the result should be "rhel"
    And the package manager should be "dnf"

  Scenario: Detect CentOS Stream OS family
    Given /etc/os-release contains ID=centos and ID_LIKE="rhel fedora"
    When I run detect_os
    Then the result should be "rhel"
    And the package manager should be "dnf" or "yum"

  Scenario: Detect Arch Linux OS family
    Given /etc/os-release contains ID=arch
    When I run detect_os
    Then the result should be "arch"
    And the package manager should be "pacman"

  Scenario: Detect Manjaro OS family
    Given /etc/os-release contains ID=manjaro and ID_LIKE=arch
    When I run detect_os
    Then the result should be "arch"
    And the package manager should be "pacman"

  Scenario: Handle unknown distribution
    Given /etc/os-release contains ID=unknownos
    When I run detect_os
    Then the result should be "unknown"
    And a warning should be logged

  # Privilege and Access Control

  Scenario: Root privilege check
    Given the current user is not root (EUID != 0)
    When I run audit-report with any arguments
    Then it should exit immediately with error code 3
    And the error message should contain "must be run as root"
    And no output directory should be created

  Scenario: Root user execution
    Given the current user is root (EUID == 0)
    When I run audit-report with valid --output directory
    Then it should proceed with audit execution
    And the output directory should be created

  # Output Directory and Structure

  Scenario: Create timestamped output directory
    Given the current time is 2026-03-22 14:30:00
    When I run audit-report --output /tmp/audits
    Then a directory /tmp/audits/20260322-143000/ should be created
    And all report files should be written to this directory

  Scenario: Prevent overwriting existing reports
    Given an output directory /tmp/audits already exists
    And it contains a previous audit report
    When I run audit-report --output /tmp/audits again
    Then a new timestamped subdirectory should be created
    And the previous report should remain intact

  Scenario: Fail on non-writable output directory
    Given I specify --output /root/protected_dir (non-writable)
    When I run audit-report
    Then it should exit with error code 4
    And the error message should indicate the directory is not writable

  # CLI Argument Parsing

  Scenario: Require --output flag
    When I run audit-report without --output flag
    Then it should exit with error code 2
    And the error message should indicate --output is required
    And the usage information should be displayed

  Scenario: Specify modules to run
    When I run audit-report --output /tmp/audits --modules lynis,rkhunter
    Then only the lynis and rkhunter modules should execute
    And the chkrootkit and openscap modules should be skipped

  Scenario: Skip missing tools (default)
    Given the rkhunter tool is not installed
    And I run audit-report with --output /tmp/audits (default behavior)
    Then rkhunter should be skipped with a warning
    And other modules should continue executing

  Scenario: Fail on missing tools
    Given the rkhunter tool is not installed
    And I run audit-report --output /tmp/audits --no-skip-missing
    Then it should exit with error code 5
    And the error message should indicate rkhunter is required but not found

  Scenario: Enable verbose output
    When I run audit-report --output /tmp/audits --verbose
    Then detailed progress information should be printed to stdout
    Including module start/end messages and file paths

  Scenario: Display version
    When I run audit-report --version
    Then it should print the version number and exit with code 0

  Scenario: Display help
    When I run audit-report --help
    Then it should display usage information
    Including all available options and examples
    And exit with code 0

  # Module Execution

  Scenario: Sequential module execution
    Given all modules are enabled
    When I run audit-report with --verbose
    Then modules should execute in order: lynis, rkhunter, chkrootkit, openscap
    And each module should complete before the next starts

  Scenario: Lynis module execution
    Given lynis is installed
    When the lynis module runs
    Then it should execute: lynis audit system --logfile <output_dir>/lynis-<ts>.log
    And the log file should be created in the output directory

  Scenario: rkhunter module execution
    Given rkhunter is installed
    When the rkhunter module runs
    Then it should execute: rkhunter --check --skip-keypress --logfile <output_dir>/rkhunter-<ts>.log
    And the log file should be created in the output directory

  Scenario: chkrootkit module execution
    Given chkrootkit is installed
    When the chkrootkit module runs
    Then it should execute: chkrootkit with output redirected to <output_dir>/chkrootkit-<ts>.txt
    And the output file should be created in the output directory

  Scenario: OpenSCAP module execution with content detection
    Given oscap is installed
    And SCAP Security Guide content is available
    When the openscap module runs
    Then it should:
      1. Detect the correct SCAP datastream file (ssg-<distro><version>-ds.xml)
      2. Detect the best available profile (cis > standard > first available)
      3. Run: oscap xccdf eval --profile <profile> --results <output_dir>/oscap-results-<ts>.xml --report <output_dir>/oscap-report-<ts>.html <datastream>
    And both XML results and HTML report should be created

  Scenario: OpenSCAP module with missing content
    Given oscap is installed
    But SCAP Security Guide content is NOT available
    When the openscap module runs
    Then it should log a warning with install instructions for the detected distro
    And the module should be marked as skipped
    And other modules should continue execution

  # Report Generation

  Scenario: Summary report generation
    Given all modules have completed (successfully or skipped)
    When the report generation phase runs
    Then a summary file should be created at <output_dir>/summary-<timestamp>.txt
    And it should contain:
      - Scan timestamp and hostname
      - Detected OS family and version
      - Per-module status (ran / skipped / not-installed)
      - Key findings: WARNING count, SUGGESTION count, FAIL count (if available)
      - Paths to all generated report files

  Scenario: Empty run (all modules skipped)
    Given no audit tools are installed
    When I run audit-report
    Then all modules should be marked as skipped
    And the summary should indicate no tools were available
    And the exit code should be 0 (not a failure, just no tools)

  # Error Handling and Edge Cases

  Scenario: Handle malformed /etc/os-release
    Given /etc/os-release is missing or malformed
    When detect_os runs
    Then it should return "unknown"
    And a warning should be logged
    And the scan should continue (best-effort mode)

  Scenario: Handle full disk during scan
    Given the output directory is on a filesystem with no space remaining
    When the audit runs and tries to write output
    Then it should fail with a clear error message
    And partial output files may remain (documented limitation)

  Scenario: Handle interrupted scan
    Given an audit is running
    When the user sends SIGINT (Ctrl+C)
    Then the current module should be terminated
    And a partial summary should be generated if possible
    And exit code should be non-zero
