extends Resource

enum Machine {
	pc,
	riscv32,
	riscv64,
	riscv128,
}

export (Machine) var machine := Machine.riscv64
export (int) var memory_size := 256
export (String, FILE) var bios setget set_bios, get_bios
export (String, FILE) var kernel setget set_kernel, get_kernel
export (String) var cmdline


func _init(p_machine := Machine.riscv64, p_memory_size := 256, p_bios := "",
		p_kernel := "", p_cmdline := ""):
	machine = p_machine
	memory_size = p_memory_size
	bios = p_bios
	kernel = p_kernel
	cmdline = p_cmdline


func set_bios(value: String) -> void:
	bios = ProjectSettings.globalize_path(value)


func get_bios() -> String:
	return ProjectSettings.localize_path(bios)


func set_kernel(value: String) -> void:
	kernel = ProjectSettings.globalize_path(value)


func get_kernel() -> String:
	return ProjectSettings.localize_path(kernel)
