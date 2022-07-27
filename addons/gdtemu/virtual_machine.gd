# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Node

const NativeVM := preload("./native/vm.gdns")
const VirtualMachineConfig := preload("./virtual_machine_config.gd")

signal console_wrote(data)

enum State {
	IDLE,
	ERRORED,
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

export(Resource) var config = null setget set_config
export(bool) var autostart := false
export(bool) var use_threads := false setget set_use_threads
export(int) var max_sleep_time_ms := 10
export(int) var max_exec_cycles := 5000000

var paused := false setget set_paused

var _native_vm: NativeVM
var _state := STATE_IDLE
var _console_buffer := PoolByteArray()
var _buffer_dirty := false
var _frame_buffer: Viewport = null


func set_use_threads(value: bool) -> void:
	if OS.get_name() in ["X11", "Server", "OSX"]:
		use_threads = value
	else:
		push_error("Use threads not supported on this platform.")
		use_threads = false


func set_config(value: VirtualMachineConfig) -> void:
	config = value if value is VirtualMachineConfig else VirtualMachineConfig.new()


func _ready():
	if autostart and not Engine.editor_hint:
		start()


func start() -> int:
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
							"size_changed", self, "_on_fb_size_changed"
						):
							_frame_buffer.connect("size_changed", self, "_on_fb_size_changed")

	if is_inside_tree():
		yield(get_tree(), "idle_frame")

	if _state == STATE_RUNNING:
		return ERR_ALREADY_IN_USE

	_native_vm = NativeVM.new()
	if _frame_buffer:
		_frame_buffer._fb_native.vm = _native_vm

	if _frame_buffer:
		if not VisualServer.is_connected("frame_pre_draw", self, "_on_frame_pre_draw"):
			VisualServer.connect("frame_pre_draw", self, "_on_frame_pre_draw")
		_native_vm.frame_buffer = _frame_buffer

	var err: int = _native_vm.start(config)
	if err != OK:
		_native_vm = null
		return err

	_state = STATE_RUNNING
	if use_threads:
		_native_vm.connect("console_wrote", self, "_on_console_wrote", [], CONNECT_DEFERRED)
		return _native_vm.run_thread(max_sleep_time_ms, max_exec_cycles)
	else:
		_native_vm.connect("console_wrote", self, "_on_console_wrote")

	return OK


func _process(_delta: float) -> void:
	if not use_threads and _native_vm and _state == STATE_RUNNING:
		_native_vm.run(max_sleep_time_ms, max_exec_cycles)


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
	if VisualServer.is_connected("frame_pre_draw", self, "_on_frame_pre_draw"):
		VisualServer.disconnect("frame_pre_draw", self, "_on_frame_pre_draw")

	if _state == STATE_RUNNING or _state == STATE_PAUSED:
		_state = STATE_STOPPED
		if use_threads:
			_native_vm.stop_thread()
		_native_vm.stop()

	if _frame_buffer and _frame_buffer.is_connected("size_changed", self, "_on_fb_size_changed"):
		_frame_buffer.disconnect("size_changed", self, "_on_fb_size_changed")


func _exit_tree():
	stop()


func console_read(data: PoolByteArray):
	if _native_vm and _state == STATE_RUNNING:
		_console_buffer.append_array(data)
		var err: int = _native_vm.console_read(data)
		if err == OK:
			_console_buffer.resize(0)


func console_resize(size: Vector2) -> void:
	if _native_vm:
		_native_vm.console_resize(size.x, size.y)


func _on_console_wrote(data: PoolByteArray):
	call_deferred("emit_signal", "console_wrote", data)


func _on_frame_pre_draw():
	if _frame_buffer:
		_frame_buffer.refresh()


func _on_fb_size_changed():
	if not _state in [STATE_IDLE, STATE_STOPPED]:
		push_warning("New FrameBuffer size will not take effect until VirtualMachine is restarted.")
