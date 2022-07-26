extends "res://addons/gut/test.gd"

const FrameBuffer := preload("res://addons/gdtemu/device/frame_buffer.gd")
const Pixelmatch := preload("res://addons/pixelmatch/pixelmatch.gd")
const VirtualMachine := preload("res://addons/gdtemu/virtual_machine.gd")

var vm: VirtualMachine
var fb: FrameBuffer
var riscv32
var riscv64
var matcher := Pixelmatch.new()


func before_each():
	vm = VirtualMachine.new()
	add_child_autofree(vm)
	fb = FrameBuffer.new()
	vm.add_child(fb)
	riscv32 = preload("../helpers/riscv32_helper.gd").new()
	add_child_autofree(riscv32)
	riscv64 = preload("../helpers/riscv64_helper.gd").new()
	add_child_autofree(riscv64)


func test_no_warning_if_single_frame_buffer():
	assert_eq(fb._get_configuration_warning(), "")


func test_warning_if_multiple_frame_buffers():
	var fb2 = FrameBuffer.new()
	vm.add_child_below_node(fb, fb2)
	assert_ne(fb2._get_configuration_warning(), "")


func test_riscv_machines_shows_boot_logo():
	for helper in [riscv32, riscv64]:
		yield(yield_to(helper.start(), "completed", 120), YIELD)
		var fb = helper.vm.find_node("FrameBuffer")
		var expected: Image = preload("../snapshots/boot_logo.png").get_data()
		var actual: Image = fb.get_texture().get_data()
		var mismatch := matcher.diff(
			actual, expected, null, actual.get_width(), actual.get_height()
		)

		# Screen has blinking cursor up to 16 pixels in size, so ignore up to this
		# many pixels difference as we can't really time the blink.
		assert_lt(mismatch, 17, "Screen has too many different pixels to snapshot.")
