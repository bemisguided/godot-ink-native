#!/usr/bin/env bash

# Script: target-release.sh
# Description: Create multi-platform release by bundling platform binaries
# Usage: ./scripts/target-release.sh <godot-version> <version> <platform-zips...>

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <godot-version> <version> <platform-zip> [platform-zip...]

Create multi-platform release by bundling platform library packages.

Arguments:
  godot-version    Godot version (4.4, 4.5)
  version          Release version (0.2.0)
  platform-zip     Path to platform libs zip (godot-ink-libs-*.zip)

Examples:
  $(basename "$0") 4.4 0.2.0 \\
    godot-ink-libs-0.2.0-godot4.4-macos.zip \\
    godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip \\
    godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip

Output:
  release/godot-ink-<version>-godot<godot-version>.zip

EOF
}

bundle_release() {
    local godot_version="$1"
    local version="$2"
    shift 2
    local platform_zips=("$@")

    log_info "Bundling multi-platform release for Godot $godot_version..."

    # Validate all input zips exist
    for zip in "${platform_zips[@]}"; do
        if [ ! -f "$zip" ]; then
            log_error "Platform zip not found: $zip"
            exit 1
        fi
        log_info "  - $(basename "$zip")"
    done

    # Create temp directory
    local temp_dir="bundle-temp"
    local addon_dir="$temp_dir/gd-ink-native"
    rm -rf "$temp_dir"
    mkdir -p "$addon_dir/bin"

    # Copy addon wrapper files from source
    log_info "Copying addon wrapper files..."
    cp -r addon/* "$addon_dir/"

    # Copy configured .gdextension file
    local build_dir="build/${godot_version}"
    if [ -f "$build_dir/gd-ink-native.gdextension" ]; then
        cp "$build_dir/gd-ink-native.gdextension" "$addon_dir/"
    else
        log_error "No configured .gdextension file found in $build_dir"
        log_error "Run './scripts/target-build.sh ${godot_version}' first"
        exit 1
    fi

    # Remove .in template if present
    rm -f "$addon_dir/gd-ink-native.gdextension.in"

    # Extract binaries from each platform zip
    log_info "Extracting platform binaries..."
    for zip in "${platform_zips[@]}"; do
        log_info "  - $(basename "$zip")"
        unzip -q "$zip" -d "$temp_dir/extract-temp"

        # Copy binary from bin/ directory
        cp -r "$temp_dir/extract-temp/bin/"* "$addon_dir/bin/"

        rm -rf "$temp_dir/extract-temp"
    done

    # Create final bundle zip
    local output_name="godot-ink-${version}-godot${godot_version}.zip"
    log_info "Creating bundle: $output_name"

    mkdir -p release
    cd "$temp_dir"
    zip -q -r "../release/$output_name" gd-ink-native
    cd ..

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Bundle created: release/$output_name"
    echo ""
    echo "Contents:"
    unzip -l "release/$output_name" | grep -E "(gd-ink-native/|bin/)"
}

# Parse arguments
if [[ $# -lt 3 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

GODOT_VERSION="$1"
VERSION="$2"
shift 2
PLATFORM_ZIPS=("$@")

# Validate version
if ! validate_version "$GODOT_VERSION"; then
    show_help
    exit 1
fi

bundle_release "$GODOT_VERSION" "$VERSION" "${PLATFORM_ZIPS[@]}"
