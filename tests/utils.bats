#!/usr/bin/env bats

# Tests for utils.sh functions

setup() {
    load 'test_helper'
    common_setup
}

teardown() {
    common_teardown
}

@test "log_info outputs correct format" {
    run log_info "test message"
    [ "$status" -eq 0 ]
    [ "$output" = "[INFO] test message" ]
}

@test "log_error outputs correct format" {
    run log_error "error message"
    [ "$status" -eq 0 ]
    [ "$output" = "[ERROR] error message" ]
}

@test "log_warn outputs correct format" {
    run log_warn "warning message"
    [ "$status" -eq 0 ]
    [ "$output" = "[WARN] warning message" ]
}

@test "check_command with existing command" {
    run check_command "bash"
    [ "$status" -eq 0 ]
}

@test "check_command with non-existent command" {
    run check_command "nonexistent_command_12345"
    [ "$status" -eq 1 ]
}

@test "require_command with existing command" {
    run require_command "bash"
    [ "$status" -eq 0 ]
}

@test "random_string generates correct length" {
    run random_string 10
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 10 ]
}

@test "random_string default length" {
    run random_string
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 8 ]
}

@test "timestamp returns ISO format" {
    run timestamp
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}
