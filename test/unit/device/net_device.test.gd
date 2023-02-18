extends "res://addons/gut/test.gd"

const NetDevice := preload("res://addons/gdtemu/device/net_device.gd")

var dev: NetDevice


func before_each():
	dev = NetDevice.new()


func test__get_port_forwards_parsed():
	dev.port_forwards = PackedStringArray(["tcp:127.0.0.1:5077-0.0.0.0:22"])
	var parsed = dev._get_port_forwards_parsed()
	assert_eq_deep(
		parsed,
		[
			{
				proto = "tcp",
				host_addr = "127.0.0.1",
				host_port = 5077,
				guest_addr = "0.0.0.0",
				guest_port = 22,
			}
		]
	)
