# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

const BlockDevice := preload("./device/block_device.gd")
const NetDevice := preload("./device/net_device.gd")

const MAX_BLOCK_DEVICES := 4
const MAX_NET_DEVICES := 1

enum MachineClass {
	PC = 1,
	RISCV32,
	RISCV64,
}
const MACHINE_CLASS_PC := MachineClass.PC
const MACHINE_CLASS_RISCV32 := MachineClass.RISCV32
const MACHINE_CLASS_RISCV64 := MachineClass.RISCV64

export(MachineClass) var machine_class := MACHINE_CLASS_PC
export(int) var memory_size := 256
export(String, FILE) var bios := ""
export(String, FILE) var kernel := ""
export(String) var cmdline := ""
export(Array, Resource) var block_devices := [] setget set_block_devices
export(Array, Resource) var net_devices := [] setget set_net_devices


func _init(
	p_machine_class := MACHINE_CLASS_PC,
	p_memory_size := 256,
	p_bios := "",
	p_kernel := "",
	p_cmdline := "",
	p_block_devices := []
):
	machine_class = p_machine_class
	memory_size = p_memory_size
	bios = p_bios
	kernel = p_kernel
	cmdline = p_cmdline
	block_devices = p_block_devices


func _set_devices(value: Array, type: String) -> Array:
	var devices := []
	var maximum: int = get("MAX_%s_DEVICES" % type.to_upper())
	var script: GDScript = get("%sDevice" % type)
	if value.size() > maximum:
		value = value.slice(0, maximum - 1)
		push_warning("Maximum number of %s devices is %s." % [type.to_lower(), maximum])
	for i in value.size():
		if not value[i] is script:
			value[i] = script.new()
	return value


func set_block_devices(value := []):
	block_devices = _set_devices(value, "Block")


func set_net_devices(value := []):
	net_devices = _set_devices(value, "Net")
