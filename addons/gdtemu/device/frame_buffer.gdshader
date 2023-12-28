// SPDX-FileCopyrightText: 2022 Leroy Hopson
// SPDX-License-Identifier: MIT

shader_type canvas_item;

uniform bool ignore_alpha = true;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (ignore_alpha)
		COLOR.a = 1.0;
}
