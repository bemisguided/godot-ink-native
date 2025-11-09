# TODO - Godot Ink Native

This document tracks known issues, planned improvements, and technical debt for the Godot Ink Native extension.

## Critical Bugs

Currently no critical bugs blocking core functionality.

## Important Features

## Code Quality & Refactoring


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
- ✅ Refactored InkStory::load_story() method with helper functions (src/ink_story.cpp:100-216)
