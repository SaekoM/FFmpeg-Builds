#!/bin/bash

SCRIPT_REPO="https://chromium.googlesource.com/webm/libvpx"
SCRIPT_COMMIT="b2c2955c8200ff434f178009df41a1e1e1623156"

# DISABLED IN THIS FORK — its decoders are never registered, so it has always been dead weight.
#
# variants/lgpl-godot.sh starts from --disable-decoders and re-enables `vp8` and `vp9` by name. Those
# are FFmpeg's NATIVE decoders. libvpx's are separate entries (`libvpx_vp8` / `libvpx_vp9`) that the
# list never names, so --enable-libvpx links the library and registers nothing you can call. Verified
# against the shipping avcodec-60.dll: the strings "libvpx-vp8" and "libvpx-vp9" do not occur in it.
#
# This is the same trap as libaom (see 50-aom.sh). VideoDecoder::_codec_id_to_preferred_decoder_name
# does ask for "libvpx" / "libvpx-vp9", but that lookup has always failed and fallen through to the
# native decoder — which is generally the faster of the two for VP9 anyway.
#
# It is disabled rather than repaired because it also broke: its configure dies with "Toolchain is
# unable to link executables" on this image, while the fourteen libraries built before it link fine.
# Diagnosing that would mean chasing config.log to fix something that produces nothing.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    local myconf=(
        --disable-shared
        --enable-static
        --enable-pic
        --disable-examples
        --disable-tools
        --disable-docs
        --disable-unit-tests
        --enable-vp9-highbitdepth
        --prefix="$FFBUILD_PREFIX"
    )

    if [[ $TARGET == win64 ]]; then
        myconf+=(
            --target=x86_64-win64-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    elif [[ $TARGET == win32 ]]; then
        myconf+=(
            --target=x86-win32-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    elif [[ $TARGET == linux64 ]]; then
        myconf+=(
            --target=x86_64-linux-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    elif [[ $TARGET == linuxarm64 ]]; then
        myconf+=(
            --target=arm64-linux-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install

    # Work around strip breaking LTO symbol index
    "$RANLIB" "$FFBUILD_PREFIX"/lib/libvpx.a
}

ffbuild_configure() {
    echo --enable-libvpx
}

ffbuild_unconfigure() {
    echo --disable-libvpx
}
