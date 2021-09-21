extends Node

export (int) var width := 640
export (int) var height := 480

var texture := ImageTexture.new()


func get_class() -> String:
	return "Framebuffer"
