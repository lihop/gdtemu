# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

enum Mode {
	READ,
	READ_WRITE,
	SNAPSHOT,
}
const MODE_READ := Mode.READ
const MODE_READ_WRITE := Mode.READ_WRITE
const MODE_SNAPSHOT := Mode.SNAPSHOT

export(String, FILE) var file := ""
export(Mode) var mode := MODE_READ_WRITE


func _init(p_file := "", p_mode := MODE_READ_WRITE):
	file = p_file
	mode = p_mode
