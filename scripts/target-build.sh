#!/usr/bin/env bash

# Script: target-build.sh
# Description: Clean, configure, and build for a specific Godot version
# Usage: ./scripts/target-build.sh <version|all> [build_type] [--clean]

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <version|all> [build_type] [--clean]

Configure and build the extension for a specific Godot version.
Uses version-specific build directories (build/4.4/, build/4.5/) for fast incremental builds.

Arguments:
  version      Godot version to build for (4.4, 4.5, or all)
  build_type   Build type (Release or Debug, default: Release)

Options:
  --clean      Clean build directory before building (full rebuild)
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4                    # Incremental build for 4.4
  $(basename "$0") 4.5 Debug              # Incremental debug build for 4.5
  $(basename "$0") 4.4 --clean            # Clean build for 4.4
  $(basename "$0") 4.5 Debug --clean      # Clean debug build for 4.5
  $(basename "$0") all                    # Build all versions
  $(basename "$0") all --clean            # Clean build for all versions

Notes:
  - Incremental builds are fast (~2-4 seconds if no changes)
  - Version-specific directories prevent 4.4/4.5 interference
  - Use --clean after updating dependencies (git submodule update)

EOF
}

# Build a single version
build_version() {
    local version="$1"
    local build_type="$2"
    local clean_build="$3"

    log_info "Building Godot $version ($build_type)..."

    # Use version-specific build directory
    local build_dir="build/${version}"

    # Clean build directory if requested
    if [ "$clean_build" = true ] && [ -d "$build_dir" ]; then
        log_info "Cleaning $build_dir..."
        rm -rf "$build_dir"
    fi

    # Configure and build
    cmake -S . -B "$build_dir" -DCMAKE_BUILD_TYPE="$build_type" -DGODOT_VERSION="$version"
    cmake --build "$build_dir" --config "$build_type" -j4

    log_success "Build complete for Godot $version"
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

# Parse arguments
GODOT_VERSION="$1"
BUILD_TYPE="Release"
CLEAN_BUILD=false

# Validate version
if ! validate_version "$GODOT_VERSION"; then
    show_help
    exit 1
fi

# Parse remaining arguments
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        Release|Debug)
            BUILD_TYPE="$1"
            shift
            ;;
        *)
            log_error "Unknown argument: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(Release|Debug)$ ]]; then
    log_error "Invalid build type: $BUILD_TYPE"
    log_error "Supported types: Release, Debug"
    exit 1
fi

# Build all versions or single version
if [[ "$GODOT_VERSION" == "all" ]]; then
    log_info "Building all Godot versions..."
    for version in "${SUPPORTED_VERSIONS[@]}"; do
        build_version "$version" "$BUILD_TYPE" "$CLEAN_BUILD"
    done
    log_success "All builds complete!"
else
    build_version "$GODOT_VERSION" "$BUILD_TYPE" "$CLEAN_BUILD"
fi
