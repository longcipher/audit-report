#!/usr/bin/env bats

# Tests for core.sh functions

setup() {
    load 'test_helper'
    common_setup
}

teardown() {
    common_teardown
}

@test "hello with default name" {
    run hello
    [ "$status" -eq 0 ]
    [ "$output" = "Hello, World!" ]
}

@test "hello with custom name" {
    run hello "Alice"
    [ "$status" -eq 0 ]
    [ "$output" = "Hello, Alice!" ]
}

@test "hello with empty name" {
    run hello ""
    [ "$status" -eq 0 ]
    [ "$output" = "Hello, !" ]
}

@test "process_file with existing file" {
    run process_file "$TEST_TMP_DIR/test.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Processing file:"* ]]
    [[ "$output" == *"File has 3 lines"* ]]
}

@test "process_file with non-existent file" {
    run process_file "$TEST_TMP_DIR/nonexistent.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: File not found"* ]]
}

@test "process_file with empty file" {
    run process_file "$TEST_TMP_DIR/empty.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"File has 0 lines"* ]]
}

@test "validate_input with valid input" {
    run validate_input "hello"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Input is valid"* ]]
}

@test "validate_input with empty input" {
    run validate_input ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Input cannot be empty"* ]]
}

@test "validate_input with short input" {
    run validate_input "ab"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Input must be at least 3 characters"* ]]
}

@test "validate_input with minimum length input" {
    run validate_input "abc"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Input is valid"* ]]
}
