# TODO - Godot Ink Native

This document tracks known issues, planned improvements, and technical debt for the Godot Ink Native extension.

## Critical Bugs

Currently no critical bugs blocking core functionality.

## Important Features

### 2. Support .json Extension for Ink Stories
**Priority:** Medium
**Status:** Not Started

- **Issue:** Extension only recognizes `.inkj` and `.inkb` extensions, but standard Ink export uses `.json` or `.ink.json`
- **Location:** `src/ink_story.cpp:92` - extension check
- **Action Items:**
  - [ ] Add support for `.json` extension (treat as `.inkj`)
  - [ ] Add support for `.ink.json` extension
  - [ ] Update documentation with supported formats
  - [ ] Add test cases for different extensions
- **Rationale:** Better compatibility with standard Ink workflow

### 3. Integrate inklecate into Build System
**Priority:** Medium
**Status:** Design Phase

- **Issue:** Users must manually compile `.ink` → `.ink.json` using external inklecate tool
- **Location:** Build system (CMakeLists.txt) and potentially addon
- **Options to Consider:**
  - **Option A:** Bundle pre-compiled inklecate binaries in releases (simplest for users)
  - **Option B:** Add inklecate as build dependency using CMake FetchContent/ExternalProject
  - **Option C:** Include inklecate in addon package for runtime compilation
- **Action Items:**
  - [ ] Research inklecate distribution/licensing
  - [ ] Evaluate cross-platform binary distribution (Windows, Linux, macOS, ARM)
  - [ ] Decide on integration approach
  - [ ] Implement chosen solution
  - [ ] Update documentation
- **Rationale:** Streamlines workflow, reduces external dependencies for users

## Code Quality & Refactoring

### 4. Refactor InkStory::load_story() Method
**Priority:** Medium
**Status:** Not Started

- **Issue:** Current implementation has nested conditionals and duplicated code
- **Location:** `src/ink_story.cpp:90-149`
- **Problems:**
  - Duplicated `ProjectSettings::globalize_path()` calls
  - Nested if/else for extension handling
  - Mixed concerns (path resolution, compilation, loading)
- **Action Items:**
  - [ ] Extract path resolution helper method
  - [ ] Consider separate methods: `load_inkj()`, `load_inkb()`, `load_json()`
  - [ ] Simplify main `load_story()` to dispatch to appropriate loader
  - [ ] Add inline documentation
- **Rationale:** Improves maintainability, readability, and testability

### 5. DRY Pass - Eliminate Code Duplication
**Priority:** Low
**Status:** Not Started

- **Issue:** General code review needed for duplicated patterns
- **Known Duplication:**
  - Path resolution code (ProjectSettings singleton, globalize_path)
  - Error handling patterns
  - CharString UTF-8 conversion patterns
- **Action Items:**
  - [ ] Review all source files in `src/`
  - [ ] Extract common utilities to helper file
  - [ ] Standardize error reporting patterns
  - [ ] Add code comments where complex logic exists
- **Rationale:** Reduces maintenance burden, easier to fix bugs in one place

## Test Issues (Non-Blocking)

### 6. get_current_text() Returns Empty String
**Priority:** Low
**Status:** Investigation Needed

- **Issue:** `InkStory::get_current_text()` returns empty string, but `continue_story()` return value works correctly
- **Location:** `src/ink_story.cpp` - `get_current_text()` implementation
- **Test:** `demo/tests/test_basic.gd:44` - prints empty story text
- **Action Items:**
  - [ ] Investigate if `get_current_text()` is implemented
  - [ ] Check if inkcpp API provides this functionality
  - [ ] Either implement or update documentation/tests
- **Impact:** Test displays empty text but assertions pass - cosmetic issue only

### 7. Variable Test Fails for Undefined Variables
**Priority:** Low
**Status:** Expected Behavior?

- **Issue:** `set_variable("test_var", 42)` then `get_variable("test_var")` returns null
- **Location:** Test at `demo/tests/test_basic.gd:105`
- **Question:** Is this expected Ink behavior? Variables may need to be declared in story first
- **Action Items:**
  - [ ] Research Ink variable behavior - can arbitrary variables be set?
  - [ ] Update test story to declare `test_var` if needed
  - [ ] Or update test to match expected behavior
  - [ ] Document variable behavior in README
- **Impact:** Test shows warning but doesn't fail - informational only

## Documentation Improvements

### 8. Document Compilation Workflow
**Priority:** Low
**Status:** Partially Done

- **Current State:** README mentions inklecate but assumes user knows the workflow
- **Action Items:**
  - [ ] Add detailed "Working with Ink Files" section to README
  - [ ] Document: `.ink` → inklecate → `.ink.json` → GDExtension → `.inkb`
  - [ ] Provide inklecate installation instructions
  - [ ] Add common troubleshooting scenarios
- **Rationale:** Reduces user confusion, especially for Ink newcomers

---

## Completed

- ✅ Extension loads and registers classes correctly
- ✅ Story loading from .inkj files works
- ✅ Story continuation and text output works
- ✅ Choice system functioning correctly
- ✅ Stream-based JSON compilation implemented
- ✅ GDExtension editor-first workflow documented
- ✅ Demo tests updated and functional
