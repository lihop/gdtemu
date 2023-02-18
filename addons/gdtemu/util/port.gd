# SPDX-FileCopyrightText: 2022-2023 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT

# Returns an unused port in the given range suitable for use by a Godot TCP or
# UDP server. Range defaults to the dynamic/private port range.
# Returns null if no valid port could be found.
static func get_unused_port(port_min := 49152, port_max := 65535) -> int:
	if not port_min <= port_max:
		push_error("port_min must be less than port_max")
		return -1

	if not port_min >= 1:
		push_error("port_min must be greater than 0")
		return -1

	if not port_max <= 65535:
		push_error("port_max must be less 65536")
		return -1

	var result = -1
	var port := port_min
	var server := TCPServer.new()

	while result == -1 and port <= port_max:
		if server.listen(port) == OK:
			result = port
		else:
			port += 1

	server.stop()

	return result
