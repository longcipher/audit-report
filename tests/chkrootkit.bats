#!/usr/bin/env bats

# Tests for chkrootkit.sh — chkrootkit scan module

setup() {
    load 'test_helper'
    common_setup

    source "$PROJECT_DIR/lib/audit-report/chkrootkit.sh"

    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- chkrootkit_check Tests ---

@test "chkrootkit_check returns 0 when chkrootkit is available" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/chkrootkit" << 'EOF'
#!/bin/sh
echo "chkrootkit mock"
EOF
    chmod +x "$TEST_TMP_DIR/bin/chkrootkit"
    # shellcheck disable=SC2030
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run chkrootkit_check
    [[ "$status" -eq 0 ]]
}

@test "chkrootkit_check returns 1 when chkrootkit is not available" {
    # shellcheck disable=SC2030,SC2031
    export PATH="/usr/bin:/bin"
    if command -v chkrootkit > /dev/null 2>&1; then
        skip "chkrootkit is installed on this system"
    fi

    run chkrootkit_check
    [[ "$status" -eq 1 ]]
}

# --- chkrootkit_run Tests ---

@test "chkrootkit_run creates output file" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/chkrootkit" << 'SCRIPT'
#!/bin/sh
echo "CHKROOTKIT OUTPUT"
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/chkrootkit"
    # shellcheck disable=SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run chkrootkit_run "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    local count
    count=$(find "$MOCK_OUTPUT" -name "chkrootkit-*.txt" | wc -l)
    [[ "$count" -ge 1 ]]
}

# --- chkrootkit_get_output_file Tests ---

@test "chkrootkit_get_output_file returns output path" {
    touch "$MOCK_OUTPUT/chkrootkit-20260322-120000.txt"

    run chkrootkit_get_output_file "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"chkrootkit"* ]]
    [[ "$output" == *".txt"* ]]
}
