// SPDX-FileCopyrightText: 2022-2023 Leroy Hopson
// SPDX-License-Identifier: MIT

#ifndef GDTEMU_FRAME_BUFFER_H
#define GDTEMU_FRAME_BUFFER_H

#include "vm.h"

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/sub_viewport.hpp>
#include <godot_cpp/classes/texture_rect.hpp>

using namespace godot;

class FrameBuffer : public SubViewport {
  GDCLASS(FrameBuffer, SubViewport)

public:
  FrameBuffer();
  ~FrameBuffer();

  bool ignore_alpha;
  void set_ignore_alpha(bool value) { ignore_alpha = value; };
  bool get_ignore_alpha() { return ignore_alpha; };

  Vector2 get_size();
  PackedByteArray get_data();
  void refresh();

  void _notification(int what);

protected:
  static void _bind_methods();

private:
  Ref<VM> vm;
  PackedByteArray data;

  Image *image = new Image();
  ImageTexture *image_texture = new ImageTexture();
  TextureRect *texture_rect = new TextureRect();
  ShaderMaterial *shader_material = new ShaderMaterial();
};

#endif // GDTEMU_FRAME_BUFFER_H
