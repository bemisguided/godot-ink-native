# InkCPP API Analysis and Mapping

This document provides a comprehensive analysis of the inkcpp library API and how we'll wrap it for Godot.

## Executive Summary

The inkcpp library uses a **binary story format** (not JSON). Key findings:

1. **Compilation**: Ink JSON → Binary format (using `ink::compiler`)
2. **Runtime**: Binary → Story → Runner (executor) + Globals (shared state)
3. **Architecture**: Story is a factory that creates Runner instances and Globals stores

## Core Architecture

```
┌─────────────────────────────────────────────────┐
│              User's Ink Script                  │
│                  (.ink file)                    │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
              [inklecate]
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│             Ink JSON Format                     │
│             (.ink.json file)                    │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
         [ink::compiler::run()]
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│          Binary Story Format                    │
│             (.bin buffer)                       │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
        [ink::runtime::story::from_binary()]
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│           ink::runtime::story                   │
│         (Factory for runners)                   │
└──────────────────┬──────────────────────────────┘
                   │
                   ├──► new_globals() → globals_interface
                   │
                   └──► new_runner() → runner_interface
                              │
                              ▼
                    ┌──────────────────────┐
                    │  runner_interface    │
                    │  - getline()         │
                    │  - choose()          │
                    │  - begin()/end()     │
                    │  - bind()            │
                    └──────────────────────┘
```

## Key Types and Structures

### 1. Value System

```cpp
namespace ink::runtime {
    typedef uint32_t hash_t;  // For hashing variable/path names

    struct value {
        enum class Type {
            Bool, Uint32, Int32, String, Float, List
        };
        Type type;
        // Union of all value types
    };
}
```

**Mapping to Godot:**
- `value` → `Variant` (GDScript's universal type)
- Type conversions handled in wrapper layer

### 2. Story (Factory Pattern)

```cpp
class story {
    // Factory methods to create story from binary data
    static story* from_file(const char* filename);
    static story* from_binary(unsigned char* data, size_t length, bool freeOnDestroy);

    // Create global stores (shared state)
    virtual globals new_globals() = 0;
    virtual globals new_globals_from_snapshot(const snapshot& obj) = 0;

    // Create runners (executors)
    virtual runner new_runner(globals store = nullptr) = 0;
    virtual runner new_runner_from_snapshot(const snapshot& obj, globals store) = 0;
};
```

**Key Insight:** Story is abstract and uses smart pointers:
- `globals` = `story_ptr<globals_interface>` (managed pointer)
- `runner` = `story_ptr<runner_interface>` (managed pointer)

### 3. Runner (Executor)

```cpp
class runner_interface {
    // Execution
    virtual bool can_continue() const = 0;
    virtual line_type getline() = 0;      // Execute next line (STL: std::string)
    virtual line_type getall() = 0;        // Execute until choice/end

    // Choices
    virtual const choice* begin() const = 0;  // Iterator to first choice
    virtual const choice* end() const = 0;    // Iterator past last choice
    virtual void choose(size_t index) = 0;

    // Tags
    virtual bool has_tags() const = 0;
    virtual size_t num_tags() const = 0;
    virtual const char* get_tag(size_t index) const = 0;
    virtual bool has_global_tags() const = 0;
    virtual const char* get_global_tag(size_t index) const = 0;
    virtual bool has_knot_tags() const = 0;
    virtual const char* get_knot_tag(size_t index) const = 0;

    // Navigation
    virtual bool move_to(hash_t path) = 0;
    virtual hash_t get_current_knot() const = 0;

    // External functions
    template<typename F>
    void bind(hash_t name, F function, bool lookaheadSafe);

    // State management
    virtual snapshot* create_snapshot() const = 0;

    // Convenience
    size_t num_choices() const;
    const choice* get_choice(size_t index) const;
};
```

### 4. Choice

```cpp
class choice {
    int index() const;           // Choice index for selection
    const char* text() const;    // Display text
    bool has_tags() const;
    size_t num_tags() const;
    const char* get_tag(size_t index) const;
};
```

**Simple struct** - easy to wrap.

### 5. Globals (Variable Store)

```cpp
class globals_interface {
    // Get/Set variables (templated)
    template<typename T> optional<T> get(const char* name) const;
    template<typename T> bool set(const char* name, const T& val);

    // Observe variables
    template<typename F> void observe(const char* name, F callback);

    // State management
    virtual snapshot* create_snapshot() const = 0;
};
```

**Supported Types:**
- `bool`, `uint32_t`, `int32_t`, `float`, `const char*`, `list`

### 6. List (Ink Lists)

```cpp
class list_interface {
    // List operations
    virtual bool contains(const char* flag) const;
    virtual void add(const char* flag);
    virtual void remove(const char* flag);

    // Iteration
    virtual iterator begin() const;
    virtual iterator begin(const char* list_name) const;
    virtual iterator end() const;

    class iterator {
        struct Flag {
            const char* flag_name;
            const char* list_name;
        };
        Flag operator*() const;
    };
};
```

### 7. Compiler

```cpp
namespace ink::compiler {
    struct compilation_results {
        error_list warnings;  // std::vector<std::string>
        error_list errors;    // std::vector<std::string>
    };

    // Compile JSON to binary
    void run(const char* filenameIn, std::ostream& out, compilation_results* results);
    void run(std::istream& in, std::ostream& out, compilation_results* results);
}
```

## Wrapper Strategy

### Architecture Decision

We'll create a **simplified single-class interface** for GDScript users:

```
InkStory (Godot wrapper)
  └─► Owns: ink::runtime::story*
  └─► Owns: ink::runtime::runner
  └─► Owns: ink::runtime::globals
```

**Rationale:**
1. Most Godot users won't need multiple runners
2. Simplifies GDScript API (single class instead of 3)
3. Can expose advanced multi-runner support later if needed

### Class Mapping

| InkCPP Class | Wrapper Class | Purpose |
|--------------|---------------|---------|
| `ink::runtime::story` | `InkStory` | Main interface (owns story/runner/globals) |
| `ink::runtime::runner_interface` | (Internal to `InkStory`) | Execution |
| `ink::runtime::globals_interface` | (Internal to `InkStory`) | Variables |
| `ink::runtime::choice` | `InkChoice` | Choice data (copied) |
| `ink::runtime::list_interface` | `InkList` | List wrapper |
| `ink::compiler` | `InkCompiler` | Compilation |
| Tags | `String` | Simple strings (no wrapper) |

### InkStory Wrapper Design

```cpp
class InkStory : public RefCounted {
    GDCLASS(InkStory, RefCounted)

private:
    // Core inkcpp objects
    ink::runtime::story* _story;
    ink::runtime::runner _runner;
    ink::runtime::globals _globals;

    // Cached data for GDScript
    Array _current_choices;  // Array of InkChoice

    // Compilation buffer (if we compile from JSON)
    std::vector<unsigned char> _compiled_binary;

public:
    // === Loading ===
    bool load_story_json(const String& json_content);    // Compile + load
    bool load_story_binary(const PackedByteArray& data); // Load pre-compiled
    bool load_story_file(const String& file_path);       // Load JSON file

    // === Execution ===
    String continue_story();           // Maps to runner->getline()
    String continue_story_maximally(); // Maps to runner->getall()
    bool can_continue() const;         // Maps to runner->can_continue()

    // === Choices ===
    Array get_current_choices() const;      // Returns Array of InkChoice
    void choose_choice_index(int index);    // Maps to runner->choose()
    void choose_path_string(const String& path); // Maps to runner->move_to()

    // === Variables ===
    Variant get_variable(const String& name) const;    // Maps to globals->get()
    void set_variable(const String& name, const Variant& value); // Maps to globals->set()
    void observe_variable(const String& name, const Callable& callback); // Maps to globals->observe()

    // === Tags ===
    Array get_current_tags() const;  // Returns Array of String
    Array get_global_tags() const;
    Array get_knot_tags() const;

    // === External Functions ===
    void bind_external_function(const String& name, const Callable& callback);

    // === State ===
    String save_state_json() const;
    void load_state_json(const String& json);
};
```

## Implementation Plan

### Phase 1: Basic Infrastructure

1. **InkChoice** (simplest)
   - Copy data from `ink::runtime::choice`
   - No direct pointer to inkcpp objects

2. **InkStory** (core functionality)
   - Load JSON → compile → create story → create runner
   - Basic continuation and choice selection
   - Simple variable get/set

### Phase 2: Advanced Features

3. **InkList** (complex wrapper)
   - Wrap `ink::runtime::list_interface*`
   - Handle iterator translation

4. **InkCompiler** (separate class)
   - Standalone compiler for pre-compilation
   - Error/warning reporting

### Phase 3: State & External Functions

5. **Snapshot/State management**
   - Save/load state
   - Snapshots

6. **External function binding**
   - Callable → C++ lambda binding
   - Argument marshalling

## Critical Implementation Details

### 1. String Handling

**InkCPP:**
- Uses `const char*` for all strings
- Expects UTF-8 or ASCII
- Uses `hash_string()` for path/variable lookups

**Godot:**
- Uses `String` (UTF-32 internally)
- Need conversions: `String::utf8().get_data()` → `const char*`

### 2. Memory Management

**InkCPP:**
- `story*` - raw pointer, must be deleted
- `runner` - smart pointer (`story_ptr<>`)
- `globals` - smart pointer (`story_ptr<>`)
- `choice*` - borrowed pointer (don't delete)

**Godot:**
- `RefCounted` base class handles reference counting
- Store inkcpp objects as members
- Delete in destructor

### 3. Variant Conversion

```cpp
// Godot Variant → ink::runtime::value
ink::runtime::value variant_to_value(const Variant& v) {
    switch (v.get_type()) {
        case Variant::BOOL: return value(bool(v));
        case Variant::INT: return value(int32_t(v));
        case Variant::FLOAT: return value(float(v));
        case Variant::STRING: return value(String(v).utf8().get_data());
        // ... handle List
    }
}

// ink::runtime::value → Godot Variant
Variant value_to_variant(const ink::runtime::value& v) {
    switch (v.type) {
        case value::Type::Bool: return v.get<value::Type::Bool>();
        case value::Type::Int32: return v.get<value::Type::Int32>();
        case value::Type::Float: return v.get<value::Type::Float>();
        case value::Type::String: return String(v.get<value::Type::String>());
        // ... handle List
    }
}
```

### 4. Compilation Flow

```cpp
bool InkStory::load_story_json(const String& json_content) {
    // 1. Prepare input stream
    std::istringstream input(json_content.utf8().get_data());

    // 2. Prepare output buffer
    std::ostringstream output;

    // 3. Compile
    ink::compiler::compilation_results results;
    ink::compiler::run(input, output, &results);

    // 4. Check errors
    if (!results.errors.empty()) {
        return false;
    }

    // 5. Get binary data
    std::string binary = output.str();
    _compiled_binary.assign(binary.begin(), binary.end());

    // 6. Load story from binary
    _story = ink::runtime::story::from_binary(
        _compiled_binary.data(),
        _compiled_binary.size(),
        false  // Don't free (we manage it)
    );

    // 7. Create globals and runner
    _globals = _story->new_globals();
    _runner = _story->new_runner(_globals);

    return true;
}
```

### 5. External Function Binding

```cpp
void InkStory::bind_external_function(const String& name, const Callable& callback) {
    // Store callback to keep it alive
    _bound_functions[name] = callback;

    // Create C++ lambda that calls GDScript
    auto lambda = [this, callback](size_t argc, const ink::runtime::value* argv)
        -> ink::runtime::value {

        // Convert arguments to Variant array
        Array args;
        for (size_t i = 0; i < argc; i++) {
            args.push_back(value_to_variant(argv[i]));
        }

        // Call GDScript callable
        Variant result = callback.callv(args);

        // Convert result back
        return variant_to_value(result);
    };

    // Bind to runner using hash
    _runner->bind(ink::hash_string(name.utf8().get_data()), lambda);
}
```

## Build System Adjustments

### Issues Discovered

1. **No separate inkcpp/inkcpp_compiler source files to glob**
   - The library is likely header-only or uses CMake
   - Need to check actual source structure

2. **Missing includes**
   - `inkcpp/inkcpp/include` contains headers
   - `inkcpp/shared/public` contains system.h
   - Need to add both to include paths

### Recommended Approach

Instead of building inkcpp directly, we should:

1. **Use CMake to build inkcpp first**
2. **Link against compiled libraries**
3. **Update SConstruct to link, not compile**

```python
# Updated SConstruct approach
env.Append(CPPPATH=[
    "inkcpp/inkcpp/include",
    "inkcpp/inkcpp_compiler/include",
    "inkcpp/shared/public",
])

env.Append(LIBPATH=["inkcpp/build/lib"])
env.Append(LIBS=["inkcpp", "inkcpp_compiler"])
```

## Next Steps

1. ✅ Understand inkcpp API structure
2. ✅ Map classes to wrappers
3. ⏭️ Fix build system to properly link inkcpp
4. ⏭️ Implement InkChoice wrapper (simple)
5. ⏭️ Implement InkStory wrapper (core)
6. ⏭️ Test basic compilation and execution
7. ⏭️ Add InkList wrapper
8. ⏭️ Add InkCompiler wrapper
9. ⏭️ Add external function support
10. ⏭️ Add state management

## Reference: Important inkcpp Files

- **Runtime Headers:**
  - `inkcpp/inkcpp/include/story.h` - Factory interface
  - `inkcpp/inkcpp/include/runner.h` - Executor interface
  - `inkcpp/inkcpp/include/choice.h` - Choice structure
  - `inkcpp/inkcpp/include/globals.h` - Variable store
  - `inkcpp/inkcpp/include/list.h` - List interface
  - `inkcpp/inkcpp/include/types.h` - Value types
  - `inkcpp/shared/public/system.h` - Basic types and hash_string

- **Compiler Headers:**
  - `inkcpp/inkcpp_compiler/include/compiler.h` - Compilation functions
  - `inkcpp/inkcpp_compiler/include/compilation_results.h` - Error reporting

## Conclusion

The inkcpp library has a clean, well-designed API. Our wrapper strategy:

1. **Simplify** for GDScript users (single InkStory class)
2. **Compile on load** (transparent JSON → binary)
3. **Map carefully** between Godot and C++ types
4. **Manage memory** properly (RefCounted + smart pointers)
5. **Build properly** (link against pre-built inkcpp libraries)

This approach gives Godot users a clean, intuitive API while maintaining full access to Ink's features.
