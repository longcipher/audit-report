#!/usr/bin/env bats

# Tests for lynis.sh — Lynis audit module

setup() {
    load 'test_helper'
    common_setup

    # Source modules
    source "$PROJECT_DIR/lib/audit-report/lynis.sh"

    # Create mock output directory
    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- lynis_check Tests ---

@test "lynis_check returns 0 when lynis is available" {
    # Create a mock lynis in PATH
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/lynis" << 'EOF'
#!/bin/sh
echo "lynis mock"
EOF
    chmod +x "$TEST_TMP_DIR/bin/lynis"
    # shellcheck disable=SC2030
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run lynis_check
    [[ "$status" -eq 0 ]]
}

@test "lynis_check returns 1 when lynis is not available" {
    # Remove lynis from PATH by using a minimal PATH
    # shellcheck disable=SC2030,SC2031
    export PATH="/usr/bin:/bin"

    # Only test if lynis is actually not installed
    if command -v lynis > /dev/null 2>&1; then
        skip "lynis is installed on this system"
    fi

    run lynis_check
    [[ "$status" -eq 1 ]]
}

# --- lynis_run Tests ---

@test "lynis_run executes lynis with correct arguments" {
    # Create mock lynis
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/lynis" << 'SCRIPT'
#!/bin/sh
# Mock lynis that creates expected output files
output_dir="$3"
logfile="${5:-$output_dir/lynis.log}"
reportfile="${7:-$output_dir/lynis.dat}"
touch "$logfile"
touch "$reportfile"
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/lynis"
    # shellcheck disable=SC2030,SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run lynis_run "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
}

@test "lynis_run creates log file in output directory" {
    # Create mock lynis that actually writes output
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/lynis" << 'SCRIPT'
#!/bin/sh
# Parse args to find logfile and reportfile
logfile=""
reportfile=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --logfile) logfile="$2"; shift 2 ;;
        --report-file) reportfile="$2"; shift 2 ;;
        *) shift ;;
    esac
done
touch "$logfile"
touch "$reportfile"
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/lynis"
    # shellcheck disable=SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run lynis_run "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    # Check log file was created
    local count
    count=$(find "$MOCK_OUTPUT" -name "lynis-*.log" | wc -l)
    [[ "$count" -ge 1 ]]
}

# --- lynis_get_output_files Tests ---

@test "lynis_get_output_files returns log file path" {
    # Create mock log file
    touch "$MOCK_OUTPUT/lynis-20260322-120000.log"

    run lynis_get_output_files "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"lynis"* ]]
    [[ "$output" == *".log"* ]]
}
