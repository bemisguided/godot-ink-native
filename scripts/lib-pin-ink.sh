#!/usr/bin/env bash

# Script: lib-pin-ink.sh
# Description: Pin inkcpp submodule to a specific tag version
# Usage: ./scripts/lib-pin-ink.sh <tag>

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
Usage: $(basename "$0") <tag>

Pin inkcpp submodule to a specific tag version.

Arguments:
  tag          Version tag to pin to (e.g., v0.1.9, v0.1.8)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") v0.1.9    # Pin to v0.1.9
  $(basename "$0") v0.1.8    # Pin to older version v0.1.8

To see available tags, run:
  cd libs/inkcpp && git tag -l

EOF
}

# Parse arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if [ $# -ne 1 ]; then
    log_error "Missing required argument: <tag>"
    echo ""
    show_help
    exit 1
fi

TAG="$1"

# Get project root (assuming script is in scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

SUBMODULE_PATH="libs/inkcpp"

if [ ! -d "$SUBMODULE_PATH" ]; then
    log_error "Submodule not found: $SUBMODULE_PATH"
    exit 1
fi

log_info "Pinning inkcpp submodule to $TAG..."

# Get current tag or commit
OLD_TAG=$(cd "$SUBMODULE_PATH" && git describe --tags --exact-match 2>/dev/null || echo "")
if [ -z "$OLD_TAG" ]; then
    OLD_TAG=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)
    log_info "Currently on commit: $OLD_TAG"
else
    log_info "Currently on tag: $OLD_TAG"
fi

# Fetch all tags to make sure we have the latest
log_info "Fetching tags from remote..."
(cd "$SUBMODULE_PATH" && git fetch --tags)

# Verify the tag exists
if ! (cd "$SUBMODULE_PATH" && git rev-parse "$TAG" >/dev/null 2>&1); then
    log_error "Tag '$TAG' does not exist in inkcpp repository"
    echo ""
    log_info "Available tags:"
    (cd "$SUBMODULE_PATH" && git tag -l | tail -10)
    exit 1
fi

# Checkout the specified tag
log_info "Checking out $TAG..."
(
    cd "$SUBMODULE_PATH"
    git checkout "$TAG"
)

# Verify we're on the correct tag
NEW_TAG=$(cd "$SUBMODULE_PATH" && git describe --tags --exact-match 2>/dev/null)

if [ "$OLD_TAG" == "$NEW_TAG" ]; then
    log_info "Already on $OLD_TAG"
else
    log_success "Pinned: $OLD_TAG -> $NEW_TAG"
fi

echo ""
log_warn "IMPORTANT: The submodule change is not yet committed to the main repository."
log_warn "To record this change, run:"
echo ""
echo "  git add libs/inkcpp"
echo "  git commit -m \"Pin inkcpp to $NEW_TAG\""
echo ""

log_success "InkCPP submodule pinned to $TAG!"
