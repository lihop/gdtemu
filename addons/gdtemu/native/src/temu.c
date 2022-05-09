// SPDX-FileCopyrightText: 2016-2018 Fabrice Bellard
// SPDX-License-Identifier: MIT
//
// Copy relevant functions from `../thirdparty/TinyEMU/temu.c` so we don't need
// to compile the whole thing or deal with the issues caused by the
// CONFIG_VERSION macro.

#include "temu.h"
#ifdef CONFIG_SLIRP
#include "slirp/libslirp.h"

void slirp_write_packet(EthernetDevice *net, const uint8_t *buf, int len) {
  Slirp *slirp_state = net->opaque;
  slirp_input(slirp_state, buf, len);
}

int slirp_can_output(void *opaque) {
  EthernetDevice *net = opaque;
  return net->device_can_write_packet(net);
}

void slirp_output(void *opaque, const uint8_t *pkt, int pkt_len) {
  EthernetDevice *net = opaque;
  return net->device_write_packet(net, pkt, pkt_len);
}

void slirp_select_fill1(EthernetDevice *net, int *pfd_max, fd_set *rfds,
                        fd_set *wfds, fd_set *efds, int *pdelay) {
  Slirp *slirp_state = net->opaque;
  slirp_select_fill(slirp_state, pfd_max, rfds, wfds, efds);
}

void slirp_select_poll1(EthernetDevice *net, fd_set *rfds, fd_set *wfds,
                        fd_set *efds, int select_ret) {
  Slirp *slirp_state = net->opaque;
  slirp_select_poll(slirp_state, rfds, wfds, efds, (select_ret <= 0));
}
#endif /* CONFIG_SLIRP */
