/* Copyright (c) 2025 Godot Ink Native Contributors
 *
 * This file is part of godot-ink-native which is released under MIT license.
 * See file LICENSE for full license details.
 */

#include "register_types.h"

#include "ink_choice.h"
#include "ink_compiler.h"
#include "ink_story.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_ink_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    // Register Ink classes
    ClassDB::register_class<InkChoice>();
    ClassDB::register_class<InkCompiler>();
    ClassDB::register_class<InkStory>();
}

void uninitialize_ink_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    // Cleanup if needed
}

extern "C" {
    // Initialization entry point
    GDExtensionBool GDE_EXPORT godot_ink_init(
        GDExtensionInterfaceGetProcAddress p_get_proc_address,
        GDExtensionClassLibraryPtr p_library,
        GDExtensionInitialization *r_initialization
    ) {
        godot::GDExtensionBinding::InitObject init_obj(
            p_get_proc_address,
            p_library,
            r_initialization
        );

        init_obj.register_initializer(initialize_ink_module);
        init_obj.register_terminator(uninitialize_ink_module);
        init_obj.set_minimum_library_initialization_level(
            MODULE_INITIALIZATION_LEVEL_SCENE
        );

        return init_obj.init();
    }
}
