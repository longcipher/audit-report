#!/usr/bin/env bash
# rkhunter.sh — rkhunter scan module for audit-report
# Wraps the rkhunter rootkit detection tool.

set -euo pipefail

# Function: rkhunter_check
# Description: Check if rkhunter is available in PATH
# Returns: 0 if available, 1 if not
rkhunter_check() {
    command_exists "rkhunter"
}

# Function: rkhunter_run
# Description: Run rkhunter scan and write output to the specified directory
# Args: $1 - output directory path
# Sets: RKHUNTER_LOGFILE with path to generated log file
RKHUNTER_LOGFILE=""

rkhunter_run() {
    local output_dir="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    RKHUNTER_LOGFILE="${output_dir}/rkhunter-${timestamp}.log"

    rkhunter --check --skip-keypress --nocolors \
        --logfile "$RKHUNTER_LOGFILE" \
        2>&1 || true

    return 0
}

# Function: rkhunter_get_output_file
# Description: Return path to rkhunter output file
# Args: $1 - output directory
# Outputs: path to log file
rkhunter_get_output_file() {
    local output_dir="$1"
    local file
    file="$(find "$output_dir" -name "rkhunter-*.log" -print -quit 2> /dev/null || true)"
    if [[ -n "$file" ]]; then
        printf "%s\n" "$file"
    fi
    return 0
}
