extends "./test_base.gd"


static func setup_vm(vm, use_threads := false) -> void:
	.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_RISCV32
	vm.config.bios = "res://addons/gdtemu/native/bin/bbl32.bin"
	vm.config.kernel = "res://examples/riscv32/images/Image"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


func start():
	scene = preload("res://examples/riscv32/riscv32.tscn").instance()
	add_child_autoqfree(scene)
	vm = scene.get_node("VirtualMachine")
	terminal = scene.find_node("Terminal")
	scene.find_node("PowerButton").pressed = true
	while not "buildroot login: " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)
	vm.console_read("root\n".to_utf8())
	while not "# " in terminal.copy_all():
		yield(yield_to(vm, "console_wrote", 20), YIELD)


func test_riscv32_bios_and_kernel_only_no_thread():
	setup_vm(vm, false)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_riscv32_bios_and_kernel_only_with_thread():
	setup_vm(vm, true)
	add_child_autofree(vm)
	vm.start()
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_signal_emitted(vm, "console_wrote")


func test_riscv32_architecture():
	yield(start(), "completed")
	vm.console_read("uname -a\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_string_contains(terminal.copy_all(), "riscv32 GNU/Linux")


func test_riscv32_virtio_rng_device():
	yield(start(), "completed")
	vm.console_read("cat /sys/devices/virtual/misc/hw_random/rng_current\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_string_contains(terminal.copy_all(), "virtio_rng.0")
