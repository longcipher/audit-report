#!/usr/bin/env bash
# lynis.sh — Lynis audit module for audit-report
# Wraps the lynis security auditing tool.

set -euo pipefail

# Function: lynis_check
# Description: Check if lynis is available in PATH
# Returns: 0 if available, 1 if not
lynis_check() {
    command_exists "lynis"
}

# Function: lynis_run
# Description: Run lynis audit and write output to the specified directory
# Args: $1 - output directory path
# Sets: LYNIS_LOGFILE, LYNIS_REPORTFILE with paths to generated files
LYNIS_LOGFILE=""
LYNIS_REPORTFILE=""

lynis_run() {
    local output_dir="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    LYNIS_LOGFILE="${output_dir}/lynis-${timestamp}.log"
    LYNIS_REPORTFILE="${output_dir}/lynis-${timestamp}.dat"

    lynis audit system \
        --no-colors \
        --quick \
        --logfile "$LYNIS_LOGFILE" \
        --report-file "$LYNIS_REPORTFILE" \
        2>&1 || true

    return 0
}

# Function: lynis_get_output_files
# Description: Return paths to generated lynis output files
# Args: $1 - output directory
# Outputs: paths to log and dat files, one per line
lynis_get_output_files() {
    local output_dir="$1"
    local files
    files="$(find "$output_dir" -name "lynis-*.log" -o -name "lynis-*.dat" 2> /dev/null | sort)"
    if [[ -n "$files" ]]; then
        printf "%s\n" "$files"
    fi
    return 0
}
