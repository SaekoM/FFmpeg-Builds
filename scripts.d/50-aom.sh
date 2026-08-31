#!/bin/bash

SCRIPT_REPO="https://aomedia.googlesource.com/aom"
SCRIPT_COMMIT="83ccc009eade321c8723ae0da8655fc68ce6a128"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# AV1 encoder plus the reference decoder. Encoders are disabled, and the AV1 decoder this build
# deliberately registers is libdav1d — libaom's is far too slow for playback (see the AV1 note in
# variants/lgpl-godot.sh). Also one of the slowest builds in the whole chain.
#
# generate.sh skips the stage entirely and build.sh emits ffbuild_unconfigure instead, so the
# library is simply absent rather than half-present. Re-enable only alongside the variant flag
# that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerstage() {
    to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=/,dst=\$FFBUILD_DLDIR,from=${DL_IMAGE},rw --mount=src=patches/aom,dst=/patches run_stage /stage.sh"
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    for patch in /patches/*.patch; do
        echo "Applying $patch"
        git am < "$patch"
    done

    mkdir cmbuild && cd cmbuild

    # Workaround broken build system
    export CFLAGS="$CFLAGS -pthread -I/opt/ffbuild/include/libvmaf"

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DBUILD_SHARED_LIBS=OFF -DENABLE_EXAMPLES=NO -DENABLE_TESTS=NO -DENABLE_TOOLS=NO -DCONFIG_TUNE_VMAF=1 ..
    make -j$(nproc)
    make install

    echo "Requires.private: libvmaf" >> "$FFBUILD_PREFIX/lib/pkgconfig/aom.pc"
}

ffbuild_configure() {
    echo --enable-libaom
}

ffbuild_unconfigure() {
    echo --disable-libaom
}
