# SPDX-FileCopyrightText: 2021-2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends EditorPlugin


func _enter_tree():
	add_custom_type(
		"VirtualMachine",
		"Node",
		preload("./virtual_machine.gd"),
		preload("./icons/virtual_machine_icon.svg")
	)
	add_custom_type("BlockDevice", "Resource", preload("./device/block_device.gd"), null)
	add_custom_type("NetDevice", "Resource", preload("./device/net_device.gd"), null)


func _exit_tree():
	remove_custom_type("NetDevice")
	remove_custom_type("BlockDevice")
	remove_custom_type("VirtualMachine")
