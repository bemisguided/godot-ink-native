#!/usr/bin/env bash

# Script: lib-update-ink.sh
# Description: Update inkcpp submodule to latest main/master branch
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

Update inkcpp submodule to latest main/master branch.

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

# Get current commit before update
OLD_COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)

# Determine default branch (main or master)
DEFAULT_BRANCH=$(cd "$SUBMODULE_PATH" && git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
if [ -z "$DEFAULT_BRANCH" ]; then
    # Fallback: try main first, then master
    if (cd "$SUBMODULE_PATH" && git show-ref --verify --quiet refs/heads/main); then
        DEFAULT_BRANCH="main"
    elif (cd "$SUBMODULE_PATH" && git show-ref --verify --quiet refs/heads/master); then
        DEFAULT_BRANCH="master"
    else
        log_error "Could not determine default branch for inkcpp"
        exit 1
    fi
fi

log_info "Using branch: $DEFAULT_BRANCH"

# Update submodule
(
    cd "$SUBMODULE_PATH"
    git checkout "$DEFAULT_BRANCH"
    git pull origin "$DEFAULT_BRANCH"
)

# Get new commit after update
NEW_COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)

if [ "$OLD_COMMIT" == "$NEW_COMMIT" ]; then
    log_info "Already up to date ($OLD_COMMIT)"
else
    log_success "Updated: $OLD_COMMIT -> $NEW_COMMIT"
fi

log_success "InkCPP submodule updated!"
