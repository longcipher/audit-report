#!/usr/bin/env bats

# Tests for openscap.sh — OpenSCAP evaluation module

setup() {
    load 'test_helper'
    common_setup

    source "$PROJECT_DIR/lib/audit-report/openscap.sh"

    MOCK_OUTPUT="$TEST_TMP_DIR/output"
    mkdir -p "$MOCK_OUTPUT"
}

teardown() {
    common_teardown
}

# --- openscap_check Tests ---

@test "openscap_check returns 0 when oscap is available" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/oscap" << 'EOF'
#!/bin/sh
echo "oscap mock"
EOF
    chmod +x "$TEST_TMP_DIR/bin/oscap"
    # shellcheck disable=SC2030
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    run openscap_check
    [[ "$status" -eq 0 ]]
}

@test "openscap_check returns 1 when oscap is not available" {
    # shellcheck disable=SC2030,SC2031
    export PATH="/usr/bin:/bin"
    if command -v oscap > /dev/null 2>&1; then
        skip "oscap is installed on this system"
    fi

    run openscap_check
    [[ "$status" -eq 1 ]]
}

# --- openscap_detect_content Tests ---

@test "openscap_detect_content finds datastream file" {
    # Create mock SCAP content directory
    local mock_content="$TEST_TMP_DIR/scap"
    mkdir -p "$mock_content"
    touch "$mock_content/ssg-ubuntu2204-ds.xml"

    run openscap_detect_content "debian" "ubuntu" "22.04" "$mock_content"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"ssg-ubuntu2204-ds.xml"* ]]
}

@test "openscap_detect_content returns empty for missing content" {
    local empty_dir="$TEST_TMP_DIR/empty"
    mkdir -p "$empty_dir"

    run openscap_detect_content "debian" "ubuntu" "22.04" "$empty_dir"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test "openscap_detect_content finds rhel datastream" {
    local mock_content="$TEST_TMP_DIR/scap"
    mkdir -p "$mock_content"
    touch "$mock_content/ssg-rhel9-ds.xml"

    run openscap_detect_content "rhel" "rocky" "9" "$mock_content"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"ssg-rhel9-ds.xml"* ]]
}

@test "openscap_detect_content finds centos datastream" {
    local mock_content="$TEST_TMP_DIR/scap"
    mkdir -p "$mock_content"
    touch "$mock_content/ssg-centos8-ds.xml"

    run openscap_detect_content "rhel" "centos" "8" "$mock_content"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"ssg-centos8-ds.xml"* ]]
}

# --- openscap_run Tests ---

@test "openscap_run creates XML and HTML output files" {
    mkdir -p "$TEST_TMP_DIR/bin"
    cat > "$TEST_TMP_DIR/bin/oscap" << 'SCRIPT'
#!/bin/sh
# Parse --results and --report args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --results) touch "$2"; shift 2 ;;
        --report) touch "$2"; shift 2 ;;
        *) shift ;;
    esac
done
exit 0
SCRIPT
    chmod +x "$TEST_TMP_DIR/bin/oscap"
    # shellcheck disable=SC2031
    export PATH="$TEST_TMP_DIR/bin:$PATH"

    # Create mock SCAP content
    local mock_content="$TEST_TMP_DIR/scap"
    mkdir -p "$mock_content"
    touch "$mock_content/ssg-ubuntu2204-ds.xml"

    run openscap_run "$MOCK_OUTPUT" "$mock_content/ssg-ubuntu2204-ds.xml" "xccdf_org.ssgproject.content_profile_cis"
    [[ "$status" -eq 0 ]]
    local xml_count html_count
    xml_count=$(find "$MOCK_OUTPUT" -name "oscap-results-*.xml" | wc -l)
    html_count=$(find "$MOCK_OUTPUT" -name "oscap-report-*.html" | wc -l)
    [[ "$xml_count" -ge 1 ]]
    [[ "$html_count" -ge 1 ]]
}

# --- openscap_get_output_files Tests ---

@test "openscap_get_output_files returns xml and html paths" {
    touch "$MOCK_OUTPUT/oscap-results-20260322-120000.xml"
    touch "$MOCK_OUTPUT/oscap-report-20260322-120000.html"

    run openscap_get_output_files "$MOCK_OUTPUT"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"oscap-results"* ]]
    [[ "$output" == *"oscap-report"* ]]
}
