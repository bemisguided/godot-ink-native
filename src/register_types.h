/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#ifndef INK_REGISTER_TYPES_H
#define INK_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_ink_module(ModuleInitializationLevel p_level);
void uninitialize_ink_module(ModuleInitializationLevel p_level);

#endif // INK_REGISTER_TYPES_H
