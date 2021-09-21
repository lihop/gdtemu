extends Control


func _ready():
	if not File.new().file_exists("user://rootfs.ext2"):
		Directory.new().copy("res://examples/files/rootfs.ext2", "user://rootfs.ext2")
	$Emulator.run()
	$Emulator.connect("console_data_received", self, "_on_data")
	set_process(true)


func _process(_delta):
	var delay = $Emulator.get_sleep_duration(10)
	if delay > 0:
		set_process(false)
		yield(get_tree().create_timer(delay * 0.001), "timeout")
		set_process(true)
	else:
		$Emulator.interp(1000000)


func _on_data(data):
	$Terminal.write(data)
