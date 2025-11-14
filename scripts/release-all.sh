#!/usr/bin/env bash

# Script: release-all.sh
# Description: Build and release for all supported Godot versions
# Usage: ./scripts/release-all.sh

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

Build and create release packages for all supported Godot versions.

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

# Supported Godot versions
VERSIONS=("4.4" "4.5")

# Build each version
for VERSION in "${VERSIONS[@]}"; do
    echo ""
    "$PROJECT_ROOT/scripts/release-version.sh" "$VERSION" || log_error "Failed: Godot $VERSION"
done

# List created packages
echo ""
if [ -d "release" ]; then
    ls -lh release/*.zip 2>/dev/null || echo "No packages created"
fi
