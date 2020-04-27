#!/usr/bin/env bash

ROOT=(pwd)
RESULT=$ROOT/result
#HOST=aarch64-unknown-linux-android
#HOST=aarch64-linux-gnu

STRIP=$HOST-strip
CROSS_PREFIX="$HOST-"

URL=https://ffmpeg.org/releases/ffmpeg-4.2.2.tar.bz2
FILE=ffmpeg.tar.bz2

#${HOST}-populate

wget -q $URL -O $FILE

[[ ! -e ffmpeg ]] && mkdir ffmpeg

tar -xaf $FILE -C ffmpeg && rm -rf $FILE

cd ffmpeg

CONFIGURE=$(find $(pwd) -name configure -print)

COMMAND=$(cat << EOF
$CONFIGURE \
--arch=aarch64 \
--cpu=armv8-a \
--target-os=linux \
--cross-prefix=$CROSS_PREFIX \
--strip=$STRIP \
--enable-pic \
--enable-mmx \
--prefix=$RESULT \
--enable-shared \
--enable-cross-compile \
--enable-stripping \
--enable-network \
--enable-openssl \
--enable-swscale \
--enable-decoders \
--enable-demuxers \
--enable-protocols \
--pkg-config=true \
--extra-cflags="-fPIC" \
--extra-ldflags="-lssl" 
EOF
)

echo ""
echo $COMMAND && eval $COMMAND
echo ""
make -j 4 && make install
