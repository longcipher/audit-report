#!/usr/bin/env bats

# Tests for report.sh — Summary report generation module

setup() {
    load 'test_helper'
    common_setup

    source "$PROJECT_DIR/lib/audit-report/report.sh"

    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- report_generate_summary Tests ---

@test "report_generate_summary creates summary file" {
    run report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    [[ "$status" -eq 0 ]]
    local count
    count=$(find "$MOCK_OUTPUT" -name "summary-*.txt" | wc -l)
    [[ "$count" -ge 1 ]]
}

@test "summary contains scan timestamp" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "20260322-143000" "$summary"
}

@test "summary contains OS information" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "debian" "$summary"
    grep -q "ubuntu" "$summary"
    grep -q "22.04" "$summary"
}

@test "summary contains module results section" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "Module Results" "$summary"
}

@test "summary contains all module names" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "lynis" "$summary"
    grep -q "rkhunter" "$summary"
    grep -q "chkrootkit" "$summary"
    grep -q "openscap" "$summary"
}

@test "summary shows completed message" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "rhel" "rocky" "9"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "completed" "$summary"
}

@test "summary shows skipped when no module output exists" {
    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "arch" "arch" ""
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "skipped" "$summary"
}

@test "summary includes mock module output files" {
    # Create mock module outputs
    touch "$MOCK_OUTPUT/lynis-20260322-143000.log"
    touch "$MOCK_OUTPUT/rkhunter-20260322-143000.log"

    report_generate_summary "$MOCK_OUTPUT" "20260322-143000" "debian" "ubuntu" "22.04"
    local summary
    summary="$(find "$MOCK_OUTPUT" -name "summary-*.txt" -print -quit)"
    grep -q "lynis-20260322-143000.log" "$summary"
    grep -q "rkhunter-20260322-143000.log" "$summary"
}
