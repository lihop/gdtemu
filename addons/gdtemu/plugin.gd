# SPDX-FileCopyrightText: 2021 Leroy Hopson <gdtemu@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Emulator", "Node", preload("./emulator.gd"), null)


func _exit_tree():
	remove_custom_type("Emulator")
