// SPDX-FileCopyrightText: 2016-2018 Fabrice Bellard
// SPDX-License-Identifier: MIT

#include <stdio.h>
#include <inttypes.h>

#include "cutils.h"
#include "virtio.h"

typedef enum {
    BF_MODE_RO,
    BF_MODE_RW,
    BF_MODE_SNAPSHOT,
} BlockDeviceModeEnum;

#define SECTOR_SIZE 512

typedef struct BlockDeviceFile {
    FILE *f;
    int64_t nb_sectors;
    BlockDeviceModeEnum mode;
    uint8_t **sector_table;
} BlockDeviceFile;

BlockDevice *block_device_init(const char *filename, BlockDeviceModeEnum mode);

void slirp_write_packet(EthernetDevice *net, const uint8_t *buf, int len);
void slirp_select_fill1(EthernetDevice *net, int *pfd_max, fd_set *rfds, fd_set *wfds, fd_set *efds, int *pdelay);
void slirp_select_poll1(EthernetDevice *net, fd_set *rfds, fd_set *wfds, fd_set *efds, int select_ret);
EthernetDevice *slirp_open(void);

void virt_machine_run(VirtMachine *m);

CharacterDevice *console_init(BOOL allow_ctrlc);