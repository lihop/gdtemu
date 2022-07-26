# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
tool
extends Viewport

const _FrameBufferNative := preload("../native/frame_buffer.gdns")
const _VirtualMachine := preload("../virtual_machine.gd")

export var ignore_alpha := true setget set_ignore_alpha

var _image := Image.new()
var _image_texture := ImageTexture.new()
var _texture_rect := TextureRect.new()
var _fb_native := _FrameBufferNative.new()
var _shader_material := ShaderMaterial.new()


func set_ignore_alpha(value: bool) -> void:
	ignore_alpha = value
	_shader_material.set_shader_param("ignore_alpha", ignore_alpha)


func _init():
	if not is_connected("size_changed", self, "_on_size_changed"):
		connect("size_changed", self, "_on_size_changed")


func _ready():
	_texture_rect.flip_v = true
	_texture_rect.rect_size = size
	_texture_rect.texture = _image_texture
	_texture_rect.material = ShaderMaterial.new()
	_texture_rect.material.shader = preload("./frame_buffer.shader")
	add_child(_texture_rect)


func refresh():
	if not _fb_native.vm:
		return

	_image.create_from_data(
		_fb_native.get_size().x,
		_fb_native.get_size().y,
		false,
		Image.FORMAT_RGBA8,
		_fb_native.get_data()
	)
	_image_texture.create_from_image(_image)


func _get_configuration_warning():
	# Check that parent node is VirtualMachine.
	if not get_parent() is _VirtualMachine:
		return "FrameBuffer only serves to provide a frame buffer to a VirtualMachine node. Please only use it as a child of VirtualMachine to give it a frame buffer."

	# Check that parent only has one FrameBuffer child.
	for child in get_parent().get_children():
		if child.is_class("FrameBuffer"):
			if child == self:
				break
			else:
				return "The VirtualMachine node currently only supports a single FrameBuffer. This FrameBuffer will be ignored."

	# No problems.
	return ""


func get_class():
	return "FrameBuffer"


func is_class(p_class: String) -> bool:
	return p_class == get_class()


func _notification(what: int):
	match what:
		NOTIFICATION_PARENTED, NOTIFICATION_UNPARENTED, NOTIFICATION_MOVED_IN_PARENT:
			update_configuration_warning()


func _on_size_changed():
	_texture_rect.rect_size = size
	refresh()
