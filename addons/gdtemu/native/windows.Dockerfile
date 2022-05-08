# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
FROM ubuntu:20.04
RUN apt-get update -y
RUN apt-get install -y python3 python3-pip
RUN pip3 install scons
RUN apt-get install -y gcc-mingw-w64-i686 g++-mingw-w64-i686
RUN apt-get install -y gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
CMD scons platform=windows generate_bindings=yes target=${TARGET:-release} bits=${BITS:-64} -j$(nproc)
