#!/usr/bin/env bats

# Tests for archaudit.sh — arch-audit scan module

setup() {
    load 'test_helper'
    common_setup

    source "$PROJECT_DIR/lib/audit-report/archaudit.sh"

    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- archaudit_check Tests ---

@test "archaudit_check returns 0 when arch-audit is available" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/arch-audit" << 'EOF'
#!/bin/sh
echo "arch-audit mock"
EOF
    chmod +x "$TEST_TMP_DIR/bin/arch-audit"
    # shellcheck disable=SC2030
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run archaudit_check
    [[ "$status" -eq 0 ]]
}

@test "archaudit_check returns 1 when arch-audit is not available" {
    # shellcheck disable=SC2030,SC2031
    export PATH="/usr/bin:/bin"
    if command -v arch-audit > /dev/null 2>&1; then
        skip "arch-audit is installed on this system"
    fi

    run archaudit_check
    [[ "$status" -eq 1 ]]
}

# --- archaudit_run Tests ---

@test "archaudit_run creates output file in output directory" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/arch-audit" << 'SCRIPT'
#!/bin/sh
echo "no vulnerable packages"
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/arch-audit"
    # shellcheck disable=SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run archaudit_run "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    local count
    count=$(find "$MOCK_OUTPUT" -name "archaudit-*.txt" | wc -l)
    [[ "$count" -ge 1 ]]
}

# --- archaudit_get_output_file Tests ---

@test "archaudit_get_output_file returns output path" {
    touch "$MOCK_OUTPUT/archaudit-20260322-120000.txt"

    run archaudit_get_output_file "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"archaudit"* ]]
    [[ "$output" == *".txt"* ]]
}
