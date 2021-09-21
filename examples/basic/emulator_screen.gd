extends TextureRect

export (NodePath) var framebuffer_path setget set_framebuffer_path

var framebuffer setget set_framebuffer


func set_framebuffer_path(value: NodePath) -> void:
	framebuffer_path = value
	self.framebuffer = get_node_or_null(framebuffer_path)


func set_framebuffer(value: Node) -> void:
	framebuffer = value
	if framebuffer and "texture" in framebuffer and framebuffer.texture is Texture:
		texture = framebuffer.texture
