/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_story.h"
#include "ink_compiler.h"
#include "ink_utils.h"

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
	ClassDB::bind_method(D_METHOD("reset_state"), &InkStory::reset_state);

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

	// Resource property methods
	ClassDB::bind_method(D_METHOD("set_story_path", "path"), &InkStory::set_story_path);
	ClassDB::bind_method(D_METHOD("get_story_path"), &InkStory::get_story_path);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "story_path", PROPERTY_HINT_FILE, "*.inkb,*.inkj,*.json"),
	             "set_story_path", "get_story_path");

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

// ===== Story Loading Helper Methods =====

/**
 * @brief Resolve a Godot resource path to a filesystem path
 *
 * Converts res:// URIs to absolute filesystem paths using ProjectSettings.
 * Delegates to InkUtils::resolve_resource_path() to eliminate code duplication.
 *
 * @param res_path The resource path to resolve
 * @return Resolved filesystem path, or empty string on error
 */
String InkStory::_resolve_resource_path(const String& res_path) {
	return InkUtils::resolve_resource_path(res_path);
}

/**
 * @brief Load an Ink binary story file (.inkb)
 *
 * Handles cleanup of existing story, loads binary from filesystem,
 * and initializes globals and runner.
 *
 * @param binary_path Path to .inkb file (res:// or filesystem path)
 * @return true on success, false on error
 */
bool InkStory::_load_binary_story(const String& binary_path) {
	// Resolve path
	String fs_path = _resolve_resource_path(binary_path);
	if (fs_path.is_empty()) {
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
		ERR_PRINT(String("InkStory: Failed to load story from: ") + binary_path);
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

/**
 * @brief Compile JSON story to binary and load it
 *
 * Compiles .json/.inkj files to .inkb format using InkCompiler,
 * then loads the resulting binary.
 *
 * @param json_path Path to .json or .inkj file
 * @return true on success, false on error
 */
bool InkStory::_compile_and_load_json(const String& json_path) {
	// Generate binary path by replacing extension
	String binary_path = json_path.get_basename() + ".inkb";

	// Compile using InkCompiler
	if (!InkCompiler::compile_json_file(json_path, binary_path)) {
		ERR_PRINT(String("InkStory: Failed to compile story: ") + json_path);
		return false;
	}

	// Load the compiled binary
	return _load_binary_story(binary_path);
}

/**
 * @brief Load an Ink story from file
 *
 * Supports multiple file formats:
 * - .json, .inkj: Compiled to .inkb then loaded
 * - .inkb: Loaded directly
 *
 * The method automatically handles format detection and dispatch to
 * appropriate loading helpers.
 *
 * @param story_path Path to story file (supports res:// URIs)
 * @return true on success, false on error
 */
bool InkStory::load_story(const String& story_path) {
	// Detect file format
	String extension = story_path.get_extension().to_lower();

	// Route to appropriate loader
	bool success = false;
	if (extension == "json" || extension == "inkj") {
		// JSON formats require compilation
		success = _compile_and_load_json(story_path);
	} else if (extension == "inkb") {
		// Binary format loads directly
		success = _load_binary_story(story_path);
	} else {
		// Unsupported format
		ERR_PRINT(String("InkStory: Unsupported file extension '") + extension +
		          String("'. Use .json, .ink.json, .inkj, or .inkb files."));
		return false;
	}

	// Store path on successful load
	if (success) {
		_story_path = story_path;
	}

	return success;
}

void InkStory::reset_state() {
	if (!_story || !_globals) {
		return;
	}

	// Recreate the runner to reset state
	_runner = _story->new_runner(_globals);
	_current_text = String();
	_update_choices();
}

String InkStory::continue_story() {
	if (!_runner || !_runner->can_continue()) {
		return String();
	}

	try {
		// Get next line using std::string version
		std::string line = _runner->getline();

		// Cache the text for get_current_text()
		_current_text = String(line.c_str());

		// Update choices after continuation
		_update_choices();

		return _current_text;
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

		// Cache the text for get_current_text()
		_current_text = String(text.c_str());

		// Update choices
		_update_choices();

		return _current_text;
	} catch (const std::exception& e) {
		ERR_PRINT(String("Ink runtime error in continue_story_maximally(): ") + String(e.what()));
		return String();
	}
}

bool InkStory::can_continue() const {
	return _runner && _runner->can_continue();
}

String InkStory::get_current_text() const {
	return _current_text;
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
	// Store CharString to keep it alive during hash computation
	CharString path_utf8 = path.utf8();
	const char* path_cstr = path_utf8.get_data();
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

	CharString name_utf8 = name.utf8();
	const char* var_name = name_utf8.get_data();

	auto opt_value = _globals->get<ink::runtime::value>(var_name);
	if (!opt_value) {
		return Variant();
	}

	// Use helper for all types (no lifetime issues when reading)
	return InkUtils::ink_value_to_variant(*opt_value);
}

void InkStory::set_variable(const String& name, const Variant& value) {
	if (!_globals) {
		ERR_PRINT("Cannot set variable: story not loaded");
		return;
	}

	CharString name_utf8 = name.utf8();
	const char* var_name = name_utf8.get_data();

	// Handle strings directly to ensure CharString stays alive during _globals->set()
	if (value.get_type() == Variant::STRING) {
		String str = value;
		CharString str_utf8 = str.utf8();
		// InkCPP copies the string data into its internal string_table during set()
		ink::runtime::value ink_value = ink::runtime::value(str_utf8.get_data());
		_globals->set<ink::runtime::value>(var_name, ink_value);
	} else {
		// Use helper for primitive types (no lifetime issues)
		ink::runtime::value ink_value = InkUtils::variant_to_ink_value(value);
		_globals->set<ink::runtime::value>(var_name, ink_value);
	}
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

void InkStory::set_story_path(const String& path) {
	if (path.is_empty()) {
		_story_path = String();
		return;
	}

	// Load the story when path is set
	if (load_story(path)) {
		// _story_path is set by load_story() on success
		// This enables Resource serialization
	}
}

String InkStory::get_story_path() const {
	return _story_path;
}
