// SPDX-FileCopyrightText: 2021-2022 Leroy Hopson <copyright@leroy.geek.nz> 
// SPDX-FileCopyrightText: 2019 Fernando Lemos
// SPDX-FileCopyrightText: 2016-2018 Fabrice Bellard
// SPDX-License-Identifier: MIT

#include "vm.h"

#include <ProjectSettings.hpp>

using namespace godot;

void VM::_register_methods() {
  register_signal<VM>("console_wrote", "data", GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY);

  register_method("_init", &VM::_init);

  register_method("start", &VM::start);
  register_method("run", &VM::run);
  register_method("stop", &VM::stop);

  register_method("console_read", &VM::console_read);
  register_method("console_resize", &VM::console_resize);
}

VM::VM() {}
VM::~VM() {}

void VM::_init() {}

static int _console_read(void *opaque, uint8_t *buf, int len) {
  return 0;
}

static void _console_write(void *opaque, const uint8_t *buf, int len) {
  PoolByteArray data = PoolByteArray();
  data.resize(len);

  {
    memcpy(data.write().ptr(), buf, len);
  }

  VM *vm = static_cast<VM*>(opaque);
  vm->emit_signal("console_wrote", data);
}

godot_error VM::start(Resource *config) {
  ProjectSettings *proj_settings = ProjectSettings::get_singleton();

  VirtMachineParams params_s, *params = &params_s;
  virt_machine_set_defaults(params);

  int machine_class = config->get("machine_class");
  if (machine_class == 1) {
    params->machine_name = (char*)"pc";
    params->vmc = &pc_machine_class;
  } else if (machine_class >= 2 && machine_class <= 4) {
    params->vmc = &riscv_machine_class;
    switch (machine_class) {
      case 2:
        params->machine_name = (char*)"riscv32"; 
        break;
      case 3:
        params->machine_name = (char*)"riscv64"; 
        break;
      case 4:
        params->machine_name = (char*)"riscv128";
        break;
    }
  } else {
    ERR_PRINT("Unrecognized machine class.");
    return GODOT_FAILED;
  }
  params->vmc->virt_machine_set_defaults(params);

  int ram_size = config->get("memory_size");
  params->ram_size = (uint64_t)ram_size << 20;

  String bios = proj_settings->globalize_path(config->get("bios"));
  if (!bios.empty()) {
    VMFileEntry *entry = &params->files[VM_FILE_BIOS];
    entry->filename = bios.alloc_c_string();
    entry->len = load_file(&entry->buf, entry->filename);
  }

  String kernel = proj_settings->globalize_path(config->get("kernel"));
  if (!kernel.empty()) {
    VMFileEntry *entry = &params->files[VM_FILE_KERNEL];
    entry->filename = kernel.alloc_c_string();
    entry->len = load_file(&entry->buf, entry->filename);
  }

  String cmdline = config->get("cmdline");
  if (!cmdline.empty()) {
    vm_add_cmdline(params, cmdline.alloc_c_string());
  }

  Array block_devices = config->get("block_devices");
  params->drive_count = block_devices.size();
  for (int i = 0; i < block_devices.size(); i++) {
    BlockDevice *drive;
    Resource *device = block_devices[i];
    String file = proj_settings->globalize_path(device->get("file"));
    int mode = device->get("mode");
    char *fname = file.alloc_c_string();
    drive = block_device_init(fname, (BlockDeviceModeEnum)mode);
    params->tab_drive[i].block_dev = drive;
  }

  params->rtc_real_time = TRUE;

  CharacterDevice *console = new CharacterDevice(); 
  console->opaque = this;
  console->read_data = _console_read;
  console->write_data = _console_write;
  params->console = console;

  vm = virt_machine_init(params);
  if (!vm) {
     return GODOT_FAILED;
  }

  return GODOT_OK;
}

void VM::run(int max_sleep_time_ms = MAX_SLEEP_TIME, int max_exec_cycles = MAX_EXEC_CYCLES) {
  fd_set rfds, wfds, efds;
  int fd_max, ret, delay;
  struct timeval tv;

  delay = virt_machine_get_sleep_duration(vm, max_sleep_time_ms);

  FD_ZERO(&rfds);
  FD_ZERO(&wfds);
  FD_ZERO(&efds);
  fd_max = -1;

  if (vm->net) {
    vm->net->select_fill(vm->net, &fd_max, &rfds, &wfds, &efds, &delay);
  }

  tv.tv_sec = delay / 1000;
  tv.tv_usec = (delay % 1000) * 1000;
  ret = select(fd_max + 1, &rfds, &wfds, &efds, &tv);
  if (vm->net) {
    vm->net->select_poll(vm->net, &rfds, &wfds, &efds, ret);
  }

  virt_machine_interp(vm, max_exec_cycles);
}

void VM::stop() {
  if (vm != nullptr) {
    virt_machine_end(vm);
  }
}

godot_error VM::console_read(PoolByteArray data) {
  if (!vm->console_dev) {
    return GODOT_ERR_DOES_NOT_EXIST; 
  } else if (!virtio_console_can_write_data(vm->console_dev)) {
    return GODOT_ERR_BUSY;
  }

  if (data.size() > 0) {
    virtio_console_write_data(vm->console_dev, data.read().ptr(), data.size());
  }

  return GODOT_OK;
}

void VM::console_resize(int width = 80, int height = 24) {
  if (vm->console_dev) {
    virtio_console_resize_event(vm->console_dev, width, height);
  }
}
