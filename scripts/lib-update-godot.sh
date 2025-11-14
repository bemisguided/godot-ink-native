#!/usr/bin/env bash

# Script: lib-update-godot.sh
# Description: Update godot-cpp submodules to latest stable branches
# Usage: ./scripts/lib-update-godot.sh

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

Update godot-cpp submodules to latest stable branches.

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

# Godot-CPP versions to update
GODOT_VERSIONS=("4.4" "4.5")

log_info "Updating godot-cpp submodules..."

for VERSION in "${GODOT_VERSIONS[@]}"; do
    SUBMODULE_PATH="libs/godot/godot-cpp-$VERSION"

    if [ ! -d "$SUBMODULE_PATH" ]; then
        log_warn "Submodule not found: $SUBMODULE_PATH (skipping)"
        continue
    fi

    log_info "Updating godot-cpp-$VERSION..."

    # Get current commit before update
    OLD_COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)

    # Update submodule
    (
        cd "$SUBMODULE_PATH"
        git checkout "$VERSION"
        git pull origin "$VERSION"
    )

    # Get new commit after update
    NEW_COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)

    if [ "$OLD_COMMIT" == "$NEW_COMMIT" ]; then
        log_info "  Already up to date ($OLD_COMMIT)"
    else
        log_success "  Updated: $OLD_COMMIT -> $NEW_COMMIT"
    fi
done

log_success "Godot-CPP submodules updated!"
echo ""
log_warn "IMPORTANT: Dependencies have been updated!"
log_warn "You must rebuild with --clean flag to use the new versions:"
log_warn "  ./scripts/build-version.sh 4.4 --clean"
log_warn "  ./scripts/build-version.sh 4.5 --clean"
