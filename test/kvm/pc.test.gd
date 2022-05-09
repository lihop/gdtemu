# GitHub Actions does not support KVM so keep these tests in a separate directory.
extends "../integration/test_base.gd"

# GitHub Actions runners don't support KVM.
var ci := OS.get_environment("GITHUB_ACTIONS") == "true"


static func setup_vm(vm, use_threads := false) -> void:
	.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_PC
	vm.config.kernel = "res://examples/pc/bzImage"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


func test_pc_kernel_only_no_thread():
	if ci:
		return
	setup_vm(vm, false)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_pc_kernel_only_with_thread():
	if ci:
		return
	setup_vm(vm, true)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_pc_example():
	if ci:
		return
	var scene := preload("res://examples/pc/pc.tscn").instance()
	add_child_autoqfree(scene)
	var vm = scene.get_node("VirtualMachine")
	var terminal = scene.get_node("_/Terminal")
	scene.get_node("_/_/PowerButton").pressed = true
	while not "buildroot login: " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("root\n".to_utf8())
	while not "Password: " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("root\n".to_utf8())
	while not "# " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("uname -a\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_string_contains(terminal.copy_all(), "x86_64 GNU/Linux")
