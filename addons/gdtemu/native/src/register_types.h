// SPDX-FileCopyrightText: 2023 Leroy Hopson <copyright@leroy.geek.nz>
// SPDX-License-Identifier: MIT

#ifndef GDTEMU_REGISTER_TYPES_H
#define GDTEMU_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_gdtemu_module(ModuleInitializationLevel p_level);
void uninitialize_gdtemu_module(ModuleInitializationLevel p_level);

#endif // GDTEMU_REGISTER_TYPES_H
