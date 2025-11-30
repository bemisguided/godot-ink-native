# Development Scripts

This directory contains convenience scripts for common development tasks. These scripts wrap CMake commands and Git operations to simplify the development workflow.

**Note:** These scripts are development aids and not the official documented build process. For production builds and official documentation, refer to the main [README.md](../README.md).

## Prerequisites

- Bash shell (Linux, macOS, or WSL on Windows)
- CMake 3.20+
- Git
- Godot 4.4+ (for testing)

## Scripts Overview

| Script                 | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| `target-build.sh`      | Build for a specific Godot version or all versions       |
| `target-clean.sh`      | Clean build artifacts for specific version(s)            |
| `target-release.sh`    | Build and create release package(s)                      |
| `lib-update.sh`        | Update library submodules (godot-cpp, inkcpp, or all)    |
| `lib-show-versions.sh` | Display current versions of all dependency submodules    |
| `lib-pin-ink.sh`       | Pin inkcpp submodule to a specific tag version           |
| `validate-setup.sh`        | Extract release package into demo/addons/gd-ink-native   |
| `validate-run.sh`          | Run demo project tests using Godot                       |

## Target Scripts (Version Operations)

### `target-build.sh`

Build the extension for a specific Godot version or all versions.

```bash
# Syntax
./scripts/target-build.sh <4.4|4.5|all> [build_type] [--clean]

# Examples
./scripts/target-build.sh 4.4                  # Build Godot 4.4 (incremental)
./scripts/target-build.sh 4.5 Debug            # Build Godot 4.5 (Debug)
./scripts/target-build.sh 4.4 --clean          # Clean build for 4.4
./scripts/target-build.sh all                  # Build all versions
./scripts/target-build.sh all --clean          # Clean build all versions
```

**Arguments:**
- `version` - Godot version to build (4.4, 4.5, or all)
- `build_type` - Build type (Release or Debug, default: Release)
- `--clean` - Clean build directory before building

**Features:**
- Version-specific build directories (build/4.4/, build/4.5/)
- Fast incremental builds (~2-4 seconds if no changes)
- Parallel compilation (4 jobs)
- "all" support builds all versions sequentially

### `target-clean.sh`

Clean build artifacts for specific Godot version(s).

```bash
# Syntax
./scripts/target-clean.sh [4.4|4.5|all]

# Examples
./scripts/target-clean.sh           # Show available artifacts
./scripts/target-clean.sh 4.4       # Clean 4.4 build artifacts
./scripts/target-clean.sh all       # Clean all build artifacts
```

**Arguments:**
- `version` - Version to clean (4.4, 4.5, or all, default: show status)

### `target-release.sh`

Build and create release package for specific version(s).

```bash
# Syntax
./scripts/target-release.sh <4.4|4.5|all>

# Examples
./scripts/target-release.sh 4.4     # Create release for Godot 4.4
./scripts/target-release.sh all     # Create releases for all versions
```

**Arguments:**
- `version` - Godot version to release (4.4, 4.5, or all)

**Output:**
- Package: `release/godot-ink-<VERSION>-godot<GODOT_VERSION>-<PLATFORM>.zip`

## Library Scripts (Dependency Management)

### `lib-update.sh`

Update library submodules to latest stable versions.

```bash
# Syntax
./scripts/lib-update.sh [godot|ink|all]

# Examples
./scripts/lib-update.sh             # Update all (default)
./scripts/lib-update.sh godot       # Update godot-cpp only
./scripts/lib-update.sh ink         # Update inkcpp only
```

**Arguments:**
- `target` - Libraries to update (godot, ink, or all, default: all)

**What it does:**
- `godot` - Updates godot-cpp-4.4 and godot-cpp-4.5 to latest branch commits
- `ink` - Updates inkcpp to latest stable tag (v0.1.x)
- `all` - Updates everything + runs `git submodule update --init --recursive`

**Note:** Remember to commit submodule changes and rebuild with `--clean`:

```bash
./scripts/lib-update.sh
git add libs/
git commit -m "Update dependency submodules"
./scripts/target-build.sh all --clean
```

### `lib-show-versions.sh`

Display current pinned versions of all dependency submodules.

```bash
./scripts/lib-show-versions.sh
```

**Example output:**
```
========================================
Dependency Submodule Versions
========================================

Godot-CPP 4.4: e4b7c25 (branch: 4.4)
Godot-CPP 4.5: abe9457 (branch: 4.5)

InkCPP: v0.1.9 (tag)

========================================
```

### `lib-pin-ink.sh`

Pin inkcpp submodule to a specific tag version.

```bash
# Syntax
./scripts/lib-pin-ink.sh <tag>

# Examples
./scripts/lib-pin-ink.sh v0.1.9     # Pin to v0.1.9
./scripts/lib-pin-ink.sh v0.1.8     # Rollback to v0.1.8
```

**Use cases:**
- Pin to a specific stable version for testing
- Rollback to an older version if needed
- Override automatic update from `lib-update.sh`

## Validation Scripts

### `validate-setup.sh`

Extract release package into `demo/addons/gd-ink-native` for testing.

```bash
# Syntax
./scripts/validate-setup.sh [version]

# Examples
./scripts/validate-setup.sh             # Extract latest available
./scripts/validate-setup.sh 4.4         # Extract Godot 4.4 release
```

**Prerequisites:**
- Release package must exist (run `target-release.sh` first)

### `validate-run.sh`

Run the demo project tests using Godot.

```bash
# Syntax
./scripts/validate-run.sh

# Examples
./scripts/validate-run.sh                              # Use 'godot' from PATH
GODOT_APP=/path/to/godot ./scripts/validate-run.sh     # Use specific executable
```

**Environment Variables:**
- `GODOT_APP` - Path to Godot executable (default: `godot`)

**Prerequisites:**
- Demo addon must be installed (run `validate-setup.sh` first)

## Common Workflows

### Initial Setup

```bash
# Clone repository with submodules
git clone --recursive https://github.com/yourusername/godot-ink-native.git
cd godot-ink-native

# Set Godot executable path (if not in PATH)
export GODOT_APP=/path/to/godot
```

### Development Workflow

```bash
# 1. Build for your target Godot version
./scripts/target-build.sh 4.4

# 2. Create release package
./scripts/target-release.sh 4.4

# 3. Install to demo for testing
./scripts/validate-setup.sh 4.4

# 4. Run tests
./scripts/validate-run.sh
```

### Multi-Version Release Workflow

```bash
# Build and package for all supported Godot versions
./scripts/target-release.sh all

# Output will be in release/ directory:
# - godot-ink-0.1.0-godot4.4-macos.zip
# - godot-ink-0.1.0-godot4.5-macos.zip
```

### Update Dependencies

```bash
# Update all submodules to latest
./scripts/lib-update.sh

# Or update individually
./scripts/lib-update.sh godot  # Just godot-cpp
./scripts/lib-update.sh ink    # Just inkcpp

# Commit the updates and rebuild
git add libs/
git commit -m "Update dependency submodules"
./scripts/target-build.sh all --clean
```

### Quick Rebuild and Test Cycle

```bash
# Make code changes, then:
./scripts/target-build.sh 4.4         # Incremental build (fast!)
./scripts/target-release.sh 4.4       # Package it
./scripts/validate-setup.sh 4.4           # Install to demo
./scripts/validate-run.sh                 # Run tests
```

## Script Features

All scripts include:

- **Consistent interface**: "all" parameter works across target-* scripts
- **Help text**: Run with `-h` or `--help` flag
- **Color output**: Blue for info, green for success, yellow for warnings, red for errors
- **Error handling**: Exit immediately on error (`set -e`)
- **Input validation**: Verify all arguments before proceeding
- **Shared boilerplate**: Common functions in `_common.sh`

## Interface Pattern

```bash
# Target operations (version-specific)
target-build.sh <4.4|4.5|all> [options]
target-clean.sh [4.4|4.5|all]
target-release.sh <4.4|4.5|all>

# Library operations (component-specific)
lib-update.sh [godot|ink|all]     # Default: all
lib-pin-ink.sh <tag>
lib-show-versions.sh

# Test operations
validate-setup.sh [version]            # Auto-detect if omitted
validate-run.sh
```

## Troubleshooting

### "Godot executable not found"

Set the `GODOT_APP` environment variable:

```bash
export GODOT_APP=/path/to/godot
```

### "Submodule not found"

Initialize submodules:

```bash
git submodule update --init --recursive
```

### "No release package found"

Build a release first:

```bash
./scripts/target-release.sh 4.4
```

### Permission Denied

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

### After Updating Dependencies

Always rebuild with `--clean` flag:

```bash
./scripts/target-build.sh all --clean
```

## See Also

- [README.md](../README.md) - Main project documentation
- [CLAUDE.md](../CLAUDE.md) - Development reference for LLMs
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
