#!/bin/bash

SCRIPT_REPO="https://git.savannah.gnu.org/git/libiconv.git"
SCRIPT_COMMIT="5e517e5bf0e1b4575ad431e81d7a4750fa2b284e"

# gnulib is cloned HERE, at download time, rather than being fetched by autopull.sh during the build.
#
# The old build ran `retry-tool ./autopull.sh --one-time`, which reaches out to savannah in the middle
# of the build stage — a network call to a moving repository, three years after this fork was frozen.
# Upstream BtbN hit the same wall and made exactly this change, so the commit pair below is theirs and
# is known to build together. Bump the two TOGETHER if ever: autogen.sh is sensitive to which gnulib it
# is handed, and a mismatched pair fails in a much less obvious way than a missing one.
#
# The GitHub mirror is used for gnulib (as upstream does) because savannah is slow and prone to timing
# out on a full clone; libiconv itself stays on savannah over https, which is what this fork already had.
SCRIPT_REPO2="https://github.com/coreutils/gnulib.git"
SCRIPT_COMMIT2="09b1597470c456aeac7e7d19b214821d4526934d"

ffbuild_enabled() {
    return 0
}

# NOTE: written against THIS fork's older harness — `to_df "RUN …"`, and a source tree at
# $FFBUILD_DLDIR/$SELF. Upstream's current copy of this file uses a newer one (bare `echo`, no `cd`,
# a $FFBUILD_DESTDIR that does not exist here), so it cannot be dropped in verbatim; only the gnulib
# change above was ported across.
ffbuild_dockerdl() {
    to_df "RUN retry-tool sh -c \"rm -rf $SELF && git clone '$SCRIPT_REPO' $SELF\" && git -C $SELF checkout \"$SCRIPT_COMMIT\""
    to_df "RUN cd $SELF && retry-tool sh -c \"rm -rf gnulib && git clone --filter=blob:none '$SCRIPT_REPO2' gnulib\" && git -C gnulib checkout \"$SCRIPT_COMMIT2\" && rm -rf gnulib/.git"
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    (unset CC CFLAGS GMAKE && ./autogen.sh)

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
