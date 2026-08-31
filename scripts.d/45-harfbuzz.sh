#!/bin/bash

SCRIPT_REPO="https://github.com/harfbuzz/harfbuzz.git"
SCRIPT_COMMIT="73ee9c346f3acccbe14a4caf258b636de7c459be"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# Text shaping, reached only through libass / the drawtext filter. --disable-filters.
#
# generate.sh skips the stage entirely and build.sh emits ffbuild_unconfigure instead, so the
# library is simply absent rather than half-present. Re-enable only alongside the variant flag
# that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

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

    export LIBS="-lpthread"

    ./autogen.sh "${myconf[@]}"
    make -j$(nproc)
    make install
}
