#!/bin/bash

SCRIPT_REPO="https://github.com/Netflix/vmaf.git"
SCRIPT_COMMIT="98bdd77b296da207ab42c3113ec8f30de58db197"

# DISABLED IN THIS FORK — libvmaf cannot be reached by the build it would ship in.
#
# FFmpeg exposes libvmaf through exactly one thing, the `vmaf` video filter (libavfilter/vf_libvmaf.c),
# and variants/lgpl-godot.sh passes --disable-filters. So this compiles a large quality-metric library,
# links it, and then nothing in the output can call it.
#
# It is disabled rather than fixed because it was also the second thing to break here: its svm.cpp does
# `#include <thread>`, and this image's mingw-w64 is a win32-threads toolchain whose libstdc++ ships no
# C++11 threading headers. Fixing that means either rebuilding the cross-toolchain with posix threads or
# patching upstream source — real work, to enable something that does nothing.
#
# build.sh calls ffbuild_unconfigure when this returns non-zero, so FFmpeg is configured with
# --disable-libvmaf and generate.sh skips the build stage entirely. Nothing else depends on it: it is a
# leaf. If filters are ever enabled in this variant, revisit BOTH this line and the threads problem.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    # Kill build of unused and broken tools
    echo > libvmaf/tools/meson.build

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Dbuilt_in_models=true
        -Denable_tests=false
        -Denable_docs=false
        -Denable_avx512=true
        -Denable_float=true
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    else
        echo "Unknown target"
        return -1
    fi

    meson "${myconf[@]}" ../libvmaf
    ninja -j"$(nproc)"
    ninja install

    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_PREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    echo --enable-libvmaf
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
