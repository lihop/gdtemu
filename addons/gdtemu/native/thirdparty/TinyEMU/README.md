<!--
  SPDX-FileCopyrightText: 2022 Leroy Hopson
  SPDX-FileCopyrightText: 2019-2020 Fernando Lemos
  SPDX-FileCopyrightText: 2017-2018 Fabrice Bellard
  SPDX-License-Identifier: MIT
-->

# TinyEMU

This is a modified version of [Fabrice Bellard's TinyEMU][TinyEMU] which is
forked from [Fernando Lemos's version](https://github.com/fernandotcl/TinyEMU/).

This fork is primarily intended for use as a library by the [gdtemu plugin] for the [Godot game engine].

The `temu` executable will eventually be removed and calls to `exit()` replaced.

[TinyEMU]: https://bellard.org/tinyemu/
[gdtemu plugin]: https://github.com/lihop/gdtemu/
[Godot game engine]: https://godotengine.org/

## Features

- 32/64/128-bit RISC-V emulation.
- x86 system emulator based on [KVM].
- VirtIO console, network, block device, input and 9P filesystem.
- Graphical display with SDL 2.
- Remote HTTP block device and filesystem.
- Small code, easy to modify, no external dependencies.
- Linux, JavaScript, macOS, iOS and (limited) Windows support.
- Support for loading ELF images.
- Support for loading initrd images or compressed initramfs archives.

[KVM]: https://www.linux-kvm.org/

## Usage

See the [gdtemu project] for an example of how this library can be used.

[gdtemu project]: https://github.com/lihop/gdtemu/

## Credits

TinyEMU was created by [Fabrice Bellard][fabrice].

Modifications were made by [Fernando Tarlá Cardoso Lemos][fernando] with contributions from [Jim Huang][jim].

This fork is maintanied by [Leroy Hopson][leroy].

[fabrice]: https://bellard.org
[fernando]: mailto:fernandotcl@gmail.com
[jim]: https://github.com/jserv
[leroy]: mailto:tinyemu@leroy.geek.nz

## License

Unless otherwise specified in individual files, TinyEMU is available under the MIT license (see [LICENSE]).

The SLIRP library has its own license (BSD 3-Clause).

[LICENSE]: /LICENSE
