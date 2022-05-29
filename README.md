<!--
  SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
  SPDX-License-Identifier: MIT
-->

# gdtemu

![Screenshot of example scene showing PC, RISC-V 32, and RISC-V 64 consoles.](/docs/screenshot.png)

## Buildroot

Buildroot can be used to generate kernels and root filesystems for VMs.

### Linux Kernel Configuration
#### Console and Block Devices
These drivers must be enabled in order for the console and block devices to work:
1. Device Drivers -> Virtio drivers -> PCI driver for virtio devices <\*>
2. Device Drivers -> Block devices -> Virtio block driver <\*>
3. Device Drivers -> Character devices -> Virtio console <\*>
4. Device Drivers -> Character devices -> RISC-V SBI console support [ ]

#### Network Devices
Network device support is confirmed with kernel version 4.19.245.
For network device support the following must be enabled:
1. Device Drivers -> Network device support -> Network core driver support [\*] -> Virtio network driver <\*>
