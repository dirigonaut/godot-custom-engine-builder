#!/bin/bash

set -e

# Config

export SCONS="scons -j${NUM_CORES} verbose=yes warnings=no progress=no"
export OPTIONS="production=yes use_mingw=yes angle_libs=/root/angle mesa_libs=/root/mesa d3d12=yes"
export OPTIONS_MONO="module_mono_enabled=yes"
export OPTIONS_LLVM="use_llvm=yes mingw_prefix=/root/llvm-mingw"
export TERM=xterm

rm -rf godot
mkdir godot
cd godot
tar xf /root/godot.tar.gz --strip-components=1

function build_for_architecture() {
  local ARCH=$1
  local IS_MONO=$2
  local SUFFIX=""

  local ARGS="arch=$ARCH"
  ARGS+=" $OPTIONS"

  if [ "$IS_MONO" == 1 ]; then
    SUFFIX="-mono"
    ARGS+=" $OPTIONS_MONO"
  fi

  if [ "$ARCH" == "arm64" ]; then
    ARGS+=" $OPTIONS_LLVM"
  fi

  $SCONS platform=windows $ARGS target=editor

  if [ ! -z "$IS_MONO" ]; then
    ./modules/mono/build_scripts/build_assemblies.py --godot-output-dir=./bin --godot-platform=windows
  fi

  mkdir -p /root/out/$ARCH/tools$SUFFIX
  cp -rvp bin/* /root/out/$ARCH/tools$SUFFIX
  rm -rf bin

  $SCONS platform=windows $ARGS target=template_debug
  $SCONS platform=windows $ARGS target=template_release

  mkdir -p /root/out/$ARCH/templates$SUFFIX
  cp -rvp bin/* /root/out/$ARCH/templates$SUFFIX
  rm -rf bin
}

# Classical
if [ "${CLASSICAL}" == "1" ]; then
  echo "Starting classical build for Windows..."

  for ARCH in "${ARCHITECTURES[@]}"; do
    if [ "$ARCH" != "arm32" ]; then
      build_for_architecture $ARCH 0
    fi
  done
fi

# Mono
if [ "${MONO}" == "1" ]; then
  echo "Starting Mono build for Windows..."

  for ARCH in "${ARCHITECTURES[@]}"; do
    if [ "$ARCH" != "arm32" ]; then
      build_for_architecture $ARCH 1
    fi
  done
fi

echo "Windows build successful"
