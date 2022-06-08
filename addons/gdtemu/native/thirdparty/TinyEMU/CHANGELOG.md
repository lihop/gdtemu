<!--
  SPDX-FileCopyrightText: 2022 Leroy Hopson
  SPDX-FileCopyrightText: 2019-2020 Fernando Lemos
  SPDX-FileCopyrightText: 2017-2018 Fabrice Bellard
  SPDX-License-Identifier: MIT
-->

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/lihop/TinyEMU/compare/v1.0.0...HEAD)
### Added
- Support for Windows using MinGW compiler and with SLiRP disabled (i.e. CONFIG_SLIRP=n).

### Changed
- Exposed slirp functions:
  - slirp_write_packet()
  - slirp_select_fill1()
  - slirp_select_poll1()

## [v1.0.0](https://github.com/lihop/TinyEMU/compare/v2019-02-10...v1.0.0) - 2020-05-25
### Added
- Added macOS and iOS support.
- Added support for loading ELF images.
- Added support for loading initrd images or compressed initramfs archives.
- Added complete JSLinux demo.
- RISC-V: Added initrd support.

### Changed
- Framebuffer support through SDL 2 instead of 1.2. 
- Changed Versioning style from date-based to [Semantic Versioning](https://semver.org/).

### Fixed
- RISC-V: Fixed FMIN/FMAX instructions.

## [2019-02-10](https://github.com/lihop/TinyEMU/releases/tag/v2019-02-10)
### Fixed
- Compilation fixes.

## 2018-09-23
### Added
- Added support for separate RISC-V BIOS and kernel.

## 2018-09-15
### Changed
- Renamed to TinyEMU (temu).
- Single executable for all emulated machines.

## 2018-08-29
### Fixed
- Compilation fixes.

## 2017-08-06
### Added
- Added JSON configuration file.
- Added graphical display with SDL.
- Added VirtIO input support.
- Added PCI bus and VirtIO PCI support.
- x86: Added IDE, PS/2, vmmouse and VGA devices.
- Added user mode network interface.

## 2017-06-10
### Changed
- RISCV: Avoid unnecessary kernel patches.
- x86: Accept standard kernel images.

## 2017-05-25
### Added
- Added small x86 emulator (x86emu) based on KVM.
- Handle console resize.
- JS emulator:
  - Added scrollbar in terminal.
  - Added file import and export.
  - Added copy/paste support.

### Changed
- RISCV: Faster emulation (1.4x).
- Support of user level ISA version 2.2 and priviledged architecture
  version 1.10.
- Modified the fs_net network protocol to match the vfsync protocol.
