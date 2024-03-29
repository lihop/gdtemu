# SPDX-FileCopyrightText: none
# SPDX-License-Identifier: CC0-1.0
extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug(
		"croconut/godot-tester",
		{
			commit = "360be4611a7cc344b6741735880725c7859ad0a6",
			install_root = "addons/gut/.cli_add",
			include = ["__rebuilder.gd", "__rebuilder_scene.tscn"]
		}
	)
	plug("bitwes/Gut", {commit = "70c08aebb318529fc7d3b07f7282b145f7512dee"})
	plug(
		"lihop/godot-pixelmatch",
		{commit = "8ad9ca5f180e6fd810823ebda2cb2e9e9d31c752", include = ["addons/pixelmatch"]}
	)
	plug("lihop/godot-xterm-dist", {tag = "v3.0.0-alpha2", include = ["addons/godot_xterm"]})
