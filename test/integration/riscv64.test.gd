extends "./test_base.gd"


static func setup_vm(vm, use_threads := false) -> void:
	.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_RISCV64
	vm.config.bios = "res://addons/gdtemu/native/bin/bbl64.bin"
	vm.config.kernel = "res://examples/riscv64/images/Image"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


func start():
	scene = preload("res://examples/riscv64/riscv64.tscn").instance()
	add_child_autoqfree(scene)
	vm = scene.get_node("VirtualMachine")
	terminal = scene.get_node("_/Terminal")
	scene.get_node("_/_/PowerButton").pressed = true
	while not "buildroot login: " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("root\n".to_utf8())
	while not "Password: " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("root\n".to_utf8())
	while not "# " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)


func test_riscv64_bios_and_kernel_only_no_thread():
	setup_vm(vm, false)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_riscv64_bios_and_kernel_only_with_thread():
	setup_vm(vm, true)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_riscv64_architecture():
	yield(start(), "completed")
	vm.console_read("uname -a\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_string_contains(terminal.copy_all(), "riscv64 GNU/Linux")
