#!/usr/bin/env bash

# Script: target-package.sh
# Description: Package complete single-platform addon for a specific Godot version
# Usage: ./scripts/target-package.sh <version|all>

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <version|all>

Package complete single-platform addon for a specific Godot version.

Arguments:
  version      Godot version to package for (4.4, 4.5, or all)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4     # Package 4.4
  $(basename "$0") 4.5     # Package 4.5
  $(basename "$0") all     # Package all versions

EOF
}

# Release a single version
release_version() {
    local version="$1"

    log_info "Building release package for Godot $version..."

    # Use version-specific build directory
    local build_dir="build/${version}"

    # Build the extension (always use Release build for releases)
    "$PROJECT_ROOT/scripts/target-build.sh" "$version" Release

    # Create release package
    cmake --build "$build_dir" --target release

    # Show package location
    local package=$(find release -name "*godot${version}*" -type f 2>/dev/null | head -n 1)
    if [ -n "$package" ]; then
        echo ""
        echo "Package: $package"
    fi

    log_success "Release complete for Godot $version"
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
    log_info "Building release packages for all Godot versions..."
    for version in "${SUPPORTED_VERSIONS[@]}"; do
        release_version "$version"
        echo ""
    done
    log_success "All releases complete!"
else
    release_version "$GODOT_VERSION"
fi
