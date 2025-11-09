#!/usr/bin/env bash

# Script: setup-demo.sh
# Description: Extract latest release package into demo/addons/gd-ink-native
# Usage: ./scripts/setup-demo.sh [godot_version]

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
Usage: $(basename "$0") [godot_version]

Extract the latest release package into demo/addons/gd-ink-native for testing.

Arguments:
  godot_version  Godot version to extract (4.4 or 4.5, default: auto-detect)

Options:
  -h, --help     Show this help message

Examples:
  $(basename "$0")           # Extract latest available release
  $(basename "$0") 4.4       # Extract Godot 4.4 release
  $(basename "$0") 4.5       # Extract Godot 4.5 release

EOF
}

# Parse arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root (assuming script is in scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GODOT_VERSION="${1:-}"

# Check if release directory exists
if [ ! -d "release" ]; then
    log_error "Release directory not found: release/"
    log_error "Build a release first with: scripts/release-version.sh"
    exit 1
fi

# Find release package
if [ -n "$GODOT_VERSION" ]; then
    # User specified version
    if [[ ! "$GODOT_VERSION" =~ ^(4\.4|4\.5)$ ]]; then
        log_error "Invalid Godot version: $GODOT_VERSION"
        log_error "Supported versions: 4.4, 4.5"
        exit 1
    fi

    PACKAGE=$(find release -name "*godot${GODOT_VERSION}*" -type f | head -n 1)

    if [ -z "$PACKAGE" ]; then
        log_error "No release package found for Godot $GODOT_VERSION"
        log_error "Build one first with: scripts/release-version.sh $GODOT_VERSION"
        exit 1
    fi
else
    # Auto-detect: find any release package (prefer 4.5, then 4.4)
    PACKAGE=$(find release -name "*godot4.5*" -type f | head -n 1)

    if [ -z "$PACKAGE" ]; then
        PACKAGE=$(find release -name "*godot4.4*" -type f | head -n 1)
    fi

    if [ -z "$PACKAGE" ]; then
        log_error "No release packages found in release/"
        log_error "Build one first with: scripts/release-version.sh 4.4"
        exit 1
    fi
fi

log_info "Found package: $(basename "$PACKAGE")"
SIZE=$(du -h "$PACKAGE" | cut -f1)
log_info "Package size: $SIZE"

# Ensure demo directory exists
if [ ! -d "demo" ]; then
    log_error "Demo directory not found: demo/"
    exit 1
fi

# Clean existing addon installation
if [ -d "demo/addons/gd-ink-native" ]; then
    log_info "Removing existing addon installation..."
    rm -rf demo/addons/gd-ink-native
fi

# Ensure demo/addons directory exists
mkdir -p demo/addons

# Extract package
log_info "Extracting package to demo/addons/gd-ink-native..."
unzip -q "$PACKAGE" -d demo/addons/gd-ink-native

# Verify extraction
if [ -f "demo/addons/gd-ink-native/gd-ink-native.gdextension" ]; then
    log_success "Addon extracted successfully!"

    # Fix macOS framework extensions (zip extraction strips .framework suffix)
    if [ -d "demo/addons/gd-ink-native/bin" ]; then
        for framework_dir in demo/addons/gd-ink-native/bin/libgodot_ink.*.macos.*; do
            if [ -d "$framework_dir" ] && [[ ! "$framework_dir" == *.framework ]]; then
                log_info "Fixing framework extension: $(basename "$framework_dir")"
                mv "$framework_dir" "${framework_dir}.framework"
            fi
        done

        # Create debug symlinks if only release builds exist (for development/testing)
        for release_framework in demo/addons/gd-ink-native/bin/*.template_release.framework; do
            if [ -d "$release_framework" ]; then
                debug_framework="${release_framework/template_release/template_debug}"
                if [ ! -e "$debug_framework" ]; then
                    log_info "Creating debug symlink: $(basename "$debug_framework")"
                    ln -s "$(basename "$release_framework")" "$debug_framework"
                fi
            fi
        done
    fi

    # Show what was extracted
    log_info "Extracted files:"
    find demo/addons/gd-ink-native -type f | sed 's|demo/addons/gd-ink-native/||' | sed 's/^/  - /'

    echo ""
    log_warn "IMPORTANT: First-Time Setup Required"
    log_warn "GDExtensions must be registered by opening the project in Godot editor."
    log_warn ""
    log_info "Run this command FIRST to register the extension:"
    echo "  godot --editor --path demo"
    log_info ""
    log_info "After opening the editor once, you can run headless tests:"
    echo "  scripts/test.sh"
else
    log_error "Extraction failed: gd-ink-native.gdextension not found"
    exit 1
fi
