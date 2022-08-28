# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
FROM emscripten/emsdk:3.1.14
RUN apt-get update && apt-get install pkg-config python3 -y
RUN pip3 install scons==4.3.0
CMD scons platform=javascript generate_bindings=yes target=${TARGET:-release} bits=${BITS:-64} -j$(nproc)
