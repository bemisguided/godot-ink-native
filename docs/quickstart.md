# Quick Start Guide - Godot Ink Native

## About This Guide

This guide provides detailed instructions for building, testing, and using the godot-ink-native extension.

## Building

### Prerequisites

- CMake 3.21+
- C++17 compiler (GCC, Clang, or MSVC)
- Godot 4.4+

### Build Commands

```bash
# Configure (choose Godot version: 4.4 or 4.5)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4

# Build
cmake --build build --config Release -j 4

# Create release package
cmake --build build --target release
```

The output will be:
- **Binary:** `build/libgodot_ink.4.4.{platform}.template_release.*`
- **Package:** `release/godot-ink-0.1.0-godot4.4-{platform}.zip`

### Switching Godot Versions

To build for a different Godot version:

```bash
# Clean previous build
rm -rf build

# Configure for Godot 4.5
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.5
cmake --build build --config Release
cmake --build build --target release
```

**Note:** Each Godot version uses its own submodule in `libs/godot/godot-cpp-{version}/`.

## Testing

### Testing with Demo

1. **Copy addon to demo:**
   ```bash
   # Extract release package
   unzip release/godot-ink-*.zip -d demo/addons/

   # Or manually copy:
   # - addon/ink.gdextension → demo/addons/ink/
   # - build/libgodot_ink.* → demo/addons/ink/bin/
   ```

2. **Open demo project:**
   ```bash
   godot --path demo
   ```

   Check the Output panel for:
   - No errors about missing extension
   - "InkStory" and "InkChoice" classes should be available

3. **Run tests:**
   ```bash
   godot --headless --path demo --script tests/test_basic.gd
   ```

Expected output:
```
=== Godot Ink Native - Basic Test Suite ===
[TEST] Story Loading
  ✓ Story loaded successfully
[TEST] Story Continuation
  ✓ Story continuation works
[TEST] Choices
  ✓ Choices work correctly
...
```

## Basic Usage

### Create and Load a Story

```gdscript
extends Node

func _ready():
    # Create story instance
    var story = InkStory.new()

    # Load from JSON file
    var file = FileAccess.open("res://story.ink.json", FileAccess.READ)
    var json_content = file.get_as_text()
    file.close()

    # Load into story (compiles automatically)
    if not story.load_story_json(json_content):
        print("Failed to load story!")
        return

    # Continue the story
    continue_story(story)

func continue_story(story: InkStory):
    # Read all available content
    while story.can_continue():
        var text = story.continue_story()
        print(text)

    # Show choices
    show_choices(story)

func show_choices(story: InkStory):
    var choices = story.get_current_choices()

    if choices.is_empty():
        print("Story ended")
        return

    for choice in choices:
        print("[%d] %s" % [choice.index, choice.text])

    # Select first choice (for example)
    story.choose_choice_index(0)
    continue_story(story)
```

### Working with Variables

```gdscript
# Set a variable
story.set_variable("player_name", "Alice")
story.set_variable("health", 100)

# Get a variable
var name = story.get_variable("player_name")
var health = story.get_variable("health")

print("Player: %s, Health: %d" % [name, health])
```

### Working with Tags

```gdscript
# Continue story
var text = story.continue_story()

# Get tags for current line
var tags = story.get_current_tags()
for tag in tags:
    print("Tag: %s" % tag)

# Get global tags (from top of story)
var global_tags = story.get_global_tags()
```

### Navigation

```gdscript
# Jump to a specific knot
if story.choose_path_string("chapter2.intro"):
    print("Navigated to chapter 2!")
```

## API Reference

### InkStory Class

#### Loading Methods
- `bool load_story(String file_path)` - Load story from file (supports `.json`, `.ink.json`, `.inkj`, `.inkb`)
- `bool load_story_json(String json_content)` - Load and compile JSON story from string
- `bool load_story_binary(PackedByteArray data)` - Load pre-compiled binary from memory
- `void reset()` - Reset story to beginning
- `bool is_loaded()` - Check if story is loaded

**Supported File Formats:**
- `.ink.json` - Standard inklecate output (recommended)
- `.json` - Plain JSON format
- `.inkj` - Custom JSON format
- `.inkb` - Pre-compiled binary format

#### Execution Methods
- `String continue_story()` - Get next line
- `String continue_story_maximally()` - Get all text until choice/end
- `bool can_continue()` - Check if more content available

#### Choice Methods
- `Array get_current_choices()` - Get array of InkChoice objects
- `int get_current_choice_count()` - Get choice count
- `void choose_choice_index(int index)` - Select a choice
- `bool choose_path_string(String path)` - Navigate to knot/stitch

#### Variable Methods
- `Variant get_variable(String name)` - Get variable value
- `void set_variable(String name, Variant value)` - Set variable value

#### Tag Methods
- `PackedStringArray get_current_tags()` - Get line tags
- `PackedStringArray get_global_tags()` - Get global tags
- `PackedStringArray get_knot_tags()` - Get knot/stitch tags

### InkChoice Class

#### Properties
- `int index` - Choice index (readonly)
- `String text` - Display text (readonly)
- `PackedStringArray tags` - Choice tags (readonly)

#### Methods
- `int get_index()` - Get choice index
- `String get_text()` - Get display text
- `PackedStringArray get_tags()` - Get tags
- `bool has_tags()` - Check if choice has tags

## Troubleshooting

### Extension Not Loading

1. Check that the binary exists in `demo/addons/ink/bin/`
2. Verify `demo/addons/ink/ink.gdextension` matches your platform
3. Check Godot console for error messages
4. Try rebuilding: `cmake --build build --clean-first`

### Compilation Errors

If you see Ink compilation errors:
- Verify your Ink JSON is valid (use inklecate to validate)
- Check the error messages in Godot console
- Test with the provided `hello.ink.json` first

### Runtime Errors

- Check that story is loaded: `story.is_loaded()`
- Verify choice indices are valid before calling `choose_choice_index()`
- Make sure to call `continue_story()` before checking choices

## Further Reading

- [README.md](README.md) - Project overview and installation
- [CHANGELOG.md](CHANGELOG.md) - Version history and planned features
- [CLAUDE.md](CLAUDE.md) - Development reference for LLM assistance
- [Official Ink Documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md) - Learn Ink syntax

## Current Limitations

- Ink Lists are not yet wrapped (use simple types for now)
- External functions not yet supported
- State save/load not yet implemented
- Variable observation callbacks not yet implemented

These features will be added in future versions.
