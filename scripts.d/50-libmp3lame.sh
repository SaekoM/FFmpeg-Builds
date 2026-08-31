#!/bin/bash

SCRIPT_REPO="https://svn.code.sf.net/p/lame/svn/trunk/lame"
SCRIPT_REV="6507"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# MP3 ENCODER. --disable-encoders, and MP3 decoding here is native (--enable-decoder=mp3).
#
# generate.sh skips the stage entirely and build.sh emits ffbuild_unconfigure instead, so the
# library is simply absent rather than half-present. Re-enable only alongside the variant flag
# that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerdl() {
    to_df "RUN retry-tool sh -c \"rm -rf lame && svn checkout '${SCRIPT_REPO}@${SCRIPT_REV}' lame\""
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR"/lame

    autoreconf -i

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-shared
        --enable-static
        --enable-nasm
        --disable-gtktest
        --disable-cpml
        --disable-frontend
        --disable-decoder
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    else
        echo "Unknown target"
        return -1
    fi

    export CFLAGS="$CFLAGS -DNDEBUG"

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install
}

ffbuild_configure() {
    echo --enable-libmp3lame
}

ffbuild_unconfigure() {
    echo --disable-libmp3lame
}
