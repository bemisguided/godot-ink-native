#!/usr/bin/env bash

# Script: target-clean.sh
# Description: Clean build artifacts for specific Godot version(s)
# Usage: ./scripts/target-clean.sh [version|all]

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") [version|all]

Clean build artifacts for specific Godot version(s).

Arguments:
  version      Godot version to clean (4.4, 4.5, or all)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4      # Clean 4.4 build artifacts
  $(basename "$0") 4.5      # Clean 4.5 build artifacts
  $(basename "$0") all      # Clean all build artifacts

Note: This only cleans build/ directories, not release packages or bin/

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

TARGET="${1:-}"

# If no argument, show what would be cleaned
if [ -z "$TARGET" ]; then
    echo "Available build artifacts:"
    echo ""
    if [ -d "build/4.4" ]; then
        SIZE=$(du -sh build/4.4 2>/dev/null | cut -f1)
        echo "  build/4.4/  ($SIZE)"
    fi
    if [ -d "build/4.5" ]; then
        SIZE=$(du -sh build/4.5 2>/dev/null | cut -f1)
        echo "  build/4.5/  ($SIZE)"
    fi
    if [ ! -d "build/4.4" ] && [ ! -d "build/4.5" ]; then
        echo "  (none)"
    fi
    echo ""
    echo "Usage: $(basename "$0") [4.4|4.5|all]"
    exit 0
fi

# Validate version
if ! validate_version "$TARGET"; then
    show_help
    exit 1
fi

# Clean specific version or all
if [[ "$TARGET" == "all" ]]; then
    if [ -d "build" ]; then
        for version in "${SUPPORTED_VERSIONS[@]}"; do
            if [ -d "build/$version" ]; then
                rm -rf "build/$version"
                log_success "Cleaned build/$version/"
            fi
        done
        log_success "Cleaned all build artifacts"
    else
        log_warn "build/ directory does not exist"
    fi
else
    if [ -d "build/$TARGET" ]; then
        rm -rf "build/$TARGET"
        log_success "Cleaned build/$TARGET/"
    else
        log_warn "build/$TARGET/ does not exist"
    fi
fi
