#!/bin/bash

# A RELEASE TARBALL, deliberately not the git tree.
#
# The git tree's ./autogen.sh regenerates the build system, and libiconv's Makefile.devel demands one
# exact automake — it calls `aclocal-1.18`. This image is Ubuntu 23.04, which ships automake 1.16.5, so
# that path dies with "aclocal-1.18: not found" regardless of which commit is pinned. A GNU release
# tarball ships a pre-generated `configure`, so nothing here needs autoconf, automake or gnulib at all.
# That also removes the old build-time `autopull.sh` fetch of gnulib — a network call in the middle of a
# build stage — as a second, independent way for this to break later.
#
# Upstream BtbN solves the same failure differently (pinned libiconv + pinned gnulib, built on a much
# newer base image whose autotools are new enough). That fix does not port here: this fork is held on
# 23.04 on purpose, so the toolchain that produced the currently shipping DLLs stays unchanged while the
# codec set is the only thing that moves. See variants/lgpl-godot.sh for why that matters.
#
# 1.17 rather than the newest release: it predates the automake-1.18 requirement entirely, it is the
# version distributions shipped for years, and libiconv is a leaf dependency where being current buys
# nothing.
SCRIPT_VERSION="1.17"
SCRIPT_TARBALL="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${SCRIPT_VERSION}.tar.gz"
# sha256 as published on ftp.gnu.org. Pinned so a swapped mirror or a truncated download fails right
# here, loudly, instead of somewhere confusing further into the build.
SCRIPT_SHA256="8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313"

ffbuild_enabled() {
    return 0
}

# Download, verify and unpack are all inside the retried command on purpose: a truncated download fails
# the checksum, and the retry then fetches it again rather than leaving a corrupt tree for the build.
ffbuild_dockerdl() {
    to_df "RUN retry-tool sh -c \"rm -rf $SELF iconv.tar.gz && curl -fsSL '$SCRIPT_TARBALL' -o iconv.tar.gz && echo '$SCRIPT_SHA256  iconv.tar.gz' | sha256sum -c - && mkdir -p $SELF && tar xzf iconv.tar.gz -C $SELF --strip-components=1\" && rm -f iconv.tar.gz"
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --enable-extra-encodings
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
}

ffbuild_configure() {
    echo --enable-iconv
}

ffbuild_unconfigure() {
    echo --disable-iconv
}
