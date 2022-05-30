extends Control

const active_console_stylebox := preload("./active_console.stylebox")
const default_style := preload("./inactive_console.stylebox")


func _ready():
	if (
		OS.get_name() != "X11" and OS.get_name() != "Server"
		# GitHub Actions runners don't support KVM
		or OS.get_environment("GITHUB_ACTIONS") == "true"
	):
		$_/PC.queue_free()
		yield(get_tree(), "idle_frame")
	else:
		$_/PC/VirtualMachine.use_threads = true
		$_/PC/_/_/PowerButton.pressed = true

	if OS.get_name() != "Windows":
		$_/_/RISCV32/VirtualMachine.use_threads = true
		$_/_/RISCV64/VirtualMachine.use_threads = true

	$_/_/RISCV32/_/_/PowerButton.pressed = true
	$_/_/RISCV64/_/_/PowerButton.pressed = true


func _on_Console_focus_entered(node: String) -> void:
	var console: PanelContainer
	if node == "PC":
		console = get_node("_/PC")
	else:
		console = get_node("_/_/%s" % node)
	console.set("custom_styles/panel", active_console_stylebox)
	for member in get_tree().get_nodes_in_group("console"):
		if member != console:
			member.set("custom_styles/panel", default_style)
