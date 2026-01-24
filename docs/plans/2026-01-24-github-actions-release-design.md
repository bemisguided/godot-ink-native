# GitHub Actions Release Workflow Design

**Date:** 2026-01-24
**Status:** In Progress - Brainstorming Phase
**Version:** Draft

## Overview

Design a GitHub Actions workflow to automate multi-platform release builds for godot-ink-native. The workflow will be manually triggered by pushing version tags and will create GitHub Releases with platform-specific library bundles.

## Goals

- Automate release builds across multiple platforms (starting with macOS)
- Support multiple Godot versions (4.4, 4.5, and future versions)
- Create properly structured release packages
- Maintain local build script compatibility (CI should use local scripts)
- Enable manual, tag-based release process (not continuous)

## Decisions Made

### 1. Release Triggering

**Trigger Method:** Git tag push
**Tag Pattern:** `v*` (e.g., `v0.2.0`, `v1.0.0-beta1`, `v2.0-rc1`)

**Flow:**
```
git tag v0.2.0 && git push origin v0.2.0
  ↓
GitHub detects tag push
  ↓
Workflow triggers automatically
  ↓
Builds for all platforms/versions
  ↓
Creates GitHub Release with assets
```

**Version Extraction:** Automatic from tag
- Tag `v0.2.0` → Version `0.2.0`
- Tag `v1.0.0-beta1` → Version `1.0.0-beta1`

### 2. Build Matrix Configuration

**Matrix Strategy:** Structured with explicit platform control

```yaml
strategy:
  matrix:
    godot-version: ['4.4', '4.5']
    include:
      - os: macos-latest
        platform: macos
        arch: "arm64;x86_64"  # Universal binary
```

**Rationale:**
- Godot versions configurable in one place (easy to add 4.6 later)
- Platform matrix supports future expansion (Windows, Linux)
- Explicit architecture control per platform
- Initially creates 2 parallel jobs (macOS × 2 Godot versions)

**Future Expansion:**
```yaml
# When adding Windows/Linux:
include:
  - os: macos-latest
    platform: macos
    arch: "arm64;x86_64"
  - os: windows-latest
    platform: windows
    arch: "x86_64"
  - os: ubuntu-latest
    platform: linux
    arch: "x86_64"
```

### 3. Release Structure

**One GitHub Release per tag** with multiple assets:

**Initial Implementation (Phase 1):**
- Per-platform library builds
- Asset naming: `godot-ink-libs-{version}-godot{godot-version}-{platform}.zip`
- Example assets for v0.2.0:
  - `godot-ink-libs-0.2.0-godot4.4-macos.zip`
  - `godot-ink-libs-0.2.0-godot4.5-macos.zip`

**Future Implementation (Phase 2):**
- Multi-platform bundles per Godot version
- Asset naming: `godot-ink-{version}-godot{godot-version}.zip`
- Example structure:
  ```
  godot-ink-0.2.0-godot4.4.zip
  ├── gd-ink-native/
  │   ├── gd-ink-native.gdextension
  │   ├── *.gd (GDScript wrapper files)
  │   └── bin/
  │       ├── libgodot_ink.4.4.macos.template_release.framework/
  │       ├── libgodot_ink.4.4.windows.template_release.x86_64.dll
  │       └── libgodot_ink.4.4.linux.template_release.x86_64.so
  ```

**Rationale:**
- Phase 1: Get multi-platform builds working quickly
- Phase 2: Add bundling logic after validating builds
- `godot-ink-libs-*` prefix distinguishes library-only builds from future bundles
- Single addon wrapper + all platform binaries = user-friendly installation

### 4. Workflow Architecture

**Workflow File:** `.github/workflows/release.yml`

**Concurrency:** One release workflow at a time (cancel in-progress if new tag pushed)

**Job Structure:**

1. **Build Jobs (Matrix)**
   - Run in parallel for each platform × Godot version combination
   - Use existing local build scripts for consistency
   - Produce per-platform library artifacts
   - Upload as `godot-ink-libs-*` artifacts

2. **Bundle Jobs (Per Godot Version)** - *Phase 2*
   - Runs after all build jobs complete
   - Collects all platform binaries for one Godot version
   - Combines with addon wrapper files
   - Produces final multi-platform zip

3. **Release Job**
   - Runs after all bundle jobs complete (or all build jobs in Phase 1)
   - Creates GitHub Release from tag
   - Uploads all assets
   - Auto-generates release notes
   - Marks as pre-release if version contains `-`

**Dependency Chain:**
```
[Build macOS 4.4] ─┐
[Build macOS 4.5] ─┤
[Build Win 4.4]   ─┼─→ [Bundle 4.4] ─┐
[Build Win 4.5]   ─┼─→ [Bundle 4.5] ─┼─→ [Create Release]
[Build Linux 4.4] ─┤                  │
[Build Linux 4.5] ─┘                  │
                                       └─→ Upload Assets
```

**Failure Handling:** If any build job fails, no release is created

## Build Job Details

Each matrix job executes these steps:

### 1. Checkout & Submodules
- Clone repository with full history (needed for tag information)
- Initialize submodules recursively (`libs/godot/godot-cpp-*`, `libs/inkcpp`)

### 2. Setup Build Tools
- CMake (pre-installed on all GitHub runners)
- Platform compilers:
  - macOS: Xcode/Clang
  - Windows: MSVC
  - Linux: GCC

### 3. Build via Existing Script
```bash
./scripts/target-build.sh ${{ matrix.godot-version }} Release --clean
```

**Rationale:**
- Uses existing, tested build scripts
- Ensures local/CI build parity
- Any improvements to local scripts benefit CI automatically

### 4. Package via Existing Script
```bash
./scripts/target-release.sh ${{ matrix.godot-version }}
```

Generates: `release/godot-ink-{version}-godot{version}-{platform}.zip`

### 5. Rename for Library Convention
Rename output to match `godot-ink-libs-*` naming pattern

### 6. Upload as Artifact
Each job uploads its platform-specific zip for collection by bundle/release jobs

## Open Questions & Left Off

### **PRIMARY DECISION NEEDED: Cross-Platform Script Support**

Current build scripts are bash (`.sh`), which creates a Windows compatibility issue:

**Options:**

**A) Keep bash scripts, Windows uses Git Bash**
- Pros: Single set of scripts to maintain
- Pros: Git Bash pre-installed on GitHub Windows runners
- Cons: Local Windows devs need Git for Windows (though common)

**B) Create parallel scripts: `.sh` for Unix, `.ps1` for Windows**
- Pros: Native on each platform
- Cons: Two versions of every script to maintain
- Cons: Logic can drift between versions

**C) Move core build logic to CMake scripts**
- Pros: CMake already cross-platform
- Pros: Most robust solution
- Cons: Bash scripts become thin wrappers
- Cons: More CMake complexity

**D) Hybrid: Python/Node for complex operations**
- Pros: Python or Node are cross-platform
- Pros: Better for file operations (bundling logic)
- Cons: Adds dependency
- Cons: Simple bash wrappers still needed

**PAUSED HERE** - Need to decide on cross-platform scripting approach before continuing design.

## Implementation Phases

### Phase 1: Basic Multi-Platform Builds
- [x] Design workflow trigger (tag-based)
- [x] Design build matrix (Godot versions + platforms)
- [x] Define asset naming convention (`godot-ink-libs-*`)
- [ ] **BLOCKED:** Decide cross-platform scripting approach
- [ ] Implement workflow for macOS only
- [ ] Add Windows build jobs
- [ ] Add Linux build jobs
- [ ] Test release creation

### Phase 2: Multi-Platform Bundling
- [ ] Design bundling script/logic
- [ ] Implement bundle jobs in workflow
- [ ] Update asset naming (remove `-libs` suffix)
- [ ] Test final release structure
- [ ] Update documentation

### Phase 3: Enhancements (Future)
- [ ] Add manual workflow dispatch option (trigger without tag)
- [ ] Add build caching for faster builds
- [ ] Add artifact retention policies
- [ ] Consider draft release option for review before publish

## Technical Notes

### macOS Universal Binaries
CMake configuration for universal binaries:
```bash
-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

### Platform Detection (from CMakeLists.txt)
```cmake
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(GODOT_PLATFORM "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(GODOT_PLATFORM "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(GODOT_PLATFORM "macos")
endif()
```

### Output Naming Convention
- **macOS**: `libgodot_ink.{version}.macos.template_release.framework` (no arch in name, universal binary)
- **Windows**: `libgodot_ink.{version}.windows.template_release.{arch}.dll`
- **Linux**: `libgodot_ink.{version}.linux.template_release.{arch}.so`

## References

- Existing build scripts: `scripts/target-build.sh`, `scripts/target-release.sh`
- CMake configuration: `CMakeLists.txt` (lines 26-34 for platform detection)
- Project documentation: `CLAUDE.md` (Section 2: Development Workflow)

## Next Steps

1. **Decide** on cross-platform scripting approach (Options A-D above)
2. **Create** bundling script logic (per chosen approach)
3. **Implement** Phase 1 workflow (macOS only first)
4. **Test** with a test tag on a branch
5. **Expand** to Windows and Linux
6. **Implement** Phase 2 bundling
7. **Document** release process for contributors

---

*Design in progress. Last updated: 2026-01-24*
