// SPDX-FileCopyrightText: 2021 Leroy Hopson <gdtemu@leroy.geek.nz> 
// SPDX-License-Identifier: MIT

#include "emulator.h"

extern "C" {
  #include <temu.h>
}

using namespace godot;

//typedef struct BlockDeviceFile {
//  Ref<File> file;
//  int64_t nb_sectors;
//  BlockDeviceModeEnum mode;
//  int needs_flush = 0;
//} BlockDeviceFile;

//static int64_t bf_get_sector_count(BlockDevice *bs) {
//  BlockDeviceFile *bf = static_cast<BlockDeviceFile*>(bs->opaque);
//  return bf->nb_sectors;
//}
//
//static int bf_read_async(BlockDevice *bs, uint64_t sector_num, uint8_t *buf, int n, BlockDeviceCompletionFunc *cb, void *opaque) {
//  BlockDeviceFile *bf = static_cast<BlockDeviceFile*>(bs->opaque);
//
//  if (!bf->file.is_valid())
//    return -1;
//
//  if (bf->needs_flush > 0) {
//    bf->file->flush();
//    bf->needs_flush = 0;
//  }
//
//  bf->file->seek(sector_num * SECTOR_SIZE);
//  PoolByteArray data = bf->file->get_buffer(n * SECTOR_SIZE);
//  memcpy(buf, data.read().ptr(), n * SECTOR_SIZE);
//
//  /* synchronous read */
//  return 0;
//}
//
//static int bf_write_async(BlockDevice *bs, uint64_t sector_num, const uint8_t *buf, int n, BlockDeviceCompletionFunc *cb, void *opaque) {
//  BlockDeviceFile *bf = static_cast<BlockDeviceFile*>(bs->opaque);
//
//  if (!bf->file.is_valid() || bf->mode == BF_MODE_RO)
//    return -1; /* error */
//
//  if (bf->needs_flush >= 1000) {
//    bf->file->flush();
//    bf->needs_flush = 0;
//  }
//
//  PoolByteArray data = PoolByteArray();
//  data.resize(n * SECTOR_SIZE);
//  {
//    memcpy(data.write().ptr(), buf, n * SECTOR_SIZE);
//  }
//
//  bf->file->seek(sector_num * SECTOR_SIZE);
//  bf->file->store_buffer(data);
//  bf->needs_flush += 1;
//
//  return 0;
//}

// static std::pair<Error, BlockDevice*> _dont_use_block_device_init(const char *filename, BlockDeviceModeEnum mode) {
//   BlockDevice *bs = new BlockDevice();
//   BlockDeviceFile *bf = new BlockDeviceFile();
//   Ref<File> file = File::_new();
//   File::ModeFlags mode_flag;

//   if (mode == BF_MODE_RW) {
//     mode_flag = File::READ_WRITE; 
//   } else {
//     mode_flag = File::READ;
//   }

//   Error err = file->open(filename, mode_flag);
//   if (err != Error::OK) {
//     // TODO: More informative error message using push_error().
//     return std::make_pair(err, nullptr);
//   }

//   bf->mode = mode;
//   Godot::print(filename);
//   printf("Got length of file: %ld\n", file->get_len());
//   Godot::print(file->get_len());
//   bf->nb_sectors = file->get_len() / SECTOR_SIZE;
//   bf->file = file;

//   bs->opaque = bf;
//   bs->get_sector_count = bf_get_sector_count;
//   bs->read_async = bf_read_async;
//   bs->write_async = bf_write_async;

//   return std::make_pair(Error::OK, bs);
// }

void Emulator::_register_methods() {
  register_signal<Emulator>("console_data_received", "data", GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY);

  register_property<Emulator, int>("status", &Emulator::status, (int)Status::NONE);
  register_property<Emulator, String>("bios", &Emulator::bios, "");
  register_property<Emulator, Ref<Image>>("fb_image", &Emulator::fb_image, Ref<Image>(Image::_new()));

  register_method("_init", &Emulator::_init);
  register_method("_ready", &Emulator::_ready);
  register_method("_process", &Emulator::_process);

  register_method("parse_config", &Emulator::parse_config);
  register_method("run", &Emulator::run);
  register_method("interp", &Emulator::interp);
  register_method("console_send", &Emulator::console_send);

  register_method("add_device", &Emulator::add_device);
  register_method("remove_device", &Emulator::remove_device);

  register_method("get_sleep_duration", &Emulator::get_sleep_duration);
}

Emulator::Emulator() {
  status = Status::NONE;
  params = new VirtMachineParams();
  vm = new VirtMachine();

  //fb_texture = Ref<ImageTexture>(ImageTexture::_new()); 
  fb_image = Ref<Image>(Image::_new());
  fb_image->create(640, 480, false, Image::FORMAT_RGBA8);
}

Emulator::~Emulator() {}

void Emulator::_init() {
  virt_machine_set_defaults(params);
  //fb_texture->set_data(fb_image);
}

void Emulator::_ready() {
  Godot::print("Working!");

  // Add the kernel command-line parameters.
  params->cmdline = String("Linux is the best!").alloc_c_string();
  params->accel_enable = false;
  params->eth_count = 0;

  // TODO: riscv128, riscv32, x86?
  params->machine_name = String("riscv64").alloc_c_string();
  params->vmc = &riscv_machine_class; 

  params->ram_size = (uint64_t)256 << 20; // 256 MB
}

static int console_read(void *opaque, uint8_t *buf, int len) {
  Emulator *emu = static_cast<Emulator*>(opaque);

  int n = std::min(len, emu->console_buffer.size());

  if (n <= 0)
    return 0;

  for(int i = 0; i < n; i++)
    buf[i] = emu->console_buffer[i];
  for(int i = 0; i < n; i++)
    emu->console_buffer.remove(0);

  return n;
}

static void console_write(void *opaque, const uint8_t *buf, int len) {
  PoolByteArray data = PoolByteArray();
  data.resize(len);

  {
  memcpy(data.write().ptr(), buf, len);
  }

  Emulator *emu = static_cast<Emulator*>(opaque);
  emu->emit_signal("console_data_received", data);
}

// static void fb_refresh(void *opaque, const uint8_t *data, int x, int y, int w, int h, int stride) {
//   Ref<Image> image = static_cast<Ref<Image>>(opaque);
//   int i, j, v, dst_pos, width, height, dst_pos1, image_stride;
//   const uint8_t* src;
//   image->lock();
//   width = image->get_width();
//   PoolByteArray::Write *data = image->get_data().write();
//   dst_pos1 = (y * width + x) * 4;
//   for (i = 0; i < h; i = (i + 1) | 0) {
//     src = data;
//     dst_pos = dst_pos1;
//     for (j = 0; j < w; j = (j + 1) | 0) {
//       data[dst_pos] = (src >> 16) & 0xff;
//     }
//   }
//   image->unlock();
// }

// static void fb_refresh1(FBDevice *fb_dev, void *opaque, int x, int y, int w, int h) {
//   int stride = fb_dev->stride;
//   fb_refresh(opaque, fb_dev->fb_data + y * stride + x * 4, x, y, w, h, stride);
// }

void Emulator::run() {
//  params->files[VM_FILE_BIOS].filename = strdup(bios.alloc_c_string());
//  params->files[VM_FILE_KERNEL].filename = strdup(kernel.alloc_c_string());
  params->accel_enable = false;

  // Initialize console.
  CharacterDevice *console = new CharacterDevice(); 

  console->opaque = this; 
  console->read_data = console_read;
  console->write_data = console_write;
  params->console = console;

  // Must do!!!!!
  // Open files and devices;
  for (int i = 0; i < params->drive_count; i++) {
    BlockDevice *drive;
    BlockDeviceModeEnum drive_mode = BF_MODE_RW;
    char *fname;
    fname = get_file_path(params->cfg_filename, params->tab_drive[i].filename);
    drive = block_device_init(fname, drive_mode);
    params->tab_drive[i].block_dev = drive; 

    //std::pair<Error, BlockDevice*> inited = block_device_init(fname, drive_mode);
    //if (inited.first == Error::OK) {
    //  params->tab_drive[i].block_dev = inited.second;
    //} else {
      // TODO: Handle error.
    //}
  }

  // Initialize virtual machine.
  vm = virt_machine_init(params);

  if (!vm) {
    status = Status::ERROR;
    Godot::print("VM not created!");
  } else {
    status = Status::RUNNING;
    Godot::print("VM created!");

    // Run vm one cycle.
    int MAX_EXEC_CYCLE = 500000;
    int MAX_SLEEP_TIME = 10; /* in ms */
    //set_process(true);
  }

  Godot::print("Still Working!");
}

int Emulator::get_sleep_duration(int max_sleep_time) {
  return status == Status::RUNNING ? virt_machine_get_sleep_duration(vm, max_sleep_time) : 0;
}

void Emulator::_process(float _delta) {
  if (status != Status::RUNNING)
    return;

  if (vm->console_dev && virtio_console_can_write_data(vm->console_dev)) {
    uint8_t buf[128];
    int ret, len;
    len = virtio_console_get_write_len(vm->console_dev);
    len = min_int(len, sizeof(buf));
    ret = vm->console->read_data(vm->console->opaque, buf, len);
    if (ret > 0)
      virtio_console_write_data(vm->console_dev, buf, ret);

    int w = 80;
    int h = 24;
    virtio_console_resize_event(vm->console_dev, w, h);
  }
}

void Emulator::parse_config(String config_file_path) {
  virt_machine_load_config_file(params, config_file_path.alloc_c_string(), NULL, NULL);
}

static void redraw(FBDevice *fb_dev, void *opaque, int x, int y, int w, int h) {
  // I don't understand this.
  int *dirty = (int*)opaque;
  *dirty = 1;
}

void Emulator::interp(int max_exec_cycles = 500000) {
  //if (vm->console_dev && virtio_console_can_write_data(vm->console))
  //Godot::print("interping");
  virt_machine_interp(vm, max_exec_cycles);

  // Update frame buffer texture.
  //fb_texture->create(1920, 1080, Image::FORMAT_RGBA8);

  if (framebuffer != nullptr) {
    int dirty = 0;
    vm->fb_dev->refresh(vm->fb_dev, redraw, &dirty);

    PoolByteArray data = PoolByteArray();
    data.resize(640 * 480 * 4);
    fb_image->create_from_data(640, 480, false, Image::FORMAT_RGBA8, data);

    fb_image->lock();

    uint8_t* fb_data = vm->fb_dev->fb_data;
    int stride = vm->fb_dev->stride;

    for (int x = 0; x < 640; x++) {
      for (int y = 0; y < 480; y++) {
        float r, g, b, a;
        r = (float)fb_data[(y * stride) + (x * 4) + 1];
        g = (float)fb_data[(y * stride) + (x * 4) + 2];
        b = (float)fb_data[(y * stride) + (x * 4) + 3];
        a = (float)fb_data[(y * stride) + (x * 4)];
        Color c = Color(r, g, b, a);
        fb_image->set_pixelv(Vector2(x, y), c);
      }
    }
  fb_image->unlock();
  }
  // We have some useful things.
  // fb_texture -> ImageTexture.
  // vm->fb_dev->fb_data -> raw pixel data.
  // vm->fb_dev->stride -> pitch (bytes in a row of pixel data?)

  //PoolByteArray data = PoolByteArray();
  //data.resize(640 * 480 * 4);
  //{
  //  memcpy(data.write().ptr(), &vm->fb_dev->fb_data, 640 * 480 * 4);
  //}
  //if (framebuffer) {
  //  ImageTexture *fb_texture = framebuffer->get("texture"); 
  //  Ref<Image> image = Image::_new();
  //  image->create_from_data(640, 480, false, Image::FORMAT_RGBA8, data);
  //  fb_texture->set_data(image);
  //  //fb_texture->set("size", Vector2(640, 480));
  //  //Ref<Image> image = Image::_new();
  //  //image->create_from_data(640, 480, false, Image::FORMAT_RGBA8, data);
  //  //fb_texture->create_from_image(image);
  //  //framebuffer->set("texture", fb_texture);
  //}

  //vm->fb_dev->fb_data;
}

void Emulator::console_send(PoolByteArray data) {
  console_buffer.append_array(data);
}

void Emulator::add_device(Node *device) {
  String device_class = device->get_class();

  if (device_class == "Framebuffer") {
    framebuffer = device;
    return;
  }
}

void Emulator::remove_device(Node *device) {
  String device_class = device->get_class();

  if (device_class == "Framebuffer" && framebuffer == device) {
    framebuffer = nullptr; 
  }
}