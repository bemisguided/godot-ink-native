#!/usr/bin/env bash

# Script: target-package-libs.sh
# Description: Package binary-only addon for a specific Godot version
# Usage: ./scripts/target-package-libs.sh <version|all>

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <version|all>

Package binary-only addon for a specific Godot version.
Used by CI for multi-platform bundling.

Arguments:
  version      Godot version (4.4, 4.5, or all)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4     # Package libs-only for 4.4
  $(basename "$0") all     # Package libs-only for all versions

EOF
}

release_libs_version() {
    local version="$1"

    log_info "Building libs-only package for Godot $version..."

    local build_dir="build/${version}"

    # Build the extension
    "$PROJECT_ROOT/scripts/target-build.sh" "$version" Release

    # Create libs-only package
    cmake --build "$build_dir" --target release-libs

    local package=$(find release -name "*godot${version}*libs*" -type f 2>/dev/null | head -n 1)
    if [ -n "$package" ]; then
        echo ""
        echo "Package: $package"
    fi

    log_success "Libs package complete for Godot $version"
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

GODOT_VERSION="$1"

# Validate version
if ! validate_version "$GODOT_VERSION"; then
    show_help
    exit 1
fi

# Release all versions or single version
if [[ "$GODOT_VERSION" == "all" ]]; then
    log_info "Building libs packages for all Godot versions..."
    for version in "${SUPPORTED_VERSIONS[@]}"; do
        release_libs_version "$version"
        echo ""
    done
    log_success "All libs packages complete!"
else
    release_libs_version "$GODOT_VERSION"
fi
