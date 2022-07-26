extends "res://addons/gut/test.gd"

const FrameBuffer := preload("res://addons/gdtemu/device/frame_buffer.gd")

var fb: FrameBuffer


func before_each():
	fb = FrameBuffer.new()
	add_child_autofree(fb)


func test_get_class():
	assert_eq(fb.get_class(), "FrameBuffer")


func test_is_class():
	assert_true(fb.is_class("FrameBuffer"))
