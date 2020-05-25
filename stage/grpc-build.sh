#!/usr/bin/env bash

set -ex

ROOT=$(pwd)
GRPC=$ROOT/grpc
RESULT=$ROOT/result

sudo apt install -y build-essential autoconf libtool pkg-config libssl-dev wget

rm -rf $GRPC && mkdir -p $GRPC && git clone --recurse-submodules -b v1.28.1 https://github.com/grpc/grpc $GRPC -j 4 && cd $GRPC

# Install CMake 3.16
wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1-Linux-x86_64.sh
sudo sh cmake-linux.sh -- --skip-license --prefix=/usr
rm cmake-linux.sh

# Build and install gRPC for the host architecture.
# We do this because we need to be able to run protoc and grpc_cpp_plugin
# while cross-compiling.
mkdir -p "cmake/build"
pushd "cmake/build"
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DgRPC_INSTALL=ON \
  -DgRPC_BUILD_TESTS=OFF \
  -DgRPC_SSL_PROVIDER=package \
  ../..
sudo make -j 4 install
popd


CC=aarch64-unknown-linux-android-gcc
CXX=aarch64-unknown-linux-android-g++
STAGE=/tmp/aarch64_stage
TOOLCHAIN_CMAKE=/tmp/toolchain.cmake
SYSROOT=$($CC -print-sysroot)

sudo ln -sf $SYSROOT/usr/lib/libc.so  $SYSROOT/usr/lib/libpthread.so

# Write a toolchain file to use for cross-compiling.
cat > $TOOLCHAIN_CMAKE << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_STAGING_PREFIX $STAGE)
set(CMAKE_SYSROOT $SYSROOT)
set(CMAKE_C_COMPILER $CC)
set(CMAKE_CXX_COMPILER $CXX)
set(CMAKE_C_FLAGS "-D__ANDROID_API__=21")
set(CMAKE_CXX_FLAGS "-D__ANDROID_API__=21")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

mkdir -p "cmake/aarch64_build"
pushd "cmake/aarch64_build"
cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_CMAKE \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$RESULT \
      -D__ANDROID_API__=21 \
      ../..
make -j 4 install
popd

mkdir -p "examples/cpp/helloworld/cmake/raspberrypi_build"
pushd "examples/cpp/helloworld/cmake/raspberrypi_build"
cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_CMAKE \
      -DCMAKE_BUILD_TYPE=Release \
      -DProtobuf_DIR=$STAGE/lib/cmake/protobuf \
      -DgRPC_DIR=$STAGE/lib/cmake/grpc \
      -DCMAKE_INSTALL_PREFIX=$RESULT \
      -D__ANDROID_API__=21 \
      ../..
make -j 4 install
popd
