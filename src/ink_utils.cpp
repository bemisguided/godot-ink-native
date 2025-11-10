/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_utils.h"

#include <godot_cpp/classes/project_settings.hpp>

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

} // namespace InkUtils
