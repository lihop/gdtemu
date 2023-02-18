# GitHub Actions does not support KVM so keep these tests in a separate directory.
extends "../integration/test_base.gd"

# GitHub Actions runners don't support KVM.
var ci := OS.get_environment("GITHUB_ACTIONS") == "true"


static func setup_vm(vm, use_threads := false) -> void:
	super.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_PC
	vm.config.kernel = "res://examples/pc/images/bzImage"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


# FIXME
func skip_test_pc_kernel_only_no_thread():
	if ci:
		return
	setup_vm(vm, false)
	add_child_autofree(vm)
	vm.start()
	await wait_for_signal(vm.console_wrote, 60)
	assert_signal_emitted(vm, "console_wrote")


func test_pc_kernel_only_with_thread():
	if ci:
		return
	setup_vm(vm, true)
	add_child_autofree(vm)
	vm.start()
	await wait_for_signal(vm.console_wrote, 60)
	assert_signal_emitted(vm, "console_wrote")


# FIXME
func skip_test_pc_example():
	if ci:
		return
	var scene := preload("res://examples/pc/pc.tscn").instantiate()
	add_child_autoqfree(scene)
	var vm = scene.get_node("VirtualMachine")
	var terminal = scene.find_child("Terminal")
	scene.get_node("_/_/PowerButton").pressed = true
	while not "buildroot login: " in terminal.copy_all():
		await wait_for_signal(vm.console_wrote, 20)
	vm.console_read("root\n".to_utf8_buffer())
	while not "Password: " in terminal.copy_all():
		await wait_for_signal(vm.console_wrote, 20)
	vm.console_read("root\n".to_utf8_buffer())
	while not "# " in terminal.copy_all():
		await wait_for_signal(vm.console_wrote, 20)
	vm.console_read("uname -a\n".to_utf8_buffer())
	await wait_for_signal(vm.console_wrote, 20)
	assert_string_contains(terminal.copy_all(), "x86_64 GNU/Linux")
