#!/usr/bin/env bash

# Script: release-all.sh
# Description: Build and release for all supported Godot versions
# Usage: ./scripts/release-all.sh

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
Usage: $(basename "$0")

Build and create release packages for all supported Godot versions.

Options:
  -h, --help   Show this help message

Example:
  $(basename "$0")

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

# Supported Godot versions
VERSIONS=("4.4" "4.5")

# Track results
SUCCESS_COUNT=0
FAILED_VERSIONS=()

log_info "Creating release packages for all Godot versions..."

# Build each version
for VERSION in "${VERSIONS[@]}"; do
    echo ""
    log_info "=========================================="
    log_info "Processing Godot $VERSION"
    log_info "=========================================="

    if "$PROJECT_ROOT/scripts/release-version.sh" "$VERSION"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        log_success "Godot $VERSION released successfully"
    else
        log_error "Failed to release Godot $VERSION"
        FAILED_VERSIONS+=("$VERSION")
    fi
done

# Summary
echo ""
log_info "=========================================="
log_info "Release Summary"
log_info "=========================================="
log_info "Successful releases: $SUCCESS_COUNT/${#VERSIONS[@]}"

if [ ${#FAILED_VERSIONS[@]} -gt 0 ]; then
    log_warn "Failed versions: ${FAILED_VERSIONS[*]}"
fi

# List all created packages
if [ -d "release" ]; then
    echo ""
    log_info "Created packages:"
    for PACKAGE in release/*.zip; do
        if [ -f "$PACKAGE" ]; then
            SIZE=$(du -h "$PACKAGE" | cut -f1)
            echo "  - $(basename "$PACKAGE") ($SIZE)"
        fi
    done
fi

# Final result
echo ""
if [ ${#FAILED_VERSIONS[@]} -eq 0 ]; then
    log_success "All releases created successfully!"
    exit 0
else
    log_error "Some releases failed. See above for details."
    exit 1
fi
