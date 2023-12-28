extends Control


func _ready():
	if (
		OS.get_name() != "X11" and OS.get_name() != "Server"
		# GitHub Actions runners don't support KVM
		or OS.get_environment("GITHUB_ACTIONS") == "true"
	):
		$PC.queue_free()
		await (get_tree().process_frame)
	else:
		$PC/VirtualMachine.use_threads = true
		$PC/_/_/PowerButton.button_pressed = true

	if OS.get_name() != "Windows":
		$RISCV32/VirtualMachine.use_threads = true
		$RISCV64/VirtualMachine.use_threads = true

	if OS.get_name() != "OSX":
		$RISCV32/_/_/PowerButton.button_pressed = true
		$RISCV64/_/_/PowerButton.button_pressed = true

	# Only run one machine for HTML5 demo as resources are limited.
	if OS.get_name() == "HTML5":
		$RISCV32.queue_free()

	_on_tab_changed(0)


func _on_tab_changed(tab):
	get_child(tab).find_child("Terminal").grab_focus()
