#!/usr/bin/env bash

set -ex

ROOT=$(pwd)
GRPC=$ROOT/grpc
RESULT=$ROOT/result

function app()
{
   get_repo
   install_cmake
   cross_compile_grpc
}

function get_repo()
{
    # sudo apt install -y build-essential autoconf libtool pkg-config libssl-dev wget

    rm -rf $GRPC && mkdir -p $GRPC && git clone --recurse-submodules -b v1.28.1 https://github.com/grpc/grpc $GRPC -j 4 && cd $GRPC
}

function install_cmake()
{
   # Install CMake 3.16
   wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1-Linux-x86_64.sh
   sudo sh cmake-linux.sh -- --skip-license --prefix=/usr
   rm cmake-linux.sh
}

function build_host_grpc()
{
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
}

function cross_compile_grpc()
{
  local prefix="aarch64-linux-android"
  export GRPC_CROSS_COMPILE=true
 # export PATH=/home/ubuntu/stand-alone-toolchain/arm-26-toolchain-clang/bin:$PATH
  export SYSROOT=$TOOL_HOME/sysroot
  export HOST_CC="/usr/bin/gcc"
  export HOST_CXX="/usr/bin/g++"
  export HOST_LD="/usr/bin/ld"
  export CC="${prefix}-clang --sysroot $SYSROOT"
  export CXX="${prefix}-clang++ --sysroot $SYSROOT"
  export LD="${prefix}-clang++"
  export LDXX="${prefix}-clang++" 
  export AR="${prefix}-ar"
  export STRIP="${prefix}-strip"
  export PROTOBUF_CONFIG_OPTS="--host=${prefix} --with-sysroot=${SYSROOT} --with-protoc=/usr/local/bin/protoc CFLAGS='-march=armv7-a -D__ANDROID_API__=26' CXXFLAGS='-frtti -fexceptions -march=armv7-a -D__ANDROID_API__=26' LIBS='-llog -lz -lc++_static'"
  export HAS_PKG_CONFIG=false
  export GRPC_CROSS_LDOPTS="-L$SYSROOT -L$GRPC"
  export GRPC_CROSS_AROPTS="rc --target=elf64-little"
  
  make -j 4
}

function cmake_cross_compile_grpc()
{
   #STAGE=/tmp/aarch64_stage
   STAGE=$RESULT/aarch64_stage
   TOOLCHAIN_CMAKE=/tmp/toolchain.cmake
   # SYSROOT=$($CC -print-sysroot)
   SYSROOT=$TOOL_HOME/sysroot
   CC="aarch64-linux-android-clang"
   CXX="aarch64-linux-android-clang++"

# sudo ln -sf $SYSROOT/usr/lib/libc.so  $SYSROOT/usr/lib/libpthread.so
# sudo ln -sf $SYSROOT/usr/lib/libc.so  $SYSROOT/usr/lib/librt.so

# Write a toolchain file to use for cross-compiling.
cat > $TOOLCHAIN_CMAKE << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_STAGING_PREFIX "$STAGE")
set(CMAKE_SYSROOT "$SYSROOT")
set(CMAKE_C_COMPILER "$CC")
set(CMAKE_CXX_COMPILER "$CXX")
set(CMAKE_C_FLAGS "-D__ANDROID_API__=21 -fPIE")
set(CMAKE_CXX_FLAGS "-D__ANDROID_API__=21 -fPIE")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

export ANDROID_NDK=$TOOL_HOME

TOOLCHAIN_CMAKE=$ROOT/stage/ndk/Android.cmake

mkdir -p "cmake/aarch64_build"
pushd "cmake/aarch64_build"
cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_CMAKE \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DANDROID_STL=c++_static \
      -DRUN_HAVE_STD_REGEX=0 \
      -DRUN_HAVE_POSIX_REGEX=0 \
      -DRUN_HAVE_STEADY_CLOCK=0 \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$RESULT \
      -DBUILD_SHARED_LIBS=ON \
      -DgRPC_INSTALL=ON \
      ../..
make -j 4 install
popd

# -D__ANDROID_API__=21 \
}

function build_hello_world()
{
   mkdir -p "examples/cpp/helloworld/cmake/aarch64_build"
   pushd "examples/cpp/helloworld/cmake/aarch64_build"
   cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_CMAKE \
      -DCMAKE_BUILD_TYPE=Release \
      -DProtobuf_DIR=$STAGE/lib/cmake/protobuf \
      -DgRPC_DIR=$STAGE/lib/cmake/grpc \
      -DCMAKE_INSTALL_PREFIX=$RESULT \
      ../..
   make -j 4
   popd

   mv examples/cpp/helloworld/cmake/aarch64_build $RESULT
}

app $*
