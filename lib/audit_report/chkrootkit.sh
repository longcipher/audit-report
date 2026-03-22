#!/usr/bin/env bash
# chkrootkit.sh — chkrootkit scan module for audit-report
# Wraps the chkrootkit rootkit detection tool.

set -euo pipefail

# Function: chkrootkit_check
# Description: Check if chkrootkit is available in PATH
# Returns: 0 if available, 1 if not
chkrootkit_check() {
    command_exists "chkrootkit"
}

# Function: chkrootkit_run
# Description: Run chkrootkit scan and capture output to file
# Args: $1 - output directory path
# Sets: CHKROOTKIT_OUTPUT with path to generated output file
CHKROOTKIT_OUTPUT=""

chkrootkit_run() {
    local output_dir="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    CHKROOTKIT_OUTPUT="${output_dir}/chkrootkit-${timestamp}.txt"

    chkrootkit > "$CHKROOTKIT_OUTPUT" 2>&1 || true

    return 0
}

# Function: chkrootkit_get_output_file
# Description: Return path to chkrootkit output file
# Args: $1 - output directory
# Outputs: path to output file
chkrootkit_get_output_file() {
    local output_dir="$1"
    local file
    file="$(find "$output_dir" -name "chkrootkit-*.txt" -print -quit 2> /dev/null || true)"
    if [[ -n "$file" ]]; then
        printf "%s\n" "$file"
    fi
    return 0
}
