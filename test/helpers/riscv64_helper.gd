extends "./vm_helper.gd"


func _get_scene_path() -> String:
	return "res://examples/riscv64/riscv64.tscn"


func _start() -> void:
	var wrote := PoolByteArray()
	while wrote != "buildroot login: ".to_utf8():
		wrote = yield(vm, "console_wrote")
	vm.console_read("root\n".to_utf8())
	while wrote != "Password: ".to_utf8():
		wrote = yield(vm, "console_wrote")
	vm.console_read("root\n".to_utf8())
	while wrote != "# ".to_utf8():
		wrote = yield(vm, "console_wrote")
