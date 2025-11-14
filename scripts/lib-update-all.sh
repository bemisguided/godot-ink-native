#!/usr/bin/env bash

# Script: lib-update-all.sh
# Description: Update all dependency submodules (godot-cpp and inkcpp)
# Usage: ./scripts/lib-update-all.sh

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

Update all dependency submodules to their latest versions.

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

log_info "Updating all dependency submodules..."

# Update godot-cpp submodules
"$PROJECT_ROOT/scripts/lib-update-godot.sh" || log_error "Failed to update godot-cpp"

# Update inkcpp submodule
"$PROJECT_ROOT/scripts/lib-update-ink.sh" || log_error "Failed to update inkcpp"

# Synchronize submodules
git submodule update --init --recursive

echo ""
echo "All submodules updated"
echo "Rebuild with: ./scripts/build-version.sh 4.4 --clean"
