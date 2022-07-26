extends Node

const Terminal := preload("res://addons/godot_xterm/terminal.gd")
const VirtualMachine := preload("res://addons/gdtemu/virtual_machine.gd")

var scene: Node
var vm: VirtualMachine
var terminal: Terminal


func _get_scene_path() -> String:
	assert(false, "Not implemented.")
	return ""


func start() -> void:
	scene = load(_get_scene_path()).instance()
	vm = scene.find_node("VirtualMachine")
	terminal = scene.find_node("Terminal")
	add_child(scene)
	yield(get_tree(), "idle_frame")
	scene.find_node("PowerButton").pressed = true
	yield(_start(), "completed")


func _start() -> void:
	yield(get_tree(), "idle_frame")
	assert(false, "Not implemented.")
	return
