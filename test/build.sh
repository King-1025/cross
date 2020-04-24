#!/usr/bin/env bash

ROOT=$(pwd)
RESULT=$ROOT/result

CC=gcc

mkdir -p $RESULT

$CC $ROOT/test/hello.c -o $RESULT/hello
