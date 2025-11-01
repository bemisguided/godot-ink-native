#!/usr/bin/env bash

# Script: lib-show-versions.sh
# Description: Show current versions of all dependency submodules
# Usage: ./scripts/lib-show-versions.sh

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

Display current pinned versions of all dependency submodules.

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

echo ""
log_info "=========================================="
log_info "Dependency Submodule Versions"
log_info "=========================================="
echo ""

# Godot-CPP versions
GODOT_VERSIONS=("4.4" "4.5")

for VERSION in "${GODOT_VERSIONS[@]}"; do
    SUBMODULE_PATH="libs/godot/godot-cpp-$VERSION"

    if [ ! -d "$SUBMODULE_PATH" ]; then
        echo -e "${CYAN}Godot-CPP ${VERSION}:${NC} ${RED}NOT FOUND${NC}"
        continue
    fi

    COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)
    BRANCH=$(cd "$SUBMODULE_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")

    echo -e "${CYAN}Godot-CPP ${VERSION}:${NC} ${GREEN}${COMMIT}${NC} (branch: ${BRANCH})"
done

echo ""

# InkCPP version
SUBMODULE_PATH="libs/inkcpp"

if [ ! -d "$SUBMODULE_PATH" ]; then
    echo -e "${CYAN}InkCPP:${NC} ${RED}NOT FOUND${NC}"
else
    # Try to get tag
    TAG=$(cd "$SUBMODULE_PATH" && git describe --tags --exact-match 2>/dev/null || echo "")

    if [ -n "$TAG" ]; then
        echo -e "${CYAN}InkCPP:${NC} ${GREEN}${TAG}${NC} (tag)"
    else
        COMMIT=$(cd "$SUBMODULE_PATH" && git rev-parse --short HEAD)
        BRANCH=$(cd "$SUBMODULE_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
        echo -e "${CYAN}InkCPP:${NC} ${YELLOW}${COMMIT}${NC} (branch: ${BRANCH}) ${RED}[WARNING: Not on a tagged release]${NC}"
    fi
fi

echo ""
log_info "=========================================="
echo ""
