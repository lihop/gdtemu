extends "./test_base.gd"

const NetDevice := preload("res://addons/gdtemu/device/net_device.gd")


static func setup_vm(vm, use_threads := false) -> void:
	.setup_vm(vm, use_threads)
	vm.config.machine_class = vm.config.MACHINE_CLASS_RISCV64
	vm.config.bios = "res://addons/gdtemu/native/bin/bbl64.bin"
	vm.config.kernel = "res://examples/riscv64/images/Image"
	vm.config.cmdline = "loglevel=1 printk.time=0 console=hvc0"


func before_each():
	scene = preload("res://examples/riscv64/riscv64.tscn").instance()
	add_child_autoqfree(scene)


func start():
	vm = scene.get_node("VirtualMachine")
	terminal = scene.find_node("Terminal")
	scene.find_node("PowerButton").pressed = true
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


func test_riscv64_virtio_rng_device():
	yield(start(), "completed")
	vm.console_read("cat /sys/devices/virtual/misc/hw_random/rng_current\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 20), YIELD)
	assert_string_contains(terminal.copy_all(), "virtio_rng.0")


func test_raw_network_interface():
	var vm = scene.find_node("VirtualMachine")
	vm.config.net_devices[0].driver = NetDevice.DRIVER_RAW
	yield(start(), "completed")
	vm.connect("transmitted", self, "_arp_reply")
	# eth0 is configured to use dhcp so we need to assign an IP manually.
	vm.console_read("ip addr add 192.168.12.18/24 dev eth0\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 10), YIELD)
	vm.console_read("arping -I eth0 -c 1 192.168.12.19\n".to_utf8())
	yield(yield_to(vm, "console_wrote", 10), YIELD)  # First output is log of unicast ARP reply.
	yield(yield_to(vm, "console_wrote", 10), YIELD)
	assert_string_contains(terminal.copy_all(), "Received 1 response")


func _arp_reply(data: PoolByteArray, interface) -> void:
	var dest_mac = Array(data.subarray(6, 11))
	var src_mac = [0xE, 0, 0, 0, 0, 2]
	var ether_type = [8, 6]  # ARP.
	var padding = [0]
	var hardware_type = [1]  # Ethernet.
	var protocol_type = [8, 0]  # IPv4.
	var hardware_size = [6]
	var protocol_size = [4]
	var opcode = [2]  # Reply.
	var sender_mac = src_mac
	var sender_ip = [192, 168, 12, 19]
	var target_mac = dest_mac
	var target_ip = Array(data.subarray(28, 31))

	if data.subarray(0, 5) == PoolByteArray([255, 255, 255, 255, 255, 255]):
		# ARP request to broadcast address. Reply with fake MAC address for requested IP.
		vm.receive(
			PoolByteArray(
				(
					dest_mac
					+ src_mac
					+ ether_type
					+ padding
					+ hardware_type
					+ protocol_type
					+ hardware_size
					+ protocol_size
					+ padding
					+ opcode
					+ sender_mac
					+ sender_ip
					+ target_mac
					+ target_ip
				)
			),
			interface
		)
