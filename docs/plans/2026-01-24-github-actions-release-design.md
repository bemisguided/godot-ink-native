# GitHub Actions Release Workflow Design

**Date:** 2026-01-24
**Status:** Complete - Ready for Implementation
**Version:** 1.0

## Overview

Design a GitHub Actions workflow to automate multi-platform release builds for godot-ink-native. The workflow will be manually triggered by pushing version tags and will create GitHub Releases with multi-platform addon bundles.

## Goals

- Automate release builds across multiple platforms (macOS, Windows, Linux)
- Support multiple Godot versions (4.4, 4.5, and future versions)
- Create properly structured multi-platform release packages
- Maintain local build script compatibility (CI should use local scripts)
- Enable manual, tag-based release process (not continuous)
- Keep CMake logic DRY (single packaging function)

## Final Architecture

### Release Flow

```
Tag Push (v0.2.0)
  ↓
GitHub Actions Triggers
  ↓
Build Matrix (Platform × Godot Version)
  ├─ macOS + 4.4 → godot-ink-libs-0.2.0-godot4.4-macos.zip
  ├─ macOS + 4.5 → godot-ink-libs-0.2.0-godot4.5-macos.zip
  ├─ Windows + 4.4 → godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip
  ├─ Windows + 4.5 → godot-ink-libs-0.2.0-godot4.5-windows-x86_64.zip
  ├─ Linux + 4.4 → godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip
  └─ Linux + 4.5 → godot-ink-libs-0.2.0-godot4.5-linux-x86_64.zip
  ↓
Bundle Jobs (Per Godot Version)
  ├─ Bundle 4.4 → godot-ink-0.2.0-godot4.4.zip (all platforms)
  └─ Bundle 4.5 → godot-ink-0.2.0-godot4.5.zip (all platforms)
  ↓
Create GitHub Release (v0.2.0)
  └─ Upload bundles as assets
```

### Release Package Structure

**Final User-Facing Assets:**
```
godot-ink-0.2.0-godot4.4.zip
├── gd-ink-native/
│   ├── gd-ink-native.gdextension
│   ├── *.gd (addon wrapper files)
│   └── bin/
│       ├── libgodot_ink.4.4.macos.template_release.framework/
│       ├── libgodot_ink.4.4.windows.template_release.x86_64.dll
│       └── libgodot_ink.4.4.linux.template_release.x86_64.so
```

Users download ONE zip for their Godot version, works on all platforms.

## Decisions Made

### 1. Release Triggering

**Trigger Method:** Git tag push
**Tag Pattern:** `v*` (e.g., `v0.2.0`, `v1.0.0-beta1`, `v2.0-rc1`)

**Version Extraction:** Automatic from tag
- Tag `v0.2.0` → Version `0.2.0`
- Tag `v1.0.0-beta1` → Version `1.0.0-beta1`

### 2. Build Matrix Configuration

```yaml
strategy:
  matrix:
    godot-version: ['4.4', '4.5']
    include:
      - os: macos-latest
        platform: macos
        arch: "arm64;x86_64"  # Universal binary
      - os: windows-latest
        platform: windows
        arch: "x86_64"
      - os: ubuntu-latest
        platform: linux
        arch: "x86_64"
```

**Creates:** 6 parallel build jobs (3 platforms × 2 Godot versions)

### 3. Two-Phase Packaging

**Phase 1: Platform Builds (libs-only)**
- Each platform builds binary-only package
- Naming: `godot-ink-libs-{version}-godot{godot-version}-{platform}.zip`
- Contents: Just the compiled binary in `bin/`

**Phase 2: Multi-Platform Bundling**
- Combines all platform binaries for each Godot version
- Naming: `godot-ink-{version}-godot{godot-version}.zip`
- Contents: Addon wrapper + all platform binaries

### 4. Cross-Platform Scripting

**Approach:** Bash scripts (Option A)
- GitHub runners have Git Bash on Windows
- Local Windows devs use Git for Windows (common tool)
- Single set of scripts to maintain
- Consistent with existing tooling

### 5. DRY CMake Design

**Approach:** Parameterized function (Option A)
- Single `create_release_target()` function
- Creates both `release` (full addon) and `release-libs` (binary-only) targets
- No duplicate packaging logic
- Easy to maintain and extend

## Implementation Details

### Part 1: CMake Changes

#### New Packaging Function

**Location:** CMakeLists.txt (replace existing `add_custom_target(release ...)`)

```cmake
# Function: create_release_target
# Parameters:
#   TARGET_NAME - Name of the custom target (e.g., "release", "release-libs")
#   INCLUDE_ADDON - TRUE to include addon wrapper files, FALSE for binary-only
#   OUTPUT_PREFIX - Filename prefix ("godot-ink" or "godot-ink-libs")
function(create_release_target TARGET_NAME INCLUDE_ADDON OUTPUT_PREFIX)
    add_custom_target(${TARGET_NAME}
        # Create temp directory for packaging
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp/bin"

        # Copy addon files if full release (conditional on INCLUDE_ADDON)
        $<$<BOOL:${INCLUDE_ADDON}>:
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${CMAKE_SOURCE_DIR}/addon"
                "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp"

            COMMAND ${CMAKE_COMMAND} -E copy
                "${CMAKE_BINARY_DIR}/gd-ink-native.gdextension"
                "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp/gd-ink-native.gdextension"

            COMMAND ${CMAKE_COMMAND} -E remove
                "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp/gd-ink-native.gdextension.in"
        >

        # Copy binary (macOS: entire framework bundle, others: library file)
        COMMAND ${CMAKE_COMMAND} -E
            $<IF:$<STREQUAL:${GODOT_PLATFORM},macos>,copy_directory,copy>
            "$<IF:$<STREQUAL:${GODOT_PLATFORM},macos>,$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>,$<TARGET_FILE:${PROJECT_NAME}>>"
            "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp/bin/$<TARGET_FILE_NAME:${PROJECT_NAME}>"

        # Copy inklecate if available (optional)
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_SOURCE_DIR}/bin/${INKLECATE_EXECUTABLE}"
            "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp/bin/${INKLECATE_EXECUTABLE}" || true

        # Create output directory
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/release"

        # Create zip archive
        COMMAND ${CMAKE_COMMAND} -E chdir "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp"
            ${CMAKE_COMMAND} -E tar "cf"
            "${CMAKE_SOURCE_DIR}/release/${OUTPUT_PREFIX}-${PROJECT_VERSION}-godot${GODOT_VERSION}-${GODOT_PLATFORM}$<$<NOT:$<STREQUAL:${GODOT_PLATFORM},macos>>:-${GODOT_ARCH}>.zip"
            --format=zip
            .

        # Cleanup temp directory
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/${TARGET_NAME}-temp"

        COMMAND ${CMAKE_COMMAND} -E echo "✅ Package created: release/${OUTPUT_PREFIX}-${PROJECT_VERSION}-godot${GODOT_VERSION}-${GODOT_PLATFORM}.zip"

        DEPENDS ${PROJECT_NAME}
        COMMENT "Packaging ${TARGET_NAME} for distribution"
        VERBATIM
    )
endfunction()

# Create both targets
create_release_target(release TRUE "godot-ink")
create_release_target(release-libs FALSE "godot-ink-libs")
```

#### Outputs

**`release` target (existing behavior - unchanged):**
- `release/godot-ink-0.2.0-godot4.4-macos.zip`
- Contains: addon files + binary in `bin/`
- Used by: local developers, direct distribution

**`release-libs` target (new):**
- `release/godot-ink-libs-0.2.0-godot4.4-macos.zip`
- Contains: only binary in `bin/`
- Used by: GitHub Actions for multi-platform bundling

### Part 2: Script Updates

#### New Script: `scripts/target-package-libs.sh`

**Purpose:** Build binary-only package for CI bundling

```bash
#!/usr/bin/env bash

# Script: target-package-libs.sh
# Description: Package binary-only for a specific Godot version
# Usage: ./scripts/target-package-libs.sh <version|all>

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <version|all>

Build binary-only package for a specific Godot version.
Used by CI for multi-platform bundling.

Arguments:
  version      Godot version (4.4, 4.5, or all)

Options:
  -h, --help   Show this help message

Examples:
  $(basename "$0") 4.4     # Build libs-only for 4.4
  $(basename "$0") all     # Build libs-only for all versions

EOF
}

release_libs_version() {
    local version="$1"

    log_info "Building libs-only package for Godot $version..."

    local build_dir="build/${version}"

    # Build the extension
    "$PROJECT_ROOT/scripts/target-build.sh" "$version" Release

    # Create libs-only package
    cmake --build "$build_dir" --target release-libs

    local package=$(find release -name "*godot${version}*libs*" -type f 2>/dev/null | head -n 1)
    if [ -n "$package" ]; then
        echo ""
        echo "Package: $package"
    fi

    log_success "Libs package complete for Godot $version"
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Get project root and change to it
PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

GODOT_VERSION="$1"

# Validate version
if ! validate_version "$GODOT_VERSION"; then
    show_help
    exit 1
fi

# Release all versions or single version
if [[ "$GODOT_VERSION" == "all" ]]; then
    log_info "Building libs packages for all Godot versions..."
    for version in "${SUPPORTED_VERSIONS[@]}"; do
        release_libs_version "$version"
        echo ""
    done
    log_success "All libs packages complete!"
else
    release_libs_version "$GODOT_VERSION"
fi
```

#### New Script: `scripts/target-package.sh`

**Purpose:** Combine multiple platform libraries into multi-platform addon

```bash
#!/usr/bin/env bash

# Script: target-release.sh
# Description: Create multi-platform release by bundling platform binaries
# Usage: ./scripts/target-release.sh <godot-version> <version> <platform-zips...>

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <godot-version> <version> <platform-zip> [platform-zip...]

Bundle multiple platform library packages into a single multi-platform addon.

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
```

### Part 3: GitHub Actions Workflow

**File:** `.github/workflows/release.yml`

```yaml
name: Release Build

# Trigger on version tags
on:
  push:
    tags:
      - 'v*'  # v0.2.0, v1.0.0-beta1, etc.

# Only one release workflow at a time
concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ============================================================================
  # Build Job: Compile binaries for each platform × Godot version
  # ============================================================================
  build:
    name: Build ${{ matrix.platform }} - Godot ${{ matrix.godot-version }}
    runs-on: ${{ matrix.os }}

    strategy:
      fail-fast: false  # Continue other builds if one fails
      matrix:
        godot-version: ['4.4', '4.5']
        include:
          - os: macos-latest
            platform: macos
            arch: "arm64;x86_64"
          # Future: Add Windows and Linux
          # - os: windows-latest
          #   platform: windows
          #   arch: "x86_64"
          # - os: ubuntu-latest
          #   platform: linux
          #   arch: "x86_64"

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0  # Full history for tag info

      - name: Setup CMake
        uses: jwlawson/actions-setup-cmake@v2
        with:
          cmake-version: '3.21'

      - name: Extract version from tag
        id: version
        run: |
          # Remove 'refs/tags/v' prefix
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Version: $VERSION"

      - name: Build extension
        run: |
          ./scripts/target-build.sh ${{ matrix.godot-version }} Release --clean
        env:
          CMAKE_OSX_ARCHITECTURES: ${{ matrix.arch }}

      - name: Create libs package
        run: |
          ./scripts/target-package-libs.sh ${{ matrix.godot-version }}

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: libs-${{ matrix.platform }}-godot${{ matrix.godot-version }}
          path: release/godot-ink-libs-*.zip
          retention-days: 1

  # ============================================================================
  # Bundle Job: Combine platform binaries per Godot version
  # ============================================================================
  bundle:
    name: Bundle Godot ${{ matrix.godot-version }}
    needs: build
    runs-on: ubuntu-latest

    strategy:
      matrix:
        godot-version: ['4.4', '4.5']

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Extract version from tag
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Download all platform artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: libs-*-godot${{ matrix.godot-version }}
          path: artifacts

      - name: List downloaded artifacts
        run: |
          echo "Downloaded artifacts:"
          find artifacts -name "*.zip" -type f

      - name: Bundle multi-platform package
        run: |
          # Collect all platform zips for this Godot version
          PLATFORM_ZIPS=$(find artifacts -name "godot-ink-libs-*-godot${{ matrix.godot-version }}-*.zip" -type f)

          # Call bundling script
          ./scripts/target-release.sh \
            ${{ matrix.godot-version }} \
            ${{ steps.version.outputs.version }} \
            $PLATFORM_ZIPS

      - name: Upload bundled package
        uses: actions/upload-artifact@v4
        with:
          name: bundle-godot${{ matrix.godot-version }}
          path: release/godot-ink-*.zip
          retention-days: 1

  # ============================================================================
  # Release Job: Create GitHub Release with all bundles
  # ============================================================================
  release:
    name: Create GitHub Release
    needs: bundle
    runs-on: ubuntu-latest
    permissions:
      contents: write  # Required to create releases

    steps:
      - name: Extract version from tag
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT

          # Check if pre-release (contains - for beta, rc, etc.)
          if [[ "$VERSION" == *-* ]]; then
            echo "prerelease=true" >> $GITHUB_OUTPUT
          else
            echo "prerelease=false" >> $GITHUB_OUTPUT
          fi

      - name: Download all bundles
        uses: actions/download-artifact@v4
        with:
          pattern: bundle-*
          path: bundles

      - name: List bundles
        run: |
          echo "Release bundles:"
          find bundles -name "*.zip" -type f

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          name: v${{ steps.version.outputs.version }}
          tag_name: ${{ github.ref }}
          generate_release_notes: true
          prerelease: ${{ steps.version.outputs.prerelease }}
          files: |
            bundles/**/godot-ink-*.zip
```

## Implementation Plan

### Phase 1: CMake Refactoring
**Goal:** Add binary-only packaging support

**Tasks:**
1. [ ] Add `create_release_target()` function to CMakeLists.txt
2. [ ] Replace existing `release` target with function call
3. [ ] Add `release-libs` target with function call
4. [ ] Test locally: `cmake --build build/4.4 --target release`
5. [ ] Test locally: `cmake --build build/4.4 --target release-libs`
6. [ ] Verify `release` output unchanged (full addon)
7. [ ] Verify `release-libs` output contains only binary

**Success Criteria:**
- ✅ Both `release` and `release-libs` targets work
- ✅ `release` output unchanged (backward compatible)
- ✅ `release-libs` produces binary-only package
- ✅ No duplicate CMake logic

**Estimated Time:** 1-2 hours

### Phase 2: Script Development
**Goal:** Create bundling infrastructure

**Tasks:**
1. [ ] Create `scripts/target-package-libs.sh`
2. [ ] Test: `./scripts/target-package-libs.sh 4.4`
3. [ ] Test: `./scripts/target-package-libs.sh all`
4. [ ] Create `scripts/target-release.sh`
5. [ ] Create mock platform zips for testing:
   ```bash
   # Create test zips
   mkdir -p test-libs/bin
   touch test-libs/bin/libgodot_ink.4.4.windows.dll
   cd test-libs && zip -r ../godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip . && cd ..
   # Repeat for other platforms
   ```
6. [ ] Test bundling: `./scripts/target-release.sh 4.4 0.2.0 test-libs/*.zip`
7. [ ] Verify output structure: `unzip -l release/godot-ink-0.2.0-godot4.4.zip`

**Success Criteria:**
- ✅ `target-package-libs.sh` works for single and all versions
- ✅ `target-release.sh` combines multiple platforms correctly
- ✅ Final bundle has correct structure (addon + all binaries)

**Estimated Time:** 2-3 hours

### Phase 3: GitHub Actions (macOS Only)
**Goal:** Get end-to-end CI working with one platform

**Tasks:**
1. [ ] Create `.github/workflows/release.yml`
2. [ ] Configure matrix with only macOS initially
3. [ ] Create test branch: `git checkout -b test-release-workflow`
4. [ ] Commit workflow and changes
5. [ ] Push test branch
6. [ ] Create test tag: `git tag v0.2.0-test && git push origin v0.2.0-test`
7. [ ] Monitor workflow: `https://github.com/your-repo/actions`
8. [ ] Debug any failures
9. [ ] Verify GitHub Release created
10. [ ] Verify asset uploaded correctly
11. [ ] Download and test bundle locally

**Success Criteria:**
- ✅ Workflow triggers on tag push
- ✅ macOS builds complete successfully (both Godot versions)
- ✅ Bundling job runs and produces output
- ✅ GitHub Release created with tag
- ✅ Assets attached and downloadable
- ✅ Downloaded bundle structure is correct

**Estimated Time:** 2-4 hours (includes debugging)

### Phase 4: Multi-Platform Expansion
**Goal:** Add Windows and Linux builds

**Tasks:**
1. [ ] Uncomment Windows matrix entry in workflow
2. [ ] Uncomment Linux matrix entry in workflow
3. [ ] Create new test tag: `v0.2.1-test`
4. [ ] Monitor all platform builds
5. [ ] Debug any platform-specific issues
6. [ ] Verify bundles contain all three platforms
7. [ ] Test downloaded bundles on each platform

**Success Criteria:**
- ✅ All platforms build successfully
- ✅ Bundling includes all three platform binaries
- ✅ Final bundles work on all platforms
- ✅ Release process completes end-to-end

**Estimated Time:** 2-4 hours (platform-specific debugging)

### Phase 5: Documentation & Cleanup
**Goal:** Document process and clean up test artifacts

**Tasks:**
1. [ ] Update README.md with release process
2. [ ] Add release workflow badge
3. [ ] Document for contributors how to trigger releases
4. [ ] Clean up test tags/releases
5. [ ] Delete test branch

**Success Criteria:**
- ✅ Documentation complete
- ✅ Contributors understand release process
- ✅ Test artifacts cleaned up

**Estimated Time:** 1 hour

## Testing Strategy

### Local Testing Commands

**Phase 1: CMake**
```bash
# Test full release (existing behavior)
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4
cmake --build build/4.4 --target release
unzip -l release/godot-ink-0.2.0-godot4.4-macos.zip

# Test libs-only release (new behavior)
cmake --build build/4.4 --target release-libs
unzip -l release/godot-ink-libs-0.2.0-godot4.4-macos.zip
```

**Phase 2: Scripts**
```bash
# Test libs script
./scripts/target-package-libs.sh 4.4
./scripts/target-package-libs.sh 4.5

# Create mock platform zips for bundle testing
mkdir -p test-bundle/macos/bin test-bundle/windows/bin test-bundle/linux/bin
touch test-bundle/macos/bin/libgodot_ink.4.4.macos.framework
touch test-bundle/windows/bin/libgodot_ink.4.4.windows.dll
touch test-bundle/linux/bin/libgodot_ink.4.4.linux.so

cd test-bundle/macos && zip -r ../../godot-ink-libs-0.2.0-godot4.4-macos.zip . && cd ../..
cd test-bundle/windows && zip -r ../../godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip . && cd ../..
cd test-bundle/linux && zip -r ../../godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip . && cd ../..

# Test bundling
./scripts/target-release.sh 4.4 0.2.0 \
  godot-ink-libs-0.2.0-godot4.4-macos.zip \
  godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip \
  godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip

# Verify bundle structure
unzip -l release/godot-ink-0.2.0-godot4.4.zip
```

**Phase 3-4: GitHub Actions**
```bash
# Create test branch
git checkout -b test-release-workflow

# Commit all changes
git add .github/workflows/release.yml scripts/ CMakeLists.txt
git commit -m "Add automated release workflow"
git push origin test-release-workflow

# Create and push test tag
git tag v0.2.0-test
git push origin v0.2.0-test

# Monitor workflow
# Visit: https://github.com/your-username/godot-ink-native/actions

# After successful release, download and test
# Visit: https://github.com/your-username/godot-ink-native/releases/tag/v0.2.0-test
```

### Validation Checklist

**After Phase 1 (CMake):**
- [ ] `release` target produces same output as before
- [ ] `release-libs` target produces binary-only package
- [ ] Both targets can run without cleaning
- [ ] Package names are correct

**After Phase 2 (Scripts):**
- [ ] Scripts have correct permissions (`chmod +x`)
- [ ] Scripts validate inputs properly
- [ ] Error messages are helpful
- [ ] Bundle script handles missing files gracefully
- [ ] Final bundle structure matches design

**After Phase 3 (CI macOS):**
- [ ] Workflow triggers on tag push
- [ ] Build logs are readable
- [ ] Artifacts upload successfully
- [ ] Bundle job finds all artifacts
- [ ] Release creation succeeds
- [ ] Assets are downloadable
- [ ] Downloaded bundle extracts correctly
- [ ] Addon loads in Godot

**After Phase 4 (All Platforms):**
- [ ] All platform builds succeed
- [ ] Bundle contains binaries for all platforms
- [ ] Bundle works on Windows, Linux, macOS
- [ ] File permissions preserved (especially on Linux)

## Troubleshooting Guide

### Common Issues

**Issue:** CMake can't find generator expression in function
**Solution:** Use `$<BOOL:>` for conditional commands, not `if()`

**Issue:** Bundling script can't find .gdextension file
**Solution:** Ensure build ran first: `./scripts/target-build.sh 4.4`

**Issue:** GitHub Actions can't find artifacts
**Solution:** Check artifact naming matches download pattern exactly

**Issue:** Release creation fails with permissions error
**Solution:** Ensure workflow has `contents: write` permission

**Issue:** Windows build fails with path issues
**Solution:** Verify Git Bash is being used, check path separators

**Issue:** macOS framework not copied correctly
**Solution:** Use `copy_directory` for frameworks, not `copy`

## Future Enhancements

### After Initial Implementation
- [ ] Add manual workflow dispatch (trigger without tag via UI)
- [ ] Add build caching for faster CI (cache CMake dependencies)
- [ ] Generate SHA256 checksums for release assets
- [ ] Add code signing for binaries (Apple Developer ID, etc.)
- [ ] Create release notes template
- [ ] Add validation step (test addon loads in Godot headless)
- [ ] Add artifact retention policies
- [ ] Consider draft releases for review before publish
- [ ] Add Discord/Slack notifications for releases
- [ ] Add download counts to README

### Potential Optimizations
- [ ] Parallel bundling (bundle both Godot versions simultaneously)
- [ ] Incremental builds (cache compiled objects)
- [ ] Self-hosted runners for faster builds
- [ ] Matrix expansion for more architectures (ARM Linux, etc.)

## Technical Notes

### Platform-Specific Output Naming

From CMakeLists.txt line 291:
```cmake
"${CMAKE_SOURCE_DIR}/release/${OUTPUT_PREFIX}-${PROJECT_VERSION}-godot${GODOT_VERSION}-${GODOT_PLATFORM}$<$<NOT:$<STREQUAL:${GODOT_PLATFORM},macos>>:-${GODOT_ARCH}>.zip"
```

**Results:**
- macOS: `godot-ink-libs-0.2.0-godot4.4-macos.zip` (no arch - universal binary)
- Windows: `godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip`
- Linux: `godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip`

### GitHub Actions Artifact Limitations
- Artifacts expire after retention period (default: 90 days, we use 1 day)
- Maximum artifact size: 10 GB per artifact
- Artifacts are stored as zipped files (automatic)
- Download/upload uses separate actions (`actions/upload-artifact@v4`)

### Cross-Platform Script Considerations
- Git Bash on Windows: installed with Git for Windows
- Path separators: bash handles both `/` and `\`
- Line endings: use LF (set in `.gitattributes`)
- Executable permissions: not needed on Windows, preserved on Unix

## References

- Existing build scripts: `scripts/target-build.sh`, `scripts/target-package.sh`
- CMake configuration: `CMakeLists.txt` (lines 260-300 for release target)
- Project documentation: `CLAUDE.md` (Section 2: Development Workflow)
- GitHub Actions docs: https://docs.github.com/en/actions
- CMake generator expressions: https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html

---

**Status:** Design complete - Ready for implementation
**Next Action:** Begin Phase 1 (CMake Refactoring)
**Last Updated:** 2026-01-24
