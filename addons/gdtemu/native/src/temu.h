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

EthernetDevice *slirp_open(void);

void virt_machine_run(VirtMachine *m);

CharacterDevice *console_init(BOOL allow_ctrlc);