// SPDX-FileCopyrightText: 2022-2023 Leroy Hopson
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

FrameBuffer::FrameBuffer() {
  vm = Ref<VM>();
  data = PackedByteArray();

  texture_rect->set_flip_v(true);
  texture_rect->set_texture(image_texture);
  texture_rect->set_material(shader_material);
  add_child(texture_rect);
  refresh();
}

FrameBuffer::~FrameBuffer() {}

void FrameBuffer::refresh() {
  texture_rect->set_size(get_size());
  image->create_from_data(get_size().x, get_size().y, false,
                          Image::FORMAT_RGBA8, get_data());
  image_texture->create_from_image(image);
}

Vector2 FrameBuffer::get_size() {
  IF_NO_FB_DEV_RETURN(Vector2(0, 0));

  return Vector2(vm->vm->fb_dev->width, vm->vm->fb_dev->height);
}

static void fb_dev_update(FBDevice *fb_dev, void *opaque, int x, int y, int w,
                          int h) {
  int *dirty = (int *)opaque;
  *dirty = 1;
}

PackedByteArray FrameBuffer::get_data() {
  IF_NO_FB_DEV_RETURN(PackedByteArray());

  int len = vm->vm->fb_dev->height * vm->vm->fb_dev->stride;

  if (data.size() != len)
    data.resize(len);

  int dirty = 0;
  vm->vm->fb_dev->refresh(vm->vm->fb_dev, fb_dev_update, &dirty);

  {
    uint32_t *src = (uint32_t *)vm->vm->fb_dev->fb_data;
    uint32_t *dest = (uint32_t *)data.ptrw();

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

void FrameBuffer::_bind_methods() {
  ClassDB::bind_method(D_METHOD("get_size"), &FrameBuffer::get_size);
  ClassDB::bind_method(D_METHOD("get_data"), &FrameBuffer::get_data);

  // register_property<FrameBuffer, Ref<VM>>("vm", &FrameBuffer::vm, Ref<VM>());
}

void FrameBuffer::_notification(int what) {
  switch (what) {
  case NOTIFICATION_WM_SIZE_CHANGED:
    refresh();
    break;
  case NOTIFICATION_PARENTED:
  case NOTIFICATION_UNPARENTED:
  case NOTIFICATION_MOVED_IN_PARENT:
    update_configuration_warnings();
    break;
  }
}
