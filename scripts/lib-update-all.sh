#!/usr/bin/env bash

# Script: lib-update-all.sh
# Description: Update all dependency submodules (godot-cpp and inkcpp)
# Usage: ./scripts/lib-update-all.sh

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

Update all dependency submodules to their latest versions.

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

log_info "Updating all dependency submodules..."

# Track results
SUCCESS_COUNT=0
FAILED_UPDATES=()

# Update godot-cpp submodules
echo ""
log_info "=========================================="
log_info "Updating godot-cpp submodules"
log_info "=========================================="
if "$PROJECT_ROOT/scripts/lib-update-godot.sh"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
    log_error "Failed to update godot-cpp submodules"
    FAILED_UPDATES+=("godot-cpp")
fi

# Update inkcpp submodule
echo ""
log_info "=========================================="
log_info "Updating inkcpp submodule"
log_info "=========================================="
if "$PROJECT_ROOT/scripts/lib-update-ink.sh"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
    log_error "Failed to update inkcpp submodule"
    FAILED_UPDATES+=("inkcpp")
fi

# Ensure all submodules are properly initialized
echo ""
log_info "Ensuring submodule consistency..."
if git submodule update --init --recursive; then
    log_success "Submodules synchronized"
else
    log_warn "Submodule synchronization reported warnings"
fi

# Summary
echo ""
log_info "=========================================="
log_info "Update Summary"
log_info "=========================================="
log_info "Successful updates: $SUCCESS_COUNT/2"

if [ ${#FAILED_UPDATES[@]} -gt 0 ]; then
    log_warn "Failed updates: ${FAILED_UPDATES[*]}"
fi

# Final result
echo ""
if [ ${#FAILED_UPDATES[@]} -eq 0 ]; then
    log_success "All submodules updated successfully!"
    echo ""
    log_warn "IMPORTANT: Dependencies have been updated!"
    log_warn "You must rebuild with --clean flag to use the new versions:"
    log_warn "  ./scripts/build-version.sh 4.4 --clean"
    log_warn "  ./scripts/build-version.sh 4.5 --clean"
    exit 0
else
    log_error "Some submodules failed to update. See above for details."
    exit 1
fi
