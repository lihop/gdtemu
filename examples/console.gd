# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends PanelContainer

signal powered_on
signal powered_off
signal paused
signal unpaused

export(bool) var autostart := false
export(String) var note := "" setget set_note, get_note

var powered_on := false
var paused := false

onready var _terminal := find_node("Terminal")


func set_note(value: String) -> void:
	$_/_/Label.text = value


func get_note() -> String:
	return $_/_/Label.text


func _ready():
	if autostart:
		$_/_/PowerButton.pressed = true
	else:
		_terminal.focus_mode = FOCUS_NONE
		$_/_/PowerButton.grab_focus()


func _on_PowerButton_toggled(button_pressed: bool) -> void:
	powered_on = button_pressed
	paused = false
	if not powered_on:
		$_/_/PauseButton.disabled = true
		$_/_/PauseButton.pressed = false
		$_/_/PowerButton.grab_focus()
		_terminal.focus_mode = FOCUS_NONE
		_terminal.write("\u001bc")  # Resets terminal.
		emit_signal("powered_off")
	else:
		$_/_/PauseButton.disabled = false
		_terminal.focus_mode = FOCUS_ALL
		_terminal.grab_focus()
		emit_signal("powered_on")


func _on_PauseButton_toggled(button_pressed: bool) -> void:
	paused = button_pressed
	if paused:
		emit_signal("paused")
	else:
		emit_signal("unpaused")
	_terminal.grab_focus()
