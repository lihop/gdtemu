# SPDX-FileCopyrightText: none
# SPDX-License-Identifier: CC0-1.0
extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug("bitwes/Gut", {commit = "70c08aebb318529fc7d3b07f7282b145f7512dee"})
	plug(
		"lihop/godot-xterm-dist",
		{commit = "a1131a562e8e8f0c57b0ddf61de7fa015d463ba0", include = ["addons/godot_xterm"]}
	)
