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
    log_error ""
    log_error "Please set the GODOT_APP environment variable:"
    log_error "  export GODOT_APP=/path/to/godot"
    log_error ""
    log_error "Or ensure 'godot' is in your PATH."
    exit 1
fi

# Check if demo directory exists
if [ ! -d "demo" ]; then
    log_error "Demo directory not found: demo/"
    exit 1
fi

# Check if demo project file exists
if [ ! -f "demo/project.godot" ]; then
    log_error "Demo project file not found: demo/project.godot"
    exit 1
fi

# Check if addon is installed in demo
if [ ! -d "demo/addons/ink" ]; then
    log_warn "Addon not found in demo/addons/ink/"
    log_warn "Run 'scripts/setup-demo.sh' to extract the addon first"
    log_warn ""
fi

# Check if project has been opened in editor (GDExtension registration)
if [ ! -d "demo/.godot" ]; then
    log_error "Project has not been opened in Godot editor yet"
    log_error ""
    log_error "GDExtensions in Godot 4.x must be registered by opening the project"
    log_error "in the editor first. This creates the .godot/ cache directory."
    log_error ""
    log_error "Run this command to open the project and register the extension:"
    log_error "  $GODOT_EXECUTABLE --editor --path demo"
    log_error ""
    log_error "After the editor opens, close it and then run tests again."
    exit 1
fi

# Run tests
log_info "Running tests with: $GODOT_EXECUTABLE"
log_info "Project: demo/"
echo ""

# Run Godot with the test scene (not --script, as that doesn't load extensions)
# Open the test scene which will run and quit automatically
"$GODOT_EXECUTABLE" --headless --path demo tests/test_basic.tscn --quit

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    log_success "Tests completed successfully!"
    exit 0
else
    echo ""
    log_error "Tests failed!"
    exit 1
fi
