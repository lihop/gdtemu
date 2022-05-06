extends "res://addons/gut/test.gd"

const VirtualMachine := preload("res://addons/gdtemu/virtual_machine.gd")
const VirtualMachineConfig := preload("res://addons/gdtemu/virtual_machine_config.gd")

var vm: VirtualMachine


func before_each():
	vm = VirtualMachine.new()


func after_each():
	if is_instance_valid(vm):
		vm.free()


# warning-ignore:shadowed_variable
static func setup_vm(vm, use_threads := false) -> void:
	var config := VirtualMachineConfig.new()
	vm.config = config
	vm.use_threads = use_threads
