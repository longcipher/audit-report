#!/usr/bin/env bash
# report.sh — Summary report generation module for audit-report
# Generates summary.txt with scan results and module statuses.

set -euo pipefail

# Function: report_generate_summary
# Description: Generate a summary report of the audit run
# Args: $1 - output directory, $2 - timestamp, $3 - distro family,
#       $4 - distro ID, $5 - distro version
report_generate_summary() {
    local output_dir="$1"
    local timestamp="$2"
    local distro_family="$3"
    local distro_id="$4"
    local distro_version="$5"

    local summary_file="${output_dir}/summary-${timestamp}.txt"
    local hostname_val
    hostname_val="$(hostname)"

    {
        printf "==============================================\n"
        printf "  audit-report Security Audit Summary\n"
        printf "==============================================\n\n"

        printf "Scan Information:\n"
        printf "  Timestamp: %s\n" "$timestamp"
        printf "  Hostname:  %s\n\n" "$hostname_val"

        printf "System Information:\n"
        printf "  OS Family:  %s\n" "$distro_family"
        printf "  OS ID:      %s\n" "$distro_id"
        printf "  OS Version: %s\n\n" "$distro_version"

        printf "Module Results:\n"
        printf "  %-15s %-10s %s\n" "Module" "Status" "Output"
        printf "  %-15s %-10s %s\n" "------" "------" "------"

        # Read module status from detect.txt and output files
        local modules=(lynis rkhunter chkrootkit openscap)
        for module in "${modules[@]}"; do
            local status
            status="not-checked"
            local output_files=""

            # Check if output files exist for this module
            case "$module" in
                lynis)
                    output_files="$(find "$output_dir" -name "lynis-*.log" -o -name "lynis-*.dat" 2> /dev/null | tr '\n' ', ')"
                    ;;
                rkhunter)
                    output_files="$(find "$output_dir" -name "rkhunter-*.log" 2> /dev/null | tr '\n' ', ')"
                    ;;
                chkrootkit)
                    output_files="$(find "$output_dir" -name "chkrootkit-*.txt" 2> /dev/null | tr '\n' ', ')"
                    ;;
                openscap)
                    output_files="$(find "$output_dir" -name "oscap-*" 2> /dev/null | tr '\n' ', ')"
                    ;;
                *) ;; # unknown module, no output files
            esac

            # Determine status
            if [[ -n "$output_files" ]]; then
                status="ran"
            else
                status="skipped"
            fi

            # Trim trailing comma
            output_files="${output_files%, }"
            printf "  %-15s %-10s %s\n" "$module" "$status" "$output_files"
        done

        printf "\nGenerated Files:\n"
        find "$output_dir" -type f | sort | while IFS= read -r file; do
            printf "  %s\n" "$file"
        done

        printf "\n==============================================\n"
        printf "  Scan completed successfully\n"
        printf "==============================================\n"
    } > "$summary_file"

    return 0
}
