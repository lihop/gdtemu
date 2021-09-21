# SPDX-FileCopyrightText: 2021 Leroy Hopson <gdtemu@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug("lihop/godot-xterm-dist", {commit = "6534aa3379ef09eca70a3e42539e47fe31ce07e4"})
