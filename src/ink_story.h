/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_STORY_H
#define INK_STORY_H

#include "ink_choice.h"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>

// Include inkcpp types (needed for smart pointers and story class)
#include <story.h>
#include <types.h>

#include <vector>

using namespace godot;

/**
 * @brief Main interface for running Ink stories in Godot
 *
 * InkStory provides a complete interface for loading, executing, and interacting
 * with Ink narrative scripts. It handles compilation of Ink JSON, story execution,
 * choice management, variables, and tags.
 *
 * Basic usage:
 * @code
 * var story = InkStory.new()
 * story.load_story("res://stories/hello.inkj")
 *
 * while story.can_continue():
 *     print(story.continue_story())
 *
 * for choice in story.get_current_choices():
 *     print(choice.text)
 *
 * story.choose_choice_index(0)
 * @endcode
 */
class InkStory : public RefCounted {
	GDCLASS(InkStory, RefCounted)

private:
	// InkCPP objects
	ink::runtime::story* _story;
	ink::runtime::runner _runner;
	ink::runtime::globals _globals;

	// Binary data storage (compiled story)
	std::vector<unsigned char> _binary_data;

	// Cached choices for GDScript
	Array _current_choices;

	// Cached current text from last continue
	String _current_text;

	// Helper methods
	void _update_choices();

	// Story loading helpers
	String _resolve_resource_path(const String& res_path);
	bool _load_binary_story(const String& binary_path);
	bool _compile_and_load_json(const String& json_path);

protected:
	static void _bind_methods();

public:
	InkStory();
	~InkStory();

	// ===== Loading =====

	/**
	 * @brief Load an Ink story from file (.inkj or .inkb)
	 *
	 * Automatically handles compilation based on file extension:
	 * - .inkj files are compiled to .inkb and saved alongside the .inkj file
	 * - .inkb files are loaded directly
	 *
	 * @param story_path Path to story file (supports res:// URIs)
	 * @return true if successful, false on error
	 *
	 * Example:
	 * @code
	 * var story = InkStory.new()
	 * story.load_story("res://stories/hello.inkj")  # Compiles to hello.inkb
	 * # or
	 * story.load_story("res://stories/hello.inkb")  # Loads directly
	 * @endcode
	 */
	bool load_story(const String& story_path);

	/**
	 * @brief Reset the story to the beginning
	 */
	void reset_state();

	// ===== Execution =====

	/**
	 * @brief Continue story execution for one line
	 * @return The next line of text
	 */
	String continue_story();

	/**
	 * @brief Continue story until reaching a choice or the end
	 * @return All text up to the next choice or end
	 */
	String continue_story_maximally();

	/**
	 * @brief Check if the story can continue
	 * @return true if more content is available
	 */
	bool can_continue() const;

	/**
	 * @brief Get the current story text (last continue result)
	 * @return Current text
	 */
	String get_current_text() const;

	// ===== Choices =====

	/**
	 * @brief Get available choices
	 * @return Array of InkChoice objects
	 */
	Array get_current_choices() const;

	/**
	 * @brief Get the number of available choices
	 * @return Choice count
	 */
	int get_current_choice_count() const;

	/**
	 * @brief Select a choice by index
	 * @param index The choice index (from InkChoice.get_index())
	 */
	void choose_choice_index(int index);

	/**
	 * @brief Navigate to a specific knot/stitch by path
	 * @param path The path string (e.g., "knot.stitch")
	 * @return true if path was found
	 */
	bool choose_path_string(const String& path);

	// ===== Tags =====

	/**
	 * @brief Get tags for the current line
	 * @return Array of tag strings
	 */
	PackedStringArray get_current_tags() const;

	/**
	 * @brief Get global tags (from top of story)
	 * @return Array of global tag strings
	 */
	PackedStringArray get_global_tags() const;

	/**
	 * @brief Get tags for the current knot/stitch
	 * @return Array of knot tag strings
	 */
	PackedStringArray get_knot_tags() const;

	// ===== Variables =====

	/**
	 * @brief Get a story variable
	 * @param name Variable name
	 * @return Variable value as Variant (supports int, float, bool, string)
	 */
	Variant get_variable(const String& name) const;

	/**
	 * @brief Set a story variable
	 * @param name Variable name
	 * @param value New value (int, float, bool, or string)
	 */
	void set_variable(const String& name, const Variant& value);

	// ===== Path/Navigation =====

	/**
	 * @brief Get the current path in the story
	 * @return Current path string
	 */
	String get_current_path() const;

	// ===== Utility =====

	/**
	 * @brief Check if the story has been loaded
	 * @return true if a story is loaded and ready
	 */
	bool is_loaded() const;
};

#endif // INK_STORY_H
