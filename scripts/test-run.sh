#!/usr/bin/env bash

# Script: test.sh
# Description: Run demo project tests using Godot
# Usage: ./scripts/test.sh

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

Run the demo project tests using Godot.

Environment Variables:
  GODOT_APP    Path to Godot executable (default: godot)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0")
  GODOT_APP=/path/to/godot $(basename "$0")

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

# Determine Godot executable
GODOT_EXECUTABLE="${GODOT_APP:-godot}"

# Check if Godot is available
if ! command -v "$GODOT_EXECUTABLE" &> /dev/null; then
    log_error "Godot executable not found: $GODOT_EXECUTABLE"
    echo "Set GODOT_APP environment variable or ensure 'godot' is in PATH"
    exit 1
fi

# Check if demo project exists
if [ ! -f "demo/project.godot" ]; then
    log_error "Demo project not found: demo/project.godot"
    exit 1
fi

# Check if addon is installed
if [ ! -d "demo/addons/gd-ink-native" ]; then
    log_error "Addon not installed. Run: scripts/test-setup.sh"
    exit 1
fi

# Check if project has been registered in editor
if [ ! -d "demo/.godot" ]; then
    log_error "Extension not registered. Open project in editor first:"
    echo "  $GODOT_EXECUTABLE --editor --path demo"
    exit 1
fi

# Run tests
"$GODOT_EXECUTABLE" --headless --path demo tests/test_comprehensive.tscn --quit
