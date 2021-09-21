// SPDX-FileCopyrightText: 2021 Leroy Hopson <gdtemu@leroy.geek.nz>
// SPDX-License-Identifier: MIT

#ifndef GDTEMU_EMULATOR_H
#define GDTEMU_EMULATOR_H


extern "C" {
  // TODO: Copied directly from temu.c. Probably don't need all of these.
  #include <stdlib.h>
  #include <stdio.h>
  #include <stdarg.h>
  #include <string.h>
  #include <inttypes.h>
  #include <assert.h>
  #include <fcntl.h>
  #include <errno.h>
  #include <unistd.h>
  #include <time.h>
  #include <getopt.h>
  #ifndef _WIN32
  #include <termios.h>
  #include <sys/ioctl.h>
  #endif
  #if !defined(_WIN32) && !defined(__APPLE__)
  #include <net/if.h>
  #include <linux/if_tun.h>
  #endif
  #include <sys/stat.h>
  #include <signal.h>
  #ifdef __APPLE__
  #include <TargetConditionals.h>
  #endif

  #include "cutils.h"
  #include "iomem.h"
  #include "virtio.h"
  #include "machine.h"
  #ifdef CONFIG_FS_NET
  #include "fs_utils.h"
  #include "fs_wget.h"
  #endif
  #ifdef CONFIG_SLIRP
  #include "slirp/libslirp.h"
  #endif
}

#include <File.hpp>
#include <Godot.hpp>
#include <Node.hpp>
#include <ImageTexture.hpp>

namespace godot {

class Emulator : public Node {
  GODOT_CLASS(Emulator, Node)

public:
  static void _register_methods();

  Emulator();
  ~Emulator();

  void _init();
  void _ready();
  void _process(float delta);

  void parse_config(String config_file_path);
  void run();
  void interp(int max_exec_cycles);
  void console_send(PoolByteArray data);

  void add_device(Node *device);
  void remove_device(Node *device);

  int get_sleep_duration(int max_sleep_time);

  enum Status {
    NONE,
    RUNNING,
    ERROR,
  };
  int status;

  String bios;
  String kernel;
  String drive;

  PoolByteArray console_buffer;
  //Ref<ImageTexture> fb_texture;
  Ref<Image> fb_image;

private:
  VirtMachine *vm;
  VirtMachineParams *params;

  Node *framebuffer; // Support only a single framebuffer for now.
};
} // namespace godot

#endif // GDTEMU_EMULATOR_H
