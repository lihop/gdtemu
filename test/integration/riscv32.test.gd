extends "./test_base.gd"


static func setup_vm(vm, use_threads := false) -> void:
	.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_RISCV32
	vm.config.bios = "res://examples/riscv32/bbl32.bin"
	vm.config.kernel = "res://examples/riscv32/Image"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


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
