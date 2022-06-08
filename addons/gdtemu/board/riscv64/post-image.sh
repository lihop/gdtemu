#!/bin/bash
#
# SPDX-FileCopyrightText: none
# SPDX-License-Identifier: CC0-1.0
#
# TinyEMU only supports raw kernel images, so convert the ELF image into a raw
# image.

${HOST_DIR}/bin/riscv64-buildroot-linux-musl-objcopy -O binary \
	${BINARIES_DIR}/vmlinux ${BINARIES_DIR}/Image
