// SPDX-FileCopyrightText: 2021-2023 Leroy Hopson <copyright@leroy.geek.nz>
// SPDX-License-Identifier: MIT

#ifndef GDTEMU_VM_H
#define GDTEMU_VM_H

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/sub_viewport.hpp>

#include <map>
#include <set>

extern "C" {
#if defined(__linux__) && !defined(_WIN32) && !defined(__APPLE__)
#include <net/if.h>
#endif
#include "cutils.h"
#include "virtio.h"
#include <time.h>

#include "machine.h"
#include "temu.h"
#if defined(CONFIG_SLIRP) && !defined(__WIN32) && !defined(EMSCRIPTEN)
#include "slirp/libslirp.h"
#endif
}

#define MAX_EXEC_CYCLES 500000
#define MAX_SLEEP_TIME 10 /* in ms */

using namespace godot;

class VM : public RefCounted {
  GDCLASS(VM, RefCounted)

public:
  VM();
  ~VM();

  void _init();

  Error start(Variant config);
  void run(int max_sleep_time_ms, int max_exec_cycles);
  void stop();

  int run_thread(int max_sleep_time_ms, int max_exec_cycles);
  void stop_thread();

  Error console_read(PackedByteArray data);
  void console_resize(int width, int height);
  void transmit(PackedByteArray data, int iface);

  bool thread_running = false;
  VirtMachine *vm;
  SubViewport *frame_buffer;
  std::map<int, PackedByteArray> net_buffers;

protected:
  static void _bind_methods();

private:
#if !defined(__WIN32) && !defined(EMSCRIPTEN)
  pthread_t thread;
#endif

public:
#if !defined(__WIN32) && !defined(EMSCRIPTEN)
  static std::set<pthread_t> threads;
  static pthread_t main_thread;
  Slirp *slirp_state;
#endif

  class BlockDeviceFile {
  public:
    Ref<FileAccess> f;
    int64_t nb_sectors;
    BlockDeviceModeEnum mode;
    uint8_t **sector_table;
  };
};

#endif // GDTEMU_VM_H
