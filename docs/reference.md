# API Reference

1API reference for `godot-ink-native`, a GDExtension wrapper for the Ink narrative scripting language.

## Class: `InkStory`

**Inherits:** `RefCounted` < `Object`

### Brief Description

Main interface for loading and executing Ink stories in Godot.

### Description

The `InkStory` class provides the primary interface for integrating Ink narrative content into Godot projects. It handles story loading, execution, choice management, and navigation through compiled Ink stories (`.inkj`, `.ink.json`, or `.ink.inkb` files).

### Properties

| Property          | Type          | Access     | Description                          |
| ----------------- | ------------- | ---------- | ------------------------------------ |
| `can_continue`    | `bool`        | Read-only  | Whether the story can continue       |
| `choice_count`    | `int`         | Read-only  | Number of available choices          |
| `current_choices` | `InkChoice[]` | Read-only  | Available choices                    |
| `current_path`    | `String`      | Read-only  | Current path (as hash string)        |
| `current_text`    | `String`      | Read-only  | Last retrieved story text            |
| `global_tags`     | `String[]`    | Read-only  | Global story tags (from top of file) |
| `knot_tags`       | `String[]`    | Read-only  | Tags for the current knot            |
| `loaded`          | `bool`        | Read-only  | Whether a story is currently loaded  |
| `story_path`      | `String`      | Read/Write | Path to the loaded story file        |
| `tags`            | `String[]`    | Read-only  | Tags for the current line            |

### Methods

| Method                                                                                         | Description                                                         |
| ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `bind_external_function ( String name, Callable function, bool lookahead_safe = true ) : void` | Binds a GDScript function or lambda to be callable from Ink.        |
| `choose_choice_index ( int index ) : void`                                                     | Selects a choice by its index.                                      |
| `choose_path_string ( String path ) : bool`                                                    | Navigates to a specific knot or stitch by path string.              |
| `continue_story ( ) : String`                                                                  | Returns the next line of story text.                                |
| `continue_story_maximally ( ) : String`                                                        | Returns all text until the next choice or end.                      |
| `get_variable ( String name ) : Variant`                                                       | Retrieves the value of a story variable.                            |
| `has_choices ( ) : bool`                                                                       | Checks if choices are currently available.                          |
| `has_external_function ( String name ) : bool`                                                 | Checks whether an external function is currently bound.             |
| `has_tags ( ) : bool`                                                                          | Checks if the current line has tags.                                |
| `load_story ( String story_path ) : bool`                                                      | Returns true if the story was loaded successfully, false otherwise. |
| `reset_state ( ) : void`                                                                       | Resets the story to its initial state.                              |
| `set_variable ( String name, Variant value ) : void`                                           | Sets the value of a story variable.                                 |
| `unbind_external_function ( String name ) : void`                                              | Removes a previously bound external function.                       |

## Method Descriptions

#### `bind_external_function ( String name, Callable function, bool lookahead_safe = true ) : void`

Binds a GDScript function or lambda to be callable from Ink. The function will be invoked when the Ink story calls the external function by name.

**Parameters:**
- `name` (String): Name of the external function as declared in Ink (e.g., `"get_player_name"`)
- `function` (Callable): GDScript function or lambda to execute when called from Ink
- `lookahead_safe` (bool): Whether the function is safe for lookahead evaluation (default: `true`)
  - `true`: Function is pure/read-only with no side effects (safe for Ink's lookahead)
  - `false`: Function has side effects and should only be called during actual execution

**Supported Parameter Types:**
- `bool`: Boolean values
- `int`: Integer numbers
- `float`: Floating-point numbers
- `String`: Text strings

**Supported Return Types:**
- `bool`: Boolean values
- `int`: Integer numbers
- `float`: Floating-point numbers
- `String`: Text strings
- `void`/`null`: For functions with no return value

**Example:**

Ink story (`story.ink`):
```ink
EXTERNAL get_player_name()
EXTERNAL roll_dice()
EXTERNAL add(a, b)
EXTERNAL concat(str1, str2)

Your name is: {get_player_name()}
You rolled: {roll_dice()}
Result: {add(5, 3)}
Message: {concat("Hello", " World")}
```

GDScript:
```python
var story = InkStory.new()
story.load_story("res://story.ink.json")

# Zero-argument function
story.bind_external_function("get_player_name", func():
    return "Hero"
)

# Random number (not lookahead safe due to randomness)
story.bind_external_function("roll_dice", func():
    return randi() % 6 + 1
, false)

# Multi-argument function
story.bind_external_function("add", func(a, b):
    return a + b
)

# String concatenation
story.bind_external_function("concat", func(s1, s2):
    return str(s1) + str(s2)
)

# Execute story
var text = story.continue_story_maximally()
print(text)
# Output:
# Your name is: Hero
# You rolled: 4
# Result: 8
# Message: Hello World
```

**Game Integration Example:**
```python
# Access game state from Ink
story.bind_external_function("get_gold", func():
    return GameState.gold
)

story.bind_external_function("has_item", func(item_name):
    return item_name in GameState.inventory
)

# Call game functions with side effects
story.bind_external_function("add_item", func(item_name):
    GameState.inventory.append(item_name)
    print("Added: ", item_name)
, false)  # false = has side effects

story.bind_external_function("play_sound", func(sound_name):
    AudioPlayer.play(sound_name)
, false)
```

**Notes:**
- Functions must be bound BEFORE the story begins executing
- Use `lookahead_safe=false` for functions that:
  - Modify game state
  - Generate random numbers
  - Play audio/visual effects
  - Trigger any side effects
- Functions can be rebound at any time to change behavior



#### `choose_choice_index ( int index ) : void`

Selects a choice by its index. The index corresponds to the `index` property of an `InkChoice` object. After choosing, call `continue_story()` to proceed.

**Parameters:**
- `index` (int): The index of the choice to select (0-based)


#### `choose_path_string ( String path ) : bool`

Jumps to a specific knot or stitch in the story by path string. Path format is `"knot_name"` or `"knot_name.stitch_name"`.

**Parameters:**
- `path` (String): The path to the target knot or stitch

**Returns:** bool - `true` if navigation succeeded, `false` if path is invalid


#### `continue_story ( ) : String`

Advances the story by one line and returns the text content. Check the `can_continue` property first to verify more content is available.

**Returns:** String - The next line of story text


#### `continue_story_maximally ( ) : String`

Continues the story until a choice point or end is reached, returning all accumulated text. Equivalent to calling `continue_story()` repeatedly until the `can_continue` property returns `false`.

**Returns:** String - All accumulated story text until next choice or end


#### `get_variable ( String name ) : Variant`

Retrieves the value of a story variable. Returns the variable value as a Variant (int, float, bool, or String). Returns null if the variable doesn't exist.

**Parameters:**
- `name` (String): The name of the variable to retrieve

**Returns:** Variant - The variable value, or null if not found


#### `has_choices ( ) : bool`

Checks if choices are currently available. Convenience method equivalent to `choice_count > 0`.

**Returns:** bool - `true` if at least one choice is available, `false` otherwise


#### `has_external_function ( String name ) : bool`

Checks whether an external function is currently bound.

**Parameters:**
- `name` (String): Name of the function to check

**Returns:** bool - `true` if the function is bound, `false` otherwise

**Example:**
```python
if not story.has_external_function("get_player_level"):
    story.bind_external_function("get_player_level", func():
        return PlayerData.level
    )
```

#### `has_tags ( ) : bool`

Checks if the current line has tags. Convenience method to check if the `tags` property is non-empty.

**Returns:** bool - `true` if tags exist on the current line, `false` otherwise


#### `load_story ( String story_path ) : bool`

Loads an Ink story from a compiled file. Accepts `.inkj`, `.ink.json`, or `.ink.inkb` file formats. Returns `true` if loading succeeded, `false` otherwise.

**Parameters:**
- `story_path` (String): Resource path to the compiled Ink story file

**Returns:** bool - `true` on success, `false` on failure


#### `reset_state ( ) : void`

Resets the story to its initial state. Clears the call stack and returns execution to the beginning of the story. Does not reset variable values.


#### `set_variable ( String name, Variant value ) : void`

Sets the value of a story variable. Supports int, float, bool, and String types.

**Parameters:**
- `name` (String): The name of the variable to set
- `value` (Variant): The new value (int, float, bool, or String)

External functions allow you to call GDScript code from within Ink stories, enabling powerful integration between game logic and narrative content.


#### `unbind_external_function ( String name ) : void`

Removes a previously bound external function. If the story attempts to call an unbound function, an error will be logged and the story will continue with a null return value.

**Parameters:**
- `name` (String): Name of the function to unbind

**Example:**
```python
# Bind a function
story.bind_external_function("get_score", func(): return player_score)

# Later, unbind it
story.unbind_external_function("get_score")

# Rebind with new implementation
story.bind_external_function("get_score", func(): return new_score_calculation())
```

## Class: `InkChoice`

**Inherits:** `RefCounted` < `Object`

### Brief Description

Represents a single choice option in an Ink story.

### Description

The `InkChoice` class encapsulates data about a choice presented to the player. It provides the display text, index for selection, and any associated tags.

### Properties

| Property | Type       | Access    | Description  |
| -------- | ---------- | --------- | ------------ |
| `index`  | `int`      | Read-only | Choice index |
| `text`   | `String`   | Read-only | Choice text  |
| `tags`   | `String[]` | Read-only | Choice tags  |

### Methods

| Method                | Description                                                                                                     |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| `has_tags ( ) : bool` | Checks if this choice has any associated tags. Convenience method to check if the `tags` property is non-empty. |

### Method Descriptions

#### `has_tags ( ) : bool`

Checks if this choice has any associated tags. Convenience method to check if the `tags` property is non-empty.

**Returns:** bool - `true` if tags exist, `false` otherwise


## Class: `InkCompiler`

**Inherits:** `RefCounted` < `Object`

### Brief Description

Utility class for compiling Ink JSON files to binary format.

### Description

The `InkCompiler` class provides static methods for compiling Ink JSON files (`.inkj` or `.ink.json`) into binary format (`.ink.inkb`). Binary files load faster and are recommended for production use.

### Properties

None.

### Methods

| Method                                                                             | Description                                                                                                   |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `static compile_json_file ( String json_res_path, String binary_res_path ) : bool` | Compiles an Ink JSON file to binary format. This is a static method that can be called directly on the class. |

### Method Descriptions

#### `compile_json_file ( String json_res_path, String binary_res_path ) : bool`

Compiles an Ink JSON file to binary format. This is a static method that can be called directly on the class.

**Parameters:**
- `json_res_path` (String): Resource path to the source JSON file (`.inkj` or `.ink.json`)
- `binary_res_path` (String): Resource path for the output binary file (`.ink.inkb`)

**Returns:** bool - `true` if compilation succeeded, `false` otherwise

**Example:**
```python
var success = InkCompiler.compile_json_file(
    "res://story.ink.json",
    "res://story.ink.inkb"
)
if success:
    print("Compilation successful!")
```

## See Also

- [Ink Language Documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md)
- [InkCPP Library](https://github.com/brwarner/inkcpp)
