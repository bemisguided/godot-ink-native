/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_VALUE_H
#define INK_VALUE_H

#include <godot_cpp/variant/char_string.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <types.h>

using namespace godot;

/**
 * @brief RAII wrapper for ink::runtime::value with automatic string lifetime management
 *
 * This class solves the string lifetime problem when converting Godot Variant to
 * ink::runtime::value. Since ink::runtime::value only stores a const char* pointer,
 * the actual string data must remain valid until InkCPP copies it.
 *
 * InkValue owns a CharString internally, ensuring the string data remains valid
 * for the lifetime of the InkValue object. This eliminates the need for external
 * storage vectors and scattered "if string" checks throughout the codebase.
 *
 * Usage:
 * @code
 * // String data automatically owned and kept alive
 * auto ink_value = InkUtils::variant_to_ink_value(variant);
 * _globals->set(name, ink_value.get());  // Safe - InkCPP copies before ink_value destroyed
 * @endcode
 *
 * @note This is an internal helper class. GDScript users never see it directly.
 */
class InkValue {
private:
	/// The underlying InkCPP value (may contain pointer to _string_storage)
	ink::runtime::value _value;

	/// Owned string storage (only used when _value contains a string type)
	CharString _string_storage;

public:
	/**
	 * @brief Construct InkValue from Godot Variant
	 *
	 * Converts the Variant to an ink::runtime::value, automatically handling
	 * string lifetime by storing the CharString internally.
	 *
	 * Supported types:
	 * - NIL → empty ink value
	 * - BOOL → ink bool
	 * - INT → ink int32
	 * - FLOAT → ink float
	 * - STRING → ink string (with automatic lifetime management)
	 *
	 * @param var The Godot Variant to convert
	 */
	explicit InkValue(const Variant& var);

	/**
	 * @brief Get the underlying ink::runtime::value
	 *
	 * Returns a const reference to the internal value. The string data
	 * (if any) remains valid as long as this InkValue object exists.
	 *
	 * @return const reference to ink::runtime::value
	 */
	const ink::runtime::value& get() const;

	/**
	 * @brief Implicit conversion to ink::runtime::value
	 *
	 * Allows InkValue to be used directly where ink::runtime::value is expected.
	 * The string data (if any) remains valid as long as this InkValue object exists.
	 *
	 * @return Copy of the ink::runtime::value
	 */
	operator ink::runtime::value() const;
};

#endif // INK_VALUE_H
