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

# Fetch and verify tag exists
(cd "$SUBMODULE_PATH" && git fetch --tags)

if ! (cd "$SUBMODULE_PATH" && git rev-parse "$TAG" >/dev/null 2>&1); then
    log_error "Tag '$TAG' does not exist"
    echo "Available tags:"
    (cd "$SUBMODULE_PATH" && git tag -l | tail -10)
    exit 1
fi

# Checkout the specified tag
(cd "$SUBMODULE_PATH" && git checkout "$TAG")

echo ""
echo "InkCPP pinned to $TAG"
echo "Commit this change: git add libs/inkcpp && git commit -m \"Pin inkcpp to $TAG\""
