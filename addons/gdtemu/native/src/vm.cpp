// SPDX-FileCopyrightText: 2021-2022 Leroy Hopson <copyright@leroy.geek.nz> 
// SPDX-FileCopyrightText: 2019 Fernando Lemos
// SPDX-FileCopyrightText: 2016-2018 Fabrice Bellard
// SPDX-License-Identifier: MIT

#include <signal.h>
#include <arpa/inet.h>
#include <sys/time.h>

#include <ProjectSettings.hpp>

#include "vm.h"

using namespace godot;

void VM::_register_methods() {
  register_signal<VM>("console_wrote", "data", GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY);

  register_method("_init", &VM::_init);

  register_method("start", &VM::start);
  register_method("run", &VM::run);
  register_method("stop", &VM::stop);

  register_method("run_thread", &VM::run_thread);
  register_method("stop_thread", &VM::stop_thread);

  register_method("console_read", &VM::console_read);
  register_method("console_resize", &VM::console_resize);
}

std::set<pthread_t> VM::threads = {};
pthread_t VM::main_thread = pthread_self();

// SIGALRM is used to interrupt execution of KVM, however setitimer() and ualarm()
// only set one alarm per process and the signal is sent only to the main thread.
// Therefore, we must propagate the signal to other threads.
static void on_alarm(int sig) {
  if (!pthread_equal(pthread_self(), VM::main_thread)) {
    return;
  }

  std::set<pthread_t>::iterator ptr;
  for (ptr = VM::threads.begin(); ptr != VM::threads.end(); ++ptr) {
    pthread_t thread = *ptr;
    pthread_kill(thread, sig);
  }
}

static EthernetDevice *slirp_open(void* opaque)
{
  VM* vm = static_cast<VM*>(opaque);

  EthernetDevice *net;
  struct in_addr net_addr  = { .s_addr = htonl(0x0a000200) }; /* 10.0.2.0 */
  struct in_addr mask = { .s_addr = htonl(0xffffff00) }; /* 255.255.255.0 */
  struct in_addr host = { .s_addr = htonl(0x0a000202) }; /* 10.0.2.2 */
  struct in_addr dhcp = { .s_addr = htonl(0x0a00020f) }; /* 10.0.2.15 */
  struct in_addr dns  = { .s_addr = htonl(0x0a000203) }; /* 10.0.2.3 */
  const char *bootfile = NULL;
  const char *vhostname = NULL;
  int restricted = 0;

  net = (EthernetDevice*)mallocz(sizeof(*net));
  
  vm->slirp_state = slirp_init(restricted, net_addr, mask, host, vhostname,
                           "", bootfile, dhcp, dns, net);

  net->mac_addr[0] = 0x02;
  net->mac_addr[1] = 0x00;
  net->mac_addr[2] = 0x00;
  net->mac_addr[3] = 0x00;
  net->mac_addr[4] = 0x00;
  net->mac_addr[5] = 0x01;
  net->opaque = vm->slirp_state;
  net->write_packet = slirp_write_packet;
  net->select_fill = slirp_select_fill1;
  net->select_poll = slirp_select_poll1;
  
  return net;
}

VM::VM() {}
VM::~VM() {}

void VM::_init() {}

static int _console_read(void *opaque, uint8_t *buf,int len) {
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

  Array net_devices = config->get("net_devices");
  params->eth_count = net_devices.size();
  for (int i = 0; i < net_devices.size(); i++) {
    EthernetDevice *eth;
    Resource *device = net_devices[i];
    int driver = device->get("driver");
    switch (driver) {
      case 0:
        params->tab_eth[i].net = slirp_open(this);
        Array port_forwards = device->call("_get_port_forwards_parsed");
        for (int i = 0; i < port_forwards.size(); i++) {
          Dictionary port_forward = port_forwards[i];

          String proto = port_forward["proto"];
          bool is_udp = proto == String("udp");

          String host_addr_str = port_forward["host_addr"];
          struct in_addr host_addr = in_addr { 0 };
          inet_pton(AF_INET, host_addr_str.alloc_c_string(), &host_addr.s_addr);
          int host_port = port_forward["host_port"];

          String guest_addr_str = port_forward["guest_addr"];
          struct in_addr guest_addr = in_addr { 0 };
          inet_pton(AF_INET, guest_addr_str.alloc_c_string(), &guest_addr.s_addr);
          int guest_port = port_forward["guest_port"];

          slirp_add_hostfwd(slirp_state, is_udp, in_addr { host_addr.s_addr }, host_port, in_addr { guest_addr.s_addr }, guest_port);
        }
        break;
    }
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

static void* thread_func(void* opaque) {
  VM* vm = static_cast<VM*>(opaque); 
  int max_sleep_time_ms = vm->get_meta("max_sleep_time_ms");
  int max_exec_cycles = vm->get_meta("max_exec_cycles");

  while (vm->thread_running) {
    vm->run(max_sleep_time_ms, max_exec_cycles);
  }

  return nullptr;
}

int VM::run_thread(int max_sleep_time_ms = MAX_SLEEP_TIME, int max_exec_cycles = MAX_EXEC_CYCLES) {
  if (thread_running) {
    return GODOT_ERR_ALREADY_IN_USE;
  }

  this->set_meta("max_sleep_time_ms", max_sleep_time_ms);
  this->set_meta("max_exec_cycles", max_exec_cycles);

  thread_running = true;

  if (pthread_create(&thread, NULL, thread_func, this) != 0) {
    thread_running = false;
    return GODOT_FAILED;
  }

  VM::threads.insert(thread);

  /* Set up handler for SIGALRM */
  struct sigaction act;
	act.sa_handler = &on_alarm;
	sigemptyset (&act.sa_mask);
	act.sa_flags = SA_SIGINFO;
	sigaction (SIGALRM, &act, NULL);

  return GODOT_OK;
}

void VM::stop_thread() {
  if (!thread_running) {
    return;
  }

  thread_running = false;
  void *_ret;
  pthread_join(thread, &_ret);
  VM::threads.erase(thread);
}

void VM::stop() {
  if (vm != nullptr) {
    virt_machine_end(vm);
    if (slirp_state) {
      slirp_cleanup(slirp_state);
      slirp_state = nullptr;
    }
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
