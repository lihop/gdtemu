// SPDX-FileCopyrightText: 2022 Leroy Hopson
// SPDX-License-Identifier: MIT

#ifndef GODOT_GDTEMU_FRAME_BUFFER_H
#define GODOT_GDTEMU_FRAME_BUFFER_H

#include "vm.h"

#include <Image.hpp>

namespace godot {

class FrameBuffer : public Reference {
  GODOT_CLASS(FrameBuffer, Reference)

public:
  static void _register_methods();

  void _init();
  Vector2 get_size();
  PoolByteArray get_data();

private:
  Ref<VM> vm;
  PoolByteArray data;
};
} // namespace godot

#endif // GODOT_GDTEMU_FRAME_BUFFER_H