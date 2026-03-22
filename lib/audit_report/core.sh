#!/usr/bin/env bash
# core.sh — Common utilities, logging, and error handling for audit-report
# All other modules depend on this library.

set -euo pipefail

# Version
readonly AUDIT_REPORT_VERSION="0.1.0"

# Error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_INVALID_ARGS=2
readonly E_NOT_ROOT=3
readonly E_OUTPUT_NOT_WRITABLE=4
readonly E_TOOL_MISSING=5

# VERBOSE flag (set by CLI)
VERBOSE="${VERBOSE:-0}"

# Function: log_info
# Description: Print info message to stdout
# Args: $1 - message
log_info() {
    local msg="$1"
    printf "[INFO] %s\n" "$msg"
}

# Function: log_warn
# Description: Print warning message to stderr
# Args: $1 - message
log_warn() {
    local msg="$1"
    printf "[WARN] %s\n" "$msg" >&2
}

# Function: log_error
# Description: Print error message to stderr
# Args: $1 - message
log_error() {
    local msg="$1"
    printf "[ERROR] %s\n" "$msg" >&2
}

# Function: die
# Description: Print error message and exit with given code
# Args: $1 - error message, $2 - exit code (default: E_GENERAL)
die() {
    local msg="$1"
    local code="${2:-$E_GENERAL}"
    log_error "$msg"
    exit "$code"
}

# Function: command_exists
# Description: Check if a command is available in PATH
# Args: $1 - command name
# Returns: 0 if found, 1 if not
command_exists() {
    local cmd="$1"
    command -v "$cmd" > /dev/null 2>&1
}
