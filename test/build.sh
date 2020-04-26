#!/usr/bin/env bash

ROOT=$(pwd)
RESULT=$ROOT/result

CC=aarch64-unknown-linux-android-gcc

mkdir -p $RESULT

$CC -pie -fPIC -Wall $ROOT/test/hello.c -o $ROOT/test/hello

$CC --your-cflags-except-sysroot -print-sysroot

aarch64-unknown-linux-android-populate -s $ROOT/test -d $RESULT -v

