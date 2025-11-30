/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "ink_value.h"

#include <godot_cpp/core/error_macros.hpp>

InkValue::InkValue(const Variant& var) {
	switch (var.get_type()) {
		case Variant::NIL:
			// Nil/null → empty ink value (for void functions)
			_value = ink::runtime::value();
			break;

		case Variant::BOOL:
			_value = ink::runtime::value((bool)var);
			break;

		case Variant::INT:
			_value = ink::runtime::value((int32_t)(int64_t)var);
			break;

		case Variant::FLOAT:
			_value = ink::runtime::value((float)(double)var);
			break;

		case Variant::STRING: {
			// Store CharString in member to keep it alive
			// _value will contain a pointer to _string_storage's data
			String str = var;
			_string_storage = str.utf8();
			_value = ink::runtime::value(_string_storage.get_data());
			break;
		}

		default:
			ERR_PRINT(String("Unsupported Variant type for ink value: ") + Variant::get_type_name(var.get_type()));
			_value = ink::runtime::value();
			break;
	}
}

const ink::runtime::value& InkValue::get() const {
	return _value;
}

InkValue::operator ink::runtime::value() const {
	return _value;
}
