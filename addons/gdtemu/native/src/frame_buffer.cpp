// SPDX-FileCopyrightText: 2022 Leroy Hopson
// SPDX-License-Identifier: MIT

#include "frame_buffer.h"

#define IF_NO_FB_DEV_RETURN(what)                                              \
  if (!vm.is_valid()) {                                                        \
    ERR_PRINT("FrameBuffer does not have a valid VM.");                        \
    return what;                                                               \
  }                                                                            \
  if (!vm->vm || !vm->vm->fb_dev) {                                            \
    ERR_PRINT("FrameBuffer VM does not have a FrameBuffer device.");           \
    return what;                                                               \
  }

using namespace godot;

void FrameBuffer::_register_methods() {
  register_method("_init", &FrameBuffer::_init);
  register_method("get_size", &FrameBuffer::get_size);
  register_method("get_data", &FrameBuffer::get_data);

  register_property<FrameBuffer, Ref<VM>>("vm", &FrameBuffer::vm, Ref<VM>());
}

void FrameBuffer::_init() {
  vm = Ref<VM>();
  data = PoolByteArray();
}

Vector2 FrameBuffer::get_size() {
  IF_NO_FB_DEV_RETURN(Vector2::ZERO);

  return Vector2(vm->vm->fb_dev->width, vm->vm->fb_dev->height);
}

static void fb_dev_update(FBDevice *fb_dev, void *opaque, int x, int y, int w,
                          int h) {
  int *dirty = (int *)opaque;
  *dirty = 1;
}

PoolByteArray FrameBuffer::get_data() {
  IF_NO_FB_DEV_RETURN(PoolByteArray());

  int len = vm->vm->fb_dev->height * vm->vm->fb_dev->stride;

  if (data.size() != len)
    data.resize(len);

  int dirty = 0;
  vm->vm->fb_dev->refresh(vm->vm->fb_dev, fb_dev_update, &dirty);

  {
    uint32_t *src = (uint32_t *)vm->vm->fb_dev->fb_data;
    uint32_t *dest = (uint32_t *)data.write().ptr();

    // Format of src data is 0xAARRGGBB but needs to be 0xAABBGGRR for Godot's
    // RGBA8 image format, so leave the green and alpha channels alone and swap
    // the red and blue ones.
    for (int i = 0; i < vm->vm->fb_dev->width * vm->vm->fb_dev->height; i++) {
      dest[i] = (src[i] & 0xFF000000) |       // Alpha channel as is.
                (src[i] & 0x00FF0000) >> 16 | // Shift red channel to blue.
                (src[i] & 0x000000FF) << 16 | // Shift blue channel to red.
                (src[i] & 0x0000FF00);        // Green channel as is.
    }
  }

  return data;
}