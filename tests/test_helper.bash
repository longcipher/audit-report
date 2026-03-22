#!/usr/bin/env bash

# Test helper functions for bats tests

# Setup function for all tests
common_setup() {
    # Get the directory of this test file
    TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"

    # Source library files
    source "$PROJECT_DIR/lib/bash_app/core.sh"
    source "$PROJECT_DIR/lib/bash_app/utils.sh"

    # Create temporary directory for tests
    TEST_TMP_DIR="$(mktemp -d)"

    # Set up test fixtures
    setup_fixtures
}

# Setup test fixtures
setup_fixtures() {
    # Create test files
    echo "line 1" > "$TEST_TMP_DIR/test.txt"
    echo "line 2" >> "$TEST_TMP_DIR/test.txt"
    echo "line 3" >> "$TEST_TMP_DIR/test.txt"

    # Create empty file
    touch "$TEST_TMP_DIR/empty.txt"
}

# Teardown function for all tests
common_teardown() {
    # Clean up temporary directory
    if [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

# Assert that output equals expected value
assert_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-}"

    if [[ "$actual" != "$expected" ]]; then
        if [[ -n "$message" ]]; then
            echo "FAIL: $message" >&2
        fi
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        return 1
    fi
}

# Assert that output contains substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" != *"$needle"* ]]; then
        if [[ -n "$message" ]]; then
            echo "FAIL: $message" >&2
        fi
        echo "Expected to contain: $needle" >&2
        echo "Actual:              $haystack" >&2
        return 1
    fi
}

# Assert that command succeeds
assert_success() {
    local status="$1"
    local message="${2:-Command failed}"

    if [[ "$status" -ne 0 ]]; then
        echo "FAIL: $message" >&2
        echo "Expected status: 0" >&2
        echo "Actual status:   $status" >&2
        return 1
    fi
}

# Assert that command fails
assert_failure() {
    local status="$1"
    local message="${2:-Command succeeded unexpectedly}"

    if [[ "$status" -eq 0 ]]; then
        echo "FAIL: $message" >&2
        echo "Expected status: non-zero" >&2
        echo "Actual status:   $status" >&2
        return 1
    fi
}
