/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_UTILS_H
#define INK_UTILS_H

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <types.h>

using namespace godot;

/**
 * @brief Shared utility functions for the Ink GDExtension
 *
 * This namespace provides common helper functions used across multiple
 * classes in the Ink integration to reduce code duplication.
 */
namespace InkUtils {

/**
 * @brief Resolve a Godot resource path to a filesystem path
 *
 * Converts res:// URIs to absolute filesystem paths using ProjectSettings.
 * This is a common operation needed when interfacing with native libraries
 * that expect filesystem paths.
 *
 * @param res_path The resource path to resolve (supports res:// URIs)
 * @return Resolved filesystem path, or empty string on error
 *
 * Example:
 * @code
 * String fs_path = InkUtils::resolve_resource_path("res://story.inkb");
 * // Returns: "/path/to/project/story.inkb"
 * @endcode
 */
String resolve_resource_path(const String& res_path);

/**
 * @brief Convert an Ink runtime value to a Godot Variant
 *
 * Converts from InkCPP's internal value type to Godot's Variant type,
 * handling all supported Ink variable types: Bool, Int32, Uint32, Float, String.
 * List types are not yet supported and will return an empty Variant with a warning.
 *
 * Note: No lifetime issues when reading - InkCPP manages the string pointers internally.
 *
 * @param ink_val The Ink value to convert
 * @return Godot Variant containing the converted value, or empty Variant() on error
 */
Variant ink_value_to_variant(const ink::runtime::value& ink_val);

/**
 * @brief Convert a Godot Variant to an Ink runtime value
 *
 * Converts from Godot's Variant type to InkCPP's internal value type.
 * Supports: BOOL, INT, FLOAT variants only.
 *
 * Note: STRING variants are NOT handled here due to lifetime requirements.
 * Strings must be handled directly in the calling code to ensure the CharString
 * stays alive during the InkCPP copy operation. See InkStory::set_variable() for example.
 *
 * Other types will print an error and return an empty ink::runtime::value.
 *
 * @param var The Godot Variant to convert
 * @return Ink value containing the converted data
 */
ink::runtime::value variant_to_ink_value(const Variant& var);

} // namespace InkUtils

#endif // INK_UTILS_H
