# SPDX-FileCopyrightText: 2022-2023 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const Port := preload("res://addons/gdtemu/util/port.gd")


func test_gets_port():
	var port := Port.get_unused_port()
	assert_typeof(port, TYPE_INT)


func test_gets_port_in_single_range():
	var unused_port := Port.get_unused_port()
	var port := Port.get_unused_port(unused_port, unused_port)
	assert_eq(port, unused_port)


func test_gets_unused_port_in_range():
	var port := Port.get_unused_port(47761, 47762)
	assert_lt(port, 47763)
	assert_gt(port, 47760)


func test_gets_unused_port():
	var used_port := Port.get_unused_port()
	var server := TCPServer.new()
	server.listen(used_port)
	var port := Port.get_unused_port(used_port, used_port + 1)
	assert_ne(port, used_port)
	assert_eq(port, used_port + 1)


func test_returns_negative_one_if_no_port_available():
	var used_port := Port.get_unused_port()
	var server := TCPServer.new()
	server.listen(used_port)
	assert_eq(Port.get_unused_port(used_port, used_port), -1)


func test_returns_negative_one_if_port_max_out_of_range():
	assert_eq(Port.get_unused_port(90000000, 99999999), -1)


func test_returns_negative_one_if_port_min_out_of_range():
	assert_eq(Port.get_unused_port(0, 5050), -1)


func test_returns_negative_one_if_port_min_greater_than_port_max():
	assert_eq(Port.get_unused_port(5050, 5049), -1)
