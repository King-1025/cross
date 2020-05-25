#!/usr/bin/env bash

set -ex

ROOT=$(pwd)
RESULT=$ROOT/result

[ ! -e openssl ] && git clone https://github.com/openssl/openssl.git openssl -j 4

cd openssl

./config --help

./Configure android64-aarch64  -D__ANDROID_API__=21 --prefix=$RESULT --cross-compile-prefix=aarch64-unknown-linux-android-

make -j 4 && make install
