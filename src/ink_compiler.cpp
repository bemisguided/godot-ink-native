/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_compiler.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/class_db.hpp>

// InkCPP compiler headers
#include <compiler.h>
#include <compilation_results.h>

#include <sstream>
#include <fstream>

void InkCompiler::_bind_methods() {
	ClassDB::bind_static_method("InkCompiler", D_METHOD("compile_json_file", "json_res_path", "binary_res_path"), &InkCompiler::compile_json_file);
}

bool InkCompiler::compile_json_file(const String& json_res_path, const String& binary_res_path) {
	// Read JSON file using Godot's FileAccess
	Ref<FileAccess> file = FileAccess::open(json_res_path, FileAccess::READ);
	if (file.is_null()) {
		ERR_PRINT(String("InkCompiler: Failed to open JSON file: ") + json_res_path);
		return false;
	}

	// Read entire JSON content
	String json_content = file->get_as_text();
	file->close();

	if (json_content.is_empty()) {
		ERR_PRINT(String("InkCompiler: JSON file is empty: ") + json_res_path);
		return false;
	}

	// Convert to std::string for inkcpp
	CharString json_utf8 = json_content.utf8();
	std::string json_str = std::string(json_utf8.get_data(), json_utf8.length());

	// Create input stream from JSON string
	std::istringstream json_stream(json_str);

	// Get ProjectSettings to resolve output path
	ProjectSettings* settings = ProjectSettings::get_singleton();
	if (!settings) {
		ERR_PRINT("InkCompiler: Failed to get ProjectSettings singleton");
		return false;
	}

	// Convert output path to filesystem path
	String binary_fs_path = settings->globalize_path(binary_res_path);
	if (binary_fs_path.is_empty()) {
		ERR_PRINT(String("InkCompiler: Failed to resolve binary path: ") + binary_res_path);
		return false;
	}

	// Convert to C string for inkcpp
	CharString binary_utf8 = binary_fs_path.utf8();
	const char* binary_path_cstr = binary_utf8.get_data();

	// Prepare compilation results
	ink::compiler::compilation_results results;

	// Compile JSON stream to binary file
	try {
		ink::compiler::run(json_stream, binary_path_cstr, &results);
	} catch (const std::exception& e) {
		ERR_PRINT(String("InkCompiler: Compilation exception: ") + String(e.what()));
		return false;
	}

	// Check for compilation errors
	if (!results.errors.empty()) {
		ERR_PRINT(String("InkCompiler: Compilation failed with ") + String::num_int64(results.errors.size()) + String(" error(s):"));
		for (const auto& error : results.errors) {
			ERR_PRINT(String("  - ") + String(error.c_str()));
		}
		return false;
	}

	// Print warnings (but don't fail)
	if (!results.warnings.empty()) {
		WARN_PRINT(String("InkCompiler: Compilation succeeded with ") + String::num_int64(results.warnings.size()) + String(" warning(s):"));
		for (const auto& warning : results.warnings) {
			WARN_PRINT(String("  - ") + String(warning.c_str()));
		}
	}

	return true;
}
