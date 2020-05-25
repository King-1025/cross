#!/usr/bin/env bash

#grep -r __ANDROID_API__ $TOOL_HOME
#exit 1

ROOT=$(pwd)
RESULT=$ROOT/result
HOST=aarch64-unknown-linux-android
#HOST=aarch64-linux-android

STRIP="$HOST-strip"
CROSS_PREFIX="${HOST}-"

URL=https://ffmpeg.org/releases/ffmpeg-4.2.2.tar.bz2
FILE=ffmpeg.tar.bz2

#${HOST}-populate

[[ ! -e ffmpeg ]] && wget -q $URL -O $FILE && mkdir ffmpeg && tar -xaf $FILE -C ffmpeg && rm -rf $FILE

cd ffmpeg

CONFIGURE=$(find $(pwd) -name configure -print)

# sed -i "s/# FFmpeg configure script.*/set -x/g" $CONFIGURE

sed -i "s/B0/b0/g" $(find $(pwd) -name "aaccoder.c" -print)

sed -i "s/B0/b0/g" $(find $(pwd) -name "hevc_mvs.c" -print)

sed -i "s/B0/b0/g" $(find $(pwd) -name "opus_pvq.c" -print)

COMMAND=$(cat << EOF
$CONFIGURE \
--arch=aarch64 \
--target-os=android \
--cc=${HOST}-gcc \
--cross-prefix=$CROSS_PREFIX \
--strip=$STRIP \
--enable-pic \
--enable-mmx \
--prefix=$RESULT \
--enable-shared \
--enable-cross-compile \
--enable-stripping \
--enable-network \
--enable-swscale \
--enable-decoders \
--enable-demuxers \
--enable-protocols \
--pkg-config=true \
--extra-cflags="-fPIC" \
--extra-cflags="-D__ANDROID_API__=21" 
EOF
)

# --enable-openssl \
# --extra-ldflags="-lssl" 

echo ""
echo $COMMAND && eval $COMMAND
echo ""
make -j 4 && make install

echo package libffmpeg.so...

SYSROOT=$(${HOST}-gcc -print-sysroot)

cd $RESULT/lib

${HOST}-ld -rpath-link=$SYSROOT/usr/lib -L$SYSROOT/usr/lib -L$RESULT/lib -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o $RESULT/lib/libffmpeg.so libavcodec.a libavfilter.a libavformat.a libavutil.a libswresample.a libswscale.a -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker64 $(find $TOOL_HOME -name libgcc.a -print)
