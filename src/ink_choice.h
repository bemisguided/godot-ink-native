/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_CHOICE_H
#define INK_CHOICE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

// Forward declare to avoid including inkcpp headers in public API
namespace ink {
namespace runtime {
	class choice;
}
} // namespace ink

using namespace godot;

/**
 * @brief Represents a choice in an Ink story
 *
 * InkChoice wraps data from an ink::runtime::choice, providing a GDScript-friendly
 * interface for accessing choice information. Choices are presented to the player
 * and can be selected to continue the story down different branches.
 */
class InkChoice : public RefCounted {
	GDCLASS(InkChoice, RefCounted)

private:
	int _index;
	String _text;
	PackedStringArray _tags;

protected:
	static void _bind_methods();

public:
	InkChoice();
	~InkChoice();

	/**
	 * @brief Get the index of this choice
	 * @return Choice index (pass to choose_choice_index)
	 */
	int get_index() const { return _index; }

	/**
	 * @brief Get the display text for this choice
	 * @return The text to show the player
	 */
	String get_text() const { return _text; }

	/**
	 * @brief Get tags associated with this choice
	 * @return Array of tag strings
	 */
	PackedStringArray get_tags() const { return _tags; }

	/**
	 * @brief Check if this choice has any tags
	 * @return true if tags exist, false otherwise
	 */
	bool has_tags() const { return !_tags.is_empty(); }

	/**
	 * @brief Internal: Initialize from native inkcpp choice
	 * @param native_choice The inkcpp choice to copy data from
	 * @note This is for internal use by InkStory only
	 */
	void _init_from_native(const ink::runtime::choice& native_choice);
};

#endif // INK_CHOICE_H
