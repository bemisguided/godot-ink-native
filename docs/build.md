# Build System Reference

## Overview

This document provides a comprehensive reference for the godot-ink-native build system, including all CMake targets, build scripts, and their usage patterns. It serves as a permanent reference for contributors and CI developers.

**Target Audience:** Contributors, CI developers, build system maintainers

**Related Documentation:**
- [scripts/README.md](../scripts/README.md) - Detailed script documentation
- [CLAUDE.md](../CLAUDE.md) - Development reference (Section 2: Development Workflow)
- [README.md](../README.md) - Getting started and installation
- [docs/plans/2026-01-24-github-actions-release-design.md](plans/2026-01-24-github-actions-release-design.md) - CI/release workflow design

## Prerequisites

Before building, ensure you have:

- **CMake 3.21+** - Build system generator
- **C++17 compiler** - GCC, Clang, or MSVC
- **Git** - For submodule management
- **Godot 4.4+** - For testing (optional, not required for building)

## Build System Overview

The build system is based on CMake and provides:

1. **Version-specific build directories** - `build/4.4/` and `build/4.5/` for fast version switching
2. **Two packaging approaches:**
   - **Full addon packages** - Complete single-platform addon with binaries and wrapper files
   - **Binary-only packages** - Platform-specific binaries for multi-platform bundling
3. **Workflow support:**
   - **Local development** - Quick single-platform builds and testing
   - **CI/multi-platform** - Build on multiple platforms, then bundle into one package

## CMake Targets

### Default Target (Library Compilation)

Compiles the GDExtension shared library.

**Purpose:** Build the native extension binary

**Inputs:**
- Source files: `src/*.cpp`, `src/*.h`
- Dependencies: `libs/godot/godot-cpp-<version>/`, `libs/inkcpp/`
- CMake variables: `GODOT_VERSION`, `CMAKE_BUILD_TYPE`

**Outputs:**

Platform-specific binary in `build/<version>/`:

- **macOS:** `libgodot_ink.<version>.macos.template_release.framework`
- **Linux:** `libgodot_ink.<version>.linux.template_release.x86_64.so`
- **Windows:** `libgodot_ink.<version>.windows.template_release.x86_64.dll`

**Usage:**

```bash
# Configure for Godot 4.4
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4

# Build the library
cmake --build build/4.4 --config Release -j4
```

**Example Output Path:**

```
build/4.4/libgodot_ink.4.4.macos.template_release.framework
├── Resources/
│   └── Info.plist
└── libgodot_ink.4.4.macos.template_release
```

---

### `release` Target

Creates a complete single-platform addon package with binaries and wrapper files.

**Purpose:** Package the complete addon for single-platform distribution

**Inputs:**
- Compiled binary from default target
- Addon wrapper files: `addon/*.gd`, `addon/plugin.cfg`
- Configured `.gdextension` file: `build/<version>/gd-ink-native.gdextension`
- Inklecate compiler: `bin/inklecate` (optional)

**Outputs:**

Single-platform package in `release/`:

```
release/godot-ink-<version>-godot<godot-version>-<platform>.zip
```

**Package Contents:**
```
gd-ink-native/
├── gd-ink-native.gdextension    # Platform-configured extension definition
├── plugin.cfg                    # Godot plugin configuration
├── *.gd                          # GDScript wrapper files
└── bin/
    ├── libgodot_ink.*            # Platform-specific binary
    └── inklecate                 # Ink compiler (optional)
```

**Usage:**

```bash
# Build and create release package for Godot 4.4
cmake --build build/4.4 --target release
```

**Example:**

```bash
# Configure and build
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4
cmake --build build/4.4 --config Release -j4

# Create release package
cmake --build build/4.4 --target release

# Output: release/godot-ink-0.1.0-godot4.4-macos.zip
```

---

### `release-libs` Target

Creates a binary-only package for multi-platform bundling.

**Purpose:** Package only the compiled binary for CI multi-platform workflows

**Inputs:**
- Compiled binary from default target
- Inklecate compiler: `bin/inklecate` (optional)

**Outputs:**

Binary-only package in `release/`:

```
release/godot-ink-libs-<version>-godot<godot-version>-<platform>.zip
```

**Package Contents:**
```
bin/
├── libgodot_ink.*     # Platform-specific binary
└── inklecate          # Ink compiler (optional)
```

**Usage:**

```bash
# Build and create libs-only package for Godot 4.4
cmake --build build/4.4 --target release-libs
```

**Example:**

```bash
# Configure and build
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4
cmake --build build/4.4 --config Release -j4

# Create libs-only package
cmake --build build/4.4 --target release-libs

# Output: release/godot-ink-libs-0.1.0-godot4.4-macos.zip
```

**CI Context:**

This target is used in multi-platform CI workflows:
1. Each platform (macOS, Windows, Linux) builds and creates a libs-only package
2. A separate bundling job collects all platform packages
3. The bundling job uses `target-package.sh` to combine them into one multi-platform addon

---

## Build Scripts

### `target-build.sh`

Configures CMake and compiles the extension.

**Purpose:** Build the extension binary with CMake

**Syntax:**

```bash
./scripts/target-build.sh <version|all> [build_type] [--clean]
```

**Arguments:**
- `version` - Godot version: `4.4`, `4.5`, or `all`
- `build_type` - Build type: `Release` or `Debug` (default: `Release`)

**Options:**
- `--clean` - Full rebuild (use after dependency updates)
- `-h, --help` - Show help message

**Inputs:**
- Source files: `src/*.cpp`, `src/*.h`
- Submodules: `libs/godot/godot-cpp-<version>/`, `libs/inkcpp/`

**Outputs:**
- Compiled binary in `build/<version>/`

**Examples:**

```bash
# Incremental build for Godot 4.4 (Release)
./scripts/target-build.sh 4.4

# Incremental build for Godot 4.5 (Debug)
./scripts/target-build.sh 4.5 Debug

# Clean build for Godot 4.4 (after dependency updates)
./scripts/target-build.sh 4.4 --clean

# Clean debug build for Godot 4.5
./scripts/target-build.sh 4.5 Debug --clean

# Build all supported versions
./scripts/target-build.sh all
```

**Performance:**
- **First build:** ~5-10 minutes (builds dependencies)
- **Switching versions:** ~2-4 seconds (no rebuild needed)
- **Incremental rebuild:** ~8-15 seconds (only changed files)

---

### `target-package.sh`

Packages complete single-platform addon.

**Purpose:** Package a complete addon for single-platform distribution

**Syntax:**

```bash
./scripts/target-package.sh <version|all>
```

**Arguments:**
- `version` - Godot version: `4.4`, `4.5`, or `all`

**Options:**
- `-h, --help` - Show help message

**Inputs:**
- Source files (builds binary automatically)
- Addon wrapper files: `addon/*`
- Configured `.gdextension` from `build/<version>/`

**Outputs:**

```
release/godot-ink-<version>-godot<godot-version>-<platform>.zip
```

**Examples:**

```bash
# Build and package for Godot 4.4
./scripts/target-package.sh 4.4
# Output: release/godot-ink-0.1.0-godot4.4-macos.zip

# Build and package for Godot 4.5
./scripts/target-package.sh 4.5
# Output: release/godot-ink-0.1.0-godot4.5-macos.zip

# Build and package all versions
./scripts/target-package.sh all
# Output:
#   release/godot-ink-0.1.0-godot4.4-macos.zip
#   release/godot-ink-0.1.0-godot4.5-macos.zip
```

**Workflow:**

This script:
1. Calls `target-build.sh <version> Release` to compile the binary
2. Runs CMake `release` target to create the package
3. Displays the package location

---

### `target-package-libs.sh`

Packages binary-only for CI multi-platform bundling.

**Purpose:** Package binary-only for multi-platform bundling workflows

**Syntax:**

```bash
./scripts/target-package-libs.sh <version|all>
```

**Arguments:**
- `version` - Godot version: `4.4`, `4.5`, or `all`

**Options:**
- `-h, --help` - Show help message

**Inputs:**
- Source files (builds binary automatically)

**Outputs:**

```
release/godot-ink-libs-<version>-godot<godot-version>-<platform>.zip
```

**Examples:**

```bash
# Build libs-only package for Godot 4.4
./scripts/target-package-libs.sh 4.4
# Output: release/godot-ink-libs-0.1.0-godot4.4-macos.zip

# Build libs-only packages for all versions
./scripts/target-package-libs.sh all
# Output:
#   release/godot-ink-libs-0.1.0-godot4.4-macos.zip
#   release/godot-ink-libs-0.1.0-godot4.5-macos.zip
```

**CI Usage:**

In GitHub Actions workflow:

```yaml
# Build job (runs on each platform)
- name: Build libs-only package
  run: ./scripts/target-package-libs.sh 4.4

# Upload artifact for bundling
- name: Upload libs package
  uses: actions/upload-artifact@v4
  with:
    name: libs-${{ matrix.platform }}
    path: release/godot-ink-libs-*.zip
```

**Workflow:**

This script:
1. Calls `target-build.sh <version> Release` to compile the binary
2. Runs CMake `release-libs` target to create the binary-only package
3. Displays the package location

---

### `target-package.sh`

Creates multi-platform release by bundling platform binaries.

**Purpose:** Create multi-platform release by bundling platform binaries into one complete addon

**Syntax:**

```bash
./scripts/target-release.sh <godot-version> <version> <platform-zip> [platform-zip...]
```

**Arguments:**
- `godot-version` - Godot version: `4.4` or `4.5`
- `version` - Release version (e.g., `0.2.0`)
- `platform-zip` - Path to platform libs zip (`godot-ink-libs-*.zip`)

**Options:**
- `-h, --help` - Show help message

**Inputs:**
- Multiple platform libs-only zips (`godot-ink-libs-*.zip`)
- Configured `.gdextension` from `build/<godot-version>/`
- Addon wrapper files from `addon/`

**Outputs:**

```
release/godot-ink-<version>-godot<godot-version>.zip
```

**Note:** Multi-platform packages have **no platform suffix** in the filename.

**Example:**

```bash
# Bundle macOS, Windows, and Linux binaries into single addon
./scripts/target-release.sh 4.4 0.2.0 \
  release/godot-ink-libs-0.2.0-godot4.4-macos.zip \
  release/godot-ink-libs-0.2.0-godot4.4-windows-x86_64.zip \
  release/godot-ink-libs-0.2.0-godot4.4-linux-x86_64.zip

# Output: release/godot-ink-0.2.0-godot4.4.zip
```

**Package Contents:**

```
gd-ink-native/
├── gd-ink-native.gdextension    # Multi-platform extension definition
├── plugin.cfg                    # Godot plugin configuration
├── *.gd                          # GDScript wrapper files
└── bin/
    ├── libgodot_ink.4.4.macos.template_release.framework/   # macOS binary
    ├── libgodot_ink.4.4.windows.template_release.x86_64.dll # Windows binary
    └── libgodot_ink.4.4.linux.template_release.x86_64.so    # Linux binary
```

**CI Context:**

```yaml
# Bundle job (depends on all build jobs)
- name: Download all platform artifacts
  uses: actions/download-artifact@v4

- name: Bundle multi-platform addon
  run: |
    ./scripts/target-release.sh 4.4 0.2.0 \
      libs-macos/godot-ink-libs-*.zip \
      libs-windows/godot-ink-libs-*.zip \
      libs-linux/godot-ink-libs-*.zip

- name: Upload multi-platform release
  uses: actions/upload-artifact@v4
  with:
    name: addon-multiplatform
    path: release/godot-ink-*.zip
```

**Workflow:**

This script:
1. Validates all input platform zips exist
2. Creates temporary directory structure
3. Copies addon wrapper files from `addon/`
4. Copies configured `.gdextension` from `build/<godot-version>/`
5. Extracts binaries from each platform zip into `bin/`
6. Creates final multi-platform zip
7. Cleans up temporary files

---

## Common Workflows

### Local Development (Single Platform)

Quick build and package for your current platform:

```bash
# Build and package for Godot 4.4 (single command)
./scripts/target-package.sh 4.4

# Result: release/godot-ink-0.1.0-godot4.4-macos.zip
# (platform suffix varies: macos, windows-x86_64, linux-x86_64)
```

**Testing:**

```bash
# Extract to demo project
./scripts/validate-setup.sh 4.4

# Run tests
./scripts/validate-run.sh
```

---

### Multi-Platform Release (CI)

CI workflow for building across multiple platforms and bundling:

**Step 1: Build on each platform**

```yaml
# Each platform runs this job
jobs:
  build-libs:
    strategy:
      matrix:
        platform: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - name: Build libs-only
        run: ./scripts/target-package-libs.sh 4.4
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: libs-${{ matrix.platform }}
          path: release/godot-ink-libs-*.zip
```

**Step 2: Bundle all platforms**

```yaml
  bundle:
    needs: build-libs
    runs-on: ubuntu-latest
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v4
      - name: Bundle multi-platform addon
        run: |
          ./scripts/target-release.sh 4.4 0.2.0 \
            libs-*/godot-ink-libs-*.zip
      - name: Upload multi-platform addon
        uses: actions/upload-artifact@v4
        with:
          name: addon-multiplatform
          path: release/godot-ink-*.zip
```

**Result:**

```
release/godot-ink-0.2.0-godot4.4.zip
```

This single package works on macOS, Windows, and Linux.

---

### Version Switching

Switch between Godot versions with minimal rebuilding:

```bash
# Build for Godot 4.4
./scripts/target-build.sh 4.4
# First build: ~5-10 minutes

# Switch to Godot 4.5 (FAST - no cleanup needed)
./scripts/target-build.sh 4.5
# Switching: ~2-4 seconds (no rebuild)

# Switch back to Godot 4.4 (FAST - artifacts preserved)
./scripts/target-build.sh 4.4
# Switching back: ~2-4 seconds

# Incremental rebuild (after code changes)
./scripts/target-build.sh 4.4
# Only changed files: ~8-15 seconds
```

**Why it's fast:**

Version-specific build directories (`build/4.4/`, `build/4.5/`) preserve all build artifacts. Switching versions only requires re-running CMake configuration, not recompiling dependencies.

**When to use `--clean`:**

```bash
# After updating dependencies
git submodule update --remote
./scripts/target-build.sh 4.4 --clean
```

---

### Debug Builds

Build with debug symbols for development:

```bash
# Debug build for Godot 4.4
./scripts/target-build.sh 4.4 Debug

# Output: build/4.4/libgodot_ink.4.4.macos.template_debug.framework
```

**Note:** Debug builds are **not** packaged by `target-package.sh` (always uses Release).

---

## Output Naming Conventions

### Single-Platform Full Addon

```
godot-ink-<version>-godot<godot-version>-<platform>.zip
```

**Examples:**
- `godot-ink-0.1.0-godot4.4-macos.zip`
- `godot-ink-0.1.0-godot4.4-windows-x86_64.zip`
- `godot-ink-0.1.0-godot4.4-linux-x86_64.zip`

**Contains:** Complete addon with binaries and wrapper files

---

### Binary-Only (libs-only)

```
godot-ink-libs-<version>-godot<godot-version>-<platform>.zip
```

**Examples:**
- `godot-ink-libs-0.1.0-godot4.4-macos.zip`
- `godot-ink-libs-0.1.0-godot4.4-windows-x86_64.zip`
- `godot-ink-libs-0.1.0-godot4.4-linux-x86_64.zip`

**Contains:** Only the compiled binary (no addon wrapper files)

---

### Multi-Platform Addon

```
godot-ink-<version>-godot<godot-version>.zip
```

**Examples:**
- `godot-ink-0.2.0-godot4.4.zip`
- `godot-ink-0.2.0-godot4.5.zip`

**Note:** No platform suffix - works on all platforms

**Contains:** Complete addon with binaries for macOS, Windows, and Linux

---

## Binary Naming Conventions

Compiled binaries follow this pattern:

```
libgodot_ink.<godot-version>.<platform>.template_<build-type>.<arch><ext>
```

**Examples:**

| Platform | Binary Name |
|----------|-------------|
| macOS | `libgodot_ink.4.4.macos.template_release.framework` |
| Linux | `libgodot_ink.4.4.linux.template_release.x86_64.so` |
| Windows | `libgodot_ink.4.4.windows.template_release.x86_64.dll` |

**Debug builds:**
- Replace `template_release` with `template_debug`
- Example: `libgodot_ink.4.4.macos.template_debug.framework`

---

## See Also

- [scripts/README.md](../scripts/README.md) - Detailed script documentation with all available scripts
- [CLAUDE.md](../CLAUDE.md) - Development reference for LLM assistance (Section 2: Development Workflow)
- [README.md](../README.md) - Getting started and installation instructions
- [docs/plans/2026-01-24-github-actions-release-design.md](plans/2026-01-24-github-actions-release-design.md) - CI/release workflow design document
