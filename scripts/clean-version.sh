#!/usr/bin/env bash

# Script: clean-version.sh
# Description: Clean build artifacts for specific Godot version(s)
# Usage: ./scripts/clean-version.sh [version|all]

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
Usage: $(basename "$0") [version|all]

Clean build artifacts for specific Godot version(s).

Arguments:
  version      Godot version to clean (4.4 or 4.5)
  all          Clean all versions

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

# Get project root (assuming script is in scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Clean specific version or all
case "$TARGET" in
    4.4|4.5)
        if [ -d "build/$TARGET" ]; then
            rm -rf "build/$TARGET"
            echo "Cleaned build/$TARGET/"
        else
            log_warn "build/$TARGET/ does not exist"
        fi
        ;;
    all)
        if [ -d "build" ]; then
            rm -rf build/4.4 build/4.5
            echo "Cleaned all build artifacts"
        else
            log_warn "build/ directory does not exist"
        fi
        ;;
    *)
        log_error "Invalid argument: $TARGET"
        echo "Valid options: 4.4, 4.5, all"
        exit 1
        ;;
esac
