#!/usr/bin/env bash

set -ex

ROOT=$(pwd)
RESULT=$ROOT/result

[ ! -e openssl ] && git clone https://github.com/openssl/openssl.git openssl -j 4

cd openssl

#./config -h

CC=gcc CROSS_COMPILE=aarch64-unknown-linux-android- ./config -D__ANDROID_API__=21 --prefix=$RESULT

make -j 4 && make install
