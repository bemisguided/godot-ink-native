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
Usage: $(basename "$0") <version> [build_type]

Clean, configure, and build the extension for a specific Godot version.

Arguments:
  version      Godot version to build for (4.4 or 4.5)
  build_type   Build type (Release or Debug, default: Release)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4
  $(basename "$0") 4.5 Debug
  $(basename "$0") 4.4 Release

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
BUILD_TYPE="${2:-Release}"

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

log_info "Building godot-ink for Godot $GODOT_VERSION ($BUILD_TYPE)"

# Clean build directory
if [ -d "build" ]; then
    log_info "Cleaning build directory..."
    rm -rf build
fi

# Configure
log_info "Configuring CMake..."
cmake -S . -B build -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DGODOT_VERSION="$GODOT_VERSION"

# Build
log_info "Building extension..."
cmake --build build --config "$BUILD_TYPE" -j4

# Report success
log_success "Build complete!"

# Show binary location
if [ -d "build" ]; then
    BINARY=$(find build -name "libgodot_ink*" -type f -o -name "libgodot_ink*.framework" -type d | head -n 1)
    if [ -n "$BINARY" ]; then
        log_info "Binary location: $BINARY"
        if [ -f "$BINARY" ]; then
            SIZE=$(du -h "$BINARY" | cut -f1)
            log_info "Binary size: $SIZE"
        fi
    fi
fi
