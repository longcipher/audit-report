#!/usr/bin/env bats

# Tests for CLI argument parsing and core functions (audit-report)

setup() {
    load 'test_helper'
    common_setup
}

teardown() {
    common_teardown
}

# --- Logging Tests ---

@test "log_info outputs correct format" {
    run log_info "test message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[INFO] test message"* ]]
}

@test "log_warn outputs to stderr" {
    run log_warn "warning message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[WARN] warning message"* ]]
}

@test "log_error outputs to stderr" {
    run log_error "error message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[ERROR] error message"* ]]
}

# --- die Tests ---

@test "die exits with default code 1" {
    run die "fatal error"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"fatal error"* ]]
}

@test "die exits with custom code" {
    run die "custom error" 2
    [[ "$status" -eq 2 ]]
    [[ "$output" == *"custom error"* ]]
}

# --- command_exists Tests ---

@test "command_exists returns 0 for existing command" {
    run command_exists "bash"
    [[ "$status" -eq 0 ]]
}

@test "command_exists returns 1 for non-existent command" {
    run command_exists "nonexistent_command_xyz_123"
    [[ "$status" -eq 1 ]]
}

# --- Version Constant ---

@test "AUDIT_REPORT_VERSION is defined" {
    [[ -n "$AUDIT_REPORT_VERSION" ]]
}

@test "AUDIT_REPORT_VERSION follows semver" {
    [[ "$AUDIT_REPORT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# --- Error Code Constants ---

@test "error code constants are defined" {
    [[ "$E_SUCCESS" -eq 0 ]]
    [[ "$E_GENERAL" -eq 1 ]]
    [[ "$E_INVALID_ARGS" -eq 2 ]]
    [[ "$E_NOT_ROOT" -eq 3 ]]
    [[ "$E_OUTPUT_NOT_WRITABLE" -eq 4 ]]
    [[ "$E_TOOL_MISSING" -eq 5 ]]
}

# --- CLI Argument Parsing Tests ---

@test "audit-report --help shows usage" {
    run "$PROJECT_DIR/bin/audit-report" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--output"* ]]
    [[ "$output" == *"--modules"* ]]
    [[ "$output" == *"--verbose"* ]]
    [[ "$output" == *"--help"* ]]
    [[ "$output" == *"--version"* ]]
}

@test "audit-report --version shows version" {
    run "$PROJECT_DIR/bin/audit-report" --version
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"audit-report"* ]]
    [[ "$output" == *"0.1.0"* ]]
}

@test "audit-report without --output fails with error" {
    run "$PROJECT_DIR/bin/audit-report"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *"--output"* ]]
}

@test "audit-report with --output accepts value" {
    # This will still fail at root check, but should parse args correctly
    run "$PROJECT_DIR/bin/audit-report" --output /tmp/test
    # Should not fail with invalid args error
    [[ "$output" != *"--output is required"* ]]
}

@test "audit-report with -o short flag works" {
    run "$PROJECT_DIR/bin/audit-report" -o /tmp/test
    [[ "$output" != *"--output is required"* ]]
}

@test "audit-report with --modules accepts value" {
    run "$PROJECT_DIR/bin/audit-report" --output /tmp/test --modules lynis,rkhunter
    [[ "$output" != *"Unknown option"* ]]
}

@test "audit-report with --verbose flag" {
    run "$PROJECT_DIR/bin/audit-report" --output /tmp/test --verbose
    [[ "$output" != *"Unknown option"* ]]
}

@test "audit-report with unknown option fails" {
    run "$PROJECT_DIR/bin/audit-report" --unknown-flag
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Unknown option"* ]]
}

@test "audit-report with -h shows help" {
    run "$PROJECT_DIR/bin/audit-report" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "audit-report with --version flag works" {
    run "$PROJECT_DIR/bin/audit-report" --version
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"audit-report"* ]]
}

# --- Root Check Tests ---

@test "audit-report requires root privileges" {
    # Run as current user (non-root in test env)
    if [[ $EUID -eq 0 ]]; then
        skip "Running as root, cannot test root check"
    fi
    run "$PROJECT_DIR/bin/audit-report" --output /tmp/test-audit
    [[ "$status" -eq 3 ]]
    [[ "$output" == *"must be run as root"* ]]
}

# --- Output Directory Tests ---

@test "audit-report creates timestamped output directory" {
    if [[ $EUID -ne 0 ]]; then
        skip "Requires root"
    fi
    local test_dir="$TEST_TMP_DIR/audit-out"
    mkdir -p "$test_dir"
    run "$PROJECT_DIR/bin/audit-report" --output "$test_dir"
    [[ "$status" -eq 0 ]]
    # Check that a timestamped subdirectory was created
    local subdirs
    subdirs=$(find "$test_dir" -mindepth 1 -maxdepth 1 -type d | wc -l) || true
    [[ "$subdirs" -ge 1 ]]
}

@test "RUN_DIR contains timestamp format" {
    if [[ $EUID -ne 0 ]]; then
        skip "Requires root"
    fi
    local test_dir="$TEST_TMP_DIR/audit-out"
    mkdir -p "$test_dir"
    run "$PROJECT_DIR/bin/audit-report" --output "$test_dir"
    [[ "$status" -eq 0 ]]
    # Find the created subdirectory and check timestamp format YYYYMMDD-HHMMSS
    local subdir
    subdir=$(find "$test_dir" -mindepth 1 -maxdepth 1 -type d | head -1) || true
    local dirname
    dirname=$(basename "$subdir")
    [[ "$dirname" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}
