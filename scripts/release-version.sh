#!/usr/bin/env bash

# Script: release-version.sh
# Description: Build and create release package for a specific Godot version
# Usage: ./scripts/release-version.sh <version>

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
Usage: $(basename "$0") <version>

Build and create release package for a specific Godot version.

Arguments:
  version      Godot version to release for (4.4 or 4.5)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4
  $(basename "$0") 4.5

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

GODOT_VERSION="$1"

# Validate Godot version
if [[ ! "$GODOT_VERSION" =~ ^(4\.4|4\.5)$ ]]; then
    log_error "Invalid Godot version: $GODOT_VERSION"
    log_error "Supported versions: 4.4, 4.5"
    exit 1
fi

log_info "Creating release package for Godot $GODOT_VERSION"

# Build the extension (always use Release build for releases)
log_info "Building extension (Release)..."
"$PROJECT_ROOT/scripts/build-version.sh" "$GODOT_VERSION" Release

# Create release package
log_info "Creating release package..."
cmake --build build --target release

# Report success
log_success "Release package created!"

# Show package location
if [ -d "release" ]; then
    PACKAGE=$(find release -name "*godot${GODOT_VERSION}*" -type f | head -n 1)
    if [ -n "$PACKAGE" ]; then
        log_info "Package location: $PACKAGE"
        SIZE=$(du -h "$PACKAGE" | cut -f1)
        log_info "Package size: $SIZE"

        # Show package contents
        log_info "Package contents:"
        unzip -l "$PACKAGE" | tail -n +4 | head -n -2
    fi
fi
