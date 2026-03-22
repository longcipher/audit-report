#!/usr/bin/env bash
#
# Basher package manifest for audit-report
# See: https://github.com/basherpm/basher
#
# This file defines metadata for the basher package manager.
# Basher will read this file when installing the package.
#

# Package name
# This is the command that will be available after installation
name="audit-report"

# Package version
# This should match your git tags
version="0.1.0"

# Package description
# A short, one-line description
description="Linux security auditing tool with auto-detection and multiple scanners"

# Homepage
# URL to the project homepage or repository
homepage="https://github.com/longcipher/audit-report"

# Author
# Package maintainer
author="longcipher"

# License
# SPDX license identifier
license="Apache-2.0"

# Bin files
# These are the executables that will be linked to ~/.basher/bin
# Format: source_path:target_name (target_name is optional, defaults to basename of source_path)
bins=(
    "bin/audit-report"
)

# Dependencies (optional)
# List other basher packages this package depends on
# Format: username/package
# dependencies=(
#     "username/other-package"
# )

# Runtime dependencies (optional)
# List system commands required by this package
# These are checked during installation
runtime_dependencies=(
    "bash"
    "curl"
)

# Post-install hook (optional)
# This function is called after installation is complete
# post_install() {
#     echo "audit-report has been installed!"
#     echo "Run 'audit-report --help' to get started."
# }

# Post-upgrade hook (optional)
# This function is called after upgrade is complete
# post_upgrade() {
#     echo "audit-report has been upgraded to the latest version!"
# }
