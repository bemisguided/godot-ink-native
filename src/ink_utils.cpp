/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_utils.h"

#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

namespace InkUtils {

String resolve_resource_path(const String& res_path) {
	ProjectSettings* settings = ProjectSettings::get_singleton();
	if (!settings) {
		ERR_PRINT("InkUtils: Failed to get ProjectSettings singleton");
		return String();
	}

	String fs_path = settings->globalize_path(res_path);
	if (fs_path.is_empty()) {
		ERR_PRINT(String("InkUtils: Failed to resolve path: ") + res_path);
		return String();
	}

	return fs_path;
}

Variant ink_value_to_variant(const ink::runtime::value& ink_val) {
	// Convert all supported types (no lifetime issues when reading from Ink)
	switch (ink_val.type) {
		case ink::runtime::value::Type::Bool:
			return Variant(ink_val.get<ink::runtime::value::Type::Bool>());

		case ink::runtime::value::Type::Int32:
			return Variant(ink_val.get<ink::runtime::value::Type::Int32>());

		case ink::runtime::value::Type::Uint32:
			return Variant((int64_t)ink_val.get<ink::runtime::value::Type::Uint32>());

		case ink::runtime::value::Type::Float:
			return Variant(ink_val.get<ink::runtime::value::Type::Float>());

		case ink::runtime::value::Type::String:
			// No lifetime issues when reading - InkCPP manages the string pointer
			return Variant(String(ink_val.get<ink::runtime::value::Type::String>()));

		case ink::runtime::value::Type::List:
			WARN_PRINT("List variables not yet supported");
			return Variant();
	}

	return Variant();
}

InkValue variant_to_ink_value(const Variant& var) {
	// Factory function - delegates to InkValue constructor which handles all types including strings
	return InkValue(var);
}

} // namespace InkUtils
