#!/bin/sh
# SPDX-FileCopyrightText: 2021 Leroy Hopson <copyright@leroy.geek.nz> 
# SPDX-License-Identifier: MIT
set -e

# Parse args.
args=$@
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -t|--target)
      target="$2"
      shift
      shift
      ;;
    --disable-pty)
      disable_pty="yes"
      shift
      ;;
    *)
      echo "Usage: ./build.sh [-t|--target <release|debug>] [--disable_pty]";
      exit 128
      shift
      ;;
  esac
done

# Set defaults.
target=${target:-debug}
disable_pty=${disable_pty:-no}
nproc=$(nproc || sysctl -n hw.ncpu)

#GODOT_DIR Get the absolute path to the directory this script is in.
NATIVE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Run script inside a nix shell if it is available.
if command -v nix-shell && [ $NIX_PATH ] && [ -z $IN_NIX_SHELL ]; then
	cd ${NATIVE_DIR}
	nix-shell --pure --run "NIX_PATH=${NIX_PATH} ./build.sh $args"
	exit
fi

# Update git submodules.
updateSubmodules() {
	eval $1=$2 # E.g TINYEMU_DIR=${NATIVE_DIR}/thirdparty/TinyEMU

	if [ -z "$(ls -A -- "$2")" ]; then
		cd ${NATIVE_DIR}
		git submodule update --init --recursive -- $2
	fi
}

updateSubmodules TINYEMU_DIR ${NATIVE_DIR}/thirdparty/TinyEMU
updateSubmodules GODOT_CPP_DIR ${NATIVE_DIR}/thirdparty/godot-cpp

# Build godot-cpp bindings.
cd ${GODOT_CPP_DIR}
scons target=$target -j$nproc #generate_bindings=yes target=$target -j$nproc

## Build libgdtemu.
cd ${NATIVE_DIR}
scons target=$target -j$nproc
