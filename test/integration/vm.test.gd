extends "./test_base.gd"


func test_add_remove_vm_node():
	assert_true(is_instance_valid(vm))
	add_child(vm)
	remove_child(vm)
	vm.free()
	assert_false(is_instance_valid(vm))
