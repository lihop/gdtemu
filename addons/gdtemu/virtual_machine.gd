# SPDX-FileCopyrightText: 2022-2023 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends Node

const VirtualMachineConfig := preload("./virtual_machine_config.gd")

const _NetDevice := preload("./device/net_device.gd")

signal console_wrote(data)
signal transmitted(data, interface)

enum State {
	IDLE,
	RUNNING,
	PAUSED,
	STOPPED,
	ERRORED,
}
const STATE_IDLE = State.IDLE
const STATE_RUNNING = State.RUNNING
const STATE_PAUSED = State.PAUSED
const STATE_STOPPED = State.STOPPED

enum Priority {
	LOW,
	NORMAL,
	HIGH,
}

@export var config: Resource = null:
	set = set_config
@export var autostart := false
@export var use_threads := false:
	set = set_use_threads
@export var max_sleep_time_ms := 10
@export var max_exec_cycles := 5000000

var paused := false:
	set = set_paused

var _native_vm: VM  # TODO: Merge with VirtualMachine and rename to VirtualMachine.
var _state := STATE_IDLE
var _console_buffer := PackedByteArray()
var _buffer_dirty := false
var _frame_buffer = null


func set_use_threads(value: bool) -> void:
	if value:
		if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "macOS"]:
			use_threads = true
		else:
			push_error("Threads not supported on this platform.")
	else:
		use_threads = false


func set_config(value: VirtualMachineConfig) -> void:
	config = value if value is VirtualMachineConfig else VirtualMachineConfig.new()


func _ready():
	if autostart and not Engine.is_editor_hint():
		start()


func start() -> int:
	# HACK: User net_device driver doesn't work on windows or HTML5, so always set it to Raw.
	for net_device in config.net_devices:
		if OS.get_name() == "Windows" or OS.get_name() == "HTML5":
			net_device.driver = _NetDevice.DRIVER_RAW

	for child in get_children():
		match child.get_class():
			"FrameBuffer":
				if _frame_buffer and _frame_buffer != child:
					push_warning(
						(
							"Currently only a single FrameBuffer is supported. %s will be ignored."
							% child
						)
					)
				else:
					if config.machine_class == VirtualMachineConfig.MACHINE_CLASS_PC:
						push_error("FrameBuffer is not supported for PC machine class.")
					else:
						_frame_buffer = child
						if not _frame_buffer.is_connected(
							"size_changed", Callable(self, "_on_fb_size_changed")
						):
							_frame_buffer.connect(
								"size_changed", Callable(self, "_on_fb_size_changed")
							)

	if is_inside_tree():
		await (get_tree().process_frame)

	if _state == STATE_RUNNING:
		return ERR_ALREADY_IN_USE

	_native_vm = VM.new()
	if _frame_buffer:
		_frame_buffer._fb_native.vm = _native_vm

	if _frame_buffer:
		if not RenderingServer.is_connected("frame_pre_draw", Callable(self, "_on_frame_pre_draw")):
			RenderingServer.connect("frame_pre_draw", Callable(self, "_on_frame_pre_draw"))
		_native_vm.frame_buffer = _frame_buffer

	var err: int = _native_vm.start(config)
	if err != OK:
		_native_vm = null
		return err

	_state = STATE_RUNNING
	if use_threads:
		_native_vm.connect("console_wrote", Callable(self, "_on_console_wrote"), CONNECT_DEFERRED)
		_native_vm.connect("received", Callable(self, "_on_received"), CONNECT_DEFERRED)
		return _native_vm.run_thread(max_sleep_time_ms, max_exec_cycles)
	else:
		_native_vm.connect("console_wrote", Callable(self, "_on_console_wrote"))
		_native_vm.connect("received", Callable(self, "_on_received"))

	return OK


func _process(_delta: float) -> void:
	if not use_threads and _native_vm and _state == STATE_RUNNING:
		_native_vm.run(max_sleep_time_ms, max_exec_cycles)


func receive(data: PackedByteArray, interface := 0) -> int:
	if config.net_devices == null or config.net_devices.size() < interface + 1:
		push_error("VirtualMachine has no net_device at index %d." % interface)
		return ERR_PARAMETER_RANGE_ERROR

	if _native_vm:
		_native_vm.call_deferred("transmit", data, interface)
		return OK
	else:
		return FAILED


func set_paused(value: bool) -> void:
	paused = value
	if paused and _state == STATE_RUNNING:
		_state = STATE_PAUSED
		if use_threads:
			_native_vm.stop_thread()
	elif not paused and _state == STATE_PAUSED:
		_state = STATE_RUNNING
		if use_threads:
			_native_vm.run_thread(max_sleep_time_ms, max_exec_cycles)


func stop():
	if RenderingServer.is_connected("frame_pre_draw", Callable(self, "_on_frame_pre_draw")):
		RenderingServer.disconnect("frame_pre_draw", Callable(self, "_on_frame_pre_draw"))

	if _state == STATE_RUNNING or _state == STATE_PAUSED:
		_state = STATE_STOPPED
		if use_threads:
			_native_vm.stop_thread()
		_native_vm.stop()

	if (
		_frame_buffer
		and _frame_buffer.is_connected("size_changed", Callable(self, "_on_fb_size_changed"))
	):
		_frame_buffer.disconnect("size_changed", Callable(self, "_on_fb_size_changed"))


func _exit_tree():
	stop()


func console_read(data: PackedByteArray):
	if _native_vm and _state == STATE_RUNNING:
		_console_buffer.append_array(data)
		var err: int = _native_vm.console_read(data)
		if err == OK:
			_console_buffer.resize(0)


func console_resize(size: Vector2) -> void:
	if _native_vm:
		_native_vm.console_resize(size.x, size.y)


func _on_console_wrote(data: PackedByteArray):
	call_deferred("emit_signal", "console_wrote", data)


func _on_received(data: PackedByteArray, interface: int):
	call_deferred("emit_signal", "transmitted", data, interface)


func _on_frame_pre_draw():
	if _frame_buffer:
		_frame_buffer.refresh()


func _on_fb_size_changed():
	if not _state in [STATE_IDLE, STATE_STOPPED]:
		push_warning("New FrameBuffer size will not take effect until VirtualMachine is restarted.")
