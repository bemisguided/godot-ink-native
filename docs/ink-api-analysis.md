You are right. I fixed types everywhere and corrected the external-binding vs variable APIs. Below is a complete Godot-flavored wrapper spec that covers the full public surface of `Ink.Runtime.Story` and its related types, with explicit data types and status per member.

# Ink Story wrapper for Godot 4.x

Godot data types only. Snake case. Signals instead of C# events. External functions use `Callable`. Variables use `Variant` get/set and optional observers.

C# references for core members shown in Story.cs: constants, properties, events, continue/canContinue/ContinueAsync, profiling, reset, flows. ([GitHub][1])

---

## Types

### `class Choice : RefCounted`

Godot representation of `Ink.Runtime.Choice`.

| Member        | Type                | Notes                                         |
| ------------- | ------------------- | --------------------------------------------- |
| `text`        | `String`            | Display text.                                 |
| `index`       | `int32_t`           | Choice index used by `choose(int32_t)`.       |
| `path_string` | `String`            | Optional internal divert target if available. |
| `tags`        | `PackedStringArray` | Choice-level tags if story provides them.     |

### `class InkList : RefCounted`

Godot representation of `Ink.Runtime.InkList`.

| Member    | Type                    | Notes                                                                 |
| --------- | ----------------------- | --------------------------------------------------------------------- |
| `entries` | `Array` of `Dictionary` | Each entry: `{ "origin": String, "item": String, "value": int32_t }`. |

Helpers:

* `bool contains(const String& item)`
* `int32_t get_value(const String& item)`

---

## `class Story : Object`

Godot wrapper over InkCPP (`story` + `runner`). Public API mirrors C# with Godot types.

### Signals (map C# events → Godot)

| Signal                   | Args                               | Maps C#                                          |
| ------------------------ | ---------------------------------- | ------------------------------------------------ |
| `error_emitted`          | `(int error_type, String message)` | `onError(errorMessage, ErrorType)` ([GitHub][1]) |
| `did_continue`           | `()`                               | `onDidContinue` ([GitHub][1])                    |
| `will_make_choice`       | `()`                               | `onMakeChoice` ([GitHub][1])                     |
| `will_evaluate_function` | `()`                               | `onEvaluateFunction` ([GitHub][1])               |
| `did_complete_function`  | `()`                               | `onCompleteEvaluateFunction` ([GitHub][1])       |
| `did_choose_path`        | `(String path)`                    | `onChoosePathString` ([GitHub][1])               |

> Status: optional but recommended if you rely on event hooks.

### Construction / story data

| C#                       | Godot wrapper                                         | In             | Out    | Status | Notes                          |
| ------------------------ | ----------------------------------------------------- | -------------- | ------ | ------ | ------------------------------ |
| `Story(string json)`     | `void load_story(const String& compiled_binary_path)` | `.inkbin` path | `void` | ✔      | InkCPP loads binary, not JSON. |
| `Story(Container, List)` | –                                                     | –              | –      | ✖      | Compiler-internal.             |

### Core flow

| C#                           | Godot wrapper                                 | In       | Out      | Status          | Notes                                   |
| ---------------------------- | --------------------------------------------- | -------- | -------- | --------------- | --------------------------------------- |
| `bool canContinue`           | `bool can_continue() const`                   | –        | `bool`   | ✔ ([GitHub][1]) |                                         |
| `string Continue()`          | `String continue_story()`                     | –        | `String` | ✔ ([GitHub][1]) | `continue` is a C++ keyword             |
| `string ContinueMaximally()` | `String continue_story_maximally()`           | –        | `String` | ✔               | Added `_story` for clarity              |
| `void ContinueAsync(float)`  | `void continue_async(double millisecs_limit)` | `double` | `void`   | ✖ ([GitHub][1]) |                                         |
| `bool asyncContinueComplete` | `bool async_continue_complete() const`        | –        | `bool`   | ✖ ([GitHub][1]) |                                         |

### Text and tags

| C#                         | Godot wrapper                                | In  | Out                 | Status          |
| -------------------------- | -------------------------------------------- | --- | ------------------- | --------------- |
| `string currentText`       | `String get_current_text() const`            | –   | `String`            | ✔ ([GitHub][1]) |
| `List<string> currentTags` | `PackedStringArray get_current_tags() const` | –   | `PackedStringArray` | ✔ ([GitHub][1]) |

### Choices

| C#                            | Godot wrapper                       | In        | Out                      | Status          |
| ----------------------------- | ----------------------------------- | --------- | ------------------------ | --------------- |
| `List<Choice> currentChoices` | `Array get_current_choices() const` | –         | `Array` of `Ref<Choice>` | ✔ ([GitHub][1]) |
| `void ChooseChoiceIndex(int)` | `void choose_choice_index(int32_t index)` | `int32_t` | `void`            | ✔               |

### Diverts / path control

| C#                              | Godot wrapper                                 | In       | Out    | Status |
| ------------------------------- | --------------------------------------------- | -------- | ------ | ------ |
| `void ChoosePathString(string)` | `void choose_path_string(const String& path)` | `String` | `void` | ✔      |

### Variables

| C#                             | Godot wrapper                                                 | In                | Out          | Status | Notes                             |
| ------------------------------ | ------------------------------------------------------------- | ----------------- | ------------ | ------ | --------------------------------- |
| `variablesState[name] = value` | `void set_variable(const String& name, const Variant& value)` | `String, Variant` | `void`       | ✔      | Variant→ink value conversion.     |
| `var v = variablesState[name]` | `Variant get_variable(const String& name) const`              | `String`          | `Variant`    | ✔      | ink value→Variant conversion.     |
| `VariablesState` object        | `Dictionary variables_snapshot() const`                       | –                 | `Dictionary` | △      | Optional bulk dump for debugging. |

> Correction you flagged: **binding is for external functions, not variables**. Variables use `get_variable/set_variable`. Observers below.

### Variable observers

| C#                                                | Godot wrapper                                                                      | In                                               | Out    | Status |
| ------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------ | ------ | ------ |
| `ObserveVariable(string, Action<string, object>)` | `void observe_variable(const String& name, const Callable& cb)`                    | `String, Callable( String name, Variant value )` | `void` | △      |
| `RemoveVariableObserver(…)`                       | `void remove_variable_observer(const Callable& cb, const String& name = String())` | `Callable, String?`                              | `void` | △      |

> Implemented by tracking changes after `did_continue` and invoking callbacks for touched names.

### Lists

| C#                  | Godot wrapper                                                 | In                     | Out            | Status |
| ------------------- | ------------------------------------------------------------- | ---------------------- | -------------- | ------ |
| `InkList` access    | `Ref<InkList> get_list(const String& name) const`             | `String`               | `Ref<InkList>` | △      |
| Set a list variable | `void set_list(const String& name, const Ref<InkList>& list)` | `String, Ref<InkList>` | `void`         | △      |

### Errors and warnings

| C#                             | Godot wrapper                                | In  | Out                 | Status          |
| ------------------------------ | -------------------------------------------- | --- | ------------------- | --------------- |
| `List<string> currentErrors`   | `PackedStringArray current_errors() const`   | –   | `PackedStringArray` | ✔ ([GitHub][1]) |
| `List<string> currentWarnings` | `PackedStringArray current_warnings() const` | –   | `PackedStringArray` | ✔ ([GitHub][1]) |
| `bool hasError`                | `bool has_error() const`                     | –   | `bool`              | ✔ ([GitHub][1]) |
| `bool hasWarning`              | `bool has_warning() const`                   | –   | `bool`              | ✔ ([GitHub][1]) |

### Save / load

| C#                      | Godot wrapper                                  | In                | Out               | Status |                                                                |
| ----------------------- | ---------------------------------------------- | ----------------- | ----------------- | ------ | -------------------------------------------------------------- |
| `string ToJson()`       | –                                              | –                 | –                 | ✖      | C# story JSON is format metadata, not runtime state in InkCPP. |
| `void ToJson(Stream)`   | –                                              | –                 | –                 | ✖      |                                                                |
| `Packed state (custom)` | `PackedByteArray save_state() const`           | –                 | `PackedByteArray` | ✔      |                                                                |
| `LoadJson(...)`         | `void load_state(const PackedByteArray& data)` | `PackedByteArray` | `void`            | ✔      |                                                                |
| `ResetState()`          | `void reset_state()`                           | –                 | `void`            | ✔      |                                                                |

### Callstack / unwind

| C#                 | Godot wrapper            | In  | Out    | Status |
| ------------------ | ------------------------ | --- | ------ | ------ |
| `ResetCallstack()` | `void reset_callstack()` | –   | `void` | ✔      |

### Multi-flow

| C#                              | Godot wrapper                                | In       | Out                 | Status          |
| ------------------------------- | -------------------------------------------- | -------- | ------------------- | --------------- |
| `SwitchFlow(string)`            | `void switch_flow(const String& flow_name)`  | `String` | `void`              | △               |
| `RemoveFlow(string)`            | `void remove_flow(const String& flow_name)`  | `String` | `void`              | △               |
| `SwitchToDefaultFlow()`         | `void switch_to_default_flow()`              | –        | `void`              | △               |
| `string currentFlowName`        | `String current_flow_name() const`           | –        | `String`            | ✔ ([GitHub][1]) |
| `bool currentFlowIsDefaultFlow` | `bool current_flow_is_default() const`       | –        | `bool`              | ✔ ([GitHub][1]) |
| `List aliveFlowNames`           | `PackedStringArray alive_flow_names() const` | –        | `PackedStringArray` | ✔ ([GitHub][1]) |

> In InkCPP you achieve multi-flow by multiple runners. Wrapper can simulate names → runner map.

### External functions

| C#                            | Godot wrapper                                                                                                      | In                       | Out                                       | Status |                                 |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ | ----------------------------------------- | ------ | ------------------------------- |
| `BindExternalFunction(...)`   | `void bind_external_function(const String& name, const Callable& fn, bool lookahead_safe = true)`                 | `String, Callable, bool` | `void`                                    | ✔      |                                 |
| Overloads for arity           | same single `Callable`                                                                                             | –                        | –                                         | ✔      | Godot `Callable` handles arity. |
| `TryGetExternalFunction(...)` | `Dictionary try_get_external_function(const String& name) const`                                                   | `String`                 | `{ "found": bool, "callable": Callable }` | △      |                                 |
| `UnbindExternalFunction(...)` | `void unbind_external_function(const String& name)`                                                                | `String`                 | `void`                                    | △      |                                 |
| `HasFunction(string)`         | `bool has_function(const String& function_name) const`                                                             | `String`                 | `bool`                                    | △      |                                 |
| `EvaluateFunction(name, ...)` | `Dictionary evaluate_function(const String& name, const Array& args = Array(), bool capture_text = false)`        | `String, Array, bool`    | `{ "result": Variant, "text": String }`   | △      |                                 |

> `evaluate_function` is emulated via divert into the function and reading output, matching C# behavior.

### Expression evaluation

| C#                              | Godot wrapper | Status |                                            |
| ------------------------------- | ------------- | ------ | ------------------------------------------ |
| `EvaluateExpression(Container)` | –             | ✖      | Advanced/unsupported in InkCPP public API. |

### Profiling

| C#                          | Godot wrapper            | In  | Out    | Status |
| --------------------------- | ------------------------ | --- | ------ | ------ |
| `Profiler StartProfiling()` | `void start_profiling()` | –   | `void` | △      |
| `void EndProfiling()`       | `void end_profiling()`   | –   | `void` | △      |

> Implement as no-ops or minimal timers inside wrapper; InkCPP has no built-in profiler hook.

---

## Godot-type details and conversion

### Variant to ink value

* `int` → ink int
* `float`/`double` → ink float
* `String` → ink string
* `bool` → ink int 0/1
* `Ref<InkList>` → ink list value
* Other types → raise `error_emitted(0, "unsupported Variant type")`

### ink value to Variant

* ink int → `int`
* ink float → `double`
* ink string → `String`
* ink list → `Ref<InkList>`
* null/void → `Variant()` (nil)

---

## Minimal Godot signatures cheat-sheet

```cpp
// Construction
void load_story(const String& compiled_binary_path);

// Flow
bool can_continue() const;
String continue_story();
String continue_story_maximally();
void continue_async(double millisecs_limit);
bool async_continue_complete() const;

// Choices
Array get_current_choices() const;             // Array<Ref<Choice>>
void choose_choice_index(int32_t index);

// Divert
void choose_path_string(const String& path);

// Text & tags
String get_current_text() const;
PackedStringArray get_current_tags() const;

// Variables
void set_variable(const String& name, const Variant& value);
Variant get_variable(const String& name) const;
void observe_variable(const String& name, const Callable& cb);
void remove_variable_observer(const Callable& cb, const String& name = String());

// Lists
Ref<InkList> get_list(const String& name) const;
void set_list(const String& name, const Ref<InkList>& list);

// Errors / warnings
PackedStringArray current_errors() const;
PackedStringArray current_warnings() const;
bool has_error() const;
bool has_warning() const;

// Save / load / reset
PackedByteArray save_state() const;
void load_state(const PackedByteArray& data);
void reset_state();
void reset_callstack();

// Flows
void switch_flow(const String& flow_name);
void remove_flow(const String& flow_name);
void switch_to_default_flow();
String current_flow_name() const;
bool current_flow_is_default() const;
PackedStringArray alive_flow_names() const;

// External functions
void bind_external_function(const String& name, const Callable& fn, bool lookahead_safe = true);
void unbind_external_function(const String& name);
Dictionary try_get_external_function(const String& name) const; // { found:bool, callable:Callable }
bool has_function(const String& function_name) const;
Dictionary evaluate_function(const String& name, const Array& args = Array(), bool capture_text = false); // { result, text }

// Profiling (optional)
void start_profiling();
void end_profiling();

// Signals
// error_emitted(int error_type, String message)
// did_continue()
// will_make_choice()
// will_evaluate_function()
// did_complete_function()
// did_choose_path(String path)
```

---

## Notes on your earlier concern

* The earlier “bind variable” phrasing was incorrect. Correct split is:

  * **Variables**: `get_variable/set_variable` (+ optional observers).
  * **External functions**: `bind_external/unbind_external/try_get_external/evaluate_function`.

---

If you want, I can now output compile-ready `.h/.cpp` with these exact signatures and Godot GDExtension registration.

[1]: https://raw.githubusercontent.com/inkle/ink/refs/heads/master/ink-engine-runtime/Story.cs "raw.githubusercontent.com"
