/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_COMPILER_H
#define INK_COMPILER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

/**
 * @brief Wrapper for InkCPP compiler functionality
 *
 * InkCompiler provides static methods to compile Ink JSON files (.inkj) to binary format (.inkb).
 * It handles Godot resource URIs (res://) and converts them to filesystem paths automatically.
 *
 * File naming convention:
 * - .ink - Original Ink story script
 * - .inkj - JSON compilation (from Ink compiler)
 * - .inkb - Binary compilation (InkCPP format)
 *
 * Basic usage:
 * @code
 * var success = InkCompiler.compile_json_file(
 *     "res://stories/my_story.inkj",
 *     "res://stories/my_story.inkb"
 * )
 * if success:
 *     print("Compilation successful!")
 * @endcode
 */
class InkCompiler : public RefCounted {
	GDCLASS(InkCompiler, RefCounted)

protected:
	static void _bind_methods();

public:
	/**
	 * @brief Compile an Ink JSON file (.inkj) to binary format (.inkb)
	 *
	 * Takes Godot resource URIs (res://) and compiles the JSON file to binary.
	 * Errors and warnings are printed to the Godot console.
	 *
	 * @param json_res_path Path to input .inkj file (supports res:// URIs)
	 * @param binary_res_path Path to output .inkb file (supports res:// URIs)
	 * @return true if compilation succeeded, false on error
	 *
	 * Example:
	 * @code
	 * InkCompiler.compile_json_file(
	 *     "res://stories/hello.inkj",
	 *     "res://stories/hello.inkb"
	 * )
	 * @endcode
	 */
	static bool compile_json_file(const String& json_res_path, const String& binary_res_path);
};

#endif // INK_COMPILER_H
