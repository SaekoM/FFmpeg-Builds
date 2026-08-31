#!/bin/bash

SCRIPT_REPO="https://code.videolan.org/videolan/libudfread.git"
SCRIPT_COMMIT="b3e6936a23f8af30a0be63d88f4695bdc0ea26e1"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# UDF reader, reached only through libbluray. No bluray demuxer is enabled.
#
# generate.sh skips the stage entirely and build.sh emits ffbuild_unconfigure instead, so the
# library is simply absent rather than half-present. Re-enable only alongside the variant flag
# that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    ./bootstrap

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-shared
        --enable-static
        --with-pic
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install

    ln -s libudfread.pc "$FFBUILD_PREFIX"/lib/pkgconfig/udfread.pc
}
