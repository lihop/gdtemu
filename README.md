<!--
  SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
  SPDX-License-Identifier: MIT
-->

# gdtemu

## Buildroot

Buildroot can be used to generate kernels and root filesystems for VMs.

### Linux Kernel Configuration
These drivers must be enabled in order for the console and block devices to work:
1. Device Drivers -> Virtio drivers -> PCI driver for virtio devices
2. Device Drivers -> Character devices -> Virtio console
3. Device Drivers -> Block devices -> Virtio block driver
