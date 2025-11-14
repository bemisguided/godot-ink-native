#!/usr/bin/env bash

# Script: lib-update-ink.sh
# Description: Update inkcpp submodule to latest stable tag release
# Usage: ./scripts/lib-update-ink.sh

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

Update inkcpp submodule to latest stable tag release.

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

SUBMODULE_PATH="libs/inkcpp"

if [ ! -d "$SUBMODULE_PATH" ]; then
    log_error "Submodule not found: $SUBMODULE_PATH"
    exit 1
fi

log_info "Updating inkcpp submodule..."

# Get current tag (if on a tag) or commit
OLD_TAG=$(cd "$SUBMODULE_PATH" && git describe --tags --exact-match 2>/dev/null || echo "")
if [ -z "$OLD_TAG" ]; then
    OLD_TAG=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)
    log_info "Currently on commit: $OLD_TAG (not a tagged release)"
else
    log_info "Currently on tag: $OLD_TAG"
fi

# Fetch all tags from remote
log_info "Fetching tags from remote..."
(cd "$SUBMODULE_PATH" && git fetch --tags)

# Find latest semantic version tag (v0.1.x, v0.2.x, etc.)
LATEST_TAG=$(cd "$SUBMODULE_PATH" && git tag -l 'v*' | sort -V | tail -n 1)

if [ -z "$LATEST_TAG" ]; then
    log_error "No version tags found in inkcpp repository"
    exit 1
fi

log_info "Latest available tag: $LATEST_TAG"

# Checkout the latest tag
(
    cd "$SUBMODULE_PATH"
    git checkout "$LATEST_TAG"
)

# Get new tag after update
NEW_TAG=$(cd "$SUBMODULE_PATH" && git describe --tags --exact-match 2>/dev/null)

if [ "$OLD_TAG" == "$NEW_TAG" ]; then
    log_info "Already on latest tag ($OLD_TAG)"
else
    log_success "Updated: $OLD_TAG -> $NEW_TAG"
fi

log_success "InkCPP submodule updated!"
echo ""
log_warn "IMPORTANT: Dependencies have been updated!"
log_warn "You must rebuild with --clean flag to use the new versions:"
log_warn "  ./scripts/build-version.sh 4.4 --clean"
log_warn "  ./scripts/build-version.sh 4.5 --clean"
