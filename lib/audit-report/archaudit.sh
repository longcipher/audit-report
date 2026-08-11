#!/usr/bin/env bash
# archaudit.sh — arch-audit scan module for audit-report
# Wraps arch-audit, the Arch Linux CVE checker for installed packages.

set -euo pipefail

# Function: archaudit_check
# Description: Check if arch-audit is available in PATH
# Returns: 0 if available, 1 if not
archaudit_check() {
    command_exists "arch-audit"
}

# Function: archaudit_run
# Description: Run arch-audit scan and capture output to file
# Args: $1 - output directory path
# Sets: ARCHAUDIT_OUTPUT with path to generated output file
ARCHAUDIT_OUTPUT=""

archaudit_run() {
    local output_dir="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    ARCHAUDIT_OUTPUT="${output_dir}/archaudit-${timestamp}.txt"

    arch-audit > "$ARCHAUDIT_OUTPUT" 2>&1 || true

    return 0
}

# Function: archaudit_get_output_file
# Description: Return path to arch-audit output file
# Args: $1 - output directory
# Outputs: path to output file
archaudit_get_output_file() {
    local output_dir="$1"
    local file
    file="$(find "$output_dir" -name "archaudit-*.txt" -print -quit 2> /dev/null || true)"
    if [[ -n "$file" ]]; then
        printf "%s\n" "$file"
    fi
    return 0
}