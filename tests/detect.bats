#!/usr/bin/env bats

# Tests for detect.sh — OS detection module

setup() {
    load 'test_helper'
    common_setup

    # Source detect module
    source "$PROJECT_DIR/lib/audit-report/detect.sh"

    # Create a mock /etc/os-release directory
    MOCK_OS_RELEASE="$TEST_TMP_DIR/os-release"
}

teardown() {
    common_teardown
}

# --- detect_os Tests ---

@test "detect_os returns debian for Ubuntu" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Ubuntu"
VERSION="22.04 LTS (Jammy Jellyfish)"
ID=ubuntu
ID_LIKE=debian
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "debian" ]]
}

@test "detect_os returns rhel for Rocky Linux" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Rocky Linux"
VERSION="9.3 (Blue Onyx)"
ID=rocky
ID_LIKE="rhel centos fedora"
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "rhel" ]]
}

@test "detect_os returns rhel for CentOS Stream" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="CentOS Stream"
VERSION="9"
ID=centos
ID_LIKE="rhel fedora"
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "rhel" ]]
}

@test "detect_os returns arch for Arch Linux" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Arch Linux"
ID=arch
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "arch" ]]
}

@test "detect_os returns arch for Manjaro" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Manjaro Linux"
ID=manjaro
ID_LIKE=arch
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "arch" ]]
}

@test "detect_os returns unknown for unknown distribution" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="UnknownOS"
ID=unknownos
EOF
    run detect_os "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "unknown" ]]
}

@test "detect_os handles missing os-release file" {
    run detect_os "/nonexistent/path"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "unknown" ]]
}

# --- detect_package_manager Tests ---

@test "detect_package_manager returns apt for debian" {
    run detect_package_manager "debian"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "apt" ]]
}

@test "detect_package_manager returns dnf for rhel" {
    run detect_package_manager "rhel"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "dnf" ]]
}

@test "detect_package_manager returns pacman for arch" {
    run detect_package_manager "arch"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "pacman" ]]
}

@test "detect_package_manager returns unknown for unknown family" {
    run detect_package_manager "unknown"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "unknown" ]]
}

# --- detect_os_version Tests ---

@test "detect_os_version extracts VERSION_ID" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Ubuntu"
VERSION="22.04 LTS"
ID=ubuntu
VERSION_ID="22.04"
EOF
    run detect_os_version "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "22.04" ]]
}

@test "detect_os_version returns empty for missing VERSION_ID" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Arch Linux"
ID=arch
EOF
    run detect_os_version "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "" ]]
}

# --- detect_os_id Tests ---

@test "detect_os_id extracts ID field" {
    cat > "$MOCK_OS_RELEASE" << 'EOF'
NAME="Rocky Linux"
ID=rocky
VERSION_ID="9.3"
EOF
    run detect_os_id "$MOCK_OS_RELEASE"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "rocky" ]]
}
