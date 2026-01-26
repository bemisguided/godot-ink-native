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

detect_platforms() {
    local platform_zips=("$@")
    local platforms=()

    for zip in "${platform_zips[@]}"; do
        local basename=$(basename "$zip")
        if [[ "$basename" =~ -macos\.zip$ ]]; then
            platforms+=("macos")
        elif [[ "$basename" =~ -windows-.*\.zip$ ]]; then
            platforms+=("windows")
        elif [[ "$basename" =~ -linux-.*\.zip$ ]]; then
            platforms+=("linux")
        fi
    done

    echo "${platforms[@]}"
}

generate_gdextension() {
    local godot_version="$1"
    local output_file="$2"
    shift 2
    local platforms=("$@")

    log_info "Generating .gdextension file for platforms: ${platforms[*]}"

    # Read template
    local template_file="addon/gd-ink-native.gdextension.in"
    if [ ! -f "$template_file" ]; then
        log_error "Template file not found: $template_file"
        exit 1
    fi

    # Build platform filter regex for awk
    local platform_regex=""
    for p in "${platforms[@]}"; do
        if [ -z "$platform_regex" ]; then
            platform_regex="$p"
        else
            platform_regex="$platform_regex|$p"
        fi
    done

    # Use awk to filter platform sections
    awk -v platforms="$platform_regex" '
    BEGIN { in_section = 0; in_libraries = 0 }

    # Print everything before [libraries] section
    !in_libraries && /^\[libraries\]/ {
        print
        in_libraries = 1
        next
    }

    !in_libraries {
        print
        next
    }

    # In [libraries] section - detect platform headers
    /^[[:space:]]*;[[:space:]]*(Windows|Linux|macOS)/ {
        platform = tolower($0)
        gsub(/^[[:space:]]*;[[:space:]]*/, "", platform)
        gsub(/[[:space:]]*$/, "", platform)

        # Check if this platform should be included
        if (match(tolower(platform), platforms)) {
            in_section = 1
            print
        } else {
            in_section = 0
        }
        next
    }

    # In a platform section - print all lines including empty ones
    in_section && /^[[:space:]]*$/ {
        print
        in_section = 0
        next
    }

    # In a platform section - print config lines
    in_section {
        print
    }
    ' "$template_file" > "$output_file"

    # Substitute version variable
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/@GODOT_VERSION@/$godot_version/g" "$output_file"
    else
        sed -i "s/@GODOT_VERSION@/$godot_version/g" "$output_file"
    fi

    log_info "Generated .gdextension file: $output_file"
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

    # Generate .gdextension file based on available platforms
    local platforms=($(detect_platforms "${platform_zips[@]}"))
    generate_gdextension "$godot_version" "$addon_dir/gd-ink-native.gdextension" "${platforms[@]}"

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
