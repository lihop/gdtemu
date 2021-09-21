extends Node

const NativeEmulator := preload("./native/emulator.gdns")

signal console_data_received(data)

enum MachineClass {
	pc
	riscv32,
	riscv64,
	riscv128,
}

enum Status {
	NONE,
	RUNNING,
	ERROR,
}

export (MachineClass) var machine_class = MachineClass.riscv64 setget set_machine
export (int) var memory_size = 256 setget set_memory_size
export (String, FILE) var bios setget set_bios
export (String, FILE) var kernel setget set_kernel
export (String) var cmd_line setget set_cmd_line
export (String, FILE) var disk_image setget set_disk_image

export (Resource) var config

export (bool) var running := false
export (bool) var paused := false
export (bool) var auto_start := false

var _native_emulator = NativeEmulator.new()


func get_class() -> String:
	return "Emulator"


func set_machine(value: int = MachineClass.riscv64) -> void:
	machine_class = value
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change machine_class while emulator is running")
	else:
		_native_emulator.set("machine_class", machine_class)


func set_memory_size(value: int = 256) -> void:
	memory_size = value
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change memory_size while emulator is running")
	else:
		_native_emulator.set("memory_size", memory_size)


func set_bios(value: String = "") -> void:
	bios = ProjectSettings.globalize_path(value)
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change bios while emulator is running")
	else:
		_native_emulator.set("bios", bios)


func set_kernel(value: String = "") -> void:
	kernel = ProjectSettings.globalize_path(value)
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change kernel while emulator is running")
	else:
		_native_emulator.set("kernel", kernel)


func set_cmd_line(value: String = "") -> void:
	cmd_line = value
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change cmd_line while emulator is running")
	else:
		_native_emulator.set("cmd_line", cmd_line)


# TODO: Support attaching/removing disks while running.
func set_disk_image(value: String = "") -> void:
	disk_image = ProjectSettings.globalize_path(value)
	if _native_emulator.status == Status.RUNNING:
		push_warning("Cannot change disk_image while emulator is running")
	else:
		_native_emulator.set("disk_image", disk_image)


func _ready():
	add_child(_native_emulator)
	_native_emulator.connect("console_data_received", self, "_on_console_data_received")


func run():
	var new_config = {
		version = 1,
		machine = MachineClass.keys()[machine_class],
		memory_size = memory_size,
		bios = bios,
		kernel = kernel,
		cmdline = cmd_line,
		drive0 = {
			file = disk_image,
		},
	}
	
	for child in get_children():
		if child.get_class() == "Framebuffer":
			_native_emulator.add_device(child)
			new_config["display0"] = {
				device = "simplefb",
				width = child.width,
				height = child.height,
			}
			new_config["input_device"] = "virtio"
	
	if config:
		new_config.bios = ProjectSettings.globalize_path(config.bios)
		new_config.kernel = ProjectSettings.globalize_path(config.kernel)
		new_config.machine = MachineClass.keys()[config.machine]
		new_config.memory_size = config.memory_size
		new_config.cmdline = config.cmdline
	
	# TODO: Not like this.
	var file := File.new()
	file.open("user://config.cfg", File.WRITE)
	file.store_string(JSON.print(new_config))
	file.close()
	_native_emulator.parse_config(ProjectSettings.globalize_path("user://config.cfg"))
	_native_emulator.run()


func interp(max_exec_cycles: int = 500000):
	if _native_emulator.status == Status.RUNNING:
		_native_emulator.interp(max_exec_cycles)


func add_child(node: Node, legible_unique_name := false):
	.add_child(node, legible_unique_name)


func remove_child(node: Node):
	.remove_child(node)


func _on_console_data_received(data: PoolByteArray):
	emit_signal("console_data_received", data)


func console_send(data: PoolByteArray) -> void:
	if _native_emulator.status == Status.RUNNING:
		_native_emulator.console_send(data)


func get_sleep_duration(max_sleep_time: int = 10) -> int:
	return _native_emulator.get_sleep_duration(max_sleep_time)
