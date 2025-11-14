#!/usr/bin/env bash

# Script: build-version.sh
# Description: Clean, configure, and build for a specific Godot version
# Usage: ./scripts/build-version.sh <version> [build_type]

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

show_help() {
    cat << EOF
Usage: $(basename "$0") <version> [build_type] [--clean]

Configure and build the extension for a specific Godot version.
Uses version-specific build directories (build-4.4/, build-4.5/) for fast incremental builds.

Arguments:
  version      Godot version to build for (4.4 or 4.5)
  build_type   Build type (Release or Debug, default: Release)

Options:
  --clean      Clean build directory before building (full rebuild)
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4                    # Incremental build for 4.4
  $(basename "$0") 4.5 Debug              # Incremental debug build for 4.5
  $(basename "$0") 4.4 --clean            # Clean build for 4.4
  $(basename "$0") 4.5 Debug --clean      # Clean debug build for 4.5

Notes:
  - Incremental builds are fast (~2-4 seconds if no changes)
  - Version-specific directories prevent 4.4/4.5 interference
  - Use --clean after updating dependencies (git submodule update)

EOF
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root (assuming script is in scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Parse arguments
GODOT_VERSION="$1"
BUILD_TYPE="Release"
CLEAN_BUILD=false

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

# Validate Godot version
if [[ ! "$GODOT_VERSION" =~ ^(4\.4|4\.5)$ ]]; then
    log_error "Invalid Godot version: $GODOT_VERSION"
    log_error "Supported versions: 4.4, 4.5"
    exit 1
fi

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(Release|Debug)$ ]]; then
    log_error "Invalid build type: $BUILD_TYPE"
    log_error "Supported types: Release, Debug"
    exit 1
fi

# Use version-specific build directory
BUILD_DIR="build/${GODOT_VERSION}"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ] && [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Configure and build
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DGODOT_VERSION="$GODOT_VERSION"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j4
