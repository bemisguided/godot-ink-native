/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_UTILS_H
#define INK_UTILS_H

#include "ink_value.h"

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
 * @brief Convert a Godot Variant to an InkValue (RAII wrapper for ink::runtime::value)
 *
 * Factory function that converts from Godot's Variant type to InkValue, which
 * automatically manages string lifetime using RAII principles.
 *
 * Supported types: NIL, BOOL, INT, FLOAT, STRING
 * - Primitive types are converted directly
 * - String types have their CharString data owned by the returned InkValue
 * - Other types will print an error and return an empty ink value
 *
 * The returned InkValue keeps string data alive until it's destroyed, ensuring
 * safe usage with InkCPP APIs that copy the string data synchronously.
 *
 * @param var The Godot Variant to convert
 * @return InkValue containing the converted data (with automatic string lifetime management)
 *
 * Example:
 * @code
 * auto ink_value = InkUtils::variant_to_ink_value(variant);
 * _globals->set(name, ink_value.get());  // Safe - string data valid until ink_value destroyed
 * @endcode
 */
InkValue variant_to_ink_value(const Variant& var);

} // namespace InkUtils

#endif // INK_UTILS_H
