#!/usr/bin/env bash
# openscap.sh — OpenSCAP evaluation module for audit-report
# Wraps the oscap tool with SCAP content auto-detection.

set -euo pipefail

# Default SCAP content directories
readonly SCAP_CONTENT_DIRS=(
    "/usr/share/xml/scap/ssg/content"
    "/usr/share/scap-security-guide"
    "/usr/share/xml/scap"
)

# Function: openscap_check
# Description: Check if oscap is available in PATH
# Returns: 0 if available, 1 if not
openscap_check() {
    command_exists "oscap"
}

# Function: openscap_detect_content
# Description: Find the SCAP datastream file for the given OS
# Args: $1 - distro family (debian/rhel/arch), $2 - distro ID, $3 - version,
#       $4 - optional content directory to search
# Outputs: full path to ssg-*-ds.xml or empty string
openscap_detect_content() {
    local family="$1"
    local distro_id="$2"
    local version="$3"
    local search_dir="${4:-}"

    local -a search_dirs
    if [[ -n "$search_dir" ]]; then
        search_dirs=("$search_dir")
    else
        search_dirs=("${SCAP_CONTENT_DIRS[@]}")
    fi

    # Strip dots from version for filename matching (22.04 -> 2204)
    local version_nodots="${version//./}"

    local ds_file=""

    for dir in "${search_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi

        # Try exact match patterns in order of preference
        case "$family" in
            debian)
                # Try ubuntu-specific first, then generic debian
                if [[ -f "$dir/ssg-${distro_id}${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-${distro_id}${version_nodots}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-${distro_id}${version}-ds.xml" ]]; then
                    ds_file="$dir/ssg-${distro_id}${version}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-debian${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-debian${version_nodots}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-ubuntu${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-ubuntu${version_nodots}-ds.xml"
                    break
                fi
                ;;
            rhel)
                # Try centos, rhel, rocky patterns
                if [[ -f "$dir/ssg-${distro_id}${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-${distro_id}${version_nodots}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-${distro_id}${version}-ds.xml" ]]; then
                    ds_file="$dir/ssg-${distro_id}${version}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-rhel${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-rhel${version_nodots}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-rhel${version}-ds.xml" ]]; then
                    ds_file="$dir/ssg-rhel${version}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-centos${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-centos${version_nodots}-ds.xml"
                    break
                elif [[ -f "$dir/ssg-sl${version_nodots}-ds.xml" ]]; then
                    ds_file="$dir/ssg-sl${version_nodots}-ds.xml"
                    break
                fi
                ;;
            arch)
                if [[ -f "$dir/ssg-${distro_id}-ds.xml" ]]; then
                    ds_file="$dir/ssg-${distro_id}-ds.xml"
                    break
                fi
                ;;
            *) ;; # unsupported family, continue searching
        esac
    done

    printf "%s\n" "$ds_file"
    return 0
}

# Function: openscap_detect_profile
# Description: Select the best available profile from a SCAP datastream
# Args: $1 - path to SCAP datastream file
# Outputs: profile ID string
openscap_detect_profile() {
    local datastream="$1"

    if [[ -z "$datastream" ]] || [[ ! -f "$datastream" ]]; then
        printf "\n"
        return 0
    fi

    local profiles
    profiles="$(oscap info "$datastream" 2> /dev/null | grep "Profile" | sed 's/.*Profile: //' || true)"

    # Try CIS profile first, then standard, then first available
    if [[ "$profiles" == *"cis"* ]]; then
        local selected
        selected="$(printf "%s\n" "$profiles" | grep -i "cis" | head -1)" || true
        printf "%s\n" "$selected"
    elif [[ "$profiles" == *"standard"* ]]; then
        local selected
        selected="$(printf "%s\n" "$profiles" | grep -i "standard" | head -1)" || true
        printf "%s\n" "$selected"
    elif [[ -n "$profiles" ]]; then
        local selected
        selected="$(printf "%s\n" "$profiles" | head -1)" || true
        printf "%s\n" "$selected"
    else
        printf "\n"
    fi

    return 0
}

# Function: openscap_run
# Description: Run OpenSCAP evaluation
# Args: $1 - output directory, $2 - datastream file path, $3 - profile ID
# Sets: OSCAP_RESULTS_FILE, OSCAP_REPORT_FILE
OSCAP_RESULTS_FILE=""
OSCAP_REPORT_FILE=""

openscap_run() {
    local output_dir="$1"
    local datastream="$2"
    local profile="$3"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    OSCAP_RESULTS_FILE="${output_dir}/oscap-results-${timestamp}.xml"
    OSCAP_REPORT_FILE="${output_dir}/oscap-report-${timestamp}.html"

    oscap xccdf eval \
        --profile "$profile" \
        --results "$OSCAP_RESULTS_FILE" \
        --report "$OSCAP_REPORT_FILE" \
        "$datastream" \
        2>&1 || true

    return 0
}

# Function: openscap_get_output_files
# Description: Return paths to generated OpenSCAP output files
# Args: $1 - output directory
# Outputs: paths to XML and HTML files
openscap_get_output_files() {
    local output_dir="$1"
    local files
    files="$(find "$output_dir" -name "oscap-results-*.xml" -o -name "oscap-report-*.html" 2> /dev/null | sort)"
    if [[ -n "$files" ]]; then
        printf "%s\n" "$files"
    fi
    return 0
}
