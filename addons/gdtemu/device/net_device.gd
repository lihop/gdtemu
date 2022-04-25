# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

enum Driver {
	USER,
}
const DRIVER_USER := Driver.USER

export(Driver) var driver := DRIVER_USER
export(PoolStringArray) var port_forwards := PoolStringArray()


func _init(p_driver := DRIVER_USER, p_port_forwards := PoolStringArray()):
	driver = p_driver
	port_forwards = p_port_forwards


# Returns an array of port forwards in Dictionary form.
func _get_port_forwards_parsed() -> Array:
	var regex := RegEx.new()
	regex.compile(
		"^(?<proto>udp|tcp):(?<host_addr>(\\d+|\\.)*):(?<host_port>\\d+)-(?<guest_addr>(\\d+|\\.)*):(?<guest_port>\\d+)"
	)

	var result := []
	for port_forward in port_forwards:
		var matches: RegExMatch = regex.search(port_forward)
		if matches:
			result.append(
				{
					proto = matches.get_string("proto"),
					host_addr = matches.get_string("host_addr"),
					host_port = int(matches.get_string("host_port")),
					guest_addr = matches.get_string("guest_addr"),
					guest_port = int(matches.get_string("guest_port")),
				}
			)
	return result
