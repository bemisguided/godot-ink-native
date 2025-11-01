/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_choice.h"

#include <choice.h> // inkcpp header

#include <godot_cpp/core/class_db.hpp>

InkChoice::InkChoice() : _index(-1) {
}

InkChoice::~InkChoice() {
}

void InkChoice::_bind_methods() {
	// Bind getter methods
	ClassDB::bind_method(D_METHOD("get_index"), &InkChoice::get_index);
	ClassDB::bind_method(D_METHOD("get_text"), &InkChoice::get_text);
	ClassDB::bind_method(D_METHOD("get_tags"), &InkChoice::get_tags);
	ClassDB::bind_method(D_METHOD("has_tags"), &InkChoice::has_tags);

	// Add properties for easier GDScript access
	ADD_PROPERTY(PropertyInfo(Variant::INT, "index"), "", "get_index");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "text"), "", "get_text");
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_STRING_ARRAY, "tags"), "", "get_tags");
}

void InkChoice::_init_from_native(const ink::runtime::choice& native_choice) {
	// Copy index and text
	_index = native_choice.index();
	_text = String(native_choice.text());

	// Copy tags
	_tags.clear();
	if (native_choice.has_tags()) {
		size_t num_tags = native_choice.num_tags();
		for (size_t i = 0; i < num_tags; i++) {
			const char* tag = native_choice.get_tag(i);
			if (tag) {
				_tags.push_back(String(tag));
			}
		}
	}
}
