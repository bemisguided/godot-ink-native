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
| `build-version.sh`     | Clean, configure, and build for a specific Godot version |
| `release-version.sh`   | Build and create release package for a specific version  |
| `release-all.sh`       | Build and release for all supported Godot versions       |
| `lib-update-godot.sh`  | Update godot-cpp submodules to latest stable branches    |
| `lib-update-ink.sh`    | Update inkcpp submodule to latest stable tag release     |
| `lib-update-all.sh`    | Update all dependency submodules                         |
| `lib-show-versions.sh` | Display current versions of all dependency submodules    |
| `lib-pin-ink.sh`       | Pin inkcpp submodule to a specific tag version           |
| `test-run.sh`          | Run demo project tests using Godot                       |
| `test-setup.sh`        | Extract release package into demo/addons/ink             |

## Detailed Usage

### `build-version.sh`

Clean, configure, and build the extension for a specific Godot version.

```bash
# Syntax
./scripts/build-version.sh <version> [build_type]

# Examples
./scripts/build-version.sh 4.4           # Build Godot 4.4 (Release)
./scripts/build-version.sh 4.4 Debug    # Build Godot 4.4 (Debug)
./scripts/build-version.sh 4.4 Release  # Build Godot 4.4 (Release)
```

**Arguments:**
- `version` - Godot version to build for (4.4 or 4.5)
- `build_type` - Build type (Release or Debug, default: Release)

**What it does:**
1. Validates input parameters
2. Removes existing `build/` directory
3. Runs CMake configure with specified options
4. Builds the extension with 4 parallel jobs
5. Reports binary location and size

**Output:**
- Binary: `build/libgodot_ink.<VERSION>.<PLATFORM>.template_<BUILD_TYPE>.*`

### `release-version.sh`

Build and create a release package for a specific Godot version.

```bash
# Syntax
./scripts/release-version.sh <version>

# Examples
./scripts/release-version.sh 4.4  # Create release for Godot 4.4
./scripts/release-version.sh 4.4  # Create release for Godot 4.4
```

**Arguments:**
- `version` - Godot version to release for (4.4 or 4.5)

**What it does:**
1. Calls `build-version.sh` with Release build type
2. Runs CMake `release` target to create distribution package
3. Reports package location, size, and contents

**Output:**
- Package: `release/godot-ink-<VERSION>-godot<GODOT_VERSION>-<PLATFORM>.zip`

### `release-all.sh`

Build and create release packages for all supported Godot versions.

```bash
# Syntax
./scripts/release-all.sh

# Example
./scripts/release-all.sh  # Build releases for 4.4 and 4.4
```

**What it does:**
1. Iterates through all supported Godot versions (4.4, 4.5)
2. Calls `release-version.sh` for each version
3. Tracks success/failure for each version
4. Reports summary with all created packages

**Output:**
- Packages: Multiple zip files in `release/` directory
- Summary of successful and failed builds

### `lib-update-godot.sh`

Update godot-cpp submodules to their latest stable branch versions.

```bash
# Syntax
./scripts/lib-update-godot.sh

# Example
./scripts/lib-update-godot.sh  # Update both godot-cpp-4.4 and godot-cpp-4.5
```

**What it does:**
1. Updates `libs/godot/godot-cpp-4.4` to latest 4.4 branch
2. Updates `libs/godot/godot-cpp-4.4` to latest 4.4 branch
3. Reports old and new commit hashes for each
4. Indicates if already up to date

**Note:** This only updates the submodule checkout. You need to commit the submodule changes if you want to record them:

```bash
./scripts/lib-update-godot.sh
git add libs/godot/
git commit -m "Update godot-cpp submodules"
```

### `lib-update-ink.sh`

Update inkcpp submodule to the latest stable tag release.

```bash
# Syntax
./scripts/lib-update-ink.sh

# Example
./scripts/lib-update-ink.sh  # Update inkcpp to latest tag
```

**What it does:**
1. Fetches all tags from remote
2. Finds latest semantic version tag (v0.1.x, v0.2.x, etc.)
3. Checks out the latest tag
4. Reports old and new tag versions
5. Indicates if already on latest tag

**Note:** This uses tag-based versioning for stable releases. Same as godot updates, you need to commit the changes:

```bash
./scripts/lib-update-ink.sh
git add libs/inkcpp
git commit -m "Update inkcpp to v0.1.10"
```

### `lib-update-all.sh`

Update all dependency submodules (godot-cpp and inkcpp).

```bash
# Syntax
./scripts/lib-update-all.sh

# Example
./scripts/lib-update-all.sh  # Update all submodules
```

**What it does:**
1. Calls `lib-update-godot.sh` to update godot-cpp
2. Calls `lib-update-ink.sh` to update inkcpp
3. Runs `git submodule update --init --recursive` to ensure consistency
4. Reports summary of all updates

**Note:** Remember to commit all submodule changes:

```bash
./scripts/lib-update-all.sh
git add libs/
git commit -m "Update all dependency submodules"
```

### `lib-show-versions.sh`

Display current pinned versions of all dependency submodules.

```bash
# Syntax
./scripts/lib-show-versions.sh

# Example
./scripts/lib-show-versions.sh  # Show all dependency versions
```

**What it does:**
1. Shows current commit/branch for godot-cpp-4.4 and godot-cpp-4.5
2. Shows current tag for inkcpp (or warns if not on a tag)
3. Uses color-coded output for easy reading

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
./scripts/lib-pin-ink.sh v0.1.9   # Pin to v0.1.9
./scripts/lib-pin-ink.sh v0.1.8   # Rollback to v0.1.8
```

**Arguments:**
- `tag` - Version tag to pin to (e.g., v0.1.9, v0.1.8)

**What it does:**
1. Fetches all tags from remote
2. Validates the specified tag exists
3. Checks out the specified tag
4. Reports old and new versions
5. Reminds you to commit the change

**Use cases:**
- Pin to a specific stable version for testing
- Rollback to an older version if needed
- Override automatic update from `lib-update-ink.sh`

**Note:** Remember to commit the submodule change:

```bash
./scripts/lib-pin-ink.sh v0.1.8
git add libs/inkcpp
git commit -m "Pin inkcpp to v0.1.8"
```

### `test-run.sh`

Run the demo project tests using Godot.

```bash
# Syntax
./scripts/test.sh

# Examples
./scripts/test.sh                           # Use 'godot' from PATH
GODOT_APP=/path/to/godot ./scripts/test.sh  # Use specific Godot executable
```

**Environment Variables:**
- `GODOT_APP` - Path to Godot executable (default: `godot`)

**What it does:**
1. Checks if Godot executable is available
2. Verifies demo directory and project file exist
3. Warns if addon is not installed in demo
4. Runs Godot in headless mode with test script
5. Reports test results

**Prerequisites:**
- Demo addon must be installed (run `setup-demo.sh` first)
- Demo must have tests in `demo/tests/test_basic.tscn`

**Setting GODOT_APP:**

```bash
# Temporary (current session)
export GODOT_APP=/Applications/Godot.app/Contents/MacOS/Godot
./scripts/test.sh

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export GODOT_APP=/path/to/godot' >> ~/.bashrc
```

### `setup-demo.sh`

Extract the latest release package into `demo/addons/ink` for testing.

```bash
# Syntax
./scripts/setup-demo.sh [godot_version]

# Examples
./scripts/setup-demo.sh      # Extract latest available release
./scripts/setup-demo.sh 4.4  # Extract Godot 4.4 release
./scripts/setup-demo.sh 4.4  # Extract Godot 4.4 release
```

**Arguments:**
- `godot_version` - Godot version to extract (4.4 or 4.5, default: auto-detect)

**What it does:**
1. Finds release package in `release/` directory
2. Removes existing `demo/addons/ink` if present
3. Extracts package to `demo/addons/ink`
4. Verifies extraction was successful
5. Lists extracted files

**Prerequisites:**
- Release package must exist (run `release-version.sh` first)

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
./scripts/build-version.sh 4.4

# 2. Create release package
./scripts/release-version.sh 4.4

# 3. Install to demo for testing
./scripts/setup-demo.sh 4.4

# 4. Run tests
./scripts/test.sh
```

### Release Workflow

```bash
# Build and package for all supported Godot versions
./scripts/release-all.sh

# Output will be in release/ directory:
# - godot-ink-0.1.0-godot4.4-macos.zip
# - godot-ink-0.1.0-godot4.4-macos.zip
```

### Update Dependencies

```bash
# Update all submodules to latest
./scripts/lib-update-all.sh

# Or update individually
./scripts/lib-update-godot.sh  # Just godot-cpp
./scripts/lib-update-ink.sh    # Just inkcpp

# Commit the updates
git add libs/
git commit -m "Update dependency submodules"
```

### Testing Changes

```bash
# Quick rebuild and test cycle
./scripts/build-version.sh 4.4 Debug  # Faster Debug build
./scripts/release-version.sh 4.4      # Package it
./scripts/setup-demo.sh 4.4           # Install to demo
./scripts/test.sh                     # Run tests
```

## Script Features

All scripts include:

- **Help text**: Run with `-h` or `--help` flag
- **Color output**: Blue for info, green for success, yellow for warnings, red for errors
- **Error handling**: Exit immediately on error (`set -e`)
- **Input validation**: Verify all arguments before proceeding
- **Verbose output**: Clear progress messages for each step

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
./scripts/release-version.sh 4.4
```

### Permission Denied

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

## See Also

- [README.md](../README.md) - Main project documentation
- [CLAUDE.md](../CLAUDE.md) - Development reference for LLMs
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
