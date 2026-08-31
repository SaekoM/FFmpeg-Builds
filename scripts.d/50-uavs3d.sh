#!/bin/bash

SCRIPT_REPO="https://github.com/uavs3/uavs3d.git"
SCRIPT_COMMIT="1fd04917cff50fac72ae23e45f82ca6fd9130bd8"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# AVS3 decoder. No avs3 decoder is enabled.
#
# generate.sh skips the stage entirely and build.sh emits ffbuild_unconfigure instead, so the
# library is simply absent rather than half-present. Re-enable only alongside the variant flag
# that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerdl() {
    to_df "RUN git clone \"$SCRIPT_REPO\" \"$SELF\" && git -C \"$SELF\" checkout \"$SCRIPT_COMMIT\""
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    mkdir build/linux
    cd build/linux

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DCOMPILE_10BIT=1 -DBUILD_SHARED_LIBS=NO ../..
    make -j$(nproc)
    make install
}

ffbuild_configure() {
    echo --enable-libuavs3d
}

ffbuild_unconfigure() {
    echo --disable-libuavs3d
}
