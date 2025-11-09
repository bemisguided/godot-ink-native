# Godot Ink Native

A high-performance GDExtension that brings the [Ink narrative scripting language](https://github.com/inkle/ink) to Godot 4.4+.

This extension wraps the [inkcpp](https://github.com/JBenda/inkcpp) library, providing native C++ performance for Ink story execution in Godot.

## Features

- **Full Ink Runtime** - Execute Ink stories with complete narrative control
- **Automatic Compilation** - Load Ink JSON files with built-in compilation
- **GDScript-Friendly API** - Snake_case methods for seamless integration
- **Cross-Platform** - Windows, Linux, and macOS support
- **High Performance** - Native C++ implementation
- **Godot 4.4+ Compatible** - Works with Godot 4.4 and later

## What is Ink?

[Ink](https://www.inklestudios.com/ink/) is a powerful narrative scripting language by Inkle Studios, used in acclaimed games like:
- 80 Days
- Heaven's Vault
- Sorcery!

Ink enables branching narratives, choices, variables, and complex story logic.

## Installation

### From Release (Recommended)

1. Download the latest release from the [Releases page](https://github.com/yourusername/godot-ink-native/releases)
2. Extract the `addons/gd-ink-native` folder to your Godot project's `addons/` directory
3. Restart Godot or reload your project
4. The extension will be automatically loaded

### From Source

See the [Building](#building) section below.

## Quick Start

### 1. Prepare Your Ink Story

Compile your `.ink` file to JSON using [inklecate](https://github.com/inkle/ink):

```bash
inklecate story.ink -o story.ink.json
```

The extension supports multiple file formats:
- `.ink.json` - Standard inklecate output (recommended)
- `.json` - Plain JSON format
- `.inkj` - Custom JSON format
- `.inkb` - Pre-compiled binary format

### 2. Load and Run in GDScript

```gdscript
extends Node

var story: InkStory

func _ready():
    # Create story instance
    story = InkStory.new()

    # Load JSON file
    var file = FileAccess.open("res://story.ink.json", FileAccess.READ)
    var json_content = file.get_as_text()
    file.close()

    # Load story (compiles automatically)
    if story.load_story_json(json_content):
        continue_story()
    else:
        print("Failed to load story")

func continue_story():
    # Continue until we need player input
    while story.can_continue():
        var text = story.continue_story()
        print(text)

    # Show choices
    var choices = story.get_current_choices()
    if choices.is_empty():
        print("Story ended")
        return

    for choice in choices:
        print("[%d] %s" % [choice.index, choice.text])

func make_choice(choice_index: int):
    story.choose_choice_index(choice_index)
    continue_story()
```

## Core Classes

### InkStory

The main class for running Ink stories.

**Key Methods:**
- `load_story_json(json: String)` - Load and compile an Ink story
- `continue_story()` - Get next line of text
- `can_continue()` - Check if more content available
- `get_current_choices()` - Get available choices
- `choose_choice_index(index: int)` - Select a choice
- `get_variable(name: String)` - Get story variable
- `set_variable(name: String, value: Variant)` - Set story variable
- `get_current_tags()` - Get tags for current line

### InkChoice

Represents a choice in the story.

**Properties:**
- `index` - Choice index
- `text` - Display text
- `tags` - Array of choice tags

## Documentation

- [QUICKSTART.md](QUICKSTART.md) - Detailed usage guide with examples
- [CLAUDE.md](CLAUDE.md) - Development reference for LLM assistance
- [CHANGELOG.md](CHANGELOG.md) - Version history

For Ink language syntax, see the [official Ink documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md).

## Building

### Requirements

- CMake 3.21 or later
- C++17 compatible compiler (GCC, Clang, or MSVC)
- Git (for submodules)

### Build Steps

```bash
# Clone with submodules
git clone --recursive https://github.com/yourusername/godot-ink-native.git
cd godot-ink-native

# Configure (choose Godot version: 4.4 or 4.5)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4

# Build
cmake --build build --config Release -j 4

# Create release package
cmake --build build --target release

# Output:
# - Binary: build/libgodot_ink.4.4.{platform}.template_release.*
# - Package: release/godot-ink-0.1.0-godot4.4-{platform}.zip
```

### Switching Godot Versions

To build for a different Godot version:

```bash
# Clean and rebuild for Godot 4.4
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DGODOT_VERSION=4.4
cmake --build build --config Release
cmake --build build --target release
```

### Testing with Demo

To test in the demo project:

```bash
# 1. Extract release package to demo
./scripts/test-setup.sh 4.4

# 2. IMPORTANT: Open the project in Godot editor to register the extension
#    GDExtensions in Godot 4.x must be registered via the editor first
godot --editor --path demo

# 3. After the editor opens and loads the project, close it

# 4. Now you can run headless tests
./scripts/test-run.sh
```

**Why the editor step?** Godot 4.x GDExtensions are registered when the project is first opened in the editor. This creates the `.godot/` cache directory with extension metadata. Headless execution relies on this cached data.

### Environment Setup

For testing and running scripts, you may need to configure the path to your Godot executable:

#### Setting GODOT_APP

If `godot` is not in your PATH, set the `GODOT_APP` environment variable:

**macOS:**
```bash
export GODOT_APP=/Applications/Godot.app/Contents/MacOS/Godot
```

**Linux:**
```bash
export GODOT_APP=/path/to/godot
```

**Windows (PowerShell):**
```powershell
$env:GODOT_APP = "C:\Path\To\Godot.exe"
```

**Make it permanent:**

Add the export command to your shell configuration file:
```bash
# For bash
echo 'export GODOT_APP=/path/to/godot' >> ~/.bashrc

# For zsh (macOS default)
echo 'export GODOT_APP=/path/to/godot' >> ~/.zshrc
```

Then reload your shell or run `source ~/.bashrc` (or `~/.zshrc`).

#### Development Scripts

The `scripts/` directory contains convenience wrappers for common development tasks:

```bash
# Quick build and test
./scripts/build-version.sh 4.4          # Build for Godot 4.4
./scripts/test-setup.sh                 # Extract to demo/
./scripts/test-run.sh                   # Run tests (requires GODOT_APP)

# Build releases for all versions
./scripts/release-all.sh

# Update dependencies
./scripts/lib-update-all.sh
```

For detailed script documentation, see [scripts/README.md](scripts/README.md).

## Examples

The `demo/` directory contains a complete example project with:
- Basic story loading and continuation
- Choice handling
- Variable management
- Tag processing

Run the test suite:
```bash
godot --headless --path demo --script tests/test_basic.gd
```

## Current Limitations

This is version 0.1.0 with core functionality. Not yet implemented:
- **Ink Lists** - Use basic types (int, string, bool) for now
- **External Functions** - Cannot bind GDScript functions to be called from Ink
- **State Save/Load** - Cannot save/restore story state

These features are planned for future releases.

## Requirements

- Godot 4.4 or later
- Ink stories in JSON format (compiled with inklecate)
  - Supported formats: `.ink.json`, `.json`, `.inkj`, or `.inkb`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- [Ink](https://github.com/inkle/ink) by Inkle Studios
- [inkcpp](https://github.com/JBenda/inkcpp) by JBenda
- [godot-cpp](https://github.com/godotengine/godot-cpp) by Godot Engine contributors

## Support

- Report bugs on the [Issues page](https://github.com/yourusername/godot-ink-native/issues)
- For Ink language questions, see the [official Ink documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md)
