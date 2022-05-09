// SPDX-FileCopyrightText: 2016-2018 Fabrice Bellard
// SPDX-License-Identifier: MIT

#include <inttypes.h>
#include <stdio.h>

#include "cutils.h"
#include "virtio.h"

typedef enum {
  BF_MODE_RO,
  BF_MODE_RW,
  BF_MODE_SNAPSHOT,
} BlockDeviceModeEnum;

#define SECTOR_SIZE 512

void slirp_write_packet(EthernetDevice *net, const uint8_t *buf, int len);
void slirp_select_fill1(EthernetDevice *net, int *pfd_max, fd_set *rfds,
                        fd_set *wfds, fd_set *efds, int *pdelay);
void slirp_select_poll1(EthernetDevice *net, fd_set *rfds, fd_set *wfds,
                        fd_set *efds, int select_ret);
EthernetDevice *slirp_open(void);
