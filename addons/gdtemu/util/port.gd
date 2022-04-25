# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT

# Returns an unused port in the given range suitable for use by a Godot TCP or
# UDP server. Range defaults to the dynamic/private port range.
# Returns null if no valid port could be found.
static func get_unused_port(port_min := 49152, port_max := 65535) -> int:
	assert(port_min <= port_max, "port_min must be less than port_max")
	assert(port_min >= 0, "port_min must be greater than -1")
	assert(port_max <= 65535, "port_max must be less 65536")

	var result = null
	var port := port_min
	var server := TCP_Server.new()

	while result == null and port <= port_max:
		if server.listen(port) == OK:
			result = port
		else:
			port += 1

	server.stop()
	return result
