#!/usr/bin/env bash
set -euo pipefail

# audit-report installer script
# Usage: curl -fsSL https://raw.githubusercontent.com/longcipher/audit-report/master/install.sh | bash

readonly REPO_URL="https://github.com/longcipher/audit-report"
readonly RAW_URL="https://raw.githubusercontent.com/longcipher/audit-report/master"

# Installation paths
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${PREFIX}/bin"
LIB_DIR="${PREFIX}/lib/audit-report"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if [[ "$EUID" -ne 0 ]] && [[ ! -w "$BIN_DIR" ]]; then
        log_warn "Installation directory $BIN_DIR is not writable."
        log_warn "You may need to run with sudo or set PREFIX to a writable directory:"
        log_warn "  curl -fsSL ... | PREFIX=\$HOME/.local bash"
    fi

    if ! command_exists curl && ! command_exists wget; then
        log_error "Neither curl nor wget is installed. Please install one of them."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Download file using curl or wget
download() {
    local url="$1"
    local output="$2"

    if command_exists curl; then
        curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$output"
    else
        wget -q --tries=3 --timeout=30 "$url" -O "$output"
    fi
}

# Install audit-report
install_audit_report() {
    log_info "Installing audit-report..."
    log_info "Installation prefix: $PREFIX"

    # Create directories
    mkdir -p "$BIN_DIR"
    mkdir -p "$LIB_DIR"

    # Download main script
    log_info "Downloading main executable..."
    local temp_bin
    temp_bin=$(mktemp)
    download "$RAW_URL/bin/audit-report" "$temp_bin"
    install -m755 "$temp_bin" "$BIN_DIR/audit-report"
    rm -f "$temp_bin"

    # Download library files
    log_info "Downloading library files..."
    local lib_files=("core.sh" "detect.sh" "lynis.sh" "rkhunter.sh" "chkrootkit.sh" "openscap.sh" "report.sh")

    for lib in "${lib_files[@]}"; do
        local temp_lib
        temp_lib=$(mktemp)
        if download "$RAW_URL/lib/audit_report/$lib" "$temp_lib" 2>/dev/null; then
            install -m644 "$temp_lib" "$LIB_DIR/$lib"
            log_info "  Downloaded: $lib"
        else
            log_warn "  Skipped (optional): $lib"
        fi
        rm -f "$temp_lib"
    done

    # Verify installation
    if [[ -x "$BIN_DIR/audit-report" ]]; then
        log_success "audit-report installed successfully to $BIN_DIR/audit-report"
    else
        log_error "Installation failed: executable not found"
        exit 1
    fi

    # Check if in PATH
    if command_exists audit-report; then
        log_success "audit-report is available in PATH"
        log_info "Run 'audit-report --help' to get started"
    else
        log_warn "audit-report is not in your PATH"
        log_info "Add the following to your shell configuration:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
    fi
}

# Uninstall audit-report
uninstall() {
    log_info "Uninstalling audit-report..."

    if [[ -f "$BIN_DIR/audit-report" ]]; then
        rm -f "$BIN_DIR/audit-report"
        log_success "Removed $BIN_DIR/audit-report"
    fi

    if [[ -d "$LIB_DIR" ]]; then
        rm -rf "$LIB_DIR"
        log_success "Removed $LIB_DIR"
    fi

    log_success "audit-report uninstalled"
}

# Main function
main() {
    # Parse arguments
    local action="install"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                action="uninstall"
                shift
                ;;
            --prefix)
                PREFIX="$2"
                BIN_DIR="${PREFIX}/bin"
                LIB_DIR="${PREFIX}/lib/audit-report"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --prefix PATH    Install to PATH instead of $PREFIX"
                echo "  --uninstall      Uninstall audit-report"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo "=========================================="
    echo "  audit-report Installer"
    echo "=========================================="
    echo ""

    case "$action" in
        install)
            check_prerequisites
            install_audit_report
            ;;
        uninstall)
            uninstall
            ;;
    esac
}

main "$@"
