/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_UTILS_H
#define INK_UTILS_H

#include <godot_cpp/variant/string.hpp>

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

} // namespace InkUtils

#endif // INK_UTILS_H
