#!/usr/bin/env bash
# detect.sh — OS distribution detection module for audit-report
# Pure functions for detecting OS family, package manager, and SCAP content.

set -euo pipefail

# Function: detect_os
# Description: Detect OS family from os-release file
# Args: $1 - path to os-release file (default: /etc/os-release)
# Returns: debian, rhel, arch, or unknown
# Outputs: detected family to stdout
detect_os() {
    local os_release="${1:-/etc/os-release}"

    if [[ ! -f "$os_release" ]]; then
        printf "unknown\n"
        return 0
    fi

    local id=""
    local id_like=""

    while IFS='=' read -r key value; do
        # Remove quotes from value
        value="${value#\"}"
        value="${value%\"}"
        case "$key" in
            ID) id="$value" ;;
            ID_LIKE) id_like="$value" ;;
            *) ;; # ignore other keys
        esac
    done < "$os_release"

    # Determine family based on ID and ID_LIKE
    case "$id" in
        ubuntu | debian | linuxmint | pop)
            printf "debian\n"
            return 0
            ;;
        centos | rhel | rocky | alma | fedora | ol | amzn)
            printf "rhel\n"
            return 0
            ;;
        arch | manjaro | endeavouros | garuda)
            printf "arch\n"
            return 0
            ;;
        *) ;; # unknown ID, continue to ID_LIKE fallback
    esac

    # Check ID_LIKE for fallback
    if [[ -n "$id_like" ]]; then
        if [[ "$id_like" == *"debian"* ]]; then
            printf "debian\n"
            return 0
        elif [[ "$id_like" == *"rhel"* ]] || [[ "$id_like" == *"centos"* ]] || [[ "$id_like" == *"fedora"* ]]; then
            printf "rhel\n"
            return 0
        elif [[ "$id_like" == *"arch"* ]]; then
            printf "arch\n"
            return 0
        fi
    fi

    printf "unknown\n"
    return 0
}

# Function: detect_package_manager
# Description: Map OS family to package manager
# Args: $1 - OS family (debian, rhel, arch, unknown)
# Returns: apt, dnf, yum, pacman, or unknown
detect_package_manager() {
    local family="$1"

    case "$family" in
        debian)
            printf "apt\n"
            ;;
        rhel)
            if command_exists dnf; then
                printf "dnf\n"
            elif command_exists yum; then
                printf "yum\n"
            else
                printf "dnf\n"
            fi
            ;;
        arch)
            printf "pacman\n"
            ;;
        *)
            printf "unknown\n"
            ;;
    esac

    return 0
}

# Function: detect_os_version
# Description: Extract VERSION_ID from os-release file
# Args: $1 - path to os-release file (default: /etc/os-release)
# Returns: version string or empty
detect_os_version() {
    local os_release="${1:-/etc/os-release}"

    if [[ ! -f "$os_release" ]]; then
        printf "\n"
        return 0
    fi

    local version_id=""

    while IFS='=' read -r key value; do
        value="${value#\"}"
        value="${value%\"}"
        if [[ "$key" == "VERSION_ID" ]]; then
            version_id="$value"
            break
        fi
    done < "$os_release"

    printf "%s\n" "$version_id"
    return 0
}

# Function: detect_os_id
# Description: Extract ID field from os-release file
# Args: $1 - path to os-release file (default: /etc/os-release)
# Returns: distribution ID string
detect_os_id() {
    local os_release="${1:-/etc/os-release}"

    if [[ ! -f "$os_release" ]]; then
        printf "unknown\n"
        return 0
    fi

    local distro_id=""

    while IFS='=' read -r key value; do
        value="${value#\"}"
        value="${value%\"}"
        if [[ "$key" == "ID" ]]; then
            distro_id="$value"
            break
        fi
    done < "$os_release"

    printf "%s\n" "$distro_id"
    return 0
}
