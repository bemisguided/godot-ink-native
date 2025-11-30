#!/usr/bin/env bash

# Script: lib-show-versions.sh
# Description: Show current versions of all dependency submodules
# Usage: ./scripts/lib-show-versions.sh

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

# Additional color for this script
CYAN='\033[0;36m'

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

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
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
