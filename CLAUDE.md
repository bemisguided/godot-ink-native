# CLAUDE.md - LLM Development Reference

Quick reference guide for AI assistants working on godot-ink-native.

## 1. Project Overview

**What:** GDExtension wrapping inkcpp library for Godot 4.4+
**Language:** C++17
**Build System:** Pure CMake (no SCons)
**Target:** Cross-platform (Windows, Linux, macOS)
**Output:** Shared library (.dll/.so/.framework)

## 2. Development Workflow - ⚠️ USE SCRIPTS FIRST

**CRITICAL:** All build, test, and dependency operations MUST use the provided scripts in `scripts/`. Direct cmake or git commands require special permissions and should only be used for debugging or advanced scenarios.

### Available Scripts (Always Permitted)

**Build & Release:**
- `./scripts/target-build.sh <version|all> [build_type] [--clean]` - Build for specific Godot version or all versions (incremental by default)
- `./scripts/target-clean.sh [version|all]` - Clean build artifacts for specific version(s)
- `./scripts/target-release.sh <version|all>` - Build and create release package(s)

**Validation:**
- `./scripts/validate-run.sh` - Run demo project tests using Godot (requires GODOT_APP env var)
- `./scripts/validate-setup.sh [version]` - Extract release package into demo/addons/gd-ink-native

**Dependency Management:**
- `./scripts/lib-update.sh [godot|ink|all]` - Update library submodules (default: all)
- `./scripts/lib-show-versions.sh` - Display current versions of all submodules
- `./scripts/lib-pin-ink.sh <tag>` - Pin inkcpp to a specific tag version

### Permission Model

✅ **Always Allowed:** All scripts listed above
⚠️ **Requires Permission:** All `git` commands (git checkout, git commit, git push, etc.)
❌ **Not Recommended:** Direct cmake commands (use build scripts instead)

### Standard Workflows

**Quick build and test:**
```bash
./scripts/target-build.sh 4.4
./scripts/validate-setup.sh 4.4
./scripts/validate-run.sh
```

**Create release:**
```bash
./scripts/target-release.sh 4.4
# Output: release/godot-ink-0.1.0-godot4.4-macos.zip
```

**Build all versions:**
```bash
./scripts/target-build.sh all
./scripts/target-release.sh all
```

**Update dependencies (requires git permission):**
```bash
./scripts/lib-update.sh
# Then commit changes
```

## 3. Code Style & Conventions

### Naming Rules
- **Classes:** PascalCase (`InkStory`, `InkChoice`)
- **Public methods:** snake_case (`continue_story`, `get_variable`)
- **Private members:** snake_case with underscore prefix (`_story`, `_runner`)
- **Constants:** UPPER_SNAKE_CASE
- **Files:** snake_case matching class name (`ink_story.h`, `ink_story.cpp`)

### File Structure
```cpp
/* Copyright header */
#ifndef CLASS_NAME_H
#define CLASS_NAME_H

// Godot includes first
#include <godot_cpp/classes/ref_counted.hpp>

// InkCPP includes second
#include <story.h>

// STL includes last
#include <vector>

using namespace godot;

class ClassName : public RefCounted {
    GDCLASS(ClassName, RefCounted)

private:
    // Members

protected:
    static void _bind_methods();

public:
    // Constructor/destructor
    // Public methods
};

#endif
```

### Class Organization
1. Private members first
2. Protected methods (including `_bind_methods()`)
3. Public constructor/destructor
4. Public methods grouped by category (Loading, Execution, Choices, etc.)

### Documentation
- Use Doxygen-style comments for public API: `/** @brief ... */`
- Include usage examples in header comments
- Document parameters: `@param name Description`
- Document returns: `@return Description`

## 3. Dependency Versioning

### Version Pinning Strategy

The project uses **different versioning strategies** for different dependencies:

**godot-cpp (Branch Tracking):**
- Tracks stable **branches**: `4.4` and `4.5`
- These branches receive backported fixes from Godot upstream
- Updates pull latest commits from the branch
- Location: `libs/godot/godot-cpp-4.4/` and `libs/godot/godot-cpp-4.5/`
- Update: `./scripts/lib-update-godot.sh`

**inkcpp (Tag Pinning):**
- Pins to stable **semantic version tags**: `v0.1.9`, `v0.1.8`, etc.
- Current version: **v0.1.9**
- Tags represent stable releases
- Master branch may contain unstable commits
- Location: `libs/inkcpp/`
- Update to latest: `./scripts/lib-update-ink.sh`
- Pin to specific: `./scripts/lib-pin-ink.sh v0.1.9`

**Why Different Strategies?**
- godot-cpp branches are maintained for stability (like Godot itself)
- inkcpp uses tags for releases, with active development on master
- This ensures both stability and reproducibility

**Checking Versions:**
```bash
./scripts/lib-show-versions.sh
# Output:
# Godot-CPP 4.4: e4b7c25 (branch: 4.4)
# Godot-CPP 4.5: abe9457 (branch: 4.5)
# InkCPP: v0.1.9 (tag)
```

## 4. Project Structure

### Critical Paths
```
godot-ink-native/
├── CMakeLists.txt                     # Root build config
├── addon/                             # Addon source files
│   └── gd-ink-native.gdextension      # Extension config
├── libs/                    # Third-party libraries (submodules)
│   ├── godot/
│   │   ├── godot-cpp-4.4/   # godot-cpp 4.4 (submodule)
│   │   └── godot-cpp-4.5/   # godot-cpp 4.5 (submodule)
│   └── inkcpp/              # inkcpp library (submodule)
├── build/                   # CMake build directory (gitignored)
│   ├── 4.4/                 # Build artifacts for Godot 4.4
│   └── 4.5/                 # Build artifacts for Godot 4.5
├── release/                 # Distribution packages (gitignored)
│   └── godot-ink-*.zip
├── demo/                    # Demo project (no addons/)
│   ├── examples/            # Test Ink stories (.ink.json)
│   ├── tests/               # GDScript test suites
│   └── project.godot        # Godot project file
└── src/                     # C++ wrapper implementation
    ├── ink_choice.h/cpp     # Choice wrapper (simple data holder)
    ├── ink_story.h/cpp      # Main story interface (owns story/runner/globals)
    └── register_types.h/cpp # GDExtension entry point
```

### Key Files

**CMakeLists.txt** - Root build configuration
- Platform detection (Linux/Windows/macOS)
- Multi-version support (GODOT_VERSION: 4.4 or 4.5)
- InkCPP options (disable PY/C/TEST)
- Output naming convention includes version
- Links: godot-cpp, inkcpp, inkcpp_compiler
- Custom `release` target for packaging

**addon/gd-ink-native.gdextension** - Extension configuration
- Entry symbol: `godot_ink_init`
- Platform-specific library paths
- Compatibility: Godot 4.4 to 4.5.99

**.gitignore** - Exclude build artifacts
- `/build/*/` directories (version-specific: build/4.4/, build/4.5/)
- CMake artifacts (CMakeCache.txt, CMakeFiles/, *.cmake)
- Binary outputs (except .gitkeep)

### Submodules
```bash
# Clone with submodules
git clone --recursive <repo>

# Or initialize after clone
git submodule update --init --recursive

# Submodule locations:
# - libs/godot/godot-cpp-4.4/  (godot-cpp branch 4.4)
# - libs/godot/godot-cpp-4.4/  (godot-cpp branch 4.4)
# - libs/inkcpp/               (inkcpp library)
```

## 4. Architecture Decisions

### Wrapper Strategy
- **Simplify API:** Hide factory pattern (Story → Runner + Globals)
- **Single Entry Point:** InkStory class owns all three internally
- **Data Copying:** InkChoice copies data (no borrowed pointers)
- **GDScript-Friendly:** Return Godot types (Array, Variant, String)

### Memory Management
```cpp
// InkStory ownership pattern:
ink::runtime::story* _story;        // Raw pointer - delete in destructor
ink::runtime::runner _runner;       // Smart pointer - auto-managed
ink::runtime::globals _globals;     // Smart pointer - auto-managed
std::vector<unsigned char> _binary; // Owns compiled story data
```

**Rules:**
1. InkStory destructor deletes `_story`
2. `_runner` and `_globals` are smart pointers (story_ptr<>) - don't delete
3. `_binary_data` must outlive the story (story::from_binary doesn't copy)
4. InkChoice copies all data - no lifetime dependencies

### Type Conversions

**Variant → ink::runtime::value:**
```cpp
switch (value.get_type()) {
    case Variant::BOOL: return ink::runtime::value((bool)value);
    case Variant::INT: return ink::runtime::value((int32_t)(int64_t)value);
    case Variant::FLOAT: return ink::runtime::value((float)(double)value);
    case Variant::STRING: /* See string handling warning below */
}
```

**ink::runtime::value → Variant:**
```cpp
switch (val.type) {
    case ink::runtime::value::Type::Bool:
        return Variant(val.get<ink::runtime::value::Type::Bool>());
    case ink::runtime::value::Type::Int32:
        return Variant(val.get<ink::runtime::value::Type::Int32>());
    // ... etc
}
```

### Include Strategy

**CRITICAL:** Cannot forward-declare inkcpp types. They are typedefs, not classes.

```cpp
// WRONG - will cause GDCLASS compilation errors:
namespace ink::runtime {
    class runner_interface;
    class globals_interface;
}

// CORRECT - include directly:
#include <story.h>
#include <types.h>
```

**Why:** `ink::runtime::runner` is `typedef story_ptr<runner_impl> runner`

### JSON Compilation
- User provides JSON → `_compile_json_to_binary()` → binary stored in `_binary_data`
- Uses `ink::compiler::run()` from inkcpp_compiler
- Error handling: Check `compilation_results.errors`, print to Godot console
- Warnings: Print but don't fail compilation

### External Functions

External functions allow GDScript to be called from Ink stories. Implemented via bridge pattern.

**Architecture:**
```cpp
// Storage
std::unordered_map<std::string, Callable> _external_functions;
std::vector<InkValue> _external_value_storage;  // RAII storage for return values

// Bridge function (called by InkCPP when Ink invokes external function)
ink::runtime::value _external_function_bridge(
    const std::string& name,
    size_t argc,
    const ink::runtime::value* argv);
```

**Key Implementation Details:**

1. **Binding Process:**
   - `bind_external_function()` stores Callable in `_external_functions` map
   - Registers lambda with InkCPP that calls `_external_function_bridge()`
   - Lambda captures `this` and `func_name` to bridge to GDScript

2. **Argument Order:**
   - **CRITICAL:** InkCPP passes arguments in REVERSE order (stack-based)
   - Must reverse arguments before passing to Callable:
   ```cpp
   for (int i = argc - 1; i >= 0; i--) {
       args.push_back(InkUtils::ink_value_to_variant(argv[i]));
   }
   ```

3. **Return Value Handling:**
   - All return types handled uniformly via `InkValue` wrapper
   - Store InkValue in `_external_value_storage` to keep strings alive:
   ```cpp
   _external_value_storage.push_back(InkUtils::variant_to_ink_value(result));
   return _external_value_storage.back().get();
   ```
   - Storage cleared after `continue_story()` and `continue_story_maximally()` complete
   - No special-case string handling needed - RAII manages lifetime automatically

4. **Type Support:**
   - **Parameters:** bool, int, float, string
   - **Returns:** bool, int, float, string, void/null
   - Uses `InkUtils::ink_value_to_variant()` and `variant_to_ink_value()` for conversions

5. **Error Handling:**
   - Unbound functions log error and return null value
   - Exceptions caught and logged
   - Story continues executing even with errors

**Example Usage:**
```cpp
// GDScript side
story.bind_external_function("get_player_name", func(): return "Hero")
story.bind_external_function("add", func(a, b): return a + b)
story.bind_external_function("concat", func(s1, s2): return str(s1) + str(s2))

// Ink side
EXTERNAL get_player_name()
EXTERNAL add(a, b)
EXTERNAL concat(s1, s2)

Your name is: {get_player_name()}
Math: {add(5, 3)}
String: {concat("Hello", " World")}
```

**Common Pitfalls:**
- Forgetting to reverse arguments → functions receive parameters backwards
- Binding after story starts → functions not registered in time

## 5. Build System

### ⚠️ ALWAYS USE SCRIPTS - See Section 2

**Recommended workflow (uses permitted scripts):**
```bash
# Build for Godot 4.4 (incremental)
./scripts/target-build.sh 4.4

# Build with clean (after dependency updates)
./scripts/target-build.sh 4.4 --clean

# Create release package
./scripts/target-release.sh 4.4

# Install to demo and test
./scripts/validate-setup.sh 4.4
./scripts/validate-run.sh
```

### Manual CMake Commands (Advanced/Debugging Only)

**Not recommended** - Direct cmake commands require workarounds for permissions. Use scripts instead.

<details>
<summary>Manual Build Flow (click to expand)</summary>

```bash
# 1. Configure (specify Godot version) - uses version-specific directory
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4

# 2. Build
cmake --build build/4.4 --config Release -j 4

# 3. Create distribution package
cmake --build build/4.4 --target release

# 4. Output locations:
# - Binary: build/4.4/libgodot_ink.4.4.{platform}.template_release.*
# - Package: release/godot-ink-0.1.0-godot4.4-{platform}.zip

# 5. Testing with demo (manual copy):
unzip release/godot-ink-*.zip -d demo/addons/
godot --path demo
```

**Why scripts are better:**
- Handle cleaning automatically
- Validate inputs
- Color-coded output
- Error handling built-in
- No permission issues

</details>

### Version Management

**Switching Godot versions (use scripts):**
```bash
# Build for 4.4 (uses build/4.4/ directory)
./scripts/target-build.sh 4.4

# Build for 4.5 (uses build/4.5/ directory)
./scripts/target-build.sh 4.5

# Switch back to 4.4 - FAST! (seconds, not minutes)
./scripts/target-build.sh 4.4

# Force clean rebuild if needed
./scripts/target-build.sh 4.4 --clean
```

**Performance:**
- First build: ~5-10 minutes (builds dependencies)
- Switching versions: ~2-4 seconds (no rebuild needed)
- Incremental rebuild: ~8-15 seconds (only changed files)

<details>
<summary>Manual version switching (not recommended)</summary>

```bash
# Version-specific directory - no cleaning needed
cmake -S . -B build/4.4 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4
cmake --build build/4.4 --config Release
cmake --build build/4.4 --target release

# Switch to 4.5 - uses separate directory
cmake -S . -B build/4.5 -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.5
cmake --build build/4.5 --config Release
```

</details>

**Submodule organization:**
- `libs/godot/godot-cpp-4.4/` - Godot-CPP 4.4 bindings
- `libs/godot/godot-cpp-4.5/` - Godot-CPP 4.5 bindings
- `libs/inkcpp/` - InkCPP runtime and compiler

CMake automatically selects the correct godot-cpp version based on GODOT_VERSION.

### CMake Options

**InkCPP Settings (always set these):**
```cmake
set(INKCPP_PY OFF CACHE BOOL "Disable Python bindings" FORCE)
set(INKCPP_C OFF CACHE BOOL "Disable C bindings" FORCE)
set(INKCPP_TEST OFF CACHE BOOL "Disable tests" FORCE)
```

**Build Types:**
- `Release` → template_release (optimized, no debug symbols)
- `Debug` → template_debug (debug symbols, no optimization)

### Platform Detection
```cmake
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(GODOT_PLATFORM "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(GODOT_PLATFORM "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(GODOT_PLATFORM "macos")
endif()
```

### Version Management

**Output naming pattern:**
```
libgodot_ink.{GODOT_VERSION}.{PLATFORM}.{BUILD_TYPE}.{ARCH}{EXT}
```

Example: `libgodot_ink.4.4.macos.template_release.framework`

**When updating Godot version:**
1. Update submodule: `cd godot-cpp-4.4 && git checkout <version>`
2. Update CMakeLists.txt: `set(GODOT_VERSION "4.2")`
3. Update gd-ink-native.gdextension: `compatibility_minimum = 4.2`
4. Update output paths in CMakeLists.txt
5. Rebuild from scratch

### Adding New Source Files

**After creating new .cpp/.h files:**
```bash
# MUST reconfigure CMake (GLOB_RECURSE is configure-time, not build-time)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

**Alternative:** Replace GLOB_RECURSE with explicit file list (better practice).

## 6. Testing

### Test Files

**demo/tests/test_basic.gd** - GDScript test suite
- Tests: loading, continuation, choices, tags, variables
- Pattern: Create InkStory, load JSON, assert expected behavior

**demo/examples/hello.ink.json** - Simple test story
- Basic continuation, choices, tags, variables
- Use for initial validation

### Running Tests

**From Godot editor:**
1. Open demo project: `godot --path demo`
2. Open `demo/tests/test_basic.gd`
3. Run the scene
4. Check Output panel

**From command line:**
```bash
cd /path/to/godot-ink-native
godot --headless --path demo --script tests/test_basic.gd
```

**Expected output:**
```
=== Godot Ink Native - Basic Test Suite ===
[TEST] Story Loading
  ✓ Story loaded successfully
[TEST] Story Continuation
  ✓ Story continuation works
...
```

### Verification Steps

1. **Binary exists:** Check `demo/addons/gd-ink-native/bin/` for platform-specific output
2. **Binary size:** Should be ~1-2MB (macOS framework ~1.2MB)
3. **Extension loads:** No errors in Godot console about missing extension
4. **Classes available:** InkStory and InkChoice visible in Create Node dialog
5. **Tests pass:** All assertions in test_basic.gd succeed

## 7. Common Pitfalls & Solutions

### Build Issues

**Problem:** Linker errors "undefined symbols" after adding new class
**Solution:** Reconfigure CMake: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
**Why:** GLOB_RECURSE only runs at configure time, not build time

**Problem:** CMake can't find godot-cpp or inkcpp
**Solution:** Check submodules: `git submodule update --init --recursive`

**Problem:** Binary outputs to wrong location
**Solution:** Check `CMAKE_LIBRARY_OUTPUT_DIRECTORY` in CMakeLists.txt

**Problem:** Build fails with "missing header"
**Solution:** Check include paths: godot-cpp and inkcpp headers must be visible

### Code Issues

**Problem:** GDCLASS compilation errors about Wrapped type
**Cause:** Forward-declared inkcpp typedefs instead of including headers
**Solution:** Always include `<story.h>` and `<types.h>` directly

**Problem:** Segfault when accessing runner/globals
**Cause:** Forgot to check if objects are valid (null check)
**Solution:** Always check: `if (!_runner) return;`

**Problem:** Choices not updating
**Cause:** Forgot to call `_update_choices()` after story operations
**Solution:** Call after: `continue_story()`, `choose_choice_index()`, `reset()`

**Problem:** Story binary not loading
**Cause:** `_binary_data` was freed or went out of scope
**Solution:** Store binary in class member, pass `false` to `from_binary()` free parameter

### String Handling

**InkValue RAII Wrapper:**

The codebase uses an `InkValue` wrapper class to solve the string lifetime problem when converting Godot Variant to `ink::runtime::value`.

**The Problem:**
`ink::runtime::value` only stores a `const char*` pointer. The actual string data must remain valid until InkCPP copies it into its internal `string_table`.

**The Solution:**
```cpp
// InkValue owns the CharString, keeping it alive via RAII
auto ink_value = InkUtils::variant_to_ink_value(variant);
_globals->set(name, ink_value.get());
// CharString stays valid until ink_value destroyed (end of scope)
```

**Implementation:**
- `InkValue` class stores both `ink::runtime::value` and `CharString`
- Created via factory function: `InkUtils::variant_to_ink_value()`
- Automatic lifetime management - no manual storage needed
- Eliminates scattered "if string" checks

**Usage Patterns:**
```cpp
// Local scope - automatic cleanup
void set_variable(const String& name, const Variant& value) {
    auto ink_value = InkUtils::variant_to_ink_value(value);
    _globals->set(name, ink_value.get());
    // ink_value destroyed after set() completes - safe
}

// External functions - stored until processing complete
ink::runtime::value _external_function_bridge(...) {
    _external_value_storage.push_back(InkUtils::variant_to_ink_value(result));
    return _external_value_storage.back().get();
    // Storage cleared after continue_story() completes
}
```

## 8. Future Extensions

### Not Yet Implemented

- **InkList wrapper:** Complex list operations (add/remove/contains)
- **State save/load:** Serialize/deserialize story state
- **Variable observers:** Callbacks when variables change

### Implemented Features

- ✅ **External functions:** Bind GDScript functions callable from Ink (v0.1.0)
  - Supports arbitrary argument counts
  - Type conversion for bool, int, float, string
  - Lookahead safety control
  - Full error handling

### Adding New Wrapper Classes

**Template:**
```cpp
// ink_new_class.h
#ifndef INK_NEW_CLASS_H
#define INK_NEW_CLASS_H

#include <godot_cpp/classes/ref_counted.hpp>
// Include inkcpp headers as needed

using namespace godot;

class InkNewClass : public RefCounted {
    GDCLASS(InkNewClass, RefCounted)

private:
    // Native inkcpp object or data

protected:
    static void _bind_methods();

public:
    InkNewClass();
    ~InkNewClass();

    // Public API methods
};

#endif
```

**Steps:**
1. Create header + implementation files in `src/`
2. Implement constructor, destructor, `_bind_methods()`
3. Add to `register_types.cpp`: `ClassDB::register_class<InkNewClass>()`
4. Reconfigure CMake
5. Rebuild
6. Test in Godot

## 9. Quick Reference

### New Class Template

```cpp
// ink_example.h
#ifndef INK_EXAMPLE_H
#define INK_EXAMPLE_H

#include <godot_cpp/classes/ref_counted.hpp>

using namespace godot;

class InkExample : public RefCounted {
    GDCLASS(InkExample, RefCounted)

private:
    int _data;

protected:
    static void _bind_methods();

public:
    InkExample();
    ~InkExample();

    void set_data(int value);
    int get_data() const;
};

#endif
```

```cpp
// ink_example.cpp
#include "ink_example.h"
#include <godot_cpp/core/class_db.hpp>

InkExample::InkExample() : _data(0) {
}

InkExample::~InkExample() {
}

void InkExample::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_data", "value"), &InkExample::set_data);
    ClassDB::bind_method(D_METHOD("get_data"), &InkExample::get_data);

    ADD_PROPERTY(PropertyInfo(Variant::INT, "data"), "set_data", "get_data");
}

void InkExample::set_data(int value) {
    _data = value;
}

int InkExample::get_data() const {
    return _data;
}
```

### Complete Rebuild Commands (⚠️ USE SCRIPTS - See Section 2)

```bash
# Incremental build (fast)
./scripts/target-build.sh 4.4
./scripts/target-release.sh 4.4
./scripts/validate-setup.sh 4.4
./scripts/validate-run.sh

# Clean build (after dependency updates)
./scripts/target-build.sh 4.4 --clean
./scripts/target-release.sh 4.4
```

### Switch Godot Version (⚠️ USE SCRIPTS - See Section 2)

```bash
# Version-specific directories - no cleaning needed
./scripts/target-build.sh 4.4  # Build for 4.4 (uses build/4.4/)
./scripts/target-build.sh 4.5  # Build for 4.5 (uses build/4.5/)
./scripts/target-build.sh 4.4  # Switch back - FAST! (seconds)
```

### Quick Test (⚠️ USE SCRIPTS - See Section 2)

```bash
# Recommended workflow
./scripts/validate-setup.sh 4.4
./scripts/validate-run.sh
```

### Debug Build (⚠️ USE SCRIPTS - See Section 2)

```bash
# Debug build with scripts
./scripts/target-build.sh 4.4 Debug

# Scripts support both Release and Debug
```

## 10. Development Scripts

**⚠️ REQUIRED WORKFLOW** - All build/test operations must use these scripts. Direct cmake/git commands are restricted and require special permissions. See Section 2 for complete details.

### Available Scripts

**Build & Release:**
- `build-version.sh <version> [build_type] [--clean]` - Configure and build for specific Godot version (incremental by default)
- `release-version.sh <version>` - Build and create release package
- `release-all.sh` - Build and release for all supported versions

**Dependency Management:**
- `lib-update-godot.sh` - Update godot-cpp submodules to latest stable branches (warns to use --clean)
- `lib-update-ink.sh` - Update inkcpp submodule to latest stable tag (warns to use --clean)
- `lib-update-all.sh` - Update all dependency submodules (warns to use --clean)

**Testing:**
- `validate-run.sh` - Run demo project tests using Godot
- `validate-setup.sh [version]` - Extract release package into demo/addons/ink

### Common Script Workflows

**Quick build and test:**
```bash
# Build, package, and test for Godot 4.4
./scripts/target-build.sh 4.4
./scripts/target-release.sh 4.4
./scripts/validate-setup.sh 4.4
./scripts/validate-run.sh
```

**Release all versions:**
```bash
# Build packages for all Godot versions
./scripts/release-all.sh

# Output in release/:
# - godot-ink-0.1.0-godot4.4-macos.zip
# - godot-ink-0.1.0-godot4.4-macos.zip
```

**Update dependencies:**
```bash
# Update all submodules to latest
./scripts/lib-update-all.sh

# Commit changes
git add libs/
git commit -m "Update dependency submodules"
```

### Environment Variables

**GODOT_APP** - Path to Godot executable (required for `validate-run.sh`):
```bash
# Set for current session
export GODOT_APP=/Applications/Godot.app/Contents/MacOS/Godot
./scripts/validate-run.sh

# Or set permanently in ~/.bashrc or ~/.zshrc
echo 'export GODOT_APP=/path/to/godot' >> ~/.bashrc
```

### Script Features

All scripts include:
- Color-coded output (blue=info, green=success, yellow=warning, red=error)
- `-h` or `--help` flag for usage information
- Input validation before proceeding
- Error handling (`set -e` - exit on error)
- Verbose progress messages

### See Also

For detailed script documentation, see [scripts/README.md](scripts/README.md).

---

## Summary Checklist

**Before committing code:**
- [ ] Follows naming conventions (PascalCase classes, snake_case methods)
- [ ] Includes copyright header
- [ ] Public methods have Doxygen comments
- [ ] Memory management is clear (who owns what)
- [ ] Null checks before accessing pointers
- [ ] `_bind_methods()` registers all public API
- [ ] CMake reconfigured if new files added
- [ ] Builds without errors
- [ ] Tested in Godot

**Before releasing:**
- [ ] All platforms build successfully
- [ ] Test suite passes
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated (CMakeLists.txt, .gdextension)

---

*This document is for LLM reference. For user-facing documentation, see README.md and QUICKSTART.md.*
