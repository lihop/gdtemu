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
export(bool) var use_threads := true
export(Priority) var thread_priority := Priority.NORMAL
export(int) var max_sleep_time_ms := 10
export(int) var max_exec_cycles := 5000000

var paused := false setget set_paused

var _native_vm: NativeVM
var _thread: Thread
var _mutex := Mutex.new()
var _state := STATE_IDLE
var _console_buffer := PoolByteArray()
var _buffer_dirty := false


func set_config(value: VirtualMachineConfig) -> void:
	config = value if value is VirtualMachineConfig else VirtualMachineConfig.new()


func _ready():
	set_process(false)
	if autostart and not Engine.editor_hint:
		start()


func start() -> int:
	if _state == STATE_RUNNING:
		return ERR_ALREADY_IN_USE

	_native_vm = NativeVM.new()

	var err: int = _native_vm.start(config)
	if err != OK:
		_native_vm = null
		return err

	_state = STATE_RUNNING
	if use_threads:
		_native_vm.connect("console_wrote", self, "_on_console_wrote", [], CONNECT_DEFERRED)
		_thread = Thread.new()
		return _thread.start(self, "_thread_process", null, thread_priority)
	else:
		_native_vm.connect("console_wrote", self, "_on_console_wrote")
		set_process(true)

	return OK


func _process(_delta: float) -> void:
	if _native_vm:
		_native_vm.run(max_sleep_time_ms, max_exec_cycles)


func _thread_process(_data := null) -> void:
	while _state == STATE_RUNNING:
		_native_vm.run(max_sleep_time_ms, max_exec_cycles)


func set_paused(value: bool) -> void:
	paused = value
	if paused and _state == STATE_RUNNING:
		_state = STATE_PAUSED
		set_process(false)
		if _thread.is_active():
			_thread.wait_to_finish()
	elif not paused and _state == STATE_PAUSED:
		_state = STATE_RUNNING
		if use_threads:
			_thread = Thread.new()
			_thread.start(self, "_thread_process", null, thread_priority)
		else:
			set_process(true)


func stop():
	if _state == STATE_RUNNING or _state == STATE_PAUSED:
		_state = STATE_STOPPED
		if _thread and _thread.is_active():
			_thread.wait_to_finish()
		if _native_vm:
			_native_vm.stop()
			_native_vm = null


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
