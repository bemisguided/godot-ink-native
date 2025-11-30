#!/usr/bin/env bash

# Script: lib-update.sh
# Description: Update library submodules (godot-cpp and inkcpp)
# Usage: ./scripts/lib-update.sh [godot|ink|all]

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") [godot|ink|all]

Update library submodules to latest stable versions.

Arguments:
  godot        Update godot-cpp submodules only (default branches)
  ink          Update inkcpp submodule only (latest stable tag)
  all          Update all submodules (default if no argument provided)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0")         # Update all libraries (default)
  $(basename "$0") godot   # Update godot-cpp only
  $(basename "$0") ink     # Update inkcpp only
  $(basename "$0") all     # Update all libraries

Note: After updating, run: ./scripts/target-build.sh <version> --clean

EOF
}

# Update godot-cpp submodules
update_godot() {
    log_info "Updating godot-cpp submodules..."

    for version in "${SUPPORTED_VERSIONS[@]}"; do
        local submodule_path="libs/godot/godot-cpp-$version"

        if [ ! -d "$submodule_path" ]; then
            log_warn "Submodule not found: $submodule_path (skipping)"
            continue
        fi

        log_info "Updating godot-cpp-$version to latest on branch $version..."
        (
            cd "$submodule_path"
            git checkout "$version"
            git pull origin "$version"
        )
        log_success "godot-cpp-$version updated"
    done

    log_success "Godot-CPP submodules updated"
}

# Update inkcpp submodule
update_ink() {
    log_info "Updating inkcpp submodule..."

    local submodule_path="libs/inkcpp"

    if [ ! -d "$submodule_path" ]; then
        log_error "Submodule not found: $submodule_path"
        return 1
    fi

    # Fetch and find latest tag
    (cd "$submodule_path" && git fetch --tags)

    local latest_tag=$(cd "$submodule_path" && git tag -l 'v*' | sort -V | tail -n 1)

    if [ -z "$latest_tag" ]; then
        log_error "No version tags found"
        return 1
    fi

    log_info "Updating inkcpp to $latest_tag..."
    (cd "$submodule_path" && git checkout "$latest_tag")

    log_success "InkCPP updated to $latest_tag"
}

# Parse arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

TARGET="${1:-all}"

# Validate target
case "$TARGET" in
    godot|ink|all)
        # Valid target
        ;;
    *)
        log_error "Invalid target: $TARGET"
        log_error "Valid targets: godot, ink, all"
        show_help
        exit 1
        ;;
esac

# Update based on target
case "$TARGET" in
    godot)
        update_godot
        ;;
    ink)
        update_ink
        ;;
    all)
        update_godot
        echo ""
        update_ink
        echo ""
        log_info "Running: git submodule update --init --recursive"
        git submodule update --init --recursive
        log_success "All submodules updated"
        ;;
esac

echo ""
log_warn "Remember to rebuild with: ./scripts/target-build.sh <version> --clean"
