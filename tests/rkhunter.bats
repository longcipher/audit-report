#!/usr/bin/env bats

# Tests for rkhunter.sh — rkhunter scan module

setup() {
    load 'test_helper'
    common_setup

    source "$PROJECT_DIR/lib/audit_report/rkhunter.sh"

    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- rkhunter_check Tests ---

@test "rkhunter_check returns 0 when rkhunter is available" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/rkhunter" << 'EOF'
#!/bin/sh
echo "rkhunter mock"
EOF
    chmod +x "$TEST_TMP_DIR/bin/rkhunter"
    # shellcheck disable=SC2030
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run rkhunter_check
    [[ "$status" -eq 0 ]]
}

@test "rkhunter_check returns 1 when rkhunter is not available" {
    # shellcheck disable=SC2030,SC2031
    export PATH="/usr/bin:/bin"
    if command -v rkhunter > /dev/null 2>&1; then
        skip "rkhunter is installed on this system"
    fi

    run rkhunter_check
    [[ "$status" -eq 1 ]]
}

# --- rkhunter_run Tests ---

@test "rkhunter_run creates log file in output directory" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/rkhunter" << 'SCRIPT'
#!/bin/sh
logfile=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --logfile) logfile="$2"; shift 2 ;;
        *) shift ;;
    esac
done
touch "$logfile"
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/rkhunter"
    # shellcheck disable=SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run rkhunter_run "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    local count
    count=$(find "$MOCK_OUTPUT" -name "rkhunter-*.log" | wc -l)
    [[ "$count" -ge 1 ]]
}

# --- rkhunter_get_output_file Tests ---

@test "rkhunter_get_output_file returns log path" {
    touch "$MOCK_OUTPUT/rkhunter-20260322-120000.log"

    run rkhunter_get_output_file "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"rkhunter"* ]]
    [[ "$output" == *".log"* ]]
}
