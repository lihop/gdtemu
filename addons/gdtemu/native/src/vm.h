// SPDX-FileCopyrightText: 2021-2022 Leroy Hopson <copyright@leroy.geek.nz>
// SPDX-License-Identifier: MIT

#ifndef GODOT_GDTEMU_VM_H
#define GODOT_GDTEMU_VM_H

extern "C" {
  #if defined(__linux__) && !defined(_WIN32) && !defined(__APPLE__)
  #include <net/if.h>
  #endif

  #include "cutils.h"
  #include "virtio.h"
  #include "machine.h"
  #include "temu.h"
}

#include <Godot.hpp>
#include <Resource.hpp>

#define MAX_EXEC_CYCLES 500000
#define MAX_SLEEP_TIME 10 /* in ms */

namespace godot {

class VM : public Reference {
  GODOT_CLASS(VM, Reference)

public:
  static void _register_methods();

  VM();
  ~VM();

  void _init();

  godot_error start(Resource *config);
  void run(int max_sleep_time_ms, int max_exec_cycles);
  void stop();

  godot_error console_read(PoolByteArray data);
  void console_resize(int width, int height);

private:
  VirtMachine *vm;
};
} // namespace godot

#endif // GODOT_GDTEMU_VM_H 