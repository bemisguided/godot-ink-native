# API Reference

Comprehensive API reference for godot-ink-cpp, a GDExtension wrapper for the Ink narrative scripting language.

---

## Class: InkStory

**Inherits:** RefCounted < Object

### Brief Description

Main interface for loading and executing Ink stories in Godot.

### Description

The `InkStory` class provides the primary interface for integrating Ink narrative content into Godot projects. It handles story loading, execution, choice management, and navigation through compiled Ink stories (.inkj, .ink.json, or .ink.inkb files).

### Properties

None.

### Methods

#### Story Loading

| Return Type | Method |
|-------------|--------|
| bool | **load_story** ( String story_path ) |
| void | **reset_state** ( ) |
| bool | **is_loaded** ( ) const |

#### Story Execution

| Return Type | Method |
|-------------|--------|
| String | **continue_story** ( ) |
| String | **continue_story_maximally** ( ) |
| bool | **can_continue** ( ) const |
| String | **get_current_text** ( ) const |

#### Choices

| Return Type | Method |
|-------------|--------|
| Array | **get_current_choices** ( ) const |
| int | **get_current_choice_count** ( ) const |
| void | **choose_choice_index** ( int index ) |
| bool | **choose_path_string** ( String path ) |

#### Tags

| Return Type | Method |
|-------------|--------|
| PackedStringArray | **get_current_tags** ( ) const |
| PackedStringArray | **get_global_tags** ( ) const |
| PackedStringArray | **get_knot_tags** ( ) const |

#### Variables

| Return Type | Method |
|-------------|--------|
| Variant | **get_variable** ( String name ) const |
| void | **set_variable** ( String name, Variant value ) |

#### Navigation

| Return Type | Method |
|-------------|--------|
| String | **get_current_path** ( ) const |

---

## Method Descriptions

### Story Loading Methods

---

#### bool **load_story** ( String story_path )

Loads an Ink story from a compiled file. Accepts `.inkj`, `.ink.json`, or `.ink.inkb` file formats. Returns `true` if loading succeeded, `false` otherwise.

**Parameters:**
- `story_path` (String): Resource path to the compiled Ink story file

**Returns:** bool - `true` on success, `false` on failure

---

#### void **reset_state** ( )

Resets the story to its initial state. Clears the call stack and returns execution to the beginning of the story. Does not reset variable values.

---

#### bool **is_loaded** ( ) const

Checks whether a story is currently loaded and ready for execution.

**Returns:** bool - `true` if a story is loaded, `false` otherwise

---

### Story Execution Methods

---

#### String **continue_story** ( )

Advances the story by one line and returns the text content. Call `can_continue()` first to verify more content is available.

**Returns:** String - The next line of story text

---

#### String **continue_story_maximally** ( )

Continues the story until a choice point or end is reached, returning all accumulated text. Equivalent to calling `continue_story()` repeatedly until `can_continue()` returns `false`.

**Returns:** String - All accumulated story text until next choice or end

---

#### bool **can_continue** ( ) const

Checks if the story has more content to display before requiring a choice or reaching the end.

**Returns:** bool - `true` if more content is available, `false` if at a choice point or story end

---

#### String **get_current_text** ( ) const

Returns the cached text from the most recent `continue_story()` or `continue_story_maximally()` call.

**Returns:** String - The last retrieved story text

---

### Choice Methods

---

#### Array **get_current_choices** ( ) const

Returns an array of available choices at the current story position. Each element is an `InkChoice` object.

**Returns:** Array - Array of `InkChoice` objects (empty if no choices available)

---

#### int **get_current_choice_count** ( ) const

Returns the number of choices currently available to the player.

**Returns:** int - Number of available choices

---

#### void **choose_choice_index** ( int index )

Selects a choice by its index. The index corresponds to the `index` property of an `InkChoice` object. After choosing, call `continue_story()` to proceed.

**Parameters:**
- `index` (int): The index of the choice to select (0-based)

---

#### bool **choose_path_string** ( String path )

Jumps to a specific knot or stitch in the story by path string. Path format is `"knot_name"` or `"knot_name.stitch_name"`.

**Parameters:**
- `path` (String): The path to the target knot or stitch

**Returns:** bool - `true` if navigation succeeded, `false` if path is invalid

---

### Tag Methods

---

#### PackedStringArray **get_current_tags** ( ) const

Returns tags associated with the current line of content. Tags are metadata attached to lines in the Ink source (e.g., `# mood: tense`).

**Returns:** PackedStringArray - Tags for the current line

---

#### PackedStringArray **get_global_tags** ( ) const

Returns global tags defined at the top of the Ink story file.

**Returns:** PackedStringArray - Global story tags

---

#### PackedStringArray **get_knot_tags** ( ) const

Returns tags associated with the current knot (section) of the story.

**Returns:** PackedStringArray - Tags for the current knot

---

### Variable Methods

---

#### Variant **get_variable** ( String name ) const

Retrieves the value of a story variable. Returns the variable value as a Variant (int, float, bool, or String). Returns null if the variable doesn't exist.

**Parameters:**
- `name` (String): The name of the variable to retrieve

**Returns:** Variant - The variable value, or null if not found

---

#### void **set_variable** ( String name, Variant value )

Sets the value of a story variable. Supports int, float, bool, and String types.

**Parameters:**
- `name` (String): The name of the variable to set
- `value` (Variant): The new value (int, float, bool, or String)

---

### Navigation Methods

---

#### String **get_current_path** ( ) const

Returns the current path in the story as a hash string. Note: This returns a hash representation, not a human-readable path.

**Returns:** String - Current path hash as a string

---

## Class: InkChoice

**Inherits:** RefCounted < Object

### Brief Description

Represents a single choice option in an Ink story.

### Description

The `InkChoice` class encapsulates data about a choice presented to the player. It provides the display text, index for selection, and any associated tags.

### Properties

| Type | Property | Default |
|------|----------|---------|
| int | **index** | 0 |
| String | **text** | `""` |
| PackedStringArray | **tags** | `[]` |

### Methods

| Return Type | Method |
|-------------|--------|
| int | **get_index** ( ) const |
| String | **get_text** ( ) const |
| PackedStringArray | **get_tags** ( ) const |
| bool | **has_tags** ( ) const |

---

## Method Descriptions

### int **get_index** ( ) const

Returns the index of this choice. Use this value with `InkStory.choose_choice_index()`.

**Returns:** int - The choice index

---

### String **get_text** ( ) const

Returns the display text for this choice.

**Returns:** String - The choice text to show the player

---

### PackedStringArray **get_tags** ( ) const

Returns tags associated with this choice.

**Returns:** PackedStringArray - Tags attached to this choice

---

### bool **has_tags** ( ) const

Checks if this choice has any associated tags.

**Returns:** bool - `true` if tags exist, `false` otherwise

---

## Class: InkCompiler

**Inherits:** RefCounted < Object

### Brief Description

Utility class for compiling Ink JSON files to binary format.

### Description

The `InkCompiler` class provides static methods for compiling Ink JSON files (`.inkj` or `.ink.json`) into binary format (`.ink.inkb`). Binary files load faster and are recommended for production use.

### Properties

None.

### Methods

| Return Type | Method |
|-------------|--------|
| bool | **compile_json_file** ( String json_res_path, String binary_res_path ) static |

---

## Method Descriptions

### bool **compile_json_file** ( String json_res_path, String binary_res_path ) static

Compiles an Ink JSON file to binary format. This is a static method that can be called directly on the class.

**Parameters:**
- `json_res_path` (String): Resource path to the source JSON file (`.inkj` or `.ink.json`)
- `binary_res_path` (String): Resource path for the output binary file (`.ink.inkb`)

**Returns:** bool - `true` if compilation succeeded, `false` otherwise

**Example:**
```gdscript
var success = InkCompiler.compile_json_file(
    "res://story.ink.json",
    "res://story.ink.inkb"
)
if success:
    print("Compilation successful!")
```

---

## See Also

- [Ink Language Documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md)
- [InkCPP Library](https://github.com/brwarner/inkcpp)
