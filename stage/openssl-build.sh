#!/usr/bin/env bash

set -ex

ROOT=$(pwd)
RESULT=$TOOL_HOME

[ ! -e openssl ] && git clone https://github.com/openssl/openssl.git openssl -j 4

cd openssl

#./config -h

export ANDROID_NDK_ROOT=$TOOL_HOME

./Configure linux-aarch64 -D__ANDROID_API__=21 --prefix=$RESULT --cross-compile-prefix=aarch64-unknown-linux-android- -enable-threads

make -j 4

export PATH=$PATH:$TOOL_HOME/bin 

sudo make install
