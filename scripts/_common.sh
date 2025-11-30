#!/usr/bin/env bash

# Script: _common.sh
# Description: Shared boilerplate for all godot-ink-native scripts
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

# Exit on error and undefined variables
set -e
set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for logging
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

# Get project root directory
get_project_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Supported Godot versions
SUPPORTED_VERSIONS=("4.4" "4.5")

# Validate Godot version
validate_version() {
    local version="$1"

    if [[ "$version" == "all" ]]; then
        return 0
    fi

    for supported in "${SUPPORTED_VERSIONS[@]}"; do
        if [[ "$version" == "$supported" ]]; then
            return 0
        fi
    done

    log_error "Unsupported version: $version"
    log_error "Supported versions: ${SUPPORTED_VERSIONS[*]} all"
    return 1
}
