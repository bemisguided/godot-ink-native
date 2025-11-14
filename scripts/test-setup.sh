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

# Ensure demo directory exists
if [ ! -d "demo" ]; then
    log_error "Demo directory not found: demo/"
    exit 1
fi

# Clean and recreate addon directory
rm -rf demo/addons/gd-ink-native
mkdir -p demo/addons

# Extract package
unzip -q "$PACKAGE" -d demo/addons/gd-ink-native

# Verify extraction
if [ ! -f "demo/addons/gd-ink-native/gd-ink-native.gdextension" ]; then
    log_error "Extraction failed: gd-ink-native.gdextension not found"
    exit 1
fi

# Fix macOS framework extensions (zip strips .framework suffix)
if [ -d "demo/addons/gd-ink-native/bin" ]; then
    for framework_dir in demo/addons/gd-ink-native/bin/libgodot_ink.*.macos.*; do
        if [ -d "$framework_dir" ] && [[ ! "$framework_dir" == *.framework ]]; then
            mv "$framework_dir" "${framework_dir}.framework"
        fi
    done

    # Create debug symlinks if only release builds exist
    for release_framework in demo/addons/gd-ink-native/bin/*.template_release.framework; do
        if [ -d "$release_framework" ]; then
            debug_framework="${release_framework/template_release/template_debug}"
            if [ ! -e "$debug_framework" ]; then
                ln -s "$(basename "$release_framework")" "$debug_framework"
            fi
        fi
    done
fi

echo ""
echo "Addon installed to demo/addons/gd-ink-native/"
echo "First-time setup: Open project in Godot editor to register extension"
