/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_story.h"
#include "ink_compiler.h"

#include <choice.h>
#include <compiler.h>
#include <compilation_results.h>
#include <globals.h>
#include <runner.h>
#include <story.h>
#include <system.h>
#include <types.h>

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <sstream>
#include <string>

InkStory::InkStory() : _story(nullptr) {
}

InkStory::~InkStory() {
	// Clean up story (runner and globals are smart pointers, auto-deleted)
	if (_story) {
		delete _story;
		_story = nullptr;
	}
}

void InkStory::_bind_methods() {
	// Loading methods
	ClassDB::bind_method(D_METHOD("load_story", "story_path"), &InkStory::load_story);
	ClassDB::bind_method(D_METHOD("reset"), &InkStory::reset);

	// Execution methods
	ClassDB::bind_method(D_METHOD("continue_story"), &InkStory::continue_story);
	ClassDB::bind_method(D_METHOD("continue_story_maximally"), &InkStory::continue_story_maximally);
	ClassDB::bind_method(D_METHOD("can_continue"), &InkStory::can_continue);
	ClassDB::bind_method(D_METHOD("get_current_text"), &InkStory::get_current_text);

	// Choice methods
	ClassDB::bind_method(D_METHOD("get_current_choices"), &InkStory::get_current_choices);
	ClassDB::bind_method(D_METHOD("get_current_choice_count"), &InkStory::get_current_choice_count);
	ClassDB::bind_method(D_METHOD("choose_choice_index", "index"), &InkStory::choose_choice_index);
	ClassDB::bind_method(D_METHOD("choose_path_string", "path"), &InkStory::choose_path_string);

	// Tag methods
	ClassDB::bind_method(D_METHOD("get_current_tags"), &InkStory::get_current_tags);
	ClassDB::bind_method(D_METHOD("get_global_tags"), &InkStory::get_global_tags);
	ClassDB::bind_method(D_METHOD("get_knot_tags"), &InkStory::get_knot_tags);

	// Variable methods
	ClassDB::bind_method(D_METHOD("get_variable", "name"), &InkStory::get_variable);
	ClassDB::bind_method(D_METHOD("set_variable", "name", "value"), &InkStory::set_variable);

	// Path methods
	ClassDB::bind_method(D_METHOD("get_current_path"), &InkStory::get_current_path);

	// Utility methods
	ClassDB::bind_method(D_METHOD("is_loaded"), &InkStory::is_loaded);
}

void InkStory::_update_choices() {
	_current_choices.clear();

	if (!_runner) {
		return;
	}

	try {
		// Iterate through choices using inkcpp's iterator interface
		for (const ink::runtime::choice* c = _runner->begin(); c != _runner->end(); ++c) {
			Ref<InkChoice> choice;
			choice.instantiate();
			choice->_init_from_native(*c);
			_current_choices.push_back(choice);
		}
	} catch (const std::exception& e) {
		ERR_PRINT(String("Ink runtime error while updating choices: ") + String(e.what()));
	}
}

bool InkStory::load_story(const String& story_path) {
	// Get file extension
	String extension = story_path.get_extension().to_lower();
	String path_to_load = story_path;

	// Check for JSON formats that need compilation (.inkj or .json)
	if (extension == "inkj" || extension == "json") {
		// Compile .inkj to .inkb
		// Generate binary path by replacing extension
		String binary_path = story_path.get_basename() + ".inkb";

		// Compile using InkCompiler
		if (!InkCompiler::compile_json_file(story_path, binary_path)) {
			ERR_PRINT(String("InkStory: Failed to compile story: ") + story_path);
			return false;
		}

		// Now load the compiled binary
		path_to_load = binary_path;
		extension = "inkb";
	}

	if (extension == "inkb") {
		// Load binary file
		ProjectSettings* settings = ProjectSettings::get_singleton();
		if (!settings) {
			ERR_PRINT("InkStory: Failed to get ProjectSettings singleton");
			return false;
		}

		// Convert res:// path to filesystem path
		String fs_path = settings->globalize_path(path_to_load);
		if (fs_path.is_empty()) {
			ERR_PRINT(String("InkStory: Failed to resolve path: ") + story_path);
			return false;
		}

		// Clean up existing story
		if (_story) {
			delete _story;
			_story = nullptr;
			_runner = ink::runtime::runner();
			_globals = ink::runtime::globals();
		}

		// Load story from binary file
		_story = ink::runtime::story::from_file(fs_path.utf8().get_data());

		if (!_story) {
			ERR_PRINT(String("InkStory: Failed to load story from: ") + story_path);
			return false;
		}

		// Create globals and runner
		_globals = _story->new_globals();
		_runner = _story->new_runner(_globals);

		if (!_runner) {
			ERR_PRINT("InkStory: Failed to create story runner");
			return false;
		}

		// Update initial choices
		_update_choices();

		return true;
	}

	// Unsupported file extension
	ERR_PRINT(String("InkStory: Unsupported file extension '") + extension + String("'. Use .json, .ink.json, .inkj, or .inkb files."));
	return false;
}

void InkStory::reset() {
	if (!_story || !_globals) {
		return;
	}

	// Recreate the runner to reset state
	_runner = _story->new_runner(_globals);
	_update_choices();
}

String InkStory::continue_story() {
	if (!_runner || !_runner->can_continue()) {
		return String();
	}

	try {
		// Get next line using std::string version
		std::string line = _runner->getline();

		// Update choices after continuation
		_update_choices();

		return String(line.c_str());
	} catch (const std::exception& e) {
		ERR_PRINT(String("Ink runtime error in continue_story(): ") + String(e.what()));
		return String();
	}
}

String InkStory::continue_story_maximally() {
	if (!_runner) {
		return String();
	}

	try {
		// Get all content until choice or end
		std::string text = _runner->getall();

		// Update choices
		_update_choices();

		return String(text.c_str());
	} catch (const std::exception& e) {
		ERR_PRINT(String("Ink runtime error in continue_story_maximally(): ") + String(e.what()));
		return String();
	}
}

bool InkStory::can_continue() const {
	return _runner && _runner->can_continue();
}

String InkStory::get_current_text() const {
	// Note: inkcpp doesn't store "current text", so this returns empty
	// Users should store the result of continue_story() themselves
	return String();
}

Array InkStory::get_current_choices() const {
	return _current_choices;
}

int InkStory::get_current_choice_count() const {
	return _current_choices.size();
}

void InkStory::choose_choice_index(int index) {
	if (!_runner) {
		ERR_PRINT("Cannot choose: story not loaded");
		return;
	}

	if (index < 0 || index >= _current_choices.size()) {
		ERR_PRINT(String("Invalid choice index: ") + String::num_int64(index));
		return;
	}

	try {
		// Choose the option
		_runner->choose(index);

		// Update choices after choosing
		_update_choices();
	} catch (const std::exception& e) {
		ERR_PRINT(String("Ink runtime error in choose_choice_index(): ") + String(e.what()));
	}
}

bool InkStory::choose_path_string(const String& path) {
	if (!_runner) {
		ERR_PRINT("Cannot navigate: story not loaded");
		return false;
	}

	// Convert path to hash
	const char* path_cstr = path.utf8().get_data();
	ink::hash_t path_hash = ink::hash_string(path_cstr);

	// Move to the path
	bool success = _runner->move_to(path_hash);

	if (success) {
		_update_choices();
	}

	return success;
}

PackedStringArray InkStory::get_current_tags() const {
	PackedStringArray tags;

	if (!_runner) {
		return tags;
	}

	size_t num_tags = _runner->num_tags();
	for (size_t i = 0; i < num_tags; i++) {
		const char* tag = _runner->get_tag(i);
		if (tag) {
			tags.push_back(String(tag));
		}
	}

	return tags;
}

PackedStringArray InkStory::get_global_tags() const {
	PackedStringArray tags;

	if (!_runner) {
		return tags;
	}

	size_t num_tags = _runner->num_global_tags();
	for (size_t i = 0; i < num_tags; i++) {
		const char* tag = _runner->get_global_tag(i);
		if (tag) {
			tags.push_back(String(tag));
		}
	}

	return tags;
}

PackedStringArray InkStory::get_knot_tags() const {
	PackedStringArray tags;

	if (!_runner) {
		return tags;
	}

	size_t num_tags = _runner->num_knot_tags();
	for (size_t i = 0; i < num_tags; i++) {
		const char* tag = _runner->get_knot_tag(i);
		if (tag) {
			tags.push_back(String(tag));
		}
	}

	return tags;
}

Variant InkStory::get_variable(const String& name) const {
	if (!_globals) {
		return Variant();
	}

	const char* var_name = name.utf8().get_data();

	// Try to get as a generic value
	auto opt_value = _globals->get<ink::runtime::value>(var_name);
	if (!opt_value) {
		return Variant();
	}

	const ink::runtime::value& val = *opt_value;

	// Convert based on type
	switch (val.type) {
		case ink::runtime::value::Type::Bool:
			return Variant(val.get<ink::runtime::value::Type::Bool>());

		case ink::runtime::value::Type::Int32:
			return Variant(val.get<ink::runtime::value::Type::Int32>());

		case ink::runtime::value::Type::Uint32:
			return Variant((int64_t)val.get<ink::runtime::value::Type::Uint32>());

		case ink::runtime::value::Type::Float:
			return Variant(val.get<ink::runtime::value::Type::Float>());

		case ink::runtime::value::Type::String:
			return Variant(String(val.get<ink::runtime::value::Type::String>()));

		case ink::runtime::value::Type::List:
			// TODO: Implement InkList wrapper
			WARN_PRINT("List variables not yet supported");
			return Variant();
	}

	return Variant();
}

void InkStory::set_variable(const String& name, const Variant& value) {
	if (!_globals) {
		ERR_PRINT("Cannot set variable: story not loaded");
		return;
	}

	const char* var_name = name.utf8().get_data();

	// Convert Variant to ink::runtime::value
	ink::runtime::value ink_value;

	switch (value.get_type()) {
		case Variant::BOOL:
			ink_value = ink::runtime::value((bool)value);
			break;

		case Variant::INT:
			ink_value = ink::runtime::value((int32_t)(int64_t)value);
			break;

		case Variant::FLOAT:
			ink_value = ink::runtime::value((float)(double)value);
			break;

		case Variant::STRING: {
			String str = value;
			// Warning: This string pointer must remain valid!
			// For safety, we should store it, but for now this is a limitation
			ink_value = ink::runtime::value(str.utf8().get_data());
			break;
		}

		default:
			ERR_PRINT(String("Unsupported variable type: ") + Variant::get_type_name(value.get_type()));
			return;
	}

	// Set the variable
	_globals->set<ink::runtime::value>(var_name, ink_value);
}

String InkStory::get_current_path() const {
	if (!_runner) {
		return String();
	}

	// Get current knot hash
	ink::hash_t knot_hash = _runner->get_current_knot();

	// Note: inkcpp doesn't provide reverse hash lookup
	// We'd need to maintain our own mapping to get the string path
	// For now, just return the hash as a string
	return String::num_int64(knot_hash);
}

bool InkStory::is_loaded() const {
	return _story != nullptr && _runner;
}
