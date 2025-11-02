# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for multiple file extensions: `.json`, `.ink.json`, `.inkj`, and `.inkb`
  - Improved compatibility with standard Ink workflow
  - No need to rename inklecate output files

### Planned
- InkList wrapper for Ink list operations
- External function binding (call GDScript from Ink)
- State save/load functionality
- Variable observation callbacks
- Multi-platform CI/CD pipeline

---

## [0.1.0] - 2025-01-XX

### Added
- **InkStory class** - Main interface for running Ink stories
  - `load_story_json()` - Load and compile Ink JSON stories
  - `load_story_binary()` - Load pre-compiled binary stories
  - `continue_story()` - Get next line of story text
  - `continue_story_maximally()` - Get all text until choice or end
  - `can_continue()` - Check if more content is available
  - `get_current_choices()` - Get available choices as array
  - `choose_choice_index()` - Select a choice by index
  - `choose_path_string()` - Navigate to specific knot/stitch
  - `get_variable()` / `set_variable()` - Get/set story variables (int, float, bool, string)
  - `get_current_tags()` - Get tags for current line
  - `get_global_tags()` - Get global story tags
  - `get_knot_tags()` - Get tags for current knot/stitch
  - `reset()` - Reset story to beginning
  - `is_loaded()` - Check if story is loaded

- **InkChoice class** - Wrapper for story choices
  - `index` property - Choice index
  - `text` property - Display text
  - `tags` property - Array of choice tags
  - `has_tags()` - Check if choice has tags

- **Build System**
  - Pure CMake build system
  - Cross-platform support (Windows, Linux, macOS)
  - Automatic submodule building (godot-cpp, inkcpp)
  - Platform-specific output naming
  - macOS framework bundle support

- **Demo Project**
  - Example Ink story (`demo/examples/hello.ink.json`)
  - Comprehensive test suite (`demo/tests/test_basic.gd`)
  - GDExtension configuration (`demo/addons/ink/ink.gdextension`)

- **Documentation**
  - README.md - Project overview and quick start
  - QUICKSTART.md - Detailed usage guide
  - CHANGELOG.md - This file
  - CLAUDE.md - LLM development reference
  - LICENSE - MIT license

### Technical Details
- Wraps inkcpp library v0.1.9 (JBenda)
- Uses godot-cpp 4.4+ bindings
- Supports Godot 4.4 and 4.5
- Automatic Ink JSON to binary compilation
- GDScript-friendly API with snake_case naming
- RefCounted memory management
- Tag-based version pinning for inkcpp dependency

### Known Limitations
- Ink Lists not yet wrapped (use simple types)
- External functions not yet supported
- State persistence not yet implemented
- String variables may have lifetime issues (needs testing)

---

## Development History

This project was developed through the following phases:
1. Build system selection (pure CMake approach)
2. InkCPP API analysis and architecture planning
3. Core wrapper implementation (InkChoice, InkStory)
4. Compilation and testing
5. Documentation and cleanup

Initial MVP implementation completed October 2025.
