#!/usr/bin/env bash

# Script: validate-run.sh
# Description: Run demo project tests using Godot
# Usage: ./scripts/validate-run.sh

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

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

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
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
    log_error "Addon not installed. Run: scripts/validate-setup.sh"
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
